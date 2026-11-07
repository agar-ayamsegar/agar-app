//
//  FreshnessViewModel.swift
//  Agar
//
//  Created by Bee Wijaya on 04/11/26.
//

import SwiftUI

enum FreshnessState {
    case idle,
         calibrated,
         scanned(Freshness),
         error(String)
}

@Observable
class FreshnessViewModel {
    // MARK: - freshness model coming from services
    private var model: FreshnessModel?

    // MARK: - state variable
    private(set) var state: FreshnessState = .idle
    private(set) var rel: (rel137: Float, rel135: Float)?

    // the empty box must be read before any chicken can be scanned
    var needsBaseline: Bool {
        model?.air == nil
    }

    init() {
        loadModel()
    }

    // baseline from the empty box, every scan is measured against this
    func calibrate(withEmptyBox readings: [Sensor]) {
        // calibrate is mutating, so it has to run on the property itself
        guard model != nil else { return }

        do {
            try model?.calibrate(withEmptyBox: readings)
            state = .calibrated
        } catch {
            state = .error(message(for: error))
        }
    }

    // ble rows -> rel -> mlx
    func scan(_ readings: [Sensor]) {
        guard let model = model else { return }

        do {
            let rel = try model.rel(for: readings)
            self.rel = rel
            state = .scanned(model.process(rel137: rel.rel137, rel135: rel.rel135))
        } catch {
            rel = nil
            state = .error(message(for: error))
        }
    }

    // the baseline lives inside the model, so dropping it means loading the model again
    func reset() {
        model = nil
        rel = nil
        state = .idle
        loadModel()
    }

    private func loadModel() {
        guard let url = Bundle.main.url(forResource: "freshness_model", withExtension: "json") else {
            state = .error("freshness_model.json tidak ada di bundle.")
            return
        }

        do {
            model = try FreshnessModel(modelFileAt: url)
        } catch {
            state = .error("Gagal memuat model: \(error)")
        }
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
            return "Sensor mentok di \(Int(FreshnessModel.adcMax)). Cek kabel GND."
        case .baselineContaminated:
            return "Ayam terbaca lebih bersih dari kotak kosong. Baseline diambil saat kotak masih bau."
        }
    }
}
