//import SwiftUI
//import AVFoundation
//
//
//struct VisionView: View {
//    @AppStorage("gptLanguage") var gptLanguage: GPTLanguage = .english
//    @StateObject var vm: VisionVM
//    @EnvironmentObject var userManager: UserManager
//    @Environment(\.scenePhase) var scenePhase  // To handle foreground/background transitions
//
//    var body: some View {
//        VStack {
//            CameraPermissionView()  // This will hold the camera preview
//        }
//        .onChange(of: scenePhase) { newPhase in
//            if newPhase == .active {
//                // Restart the capture session when the app comes to the foreground
//                NotificationCenter.default.post(name: NSNotification.Name("StartCaptureSession"), object: nil)
//            } else if newPhase == .background {
//                // Stop the capture session when the app goes to the background
//                NotificationCenter.default.post(name: NSNotification.Name("StopCaptureSession"), object: nil)
//            }
//        }
//    }
//}
//
//
//struct CameraPermissionView: View {
//    @State private var cameraAuthorized = false
//    @State private var showPermissionDeniedAlert = false
//
//    var body: some View {
//        VStack {
//            if cameraAuthorized {
//                CameraPreviewTestView()
//                    .onAppear {
//                        NotificationCenter.default.post(name: NSNotification.Name("StartCaptureSession"), object: nil)
//                    }
//                    .onDisappear {
//                        NotificationCenter.default.post(name: NSNotification.Name("StopCaptureSession"), object: nil)
//                    }
//            } else {
//                Button("Request Camera Access") {
//                    requestCameraPermission()
//                }
//                .padding()
//                .alert(isPresented: $showPermissionDeniedAlert) {
//                    Alert(
//                        title: Text("Camera Access Denied"),
//                        message: Text("Please enable camera access in Settings."),
//                        primaryButton: .default(Text("Open Settings"), action: openSettings),
//                        secondaryButton: .cancel()
//                    )
//                }
//            }
//        }
//        .onAppear {
//            checkCameraPermission()
//        }
//    }
//
//    func checkCameraPermission() {
//        let status = AVCaptureDevice.authorizationStatus(for: .video)
//        switch status {
//        case .authorized:
//            cameraAuthorized = true
//        case .notDetermined:
//            requestCameraPermission()
//        case .denied, .restricted:
//            showPermissionDeniedAlert = true
//        @unknown default:
//            break
//        }
//    }
//
//    func requestCameraPermission() {
//        AVCaptureDevice.requestAccess(for: .video) { granted in
//            DispatchQueue.main.async {
//                if granted {
//                    cameraAuthorized = true
//                } else {
//                    showPermissionDeniedAlert = true
//                }
//            }
//        }
//    }
//
//    func openSettings() {
//        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
//            return
//        }
//        if UIApplication.shared.canOpenURL(settingsURL) {
//            UIApplication.shared.open(settingsURL)
//        }
//    }
//}

import SwiftUI
import AVFoundation

struct VisionView: View {
    @State private var hasCameraPermission = false
    @State private var showCameraView = false
    @State private var missingPermissionsMessage = ""
    
    let cameraManager = CameraManager() // Create an instance of CameraManager
    
    var body: some View {
        if showCameraView {
            CameraVisionView(cameraManager: cameraManager)
        } else {
            VStack {
                Text(missingPermissionsMessage)
                    .foregroundColor(.red)
                    .padding()
                Button(action: openSettings) {
                    Text("Go to settings")
                        .foregroundColor(.blue)
                }
            }
            .onAppear {
                checkPermissions()
            }
        }
    }
    
    // Function to open the device settings
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // Check all permissions
    func checkPermissions() {
        checkCameraPermission()
        
        // If all permissions are granted, show the camera view
        if hasCameraPermission {
            showCameraView = true
        } else {
            // Display a message with the missing permissions
            updateMissingPermissionsMessage()
        }
    }
    
    // Request permission for the camera
    func checkCameraPermission() {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            hasCameraPermission = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .video) { granted in
                DispatchQueue.main.async {
                    self.hasCameraPermission = granted
                    self.checkPermissions()
                }
            }
        default:
            hasCameraPermission = false
        }
    }
    
    // Update the missing permissions message
    func updateMissingPermissionsMessage() {
        missingPermissionsMessage = "The following permissions are missing:\n"
        if !hasCameraPermission {
            missingPermissionsMessage += "- Camera access\n"
        }
        missingPermissionsMessage += "Please enable them in the settings."
    }
}
