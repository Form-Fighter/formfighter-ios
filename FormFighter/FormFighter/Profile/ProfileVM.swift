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
    private var listener: ListenerRegistration?
    private var hasInitialized = false
    
    struct FeedbackListItem: Identifiable {
        let id: String
        let date: Date
        let status: String
        let videoUrl: String?
        let score: Double
        
        var isCompleted: Bool {
            return status == "completed"
        }
    }
    
    func fetchUserFeedback(userId: String) {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        isLoading = true
        
        let feedbackRef = db.collection("feedback")
            .whereField("userId", isEqualTo: userId)
            .whereField("status", isEqualTo: "completed")
        
        listener = feedbackRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                print("Error fetching feedback: \(error.localizedDescription)")
                self.isLoading = false
                return
            }
            
            guard let documents = snapshot?.documents else {
                self.isLoading = false
                return
            }
            
            self.feedbacks = documents.compactMap { document in
                let data = document.data()
                
                let jabScore: Double
                if let modelFeedback = data["modelFeedback"] as? [String: Any],
                   let body = modelFeedback["body"] as? [String: Any],
                   let score = body["jab_score"] as? Double {
                    jabScore = score
                } else {
                    jabScore = 0.0
                }
                
                return FeedbackListItem(
                    id: document.documentID,
                    date: Date(),
                    status: data["status"] as? String ?? "",
                    videoUrl: data["videoUrl"] as? String,
                    score: jabScore
                )
            }
            
            self.isLoading = false
        }
    }
    
    deinit {
        listener?.remove()
    }
}
