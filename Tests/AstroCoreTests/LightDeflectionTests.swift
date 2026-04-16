import Testing
import Foundation

@testable import AstroCore

@Suite("Light Deflection Tests")
struct LightDeflectionTests {
    // Physical bounds: deflection is non-negative for elongations >= 1°
    @Test func deflectionPhysicalBounds() {
        // Typical planetary elongations (>2° from Sun) must yield positive deflection
        let elongations = [5.0, 10.0, 30.0, 45.0, 90.0, 120.0, 180.0]
        for e in elongations {
            let d = PlanetaryPosition.gravitationalDeflectionArcsec(elongationDeg: e)
            #expect(d > 0.0, "Expected positive deflection at elongation \(e)°")
        }
    }

    // Formula: 0.00407 / sin(elongation)
    @Test func deflectionFormula() {
        // At 90°: sin(90°) = 1 → deflection ≈ 0.00407"
        let at90 = PlanetaryPosition.gravitationalDeflectionArcsec(elongationDeg: 90.0)
        #expect(abs(at90 - 0.00407) < 1e-6)

        // At 10°: 0.00407 / sin(10°) ≈ 0.02343"
        let at10 = PlanetaryPosition.gravitationalDeflectionArcsec(elongationDeg: 10.0)
        let expected10 = 0.00407 / Foundation.sin(10.0 * .pi / 180.0)
        #expect(abs(at10 - expected10) < 1e-6)

        // Below 1° threshold: returns 0
        let below = PlanetaryPosition.gravitationalDeflectionArcsec(elongationDeg: 0.5)
        #expect(below == 0.0)

        // Exactly 1° is allowed (not below threshold)
        let atOne = PlanetaryPosition.gravitationalDeflectionArcsec(elongationDeg: 1.0)
        #expect(atOne > 0.0)
    }

    // FK5 frame correction constant must be -0.09033"
    @Test func fk5CorrectionApplied() {
        let result = PlanetaryPosition.fk5LongitudeCorrectionArcsec()
        #expect(abs(result - (-0.09033)) < 0.001)
    }

    // Residual correction must be non-zero for Mercury at J2000
    @Test func residualCorrectionApplied() {
        let correction = PlanetResiduals.correctionArcsec(for: .mercury, t: 0.0)
        #expect(correction != 0.0, "Mercury residual correction should be non-zero at J2000")
    }
}
