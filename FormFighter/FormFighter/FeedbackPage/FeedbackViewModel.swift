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
                
                if let error = error {
                    self.error = error.localizedDescription
                    return
                }
                
                guard let document = documentSnapshot, document.exists,
                      let data = document.data() else {
                    self.error = "Document not found"
                    return
                }
                
                if let statusString = data["status"] as? String,
                   let feedbackStatus = FeedbackStatus(rawValue: statusString) {
                    self.status = feedbackStatus
                }
                
                if self.status == .completed {
                    do {
                        self.feedback = try Firestore.Decoder().decode(FeedbackModels.FeedbackData.self, from: data)
                    } catch {
                        print("Decoding error: \(error)")
                        self.error = "Failed to decode feedback data"
                    }
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