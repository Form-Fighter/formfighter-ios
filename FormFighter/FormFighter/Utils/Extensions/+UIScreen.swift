import UIKit

extension UIScreen {
    static var width: CGFloat {
        UIScreen.main.bounds.width
    }
    
    static var height: CGFloat {
        UIScreen.main.bounds.height
    }
    
    //MARK: - Checks if the screen size is like the iPhone SE, in case you need to make special adjustments in the UI for this screen.
    static var isSE: Bool {
        width == 375 && height == 667
    }
}
