import Foundation

// First, define FeedbackModels namespace
enum FeedbackModels {
    struct FeedbackDetails: Codable {
        let feedback: String
        let score: Double
    }
    
    struct FeedbackData: Codable {
        let animation_usdz_url: String
        let modelFeedback: ModelFeedback
    }
    
    struct ModelFeedback: Codable {
        let body: BodyFeedback
        let jab_score: Double
    }
    
    struct BodyFeedback: Codable {
        let feedback: FeedbackCategories
    }
    
    struct FeedbackCategories: Codable {
        let extensionFeedback: FeedbackDetails
        let guardPosition: FeedbackDetails
        let retraction: FeedbackDetails
        
        enum CodingKeys: String, CodingKey {
            case extensionFeedback = "extension"
            case guardPosition = "guard"
            case retraction
        }
    }
} 