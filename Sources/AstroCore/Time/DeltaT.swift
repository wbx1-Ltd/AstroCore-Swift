import Foundation

/// ΔT = TT - UT1 (seconds)
/// Historical ranges use published polynomial fits.
/// Modern and near-future ranges use interpolated official samples.
enum DeltaT {
    private static let firstHistoricSampleYear = DeltaTHistoricTable.samples[0].decimalYear
    private static let lastHistoricSampleYear = DeltaTHistoricTable.samples[DeltaTHistoricTable.samples.count - 1].decimalYear
    private static let firstOfficialSampleYear = DeltaTOfficialTable.samples[0].decimalYear
    private static let lastOfficialSampleYear = DeltaTOfficialTable.samples[DeltaTOfficialTable.samples.count - 1].decimalYear
    private static let lastOfficialSampleValue = DeltaTOfficialTable.samples[DeltaTOfficialTable.samples.count - 1].deltaTSeconds

    /// Compute ΔT in seconds for a given decimal year.
    static func deltaT(decimalYear y: Double) -> Double {
        if y < 1800 || y > 2100 {
            if y < 1800 { return deltaT(decimalYear: 1800) }
            return deltaT(decimalYear: 2100)
        }

        if let historic = interpolatedSampleDeltaT(
            decimalYear: y,
            samples: DeltaTHistoricTable.samples
        ) {
            return historic
        }

        if let modern = interpolatedSampleDeltaT(
            decimalYear: y,
            samples: DeltaTOfficialTable.samples
        ) {
            return modern
        }

        if y > lastHistoricSampleYear && y < firstOfficialSampleYear {
            let lower = DeltaTHistoricTable.samples[DeltaTHistoricTable.samples.count - 1]
            let upper = DeltaTOfficialTable.samples[0]
            return interpolatedValue(
                decimalYear: y,
                lower: lower,
                upper: upper
            )
        }

        return futureDeltaT(decimalYear: y)
    }

    private static func interpolatedSampleDeltaT(
        decimalYear y: Double,
        samples: [(decimalYear: Double, deltaTSeconds: Double)]
    ) -> Double? {
        guard let first = samples.first, let last = samples.last,
              y >= first.decimalYear, y <= last.decimalYear
        else {
            return nil
        }
        if y == first.decimalYear {
            return first.deltaTSeconds
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
        return interpolatedValue(
            decimalYear: y,
            lower: samples[lowerIndex],
            upper: samples[upperIndex]
        )
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
        return b * b * b * 121.0 / 30000000.0
            + b * b / 1250.0
            + b * 521.0 / 3000.0
            + 64.0
    }

    private static func interpolatedValue(
        decimalYear y: Double,
        lower: (decimalYear: Double, deltaTSeconds: Double),
        upper: (decimalYear: Double, deltaTSeconds: Double)
    ) -> Double {
        let span = upper.decimalYear - lower.decimalYear
        guard span > 0 else { return lower.deltaTSeconds }
        let fraction = (y - lower.decimalYear) / span
        return lower.deltaTSeconds + (upper.deltaTSeconds - lower.deltaTSeconds) * fraction
    }
}
