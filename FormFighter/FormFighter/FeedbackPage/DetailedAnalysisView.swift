import SwiftUI

struct DetailedAnalysisView: View {
    @ObservedObject var viewModel: FeedbackViewModel
    
    // Categories matching the React version
    private let categories = [
        ("all", "All"),
        ("head", "Head & Chin"),
        ("arms", "Arms & Hands"),
        ("shoulders", "Shoulders"),
        ("torso", "Torso & Hips"),
        ("legs", "Legs & Feet"),
        ("overall", "Overall Metrics")
    ]
    
    @State private var selectedCategory: String = "all"
    
    // Grouped metrics matching the React version
    private let groupedMetrics: [String: [String]] = [
        "head": [
            "Chin_Lift_Extension",
            "Chin_Tucked_Extension",
            "Chin_Tucked_Guard",
            "Chin_Tucked_Retraction",
            "Head_Stability_Extension",
            "Head_Stability_Guard",
            "Head_Stability_Retraction"
        ],
        "arms": [
            "Elbow_Flare_Extension",
            "Elbow_Protection_Extension",
            "Elbow_Straight_Line_Extension",
            "Elbow_Velocity_Extension",
            "Elbow_Velocity_Retraction",
            "Hand_Drop_Before_Extension",
            "Hand_Velocity_Extension",
            "Hand_Velocity_Retraction",
            "Wrist_Angle_Extension",
            "Jab_Arm_Extension",
            "Jab_Straight_Line_Extension",
            "Rear_Hand_In_Guard_Extension"
        ],
        "shoulders": [
            "Shoulder_Rotation_Extension",
            "Shoulder_Rotation_Retraction",
            "Shoulder_Velocity_Extension",
            "Shoulder_Velocity_Retraction",
            "Hands_Above_Shoulders_Guard"
        ],
        "torso": [
            "Torso_Rotation_Extension",
            "Torso_Rotation_Retraction",
            "Hip_Rotation_Extension",
            "Hip_Rotation_Retraction",
            "Hip_Velocity_Extension",
            "Hip_Velocity_Retraction"
        ],
        "legs": [
            "Leg_To_Shoulder_Width_Guard",
            "Mean_Back_Leg_Angle_Extension",
            "Mean_Back_Leg_Angle_Guard",
            "Mean_Back_Leg_Angle_Retraction",
            "Foot_Placement_Extension",
            "Foot_Placement_Guard",
            "Foot_Placement_Retraction",
            "Foot_Velocity_Extension",
            "Foot_Velocity_Retraction",
            "Foot_Steps_With_Punch_Diff_Extension",
            "Foot_Stepping_Direction_Extension",
            "Step_Distance_Extension"
        ],
        "overall": [
            "Force_Generation_Extension",
            "Motion_Sequence",
            "Overall_Velocity_Extension",
            "Overall_Velocity_Retraction",
            "Whip_Effect_Extension",
            "Return_Position_Difference_Retraction"
        ]
    ]
    
    var body: some View {
        VStack(spacing: 16) {
            // Category Filter
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(categories, id: \.0) { category in
                        CategoryButton(
                            title: category.1,
                            isSelected: selectedCategory == category.0,
                            action: { selectedCategory = category.0 }
                        )
                    }
                }
                .padding(.horizontal)
            }
            
            // Metrics Display
            ScrollView {
                LazyVStack(spacing: 16) {
                    ForEach(Array(filteredMetrics.enumerated()), id: \.1) { index, metricKey in
                        if let feedback = viewModel.feedback?.modelFeedback,
                           let body = feedback.body {
                            if let metricData = self.getMetricData(for: metricKey, from: body) {
                                MetricCardView(title: metricKey, metric: metricData)
                            }
                        }
                    }
                }
                .padding()
            }
        }
    }
    
    private var filteredMetrics: [String] {
        if selectedCategory == "all" {
            return Array(groupedMetrics.values.flatMap { $0 })
        }
        return groupedMetrics[selectedCategory] ?? []
    }
    
    private func getMetricData(for key: String, from feedback: FeedbackModels.BodyFeedback) -> FeedbackModels.MetricDetails? {
        switch key {
            case "Chin_Tucked_Extension": return feedback.chin_tucked_extension
            case "Torso_Rotation_Extension": return feedback.torso_rotation_extension
            case "Shoulder_Rotation_Retraction": return feedback.shoulder_rotation_retraction
            case "Hip_Rotation_Extension": return feedback.hip_rotation_extension
            case "Hip_Velocity_Retraction": return feedback.hip_velocity_retraction
            case "Elbow_Velocity_Extension": return feedback.elbow_velocity_extension
            case "Motion_Sequence": return feedback.motion_sequence
            case "Hip_Velocity_Extension": return feedback.hip_velocity_extension
            case "Foot_Placement_Retraction": return feedback.foot_placement_retraction
            case "Foot_Stepping_Direction_Extension": return feedback.foot_stepping_direction_extension
            case "Leg_To_Shoulder_Width_Guard": return feedback.leg_to_shoulder_width_guard
            case "Jab_Straight_Line_Extension": return feedback.jab_straight_line_extension
            case "Hand_Drop_Before_Extension": return feedback.hand_drop_before_extension
            case "Hand_Velocity_Extension": return feedback.hand_velocity_extension
            case "Hand_Velocity_Retraction": return feedback.hand_velocity_retraction
            case "Hands_Above_Shoulders_Guard": return feedback.hands_above_shoulders_guard
            case "Hip_Rotation_Retraction": return feedback.hip_rotation_retraction
            case "Torso_Rotation_Retraction": return feedback.torso_rotation_retraction
            case "Shoulder_Rotation_Extension": return feedback.shoulder_rotation_extension
            case "Head_Stability_Retraction": return feedback.head_stability_retraction
            case "Mean_Back_Leg_Angle_Retraction": return feedback.mean_back_leg_angle_retraction
            case "Return_Position_Difference_Retraction": return feedback.return_position_difference_retraction
            case "Foot_Placement_Guard": return feedback.foot_placement_guard
            case "Rear_Hand_In_Guard_Extension": return feedback.rear_hand_in_guard_extension
            case "Overall_Velocity_Extension": return feedback.overall_velocity_extension
            case "Foot_Velocity_Extension": return feedback.foot_velocity_extension
            case "Elbow_Straight_Line_Extension": return feedback.elbow_straight_line_extension
            case "Force_Generation_Extension": return feedback.force_generation_extension
            case "Mean_Back_Leg_Angle_Extension": return feedback.mean_back_leg_angle_extension
            case "Head_Stability_Guard": return feedback.head_stability_guard
            case "Foot_Steps_With_Punch_Diff_Extension": return feedback.foot_steps_with_punch_diff_extension
            case "Elbow_Protection_Extension": return feedback.elbow_protection_extension
            case "Chin_Lift_Extension": return feedback.chin_lift_extension
            case "Wrist_Angle_Extension": return feedback.wrist_angle_extension
            case "Foot_Velocity_Retraction": return feedback.foot_velocity_retraction
            case "Jab_Arm_Extension": return feedback.jab_arm_extension
            case "Elbow_Flare_Extension": return feedback.elbow_flare_extension
            case "Step_Distance_Extension": return feedback.step_distance_extension
            case "Mean_Back_Leg_Angle_Guard": return feedback.mean_back_leg_angle_guard
            case "Overall_Velocity_Retraction": return feedback.overall_velocity_retraction
            case "Head_Stability_Extension": return feedback.head_stability_extension
            case "Foot_Placement_Extension": return feedback.foot_placement_extension
            case "Chin_Tucked_Guard": return feedback.chin_tucked_guard
            case "Chin_Tucked_Retraction": return feedback.chin_tucked_retraction
            case "Hand_Velocity_Extension": return feedback.hand_velocity_extension
            case "Hand_Velocity_Retraction": return feedback.hand_velocity_retraction
            case "Hands_Above_Shoulders_Guard": return feedback.hands_above_shoulders_guard
            case "Whip_Effect_Extension": return feedback.whip_effect_extension
            case "Elbow_Velocity_Retraction": return feedback.elbow_velocity_retraction
            case "Shoulder_Velocity_Extension": return feedback.shoulder_velocity_extension
            case "Shoulder_Velocity_Retraction": return feedback.shoulder_velocity_retraction
            default: return nil
        }
    }
}

// Category Button Component
struct CategoryButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.medium)
                .padding(.horizontal, 16)
                .padding(.vertical, 8)
                .background(isSelected ? ThemeColors.primary : Color(.systemGray6))
                .foregroundColor(isSelected ? .white : .primary)
                .cornerRadius(8)
        }
        .buttonStyle(PlainButtonStyle())
    }
} 