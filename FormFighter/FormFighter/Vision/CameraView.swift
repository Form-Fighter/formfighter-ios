import SwiftUI
import AVFoundation
import AVKit

struct CameraVisionView: View {
    // MARK: - Recording States
    @State private var isCountingDown: Bool = false
    @State private var countdownValue: Int = 10
    @State private var isRecording = false
    @State private var recordingMessage = ""
    @State private var recordingProgress: Double = 0

    // We capture the recorded video URL from the manager here.
    @State private var recordedVideoURL: URL?
    @State private var navigateToPreview = false

    // Timers for countdown and recording progress.
    @State private var countdownTimer: Timer?
    @State private var recordingTimer: Timer?

    // MARK: - Audio Players
    @State private var countdownPlayer: AVAudioPlayer?
    @State private var startPlayer: AVAudioPlayer?
    @State private var jabInstructionPlayer: AVAudioPlayer?
    
    @ObservedObject var cameraManager: CameraManager

    @EnvironmentObject var userManager: UserManager
    @AppStorage("hasSeenInstructions") private var hasSeenInstructions = false
    @State private var currentInstructionStep = 1
    @State private var showInstructionsOverlay = false

    // Track app state (foreground/background)
    @Environment(\.scenePhase) var scenePhase

    var body: some View {
        ZStack {
            // Camera preview
            CameraPreviewView(cameraManager: cameraManager)
                .ignoresSafeArea(edges: [.horizontal, .top])
                .onAppear {
                    print("DEBUG: CameraPreviewView appeared.")
                }

            VStack {
                HStack {
                    Spacer()
                    Text("Remaining Tokens: \(userManager.user?.tokens ?? 0)")
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding(8)
                        .background(Color.black.opacity(0.5))
                        .cornerRadius(8)
                    Spacer()
                }
                .padding(.top, 20)
                Spacer()
            }
            
            // Info button at top right
            VStack {
                HStack {
                    Spacer()
                    Button {
                        currentInstructionStep = 1
                        showInstructionsOverlay = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.title2)
                            .foregroundColor(.white)
                    }
                    .padding()
                }
                .padding(.top, 50)
                Spacer()
            }
            
            // Instructions overlay
            if !hasSeenInstructions || showInstructionsOverlay {
                InstructionsOverlay(
                    currentStep: $currentInstructionStep,
                    isShowing: $showInstructionsOverlay,
                    hasSeenInstructions: $hasSeenInstructions
                )
            }
            
            // Countdown overlay while waiting to record
            if isCountingDown {
                Text("\(countdownValue)")
                    .font(.system(size: 100, weight: .heavy))
                    .foregroundColor(.red)
                    .shadow(color: .black, radius: 2)
                    .transition(.scale)
                    .onAppear {
                        print("DEBUG: Countdown overlay shown with value \(countdownValue).")
                    }
            }
            
            // Recording overlay
            if isRecording {
                VStack(spacing: 15) {
                    Image(systemName: "record.circle")
                        .foregroundColor(.red)
                        .font(.system(size: 50))
                    Text(recordingMessage)
                        .font(.headline.bold())
                        .foregroundColor(.white)
                    ProgressView(value: recordingProgress, total: 1.0)
                        .progressViewStyle(LinearProgressViewStyle(tint: .red))
                        .frame(width: 200)
                        .animation(.linear(duration: 2.0), value: recordingProgress)
                }
                .padding()
                .background(Color.black.opacity(0.7))
                .cornerRadius(15)
                .padding(.top, 100)
                .onAppear {
                    print("DEBUG: Recording overlay shown. Message: \(recordingMessage), progress: \(recordingProgress)")
                }
            }
            
            // Start recording button (only when no recording/countdown/instructions)
            if !isRecording && !isCountingDown && !showInstructionsOverlay && hasSeenInstructions {
                Button(action: {
                    print("DEBUG: Start Recording button tapped.")
                    startManualRecording()
                }) {
                    Text("Start Recording")
                        .font(.title)
                        .foregroundColor(.white)
                        .padding()
                        .background(Color.green)
                        .cornerRadius(12)
                }
                .position(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
            }
        }
        // Present ResultsView as a sheet only if there’s a valid video URL.
        .sheet(isPresented: Binding<Bool>(
            get: { navigateToPreview && cameraManager.recordedVideoURL != nil },
            set: { newValue in
                if !newValue { navigateToPreview = false }
            }
        )) {
            // Force unwrap is safe here because we only show when URL is non-nil.
            ResultsView(videoURL: cameraManager.recordedVideoURL!)
                .environmentObject(UserManager.shared)
                .onAppear {
                    let url = cameraManager.recordedVideoURL!
                    print("DEBUG: ResultsView appearing with URL: \(url)")
                    print("DEBUG: File exists at URL: \(FileManager.default.fileExists(atPath: url.path))")
                    cameraManager.stopSession()
                }
                .onDisappear {
                    print("DEBUG: ResultsView disappeared, resetting state")
                    resetRecordingState()
                }
        }
        .ignoresSafeArea(edges: [.top, .leading, .trailing])
        .onAppear {
            print("DEBUG: CameraVisionView onAppear.")
            setupAudioPlayers()
            if !cameraManager.isActive {
                print("DEBUG: Starting camera session.")
                cameraManager.startSession()
            }
        }
        .onDisappear {
            print("DEBUG: CameraVisionView onDisappear.")
            cancelTimers() // Cancel any running timers and reset state.
            cameraManager.stopSession()
            resetRecordingState()
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        // Listen for changes to recordedVideoURL.
        .onReceive(cameraManager.$recordedVideoURL) { url in
            if let url = url, FileManager.default.fileExists(atPath: url.path) {
                recordedVideoURL = url
                navigateToPreview = true
                print("DEBUG: onReceive - valid recordedVideoURL: \(url)")
            } else {
                print("DEBUG: onReceive - recordedVideoURL is nil or file not found")
            }
        }
        // Handle background/foreground changes.
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .background {
                print("DEBUG: App moved to background. Cancelling any pending timers and recording.")
                cancelTimers()
                if isRecording {
                    cameraManager.stopRecording()
                    resetRecordingState()
                }
                if cameraManager.recordedVideoURL == nil {
                    navigateToPreview = false
                }
            } else if newPhase == .active {
                print("DEBUG: App moved to active.")
                if !cameraManager.isActive {
                    cameraManager.startSession()
                }
            }
        }
    }
    
    // MARK: - Audio Setup
    func setupAudioPlayers() {
        if let countdownURL = Bundle.main.url(forResource: "countdown", withExtension: "wav") {
            countdownPlayer = try? AVAudioPlayer(contentsOf: countdownURL)
            countdownPlayer?.prepareToPlay()
            print("DEBUG: Countdown sound player setup.")
        } else {
            print("DEBUG: Countdown sound file not found!")
        }
        if let startURL = Bundle.main.url(forResource: "start", withExtension: "wav") {
            startPlayer = try? AVAudioPlayer(contentsOf: startURL)
            startPlayer?.prepareToPlay()
            print("DEBUG: Start sound player setup.")
        } else {
            print("DEBUG: Start sound file not found!")
        }
        if let jabInstructionURL = Bundle.main.url(forResource: "JabStraightAhead", withExtension: "wav") {
            jabInstructionPlayer = try? AVAudioPlayer(contentsOf: jabInstructionURL)
            jabInstructionPlayer?.prepareToPlay()
            print("DEBUG: Jab instruction sound player setup.")
        } else {
            print("DEBUG: Jab instruction sound file not found!")
        }
    }
    
    // MARK: - Recording Logic
    func startManualRecording() {
        print("DEBUG: startManualRecording() called.")
        countdownValue = 10
        isCountingDown = true
        
        // Store the countdown timer.
        countdownTimer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
            print("DEBUG: Countdown timer tick. Current value: \(self.countdownValue)")
            if self.countdownValue > 1 {
                self.countdownValue -= 1
                self.countdownPlayer?.play()
            } else {
                timer.invalidate()
                self.countdownTimer = nil
                self.isCountingDown = false
                self.startPlayer?.play()
                print("DEBUG: Countdown finished. Initiating simulateRecording().")
                simulateRecording()
            }
        }
    }
    
    func simulateRecording() {
        print("DEBUG: simulateRecording() called.")
        isRecording = true
        recordingMessage = "Recording..."
        recordingProgress = 0.0

        jabInstructionPlayer?.play()
        cameraManager.startRecording()
        print("DEBUG: CameraManager.startRecording() called.")

        // Store the recording timer.
        recordingTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            withAnimation {
                self.recordingProgress += 0.05
            }
            print("DEBUG: Recording progress: \(self.recordingProgress)")
            if self.recordingProgress >= 1.0 {
                timer.invalidate()
                self.recordingTimer = nil
                self.recordingMessage = "Recording finished"
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    print("DEBUG: Stopping recording")
                    self.cameraManager.stopRecording()
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        print("DEBUG: Setting navigateToPreview")
                        if let url = self.cameraManager.recordedVideoURL,
                           FileManager.default.fileExists(atPath: url.path) {
                            self.navigateToPreview = true
                        }
                    }
                }
                self.isRecording = false
            }
        }
    }
    
    /// Cancel any active timers and reset UI state.
    func cancelTimers() {
        countdownTimer?.invalidate()
        countdownTimer = nil
        recordingTimer?.invalidate()
        recordingTimer = nil
        
        // Reset countdown UI state.
        isCountingDown = false
        countdownValue = 10
        recordingProgress = 0.0
    }
    
    func resetRecordingState() {
        print("DEBUG: resetRecordingState() called. Resetting all recording state.")
        isRecording = false
        isCountingDown = false
        countdownValue = 10
        recordingProgress = 0.0
        recordingMessage = ""
        recordedVideoURL = nil
        navigateToPreview = false
        
        // Cancel any running timers.
        cancelTimers()
        
        // Stop recording if in progress.
        if cameraManager.movieOutput.isRecording {
            cameraManager.stopRecording()
        }
        
        // Restart the camera session.
        cameraManager.stopSession()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("DEBUG: Restarting camera session after reset")
            self.cameraManager.startSession()
        }
        
        print("DEBUG: Recording state has been cleared.")
    }
}

struct CameraPreviewView: UIViewControllerRepresentable {
    var cameraManager: CameraManager
    
    func makeUIViewController(context: Context) -> UIViewController {
        print("DEBUG: makeUIViewController called for CameraPreviewView.")
        let viewController = UIViewController()
        cameraManager.setupCamera(in: viewController.view, delegate: context.coordinator)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) { }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        func captureOutput(_ output: AVCaptureOutput,
                           didOutput sampleBuffer: CMSampleBuffer,
                           from connection: AVCaptureConnection) {
            // No processing needed.
        }
    }
}

// Create a separate InstructionsOverlay view.
struct InstructionsOverlay: View {
    @Binding var currentStep: Int
    @Binding var isShowing: Bool
    @Binding var hasSeenInstructions: Bool
    
    let instructions = [
        Instruction(number: 1, text: "Turn on audio on 🔊", icon: "speaker.wave.2.fill"),
        Instruction(number: 2, text: "Only one person in camera", icon: "person.fill"),
        Instruction(number: 3, text: "Record in a well lit room", icon: "light.min"),
        Instruction(number: 4, text: "Stand 6-8 feet from camera", icon: "person.and.arrow.left.and.arrow.right"),
        Instruction(number: 5, text: "Show your full body in frame", icon: "figure.stand"),
        Instruction(number: 6, text: "Turn your body 7 degrees stance", icon: "arrow.triangle.2.circlepath"),
        Instruction(number: 7, text: "Hold still for recording", icon: "video.fill"),
        Instruction(number: 8, text: "Perform ONE jab", icon: "figure.boxing")
    ]
    
    var body: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Spacer().frame(height: 100)
                
                // Header with close button.
                HStack {
                    Text("How to Record Your Form")
                        .font(.title2.bold())
                        .foregroundColor(.white)
                    
                    Spacer()
                    
                    Button {
                        withAnimation {
                            isShowing = false
                            hasSeenInstructions = true
                        }
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.white)
                            .font(.title2)
                    }
                }
                .padding(.horizontal)
                
                Spacer()
                
                // Current instruction.
                if let instruction = instructions[safe: currentStep - 1] {
                    VStack(spacing: 30) {
                        Image(systemName: instruction.icon)
                            .font(.system(size: 60))
                            .foregroundColor(.red)
                        
                        Text(instruction.text)
                            .font(.title3)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                    .transition(.opacity)
                }
                
                Spacer()
                
                // Progress indicators.
                HStack(spacing: 8) {
                    ForEach(1...instructions.count, id: \.self) { step in
                        Circle()
                            .fill(step == currentStep ? Color.red : Color.gray)
                            .frame(width: 8, height: 8)
                    }
                }
                
                // Navigation buttons.
                HStack(spacing: 20) {
                    Button("Skip") {
                        withAnimation {
                            isShowing = false
                            hasSeenInstructions = true
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.gray.opacity(0.5))
                    .cornerRadius(10)
                    
                    Button(currentStep == instructions.count ? "Done" : "Next") {
                        withAnimation {
                            if currentStep == instructions.count {
                                isShowing = false
                                hasSeenInstructions = true
                            } else {
                                currentStep += 1
                            }
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                }
            }
            .padding()
            .transition(.opacity)
        }
    }
}

// Instruction model.
struct Instruction {
    let number: Int
    let text: String
    let icon: String
}

// Safe array subscript extension.
extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
