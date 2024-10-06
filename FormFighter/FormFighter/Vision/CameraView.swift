import SwiftUI
import AVFoundation
import Vision
import AVKit



class RecordingDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Recording error: \(error.localizedDescription)")
        } else {
            print("Video successfully recorded at: \(outputFileURL)")
        }
    }
}


struct CameraPreviewTestView: View {
    @State private var captureSession: AVCaptureSession?
    @State private var previewLayer: AVCaptureVideoPreviewLayer?
    @State private var keypointsDetected = false // Track if body is in frame
    @State private var bodyInFrame = false // Track if entire body is in frame
    @State private var recognizedPoints: [VNHumanBodyPoseObservation.JointName: VNRecognizedPoint] = [:]
    @State private var detectedKeypoints: Int = 0
    @State private var keypointsList: [VNHumanBodyPoseObservation.JointName] = [
        .nose, .leftAnkle, .rightAnkle, .leftHip, .rightHip, .leftShoulder, .rightShoulder, .leftWrist, .rightWrist
    ]

    var body: some View {
        ZStack {
            if let previewLayer = previewLayer {
                CameraPreview(captureSession: $captureSession, previewLayer: $previewLayer)
                    .aspectRatio(contentMode: .fit)
                    .frame(height: UIScreen.main.bounds.height * 0.8)
                    .edgesIgnoringSafeArea(.all)
                
                if !bodyInFrame {
                    // Prompt user to adjust to get body in frame
                    Text("Please make sure your entire body is visible in the frame.")
                        .foregroundColor(.white)
                        .background(Color.red.opacity(0.7))
                        .cornerRadius(10)
                        .padding()
                        .zIndex(1)
                    
                    // Show detected keypoints on top of the preview
                                   VStack {
                                       Spacer()
                                       Text("Detected \(detectedKeypoints) out of \(keypointsList.count) keypoints.")
                                           .foregroundColor(.white)
                                           .padding()
                                           .background(Color.black.opacity(0.6))
                                           .cornerRadius(8)
                                   }
                                   .padding(.bottom, 50)
                }
            } else {
                Text("Setting up camera...")
            }
        }
        .onAppear {
            setupCamera()
            addObservers()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                    Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                        detectKeypoints()
                        
                       // print("Starting Pose Detection!!!!!!")
                        //testPoseDetectionWithImage()
                    }
                }
        }
        .onChange(of: keypointsDetected, perform: { _ in
            if keypointsDetected {
                // If keypoints detected, check if body is in the frame
                checkBodyInFrame()
            }
        })
    }
    
    
  
    
    // Setup Camera Function (same as before)
       func setupCamera() {
           if captureSession == nil {
               captureSession = AVCaptureSession()
               guard let captureSession = captureSession else { return }

               captureSession.beginConfiguration()
               captureSession.sessionPreset = .photo

               if let videoDevice = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) {
                   do {
                       let videoInput = try AVCaptureDeviceInput(device: videoDevice)
                       if captureSession.canAddInput(videoInput) {
                           captureSession.addInput(videoInput)
                           print("Added input")
                       }
                   } catch {
                       print("Error: Cannot initialize video input: \(error.localizedDescription)")
                       return
                   }
               }

               previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
               previewLayer?.videoGravity = .resizeAspect // Keep aspect ratio
               previewLayer?.frame = UIScreen.main.bounds
               print("Preview layer set up.")
               print("Preview Layer frame size: \(previewLayer?.bounds.size)")

               captureSession.commitConfiguration()

               DispatchQueue.global(qos: .userInitiated).async {
                   captureSession.startRunning()
                   print("Capture session started.")
               }
           }
       }

    
    // Add observers for session start/stop
    func addObservers() {
        NotificationCenter.default.addObserver(forName: NSNotification.Name("StartCaptureSession"), object: nil, queue: .main) { _ in
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.startRunning()
                print("Capture session resumed.")
            }
        }

        NotificationCenter.default.addObserver(forName: NSNotification.Name("StopCaptureSession"), object: nil, queue: .main) { _ in
            DispatchQueue.global(qos: .userInitiated).async {
                self.captureSession?.stopRunning()
                print("Capture session paused.")
            }
        }
    }
    
    // Detect keypoints using Vision framework
       func detectKeypoints() {
           guard let previewLayer = previewLayer else {
               print("Preview layer is not ready.")
               return
           }

           if previewLayer.bounds.isEmpty {
               print("Preview layer bounds are empty.")
               return
           }

           print("Preview Layer frame size: \(previewLayer.bounds.size)")

           let request = VNDetectHumanBodyPoseRequest { request, error in
               if let error = error {
                   print("Error in pose detection request: \(error.localizedDescription)")
                   return
               }

               if let results = request.results as? [VNHumanBodyPoseObservation] {
                   print("Received \(results.count) pose observations.")
                   for observation in results {
                       processKeypoints(observation: observation)
                   }
               } else {
                   print("No pose observations detected.")
               }
           }

           if let capturedImage = capturePreviewImageFromLayer(previewLayer: previewLayer) {
               let handler = VNImageRequestHandler(cgImage: capturedImage, orientation: .upMirrored, options: [:])

               do {
                   try handler.perform([request])
               } catch {
                   print("Error performing Vision request: \(error.localizedDescription)")
               }
           } else {
               print("Error: Failed to capture image from the preview layer.")
           }
       }

    
    // Capture a frame for Vision processing
       func capturePreviewImageFromLayer(previewLayer: AVCaptureVideoPreviewLayer) -> CGImage? {
           guard !previewLayer.bounds.isEmpty else {
               print("Error: Preview layer bounds are empty.")
               return nil
           }

           let layerBounds = previewLayer.bounds

           // Calculate scaling to maintain aspect ratio
           let scaleFactor: CGFloat = max(layerBounds.width / 960.0, layerBounds.height / 2079.0)
           let scaledWidth = 960.0 * scaleFactor
           let scaledHeight = 2079.0 * scaleFactor

           // Adjust the image render size accordingly
           let renderer = UIGraphicsImageRenderer(size: CGSize(width: scaledWidth, height: scaledHeight))
           let resizedImage = renderer.image { context in
               previewLayer.render(in: context.cgContext)
           }

           if let cgImage = resizedImage.cgImage {
               print("Captured resized image successfully. Size: \(cgImage.width)x\(cgImage.height)")
               return cgImage
           } else {
               print("Error: Failed to capture CGImage from preview layer.")
               return nil
           }
       }



    // Process the detected keypoints (same as before)
       func processKeypoints(observation: VNHumanBodyPoseObservation) {
           let points = try? observation.recognizedPoints(.all)
           guard let points = points else {
               print("No points recognized.")
               return
           }

           print("Processing keypoints...")

           detectedKeypoints = keypointsList.reduce(0) { count, jointName in
               if let point = points[jointName], point.confidence > 0.2 {
                   return count + 1
               } else {
                   return count
               }
           }

           print("Detected \(detectedKeypoints) out of \(keypointsList.count) keypoints.")
       }
    
    
    

    func checkBodyInFrame() {
        guard let previewLayer = previewLayer else { return }
        
        print("Preview Layer frame size Check Body in Frame: \(previewLayer.bounds.size)")

        
        // Use the stored `recognizedPoints` which now uses `VNHumanBodyPoseObservation.JointName`
        if let leftAnkle = recognizedPoints[.leftAnkle], let rightAnkle = recognizedPoints[.rightAnkle] {
            let frameSize = previewLayer.bounds.size

            // Convert the normalized point (0 to 1 range) to the actual coordinates in the camera frame
            let leftAnklePosition = CGPoint(x: leftAnkle.location.x * frameSize.width,
                                            y: (1 - leftAnkle.location.y) * frameSize.height) // y is inverted
            let rightAnklePosition = CGPoint(x: rightAnkle.location.x * frameSize.width,
                                             y: (1 - rightAnkle.location.y) * frameSize.height)
            
            // Check if the keypoints are within the preview bounds
            if previewLayer.bounds.contains(leftAnklePosition) && previewLayer.bounds.contains(rightAnklePosition) {
                bodyInFrame = true
                countdown() // Call countdown when entire body is in frame
            } else {
                bodyInFrame = false
            }
        }
    }
    
    
    
    func testPoseDetectionWithImage() {
        if let image = UIImage(named: "testImage.jpg")?.cgImage {
            let handler = VNImageRequestHandler(cgImage: image, orientation: .up, options: [:])
            let request = VNDetectHumanBodyPoseRequest { request, error in
                if let error = error {
                    print("Error in pose detection request: \(error.localizedDescription)")
                    return
                }
                
                if let results = request.results as? [VNHumanBodyPoseObservation] {
                    do{
                        print("Received \(results.count) pose observations.")
                        
                        print("Received: \(try results[0].recognizedPoints(.face))")
                    }
                    catch{
                        print(error)
                    }
                } else {
                    print("No pose observations detected.")
                }
            }
            try? handler.perform([request])
        }
    }
    


    
    // Placeholder countdown function
    func countdown() {
        print("Countdown starting...") // Implement countdown logic here
    }
}


struct CameraPreview: UIViewRepresentable {
    @Binding var captureSession: AVCaptureSession?
    @Binding var previewLayer: AVCaptureVideoPreviewLayer?

    func makeUIView(context: Context) -> UIView {
        let view = UIView()

        DispatchQueue.main.async {
            if let previewLayer = previewLayer {
                print("Preview Layer frame size MakeUIView: \(previewLayer.bounds.size)")

                previewLayer.frame = UIScreen.main.bounds  // Make sure the frame is set to the view's bounds
                view.layer.addSublayer(previewLayer)
            }
        }

        return view
    }

    func updateUIView(_ uiView: UIView, context: Context) {
        DispatchQueue.main.async {
            if let previewLayer = previewLayer {
                print("Preview Layer frame size UpdateUIVIEW: \(previewLayer.bounds.size)")

                previewLayer.frame = UIScreen.main.bounds // Update the frame whenever the view is updated
            }
        }
    }
}

