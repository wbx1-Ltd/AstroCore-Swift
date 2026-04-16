import Foundation
import Testing

@testable import AstroCore

struct ChartFixture: Sendable, CustomStringConvertible {
    let name: String
    let moment: CivilMoment
    let coordinate: GeoCoordinate

    var description: String { name }
}

enum AstroCoreTestSupport {
    static func circularDifference(_ lhs: Double, _ rhs: Double) -> Double {
        let diff = abs(AngleMath.normalized(degrees: lhs - rhs))
        return min(diff, 360.0 - diff)
    }

    static func forwardArc(_ start: Double, _ end: Double) -> Double {
        AngleMath.normalized(degrees: end - start)
    }

    static func expectCircularlyEqual(
        _ lhs: Double,
        _ rhs: Double,
        tolerance: Double,
        _ message: String = ""
    ) {
        let diff = circularDifference(lhs, rhs)
        if message.isEmpty {
            #expect(diff < tolerance)
        } else {
            #expect(diff < tolerance, "\(message) (Δ=\(diff)°)")
        }
    }

    static func expectValidLongitude(_ longitude: Double) {
        #expect(longitude >= 0.0 && longitude < 360.0)
    }

    static func expectValidCusps(_ cusps: [HouseCusp]) {
        #expect(cusps.count == 12)
        for (index, cusp) in cusps.enumerated() {
            #expect(cusp.number == index + 1)
            expectValidLongitude(cusp.eclipticLongitude)
            #expect(cusp.degreeInSign >= 0.0 && cusp.degreeInSign < 30.0)
            #expect(cusp.sign.contains(longitude: cusp.eclipticLongitude))
        }
    }

    static func expectCuspPartition(
        _ cusps: [HouseCusp],
        tolerance: Double = 1e-6
    ) {
        var total = 0.0
        for index in 0..<12 {
            let arc = forwardArc(
                cusps[index].eclipticLongitude,
                cusps[(index + 1) % 12].eclipticLongitude
            )
            #expect(arc > 0.0 && arc < 360.0)
            total += arc
        }
        #expect(abs(total - 360.0) < tolerance)
    }

    static func newYork1990() throws -> ChartFixture {
        ChartFixture(
            name: "new-york",
            moment: try CivilMoment(
                year: 1990,
                month: 8,
                day: 15,
                hour: 14,
                minute: 30,
                timeZoneIdentifier: "America/New_York"
            ),
            coordinate: try GeoCoordinate(latitude: 40.7128, longitude: -74.0060)
        )
    }

    static func london2000() throws -> ChartFixture {
        ChartFixture(
            name: "london",
            moment: try CivilMoment(
                year: 2000,
                month: 1,
                day: 1,
                hour: 0,
                minute: 0,
                timeZoneIdentifier: "Europe/London"
            ),
            coordinate: try GeoCoordinate(latitude: 51.5074, longitude: -0.1278)
        )
    }

    static func tokyo1985() throws -> ChartFixture {
        ChartFixture(
            name: "tokyo",
            moment: try CivilMoment(
                year: 1985,
                month: 6,
                day: 15,
                hour: 8,
                minute: 0,
                timeZoneIdentifier: "Asia/Tokyo"
            ),
            coordinate: try GeoCoordinate(latitude: 35.6762, longitude: 139.6503)
        )
    }

    static func paris1995() throws -> ChartFixture {
        ChartFixture(
            name: "paris",
            moment: try CivilMoment(
                year: 1995,
                month: 4,
                day: 10,
                hour: 14,
                minute: 30,
                timeZoneIdentifier: "Europe/Paris"
            ),
            coordinate: try GeoCoordinate(latitude: 48.85, longitude: 2.35)
        )
    }

    static func sydney2010() throws -> ChartFixture {
        ChartFixture(
            name: "sydney",
            moment: try CivilMoment(
                year: 2010,
                month: 12,
                day: 15,
                hour: 9,
                minute: 0,
                timeZoneIdentifier: "Australia/Sydney"
            ),
            coordinate: try GeoCoordinate(latitude: -33.8688, longitude: 151.2093)
        )
    }

    static func coreHouseFixtures() throws -> [ChartFixture] {
        [
            try newYork1990(),
            try london2000(),
            try tokyo1985(),
        ]
    }
}
