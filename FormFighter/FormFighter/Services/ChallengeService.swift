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
    private let logger = OSLog(subsystem: Bundle.main.bundleIdentifier ?? "com.formfighter.app", category: "ChallengeService")
    
    private init() {}
    
    func startListening(userId: String) {
        // Listen for active challenge
        let activeChallengeListener = db.collection("challenges")
            .whereField("participants", arrayContains: ["id": userId])
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    os_log("Error listening for active challenge: %@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                    return
                }
                
                self?.activeChallenge = snapshot?.documents.first.flatMap { try? $0.data(as: Challenge.self) }
            }
        
        // Listen for completed challenges
        let completedChallengesListener = db.collection("completedChallenges")
            .whereField("participants", arrayContains: ["id": userId])
            .order(by: "endTime", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                if let error = error {
                    os_log("Error listening for completed challenges: %@", log: self?.logger ?? .default, type: .error, error.localizedDescription)
                    return
                }
                
                self?.completedChallenges = snapshot?.documents.compactMap { try? $0.data(as: Challenge.self) } ?? []
            }
        
        listeners.append(contentsOf: [activeChallengeListener, completedChallengesListener])
    }
    
    func stopListening() {
        listeners.forEach { $0.remove() }
        listeners.removeAll()
    }
    
    func handleInvite(challengeId: String, userId: String, userName: String) async throws {
        let challengeRef = db.collection("challenges").document(challengeId)
        
        guard let challengeDoc = try? await challengeRef.getDocument(),
              let challenge = try? challengeDoc.data(as: Challenge.self),
              challenge.endTime > Date() else {
            throw ChallengeError.invalidChallenge
        }
        
        let newParticipant = Challenge.Participant(
            id: userId,
            name: userName,
            inviteCount: 0,
            totalJabs: 0,
            averageScore: 0
        )
        
        try await challengeRef.updateData([
            "participants": FieldValue.arrayUnion([try Firestore.Encoder().encode(newParticipant)])
        ])
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
            os_log("Error handling challenge completion: %@", log: logger, type: .error, error.localizedDescription)
        }
    }
    
    enum ChallengeEvent {
        case feedbackViewed(feedbackId: String, score: Double)
        case invite(userId: String, userName: String)
    }
    
    func processEvent(_ event: ChallengeEvent) async throws {
        switch event {
        case .feedbackViewed(let feedbackId, let score):
            guard let userId = Auth.auth().currentUser?.uid else { return }
            let challengeRef = db.collection("challenges").document(activeChallenge?.id ?? "")
            
            // Handle DocumentSnapshot as optional
            guard let challengeDoc = try? await challengeRef.getDocument(),
                  challengeDoc.exists else {
                throw ChallengeError.invalidChallenge
            }
            
            // Handle Challenge as optional
            guard let challenge = try? challengeDoc.data(as: Challenge.self),
                  var participant = challenge.participants.first(where: { $0.id == userId }) else {
                throw ChallengeError.invalidChallenge
            }
            
            // Update participant stats
            participant.totalJabs += 1
            let oldAverage = participant.averageScore
            participant.averageScore = ((oldAverage * Double(participant.totalJabs - 1)) + score) / Double(participant.totalJabs)
            
            let event = Challenge.ChallengeEvent(
                id: UUID().uuidString,
                timestamp: Date(),
                type: .score,
                userId: userId,
                userName: participant.name,
                details: String(format: "Scored %.1f on their jab", score)
            )
            
            try await challengeRef.updateData([
                "participants": challenge.participants.map { $0.id == userId ? participant : $0 },
                "events": FieldValue.arrayUnion([try Firestore.Encoder().encode(event)])
            ])
            
        case .invite(let userId, let userName):
            // Handle invite event
            break
        }
    }
} 