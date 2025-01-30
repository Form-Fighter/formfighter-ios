struct MetricDefinition {
    let id: String
    let type: MetricType
    let displayName: String
    
    static let definitions: [String: MetricDefinition] = [
        // Head metrics
        "Chin_Lift_Extension": MetricDefinition(id: "Chin_Lift_Extension", type: .angle, displayName: "Chin Lift"),
        "Chin_Tucked_Extension": MetricDefinition(id: "Chin_Tucked_Extension", type: .boolean, displayName: "Chin Tucked Extension"),
        "Chin_Tucked_Guard": MetricDefinition(id: "Chin_Tucked_Guard", type: .boolean, displayName: "Chin Tucked Guard"),
        "Chin_Tucked_Retraction": MetricDefinition(id: "Chin_Tucked_Retraction", type: .boolean, displayName: "Chin Tucked Retraction"),
        "Head_Stability_Extension": MetricDefinition(id: "Head_Stability_Extension", type: .boolean, displayName: "Head Stability Extension"),
        "Head_Stability_Guard": MetricDefinition(id: "Head_Stability_Guard", type: .boolean, displayName: "Head Stability Guard"),
        "Head_Stability_Retraction": MetricDefinition(id: "Head_Stability_Retraction", type: .boolean, displayName: "Head Stability Retraction"),
        
        // Arms metrics
        "Elbow_Flare_Extension": MetricDefinition(id: "Elbow_Flare_Extension", type: .angle, displayName: "Elbow Flare"),
        "Elbow_Protection_Extension": MetricDefinition(id: "Elbow_Protection_Extension", type: .boolean, displayName: "Elbow Protection"),
        "Elbow_Straight_Line_Extension": MetricDefinition(id: "Elbow_Straight_Line_Extension", type: .boolean, displayName: "Straight Line Extension"),
        "Elbow_Velocity_Extension": MetricDefinition(id: "Elbow_Velocity_Extension", type: .velocity, displayName: "Elbow Extension Speed"),
        "Elbow_Velocity_Retraction": MetricDefinition(id: "Elbow_Velocity_Retraction", type: .velocity, displayName: "Elbow Retraction Speed"),
        "Hand_Drop_Before_Extension": MetricDefinition(id: "Hand_Drop_Before_Extension", type: .boolean, displayName: "Hand Drop"),
        "Hand_Velocity_Extension": MetricDefinition(id: "Hand_Velocity_Extension", type: .velocity, displayName: "Hand Extension Speed"),
        "Hand_Velocity_Retraction": MetricDefinition(id: "Hand_Velocity_Retraction", type: .velocity, displayName: "Hand Retraction Speed"),
        "Wrist_Angle_Extension": MetricDefinition(id: "Wrist_Angle_Extension", type: .angle, displayName: "Wrist Angle"),
        "Jab_Arm_Extension": MetricDefinition(id: "Jab_Arm_Extension", type: .boolean, displayName: "Jab Arm Extension"),
        "Jab_Straight_Line_Extension": MetricDefinition(id: "Jab_Straight_Line_Extension", type: .boolean, displayName: "Jab Straight Line"),
        "Rear_Hand_In_Guard_Extension": MetricDefinition(id: "Rear_Hand_In_Guard_Extension", type: .boolean, displayName: "Rear Hand In Guard"),
        
        // Shoulders metrics
        "Shoulder_Rotation_Extension": MetricDefinition(id: "Shoulder_Rotation_Extension", type: .angle, displayName: "Shoulder Rotation Extension"),
        "Shoulder_Rotation_Retraction": MetricDefinition(id: "Shoulder_Rotation_Retraction", type: .angle, displayName: "Shoulder Rotation Retraction"),
        "Shoulder_Velocity_Extension": MetricDefinition(id: "Shoulder_Velocity_Extension", type: .velocity, displayName: "Shoulder Extension Speed"),
        "Shoulder_Velocity_Retraction": MetricDefinition(id: "Shoulder_Velocity_Retraction", type: .velocity, displayName: "Shoulder Retraction Speed"),
        "Hands_Above_Shoulders_Guard": MetricDefinition(id: "Hands_Above_Shoulders_Guard", type: .boolean, displayName: "Hands Above Shoulders"),
        
        // Torso metrics
        "Torso_Rotation_Extension": MetricDefinition(id: "Torso_Rotation_Extension", type: .angle, displayName: "Torso Rotation Extension"),
        "Torso_Rotation_Retraction": MetricDefinition(id: "Torso_Rotation_Retraction", type: .angle, displayName: "Torso Rotation Retraction"),
        "Hip_Rotation_Extension": MetricDefinition(id: "Hip_Rotation_Extension", type: .angle, displayName: "Hip Rotation Extension"),
        "Hip_Rotation_Retraction": MetricDefinition(id: "Hip_Rotation_Retraction", type: .angle, displayName: "Hip Rotation Retraction"),
        "Hip_Velocity_Extension": MetricDefinition(id: "Hip_Velocity_Extension", type: .velocity, displayName: "Hip Extension Speed"),
        "Hip_Velocity_Retraction": MetricDefinition(id: "Hip_Velocity_Retraction", type: .velocity, displayName: "Hip Retraction Speed"),
        
        // Legs metrics
        "Leg_To_Shoulder_Width_Guard": MetricDefinition(id: "Leg_To_Shoulder_Width_Guard", type: .distance, displayName: "Leg to Shoulder Width"),
        "Mean_Back_Leg_Angle_Extension": MetricDefinition(id: "Mean_Back_Leg_Angle_Extension", type: .angle, displayName: "Back Leg Angle Extension"),
        "Mean_Back_Leg_Angle_Guard": MetricDefinition(id: "Mean_Back_Leg_Angle_Guard", type: .angle, displayName: "Back Leg Angle Guard"),
        "Mean_Back_Leg_Angle_Retraction": MetricDefinition(id: "Mean_Back_Leg_Angle_Retraction", type: .angle, displayName: "Back Leg Angle Retraction"),
        "Foot_Placement_Extension": MetricDefinition(id: "Foot_Placement_Extension", type: .distance, displayName: "Foot Placement Extension"),
        "Foot_Placement_Guard": MetricDefinition(id: "Foot_Placement_Guard", type: .distance, displayName: "Foot Placement Guard"),
        "Foot_Placement_Retraction": MetricDefinition(id: "Foot_Placement_Retraction", type: .distance, displayName: "Foot Placement Retraction"),
        "Foot_Velocity_Extension": MetricDefinition(id: "Foot_Velocity_Extension", type: .velocity, displayName: "Foot Extension Speed"),
        "Foot_Velocity_Retraction": MetricDefinition(id: "Foot_Velocity_Retraction", type: .velocity, displayName: "Foot Retraction Speed"),
        "Foot_Steps_With_Punch_Diff_Extension": MetricDefinition(id: "Foot_Steps_With_Punch_Diff_Extension", type: .boolean, displayName: "Foot Steps With Punch"),
        "Step_Distance_Extension": MetricDefinition(id: "Step_Distance_Extension", type: .distance, displayName: "Step Distance"),
        
        // Overall metrics
        "Force_Generation_Extension": MetricDefinition(id: "Force_Generation_Extension", type: .power, displayName: "Knock Out Power"),
        "Motion_Sequence": MetricDefinition(id: "Motion_Sequence", type: .sequence, displayName: "Motion Sequence"),
        "Overall_Velocity_Extension": MetricDefinition(id: "Overall_Velocity_Extension", type: .velocity, displayName: "Overall Extension Speed"),
        "Overall_Velocity_Retraction": MetricDefinition(id: "Overall_Velocity_Retraction", type: .velocity, displayName: "Overall Retraction Speed"),
        "Whip_Effect_Extension": MetricDefinition(id: "Whip_Effect_Extension", type: .boolean, displayName: "Whip Effect"),
        "Return_Position_Difference_Retraction": MetricDefinition(id: "Return_Position_Difference_Retraction", type: .distance, displayName: "Return Position Difference")
    ]
} 