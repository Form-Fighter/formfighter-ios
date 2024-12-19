import Foundation
import FirebaseFirestore
import FirebaseAuth
import Combine

class ChallengeViewModel: ObservableObject {
    @Published var activeChallenge: Challenge? {
        didSet {
            print("DEBUG: activeChallenge set to: \(activeChallenge?.name ?? "nil")")
            if let challenge = activeChallenge {
                print("DEBUG: Challenge details:")
                print("  - ID: \(challenge.id)")
                print("  - Name: \(challenge.name)")
                print("  - Creator: \(challenge.creatorId)")
                print("  - Start: \(challenge.startTime)")
                print("  - End: \(challenge.endTime)")
                print("  - Participants: \(challenge.participants.count)")
                print("  - Events: \(challenge.recentEvents.count)")
            }
        }
    }
    @Published var completedChallenges: [Challenge] = []
    @Published var isLoading = false
    @Published var error: Error?
    @Published var showFeedbackToast = false
    @Published var toastMessage = ""
    @Published var isLoadingMoreEvents = false
    @Published var hasMoreEvents = true
    
    private let challengeService = ChallengeService.shared
    private let userManager = UserManager.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        print("DEBUG: ChallengeViewModel initialized")
        challengeService.$activeChallenge
            .receive(on: DispatchQueue.main)
            .sink { [weak self] challenge in
                print("🔄 ChallengeViewModel received challenge update: \(challenge?.name ?? "nil")")
                print("   Participants: \(challenge?.participants.count ?? 0)")
                print("   Events: \(challenge?.recentEvents.count ?? 0)")
                if challenge == nil {
                    print("📱 Challenge was removed or set to nil")
                }
                self?.activeChallenge = challenge
            }
            .store(in: &cancellables)
        
        challengeService.$completedChallenges
            .receive(on: DispatchQueue.main)
            .sink { [weak self] challenges in
                self?.completedChallenges = challenges
            }
            .store(in: &cancellables)
            
        if let userId = Auth.auth().currentUser?.uid {
            challengeService.startListening(userId: userId)
        }
    }
    
    func createChallenge(name: String, description: String) async throws {
        print("📝 Starting challenge creation...")
        
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        guard let userId = Auth.auth().currentUser?.uid,
              activeChallenge == nil else {
            print("❌ Challenge creation failed: \(activeChallenge == nil ? "active challenge exists" : "no user ID")")
            throw ChallengeError.alreadyInChallenge
        }
        
        print("👤 Creating challenge for user: \(userId)")
        
        let challengeId = UUID().uuidString.replacingOccurrences(of: "-", with: "").lowercased()
        
        let challenge = Challenge(
            id: challengeId,
            name: name,
            description: description,
            creatorId: userId,
            startTime: Date(),
            endTime: Date().addingTimeInterval(7200)
        )
        
        do {
            try await challengeService.createChallenge(challenge)
            
            await MainActor.run {
                showToast(message: "Challenge created! Share with friends to start competing.")
            }
        } catch {
            print("❌ Challenge creation error: \(error.localizedDescription)")
            await MainActor.run {
                self.error = error
            }
            throw error
        }
    }
    
    @MainActor
    private func showToast(message: String) {
        toastMessage = message
        showFeedbackToast = true
        
        Task {
            try? await Task.sleep(nanoseconds: 3_000_000_000)
            showFeedbackToast = false
        }
    }
    
    func processInvite(challengeId: String, referrerId: String?) async throws {
        guard let userId = Auth.auth().currentUser?.uid,
              let userName = userManager.user?.firstName else {
            challengeService.clearPendingChallenge()
            throw ChallengeError.invalidChallenge
        }
        
        await MainActor.run {
            isLoading = true
        }
        
        defer {
            Task { @MainActor in
                isLoading = false
            }
        }
        
        do {
            try await challengeService.handleInvite(
                challengeId: challengeId,
                userId: userId,
                userName: userName,
                referrerId: referrerId
            )
            await MainActor.run {
                showToast(message: "Successfully joined challenge!")
            }
        } catch {
            challengeService.clearPendingChallenge()
            await MainActor.run {
                self.error = error
            }
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
    
    func debugFetchChallenge(id: String) async {
        do {
            if let challenge = try await challengeService.fetchChallenge(id: id) {
                print("🔍 Debug - Found challenge:")
                print("Name: \(challenge.name)")
                print("Creator: \(challenge.creatorId)")
                print("Participants: \(challenge.participants)")
                print("Events: \(challenge.recentEvents)")
            } else {
                print("🔍 Debug - No challenge found with ID: \(id)")
            }
        } catch {
            print("🔍 Debug - Error fetching challenge: \(error)")
        }
    }
    
    func loadMoreEvents() async {
        guard !isLoadingMoreEvents,
              hasMoreEvents,
              let challenge = activeChallenge,
              let lastEventDate = challenge.recentEvents.last?.timestamp else { return }
        
        await MainActor.run { isLoadingMoreEvents = true }
        
        do {
            let newEvents = try await challengeService.loadMoreEvents(
                fromTimestamp: lastEventDate
            )
            
            await MainActor.run {
                if var updatedChallenge = activeChallenge {
                    updatedChallenge.recentEvents.append(contentsOf: newEvents)
                    activeChallenge = updatedChallenge
                    hasMoreEvents = newEvents.count >= 15
                }
                isLoadingMoreEvents = false
            }
        } catch {
            print("❌ Error loading more events: \(error)")
            await MainActor.run {
                isLoadingMoreEvents = false
                hasMoreEvents = false
            }
        }
    }
    
    func refreshChallenge(userId: String) async {
        await MainActor.run { isLoading = true }
        challengeService.startListening(userId: userId)
        await MainActor.run { isLoading = false }
    }
} 
