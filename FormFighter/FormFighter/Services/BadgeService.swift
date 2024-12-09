import SwiftUI
import Firebase
import FirebaseFirestore
import Foundation
import Combine
import os.log

class BadgeService: ObservableObject {
    static let shared = BadgeService()
    private let db = Firestore.firestore()
    private let logger = OSLog(subsystem: "com.formfighter", category: "BadgeService")
    
    @Published private(set) var userBadges: [UserBadge] = []
    @Published private(set) var badgeProgress: [BadgeProgress] = []
    private var listeners: [ListenerRegistration] = []
    
    init() {
        print("🏅 BadgeService initialized")
    }
    
    // MARK: - Firestore Listeners
    func startListening(userId: String) {
        print("🏅 Starting badge listeners for user: \(userId)")
        
        // Listen for earned badges
        let badgesListener = db.collection("users")
            .document(userId)
            .collection("badges")
            .addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                guard let self = self else { 
                    print("🏅 Self was nil in badge listener")
                    return 
                }
                
                print("🏅 Badge snapshot received")
                print("   Error: \(String(describing: error))")
                print("   Empty snapshot: \(snapshot == nil)")
                print("   Document count: \(snapshot?.documents.count ?? 0)")
                
                if let documents = snapshot?.documents {
                    documents.forEach { doc in
                        print("   Badge document: \(doc.documentID)")
                        print("   Data: \(doc.data())")
                    }
                }
                
                if let error = error {
                    os_log("❌ Error listening for badges: %@", log: self.logger, type: .error, error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    os_log("No badge documents found", log: self.logger, type: .debug)
                    return
                }
                
                self.userBadges = documents.compactMap { document in
                    do {
                        let data = document.data()
                        print("🏅 Attempting to decode badge:")
                        print("   Document ID: \(document.documentID)")
                        print("   Raw data: \(data)")
                        let badge = try document.data(as: UserBadge.self)
                        print("   Decoded successfully: \(badge)")
                        return badge
                    } catch {
                        print("❌ Failed to decode badge: \(error)")
                        return nil
                    }
                }
            }
        
        // Listen for badge progress
        let progressListener = db.collection("users")
            .document(userId)
            .collection("badgeProgress")
            .addSnapshotListener { [weak self] (snapshot: QuerySnapshot?, error: Error?) in
                guard let self = self else { return }
                
                if let error = error {
                    os_log("❌ Error listening for badge progress: %@", log: self.logger, type: .error, error.localizedDescription)
                    return
                }
                
                guard let documents = snapshot?.documents else {
                    os_log("No progress documents found", log: self.logger, type: .debug)
                    return
                }
                
                self.badgeProgress = documents.compactMap { document in
                    try? document.data(as: BadgeProgress.self)
                }
            }
            
        listeners.append(contentsOf: [badgesListener, progressListener])
    }
    
    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    // MARK: - Badge Events
    enum BadgeEvent {
        case processFeedback(feedback: FeedbackModels.FeedbackData)
        case streakUpdated(days: Int)
    }
    
    // MARK: - Badge Processing
    func processEvent(_ event: BadgeEvent) async {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        
        switch event {
        case .processFeedback(let feedback):
            await checkFirstJabBadge(userId: userId)
            await checkTrainingBadges(userId: userId, feedback: feedback)
            await updateAndCheckVolume(userId: userId)
            
        case .streakUpdated(let days):
            await checkStreakBadges(userId: userId, days: days)
        }
    }
    
    private func checkTrainingBadges(userId: String, feedback: FeedbackModels.FeedbackData) async {
        guard let jabScore = feedback.modelFeedback?.body?.jab_score else { return }
        
        // Check Perfect Score Badge
        if jabScore >= 95 {
            await checkAndAwardBadge(userId: userId, badgeId: "perfect_score")
        }
        
        // Check Form Master Badges
        if let extensionScore = feedback.modelFeedback?.body?.feedback?.extensionFeedback?.score,
           extensionScore >= 90 {
            await checkAndAwardBadge(userId: userId, badgeId: "extension_master")
        }
        
        // Check Time-based badges
        let hour = Calendar.current.component(.hour, from: Date())
        if hour < 6 {
            await checkAndAwardBadge(userId: userId, badgeId: "early_bird")
        } else if hour >= 22 {
            await checkAndAwardBadge(userId: userId, badgeId: "night_owl")
        }
    }
    
    private func checkStreakBadges(userId: String, days: Int) async {
        // Check immediate streak badges
        let streakBadges = [
            (days: 3, badgeId: "three_day_streak"),
            (days: 7, badgeId: "weekly_warrior"),
            (days: 14, badgeId: "unstoppable"),
            (days: 30, badgeId: "monthly_master")
        ]
        
        for badge in streakBadges where days == badge.days {
            await checkAndAwardBadge(userId: userId, badgeId: badge.badgeId)
        }
        
        // Update progress for next streak badge
        let nextBadge = streakBadges.first { $0.days > days }
        if let nextBadge = nextBadge {
            let progress = BadgeProgress(
                badgeId: nextBadge.badgeId,
                currentValue: days,
                targetValue: nextBadge.days,
                progressStartDate: Date()
            )
            await updateProgress(userId: userId, badgeId: nextBadge.badgeId, progress: progress)
        }
    }
    
    private func checkVolumeBadges(userId: String, totalJabs: Int) async {
        // Check immediate volume badges
        let volumeBadges = [
            (jabs: 100, badgeId: "jab_rookie"),
            (jabs: 500, badgeId: "jab_veteran"),
            (jabs: 1000, badgeId: "jab_master")
        ]
        
        for badge in volumeBadges where totalJabs >= badge.jabs {
            await checkAndAwardBadge(userId: userId, badgeId: badge.badgeId)
        }
        
        // Update progress for next volume badge
        let nextBadge = volumeBadges.first { $0.jabs > totalJabs }
        if let nextBadge = nextBadge {
            let progress = BadgeProgress(
                badgeId: nextBadge.badgeId,
                currentValue: totalJabs,
                targetValue: nextBadge.jabs,
                progressStartDate: Date()
            )
            await updateProgress(userId: userId, badgeId: nextBadge.badgeId, progress: progress)
        }
    }
    
    private func checkFirstJabBadge(userId: String) async {
        let badgeId = "first_jab"
        
        // Check if user already has the badge
        let badgeRef = db.collection("users")
            .document(userId)
            .collection("badges")
            .document(badgeId)
            
        do {
            let badgeDoc = try await badgeRef.getDocument()
            if !badgeDoc.exists {
                await awardBadge(userId: userId, badgeId: badgeId)
                
                // Trigger celebration
                await MainActor.run {
                    NotificationCenter.default.post(
                        name: .badgeEarned,
                        object: nil,
                        userInfo: ["badgeId": badgeId]
                    )
                }
            }
        } catch {
            os_log("❌ Error checking first jab badge: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    private func checkAndAwardBadge(userId: String, badgeId: String) async {
        // Check if badge already earned
        let badgeRef = db.collection("users").document(userId).collection("badges").document(badgeId)
        let badgeDoc = try? await badgeRef.getDocument()
        
        if badgeDoc?.exists != true {
            await awardBadge(userId: userId, badgeId: badgeId)
        }
    }
    
    private func awardBadge(userId: String, badgeId: String) async {
        let badgeRef = db.collection("users").document(userId).collection("badges").document(badgeId)
        
        do {
            try await badgeRef.setData([
                "badgeId": badgeId,
                "earnedAt": Date(),
                "count": 1
            ])
            
            os_log("✅ Badge awarded: %@", log: logger, type: .debug, badgeId)
            
            // Trigger celebration
            await MainActor.run {
                NotificationCenter.default.post(
                    name: .badgeEarned,
                    object: nil,
                    userInfo: ["badgeId": badgeId]
                )
            }
        } catch {
            os_log("❌ Error awarding badge: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    private func updateProgress(userId: String, badgeId: String, progress: BadgeProgress) async {
        let progressRef = db.collection("users")
            .document(userId)
            .collection("badgeProgress")
            .document(badgeId)
        
        do {
            try await progressRef.setData([
                "currentValue": progress.currentValue,
                "targetValue": progress.targetValue,
                "progressStartDate": progress.progressStartDate
            ])
            
            os_log("✅ Progress updated for badge: %@", log: logger, type: .debug, badgeId)
        } catch {
            os_log("❌ Error updating progress: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    private func updateAndCheckVolume(userId: String) async {
        let userRef = db.collection("users").document(userId)
        
        do {
            try await db.runTransaction { (transaction, errorPointer) -> Any? in
                do {
                    let userDoc = try transaction.getDocument(userRef)
                    let currentTotal = userDoc.data()?["totalJabs"] as? Int ?? 0
                    let newTotal = currentTotal + 1
                    
                    transaction.updateData(["totalJabs": newTotal], forDocument: userRef)
                    return newTotal as Any
                } catch let error {
                    errorPointer?.pointee = error as NSError
                    return nil
                }
            }
            
            // Get the updated total and check badges
            let userDoc = try await userRef.getDocument()
            if let totalJabs = userDoc.data()?["totalJabs"] as? Int {
                await checkVolumeBadges(userId: userId, totalJabs: totalJabs)
            }
            
        } catch {
            os_log("❌ Error updating jab volume: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
}

extension Notification.Name {
    static let badgeEarned = Notification.Name("badgeEarned")
} 