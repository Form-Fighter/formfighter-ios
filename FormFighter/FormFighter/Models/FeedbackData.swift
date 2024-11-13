import Foundation

// First, define FeedbackModels namespace
enum FeedbackModels {
    struct FeedbackDetails: Codable {
        let feedback: String
        let score: Double
    }
    
    struct FeedbackData: Codable {
        let animation_usdz_url: String
        let animation_fbx_url: String
        let feedback_json_url: String
        let overlay_video_url: String
        let videoUrl: String
        let status: String
        let modelFeedback: ModelFeedback
    }
    
    struct ModelFeedback: Codable {
        let body: BodyFeedback
        let statusCode: Int
    }
    
    struct BodyFeedback: Codable {
        let feedback: FeedbackCategories
        let jab_score: Double
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