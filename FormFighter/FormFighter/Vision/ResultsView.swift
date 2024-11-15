import SwiftUI
import AVFoundation
import Vision
import Photos
import AVKit
import FirebaseFirestore
import Alamofire
import os

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
    
    @State private var player: AVPlayer
    @State private var navigateToFeedback = false
    @EnvironmentObject var userManager: UserManager
    @State private var isUploading = false
    @State private var activeError: ResultsViewError?
    @State private var feedbackId: String?
    let db = Firestore.firestore()
    
    init(videoURL: URL) {
        self.videoURL = videoURL
        self._player = State(initialValue: AVPlayer(url: videoURL))
    }
    
    var body: some View {
        ZStack {
            VideoPlayer(player: player)
                .edgesIgnoringSafeArea(.all)
                .onAppear {
                    player.play()
                    NotificationCenter.default.addObserver(forName: .AVPlayerItemDidPlayToEndTime, object: player.currentItem, queue: .main) { _ in
                        player.seek(to: .zero)
                        player.play()
                    }
                }
                .onDisappear {
                    deleteTemporaryVideo()
                }
            
            if isUploading {
                Color.black.opacity(0.5)
                ProgressView("Uploading...")
                    .foregroundColor(.white)
            }
            
            VStack {
                Spacer()
                HStack {
                    Button("Discard") {
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
        .navigationDestination(isPresented: $navigateToFeedback) {
            if let feedbackId = feedbackId {
                FeedbackView(feedbackId: feedbackId, videoURL: videoURL)
            }
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
        if userManager.userId.isEmpty {
            activeError = .userNotLoggedIn
            return
        }
        
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
            
            Task {
                await uploadToServer(feedbackId: feedbackRef.documentID, coachId: coachId)
            }
            
            self.feedbackId = feedbackRef.documentID
            self.navigateToFeedback = true
            
        } catch {
            activeError = .failedToCreateFeedback(error)
        }
    }
    
    private func uploadToServer(feedbackId: String, coachId: String?) async {
        isUploading = true  // Show loading state
        
        do {
            let videoData = try Data(contentsOf: videoURL)
            
            let headers: HTTPHeaders = [
                "userID": userManager.userId,
                "Content-Type": "multipart/form-data"
            ]
            
            // Convert to async/await pattern
            try await withCheckedThrowingContinuation { continuation in
                AF.upload(multipartFormData: { multipartFormData in
                    // Add video file
                    multipartFormData.append(
                        videoData,
                        withName: "file",
                        fileName: videoURL.lastPathComponent,
                        mimeType: "video/quicktime"
                    )
                    
                    // Add feedbackId
                    multipartFormData.append(
                        feedbackId.data(using: .utf8)!,
                        withName: "feedbackId"
                    )
                    
                    // Add coachId if available
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
                .responseData { response in
                    switch response.result {
                    case .success:
                        print("Upload successful")
                        continuation.resume()
                    case .failure(let error):
                        print("Upload failed: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            // If we get here, upload was successful
            print("Upload completed successfully")
            
        } catch {
            print("Upload error: \(error)")
            await MainActor.run {
                activeError = .uploadError(error)
            }
        }
        
        await MainActor.run {
            isUploading = false  // Hide loading state
        }
    }
}
