import Foundation

enum FeedbackStatus: String {
    case pending = "pending"
    case completed = "completed"
    case error = "error"
    
    // Processing statuses
    case requestReceived = "request_received"
    case buildingWhamNetwork = "building_wham_network"
    case dataPreprocessing = "data_preprocessing"
    case performingSlam = "performing_slam"
    case extractingImageFeatures = "extracting_image_features"
    case runningWhamNetwork = "running_wham_network"
    case runningSmplify = "running_smplify"
    case creatingVisualization = "creating_visualization"
    case extractingFeedback = "extracting_feedback"
    case animatingModel = "animating_model"
    
    static let processingStatuses: Set<String> = [
        requestReceived.rawValue,
        buildingWhamNetwork.rawValue,
        dataPreprocessing.rawValue,
        performingSlam.rawValue,
        extractingImageFeatures.rawValue,
        runningWhamNetwork.rawValue,
        runningSmplify.rawValue,
        creatingVisualization.rawValue,
        extractingFeedback.rawValue,
        animatingModel.rawValue
    ]
    
    var isProcessing: Bool {
        return FeedbackStatus.processingStatuses.contains(self.rawValue)
    }
    
    var message: String {
        switch self {
        case .pending: return "Preparing your video..."
        case .completed: return "Analysis complete!"
        case .error: return "An error occurred"
        case .requestReceived: return "Keep your guard up to protect your chin!"
        case .buildingWhamNetwork: return "Turn your hips when throwing kicks for power"
        case .dataPreprocessing: return "Stay light on your feet, ready to move"
        case .performingSlam: return "Breathe out sharply when striking"
        case .extractingImageFeatures: return "Return to guard position after each strike"
        case .runningWhamNetwork: return "Keep your elbows in to protect your body"
        case .runningSmplify: return "Pivot on your lead foot for powerful roundhouses"
        case .creatingVisualization: return "Use your shoulders to protect your chin"
        case .extractingFeedback: return "Step into your punches for more power"
        case .animatingModel: return "Keep your stance balanced and ready"
        }
    }
} 