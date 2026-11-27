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
        HStack {
            VStack(alignment: .leading) {
                Text(verbatim: "Sesi #\(session.number)")
                    .font(.system(size: 16, weight: .bold))
                
                Spacer()
                
                HStack(alignment: .lastTextBaseline, spacing: 6) {
                    Text("\(session.totalCount)")
                        .font(.system(size: 34, weight: .black).width(.expanded))
                        .contentTransition(.numericText())

                    Text("Ayam")
                        .font(.system(size: 16, weight: .black).width(.expanded))
                }
                .lineLimit(1)
            }
            
            Spacer()
            
            VStack(alignment: .leading) {
                Text(session.startedAt, format: .dateTime.day().month(.wide).year())
                    .font(.system(size: 11, weight: .thin))

                Spacer()
                
                Grid(alignment: .leading, horizontalSpacing: 4, verticalSpacing: 2) {
                    GridRow {
                        Text("Segar")
                        Text(verbatim: ": \(session.freshCount)")
                    }
                    GridRow {
                        Text("Tidak Segar")
                        Text(verbatim: ": \(session.notFreshCount)")
                    }
                }
                .font(.system(size: 11, weight: .thin))
                .padding(.bottom, 4)
                .padding(.trailing, 7)
            }
        }
        .frame(height: 90)
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(.white, in: .rect(cornerRadius: 18))
        .overlay {
            RoundedRectangle(cornerRadius: 18)
                .strokeBorder(Color.black.opacity(0.2), lineWidth: 1.5)
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
