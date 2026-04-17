import Foundation

enum Validation {
    static func requireFinite(_ value: Double, name: String) throws(AstroError) {
        if value.isNaN || value.isInfinite {
            throw .invalidCoordinate(detail: "\(name) must be finite, got \(value)")
        }
    }

    static func isLeapYear(_ year: Int) -> Bool {
        (year % 4 == 0 && year % 100 != 0) || (year % 400 == 0)
    }

    static func daysInMonth(month: Int, year: Int) -> Int {
        switch month {
        case 1, 3, 5, 7, 8, 10, 12: 31
        case 4, 6, 9, 11: 30
        case 2: isLeapYear(year) ? 29 : 28
        default: 0
        }
    }
}
