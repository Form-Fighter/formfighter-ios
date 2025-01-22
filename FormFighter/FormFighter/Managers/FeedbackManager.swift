import Foundation
import Firebase
import FirebaseFirestore
import os.log

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
        
        // The format appears to be "0.54 meters/second " with a space at the end
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
