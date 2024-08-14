import SwiftUI
import TipKit

/// Small helper protocol for a tip that is available below iOS 17
/// so that we can pass tips around and have members storing tips,
/// as stored properties can't be marked with `@available`.
@available(iOS, obsoleted: 17, message: "Can be removed once we only support iOS 17+")
public protocol TipShim {
    
    @available(iOS 17, *)
    var tip: AnyTip { get }
    
}

@available(iOS 17, *)
public extension Tip where Self: TipShim {
    
    var tip: AnyTip { AnyTip(self) }
    
}

public extension View {
    
    /// Helper for making the `popupTip` modifier available for iOS <17.
    @available(iOS, obsoleted: 17, message: "Can be removed once we only support iOS 17+")
    @ViewBuilder func popupTipShim(_ tipShim: TipShim?, arrowEdge: Edge = .top) -> some View {
        if #available(iOS 17, *), let tip = tipShim?.tip {
            self.popoverTip(tip, arrowEdge: arrowEdge)
        } else {
            self
        }
    }
    
}
