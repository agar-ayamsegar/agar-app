//
//  SessionScreen+Extension.swift
//  Agar
//
//  Created by Fikrah Damar Huda on 30/10/26.
//

import SwiftUI


extension SessionScreen {
    private static let instructions = [
        "Sambungkan Dengan Bluetooth",
        "Jangan Masukkan Ayam Dulu",
        "Biarkan mesin kondisi tertutup",
    ]

    var machinePanel: some View {
        DetailPanel {
            Group {
                switch viewModel.machineState {
                case .preparing(let progress):
                    preparing(progress: progress)
                case .connectionFailed:
                    preparing(progress: 0)
                case .ready:
                    ready
                case .scanning(let chickenNumber, let progress):
                    scanning(chickenNumber: chickenNumber, progress: progress)
                case .result(let record):
                    result(record)
                }
            }
            .padding(32)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(panelBackground, in: .rect(cornerRadius: 24))
            .animation(.easeInOut, value: panelBackground)
        }
    }

    var panelBackground: Color {
        switch viewModel.machineState {
        case .result(let record):
            return record.freshness.tint
        case .preparing, .connectionFailed, .ready, .scanning:
            return .white
        }
    }

    func headline(caption: String? = nil, title: String) -> some View {
        VStack(spacing: 0) {
            if let caption {
                Text(caption)
                    .font(.title3)
            }

            Text(title)
                .font(.system(size: 72, weight: .bold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(1)
        }
    }

    func preparing(progress: Double) -> some View {
        VStack(spacing: 16) {
            headline(title: "Menyiapkan Mesin")

            VStack(spacing: 16) {
                ChickenIllustration(pose: .preparing, height: 280)

                ProgressView(value: progress)
                    .tint(.black)
            }
            .frame(maxWidth: 420)

            VStack(spacing: 8) {
                ForEach(Self.instructions, id: \.self) { instruction in
                    Text(instruction)
                }
            }
            .font(.subheadline)

            HStack(spacing: 12) {
                Button("Coba Lagi", action: viewModel.retry)
                    .disabled(!viewModel.canRetry)

                Button("Kembali", action: onBack)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .tint(.actionBlue)
        }
    }

    var ready: some View {
        VStack(spacing: 8) {
            headline(caption: "Mesin Siap Digunakan", title: "Masukkan Ayam")

            ChickenIllustration(pose: .ready, height: 420)
        }
    
    }

    func scanning(chickenNumber: Int, progress: Double) -> some View {
        VStack(spacing: 16) {
            headline(caption: "Ayam #\(chickenNumber)", title: "Sedang Memindai")

            ChickenIllustration(pose: .scanning, height: 300)

            ProgressView(value: progress)
                .tint(.blue)
            
            Text("Tunggu dulu ya ...")
                .font(.headline)
        }
        .frame(maxWidth: 460)
    }

    func result(_ record: ScanRecord) -> some View {
        VStack(spacing: 16) {
            headline(caption: "Ayam #\(record.chickenNumber)", title: record.freshness.title)

            ChickenIllustration(pose: record.freshness.pose, height: 440)

            if let instruction = record.freshness.instruction {
                Text(instruction)
                    .font(.title3)
                    .bold()
            }
        }
        .foregroundStyle(.white)
    }

    // header, stats, riwayat scan, end button
    var sidebar: some View {
        VStack(spacing: 16) {
            header

            stats

            history

            Button {
                onEnd(viewModel.session)
            } label: {
                Text("Akhiri Sesi")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .buttonBorderShape(.capsule)
            .controlSize(.large)
            .tint(.actionBlue)
            .disabled(!viewModel.canEndSession)
        }
    }

    var header: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Sesi Scan Ayam #\(viewModel.session.number)")
                .font(.caption)
                .bold()
                .foregroundStyle(.secondary)

            Text(viewModel.session.startedAt, format: .dateTime.day().month(.wide).year())
                .font(.title3)
                .bold()

            Text("Sesi Mulai : \(viewModel.session.startedAt, format: .dateTime.hour().minute())")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 4)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var stats: some View {
        VStack(spacing: 8) {
            statCard(title: "Ayam Masuk", value: viewModel.session.totalCount, valueSize: 44)

            HStack(spacing: 8) {
                statCard(freshness: .fresh, value: viewModel.session.freshCount)
                statCard(freshness: .notFresh, value: viewModel.session.notFreshCount)
            }
        }
        .animation(.default, value: viewModel.session.totalCount)
    }

    func statCard(freshness: Freshness, value: Int) -> some View {
        statCard(title: freshness.title, value: value, tint: freshness.tint, background: freshness.lightTint)
    }

    func statCard(
        title: String,
        value: Int,
        valueSize: CGFloat = 24,
        tint: Color = .black,
        background: Color = .cardGray
    ) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(tint.opacity(0.75))

            Text("\(value)")
                .font(.system(size: valueSize, weight: .bold))
                .foregroundStyle(tint)
                .contentTransition(.numericText())
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: .rect(cornerRadius: 16))
    }

    var history: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Riwayat Scan :")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(viewModel.session.records) { record in
                        Divider()
                        historyRow(record)
                    }
                }
            }
            .defaultScrollAnchor(.bottom)
        }
        .padding(14)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color.cardGray, in: .rect(cornerRadius: 16))
    }

    func historyRow(_ record: ScanRecord) -> some View {
        HStack(spacing: 16) {
            Text(record.scannedAt, format: .dateTime.hour().minute().second())
                .frame(width: 80, alignment: .leading)

            Text("#\(record.chickenNumber)")
                .frame(width: 48, alignment: .leading)

            Text(record.freshness.title)
                .foregroundStyle(record.freshness.tint)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
        .padding(.vertical, 8)
    }
}
