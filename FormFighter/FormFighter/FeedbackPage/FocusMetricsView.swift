import SwiftUI

// struct FocusMetricsView: View {
//     let metrics: FeedbackModels.BodyFeedback
//     let feedbackId: String
//     @EnvironmentObject var userManager: UserManager
//     @State private var compareWithLastPunch = false
    
//     var body: some View {
//         VStack(spacing: 16) {
//             // Toggle for comparison
//             Toggle("Compare with last punch", isOn: $compareWithLastPunch)
//                 .padding(.horizontal)
            
//             ScrollView {
//                 VStack(spacing: 24) {
//                     if UserManager.shared.pinnedMetrics.isEmpty {
//                         Text("No focus metrics selected")
//                             .foregroundColor(.secondary)
//                             .padding()
//                     } else {
//                         ForEach(UserManager.shared.pinnedMetrics, id: \.id) { metric in
//                             MetricComparisonCard(
//                                 metric: metric,
//                                 currentMetrics: metrics,
//                                 feedbackId: feedbackId,
//                                 compareWithLastPunch: compareWithLastPunch
//                             )
//                         }
//                     }
//                 }
//                 .padding()
//             }
//         }
//     }
// }

struct MetricComparisonCard: View {
    let metric: PinnedMetric
    let currentMetrics: FeedbackModels.BodyFeedback
    let feedbackId: String
    let compareWithLastPunch: Bool
    @EnvironmentObject private var feedbackManager: FeedbackManager
    
    private var shouldHideScore: Bool {
        let hideScoreMetrics = [
            "Motion_Sequence",
            "Whip_Effect_Extension",
            "Return_Position_Difference_Retraction",
            "Rear_Hand_In_Guard_Extension",
            "Hands_Above_Shoulders_Guard",
            "Foot_Steps_With_Punch_Diff_Extension"
        ]
        return hideScoreMetrics.contains(metric.id)
    }
    
    private var isForceGeneration: Bool {
        return metric.id == "Force_Generation_Extension"
    }
    
    private var isMotionSequence: Bool {
        return metric.id == "Motion_Sequence"
    }
    
    private var isBooleanMetric: Bool {
        let metricData = getMetricData(from: currentMetrics, for: metric.id)
        if let value = metricData?.metric_values?.lowercased() {
            return value == "true" || value == "false"
        }
        return false
    }
    
    private var isVelocityMetric: Bool {
        return metric.id.lowercased().contains("velocity")
    }
    
    private func getMetricData(from feedback: FeedbackModels.BodyFeedback, for metricId: String) -> FeedbackModels.MetricDetails? {
        switch metricId {
            // Head metrics
            case "Chin_Lift_Extension": return feedback.chin_lift_extension
            case "Chin_Tucked_Extension": return feedback.chin_tucked_extension
            case "Chin_Tucked_Guard": return feedback.chin_tucked_guard
            case "Chin_Tucked_Retraction": return feedback.chin_tucked_retraction
            case "Head_Stability_Extension": return feedback.head_stability_extension
            case "Head_Stability_Guard": return feedback.head_stability_guard
            case "Head_Stability_Retraction": return feedback.head_stability_retraction
            
            // Arms metrics
            case "Elbow_Flare_Extension": return feedback.elbow_flare_extension
            case "Elbow_Protection_Extension": return feedback.elbow_protection_extension
            case "Elbow_Straight_Line_Extension": return feedback.elbow_straight_line_extension
            case "Elbow_Velocity_Extension": return feedback.elbow_velocity_extension
            case "Elbow_Velocity_Retraction": return feedback.elbow_velocity_retraction
            case "Hand_Drop_Before_Extension": return feedback.hand_drop_before_extension
            case "Hand_Velocity_Extension": return feedback.hand_velocity_extension
            case "Hand_Velocity_Retraction": return feedback.hand_velocity_retraction
            case "Wrist_Angle_Extension": return feedback.wrist_angle_extension
            case "Jab_Arm_Extension": return feedback.jab_arm_extension
            case "Jab_Straight_Line_Extension": return feedback.jab_straight_line_extension
            case "Rear_Hand_In_Guard_Extension": return feedback.rear_hand_in_guard_extension
            
            // Shoulders metrics
            case "Shoulder_Rotation_Extension": return feedback.shoulder_rotation_extension
            case "Shoulder_Rotation_Retraction": return feedback.shoulder_rotation_retraction
            case "Shoulder_Velocity_Extension": return feedback.shoulder_velocity_extension
            case "Shoulder_Velocity_Retraction": return feedback.shoulder_velocity_retraction
            case "Hands_Above_Shoulders_Guard": return feedback.hands_above_shoulders_guard
            
            // Torso metrics
            case "Torso_Rotation_Extension": return feedback.torso_rotation_extension
            case "Torso_Rotation_Retraction": return feedback.torso_rotation_retraction
            case "Hip_Rotation_Extension": return feedback.hip_rotation_extension
            case "Hip_Rotation_Retraction": return feedback.hip_rotation_retraction
            case "Hip_Velocity_Extension": return feedback.hip_velocity_extension
            case "Hip_Velocity_Retraction": return feedback.hip_velocity_retraction
            
            // Legs metrics
            case "Leg_To_Shoulder_Width_Guard": return feedback.leg_to_shoulder_width_guard
            case "Mean_Back_Leg_Angle_Extension": return feedback.mean_back_leg_angle_extension
            case "Mean_Back_Leg_Angle_Guard": return feedback.mean_back_leg_angle_guard
            case "Mean_Back_Leg_Angle_Retraction": return feedback.mean_back_leg_angle_retraction
            case "Foot_Placement_Extension": return feedback.foot_placement_extension
            case "Foot_Placement_Guard": return feedback.foot_placement_guard
            case "Foot_Placement_Retraction": return feedback.foot_placement_retraction
            case "Foot_Velocity_Extension": return feedback.foot_velocity_extension
            case "Foot_Velocity_Retraction": return feedback.foot_velocity_retraction
            case "Foot_Steps_With_Punch_Diff_Extension": return feedback.foot_steps_with_punch_diff_extension
            case "Foot_Stepping_Direction_Extension": return feedback.foot_stepping_direction_extension
            case "Step_Distance_Extension": return feedback.step_distance_extension
            
            // Overall metrics
            case "Force_Generation_Extension": return feedback.force_generation_extension
            case "Motion_Sequence": return feedback.motion_sequence
            case "Overall_Velocity_Extension": return feedback.overall_velocity_extension
            case "Overall_Velocity_Retraction": return feedback.overall_velocity_retraction
            case "Whip_Effect_Extension": return feedback.whip_effect_extension
            case "Return_Position_Difference_Retraction": return feedback.return_position_difference_retraction
            
            default: return nil
        }
    }
    
    private func extractBooleanValue(from metrics: FeedbackModels.BodyFeedback, for metricId: String) -> Bool {
        guard let metricData = getMetricData(from: metrics, for: metricId),
              let value = metricData.metric_values?.lowercased() else {
            return false
        }
        return value == "true"
    }
    
    private func getComparisonBooleanValue(for metricId: String) -> Bool {
        if compareWithLastPunch {
            return feedbackManager.getLastBooleanMetricValue(for: metricId, excluding: feedbackId)
        } else {
            return feedbackManager.getAverageBooleanMetricValue(for: metricId)
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(formatTitle(metric.displayName))
                .font(.headline)
            
            if isMotionSequence {
                motionSequenceView
            } else if isForceGeneration {
                forceGenerationView
            } else if isBooleanMetric {
                booleanComparisonView
            } else if isVelocityMetric {
                velocityComparisonView
            } else if !shouldHideScore {
                regularMetricView
            }
            
            // Add description, buffer zone, etc if needed
            metricDetailsView
        }
        .padding()
        .background(Color(.secondarySystemBackground))
        .cornerRadius(12)
    }
    
    private func booleanIndicator(value: Bool, label: String) -> some View {
        VStack(alignment: .center) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Image(systemName: value ? "checkmark.circle.fill" : "x.circle.fill")
                .foregroundColor(value ? .green : .red)
                .font(.title2)
        }
    }
    
    private func valueDisplay(value: Double, comparisonValue: Double, label: String) -> some View {
        VStack(alignment: .center) {
            Text(label)
                .font(.subheadline)
                .foregroundColor(.secondary)
            Text(String(format: "%.1f", value))
                .font(.title2.bold())
            if label != "Current" {
                let percentage = ((value - comparisonValue) / comparisonValue) * 100
                if abs(percentage) > 0.1 {
                    Text(String(format: "%+.1f%%", percentage))
                        .foregroundColor(value >= comparisonValue ? .green : .red)
                        .font(.caption)
                } else {
                    Text("=")
                        .foregroundColor(.secondary)
                        .font(.caption)
                }
            }
        }
    }
    
    private func extractMetricValue(from metrics: FeedbackModels.BodyFeedback, for metricId: String) -> Double {
        // Implementation similar to FeedbackManager.extractVelocity
        return FeedbackManager.shared.extractValue(from: metrics, for: metricId)
    }
    
    private func getComparisonValue(for metricId: String) -> Double {
        if compareWithLastPunch {
            return FeedbackManager.shared.getLastMetricValue(for: metricId, excluding: feedbackId)
        } else {
            return FeedbackManager.shared.getAverageMetricValue(for: metricId)
        }
    }
    
    private func formatTitle(_ title: String) -> String {
        if title == "Force_Generation_Extension" {
            return "Knock Out Power"
        }
        return title.replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
    
    private var motionSequenceView: some View {
        Text("Motion Sequence Analysis")
            .font(.headline)
    }
    
    private var forceGenerationView: some View {
        let currentValue = extractMetricValue(from: currentMetrics, for: metric.id)
        let comparisonValue = getComparisonValue(for: metric.id)
        
        return VStack(alignment: .leading, spacing: 8) {
            Text("Knock Out Power")
                .font(.headline)
            HStack {
                valueDisplay(value: currentValue, comparisonValue: comparisonValue, label: "Current")
                Spacer()
                valueDisplay(value: comparisonValue, comparisonValue: currentValue, 
                           label: compareWithLastPunch ? "Last Punch" : "Average")
            }
        }
    }
    
    private var booleanComparisonView: some View {
        let currentValue = extractBooleanValue(from: currentMetrics, for: metric.id)
        let comparisonValue = getComparisonBooleanValue(for: metric.id)
        
        return HStack(spacing: 20) {
            booleanIndicator(value: currentValue, label: "Current")
            Spacer()
            booleanIndicator(value: comparisonValue, 
                           label: compareWithLastPunch ? "Last Punch" : "Average")
        }
    }
    
    private var velocityComparisonView: some View {
        let currentValue = extractMetricValue(from: currentMetrics, for: metric.id)
        let comparisonValue = getComparisonValue(for: metric.id)
        
        return HStack {
            valueDisplay(value: currentValue, comparisonValue: comparisonValue, label: "Current")
            Spacer()
            valueDisplay(value: comparisonValue, comparisonValue: currentValue, 
                       label: compareWithLastPunch ? "Last Punch" : "Average")
        }
    }
    
    private var regularMetricView: some View {
        let currentValue = extractMetricValue(from: currentMetrics, for: metric.id)
        let comparisonValue = getComparisonValue(for: metric.id)
        
        return HStack {
            valueDisplay(value: currentValue, comparisonValue: comparisonValue, label: "Current")
            Spacer()
            valueDisplay(value: comparisonValue, comparisonValue: currentValue, 
                       label: compareWithLastPunch ? "Last Punch" : "Average")
        }
    }
    
    private var metricDetailsView: some View {
        EmptyView() // Placeholder for now
    }
} 
