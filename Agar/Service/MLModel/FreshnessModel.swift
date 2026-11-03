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

    private let vref: Float = 5.0
    private let vcc: Float = 5.0
    private let rl137: Float = 1.0
    private let rl135: Float = 2.0

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

    private func resistance(raw: Float, rl: Float) -> Float {
        let volts = max(raw * vref / 1023, 0.01)
        return rl * (vcc - volts) / volts
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

        air = (median(flat.map { resistance(raw: $0.mq137, rl: rl137) }),
               median(flat.map { resistance(raw: $0.mq135, rl: rl135) }))
    }

    func rel(for readings: [Sensor]) throws -> (rel137: Float, rel135: Float) {
        guard let air else { throw Problem.notCalibrated }

        let window = readings.suffix(Self.rowsPerWindow)
        guard window.count >= 5 else { throw Problem.tooFewReadings }
        guard window.allSatisfy({ $0.mq137 < 1023 && $0.mq135 < 1023 }) else {
            throw Problem.sensorSaturated
        }

        let rel137 = median(window.map { resistance(raw: $0.mq137, rl: rl137) }) / air.rs137
        let rel135 = median(window.map { resistance(raw: $0.mq135, rl: rl135) }) / air.rs135

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
