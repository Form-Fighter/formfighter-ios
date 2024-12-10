import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ChallengeViewModel: ObservableObject {
    @Published var activeChallenge: Challenge?
    @Published var completedChallenges: [Challenge] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showFeedbackToast = false
    @Published var toastMessage = ""
    
    private let challengeService = ChallengeService.shared
    private let userManager = UserManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to challenge service updates
        challengeService.$activeChallenge
            .assign(to: &$activeChallenge)
        
        challengeService.$completedChallenges
            .assign(to: &$completedChallenges)
            
        if let userId = Auth.auth().currentUser?.uid {
            challengeService.startListening(userId: userId)
        }
    }
    
    func createChallenge(name: String, description: String) async throws {
        isLoading = true
        defer { isLoading = false }
        
        guard let userId = Auth.auth().currentUser?.uid,
              activeChallenge == nil else {
            throw ChallengeError.alreadyInChallenge
        }
        
        let challenge = Challenge(
            id: UUID().uuidString,
            name: name,
            description: description,
            creatorId: userId,
            startTime: Date(),
            endTime: Date().addingTimeInterval(7200),
            participants: [
                Challenge.Participant(
                    id: userId,
                    name: userManager.user?.firstName ?? "Unknown",
                    inviteCount: 0,
                    totalJabs: 0,
                    averageScore: 0
                )
            ],
            events: []
        )
        
        do {
            try await Firestore.firestore()
                .collection("challenges")
                .document(challenge.id)
                .setData(from: challenge)
                
            showToast(message: "Challenge created! Share with friends to start competing.")
        } catch {
            self.error = error
            throw error
        }
    }
    
    private func showToast(message: String) {
        toastMessage = message
        showFeedbackToast = true
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            self.showFeedbackToast = false
        }
    }
    
    func handleInvite(challengeId: String) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let userName = userManager.user?.firstName else {
            throw ChallengeError.invalidChallenge
        }
        
        isLoading = true
        defer { isLoading = false }
        
        do {
            try await challengeService.handleInvite(
                challengeId: challengeId,
                userId: userId,
                userName: userName
            )
            showToast(message: "Successfully joined challenge!")
        } catch {
            self.error = error
            throw error
        }
    }
    
    func shareChallenge() -> String? {
        guard let challenge = activeChallenge else { return nil }
        return "formfighter://challenge/\(challenge.id)"
    }
    
    private func handleError(_ error: Error) {
        self.error = error
        showFeedbackToast = true
        toastMessage = error.localizedDescription
    }
} 
