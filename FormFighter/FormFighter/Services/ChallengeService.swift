import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import OSLog
import FirebaseMessaging


class ChallengeService: ObservableObject {
    static let shared = ChallengeService()
    
    @Published var activeChallenge: Challenge?
    @Published var completedChallenges: [Challenge] = []
    
    private let db = Firestore.firestore()
    private var listeners: [ListenerRegistration] = []
    private let userManager = UserManager.shared
    
    func startListening(userId: String) {
        stopListening()
        
        // Use collectionGroup to search across all participant subcollections
        let participantListener = db.collectionGroup("participants")
            .whereField("id", isEqualTo: userId)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let self = self,
                      let participantDocs = snapshot?.documents else {
                    print("❌ No participant documents found")
                    self?.activeChallenge = nil
                    return
                }
                
                // Get parent challenges for all participant documents
                Task {
                    do {
                        var challenges: [Challenge] = []
                        var activeChallenge: Challenge? = nil
                        var hasSetupActiveListener = false  // Flag to ensure only one active listener
                        
                        for participantDoc in participantDocs {
                            let challengeRef = participantDoc.reference.parent.parent!
                            if let challengeDoc = try? await challengeRef.getDocument(),
                               challengeDoc.exists,
                               var challenge = try? challengeDoc.data(as: Challenge.self) {
                                
                                // Fetch basic data for all challenges
                                let participants = try await challengeRef
                                    .collection("participants")
                                    .getDocuments()
                                    .documents
                                    .compactMap { try? $0.data(as: Challenge.Participant.self) }
                                
                                challenge.participants = participants
                                
                                let events = try await challengeRef
                                    .collection("events")
                                    .order(by: "timestamp", descending: true)
                                    .limit(to: 15)
                                    .getDocuments()
                                    .documents
                                    .compactMap { try? $0.data(as: Challenge.ChallengeEvent.self) }
                                
                                challenge.recentEvents = events
                                
                                // Check if this is an active challenge
                                let now = Date()
                                let isActive = challenge.startTime <= now && challenge.endTime > now
                                
                                if isActive && !hasSetupActiveListener {
                                    // Only set up listeners for the first active challenge found
                                    hasSetupActiveListener = true
                                    activeChallenge = challenge
                                    print("🎯 Setting up listeners for active challenge: \(challenge.name)")
                                    
                                    // Set up real-time listener for active challenge document
                                    let challengeListener = challengeRef.addSnapshotListener { [weak self] challengeSnapshot, error in
                                        guard let self = self else { return }
                                        
                                        if error != nil {
                                            print("❌ Challenge listener error")
                                            return
                                        }
                                        
                                        if let snapshot = challengeSnapshot {
                                            if !snapshot.exists {
                                                print("🗑️ Challenge document was deleted")
                                                Task { @MainActor in
                                                    if self.activeChallenge?.id == challengeRef.documentID {
                                                        print("🧹 Clearing active challenge")
                                                        self.activeChallenge = nil
                                                    }
                                                }
                                            } else {
                                                // Document was updated
                                                Task {
                                                    do {
                                                        if var updatedChallenge = try? snapshot.data(as: Challenge.self) {
                                                            // Fetch latest participants
                                                            let participants = try await challengeRef
                                                                .collection("participants")
                                                                .getDocuments()
                                                                .documents
                                                                .compactMap { try? $0.data(as: Challenge.Participant.self) }
                                                            
                                                            updatedChallenge.participants = participants
                                                            
                                                            // Create local copy before async context
                                                            let finalChallenge = updatedChallenge
                                                            
                                                            // Update active challenge if this is the current one
                                                            await MainActor.run {
                                                                if self.activeChallenge?.id == challengeRef.documentID {
                                                                    print("📝 Updating active challenge data")
                                                                    self.activeChallenge = finalChallenge
                                                                }
                                                            }
                                                        }
                                                    } catch {
                                                        print("❌ Error updating challenge: \(error)")
                                                    }
                                                }
                                            }
                                        }
                                    }
                                    self.listeners.append(challengeListener)
                                    
                                    // Set up real-time listener for events
                                    let eventsListener = challengeRef.collection("events")
                                        .order(by: "timestamp", descending: true)
                                        .limit(to: 15)
                                        .addSnapshotListener { [weak self] eventsSnapshot, error in
                                            guard let self = self,
                                                  let documents = eventsSnapshot?.documents else { return }
                                            
                                            print("📊 Received events update")
                                            let events = documents.compactMap { try? $0.data(as: Challenge.ChallengeEvent.self) }
                                            
                                            Task { @MainActor in
                                                // Create local copy before using in async context
                                                if let currentChallenge = self.activeChallenge {
                                                    var updatedChallenge = currentChallenge
                                                    updatedChallenge.recentEvents = events
                                                    self.activeChallenge = updatedChallenge
                                                    print("📊 Updated active challenge events: \(events.count)")
                                                }
                                            }
                                        }
                                    self.listeners.append(eventsListener)
                                }
                                
                                challenges.append(challenge)
                            }
                        }
                        
                        // Filter and sort challenges
                        let completedChallenges = challenges
                            .filter { $0.endTime <= Date() }
                            .sorted { $0.endTime > $1.endTime }
                        
                        // Create local copies before async context
                        let finalActiveChallenge = activeChallenge
                        let finalCompletedChallenges = completedChallenges
                        
                        await MainActor.run {
                            print("📱 Updating challenges:")
                            print("   Active: \(finalActiveChallenge?.name ?? "none")")
                            print("   Completed: \(finalCompletedChallenges.count)")
                            self.activeChallenge = finalActiveChallenge
                            self.completedChallenges = finalCompletedChallenges
                        }
                        
                    } catch {
                        print("❌ Error fetching challenges: \(error)")
                    }
                }
            }
        
        listeners.append(participantListener)
    }
    
    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    func handleInvite(challengeId: String, userId: String, userName: String, referrerId: String?) async throws {
        let challengeRef = db.collection("challenges").document(challengeId)
        
        // Check if challenge exists and is valid
        guard let challengeDoc = try? await challengeRef.getDocument(),
              challengeDoc.exists,
              var challenge = try? challengeDoc.data(as: Challenge.self) else {
            throw ChallengeError.invalidChallenge
        }
        
        // Check if challenge hasn't ended
        guard challenge.endTime > Date() else {
            throw ChallengeError.challengeEnded
        }
        
        // Get current user's FCM token
        let token = Messaging.messaging().fcmToken
        
        // Create new participant
        let newParticipant = Challenge.Participant(
            id: userId,
            name: userName,
            inviteCount: 0,
            totalJabs: 0,
            averageScore: 0,
            fcmToken: token
        )
        
        // Create the invite event
        let event = Challenge.ChallengeEvent(
            id: UUID().uuidString,
            timestamp: Date(),
            type: .invite,
            userId: userId,
            userName: userName,
            details: "Joined the challenge",
            feedbackId: nil
        )
        
        try await challengeRef.updateData([
            "participants": FieldValue.arrayUnion([try Firestore.Encoder().encode(newParticipant)]),
            "events": FieldValue.arrayUnion([try Firestore.Encoder().encode(event)])
        ])
        
        // Notify other participants
        await notifyParticipants(
            challenge: challenge,
            title: "New Challenger! 🥊",
            body: "\(userName) joined the challenge!",
            excludeUserId: userId
        )
    }
    
    func checkAndHandleChallengeCompletion() async {
        guard let challenge = activeChallenge,
              challenge.endTime <= Date() else { return }
        
        do {
            // Move to completed challenges
            try await db.collection("completedChallenges")
                .document(challenge.id)
                .setData(from: challenge)
            
            // Delete from active challenges
            try await db.collection("challenges")
                .document(challenge.id)
                .delete()
            
            // Update local state
            activeChallenge = nil
            completedChallenges.insert(challenge, at: 0)
        } catch {
            print("❌ Error handling challenge completion: \(error)")
        }
    }
    
    enum ChallengeEvent {
        case feedbackViewed(feedbackId: String, score: Double)
        case invite(userId: String, userName: String)
    }
    
    
    private func notifyParticipants(challenge: Challenge, title: String, body: String, excludeUserId: String? = nil) async {
        NotificationManager.shared.sendChallengeNotification(
            message: body,
            challengeId: challenge.id
        )
    }
    
   func createChallenge(_ challenge: Challenge) async throws {
        let ref = db.collection("challenges").document(challenge.id)
        
        // Create main challenge document
        try await ref.setData(from: challenge)
        
        // Get current user's FCM token
        let token = Messaging.messaging().fcmToken
        
        // Create initial participant with FCM token
        let initialParticipant = Challenge.Participant(
            id: challenge.creatorId,
            name: userManager.user?.firstName ?? "Unknown",
            inviteCount: 0,
            totalJabs: 0,
            averageScore: 0,
            fcmToken: token
        )
        
        // Create participant in subcollection
        try await ref.collection("participants")
            .document(challenge.creatorId)
            .setData(from: initialParticipant)
        
        // Create initial event
        let event = Challenge.ChallengeEvent(
            id: UUID().uuidString,
            timestamp: Date(),
            type: .invite,
            userId: challenge.creatorId,
            userName: initialParticipant.name,
            details: "Created the challenge",
            feedbackId: nil
        )
        
        try await ref.collection("events")
            .document(event.id)
            .setData(from: event)
        
        // Notify about challenge creation
        await notifyParticipants(
            challenge: challenge,
            title: "New Challenge! 🥊",
            body: "\(initialParticipant.name) created a new challenge: \(challenge.name)",
            excludeUserId: challenge.creatorId
        )
        
        // Create a new challenge instance with the initial data
        let newChallenge = Challenge(
            id: challenge.id,
            name: challenge.name,
            description: challenge.description,
            creatorId: challenge.creatorId,
            startTime: challenge.startTime,
            endTime: challenge.endTime
        )
        
        // Set the collections data
        await MainActor.run {
            var updatedChallenge = newChallenge
            updatedChallenge.participants = [initialParticipant]
            updatedChallenge.recentEvents = [event]
            self.activeChallenge = updatedChallenge
        }
    }


    func processEvent(_ event: ChallengeEvent) async throws {
    switch event {
    case .feedbackViewed(let feedbackId, let score):
        print("🎯 Processing feedback event with score: \(score)")
        guard let userId = Auth.auth().currentUser?.uid,
              let challengeId = activeChallenge?.id,
              var challenge = activeChallenge else {
            print("❌ Missing required data for challenge event:")
            print("   userId: \(Auth.auth().currentUser?.uid ?? "nil")")
            print("   challengeId: \(activeChallenge?.id ?? "nil")")
            return
        }
        
        let challengeRef = db.collection("challenges").document(challengeId)
        
        // Check for duplicate feedback
        let existingEvents = try await challengeRef.collection("events")
            .whereField("feedbackId", isEqualTo: feedbackId)
            .getDocuments()
        
        if !existingEvents.documents.isEmpty {
            print("⚠️ Feedback already processed for this challenge")
            throw ChallengeError.duplicateEvent
        }
        
        print("🎯 Creating challenge event for user: \(userId)")
        let participantRef = challengeRef.collection("participants").document(userId)
        
        // Get current participant data
        let participantDoc = try await participantRef.getDocument()
        let currentTotalJabs = (participantDoc.data()?["totalJabs"] as? Int) ?? 0
        let currentScore = (participantDoc.data()?["averageScore"] as? Double) ?? 0
        let currentInvites = (participantDoc.data()?["inviteCount"] as? Int) ?? 0
        
        // Calculate new stats
        let newTotalJabs = currentTotalJabs + 1
        let newAverageScore = ((currentScore * Double(currentTotalJabs)) + score) / Double(newTotalJabs)
        let newFinalScore = (Double(currentInvites) * 50.0 * 0.5) + (Double(newTotalJabs) * 0.2) * min(max(newAverageScore / 10.0, 0.1), 2.0)
        
        print("📊 Updating participant stats:")
        print("   Total Jabs: \(currentTotalJabs) -> \(newTotalJabs)")
        print("   Average Score: \(currentScore) -> \(newAverageScore)")
        print("   Final Score: \(newFinalScore)")
        
        // Update all participant stats atomically
        try await participantRef.updateData([
            "totalJabs": newTotalJabs,
            "averageScore": newAverageScore,
            "finalScore": newFinalScore
        ])
        
        // Create and add event
        let challengeEvent = Challenge.ChallengeEvent(
            id: UUID().uuidString,
            timestamp: Date(),
            type: .score,
            userId: userId,
            userName: userManager.user?.firstName ?? "Unknown",
            details: "Scored \(String(format: "%.1f", score)) points",
            feedbackId: feedbackId
        )
        
        try await challengeRef.collection("events")
            .document(challengeEvent.id)
            .setData(from: challengeEvent)
        
        print("✅ Updated all participant stats and created event")
        
        // Notify other participants about the score
        await notifyParticipants(
            challenge: challenge,
            title: "New Score! 🎯",
            body: "\(userManager.user?.firstName ?? "Unknown") scored \(String(format: "%.1f", score)) points!",
            excludeUserId: userId
        )
        
    case .invite(let userId, let userName):
        try await handleInvite(challengeId: activeChallenge?.id ?? "", userId: userId, userName: userName, referrerId: nil)
    }
}
    
    func clearPendingChallenge() {
        UserDefaults.standard.removeObject(forKey: "pendingChallenge")
        print("🧹 Cleared pending challenge data")
    }
    
    func fetchChallenge(id: String) async throws -> Challenge? {
        print("🔍 Fetching challenge with ID: \(id)")
        
        let doc = try await db.collection("challenges").document(id).getDocument()
        
        if doc.exists {
            print("📄 Found document")
            print("📄 Raw data: \(doc.data() ?? [:])")
            return try doc.data(as: Challenge.self)
        } else {
            print("❌ No document found with ID: \(id)")
            return nil
        }
    }
    
    // Add method to load more events
    func loadMoreEvents(fromTimestamp: Date) async throws -> [Challenge.ChallengeEvent] {
        guard let challengeId = activeChallenge?.id else { return [] }
        
        return try await db.collection("challenges")
            .document(challengeId)
            .collection("events")
            .order(by: "timestamp", descending: true)
            .whereField("timestamp", isLessThan: fromTimestamp)
            .limit(to: 15)
            .getDocuments()
            .documents
            .compactMap { try? $0.data(as: Challenge.ChallengeEvent.self) }
    }
} 

struct PendingChallenge: Codable {
    let challengeId: String
    let referrerId: String?
}

