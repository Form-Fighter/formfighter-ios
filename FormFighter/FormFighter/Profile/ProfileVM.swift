//
//  ProfileVM.swift
//  FormFighter
//
//  Created by Julian Parker on 10/4/24.
//


import Foundation
import Firebase
import FirebaseFirestore

class ProfileVM: ObservableObject {
    @Published var feedbacks: [FeedbackListItem] = []
    @Published var isLoading = true
    @Published var error: String?
    
    private let db = Firestore.firestore()
    
    struct FeedbackListItem: Identifiable {
        let id: String
        let date: Date
        let score: Double
        let status: String
        
        var isCompleted: Bool {
            return status == "completed"
        }
    }
    
    func fetchUserFeedback(userId: String) {
        db.collection("feedback")
            .whereField("userId", isEqualTo: userId)
            .addSnapshotListener { [weak self] querySnapshot, error in
                guard let self = self else { return }
                
                if let error = error {
                    self.error = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                guard let documents = querySnapshot?.documents else {
                    self.isLoading = false
                    return
                }
                
                self.feedbacks = documents.compactMap { document in
                    guard let status = document.data()["status"] as? String,
                          let createdAt = document.data()["createdAt"] as? Timestamp,
                          let modelFeedback = document.data()["modelFeedback"] as? [String: Any],
                          let jabScore = modelFeedback["jab_score"] as? Double else {
                        return nil
                    }
                    
                    // Skip if there's an error
                    if document.data()["error"] != nil {
                        return nil
                    }
                    
                    return FeedbackListItem(
                        id: document.documentID,
                        date: createdAt.dateValue(),
                        score: jabScore,
                        status: status
                    )
                }
                
                self.isLoading = false
            }
    }
}
