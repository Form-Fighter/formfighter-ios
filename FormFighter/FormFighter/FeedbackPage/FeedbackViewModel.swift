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
                    print("❌ Document not found for feedback ID: \(feedbackId)")
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
                    print("📊 Feedback status updated: \(statusString)")
                    self.status = FeedbackStatus(rawValue: statusString) ?? .pending
                }
                
                // Only decode if status is completed
                if self.status == .completed {
                    do {
                        print("📝 Raw feedback data: \(data)")
                        
                        // Attempt to decode and log each required field
                        if let title = data["title"] as? String {
                            print("📄 Found title: \(title)")
                        } else {
                            print("⚠️ Missing required field: title")
                        }
                        
                        if let feedback = data["feedback"] as? [String: Any] {
                            print("📄 Found feedback object: \(feedback)")
                        } else {
                            print("⚠️ Missing required field: feedback")
                        }
                        
                        self.feedback = try Firestore.Decoder().decode(FeedbackModels.FeedbackData.self, from: data)
                        print("✅ Successfully decoded feedback data")
                        
                        if let feedback = self.feedback {
                            Task {
                                do {
                                    try await self.processFeedback(feedback, documentId: document.documentID)
                                } catch {
                                    print("❌ Error processing feedback: \(error.localizedDescription)")
                                    self.error = error.localizedDescription
                                }
                            }
                        }
                        
                    } catch {
                        print("❌ Feedback decoding error: \(error.localizedDescription)")
                        if let decodingError = error as? DecodingError {
                            switch decodingError {
                            case .keyNotFound(let key, _):
                                print("❌ Missing key: \(key.stringValue)")
                            case .valueNotFound(let type, _):
                                print("❌ Missing value for type: \(String(describing: type))")
                            default:
                                print("❌ Other decoding error: \(String(describing: decodingError))")
                            }
                        }
                        self.error = "Failed to decode feedback data"
                    }
                }
            }
    }
    
    func checkExistingUserFeedback(feedbackId: String, completion: @escaping (Bool) -> Void) {
        print("🔍 Checking existing user feedback for ID: \(feedbackId)")
        
        db.collection("feedback").document(feedbackId).getDocument { [weak self] document, error in
            guard let self = self else { return }
            
            if let error = error {
                print("❌ Error checking user feedback: \(error.localizedDescription)")
                completion(false)
                return
            }
            
            if let data = document?.data(),
               let _ = data["userFeedback"] as? [String: Any] {
                print("✅ Found existing user feedback")
                completion(true)
            } else {
                print("ℹ️ No existing user feedback found")
                completion(false)
            }
        }
    }
    
    func submitUserFeedback(feedbackId: String, emoji: UserFeedbackType, comment: String, rating: Double, improvements: [String], wouldRecommend: Bool, completion: @escaping (Bool) -> Void) {
        print("📤 Submitting user feedback for ID: \(feedbackId)")
        
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
                    print("❌ Error submitting user feedback: \(error.localizedDescription)")
                    completion(false)
                } else {
                    print("✅ Successfully submitted user feedback")
                    completion(true)
                }
            }
    }
    

    
    private func processFeedback(_ feedback: FeedbackModels.FeedbackData, documentId: String) async throws {
        guard let score = feedback.modelFeedback?.body?.jab_score else { 
            print("❌ No score found in feedback")
            return 
        }
        
        print("🎯 Processing feedback with score: \(score)")
        
        // Process badges first
        await BadgeService.shared.processEvent(.processFeedback(feedback: feedback))
        
        // Get the feedback document to check for challengeId
        let feedbackDoc = try await db.collection("feedback").document(documentId).getDocument()
        let feedbackChallengeId = feedbackDoc.data()?["challengeId"] as? String
        
        // Process challenge if active and matches the feedback's challengeId
        if let activeChallenge = challengeService.activeChallenge,
           let feedbackChallengeId = feedbackChallengeId,
           feedbackChallengeId == activeChallenge.id,
           activeChallenge.endTime > Date() {
            print("🎯 Found matching active challenge: \(activeChallenge.name)")
            print("🎯 Challenge is still active, processing event")
            do {
                try await challengeService.processEvent(.feedbackViewed(
                    feedbackId: documentId,
                    score: score
                ))
                print("✅ Successfully processed challenge event")
                
                DispatchQueue.main.async {
                    self.challengeToast = "Score added to challenge!"
                    DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                        self.challengeToast = nil
                    }
                }
            } catch {
                print("❌ Failed to process challenge event: \(error)")
                if let challengeError = error as? ChallengeError, 
                   challengeError == .duplicateEvent {
                    DispatchQueue.main.async {
                        self.challengeToast = "Score already added to challenge!"
                    }
                } else {
                    self.error = error.localizedDescription
                }
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
} 
