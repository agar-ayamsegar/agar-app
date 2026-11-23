//
//  SessionTotalsCard.swift
//  Agar
//

import SwiftUI

/// The white block at the top of a session: how many birds, then the two colour counts.
///
/// Shared by the recap detail screen and the riwayat sheet. They were built separately and
/// drifted, which is why the sheet had its totals loose on the background while the detail
/// screen had them boxed.
struct SessionTotalsCard: View {
    let total: Int
    let freshCount: Int
    let notFreshCount: Int
    var countSize: CGFloat = 64

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .lastTextBaseline, spacing: 8) {
                Text("\(total)")
                    .font(.system(size: countSize, weight: .black).width(.expanded))
                    .contentTransition(.numericText())

                Text("Ayam")
                    .font(.system(size: 20, weight: .black).width(.expanded))
            }

            HStack(spacing: 10) {
                StatCard(freshness: .fresh, value: freshCount)
                StatCard(freshness: .notFresh, value: notFreshCount)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(.white, in: .rect(cornerRadius: 20))
    }
}

extension SessionTotalsCard {
    init(session: ScanSession, countSize: CGFloat = 64) {
        self.init(
            total: session.totalCount,
            freshCount: session.freshCount,
            notFreshCount: session.notFreshCount,
            countSize: countSize
        )
    }
}


#Preview {
    VStack {
        SessionTotalsCard(total: 130, freshCount: 128, notFreshCount: 2)
        SessionTotalsCard(total: 0, freshCount: 0, notFreshCount: 0)
    }
    .padding()
    .background(Color.surfaceCream)
}
