//
//  StatCard.swift
//  Agar
//
//  Created by fikrahdamars on 03/11/26.
//

import SwiftUI

struct StatCard: View {
    var title: String
    var value: Text
    var valueSize: CGFloat = 24
    var tint: Color = .black
    var background: Color = .cardGray

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(tint.opacity(0.75))

            // only the number is expanded black; the label above it stays plain
            value
                .font(.system(size: valueSize, weight: .black).width(.expanded))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
                // expanded is wider than the bold it replaces, so a long count shrinks
                // rather than pushing out of its card
                .lineLimit(1)
                .minimumScaleFactor(0.6)
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: .rect(cornerRadius: 16))
    }
}

extension StatCard {
    init(freshness: Freshness, value: Int) {
        self.init(title: freshness.title, value: Text("\(value)"), tint: freshness.tint, background: freshness.lightTint)
    }
}


#Preview {
    VStack {
        StatCard(title: "Ayam Masuk", value: Text("65"), valueSize: 44)

        HStack {
            StatCard(freshness: .fresh, value: 63)
            StatCard(freshness: .notFresh, value: 2)
            StatCard(title: "Waktu/Ayam", value: Text(Duration.seconds(7), format: .units(allowed: [.seconds], width: .abbreviated)))
        }
    }
    .padding()
}
