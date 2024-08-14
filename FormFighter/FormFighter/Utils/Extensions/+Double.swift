import Foundation

import CoreGraphics

extension Double {
    var percentageString: String {
        let value = self * 100
        if value.truncatingRemainder(dividingBy: 1) == 0 {
            return String(format: "%.0f%%", value)
        } else {
            return String(format: "%.2f%%", value)
        }
    }
}
