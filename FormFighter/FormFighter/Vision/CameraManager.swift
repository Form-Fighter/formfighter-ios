import AVFoundation
import SwiftUI

class CameraManager: NSObject, ObservableObject {
    var captureSession: AVCaptureSession?
    var previewLayer: AVCaptureVideoPreviewLayer?
    var movieOutput = AVCaptureMovieFileOutput()
    
    @Published var isActive = false
    @Published var setupError: Error?
    /// Published property to hold the recorded video URL.
    @Published var recordedVideoURL: URL?
    
    private let sessionQueue = DispatchQueue(label: "com.formfighter.sessionQueue")
    
    func stopSession() {
        print("DEBUG: stopSession() called.")
        sessionQueue.async { [weak self] in
            self?.captureSession?.stopRunning()
            DispatchQueue.main.async {
                self?.isActive = false
                print("DEBUG: Capture session stopped. isActive set to false.")
            }
        }
    }
    
    func startSession() {
        print("DEBUG: startSession() called.")
        guard !isActive else {
            print("DEBUG: Session already active, returning.")
            return
        }
        sessionQueue.async { [weak self] in
            self?.captureSession?.startRunning()
            DispatchQueue.main.async {
                self?.isActive = true
                print("DEBUG: Capture session started. isActive set to true.")
            }
        }
    }
    
    func cleanup() {
        print("DEBUG: cleanup() called. Cleaning up session and previewLayer.")
        stopSession()
        captureSession = nil
        previewLayer = nil
    }
    
    func setupCamera(in view: UIView, delegate: AVCaptureVideoDataOutputSampleBufferDelegate) {
        print("DEBUG: setupCamera() called.")
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = .high
        
        // Using the front camera for recording.
        guard let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front) else {
            print("DEBUG: Front camera not found.")
            return
        }
        
        do {
            let input = try AVCaptureDeviceInput(device: camera)
            if captureSession.canAddInput(input) {
                captureSession.addInput(input)
                print("DEBUG: Camera input added to session.")
            } else {
                print("DEBUG: Could not add camera input.")
                return
            }
        } catch {
            print("DEBUG: Error adding camera input: \(error)")
            return
        }
        
        // Video data output:
        let videoOutput = AVCaptureVideoDataOutput()
        videoOutput.setSampleBufferDelegate(delegate, queue: DispatchQueue(label: "cameraQueue"))
        if captureSession.canAddOutput(videoOutput) {
            captureSession.addOutput(videoOutput)
            print("DEBUG: Video data output added to session.")
        } else {
            print("DEBUG: Could not add video output.")
            return
        }
        
        // Movie file output for recording video.
        if captureSession.canAddOutput(movieOutput) {
            captureSession.addOutput(movieOutput)
            print("DEBUG: Movie file output added to session.")
        } else {
            print("DEBUG: Could not add movie output.")
            return
        }
        
        // Setup previewLayer.
        previewLayer = AVCaptureVideoPreviewLayer(session: captureSession)
        previewLayer?.videoGravity = .resizeAspectFill
        previewLayer?.frame = view.bounds
        if let layer = previewLayer {
            view.layer.addSublayer(layer)
            print("DEBUG: Preview layer added to view.")
        }
        
        DispatchQueue.global(qos: .background).async {
            captureSession.startRunning()
            DispatchQueue.main.async {
                print("DEBUG: Capture session running: \(captureSession.isRunning)")
            }
        }
        
        self.captureSession = captureSession
        print("DEBUG: setupCamera() completed successfully.")
    }
    
    func startRecording() {
        print("DEBUG: startRecording() called.")
        guard let captureSession = captureSession, captureSession.isRunning else {
            print("DEBUG: Capture session is not active.")
            return
        }
        
        if movieOutput.connections.isEmpty {
            print("DEBUG: No active connections available for recording.")
            return
        }
        
        let fileName = "output_\(UUID().uuidString).mov"
        let outputURL = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0].appendingPathComponent(fileName)
        
        if FileManager.default.fileExists(atPath: outputURL.path) {
            do {
                try FileManager.default.removeItem(at: outputURL)
                print("DEBUG: Existing file deleted at \(outputURL.path).")
            } catch {
                print("DEBUG: Error deleting file: \(error)")
            }
        }
        
        movieOutput.startRecording(to: outputURL, recordingDelegate: self)
        print("DEBUG: Recording started, saving to: \(outputURL.absoluteString)")
    }
    
    func stopRecording() {
        print("DEBUG: stopRecording() called.")
        if movieOutput.isRecording {
            movieOutput.stopRecording()
            print("DEBUG: Recording stopped.")
        } else {
            print("DEBUG: No recording in progress to stop.")
        }
    }
}

extension CameraManager: AVCaptureFileOutputRecordingDelegate {
    func fileOutput(_ output: AVCaptureFileOutput,
                    didFinishRecordingTo outputFileURL: URL,
                    from connections: [AVCaptureConnection],
                    error: Error?) {
        if let error = error {
            print("DEBUG: Recording finished with error: \(error.localizedDescription)")
        } else {
            print("DEBUG: Recording finished successfully. File URL: \(outputFileURL)")
            DispatchQueue.main.async {
                self.recordedVideoURL = outputFileURL
                print("DEBUG: recordedVideoURL in CameraManager set to \(outputFileURL)")
            }
        }
    }
} 