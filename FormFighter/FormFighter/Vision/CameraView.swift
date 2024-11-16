import SwiftUI
import AVFoundation
import Vision
import Photos
import AVKit

struct CameraVisionView: View {
    @State private var detectedBodyPoints: [CGPoint] = []
    @State private var timer1: Int = 0
    @State private var timer2: Int = 0
    @State private var isCounting = false
    @State private var isBodyDetected = false
    @State private var isBodyComplete = false
    @State private var isRecording = false
    @State private var recordingMessage = ""
    @State private var videoURL: URL?
    @State private var navigateToPreview = false
    @State private var hasTurnedBody: Bool = false
    @State private var showInstructions = true
    @State private var countdownPlayer: AVAudioPlayer?
    @State private var startPlayer: AVAudioPlayer?
    
    // Optional timers
    @State private var firstTimer: Timer?
    @State private var secondTimer: Timer?
    
    // Almacena los puntos previos
    @State private var previousBodyPoints: [CGPoint] = []
    @State private var smoothedBodyPoints: [CGPoint] = []
    
    // Add new state variable
    @State private var recordingProgress: Double = 0
    @State private var canDismissInstructions = false
    @State private var buttonOpacity = 0.5
    @State private var isCountingDown: Bool = false
    @State private var currentTurnAngle: Double = 0
    
    var cameraManager: CameraManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera view
                CameraPreviewView(detectedBodyPoints: $detectedBodyPoints,
                                  smoothedBodyPoints: $smoothedBodyPoints,
                                  isBodyDetected: $isBodyDetected,
                                  isBodyComplete: $isBodyComplete,
                                  hasTurnedBody: $hasTurnedBody,
                                  isCountingDown: $isCountingDown,
                                  currentTurnAngle: $currentTurnAngle,
                                  cameraManager: cameraManager
                                  
                )
                .edgesIgnoringSafeArea(.all)
                
                
                // Updated keypoints visualization
                ForEach(smoothedBodyPoints.indices, id: \.self) { index in
                    let point = smoothedBodyPoints[index]
                    Circle()
                        .fill(Color.red)
                        .frame(width: 12, height: 12)
                        .overlay(
                            Circle()
                                .stroke(Color.white, lineWidth: 2)
                        )
                        .position(point)
                }
                .ignoresSafeArea()
                
                
                // Updated analyzing message with progress bar
                if isCounting && timer1 < 3 {
                    VStack {
                        HStack {
                            Image(systemName: "figure.kickboxing")
                                .foregroundColor(.red)
                                .font(.system(size: 40))
                            Text("Get Ready Fighter! Stay in the camera.")
                                .font(.title3.bold())
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(15)
                        
                        ProgressView(value: Double(timer1), total: 3.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .red))
                            .padding(.top, 10)
                            .frame(width: 200)
                    }
                    .padding(.top, 50)
                }
                
                // Updated body detection message
                if !isBodyDetected || !isBodyComplete {
                    VStack {
                        Text("Step your full body into the frame, fighter! 🥊")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red.opacity(0.8))
                            .cornerRadius(15)
                    }
                    .padding(.top, 50)
                }
                
             
                
                // New overlay instructions (shows only first time)
                if showInstructions {
                    VStack(spacing: 20) {
                        Text("How to Record Your Form")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                        
                        VStack(alignment: .leading, spacing: 15) {
                            InstructionRow(number: 1, text: "Record in a well lit indoor room", icon: "light.min")
                            InstructionRow(number: 2, text: "Stand 6-8 feet from camera", icon: "person.and.arrow.left.and.arrow.right")
                            InstructionRow(number: 3, text: "Show your full body in frame", icon: "figure.stand")
                            InstructionRow(number: 4, text: "Turn your body 7 degrees left or right to show your stance", icon: "arrow.triangle.2.circlepath")
                            InstructionRow(number: 5, text: "Hold still for recording", icon: "video.fill")
                            InstructionRow(number: 6, text: "Perform ONE jab in 2 seconds", icon: "figure.boxing")
                        }
                        
                        Button("Got it! 👊") {
                            withAnimation {
                                showInstructions = false
                            }
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .background(canDismissInstructions ? Color.red : Color.gray)
                        .cornerRadius(10)
                        .opacity(buttonOpacity)
                        .scaleEffect(canDismissInstructions ? 1.0 : 0.95)
                        .animation(
                            Animation
                                .easeInOut(duration: 1.0)
                                .repeatForever(autoreverses: true),
                            value: buttonOpacity
                        )
                        .disabled(!canDismissInstructions)
                        .onAppear {
                            // Start button animation
                            withAnimation(
                                Animation
                                    .easeInOut(duration: 1.0)
                                    .repeatForever(autoreverses: true)
                            ) {
                                buttonOpacity = 1.0
                            }
                            
                            // Enable button after delay
                            DispatchQueue.main.asyncAfter(deadline: .now() + 4) {
                                withAnimation {
                                    canDismissInstructions = true
                                    buttonOpacity = 1.0
                                }
                            }
                        }
                    }
                    .padding()
                    .background(Color.black.opacity(0.85))
                    .cornerRadius(20)
                    .padding()
                }
                
                // Visual Guide Overlay when body not detected
                if !isBodyDetected || !isBodyComplete {
                    Rectangle()
                        .stroke(style: StrokeStyle(lineWidth: 3, dash: [10]))
                        .foregroundColor(.red.opacity(0.6))
                        .padding(40)
                        .overlay(
                            Image(systemName: "figure.boxing")
                                .font(.system(size: 100))
                                .foregroundColor(.black.opacity(0.3))
                        )
                }
                
                // Updated countdown with visual feedback
                if timer2 > 0 && timer2 <= 4 && !isRecording {
                    VStack {
                        Text("\(4 - timer2)")
                            .font(.system(size: 120, weight: .heavy))
                            .foregroundColor(.red)
                            .shadow(color: .black, radius: 2, x: 0, y: 0)
                            .transition(.scale)
                            .animation(.easeInOut, value: timer2)
                        
                        Text("Get Ready!")
                            .font(.title2.bold())
                            .foregroundColor(.white)
                            .shadow(color: .black, radius: 2)
                    }
                }
                
                // Updated recording message overlay
                if isRecording {
                    VStack(spacing: 15) {
                        Image(systemName: "record.circle")
                            .foregroundColor(.red)
                            .font(.system(size: 50))
                        Text(recordingMessage)
                            .font(.headline.bold())
                            .foregroundColor(.white)
                        
                        // Timer bar
                        ProgressView(value: recordingProgress, total: 1.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .red))
                            .frame(width: 200)
                            .animation(.linear(duration: 2.0), value: recordingProgress)
                    }
                    .padding()
                    .background(Color.black.opacity(0.7))
                    .cornerRadius(15)
                    .padding(.top, 100)
                }
                
                // Add to CameraVisionView body, after the existing overlays
                if isBodyDetected && isBodyComplete && !hasTurnedBody {
                    VStack {
                        HStack(spacing: 15) {
                            Image(systemName: "arrow.triangle.2.circlepath")
                                .foregroundColor(.white)
                                .font(.system(size: 30))
                            
                            Text("Turn \(currentTurnAngle, specifier: "%.0f")° / 7°")
                                .font(.title2.bold())
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.7))
                        .cornerRadius(15)
                        
                        // Progress arc
                        ZStack {
                            Circle()
                                .stroke(Color.white.opacity(0.3), lineWidth: 10)
                                .frame(width: 100, height: 100)
                            
                            Circle()
                                .trim(from: 0, to: min(CGFloat(currentTurnAngle) / 7.0, 1.0))
                                .stroke(Color.green, style: StrokeStyle(lineWidth: 10, lineCap: .round))
                                .frame(width: 100, height: 100)
                                .rotationEffect(.degrees(-90))
                                .animation(.linear, value: currentTurnAngle)
                        }
                    }
                    .padding(.top, 50)
                }
            }
            .navigationDestination(isPresented: $navigateToPreview) {
                if let videoURL = videoURL {
                    ResultsView(videoURL: videoURL)
                        .environmentObject(UserManager.shared)
                        .onAppear {
                            // Stop camera when navigating to results
                            cameraManager.stopSession()
                        }
                }
            }
        }
        .navigationBarHidden(true)
        .navigationBarBackButtonHidden(true)
        .onAppear {
            NotificationCenter.default.addObserver(forName: NSNotification.Name("VideoRecorded"), object: nil, queue: .main) { notification in
                if let url = notification.object as? URL {
                    self.videoURL = url
                    self.navigateToPreview = true
                }
            }
            setupAudioPlayers()
        }
        .onChange(of: isBodyDetected) { _ in
            checkBodyAndStartTimers()
        }
        .onChange(of: isBodyComplete) { _ in
            checkBodyAndStartTimers()
        }
        .onChange(of: hasTurnedBody) { _ in
            checkBodyAndStartTimers()
        }
        .ignoresSafeArea()
    }
    
    // Función que actualiza y suaviza los puntos detectados
    func updateDetectedBodyPoints(newPoints: [CGPoint]) {
        guard newPoints.count == detectedBodyPoints.count else {
            smoothedBodyPoints = newPoints
            previousBodyPoints = newPoints
            return
        }
        
        // Suaviza cada punto con interpolación
        smoothedBodyPoints = zip(previousBodyPoints, newPoints).map { previous, current in
            CGPoint(x: previous.x * 0.7 + current.x * 0.3, y: previous.y * 0.7 + current.y * 0.3)
        }
        
        // Actualiza los puntos previos
        previousBodyPoints = newPoints
    }
    
    func checkBodyAndStartTimers() {
        print("isBodyDetected: \(isBodyDetected), isBodyComplete: \(isBodyComplete), hasTurnedBody: \(hasTurnedBody)")
        if isBodyDetected && isBodyComplete && hasTurnedBody {
            startFirstTimer()
        } else {
            resetTimers()
        }
    }
    
    // Start the first timer
    func startFirstTimer() {
        guard firstTimer == nil else { return }
        
        isCounting = true
        timer1 = 0
        timer2 = 0
        recordingMessage = ""
        
        firstTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timer1 < 3 {
                timer1 += 1
            } else {
                firstTimer?.invalidate()
                firstTimer = nil
                timer2 = 1  // Start at 1 to show "3"
                startSecondTimer()
            }
            
            if !isBodyDetected {
                resetTimers()
            }
        }
    }
    
    // Start the second timer
    func startSecondTimer() {
        guard secondTimer == nil else { return }
        
        timer2 = 1  // Start at 1 to show "3"
        isCountingDown = true  // Set flag when countdown starts
        
        secondTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timer2 < 4 {
                timer2 += 1
                if timer2 < 4 {
                    countdownPlayer?.play()
                } else {
                    startPlayer?.play()
                    simulateRecording()
                }
            } else {
                secondTimer?.invalidate()
                secondTimer = nil
            }
        }
    }
    
    // Simulate recording
    func simulateRecording() {
        isRecording = true
        recordingMessage = "Recording..."
        recordingProgress = 0.0  // Start empty
        
        cameraManager.startRecording()
        
        // Create a timer that updates progress every 0.1 seconds
        let progressTimer = Timer.scheduledTimer(withTimeInterval: 0.1, repeats: true) { timer in
            withAnimation {
                recordingProgress += 0.05  // Increment by 5% each time (20 steps over 2 seconds)
            }
            
            // Stop the timer when we reach full
            if recordingProgress >= 1.0 {
                timer.invalidate()
                recordingMessage = "Recording finished"
                cameraManager.stopRecording()
                resetTimers()
            }
        }
    }
    
    // Reset all timers and states
    func resetTimers() {
        firstTimer?.invalidate()
        firstTimer = nil
        secondTimer?.invalidate()
        secondTimer = nil
        
        isCounting = false
        isRecording = false
        timer1 = 0
        timer2 = 0
        recordingMessage = ""
        hasTurnedBody = false  // Restablecer aquí
        isCountingDown = false  // Reset flag when timers are reset
        
        if isRecording {
            cameraManager.stopRecording()
        }
    }
    
    // Add these new helper views and functions
    private struct InstructionRow: View {
        let number: Int
        let text: String
        let icon: String
        
        var body: some View {
            HStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundColor(.red)
                    .frame(width: 40)
                Text("\(number). \(text)")
                    .foregroundColor(.white)
            }
        }
    }
    
    private func setupAudioPlayers() {
        // Setup countdown sound
        if let countdownURL = Bundle.main.url(forResource: "countdown", withExtension: "wav") {
            countdownPlayer = try? AVAudioPlayer(contentsOf: countdownURL)
            countdownPlayer?.prepareToPlay()
        }
        
        // Setup start sound
        if let startURL = Bundle.main.url(forResource: "start", withExtension: "wav") {
            startPlayer = try? AVAudioPlayer(contentsOf: startURL)
            startPlayer?.prepareToPlay()
        }
    }
}

struct CameraPreviewView: UIViewControllerRepresentable {
    @Binding var detectedBodyPoints: [CGPoint]
    @Binding var smoothedBodyPoints: [CGPoint]
    @Binding var isBodyDetected: Bool
    @Binding var isBodyComplete: Bool
    @Binding var hasTurnedBody: Bool
    @Binding var isCountingDown: Bool
    @Binding var currentTurnAngle: Double
    
    var cameraManager: CameraManager
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraPreviewView
        var hasTurnedBodyCompleted = false
        let confidenceThreshold: VNConfidence = 0.00001  // Even lower threshold for better detection
        
        init(parent: CameraPreviewView) {
            self.parent = parent
            super.init()
        }
        
        let requiredPoints: [VNHumanBodyPoseObservation.JointName] = [
            .nose,
            .leftWrist,
            .rightWrist,
            .leftAnkle,
            .rightAnkle
        ]
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard parent.cameraManager.isActive else { return }
            if parent.isCountingDown { return }
            
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let request = VNDetectHumanBodyPoseRequest { [self] request, error in
                guard let results = request.results as? [VNHumanBodyPoseObservation], error == nil else { return }
                
                var newBodyPoints: [CGPoint] = []
                var bodyDetected = false
                var bodyComplete = true
                
                for bodyObservation in results {
                    if let recognizedPoints = try? bodyObservation.recognizedPoints(.all) {
                        bodyDetected = !recognizedPoints.isEmpty
                        
                        // First check all required points are present
                        for pointName in requiredPoints {
                            if let point = recognizedPoints[pointName],
                               point.confidence > confidenceThreshold {
                                let normalizedPoint = point.location
                                let convertedPoint = convertVisionPoint(normalizedPoint, to: parent.cameraManager.previewLayer)
                                newBodyPoints.append(convertedPoint)
                            } else {
                                bodyComplete = false
                                break
                            }
                        }
                        
                        // Then check shoulders for turn if body is complete
                        if bodyComplete,
                           let leftShoulder = recognizedPoints[.leftShoulder],
                           let rightShoulder = recognizedPoints[.rightShoulder],
                           leftShoulder.confidence > confidenceThreshold,
                           rightShoulder.confidence > confidenceThreshold {
                            
                            let shoulderAngle = calculateAngleBetweenPoints(
                                left: leftShoulder.location,
                                right: rightShoulder.location
                            )
                            let adjustedAngle = abs(shoulderAngle - 90)
                            
                            if adjustedAngle >= 3 && adjustedAngle <= 10 {
                                DispatchQueue.main.async {
                                    self.parent.hasTurnedBody = true
                                }
                            }
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.parent.detectedBodyPoints = newBodyPoints
                    self.parent.isBodyDetected = bodyDetected
                    self.parent.isBodyComplete = bodyComplete
                }
            }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
        }
        
        func calculateAngleBetweenPoints(left: CGPoint, right: CGPoint) -> CGFloat {
            let deltaY = left.y - right.y
            let deltaX = left.x - right.x
            let radians = atan2(deltaY, deltaX)
            let degrees = radians * 180 / .pi
            return degrees
        }
        
        func convertVisionPoint(_ point: CGPoint, to layer: AVCaptureVideoPreviewLayer?) -> CGPoint {
            guard let layer = layer else { return .zero }
            let convertedPoint = layer.layerPointConverted(fromCaptureDevicePoint: point)
            let reflectedX = layer.bounds.width - convertedPoint.x
            return CGPoint(x: reflectedX, y: convertedPoint.y)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        return Coordinator(parent: self)
    }
    
    func makeUIViewController(context: Context) -> UIViewController {
        let viewController = UIViewController()
        cameraManager.setupCamera(in: viewController.view, delegate: context.coordinator)
        return viewController
    }
    
    func updateUIViewController(_ uiViewController: UIViewController, context: Context) {}
    
    func applySmoothing(to points: [CGPoint]) -> [CGPoint] {
        guard !points.isEmpty else { return points }
        
        // If this is the first set of points, initialize smoothed points
        if smoothedBodyPoints.isEmpty {
            return points
        }
        
        // Stronger smoothing factor (increased from 0.7)
        let smoothingFactor: CGFloat = 0.85
        
        return zip(smoothedBodyPoints, points).map { previous, current in
            // Only apply smoothing if points are within a reasonable distance
            let distance = hypot(current.x - previous.x, current.y - previous.y)
            
            // If movement is very small, keep previous point to reduce jitter
            if distance < 3.0 {
                return previous
            }
            
            // If movement is large, reduce smoothing to allow faster response
            let dynamicSmoothingFactor = distance > 20.0 ? 0.5 : smoothingFactor
            
            return CGPoint(
                x: previous.x * dynamicSmoothingFactor + current.x * (1 - dynamicSmoothingFactor),
                y: previous.y * dynamicSmoothingFactor + current.y * (1 - dynamicSmoothingFactor)
            )
        }
    }
}


class CameraManager: NSObject, ObservableObject {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var movieOutput = AVCaptureMovieFileOutput()
    @Published var isActive = false  // Changed to false by default
    
    func stopSession() {
        captureSession?.stopRunning()
        isActive = false
    }
    
    func startSession() {
        guard !isActive else { return }
        DispatchQueue.global(qos: .background).async { [weak self] in
            self?.captureSession?.startRunning()
            DispatchQueue.main.async {
                self?.isActive = true
            }
        }
    }
    
    func setupCamera(in view: UIView, delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        // Camera input configuration
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("Rear camera not found")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("Could not add camera input.")
                return
            }
        } catch {
            print("Error adding camera input: \(error)")
            return
        }
        
        // Configure and add video output
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "cameraQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("Could not add videoOutput to session.")
            return
        }
        
        // Configure and add output for video recording
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        } else {
            print("Could not add movieOutput to session.")
            return
        }
        
        // Configure preview layer
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer!)
        
        // Start capture session
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
            DispatchQueue.main.async {
                print("Capture session active: \(captureSession.isRunning)")
            }
        }
        
        self.captureSession = captureSession
    }
    
    // Start recording
    func startRecording() {
        // Ensure that the capture session is running
        guard let captureSession = captureSession, captureSession.isRunning else {
            print("Capture session is not active.")
            return
        }
        
        // Verify if movieOutput has active connections just before recording
        if movieOutput.connections.isEmpty {
            print("There are no active connections for recording output.")
            return
        }
        
        // If there are active connections, start recording
        let fileName = "output_\(UUID().uuidString).mov"
        let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        // Check if the file already exists and delete it
        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
                print("Existing file deleted.")
            } catch {
                print("Error deleting existing file: \(error)")
            }
        }
        
        
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        print("Recording started, saving to: \(outputURL.absoluteString)")
    }
    
    // Stop recording
    func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        }
    }
}

// Extension to handle recording and save video to photo library
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            Logger.log(message: "Recording error: \(error.localizedDescription)", event: .error)
            Logger.recordError(error, context: ["recording_url": outputFileURL.absoluteString])
        } else {
            if FileManager.default.fileExists(atPath: outputFileURL.path) {
                Logger.log(message: "Video recording completed successfully", event: .debug)
                // Post notification with the URL
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("VideoRecorded"), object: outputFileURL)
                }
            } else {
                Logger.log(message: "Video file not created correctly", event: .error)
            }
        }
    }
}
