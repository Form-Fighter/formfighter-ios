import SwiftUI
import AVFoundation


struct VisionView: View {
    @AppStorage("gptLanguage") var gptLanguage: GPTLanguage = .english
    @StateObject var vm: VisionVM
    @EnvironmentObject var userManager: UserManager
    @Environment(\.scenePhase) var scenePhase  // To handle foreground/background transitions

    var body: some View {
        VStack {
            CameraPermissionView()  // This will hold the camera preview
        }
        .onChange(of: scenePhase) { newPhase in
            if newPhase == .active {
                // Restart the capture session when the app comes to the foreground
                NotificationCenter.default.post(name: NSNotification.Name("StartCaptureSession"), object: nil)
            } else if newPhase == .background {
                // Stop the capture session when the app goes to the background
                NotificationCenter.default.post(name: NSNotification.Name("StopCaptureSession"), object: nil)
            }
        }
    }
}


struct CameraPermissionView: View {
    @State private var cameraAuthorized = false
    @State private var showPermissionDeniedAlert = false

    var body: some View {
        VStack {
            if cameraAuthorized {
                CameraPreviewTestView()
                    .onAppear {
                        NotificationCenter.default.post(name: NSNotification.Name("StartCaptureSession"), object: nil)
                    }
                    .onDisappear {
                        NotificationCenter.default.post(name: NSNotification.Name("StopCaptureSession"), object: nil)
                    }
            } else {
                Button("Request Camera Access") {
                    requestCameraPermission()
                }
                .padding()
                .alert(isPresented: $showPermissionDeniedAlert) {
                    Alert(
                        title: Text("Camera Access Denied"),
                        message: Text("Please enable camera access in Settings."),
                        primaryButton: .default(Text("Open Settings"), action: openSettings),
                        secondaryButton: .cancel()
                    )
                }
            }
        }
        .onAppear {
            checkCameraPermission()
        }
    }

    func checkCameraPermission() {
        let status = AVCaptureDevice.authorizationStatus(for: .video)
        switch status {
        case .authorized:
            cameraAuthorized = true
        case .notDetermined:
            requestCameraPermission()
        case .denied, .restricted:
            showPermissionDeniedAlert = true
        @unknown default:
            break
        }
    }

    func requestCameraPermission() {
        AVCaptureDevice.requestAccess(for: .video) { granted in
            DispatchQueue.main.async {
                if granted {
                    cameraAuthorized = true
                } else {
                    showPermissionDeniedAlert = true
                }
            }
        }
    }

    func openSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else {
            return
        }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL)
        }
    }
}
