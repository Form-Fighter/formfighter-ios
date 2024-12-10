import SwiftUI
import AVFoundation
import Vision
import Photos
import AVKit
import FirebaseFirestore
import Alamofire
import os
import FirebaseAnalytics
import FirebaseAuth

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
        let playerItem = AVPlayerItem(url: videoURL)
        let player = AVPlayer(playerItem: playerItem)
        player.actionAtItemEnd = .none  // Prevents player from stopping at end
        self._player = State(initialValue: player)
        
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: playerItem,
            queue: .main
        ) { _ in
            playerItem.seek(to: .zero)
            player.play()
        }
    }
    
    var body: some View {
        ZStack {
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
                            updateUserStreak()
                            self.isUploading = false
                            self.feedbackId = feedbackId
                            print("️ Switching to profile tab")
                            self.shouldNavigateToFeedback = true
                            print("🎯 Navigation flag set: \(self.shouldNavigateToFeedback)")
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
            let uploadDuration = Date().timeIntervalSince(startTime)
            Tracker.videoUploadCompleted(duration: uploadDuration)
            
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
    
    private func updateUserStreak() {
        guard let userId = Auth.auth().currentUser?.uid else { return }
        let userRef = db.collection("users").document(userId)
        
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        print("🎯 Starting streak update for user: \(userId)")
        
        // MARK: - DEBUG ONLY - Comment out for production
        #if DEBUG
        let debugResetStreak = true // Set to true to force streak update
        if debugResetStreak {
            // Set last training date to yesterday to force streak increment
            let yesterday = calendar.date(byAdding: .day, value: -1, to: today)!
            userRef.updateData([
                "lastTrainingDate": Timestamp(date: yesterday),
                "currentStreak": 0
            ]) { error in
                if let error = error {
                    print("❌ Debug reset failed: \(error.localizedDescription)")
                } else {
                    print("✅ Debug reset successful")
                    // Remove the recursive call and instead proceed with the normal streak update
                    self.performStreak(userRef: userRef, today: today, calendar: calendar)
                }
            }
            return
        }
        #endif
        
        performStreak(userRef: userRef, today: today, calendar: calendar)
    }
    
    private func performStreak(userRef: DocumentReference, today: Date, calendar: Calendar) {
        userRef.getDocument { document, error in
            guard let document = document,
                  document.exists else { 
                print("❌ No document found for streak update")
                return 
            }
            
            let lastTrainingDate = (document.data()?["lastTrainingDate"] as? Timestamp)?.dateValue()
            let currentStreak = document.data()?["currentStreak"] as? Int ?? 0
            
            print("📊 Current streak: \(currentStreak)")
            print("���� Last training date: \(String(describing: lastTrainingDate))")
            
            var newStreak = currentStreak
            
            if let lastTrainingDate = lastTrainingDate {
                let lastTrainingDay = calendar.startOfDay(for: lastTrainingDate)
                let daysBetween = calendar.dateComponents([.day], from: lastTrainingDay, to: today).day ?? 0
                
                print("📍 Days between: \(daysBetween)")
                
                if daysBetween == 1 {
                    // Consecutive day
                    newStreak += 1
                } else if daysBetween == 0 {
                    // Same day, don't increment
                    return
                } else {
                    // Streak broken
                    newStreak = 1
                }
            } else {
                // First training session
                newStreak = 1
            }
            
            print("🔥 New streak: \(newStreak)")
            
            // Update Firestore
            userRef.updateData([
                "currentStreak": newStreak,
                "lastTrainingDate": Timestamp(date: today)
            ]) { error in
                if let error = error {
                    print("❌ Error updating streak: \(error.localizedDescription)")
                } else {
                    print("✅ Streak updated successfully to: \(newStreak)")
                }
            }
            
            if newStreak > currentStreak {
                NotificationManager.shared.scheduleStreakNotification(
                    streak: newStreak,
                    lastTrainingTime: Date()
                )
            }
        }
    }
}
