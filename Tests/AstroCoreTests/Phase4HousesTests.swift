import Foundation
import Testing

@testable import AstroCore

// Phase 4: Alcabitius, Topocentric, Morinus, Meridian.
//
// Alcabitius and Topocentric keep angles on 1/4/7/10; Morinus and Meridian do
// NOT — their cusps are pure equator divisions and only satisfy the weaker
// invariants (opposites 180° apart, arcs partition 360°).

private enum Fixtures {
    static func parisMoment() throws -> CivilMoment {
        try CivilMoment(
            year: 1995, month: 4, day: 10,
            hour: 14, minute: 30,
            timeZoneIdentifier: "Europe/Paris"
        )
    }
    static func paris() throws -> GeoCoordinate {
        try GeoCoordinate(latitude: 48.85, longitude: 2.35)
    }
}

@Suite("Alcabitius houses")
struct AlcabitiusTests {
    @Test func anglesAlignAndInvariantsHold() throws {
        let moment = try Fixtures.parisMoment()
        let coord = try Fixtures.paris()
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .alcabitius
        )

        #expect(abs(result.cusps[0].eclipticLongitude - result.angles.ascendant) < 1e-7)
        #expect(abs(result.cusps[3].eclipticLongitude - result.angles.imumCoeli) < 1e-7)
        #expect(abs(result.cusps[6].eclipticLongitude - result.angles.descendant) < 1e-7)
        #expect(abs(result.cusps[9].eclipticLongitude - result.angles.midheaven) < 1e-7)

        for i in 0..<6 {
            let diff = AngleMath.normalized(
                degrees: result.cusps[i + 6].eclipticLongitude
                    - result.cusps[i].eclipticLongitude
            )
            #expect(abs(diff - 180.0) < 1e-7)
        }
    }

    @Test func fallsBackAtArctic() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 72.0, longitude: 0.0)
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .alcabitius,
            polarFallback: .wholeSign
        )
        #expect(result.resolvedSystem == .wholeSign)
    }
}

@Suite("Topocentric houses")
struct TopocentricTests {
    @Test func anglesAlignAndInvariantsHold() throws {
        let moment = try Fixtures.parisMoment()
        let coord = try Fixtures.paris()
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .topocentric
        )
        #expect(abs(result.cusps[0].eclipticLongitude - result.angles.ascendant) < 1e-7)
        #expect(abs(result.cusps[9].eclipticLongitude - result.angles.midheaven) < 1e-7)
    }

    // Topocentric is a closed-form approximation of Placidus — they should
    // agree to <1° at mid latitudes.
    @Test func approximatesPlacidus() throws {
        let moment = try Fixtures.parisMoment()
        let coord = try Fixtures.paris()
        let topo = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .topocentric
        )
        let plac = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .placidus
        )
        for i in [10, 11, 1, 2] {   // cusps 11, 12, 2, 3
            var d = abs(topo.cusps[i].eclipticLongitude - plac.cusps[i].eclipticLongitude)
            if d > 180 { d = 360 - d }
            #expect(
                d < 1.0,
                "Topocentric cusp \(i+1) differs from Placidus by \(d)°"
            )
        }
    }

    @Test func worksAtHighLatitude() throws {
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 75.0, longitude: 0.0)
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .topocentric
        )
        #expect(result.resolvedSystem == .topocentric)
    }
}

@Suite("Morinus and Meridian — equator-only systems")
struct EquatorSystemsTests {
    @Test func cuspsPartition360() throws {
        let moment = try Fixtures.parisMoment()
        let coord = try Fixtures.paris()
        for system in [HouseSystem.morinus, .meridian] {
            let result = try AstroCalculator.houses(
                for: moment, coordinate: coord, system: system
            )
            var total = 0.0
            for i in 0..<12 {
                total += AngleMath.normalized(
                    degrees: result.cusps[(i + 1) % 12].eclipticLongitude
                        - result.cusps[i].eclipticLongitude
                )
            }
            #expect(abs(total - 360.0) < 1e-7, "\(system): arc sum = \(total)")

            // Opposite cusps 180° apart.
            for i in 0..<6 {
                let diff = AngleMath.normalized(
                    degrees: result.cusps[i + 6].eclipticLongitude
                        - result.cusps[i].eclipticLongitude
                )
                #expect(abs(diff - 180.0) < 1e-7, "\(system): cusp \(i+7)−\(i+1)=\(diff)")
            }
        }
    }

    @Test func morinusCusp10IsMC() throws {
        let moment = try Fixtures.parisMoment()
        let coord = try Fixtures.paris()
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .morinus
        )
        #expect(abs(result.cusps[9].eclipticLongitude - result.angles.midheaven) < 1e-7)
    }

    @Test func meridianCusp1IsMC() throws {
        let moment = try Fixtures.parisMoment()
        let coord = try Fixtures.paris()
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .meridian
        )
        #expect(abs(result.cusps[0].eclipticLongitude - result.angles.midheaven) < 1e-7)
        #expect(abs(result.cusps[6].eclipticLongitude - result.angles.imumCoeli) < 1e-7)
    }

    @Test func morinusCusp1DiffersFromAscendant() throws {
        // A defining feature of Morinus — cusp 1 is a pure equator point, not
        // the rising degree.
        let moment = try Fixtures.parisMoment()
        let coord = try Fixtures.paris()
        let result = try AstroCalculator.houses(
            for: moment, coordinate: coord, system: .morinus
        )
        var diff = abs(result.cusps[0].eclipticLongitude - result.angles.ascendant)
        if diff > 180 { diff = 360 - diff }
        #expect(diff > 1.0, "Morinus cusp 1 was expected to differ from ASC")
    }

    @Test func definedAtPolarLatitude() throws {
        // Neither system depends on observer latitude, so both must succeed
        // beyond the polar circle.
        let moment = try CivilMoment(
            year: 2000, month: 6, day: 21,
            hour: 12, minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coord = try GeoCoordinate(latitude: 80.0, longitude: 0.0)
        for system in [HouseSystem.morinus, .meridian] {
            let result = try AstroCalculator.houses(
                for: moment, coordinate: coord, system: system
            )
            #expect(result.resolvedSystem == system)
        }
    }
}
