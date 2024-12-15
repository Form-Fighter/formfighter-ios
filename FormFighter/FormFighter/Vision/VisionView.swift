import SwiftUI
import AVFoundation

struct VisionView: View {
    @State private var hasCameraPermission = false
    @State private var showCameraView = false
    @State private var missingPermissionsMessage = ""
    @State private var showPaywall = false
    @EnvironmentObject private var purchasesManager: PurchasesManager
    
    @StateObject private var cameraManager = CameraManager()
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            ThemeColors.background.ignoresSafeArea()
            
            if !purchasesManager.premiumSubscribed && !purchasesManager.eliteSubscribed {
                PaywallView()
            } else if showCameraView {
                CameraVisionView(cameraManager: cameraManager)
                    .onAppear {
                        cameraManager.startSession()
                    }
                    .onDisappear {
                        cameraManager.stopSession()
                    }
                    .safeAreaInset(edge: .bottom) {
                        Color.clear.frame(height: 0)
                    }
            } else {
                VStack {
                    Text("🥊 Muay Thai Vision Access 🥊")
                        .font(.title2)
                        .fontWeight(.bold)
                        .padding(.bottom, 5)
                    
                    Text(missingPermissionsMessage)
                        .foregroundColor(.red)
                        .padding()
                        .multilineTextAlignment(.center)
                    
                    Button(action: openSettings) {
                        Text("Enable Camera Access")
                            .foregroundColor(.white)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(10)
                            .shadow(radius: 3)
                    }
                }
                .padding()
                .background(
                    RoundedRectangle(cornerRadius: 15)
                        .fill(Color.white)
                        .shadow(radius: 5)
                )
                .onTapGesture {
                    if !purchasesManager.premiumSubscribed && !purchasesManager.eliteSubscribed {
                        showPaywall = true
                    }
                }
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .onAppear {
            if !purchasesManager.premiumSubscribed && !purchasesManager.eliteSubscribed  {
                showPaywall = true
            }
            checkPermissions()
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
        missingPermissionsMessage = "To analyze your Muay Thai technique, we need:\n"
        if !hasCameraPermission {
            missingPermissionsMessage += "📸 Camera Access\n"
        }
        missingPermissionsMessage += "\nThis helps us provide real-time feedback on your form."
    }
}
