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
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Sesi #\(session.number)")
                    .font(.headline)

                Spacer()

                Text(session.startedAt, format: .dateTime.day().month(.wide).year())
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .lastTextBaseline) {
                Text("\(session.totalCount)")
                    .font(.system(size: 36, weight: .bold))
                Text("Ayam")
                    .font(.headline)

                Spacer()

                VStack(alignment: .leading, spacing: 2) {
                    Text("Segar : \(session.freshCount)")
                    Text("Tidak Segar : \(session.notFreshCount)")
                }
                .font(.caption2)
                .foregroundStyle(.secondary)
            }
        }
        .padding()
        .background(isSelected ? Color.cardGray : .clear, in: .rect(cornerRadius: 16))
        .contentShape(.rect)
    }
    
}
