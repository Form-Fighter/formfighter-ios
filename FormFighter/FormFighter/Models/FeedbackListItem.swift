import Foundation
import FirebaseFirestore

struct FeedbackListItem: Identifiable {
    let id: String
    let date: Date
    let status: FeedbackStatus
    let videoUrl: String?
    let score: Double
    let modelFeedback: FeedbackModels.ModelFeedback?
    let homeworkId: String?
    let coachId: String?
    var isCompleted: Bool {
        status == .completed
    }
    
    var isLoading: Bool {
        FeedbackStatus.processingStatuses.contains(status.rawValue)
    }
} 