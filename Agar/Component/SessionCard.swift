//
//  SessionCard.swift
//  Agar
//
//  Created by Joren Alexander Toding on 17/11/26.
//

import SwiftUI

struct SessionCard: View {
    let session: ScanSession

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            VStack(alignment: .leading, spacing: 10) {
                Text("Sesi #\(session.number)")
                    .font(.system(size: 17, weight: .bold))

                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(session.totalCount)")
                        .font(.system(size: 40, weight: .black).width(.expanded))
                        .contentTransition(.numericText())

                    Text("Ayam")
                        .font(.system(size: 16, weight: .black).width(.expanded))
                }
                .lineLimit(1)
                .minimumScaleFactor(0.6)
            }

            Spacer(minLength: 12)

            // date over the counts sharing one left edge, the way the sketch has them.
            // right-aligning the date instead left it starting short of the labels below it
            VStack(alignment: .leading, spacing: 12) {
                Text(session.startedAt, format: .dateTime.day().month(.wide).year())

                // the counts sit at the foot of the card, level with the big number, rather
                // than riding up under the date and leaving the bottom corner empty
                Spacer(minLength: 8)

                // a grid, so the colons sit under each other rather than ragging off the
                // length of the label in front of them
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
            }
            .font(.system(size: 11))
            .foregroundStyle(.secondary)
            .fixedSize(horizontal: true, vertical: false)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(.white, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.cardGray, lineWidth: 1.5)
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
        }))
    }
    .padding()
    .background(Color.surfaceCream)
}
