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
                    
                    return FeedbackListItem(
                        id: document.documentID,
                        date: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                        status: status,
                        videoUrl: data["videoUrl"] as? String,
                        score: jabScore,
                        modelFeedback: try? JSONDecoder().decode(FeedbackModels.ModelFeedback.self, from: JSONSerialization.data(withJSONObject: data["modelFeedback"] ?? [:]))
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
}
