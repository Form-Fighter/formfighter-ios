import SwiftUI
import Firebase
import FirebaseFirestore
import AVKit
import AVFoundation
import Photos  // Add this for PHPhotoLibrary


struct FeedbackView: View {
    @StateObject private var viewModel: FeedbackViewModel
    let feedbackId: String
    let videoURL: URL?
    
    @State private var isLoading = true
    @State private var hasAppeared = false
    
    init(feedbackId: String, videoURL: URL? = nil) {
        self.feedbackId = feedbackId
        self.videoURL = videoURL
        self._viewModel = StateObject(wrappedValue: FeedbackViewModel())
    }
    
    @Environment(\.dismiss) private var dismiss
    
    @StateObject private var notificationManager = NotificationManager.shared
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
     
    private class SharingState: ObservableObject {
        @Published var isLoading = false
        @Published var error: String?
    }
    
    @StateObject private var sharingState = SharingState()
    
    @State private var showingSavedAlert = false
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .onAppear {
                        print("⚡️ FeedbackView body appeared")
                        if !hasAppeared {
                            hasAppeared = true
                            setupView()
                        }
                    }
            } else if let feedback = viewModel.feedback, viewModel.status == .completed {
                ScrollView {
                    VStack(spacing: 20) {
                        completedFeedbackView
                        
                        // Challenge Indicator (if in active challenge)
                        if viewModel.shouldShowChallengeIndicator,
                           let challengeInfo = viewModel.activeChallengeInfo {
                            HStack {
                                Image(systemName: "trophy.fill")
                                    .foregroundColor(ThemeColors.primary)
                                Text("This jab will count towards '\(challengeInfo.name)'")
                                    .font(.subheadline)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.horizontal)
                            .padding(.vertical, 8)
                            .background(Color(.systemBackground))
                            .cornerRadius(8)
                        }
                    }
                }
                // Challenge Toast
                .overlay(alignment: .bottom) {
                    if let toastMessage = viewModel.challengeToast {
                        ToastView(message: toastMessage)
                            .transition(.move(edge: .bottom))
                            .animation(.spring(), value: viewModel.challengeToast)
                    }
                }
            } else if let error = viewModel.error {
                UnexpectedErrorView(error: error)
            } else {
                processingView
            }
        }
        .onChange(of: viewModel.feedback) { newValue in
            if newValue != nil {
                withAnimation {
                    isLoading = false
                }
                // Analytics
                Analytics.logEvent("feedback_viewed", parameters: [
                    "feedback_id": feedbackId,
                    "status": viewModel.status.rawValue
                ])
                Tracker.feedbackPageOpened(feedbackId: feedbackId)
            }
        }
        .onChange(of: viewModel.status) { newStatus in
            print("⚡️ Status changed to: \(newStatus)")
            if newStatus == .completed {
                withAnimation {
                    isLoading = false
                }
            }
        }
        .onDisappear {
            print("⚡️ FeedbackView cleaning up")
            viewModel.cleanup()
            Tracker.feedbackPageClosed(feedbackId: feedbackId)
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
        .overlay(
            Group {
                if showingSavedAlert {
                    VStack {
                        Spacer()
                        Text("Saved to Camera Roll")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.75))
                            .cornerRadius(10)
                            .padding(.bottom, 30)
                    }
                    .transition(.move(edge: .bottom))
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                            withAnimation {
                                showingSavedAlert = false
                            }
                        }
                    }
                }
            }
        )
    }
    
    private func setupView() {
        print("⚡️ FeedbackView setting up listener for ID: \(feedbackId)")
        viewModel.setupFirestoreListener(feedbackId: feedbackId)
        if videoURL == nil {
            print("⚡️ Checking existing user feedback")
            checkExistingUserFeedback()
        }
        
        // Set loading to false after a timeout
        DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
            isLoading = false
        }
    }
    
    private var processingView: some View {
        VStack(spacing: 20) {
            if viewModel.status == .error {
                // Error State
                VStack(spacing: 16) {
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 50))
                        .foregroundColor(ThemeColors.primary)
                    
                    Text("Something went wrong")
                        .font(.title3)
                        .fontWeight(.bold)
                        .multilineTextAlignment(.center)
                    
                    Text("Please try filming yourself again")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    
                    Button(action: {
                        // Dismiss the view
                        dismiss()
                    }) {
                        Text("Try Again")
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(ThemeColors.primary)
                            .cornerRadius(10)
                    }
                    .padding(.horizontal)
                }
                .onAppear {
                    Tracker.processingCompleted(success: false)
                }
            } else if !FeedbackStatus.processingStatuses.contains(viewModel.status.rawValue) {
                // Initial loading state
                VStack(spacing: 16) {
                    Text("Preparing your feedback...")
                        .font(.headline)
                        .foregroundColor(ThemeColors.primary)
                    
                    ProgressView() // Shows a spinner
                    
                    // Show a random tip while waiting
                    Text(muayThaiTips[currentTipIndex])
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
            } else {
                // Normal Processing State
                let currentStep = FeedbackStatus.orderedProcessingStatuses.firstIndex(of: viewModel.status.rawValue) ?? 0
                let totalSteps = FeedbackStatus.orderedProcessingStatuses.count
                
                // Progress indicator with step count
                VStack(spacing: 8) {
                    Text("Step \(currentStep) of \(totalSteps)")
                        .font(.headline)
                        .foregroundColor(ThemeColors.primary)
                    
                    ProgressView(value: Double(currentStep), total: Double(totalSteps))
                        .tint(ThemeColors.primary)
                        .scaleEffect(1.5)
                        .frame(width: 200)
                }
                .onAppear {
                    if currentStep == 0 {  // Only start tracking when processing begins
                        Tracker.processingStarted()
                    }
                }
                .onChange(of: viewModel.status) { newStatus in
                    if newStatus == .completed {
                        Tracker.processingCompleted(success: true)
                    }
                }
                
                // Show the message from FeedbackStatus
                Text(viewModel.status.message)
                    .font(.title3)
                    .fontWeight(.bold)
                    .multilineTextAlignment(.center)
                    .foregroundColor(.primary)
                    .padding()
                    .animation(.easeInOut, value: viewModel.status)
                
                // Display random Muay Thai tips while processing
                if viewModel.status != .completed {
                    Text(muayThaiTips[currentTipIndex])
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                        .onAppear {
                            Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                                withAnimation {
                                    currentTipIndex = (currentTipIndex + 1) % muayThaiTips.count
                                }
                            }
                        }
                }
            }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 10)
        )
        .padding()
    }
    
    private var completedFeedbackView: some View {
        ScrollView {
            VStack(spacing: 24) {
                // User Feedback Prompt (moved to top)
                if !hasSubmittedFeedback {
                    FeedbackPromptButton(action: { showFeedbackPrompt = true })
                        .transition(.move(edge: .top).combined(with: .opacity))
                        .animation(.spring(response: 0.5, dampingFraction: 0.6), value: hasSubmittedFeedback)
                }
                
                if let feedback = viewModel.feedback {
                    HStack {
                        // if let jabScore = feedback.modelFeedback?.body?.jab_score {
                        //     ScoreCardView(jabScore: jabScore)
                        // }
                    }
                    .padding(.horizontal)
                    
                    shareButtons
                    
                    // Video Comparison (existing code)
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
                    
                    // // Feedback Sections
                    // if let feedbackDetails = feedback.modelFeedback?.body?.feedback {
                    //     Group {
                    //         if let extensionFeedback = feedbackDetails.extensionFeedback {
                    //             FeedbackSection(title: "Extension", feedback: extensionFeedback)
                    //         }
                    //         if let guardFeedback = feedbackDetails.guardPosition {
                    //             FeedbackSection(title: "Guard", feedback: guardFeedback)
                    //         }
                    //         if let retractionFeedback = feedbackDetails.retraction {
                    //             FeedbackSection(title: "Retraction", feedback: retractionFeedback)
                    //         }
                    //     }
                    //     .padding(.horizontal)
                    // }
                    
                     // Add Detailed Analysis View
                    if let modelFeedback = feedback.modelFeedback?.body {
                        DetailedAnalysisView(viewModel: viewModel)
                    }
                    
                    // Comparison View (at the bottom)
                    // if let feedbackDetails = feedback.modelFeedback?.body?.feedback,
                    //    let currentScore = feedback.modelFeedback?.body?.jab_score {
                        
                    //     let bestScores = FeedbackManager.shared.getBestScores()
                        
                    //     if bestScores.overall > 0 {  // Only show if there's a previous best
                    //         JabComparisonView(
                    //             currentScore: currentScore,
                    //             currentExtension: feedbackDetails.extensionFeedback?.score ?? 0,
                    //             currentGuard: feedbackDetails.guardPosition?.score ?? 0,
                    //             currentRetraction: feedbackDetails.retraction?.score ?? 0,
                    //             bestScore: bestScores.overall,
                    //             bestExtension: bestScores.extension,
                    //             bestGuard: bestScores.guardPosition,
                    //             bestRetraction: bestScores.retraction
                    //         )
                    //         .padding(.horizontal)
                    //     }
                    // }
                    
                
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
                Analytics.logEvent("feedback_written", parameters: [
                    "feedback_id": feedbackId,
                    "rating": feedbackRating,
                    "has_comment": !userComment.isEmpty
                ])
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
    
    private func trackFeedbackInteraction(section: String) {
        Analytics.logEvent("feedback_interaction", parameters: [
            "section": section,
            "feedback_id": feedbackId
        ])
    }
    
    // 1. Basic Share Button Function
    private func shareVideo() {
        let feedbackUrl = "https://www.form-fighter.com/feedback/\(feedbackId)"
        print("📱 Sharing feedback URL: \(feedbackUrl)")
        
        let activityVC = UIActivityViewController(
            activityItems: [feedbackUrl],
            applicationActivities: nil
        )
        
        // Get the root view controller
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            // Find the top-most presented controller
            var topController = rootViewController
            while let presenter = topController.presentedViewController {
                topController = presenter
            }
            
            // Present from the top-most controller
            topController.present(activityVC, animated: true)
        }
    }
    
    // 2. Process and Share Video Function
    private func processAndShareVideo(for platform: String, isLoading: ReferenceWritableKeyPath<SharingState, Bool>) {
        guard let overlayUrl = viewModel.feedback?.overlay_video_url,
              let url = URL(string: overlayUrl) else {
            sharingState.error = "Video not available"
            return
        }
        
        // Set loading state
        sharingState[keyPath: isLoading] = true
        sharingState.error = nil
        
        // Download and process video
        URLSession.shared.dataTask(with: url) { [self] data, response, error in
            DispatchQueue.main.async {
                sharingState[keyPath: isLoading] = false
                
                if let error = error {
                    sharingState.error = "Failed to download video"
                    print("Error downloading video: \(error)")
                    return
                }
                
                guard let data = data else {
                    sharingState.error = "No video data received"
                    return
                }
                
                do {
                    let processedUrl = try processVideo(data: data)
                    presentShareSheet(with: processedUrl)
                } catch {
                    sharingState.error = "Failed to process video"
                    print("Error processing video: \(error)")
                }
            }
        }.resume()
    }
    
    // 3. Share Buttons View
    private var shareButtons: some View {
        VStack {
            if let error = sharingState.error {
                Text(error)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.bottom, 4)
            }
            
            HStack(spacing: 16) {
                // Share Button
                Button(action: shareVideo) {
                    HStack {
                        Image(systemName: "square.and.arrow.up")
                        Text("Share")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(ThemeColors.primary.opacity(0.1))
                    .foregroundColor(ThemeColors.primary)
                    .cornerRadius(12)
                }
                
                // Save to Camera Roll Button
                Button(action: saveVideoToCameraRoll) {
                    HStack {
                        if sharingState.isLoading {
                            ProgressView()
                                .scaleEffect(0.8)
                        } else {
                            Image(systemName: "square.and.arrow.down")
                        }
                        Text("Save Video")
                            .font(.subheadline)
                    }
                    .padding()
                    .background(ThemeColors.primary.opacity(0.1))
                    .foregroundColor(ThemeColors.primary)
                    .cornerRadius(12)
                }
                .disabled(sharingState.isLoading)
            }
        }
        .padding(.horizontal)
    }
    
    private func saveVideoToCameraRoll() {
        guard let overlayUrl = viewModel.feedback?.overlay_video_url,
              let url = URL(string: overlayUrl) else {
            sharingState.error = "Video not available"
            return
        }
        
        sharingState.isLoading = true
        sharingState.error = nil
        
        print("📱 Starting video download...")
        
        Task {
            do {
                // Download video
                let (data, _) = try await URLSession.shared.data(from: url)
                print("✅ Video downloaded, size: \(data.count) bytes")
                
                // Create temporary URLs
                let tempInputURL = FileManager.default.temporaryDirectory.appendingPathComponent("input.mp4")
                let tempOutputURL = FileManager.default.temporaryDirectory.appendingPathComponent("output.mp4")
                
                // Save downloaded data to temp file
                try data.write(to: tempInputURL)
                
                // Create asset from the saved file
                let asset = AVAsset(url: tempInputURL)
                let composition = AVMutableComposition()
                
                // Create video track
                guard let compositionTrack = composition.addMutableTrack(
                    withMediaType: .video,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                ) else {
                    throw NSError(domain: "VideoProcessing", code: -1, userInfo: ["description": "Could not create video track"])
                }
                
                // Get source video track
                guard let sourceVideoTrack = try await asset.loadTracks(withMediaType: .video).first else {
                    throw NSError(domain: "VideoProcessing", code: -1, userInfo: ["description": "No source video track"])
                }
                
                // Get video duration
                let duration = try await asset.load(.duration)
                let timeRange = CMTimeRange(start: .zero, duration: duration)
                
                // Add video to composition
                try compositionTrack.insertTimeRange(timeRange, of: sourceVideoTrack, at: .zero)
                
                // Add audio if it exists
                if let audioTrack = try? await asset.loadTracks(withMediaType: .audio).first,
                   let compositionAudioTrack = composition.addMutableTrack(
                    withMediaType: .audio,
                    preferredTrackID: kCMPersistentTrackID_Invalid
                   ) {
                    try compositionAudioTrack.insertTimeRange(timeRange, of: audioTrack, at: .zero)
                }
                
                // Get video size
                let videoSize = try await sourceVideoTrack.load(.naturalSize)
                
                // Create video composition
                let videoComposition = AVMutableVideoComposition()
                videoComposition.renderSize = videoSize
                videoComposition.frameDuration = CMTime(value: 1, timescale: 30)
                
                // Create composition instruction
                let instruction = AVMutableVideoCompositionInstruction()
                instruction.timeRange = timeRange
                let layerInstruction = AVMutableVideoCompositionLayerInstruction(assetTrack: compositionTrack)
                instruction.layerInstructions = [layerInstruction]
                videoComposition.instructions = [instruction]
                
                // Set up the parent layer
                let parentLayer = CALayer()
                parentLayer.frame = CGRect(origin: .zero, size: videoSize)
                
                // Set up the video layer
                let videoLayer = CALayer()
                videoLayer.frame = CGRect(origin: .zero, size: videoSize)
                
                // Add logo overlay
                let logoLayer = CALayer()
                logoLayer.contents = UIImage(named: "app-logo-new")?.cgImage
                let logoSize = videoSize.width * 0.15
                logoLayer.frame = CGRect(
                    x: 20,
                    y: videoSize.height - logoSize - 20,
                    width: logoSize,
                    height: logoSize
                )
                logoLayer.opacity = 0.9
                
                // Create feedback card layer
                let cardLayer = CALayer()
                let cardHeight = videoSize.height * 0.15
                let cardWidth = videoSize.width * 0.8
                cardLayer.frame = CGRect(
                    x: (videoSize.width - cardWidth) / 2,
                    y: videoSize.height - cardHeight - 20,
                    width: cardWidth,
                    height: cardHeight
                )
                
                // Create background with rounded corners
                let backgroundLayer = CALayer()
                backgroundLayer.frame = cardLayer.bounds
                backgroundLayer.backgroundColor = CGColor(gray: 0, alpha: 0.7)
                backgroundLayer.cornerRadius = 10
                cardLayer.addSublayer(backgroundLayer)
                
                // Create text layer for score
                let textLayer = CATextLayer()
               // let overallScore: Double = viewModel.feedback?.modelFeedback?.body?.jab_score ?? 0
                
             //   print("💬 Creating text layer with score: \(overallScore)")
                
                // Configure text layer - MAKING IT RED AND BIGGER
             //   textLayer.string = String(format: "Score: %.1f/10", overallScore)
                textLayer.fontSize = cardHeight * 0.6  // Made it bigger!
                textLayer.foregroundColor = CGColor(red: 1, green: 0, blue: 0, alpha: 1)  // BRIGHT RED
                textLayer.alignmentMode = .center
                textLayer.contentsScale = UIScreen.main.scale  // This fixes blurry text!
                textLayer.frame = CGRect(
                    x: 0,
                    y: (cardHeight - (cardHeight * 0.6)) / 2,  // Adjusted for new size
                    width: cardWidth,
                    height: cardHeight * 0.6
                )
                
                print("💬 Text layer frame: \(textLayer.frame)")
                
                // Add layers in correct order
                cardLayer.addSublayer(backgroundLayer)
                cardLayer.addSublayer(textLayer)
                print("💬 Added text layer to card")
                
                parentLayer.addSublayer(videoLayer)
                parentLayer.addSublayer(cardLayer)
                parentLayer.addSublayer(logoLayer)
                
                // Create the animation tool
                videoComposition.animationTool = AVVideoCompositionCoreAnimationTool(
                    postProcessingAsVideoLayer: videoLayer,
                    in: parentLayer
                )
                
                // Create export session
                guard let exportSession = AVAssetExportSession(
                    asset: composition,
                    presetName: AVAssetExportPresetHighestQuality
                ) else {
                    throw NSError(domain: "VideoProcessing", code: -1, userInfo: ["description": "Could not create export session"])
                }
                
                exportSession.outputURL = tempOutputURL
                exportSession.outputFileType = .mp4
                exportSession.videoComposition = videoComposition
                
                // Export the video
                await exportSession.export()
                
                // Check export status
                if exportSession.status == .completed {
                    // Save to camera roll
                    try await PHPhotoLibrary.requestAuthorization(for: .readWrite)
                    try await PHPhotoLibrary.shared().performChanges {
                        PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: tempOutputURL)
                    }
                    
                    await MainActor.run {
                        sharingState.isLoading = false
                        showingSavedAlert = true
                        print("✅ Video saved to camera roll with logo!")
                    }
                } else if let error = exportSession.error {
                    throw error
                }
                
                // Clean up temp files
                try? FileManager.default.removeItem(at: tempInputURL)
                try? FileManager.default.removeItem(at: tempOutputURL)
                
            } catch {
                await MainActor.run {
                    sharingState.isLoading = false
                    sharingState.error = "Failed to process video"
                    print("❌ Processing error: \(error)")
                }
            }
        }
    }
    
    private func processVideoAsset(asset: AVAsset, composition: AVMutableComposition, data: Data) throws {
        // Create video track
        guard let videoTrack = composition.addMutableTrack(
            withMediaType: .video,
            preferredTrackID: kCMPersistentTrackID_Invalid
        ) else {
            throw NSError(domain: "VideoProcessing", code: -1, userInfo: ["description": "Could not create video track"])
        }
        
        // Get source video track
        guard let sourceVideoTrack = try? asset.tracks(withMediaType: .video).first else {
            throw NSError(domain: "VideoProcessing", code: -1, userInfo: ["description": "No source video track"])
        }
        
        // Add video
        try videoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: asset.duration),
            of: sourceVideoTrack,
            at: .zero
        )
        
        // Rest of your video processing code...
    }
    
    private func processVideo(data: Data) throws -> URL {
        // First, save the incoming data to a temporary file
        let tempInputURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)_input.mp4")
        try data.write(to: tempInputURL)
        
        // Create asset from the saved file
        let asset = AVAsset(url: tempInputURL)
        
        // Create composition
        let composition = AVMutableComposition()
        
        // Get video track
        guard let sourceVideoTrack = try? asset.tracks(withMediaType: .video).first,
              let compositionVideoTrack = composition.addMutableTrack(
                withMediaType: .video,
                preferredTrackID: kCMPersistentTrackID_Invalid
              ) else {
            throw NSError(domain: "VideoProcessing", code: -1, userInfo: ["description": "Could not create video track"])
        }
        
        // Insert the video track
        try compositionVideoTrack.insertTimeRange(
            CMTimeRange(start: .zero, duration: asset.duration),
            of: sourceVideoTrack,
            at: .zero
        )
        
        // Add audio if it exists
        if let sourceAudioTrack = try? asset.tracks(withMediaType: .audio).first,
           let compositionAudioTrack = composition.addMutableTrack(
            withMediaType: .audio,
            preferredTrackID: kCMPersistentTrackID_Invalid
           ) {
            try? compositionAudioTrack.insertTimeRange(
                CMTimeRange(start: .zero, duration: asset.duration),
                of: sourceAudioTrack,
                at: .zero
            )
        }
        
        // Create export session
        let exportURL = FileManager.default.temporaryDirectory.appendingPathComponent("\(UUID().uuidString)_output.mp4")
        
        guard let exportSession = AVAssetExportSession(
            asset: composition,
            presetName: AVAssetExportPresetHighestQuality
        ) else {
            throw NSError(domain: "VideoProcessing", code: -1, userInfo: ["description": "Could not create export session"])
        }
        
        exportSession.outputURL = exportURL
        exportSession.outputFileType = .mp4
        
        // Export the video synchronously
        let semaphore = DispatchSemaphore(value: 0)
        exportSession.exportAsynchronously {
            semaphore.signal()
        }
        semaphore.wait()
        
        // Check export status
        guard exportSession.status == .completed else {
            throw NSError(
                domain: "VideoProcessing",
                code: -1,
                userInfo: ["description": "Export failed: \(exportSession.error?.localizedDescription ?? "unknown error")"]
            )
        }
        
        // Clean up input file
        try? FileManager.default.removeItem(at: tempInputURL)
        
        return exportURL
    }
    
    private func presentShareSheet(with videoUrl: URL) {
        let activityVC = UIActivityViewController(
            activityItems: [videoUrl],
            applicationActivities: nil
        )
        
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let rootViewController = windowScene.windows.first?.rootViewController {
            rootViewController.present(activityVC, animated: true)
        }
    }
    
    // Helper view for consistent share buttons
    private struct ShareButton: View {
        let action: () -> Void
        let icon: String
        let label: String
        let isLoading: Bool
        
        var body: some View {
            Button(action: action) {
                VStack {
                    if isLoading {
                        ProgressView()
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: icon)
                    }
                    Text(label)
                        .font(.caption)
                }
                .padding()
                .background(ThemeColors.primary.opacity(0.1))
                .foregroundColor(ThemeColors.primary)
                .cornerRadius(12)
            }
            .disabled(isLoading)
        }
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
            
            // Button(action: {
            //     // Add retry logic here if needed
            // }) {
            //     Text("Try Again")
            //         .font(.headline)
            //         .foregroundColor(.white)
            //         .padding()
            //         .frame(maxWidth: .infinity)
            //         .background(Color.blue)
            //         .cornerRadius(10)
            // }
            // .padding(.horizontal)
        }
        .padding()
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView(feedbackId: "sampleFeedbackId", videoURL: nil)
            .environmentObject(UserManager.shared)
            .environmentObject(FeedbackManager.shared)
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
                Text("Help us make Form Fighter better for you.")
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

// Toast View Component
struct ToastView: View {
    let message: String
    
    var body: some View {
        Text(message)
            .font(.subheadline)
            .foregroundColor(.white)
            .padding(.horizontal, 16)
            .padding(.vertical, 10)
            .background(ThemeColors.primary)
            .cornerRadius(20)
            .shadow(radius: 4)
            .padding(.bottom, 20)
    }
}




