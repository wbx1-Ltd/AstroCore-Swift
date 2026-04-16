import Foundation

// Alcabitius houses: trisect the ASC's semi-diurnal arc in sidereal time,
// then compute the Ascendant at each offset ARMC. Structurally identical to
// Koch but keyed on the ASC's own semi-arc rather than the MC's.
//
// SA_ASC = arccos(−tan(φ) · tan(δ_ASC))
// SA_DSC = 180° − SA_ASC        (DSC has declination −δ_ASC)
//
//   cusp 11 = ASC(ARMC − 2·SA_ASC/3)
//   cusp 12 = ASC(ARMC − SA_ASC/3)
//   cusp 2  = ASC(ARMC + SA_DSC/3)
//   cusp 3  = ASC(ARMC + 2·SA_DSC/3)
//
// Cusps 5, 6, 8, 9 are the 180° opposites. Angles sit on 1/4/7/10 as usual.
//
// Precondition: the dispatcher's polar pre-check must route |φ| > ~66° away,
// where SA_ASC becomes undefined.
enum AlcabitiusHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let ramc = context.lastDegrees
        let epsilon = context.obliquityDegrees
        let phi = context.coordinate.latitude
        let mc = context.angles.midheaven
        let asc = context.angles.ascendant

        let sinDeltaAsc = TrigDeg.sin(epsilon) * TrigDeg.sin(asc)
        let cos2Delta = 1.0 - sinDeltaAsc * sinDeltaAsc
        let cosDelta = cos2Delta.squareRoot()
        let tanDelta = sinDeltaAsc / cosDelta
        let polarFactor = TrigDeg.tan(phi) * tanDelta
        let clamped = max(-1.0, min(1.0, -polarFactor))
        let saAsc = TrigDeg.acos(clamped)
        let saDsc = 180.0 - saAsc

        var cusps = [Double](repeating: 0.0, count: 12)
        cusps[0] = asc                                              // 1
        cusps[3] = AngleMath.normalized(degrees: mc + 180.0)        // 4
        cusps[6] = AngleMath.normalized(degrees: asc + 180.0)       // 7
        cusps[9] = mc                                               // 10

        cusps[10] = ascendantAt(offset: -2.0 * saAsc / 3.0, ramc: ramc, phi: phi, eps: epsilon)  // 11
        cusps[11] = ascendantAt(offset: -saAsc / 3.0, ramc: ramc, phi: phi, eps: epsilon)        // 12
        cusps[1] = ascendantAt(offset: saDsc / 3.0, ramc: ramc, phi: phi, eps: epsilon)          // 2
        cusps[2] = ascendantAt(offset: 2.0 * saDsc / 3.0, ramc: ramc, phi: phi, eps: epsilon)    // 3

        cusps[4] = AngleMath.normalized(degrees: cusps[10] + 180.0)  // 5
        cusps[5] = AngleMath.normalized(degrees: cusps[11] + 180.0)  // 6
        cusps[7] = AngleMath.normalized(degrees: cusps[1] + 180.0)   // 8
        cusps[8] = AngleMath.normalized(degrees: cusps[2] + 180.0)   // 9

        return cusps
    }

    private static func ascendantAt(
        offset: Double, ramc: Double, phi: Double, eps: Double
    ) -> Double {
        AscendantEngine.ascendantLongitude(
            lastDegrees: AngleMath.normalized(degrees: ramc + offset),
            trueObliquityDegrees: eps,
            latitudeDegrees: phi
        )
    }
}
