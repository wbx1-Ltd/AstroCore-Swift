import Foundation
import Testing

@testable import AstroCore

private let angleAlignedSystems: [HouseSystem] = [
    .porphyry, .placidus, .koch, .alcabitius, .campanus, .regiomontanus, .topocentric,
]

@Suite("House Systems")
struct HouseSystemTests {
    @Test func midheavenFormulaAndVertexBehaveAsExpected() {
        let epsilon = 23.4393
        let cardinals = [0.0, 90.0, 180.0, 270.0]
        for armc in cardinals {
            let midheaven = AnglesEngine.midheavenLongitude(
                lastDegrees: armc,
                trueObliquityDegrees: epsilon
            )
            AstroCoreTestSupport.expectCircularlyEqual(midheaven, armc, tolerance: 1e-9)
        }

        for armc in stride(from: 5.0, through: 355.0, by: 7.0)
        where abs(armc - 90.0) > 1e-3 && abs(armc - 270.0) > 1e-3 {
            let midheaven = AnglesEngine.midheavenLongitude(
                lastDegrees: armc,
                trueObliquityDegrees: epsilon
            )
            let lhs = TrigDeg.tan(midheaven) * TrigDeg.cos(epsilon)
            let rhs = TrigDeg.tan(armc)
            #expect(abs(lhs - rhs) < 1e-9)
        }

        #expect(
            AnglesEngine.vertexLongitude(
                lastDegrees: 120.0,
                trueObliquityDegrees: epsilon,
                latitudeDegrees: 0.0
            ) == nil
        )
        #expect(
            AnglesEngine.vertexLongitude(
                lastDegrees: 120.0,
                trueObliquityDegrees: epsilon,
                latitudeDegrees: 51.5
            ) != nil
        )
        #expect(
            AnglesEngine.vertexLongitude(
                lastDegrees: 120.0,
                trueObliquityDegrees: epsilon,
                latitudeDegrees: -33.8
            ) != nil
        )

        let equatorialSemiArc = SemiArc.compute(
            eclipticLongitude: 0.0,
            obliquity: epsilon,
            latitude: 0.0
        )
        #expect(abs(equatorialSemiArc.declinationDegrees) < 1e-12)
        #expect(abs(equatorialSemiArc.rightAscensionDegrees) < 1e-12)
        #expect(abs((equatorialSemiArc.semiDiurnalArc ?? 0.0) - 90.0) < 1e-9)
        #expect(!equatorialSemiArc.isCircumpolar)

        let circumpolarSemiArc = SemiArc.compute(
            eclipticLongitude: 90.0,
            obliquity: epsilon,
            latitude: 80.0
        )
        #expect(abs(circumpolarSemiArc.declinationDegrees - epsilon) < 1e-9)
        #expect(circumpolarSemiArc.semiDiurnalArc == nil)
        #expect(circumpolarSemiArc.isCircumpolar)
    }

    @Test func allSystemsProduceValidCuspsAcrossRepresentativeCities() throws {
        for fixture in try AstroCoreTestSupport.coreHouseFixtures() {
            for system in HouseSystem.allCases {
                let result = try AstroCalculator.houses(
                    for: fixture.moment,
                    coordinate: fixture.coordinate,
                    system: system
                )
                #expect(result.requestedSystem == system)
                #expect(result.resolvedSystem == system)
                #expect(result.usedRequestedSystem)
                AstroCoreTestSupport.expectValidCusps(result.cusps)
                AstroCoreTestSupport.expectCuspPartition(result.cusps)
            }
        }
    }

    @Test func equalDivisionSystemsFollowTheirDefinitions() throws {
        let fixture = try AstroCoreTestSupport.newYork1990()

        let equalAsc = try AstroCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .equalASC
        )
        AstroCoreTestSupport.expectCircularlyEqual(
            equalAsc.cusps[0].eclipticLongitude,
            equalAsc.angles.ascendant,
            tolerance: 1e-9
        )
        for index in 0..<11 {
            let arc = AstroCoreTestSupport.forwardArc(
                equalAsc.cusps[index].eclipticLongitude,
                equalAsc.cusps[index + 1].eclipticLongitude
            )
            #expect(abs(arc - 30.0) < 1e-9)
        }

        let equalMC = try AstroCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .equalMC
        )
        AstroCoreTestSupport.expectCircularlyEqual(
            equalMC.cusps[9].eclipticLongitude,
            equalMC.angles.midheaven,
            tolerance: 1e-9
        )

        let vehlow = try AstroCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .vehlow
        )
        let offset = AstroCoreTestSupport.forwardArc(
            vehlow.cusps[0].eclipticLongitude,
            vehlow.angles.ascendant
        )
        #expect(abs(offset - 15.0) < 1e-9)

        let wholeSign = try AstroCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .wholeSign
        )
        for cusp in wholeSign.cusps {
            #expect(abs(cusp.degreeInSign) < 1e-9)
        }
        #expect(
            wholeSign.cusps[0].sign
                == ZodiacMapper.details(
                    forNormalizedLongitude: wholeSign.angles.ascendant
                ).sign
        )
    }

    @Test func porphyryAndSripatiMaintainTheirRelationships() throws {
        let fixture = try AstroCoreTestSupport.paris1995()
        let porphyry = try AstroCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .porphyry
        )
        let sripati = try AstroCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .sripati
        )

        AstroCoreTestSupport.expectCircularlyEqual(
            porphyry.cusps[0].eclipticLongitude,
            porphyry.angles.ascendant,
            tolerance: 1e-9
        )
        AstroCoreTestSupport.expectCircularlyEqual(
            porphyry.cusps[3].eclipticLongitude,
            porphyry.angles.imumCoeli,
            tolerance: 1e-9
        )
        AstroCoreTestSupport.expectCircularlyEqual(
            porphyry.cusps[6].eclipticLongitude,
            porphyry.angles.descendant,
            tolerance: 1e-9
        )
        AstroCoreTestSupport.expectCircularlyEqual(
            porphyry.cusps[9].eclipticLongitude,
            porphyry.angles.midheaven,
            tolerance: 1e-9
        )

        let quadrants: [Range<Int>] = [0..<3, 3..<6, 6..<9, 9..<12]
        for quadrant in quadrants {
            let c0 = porphyry.cusps[quadrant.lowerBound].eclipticLongitude
            let c1 = porphyry.cusps[quadrant.lowerBound + 1].eclipticLongitude
            let c2 = porphyry.cusps[quadrant.lowerBound + 2].eclipticLongitude
            let c3 = porphyry.cusps[quadrant.upperBound % 12].eclipticLongitude
            let arc1 = AstroCoreTestSupport.forwardArc(c0, c1)
            let arc2 = AstroCoreTestSupport.forwardArc(c1, c2)
            let arc3 = AstroCoreTestSupport.forwardArc(c2, c3)
            #expect(abs(arc1 - arc2) < 1e-9)
            #expect(abs(arc2 - arc3) < 1e-9)
        }

        for index in 0..<12 {
            let start = porphyry.cusps[(index + 11) % 12].eclipticLongitude
            let end = porphyry.cusps[index].eclipticLongitude
            let midpoint = AngleMath.normalized(
                degrees: start + AstroCoreTestSupport.forwardArc(start, end) / 2.0
            )
            AstroCoreTestSupport.expectCircularlyEqual(
                sripati.cusps[index].eclipticLongitude,
                midpoint,
                tolerance: 1e-9
            )
        }
    }

    @Test func angleAlignedSystemsKeepCardinalCuspsOnAngles() throws {
        let fixture = try AstroCoreTestSupport.paris1995()

        for system in angleAlignedSystems {
            let result = try AstroCalculator.houses(
                for: fixture.moment,
                coordinate: fixture.coordinate,
                system: system
            )
            AstroCoreTestSupport.expectCircularlyEqual(
                result.cusps[0].eclipticLongitude,
                result.angles.ascendant,
                tolerance: 1e-7,
                "\(system) cusp 1"
            )
            AstroCoreTestSupport.expectCircularlyEqual(
                result.cusps[3].eclipticLongitude,
                result.angles.imumCoeli,
                tolerance: 1e-7,
                "\(system) cusp 4"
            )
            AstroCoreTestSupport.expectCircularlyEqual(
                result.cusps[6].eclipticLongitude,
                result.angles.descendant,
                tolerance: 1e-7,
                "\(system) cusp 7"
            )
            AstroCoreTestSupport.expectCircularlyEqual(
                result.cusps[9].eclipticLongitude,
                result.angles.midheaven,
                tolerance: 1e-7,
                "\(system) cusp 10"
            )

            for index in 0..<6 {
                let opposite = AstroCoreTestSupport.forwardArc(
                    result.cusps[index].eclipticLongitude,
                    result.cusps[index + 6].eclipticLongitude
                )
                #expect(abs(opposite - 180.0) < 1e-7)
            }

            AstroCoreTestSupport.expectCuspPartition(result.cusps)
        }
    }

    @Test func meridianAndMorinusKeepTheirDistinctGeometry() throws {
        let fixture = try AstroCoreTestSupport.paris1995()

        let meridian = try AstroCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .meridian
        )
        let morinus = try AstroCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .morinus
        )

        AstroCoreTestSupport.expectCuspPartition(meridian.cusps)
        AstroCoreTestSupport.expectCuspPartition(morinus.cusps)
        AstroCoreTestSupport.expectCircularlyEqual(
            meridian.cusps[9].eclipticLongitude,
            meridian.angles.midheaven,
            tolerance: 1e-7
        )
        #expect(
            AstroCoreTestSupport.circularDifference(
                meridian.cusps[0].eclipticLongitude,
                meridian.angles.ascendant
            ) > 1.0
        )
        #expect(
            AstroCoreTestSupport.circularDifference(
                morinus.cusps[0].eclipticLongitude,
                morinus.angles.ascendant
            ) > 1.0
        )
        #expect(
            AstroCoreTestSupport.circularDifference(
                morinus.cusps[9].eclipticLongitude,
                morinus.angles.midheaven
            ) > 0.1
        )
    }

    @Test func topocentricTracksPlacidusAndProjectionSystemsStayDistinct() throws {
        let fixture = try AstroCoreTestSupport.paris1995()
        let topocentric = try AstroCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .topocentric
        )
        let placidus = try AstroCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .placidus
        )
        let campanus = try AstroCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .campanus
        )
        let regiomontanus = try AstroCalculator.houses(
            for: fixture.moment,
            coordinate: fixture.coordinate,
            system: .regiomontanus
        )

        for index in [10, 11, 1, 2] {
            let difference = AstroCoreTestSupport.circularDifference(
                topocentric.cusps[index].eclipticLongitude,
                placidus.cusps[index].eclipticLongitude
            )
            #expect(difference < 1.0)
        }

        var maxDifference = 0.0
        for index in [1, 2, 4, 5, 7, 8, 10, 11] {
            maxDifference = max(
                maxDifference,
                AstroCoreTestSupport.circularDifference(
                    campanus.cusps[index].eclipticLongitude,
                    regiomontanus.cusps[index].eclipticLongitude
                )
            )
        }
        #expect(maxDifference > 0.1)
    }

    @Test func semiArcSystemsFallbackOrThrowNearPolarLatitudes() throws {
        let moment = try CivilMoment(
            year: 2000,
            month: 6,
            day: 21,
            hour: 12,
            minute: 0,
            timeZoneIdentifier: "UTC"
        )
        let coordinate = try GeoCoordinate(latitude: 75.0, longitude: 0.0)

        let placidus = try AstroCalculator.houses(
            for: moment,
            coordinate: coordinate,
            system: .placidus,
            polarFallback: .equalASC
        )
        #expect(placidus.resolvedSystem == .equalASC)
        #expect(!placidus.usedRequestedSystem)

        let koch = try AstroCalculator.houses(
            for: moment,
            coordinate: coordinate,
            system: .koch,
            polarFallback: .wholeSign
        )
        #expect(koch.resolvedSystem == .wholeSign)

        let alcabitius = try AstroCalculator.houses(
            for: moment,
            coordinate: coordinate,
            system: .alcabitius,
            polarFallback: .porphyry
        )
        #expect(alcabitius.resolvedSystem == .porphyry)

        #expect(throws: AstroError.houseSystemUndefinedAtLatitude(
            system: .placidus,
            latitude: 75.0
        )) {
            _ = try AstroCalculator.houses(
                for: moment,
                coordinate: coordinate,
                system: .placidus,
                polarFallback: .error
            )
        }

        let topocentric = try AstroCalculator.houses(
            for: moment,
            coordinate: coordinate,
            system: .topocentric
        )
        #expect(topocentric.resolvedSystem == .topocentric)
    }
}
