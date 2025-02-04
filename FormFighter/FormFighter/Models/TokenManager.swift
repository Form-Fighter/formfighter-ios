import Foundation
import Firebase
import FirebaseFirestore

class TokenManager: ObservableObject {
    static let shared = TokenManager()
    private let db = Firestore.firestore()
    
    @Published var tokensRemaining: Int = 0
    @Published var totalTokensUsed: Int = 0
    @Published var nextTokenReset: Date?
    @Published var lastTokenReset: Date?
    
    private init() {}
    
    func fetchTokenInfo(coachId: String, studentId: String) {
        print("📍 Fetching tokens for coach: \(coachId), student: \(studentId)")
        db.collection("seats")
            .whereField("coachId", isEqualTo: coachId)
            .whereField("studentId", isEqualTo: studentId)
            .getDocuments { [weak self] snapshot, error in
                if let error = error {
                    print("❌ Error fetching tokens: \(error.localizedDescription)")
                    return
                }
                
                guard let self = self,
                      let document = snapshot?.documents.first else {
                    print("❌ No token document found")
                    return
                }
                
                print("✅ Token document found: \(document.data())")
                
                self.tokensRemaining = document.data()["tokensRemaining"] as? Int ?? 0
                self.totalTokensUsed = document.data()["totalTokensUsed"] as? Int ?? 0
                
                if let nextResetTimestamp = document.data()["nextTokenReset"] as? Timestamp {
                    self.nextTokenReset = nextResetTimestamp.dateValue()
                }
                
                if let lastResetTimestamp = document.data()["lastTokenReset"] as? Timestamp {
                    self.lastTokenReset = lastResetTimestamp.dateValue()
                }
            }
    }
}