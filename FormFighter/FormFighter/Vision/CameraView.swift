//import SwiftUI
//import AVFoundation
//import Vision
//import AVKit
//
//
//
//class RecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
//    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
//        if let error = error {
//            print("Recording error: \(error.localizedDescription)")
//        } else {
//            print("Video successfully recorded at: \(outputFileURL)")
//        }
//    }
//}
//
//
//struct CameraPreviewTestView: View {
//    @State private var captureSession: AVCaptureSession?
//    @State private var previewLayer: AVCaptureVideoPreviewLayer?
//    @State private var keypointsDetected = false // Track if body is in frame
//    @State private var bodyInFrame = false // Track if entire body is in frame
//    @State private var recognizedPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint] = [:]
//    @State private var detectedKeypoints: Int = 0
//    @State private var keypointsList: [VNHumanBodyPoseObservation.JointName] = [
//        .nose, .leftAnkle, .rightAnkle, .leftHip, .rightHip, .leftShoulder, .rightShoulder, .leftWrist, .rightWrist
//    ]
//
//    var body: some View {
//        ZStack {
//            if let previewLayer = previewLayer {
//                CameraPreview(captureSession: $captureSession, previewLayer: $previewLayer)
//                    .aspectRatio(contentMode: .fit)
//                    .frame(height: UIScreen.main.bounds.height * 0.8)
//                    .edgesIgnoringSafeArea(.all)
//                
//                if !bodyInFrame {
//                    // Prompt user to adjust to get body in frame
//                    Text("Please make sure your entire body is visible in the frame.")
//                        .foregroundColor(.white)
//                        .background(Color.red.opacity(0.7))
//                        .cornerRadius(10)
//                        .padding()
//                        .zIndex(1)
//                    
//                    // Show detected keypoints on top of the preview
//                                   VStack {
//                                       Spacer()
//                                       Text("Detected \(detectedKeypoints) out of \(keypointsList.count) keypoints.")
//                                           .foregroundColor(.white)
//                                           .padding()
//                                           .background(Color.black.opacity(0.6))
//                                           .cornerRadius(8)
//                                   }
//                                   .padding(.bottom, 50)
//                }
//            } else {
//                Text("Setting up camera...")
//            }
//        }
//        .onAppear {
//            setupCamera()
//            addObservers()
//            
//            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
//                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
//                        detectKeypoints()
//                        
//                       // print("Starting Pose Detection!!!!!!")
//                        //testPoseDetectionWithImage()
//                    }
//                }
//        }
//        .onChange(of: keypointsDetected, perform: { _ in
//            if keypointsDetected {
//                // If keypoints detected, check if body is in the frame
//                checkBodyInFrame()
//            }
//        })
//    }
//    
//    
//  
//    
//    // Setup Camera Function (same as before)
//       func setupCamera() {
//           if captureSession == nil {
//               captureSession = AVCaptureSession()
//               guard let captureSession = captureSession else { return }
//
//               captureSession.beginConfiguration()
//               captureSession.sessionPreset = .photo
//
//               if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
//                   do {
//                       let videoInput = try AVCaptureDeviceInput(device: videoDevice)
//                       if captureSession.canAddInput(videoInput) {
//                           captureSession.addInput(videoInput)
//                           print("Added input")
//                       }
//                   } catch {
//                       print("Error: Cannot initialize video input: \(error.localizedDescription)")
//                       return
//                   }
//               }
//
//               previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
//               previewLayer?.videoGravity = .resizeAspect // Keep aspect ratio
//               previewLayer?.frame = UIScreen.main.bounds
//               print("Preview layer set up.")
//               print("Preview Layer frame size: \(previewLayer?.bounds.size)")
//
//               captureSession.commitConfiguration()
//
//               DispatchQueue.global(qos: .userInitiated).async {
//                   captureSession.startRunning()
//                   print("Capture session started.")
//               }
//           }
//       }
//
//    
//    // Add observers for session start/stop
//    func addObservers() {
//        NotificationCenter.default.addObserver(forName: NSNotification.Name("StartCaptureSession"), object: nil, queue: .main) { _ in
//            DispatchQueue.global(qos: .userInitiated).async {
//                self.captureSession?.startRunning()
//                print("Capture session resumed.")
//            }
//        }
//
//        NotificationCenter.default.addObserver(forName: NSNotification.Name("StopCaptureSession"), object: nil, queue: .main) { _ in
//            DispatchQueue.global(qos: .userInitiated).async {
//                self.captureSession?.stopRunning()
//                print("Capture session paused.")
//            }
//        }
//    }
//    
//    // Detect keypoints using Vision framework
//       func detectKeypoints() {
//           guard let previewLayer = previewLayer else {
//               print("Preview layer is not ready.")
//               return
//           }
//
//           if previewLayer.bounds.isEmpty {
//               print("Preview layer bounds are empty.")
//               return
//           }
//
//           print("Preview Layer frame size: \(previewLayer.bounds.size)")
//
//           let request = VNDetectHumanBodyPoseRequest { request, error in
//               if let error = error {
//                   print("Error in pose detection request: \(error.localizedDescription)")
//                   return
//               }
//
//               if let results = request.results as? [VNHumanBodyPoseObservation] {
//                   print("Received \(results.count) pose observations.")
//                   for observation in results {
//                       processKeypoints(observation: observation)
//                   }
//               } else {
//                   print("No pose observations detected.")
//               }
//           }
//
//           if let capturedImage = capturePreviewImageFromLayer(previewLayer: previewLayer) {
//               let handler = VNImageRequestHandler(cgImage: capturedImage, orientation: .upMirrored, options: [:])
//
//               do {
//                   try handler.perform([request])
//               } catch {
//                   print("Error performing Vision request: \(error.localizedDescription)")
//               }
//           } else {
//               print("Error: Failed to capture image from the preview layer.")
//           }
//       }
//
//    
//    // Capture a frame for Vision processing
//       func capturePreviewImageFromLayer(previewLayer: AVCaptureVideoPreviewLayer) -> CGImage? {
//           guard !previewLayer.bounds.isEmpty else {
//               print("Error: Preview layer bounds are empty.")
//               return nil
//           }
//
//           let layerBounds = previewLayer.bounds
//
//           // Calculate scaling to maintain aspect ratio
//           let scaleFactor: CGFloat = max(layerBounds.width / 960.0, layerBounds.height / 2079.0)
//           let scaledWidth = 960.0 * scaleFactor
//           let scaledHeight = 2079.0 * scaleFactor
//
//           // Adjust the image render size accordingly
//           let renderer = UIGraphicsImageRenderer(size: CGSize(width: scaledWidth, height: scaledHeight))
//           let resizedImage = renderer.image { context in
//               previewLayer.render(in: context.cgContext)
//           }
//
//           if let cgImage = resizedImage.cgImage {
//               print("Captured resized image successfully. Size: \(cgImage.width)x\(cgImage.height)")
//               return cgImage
//           } else {
//               print("Error: Failed to capture CGImage from preview layer.")
//               return nil
//           }
//       }
//
//
//
//    // Process the detected keypoints (same as before)
//       func processKeypoints(observation: VNHumanBodyPoseObservation) {
//           let points = try? observation.recognizedPoints(.all)
//           guard let points = points else {
//               print("No points recognized.")
//               return
//           }
//
//           print("Processing keypoints...")
//
//           detectedKeypoints = keypointsList.reduce(0) { count, jointName in
//               if let point = points[jointName], point.confidence > 0.2 {
//                   return count + 1
//               } else {
//                   return count
//               }
//           }
//
//           print("Detected \(detectedKeypoints) out of \(keypointsList.count) keypoints.")
//       }
//    
//    
//    
//
//    func checkBodyInFrame() {
//        guard let previewLayer = previewLayer else { return }
//        
//        print("Preview Layer frame size Check Body in Frame: \(previewLayer.bounds.size)")
//
//        
//        // Use the stored `recognizedPoints` which now uses `VNHumanBodyPoseObservation.JointName`
//        if let leftAnkle = recognizedPoints[.leftAnkle], let rightAnkle = recognizedPoints[.rightAnkle] {
//            let frameSize = previewLayer.bounds.size
//
//            // Convert the normalized point (0 to 1 range) to the actual coordinates in the camera frame
//            let leftAnklePosition = CGPoint(x: leftAnkle.location.x * frameSize.width,
//                                            y: (1 - leftAnkle.location.y) * frameSize.height) // y is inverted
//            let rightAnklePosition = CGPoint(x: rightAnkle.location.x * frameSize.width,
//                                             y: (1 - rightAnkle.location.y) * frameSize.height)
//            
//            // Check if the keypoints are within the preview bounds
//            if previewLayer.bounds.contains(leftAnklePosition) && previewLayer.bounds.contains(rightAnklePosition) {
//                bodyInFrame = true
//                countdown() // Call countdown when entire body is in frame
//            } else {
//                bodyInFrame = false
//            }
//        }
//    }
//    
//    
//    
//    func testPoseDetectionWithImage() {
//        if let image = UIImage(named: "testImage.jpg")?.cgImage {
//            let handler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
//            let request = VNDetectHumanBodyPoseRequest { request, error in
//                if let error = error {
//                    print("Error in pose detection request: \(error.localizedDescription)")
//                    return
//                }
//                
//                if let results = request.results as? [VNHumanBodyPoseObservation] {
//                    do{
//                        print("Received \(results.count) pose observations.")
//                        
//                        print("Received: \(try results[0].recognizedPoints(.face))")
//                    }
//                    catch{
//                        print(error)
//                    }
//                } else {
//                    print("No pose observations detected.")
//                }
//            }
//            try? handler.perform([request])
//        }
//    }
//    
//
//
//    
//    // Placeholder countdown function
//    func countdown() {
//        print("Countdown starting...") // Implement countdown logic here
//    }
//}
//
//
//struct CameraPreview: UIViewRepresentable {
//    @Binding var captureSession: AVCaptureSession?
//    @Binding var previewLayer: AVCaptureVideoPreviewLayer?
//
//    func makeUIView(context: Context) -> UIView {
//        let view = UIView()
//
//        DispatchQueue.main.async {
//            if let previewLayer = previewLayer {
//                print("Preview Layer frame size MakeUIView: \(previewLayer.bounds.size)")
//
//                previewLayer.frame = UIScreen.main.bounds  // Make sure the frame is set to the view's bounds
//                view.layer.addSublayer(previewLayer)
//            }
//        }
//
//        return view
//    }
//
//    func updateUIView(_ uiView: UIView, context: Context) {
//        DispatchQueue.main.async {
//            if let previewLayer = previewLayer {
//                print("Preview Layer frame size UpdateUIVIEW: \(previewLayer.bounds.size)")
//
//                previewLayer.frame = UIScreen.main.bounds // Update the frame whenever the view is updated
//            }
//        }
//    }
//}
//

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
    @State private var isFacingCamera: Bool = true
    
    // Optional timers
    @State private var firstTimer: Timer?
    @State private var secondTimer: Timer?
    
    // Almacena los puntos previos
    @State private var previousBodyPoints: [CGPoint] = []
    @State private var smoothedBodyPoints: [CGPoint] = []
    
    var cameraManager: CameraManager
    
    var body: some View {
        NavigationStack {
            ZStack {
                // Camera view
                CameraPreviewView(detectedBodyPoints: $detectedBodyPoints,
                                  smoothedBodyPoints: $smoothedBodyPoints,
                                  isBodyDetected: $isBodyDetected,
                                  isBodyComplete: $isBodyComplete,
                                  isFacingCamera: $isFacingCamera,
                                  cameraManager: cameraManager)
                .edgesIgnoringSafeArea(.all)
                
                
                // Show key points
                ForEach(smoothedBodyPoints.indices, id: \.self) { index in
                    let point = smoothedBodyPoints[index]
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .position(point)
                }
                .ignoresSafeArea()
                
                
                // Show progress and icon while analyzing
                if isCounting && timer1 < 3 {
                    VStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .font(.largeTitle)
                            Text("Analyzing, keep the object in focus")
                                .font(.headline)
                                .foregroundColor(.white)
                        }
                        .padding()
                        .background(Color.black.opacity(0.6))
                        .cornerRadius(10)
                        
                        ProgressView(value: Double(timer1), total: 3.0)
                            .progressViewStyle(LinearProgressViewStyle(tint: .white))
                            .padding(.top, 10)
                            .frame(width: 200)
                    }
                    .padding(.top, 50)
                }
                
                // Show message if the body is not fully detected
                if !isBodyDetected || !isBodyComplete {
                    VStack {
                        Text("Please ensure your full body is in the frame.")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                    }
                    .padding(.top, 50)
                }
                
                if !isFacingCamera && isBodyDetected && isBodyComplete {
                    VStack {
                        Text("Please face the camera directly.")
                            .font(.headline)
                            .foregroundColor(.red)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                    }
                    .padding(.top, 50)
                }
                
                // Show countdown
                if timer2 > 0 && timer2 <= 4 && !isRecording {
                    Text("\(4 - timer2)")
                        .font(.system(size: 100))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                        .transition(.scale)
                        .animation(.easeInOut, value: timer2)
                }
                
                // Show recording message
                if isRecording {
                    VStack {
                        Image(systemName: "video.fill")
                            .foregroundColor(.red)
                            .font(.largeTitle)
                        Text(recordingMessage)
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.black.opacity(0.6))
                            .cornerRadius(10)
                    }
                    .padding(.top, 100)
                }
            }
            .navigationDestination(isPresented: $navigateToPreview) {
                if let videoURL = videoURL {
                    ResultsView(videoURL: videoURL)
                }
            }
        }
        .onAppear {
            NotificationCenter.default.addObserver(forName: NSNotification.Name("VideoRecorded"), object: nil, queue: .main) { notification in
                if let url = notification.object as? URL {
                    self.videoURL = url
                    self.navigateToPreview = true
                }
            }
        }
        .onChange(of: isBodyDetected) { _ in
            checkBodyAndStartTimers()
        }
        .onChange(of: isBodyComplete) { _ in
            checkBodyAndStartTimers()
        }
        .onChange(of: isFacingCamera) { _ in
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
        print("isBodyDetected: \(isBodyDetected), isBodyComplete: \(isBodyComplete), isFacingCamera: \(isFacingCamera)")
        if isBodyDetected && isBodyComplete && isFacingCamera {
            startFirstTimer()
        } else {
            resetTimers()
        }
    }
    
    // Start the first timer
    func startFirstTimer() {
        guard firstTimer == nil else { return } // Avoid multiple timers
        
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
                startSecondTimer()
            }
            
            if !isBodyDetected {
                resetTimers()
            }
        }
    }
    
    // Start the second timer
    func startSecondTimer() {
        guard secondTimer == nil else { return } // Avoid multiple timers
        
        timer2 = 0
        
        secondTimer = Timer.scheduledTimer(withTimeInterval: 1, repeats: true) { timer in
            if timer2 < 4 {
                timer2 += 1
            } else {
                secondTimer?.invalidate()
                secondTimer = nil
                simulateRecording()
            }
            
            if !isBodyDetected {
                resetTimers()
            }
        }
    }
    
    // Simulate recording
    func simulateRecording() {
        isRecording = true
        recordingMessage = "Recording..."
        
        cameraManager.startRecording()
        
        Timer.scheduledTimer(withTimeInterval: 2, repeats: false) { timer in
            recordingMessage = "Recording finished"
            cameraManager.stopRecording()
            resetTimers()
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
        
        if isRecording {
            cameraManager.stopRecording()
        }
    }
}

struct CameraPreviewView: UIViewControllerRepresentable {
    @Binding var detectedBodyPoints: [CGPoint]
    @Binding var smoothedBodyPoints: [CGPoint]
    @Binding var isBodyDetected: Bool
    @Binding var isBodyComplete: Bool
    @Binding var isFacingCamera: Bool
    
    var cameraManager: CameraManager
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraPreviewView
        
        // Umbral de confianza ajustable
        let confidenceThreshold: VNConfidence = 0.005
        
        init(parent: CameraPreviewView) {
            self.parent = parent
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            let request = VNDetectHumanBodyPoseRequest { request, error in
                guard let results = request.results as? [VNHumanBodyPoseObservation], error == nil else {
                    DispatchQueue.main.async {
                        self.parent.isBodyDetected = false
                        self.parent.isBodyComplete = false
                        self.parent.isFacingCamera = false
                    }
                    return
                }
                
                var newBodyPoints: [CGPoint] = []
                var bodyDetected = false
                var bodyComplete = true
                var facingCamera = false // Variable local para determinar si está de frente
                
                let requiredPoints: [VNHumanBodyPoseObservation.JointName] = [.nose, .leftAnkle, .rightAnkle, .leftWrist, .rightWrist]
                
                for bodyObservation in results {
                    if let recognizedPoints = try? bodyObservation.recognizedPoints(.all) {
                        if !recognizedPoints.isEmpty {
                            bodyDetected = true
                        }
                        
                        // Detección del ángulo entre los hombros
                        if let leftShoulder = recognizedPoints[.leftShoulder],
                           let rightShoulder = recognizedPoints[.rightShoulder],
                           leftShoulder.confidence > self.confidenceThreshold,
                           rightShoulder.confidence > self.confidenceThreshold {
                            
                            let shoulderAngle = self.calculateAngleBetweenPoints(left: leftShoulder.location, right: rightShoulder.location)
                            let adjustedAngle = abs(shoulderAngle - 90)
//                            print("Shoulder Angle: \(shoulderAngle) degrees")
//                            print("Adjusted Shoulder Angle: \(adjustedAngle) degrees")
                            
                            facingCamera = adjustedAngle <= 10
                        } else {
                            facingCamera = false
                        }
                        
                        // Verificar si todos los puntos requeridos están presentes
                        for pointName in requiredPoints {
                            if let point = recognizedPoints[pointName], point.confidence > self.confidenceThreshold {
                                let normalizedPoint = point.location
                                let convertedPoint = self.convertVisionPoint(normalizedPoint, to: self.parent.cameraManager.previewLayer)
                                newBodyPoints.append(convertedPoint)
                            } else {
                                bodyComplete = false
                            }
                        }
                    }
                }
                
                // Actualización de estados en el hilo principal
                DispatchQueue.main.async {
                    self.parent.detectedBodyPoints = newBodyPoints
                    self.parent.isBodyDetected = bodyDetected
                    self.parent.isBodyComplete = bodyComplete
                    self.parent.isFacingCamera = facingCamera
                    
                    // Llama a la función de suavizado
                    self.parent.smoothedBodyPoints = self.parent.applySmoothing(to: newBodyPoints)
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
        guard points.count == smoothedBodyPoints.count else {
            return points
        }
        return zip(smoothedBodyPoints, points).map { previous, current in
            CGPoint(x: previous.x * 0.7 + current.x * 0.3, y: previous.y * 0.7 + current.y * 0.3)
        }
    }
}

class CameraManager: NSObject, ObservableObject {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var movieOutput = AVCaptureMovieFileOutput() // Output for video recording
    
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
        } else {
            print("No recording in progress to stop.")
        }
    }
}

// Extension to handle recording and save video to photo library
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error in recording: \(error.localizedDescription)")
        } else {
            // Verify if the file was created correctly
            if FileManager.default.fileExists(atPath: outputFileURL.path) {
                print("The file exists, ready to be saved.")
                
                // Send a notification with the recorded video's URL
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("VideoRecorded"), object: outputFileURL)
                }
                
                // Request permission to access the photo library
                //                PHPhotoLibrary.requestAuthorization { status in
                //                    if status == .authorized || status == .limited {
                //                        // Save the video to the photo library
                //                        PHPhotoLibrary.shared().performChanges({
                //                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
                //                        }) { success, error in
                //                            if success {
                //                                print("Video saved to photo library.")
                //                            } else if let error = error {
                //                                print("Error saving video: \(error.localizedDescription)")
                //                            }
                //                        }
                //                    } else {
                //                        print("Permission to access the photo library denied.")
                //                    }
                //                }
            } else {
                print("The video file does not exist or was not created correctly.")
            }
        }
    }
}
