import Foundation

extension AstroCalculator {
    /// Compute house cusps and angles for a chart.
    ///
    /// - Parameters:
    ///   - moment: The civil moment of the chart.
    ///   - coordinate: Observer's geographic coordinate.
    ///   - system: Desired house system. Defaults to Placidus (Western mainstream).
    ///   - polarFallback: What to do when `system` is undefined at this latitude.
    /// - Returns: Cusps + angles. If a polar fallback fired,
    ///   `result.resolvedSystem` differs from `result.requestedSystem`.
    public static func houses(
        for moment: CivilMoment,
        coordinate: GeoCoordinate,
        system: HouseSystem = .placidus,
        polarFallback: PolarFallback = .porphyry
    ) throws(AstroError) -> HouseResult {
        try HouseEngine.compute(
            for: moment,
            coordinate: coordinate,
            system: system,
            polarFallback: polarFallback
        )
    }

    /// Compute the 36 Gauquelin sectors.
    ///
    /// Sector numbering follows the library's clockwise reference convention:
    /// sector 1 starts at the Ascendant and counts clockwise.
    ///
    /// Gauquelin sectors are undefined beyond the ecliptic polar circle and
    /// therefore throw `AstroError.houseSystemUndefinedAtLatitude`.
    public static func gauquelinSectors(
        for moment: CivilMoment,
        coordinate: GeoCoordinate
    ) throws(AstroError) -> GauquelinResult {
        try GauquelinEngine.compute(for: moment, coordinate: coordinate)
    }

    /// Compute a full natal chart: planets + houses + angles.
    public static func natalChart(
        for moment: CivilMoment,
        coordinate: GeoCoordinate,
        bodies: Set<CelestialBody> = Set(CelestialBody.allCases),
        system: HouseSystem = .placidus,
        polarFallback: PolarFallback = .porphyry
    ) throws(AstroError) -> NatalChart {
        let positions = try natalPositions(
            for: moment,
            coordinate: coordinate,
            bodies: bodies,
            includeAscendant: true
        )
        let houses = try houses(
            for: moment,
            coordinate: coordinate,
            system: system,
            polarFallback: polarFallback
        )
        return NatalChart(
            positions: positions,
            houses: houses,
            moment: moment,
            coordinate: coordinate
        )
    }
}
