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
import Photos


struct VisionView: View {
    @State private var hasCameraPermission = false
    @State private var hasMicrophonePermission = false
    @State private var hasPhotoLibraryPermission = false
    @State private var showCameraView = false
    @State private var missingPermissionsMessage = ""
    
    let cameraManager = CameraManager() // Crear instancia de CameraManager
    
    var body: some View {
        if showCameraView {
            CameraVisionView(cameraManager: cameraManager)
            
        } else {
            VStack {
                Text(missingPermissionsMessage)
                    .foregroundColor(.red)
                    .padding()
                Button(action: openSettings) {
                    Text("Ir a configuraciones")
                        .foregroundColor(.blue)
                }
            }
            .onAppear {
                checkPermissions()
            }
        }
    }
    
    // Función para abrir la configuración del dispositivo
    func openSettings() {
        if let url = URL(string: UIApplication.openSettingsURLString) {
            UIApplication.shared.open(url)
        }
    }
    
    // Verificar todos los permisos
    func checkPermissions() {
        checkCameraPermission()
        checkMicrophonePermission()
        checkPhotoLibraryPermission()
        
        // Si todos los permisos son otorgados, mostrar la vista de la cámara
        if hasCameraPermission && hasMicrophonePermission && hasPhotoLibraryPermission {
            showCameraView = true
        } else {
            // Mostrar un mensaje con los permisos faltantes
            updateMissingPermissionsMessage()
        }
    }
    
    // Solicitar permiso para la cámara
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
    
    // Solicitar permiso para el micrófono
    func checkMicrophonePermission() {
        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            hasMicrophonePermission = true
        case .notDetermined:
            AVCaptureDevice.requestAccess(for: .audio) { granted in
                DispatchQueue.main.async {
                    self.hasMicrophonePermission = granted
                    self.checkPermissions()
                }
            }
        default:
            hasMicrophonePermission = false
        }
    }
    
    // Solicitar permiso para la librería de fotos
    func checkPhotoLibraryPermission() {
        let photoAuthorizationStatus = PHPhotoLibrary.authorizationStatus()
        switch photoAuthorizationStatus {
        case .authorized, .limited:
            hasPhotoLibraryPermission = true
        case .notDetermined:
            PHPhotoLibrary.requestAuthorization { status in
                DispatchQueue.main.async {
                    self.hasPhotoLibraryPermission = (status == .authorized || status == .limited)
                    self.checkPermissions()
                }
            }
        default:
            hasPhotoLibraryPermission = false
        }
    }
    
    // Actualizar mensaje de permisos faltantes
    func updateMissingPermissionsMessage() {
        missingPermissionsMessage = "Faltan los siguientes permisos:\n"
        if !hasCameraPermission {
            missingPermissionsMessage += "- Acceso a la cámara\n"
        }
        if !hasMicrophonePermission {
            missingPermissionsMessage += "- Acceso al micrófono\n"
        }
        if !hasPhotoLibraryPermission {
            missingPermissionsMessage += "- Acceso a la librería de fotos\n"
        }
        missingPermissionsMessage += "Por favor, habilítalos en las configuraciones."
    }
}
