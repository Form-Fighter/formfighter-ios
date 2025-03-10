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
    @State private var currentHomework: Homework?
    
    private let muayThaiTips = [
        "Keep your guard up - protect your chin!",
        "Turn your hip over when throwing kicks",
        "Stay light on your feet, ready to move",
        "Breathe out when striking",
        "Return kicks and punches back to guard quickly",
        "Keep your elbows close to protect your body"
    ]
    
    private let challengeService = ChallengeService.shared
    
    init(videoURL: URL) {
        print("ResultsView init - videoURL: \(videoURL)")
        print("File exists: \(FileManager.default.fileExists(atPath: videoURL.path))")
        
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
                    Task {
                        currentHomework = await getActiveHomework()
                    }
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
                    Button("Start Over") {
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
                    .environmentObject(PurchasesManager.shared)
                    .environmentObject(FeedbackManager.shared)
                    .onDisappear {
                        // When returning from FeedbackView, dismiss ResultsView
                        if shouldNavigateToFeedback {
                            shouldNavigateToFeedback = false
                            dismiss()
                        }
                    }
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
        guard let userId = userManager.user?.id else {
            activeError = .userNotLoggedIn
            return
        }
        
        isUploading = true
        defer { isUploading = false }
        
        do {
            let userDoc = try await db.collection("users").document(userId).getDocument()
            let coachId = userDoc.data()?["myCoach"] as? String
            
            // Get active homework
            let homework = await getActiveHomework()
            
            let feedbackRef = try await db.collection("feedback").addDocument(data: [
                "userId": userId,
                "coachId": coachId as Any,
                "createdAt": Timestamp(date: Date()),
                "status": "pending",
                "fileName": videoURL.lastPathComponent,
                "challengeId": challengeService.activeChallenge?.id,
                "homeworkId": homework?.id
            ])
            
            // Update homework progress if this is for homework
            if let homeworkId = homework?.id {
                updateHomeworkProgress(homeworkId: homeworkId, feedbackId: feedbackRef.documentID)
            }
            
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
            guard let userId = userManager.user?.id else {
                throw ResultsViewError.userNotLoggedIn
            }
            
            let headers: HTTPHeaders = [
                "userID": userId,
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
                            
                            // Post notification after cleanup
                            NotificationCenter.default.post(
                                name: NSNotification.Name("OpenFeedback"),
                                object: nil,
                                userInfo: ["feedbackId": feedbackId]
                            )
                            
                            dismiss()  // Just dismiss without camera cleanup
                            
                            // Deduct one token for a successful video upload.
                            Task {
                                await UserManager.shared.deductOneToken()
                            }
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
            
            print("📊 Streak check - Current: \(currentStreak), Last training: \(String(describing: lastTrainingDate))")
            
            var newStreak = currentStreak
            var shouldShowCelebration = false
            
            if let lastTrainingDate = lastTrainingDate {
                let lastTrainingDay = calendar.startOfDay(for: lastTrainingDate)
                let daysBetween = calendar.dateComponents([.day], from: lastTrainingDay, to: today).day ?? 0
                
                print("📍 Days between trainings: \(daysBetween)")
                
                if daysBetween == 1 {
                    // Consecutive day - increment and celebrate
                    newStreak += 1
                    shouldShowCelebration = true
                } else if daysBetween == 0 {
                    // Same day, don't increment or celebrate
                    return
                } else {
                    // Streak broken
                    newStreak = 1
                    shouldShowCelebration = false
                }
            } else {
                // First training session
                newStreak = 1
                shouldShowCelebration = true
            }
            
            print("🔥 Streak update - New: \(newStreak), Show celebration: \(shouldShowCelebration)")
            
            // Update Firestore
            userRef.updateData([
                "currentStreak": newStreak,
                "lastTrainingDate": Timestamp(date: today)
            ]) { error in
                if let error = error {
                    print("❌ Error updating streak: \(error.localizedDescription)")
                } else {
                    print("✅ Streak updated successfully to: \(newStreak)")
                    if shouldShowCelebration {
                        UserManager.shared.shouldShowCelebration = true
                    }
                }
            }
            
            // Schedule next notification only if streak increased
            if newStreak > currentStreak {
                NotificationManager.shared.scheduleStreakNotification(
                    streak: newStreak,
                    lastTrainingTime: Date()
                )
            }
        }
    }
    
    private func getActiveHomework() async -> Homework? {
        guard let userId = Auth.auth().currentUser?.uid else { return nil }
        let db = Firestore.firestore()
        
        let today = Calendar.current.startOfDay(for: Date())
        let tomorrow = Calendar.current.date(byAdding: .day, value: 1, to: today)!
        
        do {
            let snapshot = try await db.collection("homework")
                .whereField("students", arrayContains: userId)
                .whereField("assignedDate", isGreaterThanOrEqualTo: today)
                .whereField("assignedDate", isLessThan: tomorrow)
                .getDocuments()
            
            let homeworkList = snapshot.documents.compactMap { doc -> Homework? in
                try? doc.data(as: Homework.self)
            }
            
            // Return earliest incomplete homework
            return homeworkList
                .filter { homework in
                    let completedCount = homework.completedFeedbackIds?.count ?? 0
                    let punchCount = homework.punchCount ?? 0
                    return completedCount < punchCount
                }
                .sorted { h1, h2 in
                    let date1 = h1.assignedDate?.dateValue() ?? Date()
                    let date2 = h2.assignedDate?.dateValue() ?? Date()
                    return date1 < date2
                }
                .first
        } catch {
            print("Error fetching homework: \(error)")
            return nil
        }
    }
}
