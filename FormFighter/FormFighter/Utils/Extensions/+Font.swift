import SwiftUI

extension Font {
    static func special(_ size: FontSize, weight: FontStyle) -> Font {
        return Font.custom(weight.rawValue, size: size.rawValue)
    }
}
