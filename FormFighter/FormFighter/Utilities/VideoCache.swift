import Foundation
import AVFoundation

class VideoCache {
    static let shared = VideoCache()
    private var cache: [String: URL] = [:]
    
    func cacheVideo(data: Data, for id: String) throws -> URL {
        let directory = FileManager.default.temporaryDirectory
        let fileName = "\(id)_cached_video"
        let url = directory.appendingPathComponent(fileName)
        try data.write(to: url)
        cache[id] = url
        return url
    }
    
    func getCachedVideo(for id: String) -> URL? {
        return cache[id]
    }
    
    func clearCache() {
        for url in cache.values {
            try? FileManager.default.removeItem(at: url)
        }
        cache.removeAll()
    }
} 