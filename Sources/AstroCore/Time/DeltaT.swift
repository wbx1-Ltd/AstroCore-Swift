import Foundation

// ΔT = TT - UT1 (seconds)
// Historical ranges use published polynomial fits.
// Modern and near-future ranges use interpolated official samples.
enum DeltaT {
    private static let coeffs1800To1860 = [
        13.72, -0.332447, 0.0068612, 0.0041116,
        -0.00037436, 0.0000121272, -0.0000001699, 0.000000000875,
    ]
    private static let coeffs1860To1900 = [
        7.62, 0.5737, -0.251754, 0.01680668,
        -0.0004473624, 1.0 / 233174.0,
    ]
    private static let coeffs1900To1920 = [
        -2.79, 1.494119, -0.0598939, 0.0061966, -0.000197,
    ]
    private static let coeffs1920To1941 = [21.20, 0.84493, -0.076100, 0.0020936]
    private static let coeffs1941To1961 = [29.07, 0.407, -1.0 / 233.0, 1.0 / 2547.0]
    private static let coeffs1961To1986 = [45.45, 1.067, -1.0 / 260.0, -1.0 / 718.0]
    private static let coeffs1986To2005 = [
        63.86, 0.3345, -0.060374, 0.0017275,
        0.000651814, 0.00002373599,
    ]
    private static let firstOfficialSampleYear = DeltaTOfficialTable.samples[0].decimalYear
    private static let lastOfficialSampleYear = DeltaTOfficialTable.samples[DeltaTOfficialTable.samples.count - 1].decimalYear
    private static let lastOfficialSampleValue = DeltaTOfficialTable.samples[DeltaTOfficialTable.samples.count - 1].deltaTSeconds

    /// Compute ΔT in seconds for a given decimal year.
    static func deltaT(decimalYear y: Double) -> Double {
        if y < 1800 || y > 2100 {
            if y < 1800 { return deltaT(decimalYear: 1800) }
            return deltaT(decimalYear: 2100)
        }

        if let modern = interpolatedOfficialDeltaT(decimalYear: y) {
            return modern
        }

        if y < 1860 {
            let t = y - 1800
            return horner(t, coeffs: coeffs1800To1860)
        }

        if y < 1900 {
            let t = y - 1860
            return horner(t, coeffs: coeffs1860To1900)
        }

        if y < 1920 {
            let t = y - 1900
            return horner(t, coeffs: coeffs1900To1920)
        }

        if y < 1941 {
            let t = y - 1920
            return horner(t, coeffs: coeffs1920To1941)
        }

        if y < 1961 {
            let t = y - 1950
            return horner(t, coeffs: coeffs1941To1961)
        }

        if y < 1986 {
            let t = y - 1975
            return horner(t, coeffs: coeffs1961To1986)
        }

        if y < 2005 {
            let t = y - 2000
            return horner(t, coeffs: coeffs1986To2005)
        }

        return futureDeltaT(decimalYear: y)
    }

    private static func horner(_ x: Double, coeffs: [Double]) -> Double {
        var result = coeffs[coeffs.count - 1]
        for i in stride(from: coeffs.count - 2, through: 0, by: -1) {
            result = result * x + coeffs[i]
        }
        return result
    }

    private static func interpolatedOfficialDeltaT(decimalYear y: Double) -> Double? {
        guard y >= firstOfficialSampleYear, y <= lastOfficialSampleYear else {
            return nil
        }
        let samples = DeltaTOfficialTable.samples
        if y == firstOfficialSampleYear {
            return samples[0].deltaTSeconds
        }

        var low = 0
        var high = samples.count - 1
        while low <= high {
            let mid = (low + high) / 2
            let sampleYear = samples[mid].decimalYear
            if sampleYear == y {
                return samples[mid].deltaTSeconds
            }
            if sampleYear < y {
                low = mid + 1
            } else {
                high = mid - 1
            }
        }

        let upperIndex = min(low, samples.count - 1)
        let lowerIndex = max(upperIndex - 1, 0)
        let lower = samples[lowerIndex]
        let upper = samples[upperIndex]
        let span = upper.decimalYear - lower.decimalYear
        guard span > 0 else { return lower.deltaTSeconds }
        let fraction = (y - lower.decimalYear) / span
        return lower.deltaTSeconds + (upper.deltaTSeconds - lower.deltaTSeconds) * fraction
    }

    private static func futureDeltaT(decimalYear y: Double) -> Double {
        let base = futureCubic(decimalYear: y)
        if y <= lastOfficialSampleYear + 100.0 {
            let anchor = futureCubic(decimalYear: lastOfficialSampleYear)
            return base + (anchor - lastOfficialSampleValue) * (y - (lastOfficialSampleYear + 100.0)) * 0.01
        }
        return base
    }

    private static func futureCubic(decimalYear y: Double) -> Double {
        let b = y - 2000.0
        return b * b * b * 121.0 / 30_000_000.0
            + b * b / 1250.0
            + b * 521.0 / 3000.0
            + 64.0
    }
}
