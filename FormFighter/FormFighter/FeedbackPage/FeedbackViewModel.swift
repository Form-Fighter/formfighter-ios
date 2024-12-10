import Firebase
import FirebaseFirestore
import Combine
import os.log

class FeedbackViewModel: ObservableObject {
    @Published var feedback: FeedbackModels.FeedbackData?
    @Published var error: String?
    @Published var status: FeedbackStatus = .pending
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private let logger = OSLog(subsystem: "com.formfighter", category: "FeedbackViewModel")
    
    @Published var challengeToast: String?
    private let challengeService = ChallengeService.shared
    
    func setupFirestoreListener(feedbackId: String) {
        print("⚡️ Setting up listener for feedback: \(feedbackId)")
        cleanup()
        
        listener = db.collection("feedback").document(feedbackId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    print("❌ Listener error: \(error.localizedDescription)")
                    self.error = error.localizedDescription
                    return
                }
                
                print("📥 Received feedback update")
                guard let document = documentSnapshot, document.exists,
                      let data = document.data() else {
                    os_log("Document not found for feedback ID: %@", log: self.logger, type: .error, feedbackId)
                    self.error = "Document not found"
                    return
                }
                
                // Check for error field first
                if let errorMessage = data["error"] as? String {
                    self.error = errorMessage
                    return
                }
                
                // Update status
                if let statusString = data["status"] as? String {
                    os_log("Feedback status updated: %@", log: self.logger, type: .debug, statusString)
                    self.status = FeedbackStatus(rawValue: statusString) ?? .pending
                }
                
                // Only decode if status is completed
                if self.status == .completed {
                    do {
                        // Add debug logging for the raw data
                        os_log("Raw feedback data: %@", log: self.logger, type: .debug, String(describing: data))
                        
                        // Attempt to decode and log each required field
                        if let title = data["title"] as? String {
                            os_log("Found title: %@", log: self.logger, type: .debug, title)
                        } else {
                            os_log("Missing required field: title", log: self.logger, type: .debug)
                        }
                        
                        if let feedback = data["feedback"] as? [String: Any] {
                            os_log("Found feedback object: %@", log: self.logger, type: .debug, String(describing: feedback))
                        } else {
                            os_log("Missing required field: feedback", log: self.logger, type: .debug)
                        }
                        
                        self.feedback = try Firestore.Decoder().decode(FeedbackModels.FeedbackData.self, from: data)
                        os_log("Successfully decoded feedback data", log: self.logger, type: .debug)
                        
                        // Let the BadgeService handle all badge logic and update jab volume
                      // Let the BadgeService handle all badge logic
                        Task {
                            if let feedback = self.feedback {
                                await BadgeService.shared.processEvent(.processFeedback(feedback: feedback))
                            }
                        }
                        
                    } catch {
                        os_log("Feedback decoding error: %@", log: self.logger, type: .error, error.localizedDescription)
                        // Add more detailed error information
                        if let decodingError = error as? DecodingError {
                            switch decodingError {
                            case .keyNotFound(let key, _):
                                os_log("Missing key: %@", log: self.logger, type: .error, key.stringValue)
                            case .valueNotFound(let type, _):
                                os_log("Missing value for type: %@", log: self.logger, type: .error, String(describing: type))
                            default:
                                os_log("Other decoding error: %@", log: self.logger, type: .error, String(describing: decodingError))
                            }
                        }
                        self.error = "Failed to decode feedback data"
                    }
                }
            }
    }
    
    func checkExistingUserFeedback(feedbackId: String, completion: @escaping (Bool) -> Void) {
        os_log("Checking existing user feedback for ID: %@", log: logger, type: .debug, feedbackId)
        
        db.collection("feedback").document(feedbackId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                os_log("Error checking user feedback: %@", log: self.logger, type: .error, error.localizedDescription)
                completion(false)
                return
            }
            
            if let data = document?.data(),
               let _ = data["userFeedback"] as? [String: Any] {
                os_log("Found existing user feedback", log: self.logger, type: .debug)
                completion(true)
            } else {
                os_log("No existing user feedback found", log: self.logger, type: .debug)
                completion(false)
            }
        }
    }
    
    func submitUserFeedback(feedbackId: String, emoji: UserFeedbackType, comment: String, rating: Double, improvements: [String], wouldRecommend: Bool, completion: @escaping (Bool) -> Void) {
        os_log("Submitting comprehensive user feedback for ID: %@", log: logger, type: .debug, feedbackId)
        
        let userFeedbackData: [String: Any] = [
            "userFeedback": [
                "emoji": emoji.rawValue,
                "comment": comment,
                "helpfulnessRating": rating,
                "improvements": improvements,
                "wouldRecommend": wouldRecommend,
                "submittedAt": Timestamp(date: Date())
            ]
        ]
        
        db.collection("feedback").document(feedbackId)
            .setData(userFeedbackData, merge: true) { [weak self] error in
                guard let self = self else { return }
                
                if let error = error {
                    os_log("Error submitting user feedback: %@", log: self.logger, type: .error, error.localizedDescription)
                    completion(false)
                } else {
                    os_log("Successfully submitted user feedback", log: self.logger, type: .debug)
                    completion(true)
                }
            }
    }
    
    func cleanup() {
        listener?.remove()
        listener = nil
    }
    
    deinit {
        cleanup()
    }
    
    private func handleFeedbackUpdate(_ document: DocumentSnapshot) {
        do {
            let data = document.data() ?? [:]
            self.feedback = try Firestore.Decoder().decode(FeedbackModels.FeedbackData.self, from: data)
            
            os_log("Successfully decoded feedback data", log: self.logger, type: .debug)
            
            // Process feedback for badges and challenges
            if let feedback = self.feedback {
                Task {
                    do {
                        try await processFeedback(feedback, documentId: document.documentID)
                    } catch {
                        os_log("Error processing feedback: %@", log: self.logger, type: .error, error.localizedDescription)
                        self.error = error.localizedDescription
                    }
                }
            }
        } catch {
            os_log("Feedback decoding error: %@", log: self.logger, type: .error, error.localizedDescription)
            self.error = error.localizedDescription
        }
    }
    
    private func processFeedback(_ feedback: FeedbackModels.FeedbackData, documentId: String) async throws {
        guard let score = feedback.modelFeedback?.body?.jab_score else { return }
        
        // Process badges first
        await BadgeService.shared.processEvent(.processFeedback(feedback: feedback))
        
        // Process challenge if active
        if let activeChallenge = challengeService.activeChallenge,
           activeChallenge.endTime > Date() {
            do {
                try await challengeService.processEvent(.feedbackViewed(
                    feedbackId: documentId,
                    score: score
                ))
                
                DispatchQueue.main.async {
                    self.challengeToast = "Score added to challenge!"
                    // Hide toast after 3 seconds
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.challengeToast = nil
                    }
                }
            } catch {
                os_log("Failed to process challenge feedback: %@", log: logger, type: .error, error.localizedDescription)
                self.error = error.localizedDescription
            }
        }
    }
} 
