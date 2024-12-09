import Foundation
import FirebaseFirestore

struct FeedbackListItem: Identifiable {
    let id: String
    let date: Date
    let status: FeedbackStatus
    let videoUrl: String?
    let score: Double
    
    var isCompleted: Bool {
        return status == .completed
    }
    
    var isLoading: Bool {
        return status.isProcessing
    }
} 