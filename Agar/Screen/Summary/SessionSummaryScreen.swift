//
//  SessionSummaryScreen.swift
//  Agar
//
//  Created by fikrahdamars on 03/11/26.
//

import SwiftUI

struct SessionSummaryScreen: View {
    let session: ScanSession
    var onSave: () -> Void

    var body: some View {
        VStack(spacing: 20) {
            Text("Sesi Selesai")
                .font(.system(size: 44, weight: .bold))

            ChickenIllustration(pose: .done, height: 200)

            HStack(spacing: 12) {
                Text(session.startedAt, format: .dateTime.day().month(.wide).year())
                Text("|")
                Text(session.startedAt, format: .dateTime.hour().minute())
                Text("|")
                Text(session.duration, format: .units(allowed: [.hours, .minutes], width: .wide))
            }
            .font(.subheadline)
            .foregroundStyle(.secondary)

            // a grid, so the three numbers stay on one line even when a label wraps;
            // as an HStack of VStacks the long label pushed its own total out of line
            Grid(horizontalSpacing: 12, verticalSpacing: 6) {
                GridRow {
                    statLabel("Total")
                    statLabel("Segar")
                    statLabel("Tidak Segar")
                }
                GridRow {
                    statValue(session.totalCount)
                    statValue(session.freshCount)
                    statValue(session.notFreshCount)
                }
            }
        }
        .padding(.horizontal, 16)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceCream.ignoresSafeArea())
        .bottomAction {
            Button("Simpan & Lihat Laporan", action: onSave)
                .buttonStyle(.primaryAction)
        }
    }

    private func statLabel(_ title: String) -> some View {
        Text(title)
            .font(.caption)
            .foregroundStyle(.secondary)
            .frame(maxWidth: .infinity)
    }

    private func statValue(_ value: Int) -> some View {
        Text("\(value)")
            .font(.system(size: 28, weight: .bold))
            .contentTransition(.numericText())
            .frame(maxWidth: .infinity)
    }
}


#Preview(traits: .landscapeLeft) {
    let session = ScanSession(
        number: 137,
        startedAt: .now.addingTimeInterval(-45 * 60),
        endedAt: .now,
        records: (1...120).map {
            ScanRecord(chickenNumber: $0, freshness: $0.isMultiple(of: 60) ? .notFresh : .fresh)
        }
    )

    SessionSummaryScreen(session: session) {

    }
}
