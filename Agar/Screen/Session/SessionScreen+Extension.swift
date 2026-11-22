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
        "Jangan tusuk ayam terlebih dahulu"
    ]

    var machinePanel: some View {
        Group {
            switch sessionVM.machineState {
            case .preparing(let progress):
                preparing(progress: progress)
            case .connectionFailed:
                connectionFailed
            case .ready:
                ready
            case .scanning(let chickenNumber, let progress):
                scanning(chickenNumber: chickenNumber, progress: progress)
            case .result(let record):
                result(record)
            case .nextChicken:
                nextChicken
            }
        }
        .padding(32)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(panelBackground, in: .rect(cornerRadius: 24))
        .animation(.easeInOut, value: panelBackground)
        .padding(20)
    }

    var panelBackground: Color {
        switch sessionVM.machineState {
        case .result(let record):
            return record.freshness.tint
        case .preparing, .connectionFailed, .ready, .scanning, .nextChicken:
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
                .font(.system(size: 40, weight: .bold))
                .multilineTextAlignment(.center)
                .minimumScaleFactor(0.6)
                .lineLimit(2)
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

            instructionList

            machineActions
        }
    }

    var connectionFailed: some View {
        VStack(spacing: 16) {
            headline(title: "Gagal Menyiapkan Mesin")

            ChickenIllustration(pose: .preparing, height: 280)

            instructionList

            machineActions
        }
    }

    var instructionList: some View {
        VStack(spacing: 8) {
            ForEach(Self.instructions, id: \.self) { instruction in
                Text(instruction)
            }
        }
        .font(.subheadline)
    }

    var machineActions: some View {
        HStack(spacing: 12) {
            Button("Coba Lagi") {
                Task { await bluetoothVM.connect() }
            }
            .disabled(!sessionVM.canRetry)

            Button("Kembali") {
                pageStateVM.setState(.home)
            }
        }
        .buttonStyle(.borderedProminent)
        .buttonBorderShape(.capsule)
        .tint(.actionBlue)
    }

    var ready: some View {
        VStack(spacing: 8) {
            headline(title: "Mesin Siap Digunakan")
            ChickenIllustration(pose: .ready, height: 300)
        }
    
    }

    var nextChicken: some View {
        VStack(spacing: 8) {
            headline(caption: "Tancapkan", title: "Ayam Selanjutnya")

            ChickenIllustration(pose: .ready, height: 300)
        }
    }

    func scanning(chickenNumber: Int, progress: Double) -> some View {
        VStack(spacing: 16) {
            headline(caption: "Ayam #\(chickenNumber)", title: "Sedang Menganalisa")

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

            if let grade = freshnessVM.grade, let score = freshnessVM.score {
                GradeSlider(score: score, grade: grade, tint: record.freshness.tint)
                    .frame(maxWidth: 420)
                    .layoutPriority(1)
            }

            // smaller with the slider so the bubble text always fits on an iPhone
            ChickenIllustration(pose: record.freshness.pose, height: freshnessVM.grade == nil ? 440 : 240)

            if let instruction = record.freshness.instruction {
                Text(instruction)
                    .font(.title3)
                    .bold()
            }
        }
        .foregroundStyle(.white)
    }
    
    
    
    var sessionHeader: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Sesi Pemeriksaan #\(String(format: "%03d", sessionVM.session.number))")
                .font(.headline)
            Text(sessionVM.session.startedAt, format: .dateTime.day().month(.wide).year())
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .fixedSize(horizontal: true, vertical: false)
    }

    var stats: some View {
        
        VStack(spacing: 8) {
            StatCard(title: "Ayam Masuk", value: Text("\(sessionVM.session.totalCount)"), valueSize: 44)

            HStack(spacing: 8) {
                StatCard(freshness: .fresh, value: sessionVM.session.freshCount)
                StatCard(freshness: .notFresh, value: sessionVM.session.notFreshCount)
            }
        }
        .animation(.default, value: sessionVM.session.totalCount)
    }

    var history: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Riwayat Scan :")
                .font(.caption)
                .foregroundStyle(.secondary)

            ScrollView {
                LazyVStack(spacing: 0) {
                    ForEach(sessionVM.session.records) { record in
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

    // three equal columns, so the rows line up under Waktu / Ayam / Kondisi
    func historyRow(_ record: ScanRecord) -> some View {
        HStack(spacing: 16) {
            Text(record.scannedAt, format: .dateTime.hour().minute().second())
                .frame(maxWidth: .infinity, alignment: .leading)

            Text("#\(record.chickenNumber)")
                .frame(maxWidth: .infinity, alignment: .leading)

            Text(record.freshness.title)
                .foregroundStyle(record.freshness.tint)
                .frame(maxWidth: .infinity, alignment: .leading)
        }
        .font(.subheadline)
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
    }
}
