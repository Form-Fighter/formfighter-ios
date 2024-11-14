import Foundation

struct PunchStats: Equatable {
    let timestamp: Date
    let score: Double
    let count: Int
    
    // Implement Equatable manually since Date doesn't automatically conform
    static func == (lhs: PunchStats, rhs: PunchStats) -> Bool {
        return lhs.timestamp == rhs.timestamp &&
               lhs.score == rhs.score &&
               lhs.count == rhs.count
    }
} 