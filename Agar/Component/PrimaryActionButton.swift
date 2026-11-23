//
//  PrimaryActionButton.swift
//  Agar
//

import SwiftUI

/// The one blue button the app uses for the primary action on every screen.
///
/// Deeper than the flat ActionBlue it replaces, with a little gradient and a shadow so it
/// lifts off the cream the way the sketch has it. Every screen goes through this, so the
/// four of them cannot drift apart again the way their spacing once did.
struct PrimaryActionButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .padding(.vertical, 17)
            .background(
                LinearGradient(
                    colors: [.actionBlueDeep.mix(with: .white, by: 0.16), .actionBlueDeep],
                    startPoint: .top,
                    endPoint: .bottom
                ),
                in: .capsule
            )
            // sits under the capsule rather than around it, so it reads as height not a glow
            .shadow(color: .actionBlueDeep.opacity(0.30), radius: 10, y: 5)
            .opacity(configuration.isPressed ? 0.9 : 1)
            .scaleEffect(configuration.isPressed ? 0.985 : 1)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == PrimaryActionButtonStyle {
    static var primaryAction: PrimaryActionButtonStyle { .init() }
}


#Preview {
    VStack(spacing: 20) {
        Button("Mulai Pemeriksaan") {}
        Button("Simpan & Lihat Laporan") {}
    }
    .buttonStyle(.primaryAction)
    .padding()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.surfaceCream)
}
