import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine
import OSLog


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
                        
                        for participantDoc in participantDocs {
                            let challengeRef = participantDoc.reference.parent.parent!
                            if let challengeDoc = try? await challengeRef.getDocument(),
                               var challenge = try? challengeDoc.data(as: Challenge.self) {
                                
                                // Fetch participants
                                let participants = try await challengeRef
                                    .collection("participants")
                                    .getDocuments()
                                    .documents
                                    .compactMap { try? $0.data(as: Challenge.Participant.self) }
                                
                                challenge.participants = participants
                                
                                // Fetch recent events
                                let events = try await challengeRef
                                    .collection("events")
                                    .order(by: "timestamp", descending: true)
                                    .limit(to: 15)
                                    .getDocuments()
                                    .documents
                                    .compactMap { try? $0.data(as: Challenge.ChallengeEvent.self) }
                                
                                challenge.recentEvents = events
                                challenges.append(challenge)
                            }
                        }
                        
                        // Filter and sort challenges
                        let now = Date()
                        let activeChallenges = challenges
                            .filter { $0.startTime <= now && $0.endTime > now }
                            .sorted { $0.startTime > $1.startTime }
                        
                        let completedChallenges = challenges
                            .filter { $0.endTime <= now }
                            .sorted { $0.endTime > $1.endTime }
                        
                        await MainActor.run {
                            print("📱 Updating challenges:")
                            print("   Active: \(activeChallenges.first?.name ?? "none")")
                            print("   Completed: \(completedChallenges.count)")
                            self.activeChallenge = activeChallenges.first
                            self.completedChallenges = completedChallenges
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
        
        // Create new participant
        let newParticipant = Challenge.Participant(
            id: userId,
            name: userName,
            inviteCount: 0,
            totalJabs: 0,
            averageScore: 0
        )
        
        // Create the invite event
        let event = Challenge.ChallengeEvent(
            id: UUID().uuidString,
            timestamp: Date(),
            type: .invite,
            userId: userId,
            userName: userName,
            details: "Joined the challenge"
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
        
        // Create initial participant
        let initialParticipant = Challenge.Participant(
            id: challenge.creatorId,
            name: userManager.user?.firstName ?? "Unknown",
            inviteCount: 0,
            totalJabs: 0,
            averageScore: 0
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
            details: "Created the challenge"
        )
        
        try await ref.collection("events")
            .document(event.id)
            .setData(from: event)
        
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
        guard let userId = Auth.auth().currentUser?.uid,
              let challengeId = activeChallenge?.id else { return }
              
        let challengeRef = db.collection("challenges").document(challengeId)
        let participantRef = challengeRef.collection("participants").document(userId)
        
        // Update participant stats
        try await participantRef.updateData([
            "totalJabs": FieldValue.increment(Int64(1)),
            "averageScore": score  // Simple assignment for now
        ])
        
        // Create and add event
        let challengeEvent = Challenge.ChallengeEvent(
            id: UUID().uuidString,
            timestamp: Date(),
            type: .score,
            userId: userId,
            userName: userManager.user?.firstName ?? "Unknown",
            details: "Scored \(score) points"
        )
        
        let eventRef = challengeRef.collection("events").document(challengeEvent.id)
        try await eventRef.setData(from: challengeEvent)
        
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