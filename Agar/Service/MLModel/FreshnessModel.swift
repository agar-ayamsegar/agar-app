import Foundation
import MLX

struct FreshnessModel {

    struct Model: Decodable {
        let features: [String]
        let scalerMean: [Double]
        let scalerScale: [Double]
        let coef: [Double]
        let intercept: Double
        let threshold: Double
    }

    enum Problem: Error {
        case notCalibrated
        case tooFewReadings
        case sensorSaturated
        case baselineContaminated
    }

    // the esp32 adc is 12 bit; an uno sketch sends 0-1023, so retune this if the board changes
    static let adcMax: Float = 4095
    static let rowsPerWindow = 40
    let model: Model

    private(set) var air: (rs137: Float, rs135: Float)?

    private let mean: MLXArray
    private let scale: MLXArray
    private let coef: MLXArray
    private let intercept: MLXArray

    init(modelFileAt url: URL) throws {
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        let contents = try Data(contentsOf: url)
        let loaded = try decoder.decode(Model.self, from: contents)

        model = loaded
        mean = MLXArray(converting: loaded.scalerMean)
        scale = MLXArray(converting: loaded.scalerScale)
        coef = MLXArray(converting: loaded.coef)
        intercept = MLXArray(Float(loaded.intercept))
        
    }

    private func median(_ values: [Float]) -> Float {
        let sorted = values.sorted()
        let middle = sorted.count / 2

        if sorted.count % 2 == 1 {
            return sorted[middle]
        }
        return (sorted[middle - 1] + sorted[middle]) / 2
    }

    mutating func calibrate(withEmptyBox readings: [Sensor]) throws {
        let flat = readings.dropLast(7).suffix(Self.rowsPerWindow)
        guard flat.count >= 5 else { throw Problem.tooFewReadings }

        // rs comes off the wire in kOhm, the firmware already undid the divider and the adc scale
        let rs137 = median(flat.map(\.rs137))
        let rs135 = median(flat.map(\.rs135))
        guard rs137 > 0, rs135 > 0 else { throw Problem.sensorSaturated }

        air = (rs137, rs135)
    }

    func rel(for readings: [Sensor]) throws -> (rel137: Float, rel135: Float) {
        guard let air else { throw Problem.notCalibrated }

        let window = readings.suffix(Self.rowsPerWindow)
        guard window.count >= 5 else { throw Problem.tooFewReadings }
        // raw counts are only kept for this: a railed adc reads a floor, not a smell
        guard window.allSatisfy({ $0.mq137 < Self.adcMax && $0.mq135 < Self.adcMax }) else {
            throw Problem.sensorSaturated
        }

        let rel137 = median(window.map(\.rs137)) / air.rs137
        let rel135 = median(window.map(\.rs135)) / air.rs135

        guard rel137 < 1.10, rel135 < 1.10 else { throw Problem.baselineContaminated }

        return (rel137, rel135)
    }

    func process(_ readings: [Sensor]) throws -> Freshness {
        let rel = try rel(for: readings)
        return process(rel137: rel.rel137, rel135: rel.rel135)
    }

    func process(rel137: Float, rel135: Float) -> Freshness {
        let raw = MLXArray([rel135, rel137])
        let z = (raw - mean) / scale
        let logit = (coef * z).sum() + intercept
        let p = sigmoid(logit)

        if p.item(Float.self) >= Float(model.threshold) {
            return .notFresh
        }
        return .fresh
    }
}
