//
//  ProfileVM.swift
//  FormFighter
//
//  Created by Julian Parker on 10/4/24.
//


import Foundation
import Firebase
import FirebaseFirestore
import os.log

class ProfileVM: ObservableObject {
    @Published var feedbacks: [FeedbackListItem] = []
    @Published var isLoading = true
    @Published var error: String?
    
    private let db = Firestore.firestore()
    private var listener: ListenerRegistration?
    private var hasInitialized = false
    private let logger = OSLog(subsystem: "com.formfighter", category: "ProfileVM")
    
    struct FeedbackListItem: Identifiable {
        let id: String
        let date: Date
        let status: FeedbackStatus
        let videoUrl: String?
        let score: Double
        
        var isCompleted: Bool {
            return status == .completed
        }
        
        var isLoading: Bool {
            return status.isProcessing
        }
    }
    
    func fetchUserFeedback(userId: String) {
        guard !hasInitialized else { return }
        hasInitialized = true
        
        os_log("Fetching feedback for user: %@", log: logger, type: .debug, userId)
        isLoading = true
        
        let feedbackRef = db.collection("feedback")
            .whereField("userId", isEqualTo: userId)
        
        listener = feedbackRef.addSnapshotListener { [weak self] snapshot, error in
            guard let self = self else { return }
            
            if let error = error {
                os_log("Error fetching feedback: %@", log: self.logger, type: .error, error.localizedDescription)
                self.error = error.localizedDescription
                self.isLoading = false
                return
            }
            
            guard let documents = snapshot?.documents else {
                os_log("No feedback documents found", log: self.logger, type: .debug)
                self.isLoading = false
                return
            }
            
            self.feedbacks = documents.compactMap { document in
                let data = document.data()
                
                // Check for error field
                if let _ = data["error"] as? String {
                    os_log("Skipping feedback with error: %@", log: self.logger, type: .debug, document.documentID)
                    return nil
                }
                
                let statusString = data["status"] as? String ?? ""
                let status = FeedbackStatus(rawValue: statusString) ?? .pending
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
                
                os_log("Processing feedback: %@ with status: %@", log: self.logger, type: .debug, document.documentID, status.rawValue)
                
                return FeedbackListItem(
                    id: document.documentID,
                    date: (data["createdAt"] as? Timestamp)?.dateValue() ?? Date(),
                    status: status,
                    videoUrl: data["videoUrl"] as? String,
                    score: jabScore
                )
            }
            
            os_log("Fetched %d valid feedback items", log: self.logger, type: .debug, self.feedbacks.count)
            self.isLoading = false
        }
    }
    
    deinit {
        os_log("ProfileVM deinitializing, removing listener", log: logger, type: .debug)
        listener?.remove()
    }
}
