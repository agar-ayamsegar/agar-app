//
//  SessionCard.swift
//  Agar
//
//  Created by Joren Alexander Toding on 17/11/26.
//

import SwiftUI

struct SessionCard: View {
    let session: ScanSession
    var isSelected: Bool = false

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .firstTextBaseline) {
                Text("Sesi #\(session.number)")
                    .font(.system(size: 17, weight: .bold))

                Spacer(minLength: 12)

                Text(session.startedAt, format: .dateTime.day().month(.wide).year())
                    .font(.system(size: 11))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .lastTextBaseline) {
                Text("\(session.totalCount)")
                    .font(.system(size: 40, weight: .bold))
                    .contentTransition(.numericText())

                Text("Ayam")
                    .font(.system(size: 17, weight: .bold))

                Spacer(minLength: 12)

                // a grid rather than two Texts, so the colons sit under each other the way
                // the sketch has them instead of ragging off the length of the label
                Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
                    GridRow {
                        Text("Segar")
                        Text(": \(session.freshCount)")
                    }
                    GridRow {
                        Text("Tidak Segar")
                        Text(": \(session.notFreshCount)")
                    }
                }
                .font(.system(size: 11))
                .foregroundStyle(.secondary)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(isSelected ? Color.cardGray : .white, in: .rect(cornerRadius: 18))
        // the selected card is filled, so a border on top of the fill only muddies it
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.cardGray, lineWidth: isSelected ? 0 : 1.5)
        }
        .contentShape(.rect)
    }
}


#Preview {
    VStack(spacing: 10) {
        SessionCard(session: ScanSession(number: 134, records: (1...150).map {
            ScanRecord(chickenNumber: $0, freshness: .fresh)
        }))
        SessionCard(session: ScanSession(number: 135, records: (1...130).map {
            ScanRecord(chickenNumber: $0, freshness: $0 > 128 ? .notFresh : .fresh)
        }), isSelected: true)
    }
    .padding()
    .background(Color.surfaceCream)
}
