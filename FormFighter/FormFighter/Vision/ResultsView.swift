import SwiftUI
import AVFoundation
import Vision
import Photos
import AVKit
import FirebaseFirestore
import Alamofire
import os
import FirebaseAnalytics

// Create a dedicated error type
enum ResultsViewError: LocalizedError {
    case userNotLoggedIn
    case failedToCreateFeedback(Error)
    case uploadError(Error)
    
    var errorDescription: String? {
        switch self {
        case .userNotLoggedIn:
            return "User not logged in"
        case .failedToCreateFeedback(let error):
            return "Failed to create feedback: \(error.localizedDescription)"
        case .uploadError(let error):
            return "Upload error: \(error.localizedDescription)"
        }
    }
}

struct ResultsView: View {
    var videoURL: URL
    @Environment(\.dismiss) var dismiss
    @AppStorage("selectedTab") private var selectedTab: String = TabIdentifier.vision.rawValue
    @State private var shouldSwitchToProfile = false
    
    @State private var player: AVPlayer
    @State private var shouldNavigateToFeedback = false
    @EnvironmentObject var userManager: UserManager
    @State private var isUploading = false
    @State private var activeError: ResultsViewError?
    @State private var feedbackId: String?
    let db = Firestore.firestore()
    @State private var currentTipIndex = 0
    @State private var isShowingBoxing = true
    @State private var symbolOpacity = 1.0
    
    private let muayThaiTips = [
        "Keep your guard up - protect your chin!",
        "Turn your hip over when throwing kicks",
        "Stay light on your feet, ready to move",
        "Breathe out when striking",
        "Return kicks and punches back to guard quickly",
        "Keep your elbows close to protect your body"
    ]
    
    init(videoURL: URL) {
        self.videoURL = videoURL
        self._player = State(initialValue: AVPlayer(url: videoURL))
    }
    
    var body: some View {
        ZStack {
            // Video player
            VideoPlayer(player: player)
                .edgesIgnoringSafeArea(.all)
                .disabled(true)
                .onAppear {
                    player.play()
                }
            
            // Upload overlay
            if isUploading {
                Color.black.opacity(0.5)
                uploadingView
            }
            
            // Buttons at bottom
            VStack {
                Spacer()
                HStack(spacing: 20) {
                    Button("Discard") {
                        deleteTemporaryVideo()
                        dismiss()
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.red)
                    .cornerRadius(10)
                    
                    Button("Save") {
                        Task {
                            await initiateFeedback()
                        }
                    }
                    .foregroundColor(.white)
                    .padding()
                    .background(Color.blue)
                    .cornerRadius(10)
                    .disabled(isUploading)
                }
                .padding(.bottom, 30)
            }
        }
        .navigationDestination(isPresented: $shouldNavigateToFeedback) {
            if let feedbackId = feedbackId {
                FeedbackView(feedbackId: feedbackId, videoURL: videoURL)
                    .environmentObject(UserManager.shared)
            }
        }
        .navigationBarBackButtonHidden(true)
        .alert(
            "Error",
            isPresented: Binding(
                get: { activeError != nil },
                set: { if !$0 { activeError = nil } }
            ),
            actions: {
                Button("OK", role: .cancel) {
                    activeError = nil
                }
            },
            message: {
                if let error = activeError {
                    Text(error.localizedDescription)
                }
            }
        )
        .onDisappear {
            // Cleanup
            player.pause()
            player.replaceCurrentItem(with: nil)
        }
    }
    
    func deleteTemporaryVideo() {
        do {
            try FileManager.default.removeItem(at: videoURL)
            print("Temporary video file deleted.")
        } catch {
            print("Error deleting video file: \(error)")
        }
    }
    
    private func initiateFeedback() async {
        guard !isUploading else { return }
        guard !userManager.userId.isEmpty else {
            activeError = .userNotLoggedIn
            return
        }
        
        isUploading = true
        defer { isUploading = false }
        
        do {
            let userDoc = try await db.collection("users").document(userManager.userId).getDocument()
            let coachId = userDoc.data()?["myCoach"] as? String
            
            let feedbackRef = try await db.collection("feedback").addDocument(data: [
                "userId": userManager.userId,
                "coachId": coachId as Any,
                "createdAt": Timestamp(date: Date()),
                "status": "pending",
                "fileName": videoURL.lastPathComponent
            ])
            
            // Upload video immediately after creating feedback document
            await uploadToServer(feedbackId: feedbackRef.documentID, coachId: coachId)
        } catch {
            activeError = .failedToCreateFeedback(error)
        }
    }
    
    private func uploadToServer(feedbackId: String, coachId: String?) async {
        print("⚡️ Starting upload")
        isUploading = true
        let startTime = Date()
        
        do {
            let headers: HTTPHeaders = [
                "userID": userManager.userId,
                "Content-Type": "multipart/form-data"
            ]
            
            print("⚡️ feedbackId: \(feedbackId)")
            print("⚡️ coachId: \(coachId ?? "nil")")
            print("⚡️ videoURL: \(videoURL)")
            
            try await withCheckedThrowingContinuation { (continuation: CheckedContinuation<Void, Error>) in
                AF.upload(multipartFormData: { multipartFormData in
                    multipartFormData.append(
                        videoURL,
                        withName: "file",
                        fileName: videoURL.lastPathComponent,
                        mimeType: "video/quicktime"
                    )
                    
                    multipartFormData.append(
                        feedbackId.data(using: .utf8)!,
                        withName: "feedbackId"
                    )
                    
                    if let coachId = coachId {
                        multipartFormData.append(
                            coachId.data(using: .utf8)!,
                            withName: "coachId"
                        )
                    }
                }, to: "https://www.form-fighter.com/api/upload",
                   headers: headers)
                .uploadProgress { progress in
                    print("Upload Progress: \(progress.fractionCompleted)")
                }
                .response { response in
                    if let error = response.error {
                        print("⚡️ Upload failed: \(error)")
                        continuation.resume(throwing: error)
                    } else {
                        print("⚡️ Upload success")
                        Task { @MainActor in
                            print("⚡️ Setting navigation state")
                            self.isUploading = false
                            self.feedbackId = feedbackId
                            print("��️ Switching to profile tab")
                            selectedTab = TabIdentifier.profile.rawValue
                            NotificationCenter.default.post(
                                name: NSNotification.Name("OpenFeedback"),
                                object: nil,
                                userInfo: ["feedbackId": feedbackId]
                            )
                            dismiss()  // Dismiss the camera flow
                        }
                        continuation.resume()
                    }
                }
            }
            
            // After successful upload
            let duration = Date().timeIntervalSince(startTime)
            Tracker.videoUploadCompleted(duration: duration, filmingDuration: nil)
            
        } catch {
            print("⚡️ Upload error: \(error)")
            await MainActor.run {
                activeError = .uploadError(error)
                isUploading = false
            }
            Tracker.errorOccurred(
                domain: "VideoUpload",
                code: (error as NSError).code,
                description: error.localizedDescription
            )
        }
    }
    
    private var uploadingView: some View {
        VStack(spacing: 20) {
            VStack(spacing: 8) {
                Text("Uploading your video")
                    .font(.headline)
                    .foregroundColor(ThemeColors.primary)
                
                // Sparring animation
                ZStack {
                    Image(systemName: "figure.boxing")
                        .opacity(isShowingBoxing ? 1 : 0)
                    Image(systemName: "figure.kickboxing")
                        .opacity(isShowingBoxing ? 0 : 1)
                }
                .font(.system(size: 50))
                .foregroundColor(ThemeColors.primary)
                .frame(width: 200, height: 60)
                .onAppear {
                    withAnimation(
                        .easeInOut(duration: 1.0)
                        .repeatForever(autoreverses: true)
                    ) {
                        isShowingBoxing.toggle()
                    }
                }
            }
            
            // Display random Muay Thai tips while uploading
            Text(muayThaiTips[currentTipIndex])
                .font(.title3)
                .fontWeight(.bold)
                .multilineTextAlignment(.center)
                .foregroundColor(.primary)
                .padding()
                .onAppear {
                    Timer.scheduledTimer(withTimeInterval: 3.0, repeats: true) { _ in
                        withAnimation {
                            currentTipIndex = (currentTipIndex + 1) % muayThaiTips.count
                        }
                    }
                }
        }
        .padding(30)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(UIColor.systemBackground))
                .shadow(radius: 10)
        )
        .padding()
    }
    
    private func handleUploadError(_ error: Error) {
        Analytics.logEvent("upload_error", parameters: [
            "error_description": error.localizedDescription,
            "error_code": (error as NSError).code
        ])
    }
}
