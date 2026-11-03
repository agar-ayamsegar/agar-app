

import SwiftUI


// MARK: - dummy data

enum Fake {

    static func rows(count: Int, mq137: Float, mq135: Float, wobble: Float = 1) -> [Sensor] {
        let pattern: [Float] = [0, 1, -1, 1, 0, -1, 1, -1, 0, 1]

        return (0 ..< count).map { index in
            let nudge = pattern[index % pattern.count] * wobble
            return Sensor(mq137: mq137 + nudge, mq135: mq135 + nudge,
                          rs137: 0, rs135: 0, rel137: 0, rel135: 0,
                          temp: 34, humidity: 60)
        }
    }

    static let emptyBox = rows(count: 120, mq137: 131, mq135: 160)
}


enum FakeChicken: String, CaseIterable, Identifiable {
    case fresh       = "Segar"
    case rotten      = "Busuk"
    case borderline  = "Batas"
    case looseGround = "GND Lepas"
    case tooShort    = "Kurang Data"

    var id: String { rawValue }

    var rows: [Sensor] {
        switch self {
        case .fresh:
            return Fake.rows(count: 60, mq137: 150, mq135: 192)
        case .rotten:
            return Fake.rows(count: 60, mq137: 239, mq135: 648)
        case .borderline:
            // sits exactly where the model changes its mind, wobbling +/- 9
            return Fake.rows(count: 60, mq137: 200, mq135: 289, wobble: 9)
        case .looseGround:
            return Fake.rows(count: 60, mq137: 239, mq135: 1023)
        case .tooShort:
            return Fake.rows(count: 3, mq137: 239, mq135: 648)
        }
    }
}


enum Source: String, CaseIterable, Identifiable {
    case dummy = "Data Palsu"
    case esp32 = "ESP32"

    var id: String { rawValue }
}



struct ConnectScreen: View {
    @Environment(BluetoothViewModel<Sensor>.self) var bluetoothVM

    @State private var source: Source = .dummy
    @State private var model: FreshnessModel?
    @State private var chicken: FakeChicken = .rotten
    @State private var status = "memuat model..."
    @State private var verdict: Freshness?
    @State private var detail = ""


    
    private var baselineRows: [Sensor] {
        switch source {
        case .dummy: return Fake.emptyBox
        case .esp32: return bluetoothVM.characteristics
        }
    }

    private var chickenRows: [Sensor] {
        switch source {
        case .dummy: return chicken.rows
        case .esp32: return bluetoothVM.characteristics
        }
    }

    
    private var canPress: Bool {
        if source == .dummy {
            return true
        }
        return bluetoothVM.characteristics.count >= FreshnessModel.rowsPerWindow
    }

    
    private var needsBaseline: Bool {
        model?.air == nil
    }

    private var buttonLabel: String {
        if !canPress {
            let missing = FreshnessModel.rowsPerWindow - bluetoothVM.characteristics.count
            return "Tunggu \(missing) baris lagi"
        }
        if needsBaseline {
            return "1. Ambil Baseline (kotak kosong)"
        }
        return "2. Scan Ayam"
    }

    var body: some View {
        VStack(spacing: 16) {
            Picker("Sumber", selection: $source) {
                ForEach(Source.allCases) { option in
                    Text(option.rawValue).tag(option)
                }
            }
            .pickerStyle(.segmented)

            if source == .esp32 {
                AppButton(label: "Connect", style: .secondary) {
                    Task {
                        await bluetoothVM.connect()
                    }
                }

                Text("\(bluetoothVM.characteristics.count) baris masuk")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                Picker("Ayam", selection: $chicken) {
                    ForEach(FakeChicken.allCases) { option in
                        Text(option.rawValue).tag(option)
                    }
                }
                .pickerStyle(.segmented)
                .disabled(needsBaseline)
            }

            AppButton(label: buttonLabel) {
                if needsBaseline {
                    takeBaseline()
                } else {
                    scanChicken()
                }
            }
            .disabled(!canPress)

            Text(status)
                .font(.callout)
                .multilineTextAlignment(.center)

            if let verdict {
                Text(verdict.title)
                    .font(.largeTitle)
                    .bold()
                    .foregroundStyle(verdict.tint)

                Text(detail)
                    .font(.caption)
                    .monospaced()
                    .foregroundStyle(.secondary)
            }

            if !needsBaseline {
                Button("Ulangi baseline") {
                    resetBaseline()
                }
                .font(.caption)
            }

            Spacer()
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .task {
            loadModel()
        }
        .onChange(of: source) {
            
            resetBaseline()
        }
    }


   

    private func loadModel() {
        guard model == nil else { return }

        guard let url = Bundle.main.url(forResource: "freshness_model", withExtension: "json") else {
            status = "freshness_model.json tidak ada di bundle"
            return
        }

        do {
            model = try FreshnessModel(modelFileAt: url)
            status = "Model siap. Ambil baseline dulu."
        } catch {
            status = "Gagal memuat model: \(error)"
        }
    }

    private func takeBaseline() {
        do {
            try model?.calibrate(withEmptyBox: baselineRows)

            if let air = model?.air {
                status = String(format: "Baseline siap. Rs %.2f / %.2f\n%@",
                                air.rs137, air.rs135, nextStepHint)
            }

          
            if source == .esp32 {
                bluetoothVM.clear()
            }
        } catch {
            status = message(for: error)
        }
    }

    private func scanChicken() {
        guard let model else { return }

        do {
            let rel = try model.rel(for: chickenRows)
            verdict = model.process(rel137: rel.rel137, rel135: rel.rel135)
            detail = String(format: "rel_137 %.3f    rel_135 %.3f", rel.rel137, rel.rel135)
            status = "Selesai. Ganti ayam lalu scan lagi."
        } catch {
            verdict = nil
            detail = ""
            status = message(for: error)
        }
    }

    
    private func resetBaseline() {
        verdict = nil
        detail = ""
        model = nil
        loadModel()

        if source == .esp32 {
            bluetoothVM.clear()
        }
    }

    private var nextStepHint: String {
        if source == .esp32 {
            return "Masukkan ayam, tutup kotak, tunggu 1 menit."
        }
        return "Pilih ayam, lalu scan."
    }

    private func message(for error: Error) -> String {
        guard let problem = error as? FreshnessModel.Problem else {
            return "\(error)"
        }

        switch problem {
        case .notCalibrated:
            return "Ambil baseline kotak kosong dulu."
        case .tooFewReadings:
            return "Data kurang. Butuh minimal \(FreshnessModel.rowsPerWindow) baris."
        case .sensorSaturated:
            return "Sensor mentok di 1023. Cek kabel GND."
        case .baselineContaminated:
            return "Ayam terbaca lebih bersih dari kotak kosong. Baseline diambil saat kotak masih bau."
        }
    }
}


#Preview {
    ConnectScreen()
        .environment(BluetoothViewModel<Sensor>())
}
