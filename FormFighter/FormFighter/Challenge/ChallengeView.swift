import SwiftUI
import FirebaseFirestore

struct ChallengeView: View {
    @StateObject private var viewModel = ChallengeViewModel()
    @State private var showCreateChallenge = false
    @State private var selectedTab = 0
    
    var body: some View {
        NavigationView {
            Group {
                if viewModel.isLoading {
                    ProgressView()
                } else if let activeChallenge = viewModel.activeChallenge {
                    ActiveChallengeView(challenge: activeChallenge)
                } else {
                    TabView(selection: $selectedTab) {
                        // No Active Challenge
                        VStack(spacing: 20) {
                            Image(systemName: "trophy.fill")
                                .font(.system(size: 60))
                                .foregroundColor(ThemeColors.primary)
                            
                            Text("No Active Challenge")
                                .font(.title2)
                                .fontWeight(.bold)
                            
                            Text("Create a challenge or join one through an invitation link")
                                .multilineTextAlignment(.center)
                                .foregroundColor(.secondary)
                            
                            Button {
                                showCreateChallenge = true
                            } label: {
                                Label("Create Challenge", systemImage: "plus.circle.fill")
                                    .font(.headline)
                                    .foregroundColor(.white)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: 50)
                                    .background(ThemeColors.primary)
                                    .cornerRadius(10)
                            }
                            .padding(.horizontal)
                        }
                        .padding()
                        .tag(0)
                        
                        // Challenge History
                        if !viewModel.completedChallenges.isEmpty {
                            ChallengeHistoryView(challenges: viewModel.completedChallenges)
                                .tag(1)
                        }
                    }
                    .tabViewStyle(.page)
                    .indexViewStyle(.page(backgroundDisplayMode: .always))
                }
            }
            .navigationTitle("Challenge")
            .sheet(isPresented: $showCreateChallenge) {
                CreateChallengeView(viewModel: viewModel)
            }
        }
    }
}

