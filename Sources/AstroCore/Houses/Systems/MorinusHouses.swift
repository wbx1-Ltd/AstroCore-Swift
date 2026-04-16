import Foundation

// Morinus houses: pure 12-fold division of the celestial equator measured
// from ARMC, each equator point projected to the ecliptic via the inverse
// ecliptic-equator transform assuming β = 0.
//
// For cusp n:
//     α_n = ARMC + 30°·(n − 10)
//     λ_n = atan2(sin(α_n), cos(α_n) · cos(ε))
//
// Cusp 10 = MC (M = 0) by construction. Cusp 1 is the ecliptic point at
// α = ARMC + 90°, which is NOT the Ascendant in general — Morinus notably
// does NOT align cusps 1, 4, 7 with ASC, IC, DSC. Latitude never enters the
// formula, so Morinus is defined at every latitude including the poles.
enum MorinusHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let ramc = context.lastDegrees
        let cosEps = TrigDeg.cos(context.obliquityDegrees)

        return (1...12).map { n in
            let alpha = ramc + 30.0 * Double(n - 10)
            return TrigDeg.atan2(TrigDeg.sin(alpha), TrigDeg.cos(alpha) * cosEps)
        }
    }
}
