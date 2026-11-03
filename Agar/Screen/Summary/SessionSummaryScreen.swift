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
        VStack(spacing: 24) {
            Text("Sesi Selesai")
                .font(.system(size: 72, weight: .bold))

            ChickenIllustration(pose: .done, height: 220)

            HStack(spacing: 16) {
                Text(session.startedAt, format: .dateTime.day().month(.wide).year())
                Text("|")
                Text(session.startedAt, format: .dateTime.hour().minute())
                Text("|")
                Text(session.duration, format: .units(allowed: [.hours, .minutes], width: .wide))
            }
            .font(.title3)
            .foregroundStyle(.secondary)

            HStack(spacing: 48) {
                stat(title: "Total Ayam diperiksa", value: Text("\(session.totalCount)"))
                stat(title: "Segar", value: Text("\(session.freshCount)"))
                stat(title: "Tidak Segar", value: Text("\(session.notFreshCount)"))
                stat(
                    title: "Waktu/Ayam",
                    value: Text(session.durationPerChicken, format: .units(allowed: [.seconds], width: .abbreviated))
                )
            }

            Button(action: onSave) {
                Text("Simpan & Lihat Laporan")
                    .frame(width: 320)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(.actionBlue)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color.surfaceCream.ignoresSafeArea())
    }

    private func stat(title: String, value: Text) -> some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            value
                .font(.title)
                .bold()
        }
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
