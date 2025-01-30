import SwiftUI
import Foundation
enum MetricsConstants {
    static  let groupedMetrics: [String: [String]] = [
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

    static func getExplanation(for metricId: String) -> String {
        switch metricId {
        // Head metrics
        case "Chin_Lift_Extension":
            return "Monitors if you're lifting your chin during the punch, which could leave you vulnerable"
        case "Chin_Tucked_Extension":
            return "Ensures you're keeping your chin protected while punching"
        case "Chin_Tucked_Guard":
            return "Checks if your chin stays protected in your guard position"
        case "Chin_Tucked_Retraction":
            return "Monitors chin position as you return to guard"
        case "Head_Stability_Extension":
            return "Tracks if your head stays steady during the punch"
        case "Head_Stability_Guard":
            return "Measures how still you keep your head in guard position"
        case "Head_Stability_Retraction":
            return "Analyzes head movement as you return to guard"

        // Arms metrics
        case "Elbow_Flare_Extension":
            return "Checks if your elbow stays tight to your body during the punch"
        case "Elbow_Protection_Extension":
            return "Monitors if your elbow stays in a protective position while punching"
        case "Elbow_Straight_Line_Extension":
            return "Ensures your elbow follows a straight path for maximum efficiency"
        case "Elbow_Velocity_Extension":
            return "Measures how quickly your elbow extends during the punch"
        case "Elbow_Velocity_Retraction":
            return "Tracks the speed of your elbow returning to guard"
        case "Hand_Drop_Before_Extension":
            return "Detects if you're telegraphing your punch by dropping your hand"
        case "Hand_Velocity_Extension":
            return "Measures the speed of your hand during the punch"
        case "Hand_Velocity_Retraction":
            return "Tracks how quickly you bring your hand back to guard"
        case "Wrist_Angle_Extension":
            return "Ensures proper wrist alignment for maximum impact"
        case "Jab_Arm_Extension":
            return "Measures how fully you extend your jabbing arm"
        case "Jab_Straight_Line_Extension":
            return "Tracks if your jab follows the shortest path to the target"
        case "Rear_Hand_In_Guard_Extension":
            return "Monitors if your rear hand stays in guard while jabbing"

        // Shoulders metrics
        case "Shoulder_Rotation_Extension":
            return "Measures how well you rotate your shoulder for power generation"
        case "Shoulder_Rotation_Retraction":
            return "Tracks shoulder rotation as you return to guard"
        case "Shoulder_Velocity_Extension":
            return "Measures the speed of your shoulder rotation during the punch"
        case "Shoulder_Velocity_Retraction":
            return "Analyzes how quickly your shoulder returns to guard position"
        case "Hands_Above_Shoulders_Guard":
            return "Ensures your hands stay at proper guard height"

        // Torso metrics
        case "Torso_Rotation_Extension":
            return "Measures how well you rotate your torso for maximum power"
        case "Torso_Rotation_Retraction":
            return "Tracks torso rotation as you return to guard"
        case "Hip_Rotation_Extension":
            return "Analyzes hip rotation for optimal power transfer"
        case "Hip_Rotation_Retraction":
            return "Measures hip rotation during the return to guard"
        case "Hip_Velocity_Extension":
            return "Tracks the speed of your hip rotation while punching"
        case "Hip_Velocity_Retraction":
            return "Measures how quickly your hips return to starting position"

        // Legs metrics
        case "Leg_To_Shoulder_Width_Guard":
            return "Ensures proper stance width for stability"
        case "Mean_Back_Leg_Angle_Extension":
            return "Monitors back leg position during the punch"
        case "Mean_Back_Leg_Angle_Guard":
            return "Checks if your back leg is properly positioned in guard"
        case "Mean_Back_Leg_Angle_Retraction":
            return "Tracks back leg position as you return to guard"
        case "Foot_Placement_Extension":
            return "Ensures proper foot positioning while punching"
        case "Foot_Placement_Guard":
            return "Checks if your feet are properly positioned in guard"
        case "Foot_Placement_Retraction":
            return "Monitors foot position as you return to guard"
        case "Foot_Velocity_Extension":
            return "Tracks foot movement during the punch"
        case "Foot_Velocity_Retraction":
            return "Measures foot movement speed returning to guard"
        case "Foot_Steps_With_Punch_Diff_Extension":
            return "Detects if you're stepping while punching"
        case "Foot_Stepping_Direction_Extension":
            return "Analyzes the direction of any foot movement during the punch"
        case "Step_Distance_Extension":
            return "Measures how far you step while punching"

        // Overall metrics
        case "Force_Generation_Extension":
            return "Measures the power behind your punch and its knockout potential"
        case "Motion_Sequence":
            return "Analyzes the timing and coordination of your movements"
        case "Overall_Velocity_Extension":
            return "Tracks how fast your jab is moving forward"
        case "Overall_Velocity_Retraction":
            return "Measures the speed of your return to guard position"
        case "Whip_Effect_Extension":
            return "Measures the snap and acceleration of your punch"
        case "Return_Position_Difference_Retraction":
            return "Checks if your hand returns to the correct guard position"
        default:
            let readableName = metricId.replacingOccurrences(of: "_", with: " ")
                .capitalized
            return "Analyzes your \(readableName.lowercased()) for optimal technique"
        }
    }
} 