@testable import AstroCore
import Foundation
import Testing

@Suite("Swiss House Verification")
struct SwissHouseVerificationTests {
    @Test func implementedHouseSystemsMatchSwissEphemerisWhenEnabled() throws {
        guard ProcessInfo.processInfo.environment["ASTROCORE_ENABLE_SWISS_VERIFICATION"] == "1" else {
            return
        }

        let fixtures = try [
            AstroCoreTestSupport.newYork1990(),
            AstroCoreTestSupport.london2000(),
            AstroCoreTestSupport.paris1995(),
            AstroCoreTestSupport.sydney2010()
        ]
        let snapshots = try AstroCoreTestSupport.swissHouseSnapshots(
            fixtures: fixtures,
            systems: HouseSystem.allCases,
            includeGauquelin: true
        )

        for fixture in fixtures {
            guard let snapshot = snapshots[fixture.name] else {
                Issue.record("Missing Swiss snapshot for \(fixture.name)")
                continue
            }

            for system in HouseSystem.allCases {
                guard let expected = snapshot.systems[AstroCoreTestSupport.swissLetter(for: system)] else {
                    Issue.record("Missing Swiss data for \(system) at \(fixture.name)")
                    continue
                }

                let result = try AstroCalculator.houses(
                    for: fixture.moment,
                    coordinate: fixture.coordinate,
                    system: system
                )
                for (index, cusp) in result.cusps.enumerated() {
                    AstroCoreTestSupport.expectCircularlyEqual(
                        cusp.eclipticLongitude,
                        expected[index],
                        tolerance: 3e-5,
                        "\(fixture.name) \(system.displayName) cusp \(index + 1)"
                    )
                }
            }

            guard let expectedSectors = snapshot.gauquelin else {
                Issue.record("Missing Gauquelin data for \(fixture.name)")
                continue
            }
            let gauquelin = try AstroCalculator.gauquelinSectors(
                for: fixture.moment,
                coordinate: fixture.coordinate
            )
            for (index, sector) in gauquelin.sectors.enumerated() {
                AstroCoreTestSupport.expectCircularlyEqual(
                    sector.eclipticLongitude,
                    expectedSectors[index],
                    tolerance: 3e-5,
                    "\(fixture.name) Gauquelin sector \(index + 1)"
                )
            }
        }
    }
}
