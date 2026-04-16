import Foundation

// Meridian (Zariel) houses: identical equator division to Morinus, but the
// numbering convention places cusp 1 — not cusp 10 — at the MC.
//
// For cusp n:
//     α_n = ARMC + 30°·(n − 1)
//     λ_n = atan2(sin(α_n), cos(α_n) · cos(ε))
//
// Cusp 1 = MC (M = 0), cusp 7 = IC, but cusp 10 is NOT the MC — it's the
// equator point at ARMC + 270° projected to the ecliptic. Like Morinus, the
// formula ignores latitude and works at every pole.
enum MeridianHouses {
    static func cusps(context: HouseEngine.Context) -> [Double] {
        let ramc = context.lastDegrees
        let cosEps = TrigDeg.cos(context.obliquityDegrees)

        return (1...12).map { n in
            let alpha = ramc + 30.0 * Double(n - 1)
            return TrigDeg.atan2(TrigDeg.sin(alpha), TrigDeg.cos(alpha) * cosEps)
        }
    }
}
