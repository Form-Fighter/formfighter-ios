import Foundation
import Charts
// First, define FeedbackModels namespace
enum FeedbackModels {
    struct FeedbackDetails: Codable {
        let feedback: String
        let score: Double
    }
    
    struct FeedbackData: Codable {
        let animation_usdz_url: String?
        let animation_fbx_url: String?
        let feedback_json_url: String?
        let overlay_video_url: String?
        let videoUrl: String?
        let status: String
        let modelFeedback: ModelFeedback?
        let fileName: String?
        let runpodRequestId: String?
        let userId: String
        let createdAt: Date
        let updatedAt: Date
        let analysisRequestedAt: Date?
        let userFeedback: UserFeedback?
        let coachComment: String?
        let coachId: String?
        let commentUpdatedAt: Date?
        let challengeId: String?
    }
    
    struct UserFeedback: Codable {
        let comment: String?
        let emoji: String?
        let helpfulnessRating: Double?
        let improvements: [String]?
        let submittedAt: Date?
        let wouldRecommend: Bool?
    }
    
    struct ModelFeedback: Codable {
        let body: BodyFeedback?
        let statusCode: Int?
    }
    
    struct MetricDetails: Codable {
        let metric_score: Double?
        let metric_values: String?
        let knockout_potential: String?
        let pros: [String]?
        let cons: [String]?
        let tactical_advantages: [String]?
        let strategic_advantages: [String]?
        let biomechanical_efficiency: [String]?
        let counter_opportunities: [String]?
        let description: [String]?
        let velocity: String?
        let tier: String?
        let ko: String?
        let optimal_followups: [String]?
        let strategic_applications: [String]?
        let ordered_sequence: String?
        let sequence_correct: Bool?
        let timing_differences: [Int]?
        let buffer_zone: String?
        let biomechanical_advantages: [String]?
        let counter_vulnerabilities: [String]?
        let strategic_implications: [String]?
        
        enum CodingKeys: String, CodingKey {
            case metric_score
            case metric_values
            case knockout_potential = "K.O. Potential"
            case pros
            case cons
            case tactical_advantages = "tactical advantages"
            case strategic_advantages = "strategic advantages"
            case biomechanical_efficiency = "biomechanical efficiency"
            case counter_opportunities = "counter opportunities"
            case description
            case velocity
            case tier
            case ko
            case optimal_followups = "optimal follow-ups"
            case strategic_applications = "strategic applications"
            case ordered_sequence = "ordered_sequence"
            case sequence_correct = "sequence_correct"
            case timing_differences = "timing_differences"
            case buffer_zone = "buffer_zone"
            case biomechanical_advantages = "biomechanical advantages"
            case counter_vulnerabilities = "counter vulnerabilities"
            case strategic_implications = "strategic implications"
        }
        
        init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            
            // Handle metric_score that might come as different number types
            if let intScore = try? container.decode(Int.self, forKey: .metric_score) {
                metric_score = Double(intScore)
            } else {
                metric_score = try? container.decode(Double.self, forKey: .metric_score)
            }
            
            // Handle sequence_correct that might come as different types
            if let boolValue = try? container.decode(Bool.self, forKey: .sequence_correct) {
                sequence_correct = boolValue
            } else if let intValue = try? container.decode(Int.self, forKey: .sequence_correct) {
                sequence_correct = intValue != 0
            } else if let stringValue = try? container.decode(String.self, forKey: .sequence_correct) {
                sequence_correct = stringValue.lowercased() == "true"
            } else {
                sequence_correct = nil
            }
            
            // Handle metric_values that might be number or string
            if let numberValue = try? container.decode(Double.self, forKey: .metric_values) {
                metric_values = String(numberValue)
            } else if let intValue = try? container.decode(Int.self, forKey: .metric_values) {
                metric_values = String(intValue)
            } else {
                metric_values = try? container.decode(String.self, forKey: .metric_values)
            }
            
            // Decode remaining properties
            knockout_potential = try? container.decode(String.self, forKey: .knockout_potential)
            pros = try? container.decode([String].self, forKey: .pros)
            cons = try? container.decode([String].self, forKey: .cons)
            tactical_advantages = try? container.decode([String].self, forKey: .tactical_advantages)
            strategic_advantages = try? container.decode([String].self, forKey: .strategic_advantages)
            biomechanical_efficiency = try? container.decode([String].self, forKey: .biomechanical_efficiency)
            counter_opportunities = try? container.decode([String].self, forKey: .counter_opportunities)
            description = try? container.decode([String].self, forKey: .description)
            velocity = try? container.decode(String.self, forKey: .velocity)
            tier = try? container.decode(String.self, forKey: .tier)
            optimal_followups = try? container.decode([String].self, forKey: .optimal_followups)
            strategic_applications = try? container.decode([String].self, forKey: .strategic_applications)
            ordered_sequence = try? container.decode(String.self, forKey: .ordered_sequence)
            timing_differences = try? container.decode([Int].self, forKey: .timing_differences)
            buffer_zone = try? container.decode(String.self, forKey: .buffer_zone)
            biomechanical_advantages = try? container.decode([String].self, forKey: .biomechanical_advantages)
            counter_vulnerabilities = try? container.decode([String].self, forKey: .counter_vulnerabilities)
            strategic_implications = try? container.decode([String].self, forKey: .strategic_implications)
            ko = try? container.decode(String.self, forKey: .ko)
        }
    }
    
    struct BodyFeedback: Codable {
        let feedback: FeedbackCategories?
        let jab_score: Double?
        
        // All metrics
        let chin_tucked_extension: MetricDetails?
        let torso_rotation_extension: MetricDetails?
        let shoulder_rotation_retraction: MetricDetails?
        let hip_rotation_extension: MetricDetails?
        let hip_velocity_retraction: MetricDetails?
        let elbow_velocity_extension: MetricDetails?
        let motion_sequence: MetricDetails?
        let hip_velocity_extension: MetricDetails?
        let foot_placement_retraction: MetricDetails?
        let foot_stepping_direction_extension: MetricDetails?
        let leg_to_shoulder_width_guard: MetricDetails?
        let jab_straight_line_extension: MetricDetails?
        let return_position_difference_retraction: MetricDetails?
        let foot_placement_guard: MetricDetails?
        let rear_hand_in_guard_extension: MetricDetails?
        let overall_velocity_extension: MetricDetails?
        let foot_velocity_extension: MetricDetails?
        let elbow_straight_line_extension: MetricDetails?
        let force_generation_extension: MetricDetails?
        let mean_back_leg_angle_extension: MetricDetails?
        let head_stability_guard: MetricDetails?
        let foot_steps_with_punch_diff_extension: MetricDetails?
        let shoulder_velocity_extension: MetricDetails?
        let elbow_protection_extension: MetricDetails?
        let chin_lift_extension: MetricDetails?
        let shoulder_velocity_retraction: MetricDetails?
        let wrist_angle_extension: MetricDetails?
        let foot_velocity_retraction: MetricDetails?
        let jab_arm_extension: MetricDetails?
        let elbow_flare_extension: MetricDetails?
        let elbow_velocity_retraction: MetricDetails?
        let step_distance_extension: MetricDetails?
        let mean_back_leg_angle_guard: MetricDetails?
        let overall_velocity_retraction: MetricDetails?
        let head_stability_extension: MetricDetails?
        let foot_placement_extension: MetricDetails?
        let chin_tucked_guard: MetricDetails?
        let chin_tucked_retraction: MetricDetails?
        let hand_velocity_extension: MetricDetails?
        let hand_velocity_retraction: MetricDetails?
        let hands_above_shoulders_guard: MetricDetails?
        let hip_rotation_retraction: MetricDetails?
        let torso_rotation_retraction: MetricDetails?
        let hand_drop_before_extension: MetricDetails?
        let whip_effect_extension: MetricDetails?
        let shoulder_rotation_extension: MetricDetails?
        let head_stability_retraction: MetricDetails?
        let mean_back_leg_angle_retraction: MetricDetails?

        enum CodingKeys: String, CodingKey {
            case feedback, jab_score
            case chin_tucked_extension = "Chin_Tucked_Extension"
            case torso_rotation_extension = "Torso_Rotation_Extension"
            case shoulder_rotation_retraction = "Shoulder_Rotation_Retraction"
            case hip_rotation_extension = "Hip_Rotation_Extension"
            case hip_velocity_retraction = "Hip_Velocity_Retraction"
            case elbow_velocity_extension = "Elbow_Velocity_Extension"
            case motion_sequence = "Motion_Sequence"
            case hip_velocity_extension = "Hip_Velocity_Extension"
            case foot_placement_retraction = "Foot_Placement_Retraction"
            case foot_stepping_direction_extension = "Foot_Stepping_Direction_Extension"
            case leg_to_shoulder_width_guard = "Leg_To_Shoulder_Width_Guard"
            case jab_straight_line_extension = "Jab_Straight_Line_Extension"
            case return_position_difference_retraction = "Return_Position_Difference_Retraction"
            case foot_placement_guard = "Foot_Placement_Guard"
            case rear_hand_in_guard_extension = "Rear_Hand_In_Guard_Extension"
            case overall_velocity_extension = "Overall_Velocity_Extension"
            case foot_velocity_extension = "Foot_Velocity_Extension"
            case elbow_straight_line_extension = "Elbow_Straight_Line_Extension"
            case force_generation_extension = "Force_Generation_Extension"
            case mean_back_leg_angle_extension = "Mean_Back_Leg_Angle_Extension"
            case head_stability_guard = "Head_Stability_Guard"
            case foot_steps_with_punch_diff_extension = "Foot_Steps_With_Punch_Diff_Extension"
            case shoulder_velocity_extension = "Shoulder_Velocity_Extension"
            case elbow_protection_extension = "Elbow_Protection_Extension"
            case chin_lift_extension = "Chin_Lift_Extension"
            case shoulder_velocity_retraction = "Shoulder_Velocity_Retraction"
            case wrist_angle_extension = "Wrist_Angle_Extension"
            case foot_velocity_retraction = "Foot_Velocity_Retraction"
            case jab_arm_extension = "Jab_Arm_Extension"
            case elbow_flare_extension = "Elbow_Flare_Extension"
            case elbow_velocity_retraction = "Elbow_Velocity_Retraction"
            case step_distance_extension = "Step_Distance_Extension"
            case mean_back_leg_angle_guard = "Mean_Back_Leg_Angle_Guard"
            case overall_velocity_retraction = "Overall_Velocity_Retraction"
            case head_stability_extension = "Head_Stability_Extension"
            case foot_placement_extension = "Foot_Placement_Extension"
            case chin_tucked_guard = "Chin_Tucked_Guard"
            case chin_tucked_retraction = "Chin_Tucked_Retraction"
            case hand_velocity_extension = "Hand_Velocity_Extension"
            case hand_velocity_retraction = "Hand_Velocity_Retraction"
            case hands_above_shoulders_guard = "Hands_Above_Shoulders_Guard"
            case hip_rotation_retraction = "Hip_Rotation_Retraction"
            case torso_rotation_retraction = "Torso_Rotation_Retraction"
            case hand_drop_before_extension = "Hand_Drop_Before_Extension"
            case whip_effect_extension = "Whip_Effect_Extension"
            case shoulder_rotation_extension = "Shoulder_Rotation_Extension"
            case head_stability_retraction = "Head_Stability_Retraction"
            case mean_back_leg_angle_retraction = "Mean_Back_Leg_Angle_Retraction"
        }
    }
    
    struct FeedbackCategories: Codable {
        let extensionFeedback: FeedbackDetails?
        let guardPosition: FeedbackDetails?
        let retraction: FeedbackDetails?
        
        enum CodingKeys: String, CodingKey {
            case extensionFeedback = "extension"
            case guardPosition = "guard"
            case retraction
        }
    }
}

extension FeedbackModels.FeedbackData: Equatable {
    static func == (lhs: FeedbackModels.FeedbackData, rhs: FeedbackModels.FeedbackData) -> Bool {
        return lhs.videoUrl == rhs.videoUrl
    }
} 