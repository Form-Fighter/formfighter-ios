import SwiftUI
import Firebase
import FirebaseFirestore
import AVKit


struct FeedbackView: View {
    let feedbackId: String
    let videoURL: URL?
    
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var viewModel = FeedbackViewModel()
    @State private var currentTipIndex = 0
    @State private var lastNotifiedStatus: FeedbackStatus = .pending
    @State private var showFeedbackPrompt = false
    @State private var userComment = ""
    @State private var selectedEmoji: UserFeedbackType?
    @State private var hasSubmittedFeedback = false
    @State private var feedbackRating: Double = 3
    @State private var selectedImprovements: [String] = []
    @State private var wouldRecommend: Bool = false
    
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    private let muayThaiTips = [
        "Keep your guard up - protect your chin!",
        "Turn your hip over when throwing kicks",
        "Stay light on your feet, ready to move",
        "Breathe out when striking",
        "Return kicks and punches back to guard quickly",
        "Keep your elbows close to protect your body"
    ]
    
    // Add these properties for video sync
    @State private var originalPlayer: AVPlayer?
    @State private var overlayPlayer: AVPlayer?
    
    var body: some View {
        Group {
            if let feedback = viewModel.feedback {
               
                completedFeedbackView
            } else if let error = viewModel.error {
               
                UnexpectedErrorView(error: error)
            } else if videoURL != nil {
               
                uploadingView
            } else {
               
                processingView
            }
        }
        .onAppear {
            print("⚡️ FeedbackView body appeared")
            viewModel.setupFirestoreListener(feedbackId: feedbackId)
            if videoURL == nil {
                checkExistingUserFeedback()
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .sheet(isPresented: $showFeedbackPrompt) {
            UserFeedbackPrompt(
                userComment: $userComment,
                selectedEmoji: $selectedEmoji,
                feedbackRating: $feedbackRating,
                selectedImprovements: $selectedImprovements,
                wouldRecommend: $wouldRecommend,
                onSubmit: submitUserFeedback
            )
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            ProgressView()
                .scaleEffect(1.5)
            
            Text(viewModel.status.message)
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
                .animation(.easeInOut, value: viewModel.status)
            
            // Display random Muay Thai tips while processing
            if viewModel.status.isProcessing {
                Text(muayThaiTips[currentTipIndex])
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding()
                    .onAppear {
                        // Rotate through tips every few seconds
                        Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                            withAnimation {
                                currentTipIndex = (currentTipIndex + 1) % muayThaiTips.count
                            }
                        }
                    }
            }
        }
        .padding()
    }
    
    private var completedFeedbackView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // Add Share button at the top
                Button(action: {
                    // Share both videos if available
                    if let originalURL = originalPlayer?.currentItem?.asset as? AVURLAsset,
                       let overlayURL = overlayPlayer?.currentItem?.asset as? AVURLAsset {
                        let activityVC = UIActivityViewController(
                            activityItems: [originalURL.url, overlayURL.url],
                            applicationActivities: nil
                        )
                        // Get the window scene to present the share sheet
                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                           let window = windowScene.windows.first {
                            window.rootViewController?.present(activityVC, animated: true)
                        }
                    }
                }) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                    }
                    .padding()
                    .background(Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(8)
                }
                .padding(.horizontal)

                if let feedback = viewModel.feedback {
                    if !hasSubmittedFeedback {
                        FeedbackPromptButton(action: { showFeedbackPrompt = true })
                            .transition(.move(edge: .top).combined(with: .opacity))
                            .animation(.spring(response: 0.5, dampingFraction: 0.6), value: hasSubmittedFeedback)
                            .padding(.top)
                    }
                    
                    if let jabScore = feedback.modelFeedback?.body?.jab_score {
                        ScoreCardView(jabScore: jabScore)
                    }

                           // Video Comparison
                    if let videoUrl = feedback.videoUrl,
                       let overlayUrl = feedback.overlay_video_url,
                       !videoUrl.isEmpty,
                       !overlayUrl.isEmpty,
                       let originalURL = URL(string: videoUrl),
                       let overlayURL = URL(string: overlayUrl) {
                        
                        VStack {
                            if let player2 = overlayPlayer {
                                VideoPlayer(player: player2)
                                    .frame(height: 200)
                                    .cornerRadius(12)
                            }
                            
                            if let player1 = originalPlayer {
                                VideoPlayer(player: player1)
                                    .frame(height: 200)
                                    .cornerRadius(12)
                            }
                        }
                        .padding(.horizontal)
                        .onAppear {
                            setupSyncedVideos(originalURL: originalURL, overlayURL: overlayURL)
                        }
                        .onDisappear {
                            originalPlayer?.pause()
                            overlayPlayer?.pause()
                            originalPlayer = nil
                            overlayPlayer = nil
                        }
                    }
                    
                    
                    // Existing feedback sections
                    if let feedbackDetails = feedback.modelFeedback?.body?.feedback {
                        if let extensionFeedback = feedbackDetails.extensionFeedback {
                            FeedbackSection(title: "Extension", feedback: extensionFeedback)
                        }
                        if let guardFeedback = feedbackDetails.guardPosition {
                            FeedbackSection(title: "Guard", feedback: guardFeedback)
                        }
                        if let retractionFeedback = feedbackDetails.retraction {
                            FeedbackSection(title: "Retraction", feedback: retractionFeedback)
                        }
                    }
                    
                   
                }
            }
            .padding()
        }
    }
    
    private var uploadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "figure.martial.arts")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(viewModel.status.message)
                .font(.headline)
            
            ProgressView()
                .progressViewStyle(.linear)
                .frame(width: 200)
            
            VStack(spacing: 10) {
                Text("Muay Thai Tip:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(muayThaiTips[currentTipIndex])
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .transition(.opacity)
                    .id(currentTipIndex)
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .onReceive(timer) { _ in
            withAnimation {
                currentTipIndex = (currentTipIndex + 1) % muayThaiTips.count
            }
        }
    }
    
    private func checkExistingUserFeedback() {
        viewModel.checkExistingUserFeedback(feedbackId: feedbackId) { hasSubmitted in
            hasSubmittedFeedback = hasSubmitted
        }
    }
    
    private func submitUserFeedback() {
        guard let emoji = selectedEmoji else { return }
        
        print("Submitting feedback:")
        print("- Rating: \(feedbackRating)")
        print("- Improvements: \(selectedImprovements)")
        print("- Would Recommend: \(wouldRecommend)")
        
        viewModel.submitUserFeedback(
            feedbackId: feedbackId,
            emoji: emoji,
            comment: userComment,
            rating: feedbackRating,
            improvements: selectedImprovements,
            wouldRecommend: wouldRecommend
        ) { success in
            if success {
                hasSubmittedFeedback = true
                showFeedbackPrompt = false
                Tracker.feedbackSubmitted(type: emoji, rating: feedbackRating)
            }
        }
    }
    
    private func setupSyncedVideos(originalURL: URL, overlayURL: URL) {
        // Create players
        originalPlayer = AVPlayer(url: originalURL)
        overlayPlayer = AVPlayer(url: overlayURL)
        
        // Setup looping
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: originalPlayer?.currentItem,
            queue: .main
        ) { _ in
            originalPlayer?.seek(to: .zero)
            originalPlayer?.play()
        }
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: overlayPlayer?.currentItem,
            queue: .main
        ) { _ in
            overlayPlayer?.seek(to: .zero)
            overlayPlayer?.play()
        }
        
        // Start playback
        originalPlayer?.play()
        overlayPlayer?.play()
    }
}

struct UnexpectedErrorView: View {
    let error: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Unexpected Error")
                .font(.title)
            
            Text(error)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Button(action: {
                // Add retry logic here if needed
            }) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView(feedbackId: "sampleFeedbackId", videoURL: nil)
    }
}

struct UserFeedbackPrompt: View {
    @Binding var userComment: String
    @Binding var selectedEmoji: UserFeedbackType?
    @Binding var feedbackRating: Double
    @Binding var selectedImprovements: [String]
    @Binding var wouldRecommend: Bool
    @Environment(\.dismiss) private var dismiss
    let onSubmit: () -> Void
    
    @State private var currentStep = 1
    
    private let improvements = [
        "More detailed feedback",
        "Faster analysis",
        "Additional tips",
        "Clearer instructions",
        "Better visuals"
    ]
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Progress indicator
                    ProgressView("Step \(currentStep) of 3", value: Double(currentStep), total: 3.0)
                        .padding(.horizontal)
                    
                    // Step 1: Emoji Selection
                    if currentStep == 1 {
                        FeedbackStepOne(selectedEmoji: $selectedEmoji)
                    }
                    
                    // Step 2: Rating and Improvements
                    if currentStep == 2 {
                        FeedbackStepTwo(feedbackRating: $feedbackRating, selectedImprovements: $selectedImprovements, improvements: improvements)
                    }
                    
                    // Step 3: Final Comments
                    if currentStep == 3 {
                        FeedbackStepThree(userComment: $userComment, wouldRecommend: $wouldRecommend)
                    }
                    
                    // Navigation buttons
                    HStack(spacing: 20) {
                        if currentStep > 1 {
                            Button("Back") {
                                withAnimation {
                                    currentStep -= 1
                                }
                            }
                            .buttonStyle(MuayThaiSecondaryButtonStyle())
                        }
                        
                        Button(currentStep == 3 ? "Submit" : "Next") {
                            if currentStep == 3 {
                                onSubmit()
                                dismiss()
                            } else {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        }
                        .buttonStyle(MuayThaiButtonStyle())
                        .disabled(currentStep == 1 && selectedEmoji == nil)
                    }
                    .padding()
                }
                .padding(.vertical)
            }
            .navigationBarItems(
                leading: Button("Cancel") {
                    dismiss()
                }
            )
        }
    }
}

struct FeedbackPromptButton: View {
    let action: () -> Void
    @State private var isAnimating = false
    @State private var gloveRotation = 0.0
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text("🥊")
                    .font(.title2)
                    .rotationEffect(.degrees(gloveRotation))
                Text("How was this feedback?")
                    .foregroundColor(ThemeColors.primary)
                Spacer()
                Image(systemName: "chevron.right")
                    .foregroundColor(ThemeColors.primary)
                    .rotationEffect(.degrees(isAnimating ? 10 : 0))
            }
            .padding()
            .background(Color.red.opacity(0.1))
            .cornerRadius(10)
            .scaleEffect(isAnimating ? 1.02 : 1.0)
        }
        .onAppear {
            // Slower pulse animation
            withAnimation(
                .easeInOut(duration: 2.0)
                .repeatForever(autoreverses: true)
            ) {
                isAnimating = true
            }
            
            // Slower glove rotation
            withAnimation(
                .linear(duration: 4.0)
                .repeatForever(autoreverses: false)
            ) {
                gloveRotation = 360.0
            }
        }
    }
}


struct FeedbackStepOne: View {
    @Binding var selectedEmoji: UserFeedbackType?
    
    var body: some View {
        VStack(spacing: 16) {
            Text("How was your boxing feedback?")
                .font(.title2)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
            
            HStack(spacing: 30) {
                ForEach(UserFeedbackType.allCases, id: \.self) { emoji in
                    EmojiButton(
                        emoji: emoji,
                        isSelected: selectedEmoji == emoji,
                        action: {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.6)) {
                                selectedEmoji = emoji
                            }
                        }
                    )
                }
            }
            .padding()
        }
    }
}

struct FeedbackStepTwo: View {
    @Binding var feedbackRating: Double
    @Binding var selectedImprovements: [String]
    let improvements: [String]
    
    var body: some View {
        VStack(spacing: 20) {
            Text("How helpful was the feedback?")
                .font(.headline)
            
            HStack {
                Text("1")
                Slider(value: $feedbackRating, in: 1...5, step: 0.5)
                    .accentColor(.red)
                Text("5")
            }
            .padding(.horizontal)
            
            Text("What could we improve?")
                .font(.headline)
                .padding(.top)
            
            ImprovementsGridView(selectedImprovements: $selectedImprovements, improvements: improvements)
        }
    }
}

struct FeedbackStepThree: View {
    @Binding var userComment: String
    @Binding var wouldRecommend: Bool
    
    var body: some View {
        VStack(spacing: 16) {
            Text("Any additional thoughts?")
                .font(.headline)
            
            TextField("Share your experience (optional)", text: $userComment, axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(4...6)
            
            Toggle("I would recommend this app", isOn: $wouldRecommend)
                .tint(.red)
                .padding(.vertical)
        }
        .padding(.horizontal)
    }
}




