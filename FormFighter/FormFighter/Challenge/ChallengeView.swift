import SwiftUI
import FirebaseFirestore
import FirebaseAuth

struct ChallengeView: View {
    @StateObject private var viewModel = ChallengeViewModel()
    @State private var showCreateChallenge = false
    @State private var showInviteSheet = false
    
    var body: some View {
        Group {
            if viewModel.isLoading {
                ProgressView()
            } else if let challenge = viewModel.activeChallenge {
                ActiveChallengeView(challenge: challenge, viewModel: viewModel)
            } else {
                NoChallengeView(showCreateChallenge: $showCreateChallenge)
            }
        }
        .sheet(isPresented: $showCreateChallenge) {
            CreateChallengeView(viewModel: viewModel)
        }
        .onAppear {
            print("DEBUG: ChallengeView appeared")
            
            if let userId = Auth.auth().currentUser?.uid {
                print("DEBUG: User ID: \(userId)")
                Task {
                    await viewModel.refreshChallenge(userId: userId)
                }
            }
        }
    }
}





