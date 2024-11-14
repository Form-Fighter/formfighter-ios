import SwiftUI
import Firebase
import FirebaseFirestore
import SceneKit
import QuickLook
import AVKit

// Create a dedicated type for feedback status
enum FeedbackStatus: String {
    case pending = "pending"
    case uploading = "uploading"
    case processing = "processing"
    case analyzing = "analyzing"
    case completed = "completed"
    
    var message: String {
        switch self {
        case .pending: return "Preparing your video..."
        case .uploading: return "Uploading your form..."
        case .processing: return "AI is analyzing your technique..."
        case .analyzing: return "Breaking down your movements..."
        case .completed: return "Analysis complete!"
        }
    }
}

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
    
    // Add these state variables
    @State private var isLoadingModel = false
    @State private var sceneModel: SCNScene?
    @State private var modelURL: URL?
    
    var body: some View {
        Group {
            if let feedback = viewModel.feedback {
                completedFeedbackView
            } else if let error = viewModel.error {
                UnexpectedErrorView(error: error)
            } else if videoURL != nil {
                uploadingView
            } else {
                ProgressView()
            }
        }
        .onAppear {
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
                onSubmit: submitUserFeedback
            )
        }
    }
    
    private var completedFeedbackView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let feedback = viewModel.feedback {
                    ScoreCardView(jabScore: feedback.modelFeedback.body.jab_score)
                    
                    // 3D Model Viewer
                    if !feedback.animation_usdz_url.isEmpty,
                       let usdzUrl = URL(string: feedback.animation_usdz_url) {
                        VStack {
                            if isLoadingModel {
                                ProgressView("Loading 3D Model...")
                                    .frame(height: 300)
                            } else if let scene = sceneModel {
                                SceneView(
                                    scene: scene,
                                    options: [
                                        .allowsCameraControl,
                                        .autoenablesDefaultLighting,
                                        .temporalAntialiasingEnabled
                                    ]
                                )
                                .frame(height: 300)
                                .cornerRadius(12)
                                .onAppear {
                                    // Find and play all animations
                                    scene.rootNode.enumerateChildNodes { (node, _) in
                                        // Get all animation keys
                                        for key in node.animationKeys {
                                            if let animation = node.animation(forKey: key) {
                                                // Remove existing animation
                                                node.removeAnimation(forKey: key)
                                                
                                                // Create a new animation that loops
                                                let loopingAnimation = animation.copy() as! CAAnimation
                                                loopingAnimation.repeatCount = .infinity
                                                loopingAnimation.isRemovedOnCompletion = false
                                                
                                                // Add the looping animation
                                                node.addAnimation(loopingAnimation, forKey: "loop")
                                            }
                                        }
                                    }
                                    
                                    // Ensure scene is playing
                                    scene.isPaused = false
                                }
                            } else {
                                Text("Failed to load 3D model")
                                    .frame(height: 300)
                            }
                            
                            // AR Quick Look Button
                            if let modelURL = modelURL {
                                Button(action: {
                                    let quickLook = QLPreviewController()
                                    let coordinator = makeCoordinator()
                                    quickLook.delegate = coordinator
                                    let dataSource = ARQuickLookDataSource(url: modelURL)
                                    quickLook.dataSource = dataSource
                                    
                                    if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                       let rootVC = windowScene.windows.first?.rootViewController {
                                        DispatchQueue.main.async {
                                            rootVC.present(quickLook, animated: true)
                                        }
                                    }
                                }) {
                                    Label("View in AR", systemImage: "arkit")
                                        .padding()
                                        .background(Color.blue)
                                        .foregroundColor(.white)
                                        .cornerRadius(8)
                                }
                                .disabled(isLoadingModel)
                            }
                        }
                        .onAppear {
                            loadUSDZModel(from: usdzUrl)
                        }
                    }
                    
                    // Video Comparison
                    if !feedback.videoUrl.isEmpty,
                       !feedback.overlay_video_url.isEmpty,
                       let originalURL = URL(string: feedback.videoUrl),
                       let overlayURL = URL(string: feedback.overlay_video_url) {
                        
                        HStack {
                            if let player1 = originalPlayer {
                                VideoPlayer(player: player1)
                                    .frame(height: 200)
                                    .cornerRadius(12)
                            }
                            
                            if let player2 = overlayPlayer {
                                VideoPlayer(player: player2)
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
                    FeedbackSection(title: "Extension", feedback: feedback.modelFeedback.body.feedback.extensionFeedback)
                    FeedbackSection(title: "Guard", feedback: feedback.modelFeedback.body.feedback.guardPosition)
                    FeedbackSection(title: "Retraction", feedback: feedback.modelFeedback.body.feedback.retraction)
                    
                    if !hasSubmittedFeedback {
                        FeedbackPromptButton(action: { showFeedbackPrompt = true })
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
        guard let emoji = selectedEmoji,
              userComment.count >= 15 else { return }
        
        viewModel.submitUserFeedback(
            feedbackId: feedbackId,
            emoji: emoji,
            comment: userComment
        ) { success in
            if success {
                hasSubmittedFeedback = true
                showFeedbackPrompt = false
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
    
    private func loadUSDZModel(from url: URL) {
        isLoadingModel = true
        modelURL = url
        
        // First download the file to local storage
        let documentsDirectory = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let localURL = documentsDirectory.appendingPathComponent("model.usdz")
        
        URLSession.shared.downloadTask(with: url) { tempURL, response, error in
            guard let tempURL = tempURL, error == nil else {
                DispatchQueue.main.async {
                    self.isLoadingModel = false
                    print("Download error: \(error?.localizedDescription ?? "unknown error")")
                }
                return
            }
            
            do {
                // Remove any existing file
                try? FileManager.default.removeItem(at: localURL)
                // Move downloaded file to documents
                try FileManager.default.moveItem(at: tempURL, to: localURL)
                
                // Load the scene from local file
                DispatchQueue.global(qos: .userInitiated).async {
                    if let scene = try? SCNScene(url: localURL, options: [
                        .checkConsistency: true,
                        .convertToYUp: true,
                        .flattenScene: true,
                        .preserveOriginalTopology: true,
                        .createNormalsIfAbsent: true
                    ]) {
                        DispatchQueue.main.async {
                            self.modelURL = localURL
                            self.sceneModel = scene
                            self.isLoadingModel = false
                        }
                    } else {
                        DispatchQueue.main.async {
                            self.isLoadingModel = false
                            print("Failed to load scene from local file")
                        }
                    }
                }
            } catch {
                DispatchQueue.main.async {
                    self.isLoadingModel = false
                    print("File handling error: \(error.localizedDescription)")
                }
            }
        }.resume()
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
    let onSubmit: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("How was your feedback?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Emoji Selection
                HStack(spacing: 30) {
                    ForEach(UserFeedbackType.allCases, id: \.self) { emoji in
                        Button(action: { selectedEmoji = emoji }) {
                            Text(emoji.rawValue)
                                .font(.system(size: 40))
                                .opacity(selectedEmoji == emoji ? 1.0 : 0.5)
                                .scaleEffect(selectedEmoji == emoji ? 1.2 : 1.0)
                        }
                    }
                }
                .padding()
                
                // Comment TextField
                TextField("Tell us what you think (minimum 15 characters)", text: $userComment, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4...6)
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationBarItems(
                leading: Button("Cancel") {
                    // You'll need to add a dismiss binding or use @Environment
                },
                trailing: Button("Submit") {
                    onSubmit()
                }
                .disabled(userComment.count < 15 || selectedEmoji == nil)
            )
        }
    }
}

struct FeedbackPromptButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "message")
                Text("How was this feedback?")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
    }
}

// Add this class to handle AR Quick Look
class ARQuickLookDataSource: NSObject, QLPreviewControllerDataSource {
    let url: URL
    
    init(url: URL) {
        self.url = url
        super.init()
    }
    
    func numberOfPreviewItems(in controller: QLPreviewController) -> Int {
        return 1
    }
    
    func previewController(_ controller: QLPreviewController, previewItemAt index: Int) -> QLPreviewItem {
        return url as QLPreviewItem
    }
}

class Coordinator: NSObject, QLPreviewControllerDelegate {
    var parent: FeedbackView
    
    init(_ parent: FeedbackView) {
        self.parent = parent
    }
    
    func previewControllerDidDismiss(_ controller: QLPreviewController) {
        // Handle dismissal if needed
    }
}

extension FeedbackView {
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
}
