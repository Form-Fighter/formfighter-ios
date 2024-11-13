import Firebase
import FirebaseFirestore
import Combine

class FeedbackViewModel: ObservableObject {
    @Published var feedback: FeedbackModels.FeedbackData?
    @Published var error: String?
    @Published var status: FeedbackStatus = .pending
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    
    func setupFirestoreListener(feedbackId: String) {
        listener = db.collection("feedback").document(feedbackId)
            .addSnapshotListener { [weak self] documentSnapshot, error in
                guard let self = self else { return }
                
                guard let document = documentSnapshot else {
                    self.error = error?.localizedDescription ?? "Unknown error occurred"
                    return
                }
                
                guard let data = document.data() else {
                    self.error = "Document data was empty"
                    return
                }
                
                if let newStatus = data["status"] as? String,
                   let feedbackStatus = FeedbackStatus(rawValue: newStatus) {
                    self.status = feedbackStatus
                }
                
                if self.status == .completed {
                    self.feedback = try? Firestore.Decoder().decode(FeedbackModels.FeedbackData.self, from: data)
                }
                
                if let errorMessage = data["error"] as? String {
                    self.error = errorMessage
                }
            }
    }
    
    func checkExistingUserFeedback(feedbackId: String, completion: @escaping (Bool) -> Void) {
        db.collection("feedback").document(feedbackId).getDocument { document, _ in
            if let data = document?.data(),
               let _ = data["userFeedback"] as? [String: Any] {
                completion(true)
            } else {
                completion(false)
            }
        }
    }
    
    func submitUserFeedback(feedbackId: String, emoji: UserFeedbackType, comment: String, completion: @escaping (Bool) -> Void) {
        db.collection("feedback").document(feedbackId)
            .setData([
                "userFeedback": [
                    "emoji": emoji.rawValue,
                    "comment": comment,
                    "submittedAt": Timestamp(date: Date())
                ]
            ], merge: true) { error in
                completion(error == nil)
            }
    }
    
    func cleanup() {
        listener?.remove()
    }
    
    deinit {
        cleanup()
    }
} 