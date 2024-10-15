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
    @State private var isRecording = false
    @State private var recordingMessage = ""
    @State private var videoURL: URL?
    @State private var navigateToPreview = false

    // Temporizadores opcionales
    @State private var firstTimer: Timer?
    @State private var secondTimer: Timer?

    var cameraManager: CameraManager

    var body: some View {
        NavigationStack {
            ZStack {
                // Vista de la cámara
                CameraPreviewView(detectedBodyPoints: $detectedBodyPoints, isBodyDetected: $isBodyDetected, cameraManager: cameraManager)
                    .edgesIgnoringSafeArea(.all)

                // Mostrar puntos clave
                ForEach(detectedBodyPoints.indices, id: \.self) { index in
                    let point = detectedBodyPoints[index]
                    Circle()
                        .fill(Color.green)
                        .frame(width: 10, height: 10)
                        .position(point)
                }
                .ignoresSafeArea()

                // Mostrar progreso e icono mientras se analiza
                if isCounting && timer1 < 3 {
                    VStack {
                        HStack {
                            Image(systemName: "magnifyingglass")
                                .foregroundColor(.white)
                                .font(.largeTitle)
                            Text("Analizando, mantén el objeto enfocado")
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

                // Mostrar cuenta regresiva
                if timer2 > 0 && timer2 <= 4 && !isRecording {
                    Text("\(4 - timer2)")
                        .font(.system(size: 100))
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 10)
                        .transition(.scale)
                        .animation(.easeInOut, value: timer2)
                }

                // Mostrar mensaje de grabación
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
        .onChange(of: isBodyDetected) { bodyDetected in
            if bodyDetected {
                startFirstTimer()
            } else {
                resetTimers() // Detener y resetear los temporizadores cuando el cuerpo sale del cuadro
            }
        }
        .ignoresSafeArea()
    }

    // Iniciar el primer temporizador
    func startFirstTimer() {
        guard firstTimer == nil else { return } // Evitar múltiples temporizadores

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

    // Iniciar el segundo temporizador
    func startSecondTimer() {
        guard secondTimer == nil else { return } // Evitar múltiples temporizadores

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

    // Simular la grabación
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

    // Resetear todos los temporizadores y estados
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
    @Binding var detectedBodyPoints: [CGPoint] // Ajuste a puntos del cuerpo
    @Binding var isBodyDetected: Bool // Cambiar a cuerpo detectado
    
    var cameraManager: CameraManager
    
    class Coordinator: NSObject, AVCaptureVideoDataOutputSampleBufferDelegate {
        var parent: CameraPreviewView
        
        init(parent: CameraPreviewView) {
            self.parent = parent
        }
        
        func captureOutput(_ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer, from connection: AVCaptureConnection) {
            guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else { return }
            
            // Cambiar el tipo de request para detectar puntos del cuerpo
            let request = VNDetectHumanBodyPoseRequest { request, error in
                guard let results = request.results as? [VNHumanBodyPoseObservation], error == nil else {
                    DispatchQueue.main.async {
                        self.parent.isBodyDetected = false // Ajustado a cuerpo detectado
                    }
                    return
                }
                
                var newBodyPoints: [CGPoint] = []
                var bodyDetected = false
                
                for bodyObservation in results {
                    bodyDetected = true
                    if let recognizedPoints = try? bodyObservation.recognizedPoints(.all) {
                        for (_, point) in recognizedPoints {
                            let normalizedPoint = point.location
                            let convertedPoint = self.convertVisionPoint(normalizedPoint, to: self.parent.cameraManager.previewLayer)
                            newBodyPoints.append(convertedPoint)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.parent.detectedBodyPoints = newBodyPoints // Ajustado
                    self.parent.isBodyDetected = bodyDetected // Ajustado
                }
            }
            
            let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])
            try? handler.perform([request])
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
}

class CameraManager: NSObject, ObservableObject {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var movieOutput = AVCaptureMovieFileOutput() // Salida para grabación de video
    
    func setupCamera(in view: UIView, delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        // Configuración del input de cámara
        guard let backCamera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("No se encontró la cámara trasera")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: backCamera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
            } else {
                print("No se pudo agregar la entrada de la cámara.")
                return
            }
        } catch {
            print("Error al agregar la entrada de la cámara: \(error)")
            return
        }
        
        // Configurar y agregar la salida de video
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "cameraQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
        } else {
            print("No se pudo agregar videoOutput a la sesión.")
            return
        }
        
        // Configurar y agregar la salida para la grabación de video
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
        } else {
            print("No se pudo agregar movieOutput a la sesión.")
            return
        }
        
        // Configuración de la vista previa
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.layer.bounds
        view.layer.addSublayer(previewLayer!)
        
        // Iniciar la sesión de captura
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
            DispatchQueue.main.async {
                print("Sesión de captura activa: \(captureSession.isRunning)")
            }
        }
        
        self.captureSession = captureSession
    }
    
    // Iniciar grabación
    func startRecording() {
        // Asegurarse de que la sesión de captura está corriendo
        guard let captureSession = captureSession, captureSession.isRunning else {
            print("La sesión de captura no está activa.")
            return
        }
        
        // Verificar si movieOutput tiene conexiones activas justo antes de grabar
        if movieOutput.connections.isEmpty {
            print("No hay conexiones activas para la salida de grabación.")
            return
        }
        
        // Si hay conexiones activas, iniciar la grabación
        let fileName = "output_\(UUID().uuidString).mov"
        let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        // Verificar si el archivo ya existe y eliminarlo
        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
                print("Archivo existente eliminado.")
            } catch {
                print("Error al eliminar el archivo existente: \(error)")
            }
        }
        
        
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        print("Grabación iniciada, guardando en: \(outputURL.absoluteString)")
    }
    
    // Detener grabación
    func stopRecording() {
        if movieOutput.isRecording {
            movieOutput.stopRecording()
        } else {
            print("No hay grabación en curso para detener.")
        }
    }
}

// Extensión para manejar la grabación y guardar el video en la librería de fotos
extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        if let error = error {
            print("Error en la grabación: \(error.localizedDescription)")
        } else {
            // Verificar si el archivo se creó correctamente
            if FileManager.default.fileExists(atPath: outputFileURL.path) {
                print("El archivo existe, listo para ser guardado.")
                
                // Enviar una notificación con la URL del video grabado
                DispatchQueue.main.async {
                    NotificationCenter.default.post(name: NSNotification.Name("VideoRecorded"), object: outputFileURL)
                }
                
                // Solicitar permiso para acceder a la librería de fotos
                PHPhotoLibrary.requestAuthorization { status in
                    if status == .authorized || status == .limited {
                        // Guardar el video en la librería de fotos
                        PHPhotoLibrary.shared().performChanges({
                            PHAssetChangeRequest.creationRequestForAssetFromVideo(atFileURL: outputFileURL)
                        }) { success, error in
                            if success {
                                print("Video guardado en la librería de fotos.")
                            } else if let error = error {
                                print("Error al guardar el video: \(error.localizedDescription)")
                            }
                        }
                    } else {
                        print("Permiso para acceder a la librería de fotos denegado.")
                    }
                }
            } else {
                print("El archivo de video no existe o no se creó correctamente.")
            }
        }
    }
}
