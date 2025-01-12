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
    
    static let orderedProcessingStatuses: [String] = [
        "request_received",
        "building_wham_network",
        "data_preprocessing",
        "performing_slam",
        "extracting_image_features",
        "running_wham_network",
        "running_smplify",
        "creating_visualization",
        "extracting_feedback",
        "animating_model"
    ]
    
    var isProcessing: Bool {
        return FeedbackStatus.processingStatuses.contains(self.rawValue)
    }
    
    var message: String {
        switch self {
        case .pending: return "Preparing your video..."
        case .completed: return "Analysis complete!"
        case .error: return "An error occurred"
        case .requestReceived: return "Processing your video..."
        case .buildingWhamNetwork: return "analyzing your skeleton..."
        case .dataPreprocessing: return "processing your technique..."
        case .performingSlam: return "extracting small movements..."
        case .extractingImageFeatures: return "extracting smaller movements..."
        case .runningWhamNetwork: return "analyzing all the movements together..."
        case .runningSmplify: return "running your technique through the algorithm..."
        case .creatingVisualization: return "creating a visual of your technique..."
        case .extractingFeedback: return "creating your feedback..."
        case .animatingModel: return "animating your technique..."
        }
    }
} 