import SwiftUI
import AVKit

struct FeedbackView: View {
    @State private var player = AVPlayer(url: URL(string: "https://example.com/video.mp4")!)
    private let feedbackURL = URL(string: "https://example.com/feedback")!
    
    @State private var isLoading = true
    @State private var overallScore: Int? = nil
    @State private var categoryFeedbacks: [(category: String, score: Int, feedback: String)] = []
    var feedbackID: String? // This ID will determine if data is pulled from Firebase or the server
    
    @State private var loadingMessages = [
        "Analyzing your jab...",
        "Looking at your feet...",
        "Evaluating your hip rotation...",
        "Checking your guard...",
        "Assessing your stance..."
    ]
    @State private var currentLoadingMessageIndex = 0
    @State private var timer: Timer?
    @State private var isLoadedFromServer = false
    
    var body: some View {
        VStack {
            if isLoading {
                VStack {
                    ProgressView(loadingMessages[currentLoadingMessageIndex])
                        .padding()
                }
                .onAppear {
                    startLoadingMessageTimer()
                }
            } else {
                // Video Player
                VideoPlayer(player: player)
                    .frame(height: 250)
                    .onAppear {
                        player.play()
                        player.actionAtItemEnd = .none
                        NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                            player.seek(to: .zero)
                            player.play()
                        }
                    }
                    .padding()
                    .transition(.opacity)
                    .animation(.easeIn(duration: 0.5))
                
                // Share Button
                HStack {
                    Button(action: shareFeedback) {
                        Label("Share Feedback", systemImage: "square.and.arrow.up")
                    }
                    .padding()
                    Spacer()
                    Button(action: copyToClipboard) {
                        Label("Copy URL", systemImage: "doc.on.doc")
                    }
                    .padding()
                }
                
                Divider()
                    .padding(.vertical)
                
                // Overall Score
                if let overallScore = overallScore {
                    Text("Overall Score: \(overallScore)")
                        .font(.title)
                        .padding()
                }
                
                // Category Scores & Feedback
                VStack(alignment: .leading, spacing: 15) {
                    ForEach(categoryFeedbacks, id: \ .category) { feedback in
                        CategoryFeedbackView(category: feedback.category, score: feedback.score, feedback: feedback.feedback)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Next Button to User Feedback Page (Only if loaded from server)
                if isLoadedFromServer {
                    Button(action: navigateToUserFeedback) {
                        Text("Next")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(Color.blue)
                            .cornerRadius(10)
                            .padding(.horizontal)
                    }
                }
            }
        }
        .onAppear {
            loadFeedback()
        }
    }
    
    // Load Feedback Function
    private func loadFeedback() {
        if let feedbackID = feedbackID {
            loadFromFirebase(feedbackID: feedbackID) { (success, firebaseData) in
                if success, let data = firebaseData {
                    // Data successfully loaded from Firebase
                    withAnimation {
                        self.overallScore = data.overallScore
                        self.categoryFeedbacks = data.categoryFeedbacks
                        self.isLoading = false
                    }
                    stopLoadingMessageTimer()
                } else {
                    // If Firebase data is not available, load from server
                    loadFromServer { serverData in
                        withAnimation {
                            self.overallScore = serverData.overallScore
                            self.categoryFeedbacks = serverData.categoryFeedbacks
                            self.isLoading = false
                            self.isLoadedFromServer = true
                        }
                        stopLoadingMessageTimer()
                        
                        // Optionally save server data to Firebase for future faster retrieval
                        saveToFirebase(data: serverData)
                    }
                }
            }
        } else {
            // No feedback ID provided, load from server
            loadFromServer { serverData in
                withAnimation {
                    self.overallScore = serverData.overallScore
                    self.categoryFeedbacks = serverData.categoryFeedbacks
                    self.isLoading = false
                    self.isLoadedFromServer = true
                }
                stopLoadingMessageTimer()
            }
        }
    }
    
    private func startLoadingMessageTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            currentLoadingMessageIndex = (currentLoadingMessageIndex + 1) % loadingMessages.count
        }
    }
    
    private func stopLoadingMessageTimer() {
        timer?.invalidate()
        timer = nil
    }
    
    private func loadFromFirebase(feedbackID: String, completion: @escaping (Bool, (overallScore: Int, categoryFeedbacks: [(category: String, score: Int, feedback: String)])?) -> Void) {
        // Simulating Firebase data check
        let firebaseDataAvailable = false // This would be a real check in a Firebase call
        
        if firebaseDataAvailable {
            // If data exists in Firebase
            let data = (
                overallScore: 85,
                categoryFeedbacks: [
                    (category: "Hand Position", score: 90, feedback: "Good alignment"),
                    (category: "Footwork", score: 80, feedback: "Needs more stability"),
                    (category: "Hip Rotation", score: 85, feedback: "Smooth movement"),
                    (category: "Guard", score: 75, feedback: "Keep guard tighter")
                ]
            )
            completion(true, data)
        } else {
            // If no data found in Firebase
            completion(false, nil)
        }
    }
    
    private func loadFromServer(completion: @escaping ((overallScore: Int, categoryFeedbacks: [(category: String, score: Int, feedback: String)])) -> Void) {
        // Simulating server request with delay
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            // This would be replaced with actual server call logic
            let data = (
                overallScore: 85,
                categoryFeedbacks: [
                    (category: "Hand Position", score: 90, feedback: "Good alignment"),
                    (category: "Footwork", score: 80, feedback: "Needs more stability"),
                    (category: "Hip Rotation", score: 85, feedback: "Smooth movement"),
                    (category: "Guard", score: 75, feedback: "Keep guard tighter")
                ]
            )
            completion(data)
        }
    }
    
    private func saveToFirebase(data: (overallScore: Int, categoryFeedbacks: [(category: String, score: Int, feedback: String)])) {
        // Logic to save data to Firebase for future use
        // This would involve Firebase API to save the structured data
    }
    
    // Share Feedback Function
    private func shareFeedback() {
        let activityController = UIActivityViewController(activityItems: [feedbackURL], applicationActivities: nil)
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityController, animated: true, completion: nil)
        }
    }
    
    // Copy URL to Clipboard Function
    private func copyToClipboard() {
        UIPasteboard.general.string = feedbackURL.absoluteString
    }
    
    // Navigate to User Feedback Page
    private func navigateToUserFeedback() {
        // Logic to navigate to user feedback page
        // This would depend on the navigation structure of your app (e.g., using a NavigationLink or programmatic navigation)
        print("Navigating to user feedback page...")
    }
}

struct CategoryFeedbackView: View {
    let category: String
    let score: Int
    let feedback: String
    
    var body: some View {
        VStack(alignment: .leading) {
            HStack {
                Text("\(category):")
                    .font(.headline)
                Spacer()
                Text("Score: \(score)")
                    .font(.subheadline)
            }
            Text(feedback)
                .font(.body)
                .foregroundColor(.secondary)
        }
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView()
    }
}
