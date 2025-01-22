import UIKit
import Vision

enum PoseHighlightMapping {
    enum HighlightType {
        case position, velocity, rotation, sequence
        
        var color: UIColor {
            switch self {
            case .position: return UIColor.red.withAlphaComponent(0.7)
            case .velocity: return UIColor.blue.withAlphaComponent(0.7)
            case .rotation: return UIColor.green.withAlphaComponent(0.7)
            case .sequence: return UIColor.yellow.withAlphaComponent(0.7)
            }
        }
    }
    
    static func analyzeMetric(metricName: String, sentence: String) -> (landmarks: [VNHumanBodyPoseObservation.JointName], type: HighlightType, frameTime: ClosedRange<Double>) {
        // First check keywords in the sentence
        let keywords = sentence.lowercased()
        let frameTime: ClosedRange<Double>
        
        // Determine frame timing based on keywords and metric name (ensure within 2 seconds)
        if keywords.contains("guard") || metricName.contains("Guard") {
            frameTime = 0.0...0.5  // First quarter for guard position
        } else if keywords.contains("retraction") || metricName.contains("Retraction") {
            frameTime = 1.0...1.7  // Last part for retraction
        } else {
            frameTime = 0.5...1.0  // Middle part for extension (default)
        }
        
        // Determine highlight type and landmarks
        if keywords.contains("velocity") || keywords.contains("speed") || metricName.contains("Velocity") {
            return (getBodyPartLandmarks(from: metricName), .velocity, frameTime)
        } else if keywords.contains("rotation") || keywords.contains("turn") || metricName.contains("Rotation") {
            return (getBodyPartLandmarks(from: metricName), .rotation, frameTime)
        } else if keywords.contains("sequence") || keywords.contains("timing") || metricName.contains("Sequence") {
            return (getAllLandmarks(), .sequence, frameTime)
        }
        
        // Default to position with specific landmarks
        return (getBodyPartLandmarks(from: metricName), .position, frameTime)
    }
    
    private static func getBodyPartLandmarks(from metricName: String) -> [VNHumanBodyPoseObservation.JointName] {
        if metricName.contains("Head") || metricName.contains("Chin") {
            return [.nose, .leftEar, .rightEar]
        } else if metricName.contains("Hand") || metricName.contains("Wrist") {
            return [.leftWrist, .rightWrist]
        } else if metricName.contains("Elbow") {
            return [.leftElbow, .rightElbow]
        } else if metricName.contains("Shoulder") {
            return [.leftShoulder, .rightShoulder]
        } else if metricName.contains("Hip") {
            return [.leftHip, .rightHip]
        } else if metricName.contains("Back_Leg") {
            return [.leftHip, .rightHip, .leftKnee, .rightKnee, .leftAnkle, .rightAnkle]
        } else if metricName.contains("Return_Position") {
            return [.leftShoulder, .rightShoulder, .leftElbow, .rightElbow, .leftWrist, .rightWrist]
        } else if metricName.contains("Foot") || metricName.contains("Step") {
            return [.leftAnkle, .rightAnkle]
        }
        
        return getAllLandmarks()
    }
    
    private static func getAllLandmarks() -> [VNHumanBodyPoseObservation.JointName] {
        [.nose, .leftEar, .rightEar, .leftShoulder, .rightShoulder, 
         .leftElbow, .rightElbow, .leftWrist, .rightWrist, 
         .leftHip, .rightHip]
    }
} 