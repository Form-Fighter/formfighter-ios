import Foundation
import Firebase
import FirebaseFirestore
import os.log

enum MetricType {
    case velocity     // meters/second
    case power       // Newtons
    case angle       // degrees
    case distance    // meters
    case boolean     // true/false
    case sequence    // special case for motion sequence
    
    var unit: String {
        switch self {
            case .velocity: return "meters/second"
            case .power: return "Newtons"
            case .angle: return "degrees"
            case .distance: return "meters"
            case .boolean: return ""
            case .sequence: return ""
        }
    }
}

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
        
        // Arms and Hands metrics
        "Elbow_Flare_Extension": MetricDefinition(id: "Elbow_Flare_Extension", type: .angle, displayName: "Elbow Flare"),
        "Elbow_Protection_Extension": MetricDefinition(id: "Elbow_Protection_Extension", type: .boolean, displayName: "Elbow Protection"),
        "Elbow_Straight_Line_Extension": MetricDefinition(id: "Elbow_Straight_Line_Extension", type: .boolean, displayName: "Elbow Straight Line"),
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
        
        // Legs and Feet metrics
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

class FeedbackManager: ObservableObject {
    static let shared = FeedbackManager()
    
    @Published var feedbacks: [FeedbackListItem] = []
    @Published var personalBest: Double = 0.0
    @Published var isLoading = true
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var feedbackListener: ListenerRegistration?
    private let logger = OSLog(subsystem: "com.formfighter", category: "FeedbackManager")
    
    init() {
        setupAuthStateListener()
    }
    
    private func setupAuthStateListener() {
        Auth.auth().addStateDidChangeListener { [weak self] (_, user) in
            if let userId = user?.uid {
                self?.startListening(for: userId)
            } else {
                self?.stopListening()
                self?.feedbacks = []
                self?.personalBest = 0.0
            }
        }
    }
    
    func startListening(for userId: String) {
        stopListening() // Clean up existing listener
        print("🔥 Starting feedback listener for user: \(userId)")
        isLoading = true
        
        feedbackListener = db.collection("feedback")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self else { 
                    print("⚠️ Self is nil in feedback listener")
                    return 
                }
                
                print("📥 Received snapshot update")
                
                if let error = error {
                    print("❌ Error fetching feedback: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    print("ℹ️ No feedback documents found")
                    self.feedbacks = []  // Clear existing feedbacks
                    self.isLoading = false
                    return
                }
                
                print("📊 Processing \(documents.count) feedback documents")
                
                self.feedbacks = documents.compactMap { document in
                    let data = document.data()
                    
                    // Skip if document has an error field or missing/null status
                    guard data["error"] == nil,
                          let statusString = data["status"] as? String,
                          !statusString.isEmpty,
                          let status = FeedbackStatus(rawValue: statusString),
                          status != .error  // Also skip if status is error
                    else {
                        return nil
                    }
                    
                    let jabScore: Double
                    if status == .completed {
                        if let modelFeedback = data["modelFeedback"] as? [String: Any],
                           let body = modelFeedback["body"] as? [String: Any],
                           let score = body["jab_score"] as? Double {
                            jabScore = score
                        } else {
                            jabScore = 0.0
                        }
                    } else {
                        jabScore = 0.0
                    }
                    
                    let modelFeedbackData = data["modelFeedback"] as? [String: Any] ?? [:]
                    let modelFeedback: FeedbackModels.ModelFeedback?
                    
                    do {
                        print("📦 Raw model feedback data: \(modelFeedbackData)")
                        // Convert Firestore data to JSON-safe format
                        let jsonSafeData = self.convertFirestoreDataToJSON(modelFeedbackData)
                        print("🔄 Converted JSON-safe data: \(jsonSafeData)")
                        let jsonData = try JSONSerialization.data(withJSONObject: jsonSafeData)
                        modelFeedback = try JSONDecoder().decode(FeedbackModels.ModelFeedback.self, from: jsonData)
                        print("✅ Successfully decoded model feedback")
                    } catch {
                        print("❌ Error decoding model feedback: \(error)")
                        print("❌ JSON conversion failed at step: \(error.localizedDescription)")
                        modelFeedback = nil
                    }
                    
                    return FeedbackListItem(
                        id: document.documentID,
                        date: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        status: status,
                        videoUrl: data["videoUrl"] as? String,
                        score: jabScore,
                        modelFeedback: modelFeedback
                    )
                }
                
                self.personalBest = self.feedbacks
                    .filter { $0.isCompleted }
                    .map { $0.score }
                    .max() ?? 0.0
            
                print("✅ Finished processing feedback. Count: \(self.feedbacks.count)")
                print("✅ Setting isLoading to false")
                self.isLoading = false
            }
    }
    
    func stopListening() {
        feedbackListener?.remove()
    }
    
    deinit {
        stopListening()
    }
    
    struct BestScores {
        let overall: Double
        let `extension`: Double
        let guardPosition: Double
        let retraction: Double
    }
    
    func getBestScores() -> BestScores {
        let completedFeedbacks = feedbacks.filter { $0.isCompleted }
        
        // Find the feedback with the highest overall score
        if let bestFeedback = completedFeedbacks.max(by: { $0.score < $1.score }),
           let modelFeedback = bestFeedback.modelFeedback?.body?.feedback {
            return BestScores(
                overall: bestFeedback.score,
                extension: modelFeedback.extensionFeedback?.score ?? 0,
                guardPosition: modelFeedback.guardPosition?.score ?? 0,
                retraction: modelFeedback.retraction?.score ?? 0
            )
        }
        
        return BestScores(overall: 0, extension: 0, guardPosition: 0, retraction: 0)
    }
    
    func getLastFeedback(excluding currentId: String) -> FeedbackListItem? {
        return feedbacks
            .filter { $0.id != currentId && $0.isCompleted }
            .sorted { $0.date > $1.date }
            .first
    }
    
    func getAverageMetrics() -> AverageMetrics {
        let completedFeedbacks = feedbacks.filter { $0.isCompleted }
        print("📊 Found \(completedFeedbacks.count) completed feedbacks")
        
        var totalHandExtension = 0.0
        var totalHandRetraction = 0.0
        var totalFootExtension = 0.0
        var totalFootRetraction = 0.0
        var totalPower = 0.0
        var count = 0
        
        for feedback in completedFeedbacks {
            if let metrics = feedback.modelFeedback?.body {
                print("📊 Processing feedback: \(feedback.id)")
                
                let handExt = extractVelocity(from: metrics.hand_velocity_extension)
                let handRet = extractVelocity(from: metrics.hand_velocity_retraction)
                let footExt = extractVelocity(from: metrics.foot_velocity_extension)
                let footRet = extractVelocity(from: metrics.foot_velocity_retraction)
                let power = extractPower(from: metrics.force_generation_extension)
                
                totalHandExtension += handExt
                totalHandRetraction += handRet
                totalFootExtension += footExt
                totalFootRetraction += footRet
                totalPower += power
                count += 1
            }
        }
        
        // Avoid division by zero
        guard count > 0 else {
            print("⚠️ No valid feedbacks found for averaging")
            return AverageMetrics(
                handExtensionSpeed: 0.0,
                handRetractionSpeed: 0.0,
                footExtensionSpeed: 0.0,
                footRetractionSpeed: 0.0,
                power: 0.0
            )
        }
        
        let averages = AverageMetrics(
            handExtensionSpeed: totalHandExtension / Double(count),
            handRetractionSpeed: totalHandRetraction / Double(count),
            footExtensionSpeed: totalFootExtension / Double(count),
            footRetractionSpeed: totalFootRetraction / Double(count),
            power: totalPower / Double(count)
        )
        
        print("""
            📊 Final averages:
            - Hand Extension: \(averages.handExtensionSpeed)
            - Hand Retraction: \(averages.handRetractionSpeed)
            - Foot Extension: \(averages.footExtensionSpeed)
            - Foot Retraction: \(averages.footRetractionSpeed)
            - Power: \(averages.power)
            """)
        
        return averages
    }
    
     func createMetricDetails(value: Double, unit: String) -> [String: Any] {
        return [
            "metric_values": "\(String(format: "%.2f")) \(unit)"
        ]
    }
    
     func extractVelocity(from metric: FeedbackModels.MetricDetails?) -> Double {
        guard let valueString = metric?.metric_values else {
            print("⚠️ No metric_values found")
            return 0.0
        }
        
        print("📊 Raw velocity string: \(valueString)")
        
        let cleanedString = valueString.trimmingCharacters(in: .whitespaces)
                                     .replacingOccurrences(of: " meters/second", with: "")
        
        print("📊 Cleaned velocity string: \(cleanedString)")
        
        guard let value = Double(cleanedString) else {
            print("❌ Failed to convert to Double: \(cleanedString)")
            return 0.0
        }
        
        print("✅ Extracted velocity: \(value)")
        return value
    }
    
     func extractPower(from metric: FeedbackModels.MetricDetails?) -> Double {
        guard let valueString = metric?.metric_values else {
            print("⚠️ No metric_values found")
            return 0.0
        }
        
        print("📊 Raw power string: \(valueString)")
        
        // The format appears to be "130.16 Newtons " with a space at the end
        let cleanedString = valueString.trimmingCharacters(in: .whitespaces)
                                     .replacingOccurrences(of: " Newtons", with: "")
        
        print("📊 Cleaned power string: \(cleanedString)")
        
        guard let value = Double(cleanedString) else {
            print("❌ Failed to convert to Double: \(cleanedString)")
            return 0.0
        }
        
        print("✅ Extracted power: \(value)")
        return value
    }
    
    private func convertFirestoreDataToJSON(_ data: [String: Any]) -> [String: Any] {
        var result: [String: Any] = [:]
        
        for (key, value) in data {
            if let timestamp = value as? Timestamp {
                // Convert Timestamp to ISO8601 string
                result[key] = timestamp.dateValue().ISO8601Format()
            } else if let nestedDict = value as? [String: Any] {
                // Recursively convert nested dictionaries
                result[key] = convertFirestoreDataToJSON(nestedDict)
            } else if let array = value as? [[String: Any]] {
                // Handle arrays of dictionaries
                result[key] = array.map { convertFirestoreDataToJSON($0) }
            } else {
                result[key] = value
            }
        }
        
        return result
    }
    
    func getMetricData(for metricId: String, from feedback: FeedbackModels.BodyFeedback) -> FeedbackModels.MetricDetails? {
        print("🔍 Getting metric data for: \(metricId)")
        switch metricId {
            // Head metrics
            case "Chin_Lift_Extension": return feedback.chin_lift_extension
            case "Chin_Tucked_Extension": return feedback.chin_tucked_extension
            case "Chin_Tucked_Guard": return feedback.chin_tucked_guard
            case "Chin_Tucked_Retraction": return feedback.chin_tucked_retraction
            case "Head_Stability_Extension": return feedback.head_stability_extension
            case "Head_Stability_Guard": return feedback.head_stability_guard
            case "Head_Stability_Retraction": return feedback.head_stability_retraction
            
            // Arms and Hands
            case "Hand_Velocity_Extension": return feedback.hand_velocity_extension
            case "Hand_Velocity_Retraction": return feedback.hand_velocity_retraction
            case "Hand_Drop_Before_Extension": return feedback.hand_drop_before_extension
            case "Elbow_Velocity_Extension": return feedback.elbow_velocity_extension
            case "Elbow_Velocity_Retraction": return feedback.elbow_velocity_retraction
            case "Elbow_Flare_Extension": return feedback.elbow_flare_extension
            case "Elbow_Protection_Extension": return feedback.elbow_protection_extension
            case "Elbow_Straight_Line_Extension": return feedback.elbow_straight_line_extension
            case "Wrist_Angle_Extension": return feedback.wrist_angle_extension
            case "Jab_Arm_Extension": return feedback.jab_arm_extension
            case "Jab_Straight_Line_Extension": return feedback.jab_straight_line_extension
            case "Rear_Hand_In_Guard_Extension": return feedback.rear_hand_in_guard_extension
            
            // Shoulders
            case "Shoulder_Velocity_Extension": return feedback.shoulder_velocity_extension
            case "Shoulder_Velocity_Retraction": return feedback.shoulder_velocity_retraction
            case "Shoulder_Rotation_Extension": return feedback.shoulder_rotation_extension
            case "Shoulder_Rotation_Retraction": return feedback.shoulder_rotation_retraction
            case "Hands_Above_Shoulders_Guard": return feedback.hands_above_shoulders_guard
            
            // Torso and Hips
            case "Hip_Velocity_Extension": return feedback.hip_velocity_extension
            case "Hip_Velocity_Retraction": return feedback.hip_velocity_retraction
            case "Hip_Rotation_Extension": return feedback.hip_rotation_extension
            case "Hip_Rotation_Retraction": return feedback.hip_rotation_retraction
            case "Torso_Rotation_Extension": return feedback.torso_rotation_extension
            case "Torso_Rotation_Retraction": return feedback.torso_rotation_retraction
            
            // Legs and Feet
            case "Foot_Velocity_Extension": return feedback.foot_velocity_extension
            case "Foot_Velocity_Retraction": return feedback.foot_velocity_retraction
            case "Foot_Placement_Extension": return feedback.foot_placement_extension
            case "Foot_Placement_Guard": return feedback.foot_placement_guard
            case "Foot_Placement_Retraction": return feedback.foot_placement_retraction
            case "Foot_Steps_With_Punch_Diff_Extension": return feedback.foot_stepping_direction_extension
            case "Step_Distance_Extension": return feedback.step_distance_extension
            case "Leg_To_Shoulder_Width_Guard": return feedback.leg_to_shoulder_width_guard
            case "Mean_Back_Leg_Angle_Extension": return feedback.mean_back_leg_angle_extension
            case "Mean_Back_Leg_Angle_Guard": return feedback.mean_back_leg_angle_guard
            case "Mean_Back_Leg_Angle_Retraction": return feedback.mean_back_leg_angle_retraction
            
            // Overall metrics
            case "Force_Generation_Extension": return feedback.force_generation_extension
            case "Motion_Sequence": return feedback.motion_sequence
            case "Overall_Velocity_Extension": return feedback.overall_velocity_extension
            case "Overall_Velocity_Retraction": return feedback.overall_velocity_retraction
            case "Whip_Effect_Extension": return feedback.whip_effect_extension
            case "Return_Position_Difference_Retraction": return feedback.return_position_difference_retraction
            
            default:
                print("⚠️ No case for metric: \(metricId)")
                return nil
        }
    }
    
    func extractValue(from metrics: FeedbackModels.BodyFeedback, for metricId: String) -> Double {
        print("🎯 Extracting value for: \(metricId)")
        guard let metricDefinition = MetricDefinition.definitions[metricId] else { 
            print("❌ No metric definition found for: \(metricId)")
            return 0.0 
        }
        guard let metricData = getMetricData(for: metricId, from: metrics) else { 
            print("❌ No metric data found for: \(metricId)")
            return 0.0 
        }
        
        print("📝 Metric type: \(metricDefinition.type)")
        print("📝 Raw metric data: \(metricData)")
        
        switch metricDefinition.type {
            case .velocity, .distance:
                let value = extractVelocity(from: metricData)
                print("🏃‍♂️ Extracted velocity/distance: \(value)")
                return value
            case .power:
                let value = extractPower(from: metricData)
                print("💪 Extracted power: \(value)")
                return value
            case .angle:
                let value = extractAngle(from: metricData) ?? 0.0
                print("📐 Extracted angle: \(value)")
                return value
            case .boolean:
                let value = metricData.metric_values?.lowercased() == "true" ? 1.0 : 0.0
                print("✅ Extracted boolean: \(value)")
                return value
            case .sequence:
                print("📋 Sequence type - returning 0")
                return 0.0
        }
    }
    
    func getLastMetricValue(for metricId: String, excluding feedbackId: String) -> Double {
        guard let lastFeedback = self.getLastFeedback(excluding: feedbackId)?.modelFeedback?.body else {
            return 0.0
        }
        return extractValue(from: lastFeedback, for: metricId)
    }
    
    func getAverageMetricValue(for metricId: String) -> Double {
        let feedbacks = self.getAllFeedback()
        var total = 0.0
        var count = 0
        
        for feedback in feedbacks {
            guard let body = feedback.modelFeedback?.body else { continue }
            let value = extractValue(from: body, for: metricId)
            total += value
            count += 1
        }
        
        return count > 0 ? total / Double(count) : 0.0
    }
    
    func getLastBooleanMetricValue(for metricId: String, excluding feedbackId: String) -> Bool {
        guard let lastFeedback = self.getLastFeedback(excluding: feedbackId)?.modelFeedback?.body,
              let metricData = getMetricData(for: metricId, from: lastFeedback) else {
            return false
        }
        return metricData.metric_values?.lowercased() == "true"
    }
    
    func getAverageBooleanMetricValue(for metricId: String) -> Bool {
        let feedbacks = self.getAllFeedback()
        var trueCount = 0
        var totalCount = 0
        
        for feedback in feedbacks {
            guard let body = feedback.modelFeedback?.body,
                  let metricData = getMetricData(for: metricId, from: body) else { continue }
            
            if metricData.metric_values?.lowercased() == "true" {
                trueCount += 1
            }
            totalCount += 1
        }
        
        return totalCount > 0 ? (Double(trueCount) / Double(totalCount) >= 0.5) : false
    }
    
    private func extractAngle(from metric: FeedbackModels.MetricDetails?) -> Double? {
        guard let metricValues = metric?.metric_values else { return nil }
        let components = metricValues.split(separator: " ")
        guard components.count >= 1,
              let value = Double(components[0]) else {
            return nil
        }
        return value
    }
    
    func getAllFeedback() -> [FeedbackListItem] {
        return feedbacks.filter { $0.isCompleted }
    }
    
    func getMetricValue(from metrics: FeedbackModels.BodyFeedback, for metricId: String) -> String {
        guard let metricDefinition = MetricDefinition.definitions[metricId],
              let metricData = getMetricData(for: metricId, from: metrics) else {
            return "N/A"
        }
        
        switch metricDefinition.type {
            case .velocity:
                return String(format: "%.2f m/s", extractVelocity(from: metricData))
            case .power:
                return String(format: "%.2f N", extractPower(from: metricData))
            case .angle:
                if let angle = extractAngle(from: metricData) {
                    return String(format: "%.1f°", angle)
                }
            case .distance:
                return String(format: "%.2f m", extractValue(from: metrics, for: metricId))
            case .boolean:
                return metricData.metric_values?.lowercased() == "true" ? "Yes" : "No"
            case .sequence:
                return metricData.metric_values ?? "N/A"
        }
        return "N/A"
    }
    
    func getComparisonValue(for metricId: String, excluding feedbackId: String, compareWithLastPunch: Bool) -> String {
        let metricDefinition = MetricDefinition.definitions[metricId]
        
        if compareWithLastPunch {
            guard let lastFeedback = getLastFeedback(excluding: feedbackId)?.modelFeedback?.body else {
                return "N/A"
            }
            return getMetricValue(from: lastFeedback, for: metricId)
        } else {
            let value = getAverageMetricValue(for: metricId)
            
            switch metricDefinition?.type {
                case .velocity:
                    return String(format: "%.2f m/s", value)
                case .power:
                    return String(format: "%.2f N", value)
                case .angle:
                    return String(format: "%.1f°", value)
                case .distance:
                    return String(format: "%.2f m", value)
                case .boolean:
                    return value > 0.5 ? "Yes" : "No"
                case .sequence, .none:
                    return "N/A"
            }
        }
    }
}

public struct AverageMetrics {
    let handExtensionSpeed: Double
    let handRetractionSpeed: Double
    let footExtensionSpeed: Double
    let footRetractionSpeed: Double
    let power: Double
}

// Extension to make AverageMetrics compatible with BodyFeedback
extension AverageMetrics {
    var body: FeedbackModels.BodyFeedback? {
        let metrics = createMetrics()
        return FeedbackModels.BodyFeedback(
            feedback: nil,
            jab_score: nil,
            chin_tucked_extension: nil,
            torso_rotation_extension: nil,
            shoulder_rotation_retraction: nil,
            hip_rotation_extension: nil,
            hip_velocity_retraction: nil,
            elbow_velocity_extension: nil,
            motion_sequence: nil,
            hip_velocity_extension: nil,
            foot_placement_retraction: nil,
            foot_stepping_direction_extension: nil,
            leg_to_shoulder_width_guard: nil,
            jab_straight_line_extension: nil,
            return_position_difference_retraction: nil,
            foot_placement_guard: nil,
            rear_hand_in_guard_extension: nil,
            overall_velocity_extension: nil,
            foot_velocity_extension: metrics.foot,
            elbow_straight_line_extension: nil,
            force_generation_extension: metrics.power,
            mean_back_leg_angle_extension: nil,
            head_stability_guard: nil,
            foot_steps_with_punch_diff_extension: nil,
            shoulder_velocity_extension: nil,
            elbow_protection_extension: nil,
            chin_lift_extension: nil,
            shoulder_velocity_retraction: nil,
            wrist_angle_extension: nil,
            foot_velocity_retraction: metrics.footRet,
            jab_arm_extension: nil,
            elbow_flare_extension: nil,
            elbow_velocity_retraction: nil,
            step_distance_extension: nil,
            mean_back_leg_angle_guard: nil,
            overall_velocity_retraction: nil,
            head_stability_extension: nil,
            foot_placement_extension: nil,
            chin_tucked_guard: nil,
            chin_tucked_retraction: nil,
            hand_velocity_extension: metrics.hand,
            hand_velocity_retraction: metrics.handRet,
            hands_above_shoulders_guard: nil,
            hip_rotation_retraction: nil,
            torso_rotation_retraction: nil,
            hand_drop_before_extension: nil,
            whip_effect_extension: nil,
            shoulder_rotation_extension: nil,
            head_stability_retraction: nil,
            mean_back_leg_angle_retraction: nil
        )
    }
    
    private func createMetrics() -> (hand: FeedbackModels.MetricDetails?, handRet: FeedbackModels.MetricDetails?, foot: FeedbackModels.MetricDetails?, footRet: FeedbackModels.MetricDetails?, power: FeedbackModels.MetricDetails?) {
        return (
            hand: createMetricDetails(value: handExtensionSpeed, unit: "meters/second"),
            handRet: createMetricDetails(value: handRetractionSpeed, unit: "meters/second"),
            foot: createMetricDetails(value: footExtensionSpeed, unit: "meters/second"),
            footRet: createMetricDetails(value: footRetractionSpeed, unit: "meters/second"),
            power: createMetricDetails(value: power, unit: "Newtons")
        )
    }
    
    private func createMetricDetails(value: Double, unit: String) -> FeedbackModels.MetricDetails? {
        let valueString = "\(String(format: "%.2f", value)) \(unit)"
        return try? JSONDecoder().decode(FeedbackModels.MetricDetails.self, from: JSONSerialization.data(withJSONObject: ["metric_values": valueString]))
    }
}
