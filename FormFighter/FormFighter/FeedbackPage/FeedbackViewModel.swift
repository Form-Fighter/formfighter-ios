import Firebase
import FirebaseFirestore
import Combine
import os.log
import SwiftUI

struct AnonymousComment: Identifiable {
    let id: String
    let comment: String
    let timestamp: Date
    let feedbackId: String
    
    init(id: String, data: [String: Any]) {
        self.id = id
        self.comment = data["comment"] as? String ?? ""
        self.timestamp = (data["createdAt"] as? Timestamp)?.dateValue() ?? Date()
        self.feedbackId = data["feedbackId"] as? String ?? ""
    }
}

class FeedbackViewModel: ObservableObject {
    @Published var feedback: FeedbackModels.FeedbackData?
    @Published var error: String?
    @Published var status: FeedbackStatus = .pending
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    @Published var challengeToast: String?
    private let challengeService = ChallengeService.shared
    private var toastTimer: Timer?
    
    @Published var anonymousComments: [AnonymousComment] = []
    @Published var isLoadingComments = false
    
    var shouldShowChallengeIndicator: Bool {
        guard let challenge = ChallengeService.shared.activeChallenge,
              challenge.endTime > Date(),
              let feedback = feedback,
              let feedbackChallengeId = feedback.challengeId else {
            return false
        }
        return feedbackChallengeId == challenge.id
    }
    
    var activeChallengeInfo: (name: String, id: String)? {
        guard let challenge = ChallengeService.shared.activeChallenge else {
            return nil
        }
        return (challenge.name, challenge.id)
    }
    
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
        print("📝 Feedback challenge ID: \(feedbackChallengeId ?? "nil")")
        
        // Process challenge if active and matches the feedback's challengeId
        if let activeChallenge = challengeService.activeChallenge {
            print("🎯 Active challenge found: \(activeChallenge.name)")
            print("🎯 Active challenge ID: \(activeChallenge.id)")
            print("🎯 Challenge end time: \(activeChallenge.endTime)")
            print("🎯 Current time: \(Date())")
            
            if let feedbackChallengeId = feedbackChallengeId,
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
                    
                    showToast("Score added to challenge!")
                } catch {
                    print("❌ Failed to process challenge event: \(error)")
                    if let challengeError = error as? ChallengeError, 
                       challengeError == .duplicateEvent {
                        print("⚠️ Duplicate event detected")
                        showToast("Score already added to challenge!")
                    } else {
                        self.error = error.localizedDescription
                    }
                }
            } else {
                print("❌ Challenge validation failed:")
                print("   - IDs match: \(feedbackChallengeId == activeChallenge.id)")
                print("   - Challenge active: \(activeChallenge.endTime > Date())")
            }
        } else {
            print("❌ No active challenge found")
        }
    }
    
    func cleanup() {
        listener?.remove()
        listener = nil
    }
    
    private func showToast(_ message: String, duration: TimeInterval = 3.0) {
        // Cancel any existing timer
        toastTimer?.invalidate()
        
        DispatchQueue.main.async {
            self.challengeToast = message
            
            // Set up new timer to clear the toast
            self.toastTimer = Timer.scheduledTimer(withTimeInterval: duration, repeats: false) { [weak self] _ in
                DispatchQueue.main.async {
                    withAnimation(.easeOut) {
                        self?.challengeToast = nil
                    }
                }
            }
        }
    }
    
    deinit {
        cleanup()
        toastTimer?.invalidate()
    }
    
    func fetchAnonymousComments(for feedbackId: String) {
        isLoadingComments = true
        print("🔍 Fetching anonymous comments for feedback: \(feedbackId)")
        
        let db = Firestore.firestore()
        db.collection("anonymous_comments")
            .whereField("feedbackId", isEqualTo: feedbackId)
            .order(by: "createdAt", descending: true)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                self.isLoadingComments = false
                
                if let error = error {
                    print("❌ Error fetching anonymous comments: \(error.localizedDescription)")
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    print("No anonymous comments found")
                    return
                }
                
                self.anonymousComments = documents.map { document in
                    print("📄 Comment data: \(document.data())")
                    return AnonymousComment(id: document.documentID, data: document.data())
                }
                
                print("✅ Fetched \(self.anonymousComments.count) anonymous comments")
            }
    }
} 
