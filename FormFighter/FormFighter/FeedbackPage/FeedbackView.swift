import SwiftUI
import Firebase
import FirebaseFirestore
import SceneKit
import QuickLook
import AVKit
import ModelIO


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
    @State private var isLoadingModel = false
    @State private var sceneModel: SCNScene?
    @State private var modelURL: URL?
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
    
    @State private var animationController: AnimationController?
    
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
                    
                    // 3D Model Viewer
                    if let usdzUrl = feedback.animation_usdz_url,
                       !usdzUrl.isEmpty,
                       let url = URL(string: usdzUrl) {
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
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(ThemeColors.primary, lineWidth: 2)
                                )
                                   .onAppear {
                                    if let url = modelURL {
                                        print("\n=== Loading Animation Using ModelIO ===")
                                        print("Model URL: \(url)")
                                        
                                        // Create asset and print initial info
                                        let asset = MDLAsset(url: url)
                                        print("\nAsset Details:")
                                        print("- Total objects: \(asset.count)")
                                        
                                        // Debug each object in the asset
                                        for index in 0..<asset.count {
                                            if let object = asset.object(at: index) as? MDLObject {
                                                print("\nObject \(index):")
                                                print("- Type: \(type(of: object))")
                                                print("- Name: \(object.name ?? "unnamed")")
                                                
                                                // Check for mesh sequence data
                                                if let mesh = object as? MDLMesh {
                                                    print("- Mesh Details:")
                                                    print("  - Vertex count: \(mesh.vertexCount)")
                                                    print("  - Submesh count: \(mesh.submeshes?.count ?? 0)")
                                                    
                                                    // Look for morph targets/blend shapes
//                                                    if let morphGeometry = mesh.geometry as? MDLMorphGeometry {
//                                                        print("  - Found morph targets!")
//                                                        print("  - Target count: \(morphGeometry.targetCount)")
//                                                    }
                                                }
                                            }
                                        }
                                        
                                        // Try to load as SCNScene for additional info
                                        do {
                                            let scene = try SCNScene(url: url, options: nil)
                                            print("\nScene Graph (looking for mesh sequences):")
                                            debugPrintSCNNode(scene.rootNode, level: 0)
                                            
                                            // Look for morph targets in SceneKit
                                            if let mesh = scene.rootNode.childNode(withName: "Mesh", recursively: true)?.geometry as? SCNGeometry {
                                                print("\nMesh Morpher Info:")
                                              //  print("- Has morpher: \(mesh.morpher != nil)")
//                                                if let morpher = mesh.morpher {
//                                                    print("- Target count: \(morpher.targets.count)")
//                                                    print("- Target names: \(morpher.targets.map { $0.name ?? "unnamed" })")
//                                                }
                                            }
                                        } catch {
                                            print("\nFailed to load as SCNScene: \(error)")
                                        }
                                        
                                        let sceneView = SCNView()
                                        let controller = AnimationController(sceneView: sceneView)
                                        controller.setupScene(with: url)
                                        
                                        // Store controller reference if needed
                                        self.animationController = controller
                                    }
                                }
                            } else {
                                Text("Failed to load 3D model")
                                    .frame(height: 300)
                            }
                            
                            // AR Quick Look Button
                            if let modelURL = modelURL {
                                HStack(spacing: 16) {
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
                                        Label("AR", systemImage: "arkit")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(ThemeColors.primary)
                                            .cornerRadius(12)
                                            .lineLimit(1)
                                    }
                                    
                                    Button(action: {
                                        let url = "https://www.form-fighter.com/feedback/\(feedbackId)"
                                        let activityVC = UIActivityViewController(
                                            activityItems: [url],
                                            applicationActivities: nil
                                        )
                                        
                                        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                                           let rootVC = windowScene.windows.first?.rootViewController {
                                            activityVC.popoverPresentationController?.sourceView = rootVC.view
                                            rootVC.present(activityVC, animated: true)
                                        }
                                    }) {
                                        Label("Share", systemImage: "square.and.arrow.up")
                                            .font(.headline)
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding()
                                            .background(ThemeColors.primary)
                                            .cornerRadius(12)
                                    }
                                }
                                .padding(.horizontal)
                                .disabled(isLoadingModel)
                            }
                        }
                        .onAppear {
                            loadUSDZModel(from: url)
                        }
                    }
                    
                    // Video Comparison
                    if let videoUrl = feedback.videoUrl,
                       let overlayUrl = feedback.overlay_video_url,
                       !videoUrl.isEmpty,
                       !overlayUrl.isEmpty,
                       let originalURL = URL(string: videoUrl),
                       let overlayURL = URL(string: overlayUrl) {
                        
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

// Helper function to print MDL object hierarchy
private func debugPrintMDLObject(_ object: MDLObject, level: Int) {
    let indent = String(repeating: "  ", count: level)
    print("\(indent)- \(type(of: object)): \(object.name ?? "unnamed")")
    
    if let objectContainer = object as? MDLObjectContainer {
        for child in objectContainer.objects {
            debugPrintMDLObject(child, level: level + 1)
        }
    }
}

// Helper function to print SCN node hierarchy
private func debugPrintSCNNode(_ node: SCNNode, level: Int) {
    let indent = String(repeating: "  ", count: level)
    print("\(indent)- \(node.name ?? "unnamed")")
    node.childNodes.forEach { child in
        debugPrintSCNNode(child, level: level + 1)
    }
}


