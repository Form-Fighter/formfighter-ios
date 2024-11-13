import SwiftUI
import AVFoundation
import Vision
import Photos
import AVKit
import FirebaseFirestore

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
        do {
            let boundary = "Boundary-\(UUID().uuidString)"
            var request = URLRequest(url: URL(string: "https://your-server.com/api/upload")!)
            request.httpMethod = "POST"
            
            request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
            request.setValue(userManager.userId, forHTTPHeaderField: "userID")
            
            var body = Data()
            
            let videoData = try Data(contentsOf: videoURL)
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"file\"; filename=\"\(videoURL.lastPathComponent)\"\r\n")
            body.append("Content-Type: video/quicktime\r\n\r\n")
            body.append(videoData)
            body.append("\r\n")
            
            body.append("--\(boundary)\r\n")
            body.append("Content-Disposition: form-data; name=\"feedbackId\"\r\n\r\n")
            body.append(feedbackId)
            body.append("\r\n")
            
            if let coachId = coachId {
                body.append("--\(boundary)\r\n")
                body.append("Content-Disposition: form-data; name=\"coachId\"\r\n\r\n")
                body.append(coachId)
                body.append("\r\n")
            }
            
            body.append("--\(boundary)--\r\n")
            request.httpBody = body
            
            let (_, response) = try await URLSession.shared.data(for: request)
            
            guard let httpResponse = response as? HTTPURLResponse,
                  (200...299).contains(httpResponse.statusCode) else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Server error"])
            }
            
            print("Upload initiated successfully")
            
        } catch {
            activeError = .uploadError(error)
        }
    }
}

extension Data {
    mutating func append(_ string: String) {
        if let data = string.data(using: .utf8) {
            append(data)
        }
    }
}
