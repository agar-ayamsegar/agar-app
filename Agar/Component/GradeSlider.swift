//
//  GradeSlider.swift
//  Agar
//

import SwiftUI

// 1 to 5 track with a dot that can sit between two numbers (2.5),
// and a card hanging from the dot that says what to do with the meat
struct GradeSlider: View {
    let score: Double
    let grade: FreshnessGrade
    let tint: Color

    // the card is wider than the track so the pointer still lands on it at 1 and 5
    private let inset: CGFloat = 48
    private let tickWidth: CGFloat = 3
    private let trackHeight: CGFloat = 4
    private let trackY: CGFloat = 14
    // big enough to hold the number it stands on, no bigger
    private let knobSize: CGFloat = 24
    // starts under the numbers row, so nothing of the ruler is ever covered
    private let pointerTop: CGFloat = 44
    private let pointerWidth: CGFloat = 36
    private let areaHeight: CGFloat = 64
    // numbers sit low enough that the pointer is wide enough to hold one
    private let numberDrop: CGFloat = 30

    private var fraction: CGFloat {
        CGFloat(min(max((score - 1) / 4, 0), 1))
    }

    var body: some View {
        VStack(spacing: 0) {
            GeometryReader { proxy in
                let width = proxy.size.width
                let track = width - inset * 2
                let knobX = inset + track * fraction

                ZStack {
                    // stops at the inner edge of the end ticks, no stub past 1 and 5
                    Rectangle()
                        .fill(.white)
                        .frame(width: track - tickWidth, height: trackHeight)
                        .position(x: width / 2, y: trackY)

                    // under the ticks: up there it is only a couple of points wide
                    Pointer()
                        .fill(.white)
                        .frame(width: pointerWidth, height: areaHeight - pointerTop + 2)
                        .position(x: knobX, y: (pointerTop + areaHeight + 2) / 2)

                    ForEach(1...5, id: \.self) { step in
                        let x = inset + track * CGFloat(step - 1) / 4
                        let tick: CGFloat = step == 1 || step == 5 ? 14 : 10

                        // tick tops flush with the top of the track
                        Rectangle()
                            .fill(.white)
                            .frame(width: tickWidth, height: tick)
                            .position(x: x, y: trackY + tick / 2 - trackHeight / 2)

                        Text("\(step)")
                            .font(.subheadline)
                            .foregroundStyle(.white)
                            .position(x: x, y: trackY + numberDrop)
                    }

                    // the dot cuts a gap in the track so it never looks like it ate a tick
                    Circle()
                        .fill(tint)
                        .frame(width: knobSize + 8, height: knobSize + 8)
                        .position(x: knobX, y: trackY)

                    Circle()
                        .fill(Color.surfaceCream)
                        .frame(width: knobSize, height: knobSize)
                        .shadow(color: .black.opacity(0.15), radius: 2, y: 1)
                        .position(x: knobX, y: trackY)
                }
            }
            .frame(height: areaHeight)
            .animation(.spring, value: score)

            // fixedSize so a tall screen squeezes the drawing, never cuts the text with "..."
            VStack(spacing: 4) {
                Text(grade.label)
                    .font(.headline)
                Text(grade.detail)
                    .font(.footnote)
                    .multilineTextAlignment(.center)
            }
            .fixedSize(horizontal: false, vertical: true)
            .foregroundStyle(tint)
            .padding(.vertical, 14)
            .padding(.horizontal, 16)
            .frame(maxWidth: .infinity)
            .background(Color.white, in: .rect(cornerRadius: 24))
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Skor \(score.formatted(.number.precision(.fractionLength(1)))) dari 5, \(grade.label)")
    }
}

// triangle pointing up, its base joins the card below
// nonisolated because the project defaults to MainActor and Shape draws off the main actor
nonisolated private struct Pointer: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: CGPoint(x: rect.midX, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX, y: rect.maxY))
        path.addLine(to: CGPoint(x: rect.minX, y: rect.maxY))
        path.closeSubpath()
        return path
    }
}

#Preview {
    VStack(spacing: 32) {
        GradeSlider(score: 1.0, grade: .one, tint: .notFreshRed)
        GradeSlider(score: 2.5, grade: .three, tint: .freshGreen)
        GradeSlider(score: 4.0, grade: .four, tint: .freshGreen)
    }
    .padding(24)
    .background(Color.freshGreen)
}
