import Foundation
import AVFoundation

extension Notification.Name {
    static let subscriptionStatusChanged = Notification.Name("subscriptionStatusChanged")
} 

  // Helper extension to create AVAsset from Data
    extension AVAsset {
        convenience init(data: Data) throws {
            let directory = FileManager.default.temporaryDirectory
            let fileName = UUID().uuidString
            let url = directory.appendingPathComponent(fileName)
            try data.write(to: url)
            self.init(url: url)
        }
    }
