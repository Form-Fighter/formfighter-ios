import SwiftUI
import Firebase
import FirebaseFirestore
import SceneKit

// Create a dedicated type for feedback status
enum FeedbackStatus: String {
    case pending = "pending"
    case uploading = "uploading"
    case processing = "processing"
    case analyzing = "analyzing"
    case completed = "completed"
    
    var message: String {
        switch self {
        case .pending: return "Preparing your video..."
        case .uploading: return "Uploading your form..."
        case .processing: return "AI is analyzing your technique..."
        case .analyzing: return "Breaking down your movements..."
        case .completed: return "Analysis complete!"
        }
    }
}

struct FeedbackView: View {
    let feedbackId: String
    let videoURL: URL?
    
    @StateObject private var notificationManager = NotificationManager.shared
    @StateObject private var viewModel = FeedbackViewModel()
    @State private var currentTipIndex = 0
    @State private var lastNotifiedStatus: FeedbackStatus = .pending
    @State private var showFeedbackPrompt = false
    @State private var userComment = ""
    @State private var selectedEmoji: UserFeedbackType?
    @State private var hasSubmittedFeedback = false
    
    private let timer = Timer.publish(every: 3, on: .main, in: .common).autoconnect()
    
    private let muayThaiTips = [
        "Keep your guard up - protect your chin!",
        "Turn your hip over when throwing kicks",
        "Stay light on your feet, ready to move",
        "Breathe out when striking",
        "Return kicks and punches back to guard quickly",
        "Keep your elbows close to protect your body"
    ]
    
    var body: some View {
        Group {
            if let feedback = viewModel.feedback {
                completedFeedbackView
            } else if let error = viewModel.error {
                UnexpectedErrorView(error: error)
            } else if videoURL != nil {
                uploadingView
            } else {
                ProgressView()
            }
        }
        .onAppear {
            if videoURL != nil {
                viewModel.setupFirestoreListener(feedbackId: feedbackId)
            } else {
                viewModel.setupFirestoreListener(feedbackId: feedbackId)
                checkExistingUserFeedback()
            }
        }
        .onDisappear {
            viewModel.cleanup()
        }
        .sheet(isPresented: $showFeedbackPrompt) {
            UserFeedbackPrompt(
                userComment: $userComment,
                selectedEmoji: $selectedEmoji,
                onSubmit: submitUserFeedback
            )
        }
    }
    
    private var completedFeedbackView: some View {
        ScrollView {
            VStack(spacing: 24) {
                if let feedback = viewModel.feedback {
                    ScoreCardView(jabScore: feedback.modelFeedback.jab_score)
                    
                    if let usdzUrl = URL(string: feedback.animation_usdz_url) {
                        SceneView(
                            scene: try? SCNScene(url: usdzUrl),
                            options: [.allowsCameraControl, .autoenablesDefaultLighting]
                        )
                        .frame(height: 300)
                        .cornerRadius(12)
                    }
                    
                    FeedbackSection(title: "Extension", 
                                  feedback: feedback.modelFeedback.body.feedback.extensionFeedback)
                    FeedbackSection(title: "Guard", 
                                  feedback: feedback.modelFeedback.body.feedback.guardPosition)
                    FeedbackSection(title: "Retraction", 
                                  feedback: feedback.modelFeedback.body.feedback.retraction)
                    
                    if !hasSubmittedFeedback {
                        FeedbackPromptButton(action: { showFeedbackPrompt = true })
                    }
                }
            }
            .padding()
        }
    }
    
    private var uploadingView: some View {
        VStack(spacing: 20) {
            Spacer()
            
            Image(systemName: "figure.martial.arts")
                .font(.system(size: 60))
                .foregroundColor(.blue)
            
            Text(viewModel.status.message)
                .font(.headline)
            
            ProgressView()
                .progressViewStyle(.linear)
                .frame(width: 200)
            
            VStack(spacing: 10) {
                Text("Muay Thai Tip:")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                
                Text(muayThaiTips[currentTipIndex])
                    .font(.body)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                    .transition(.opacity)
                    .id(currentTipIndex)
            }
            .padding()
            
            Spacer()
        }
        .padding()
        .onReceive(timer) { _ in
            withAnimation {
                currentTipIndex = (currentTipIndex + 1) % muayThaiTips.count
            }
        }
    }
    
    private func checkExistingUserFeedback() {
        viewModel.checkExistingUserFeedback(feedbackId: feedbackId) { hasSubmitted in
            hasSubmittedFeedback = hasSubmitted
        }
    }
    
    private func submitUserFeedback() {
        guard let emoji = selectedEmoji,
              userComment.count >= 15 else { return }
        
        viewModel.submitUserFeedback(
            feedbackId: feedbackId,
            emoji: emoji,
            comment: userComment
        ) { success in
            if success {
                hasSubmittedFeedback = true
                showFeedbackPrompt = false
            }
        }
    }
}

struct UnexpectedErrorView: View {
    let error: String
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "exclamationmark.triangle")
                .font(.system(size: 60))
                .foregroundColor(.red)
            
            Text("Unexpected Error")
                .font(.title)
            
            Text(error)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
                .padding()
            
            Button(action: {
                // Add retry logic here if needed
            }) {
                Text("Try Again")
                    .font(.headline)
                    .foregroundColor(.white)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(Color.blue)
                    .cornerRadius(10)
            }
            .padding(.horizontal)
        }
        .padding()
    }
}

struct FeedbackView_Previews: PreviewProvider {
    static var previews: some View {
        FeedbackView(feedbackId: "sampleFeedbackId", videoURL: nil)
    }
}

struct UserFeedbackPrompt: View {
    @Binding var userComment: String
    @Binding var selectedEmoji: UserFeedbackType?
    let onSubmit: () -> Void
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("How was your feedback?")
                    .font(.title2)
                    .fontWeight(.bold)
                
                // Emoji Selection
                HStack(spacing: 30) {
                    ForEach(UserFeedbackType.allCases, id: \.self) { emoji in
                        Button(action: { selectedEmoji = emoji }) {
                            Text(emoji.rawValue)
                                .font(.system(size: 40))
                                .opacity(selectedEmoji == emoji ? 1.0 : 0.5)
                                .scaleEffect(selectedEmoji == emoji ? 1.2 : 1.0)
                        }
                    }
                }
                .padding()
                
                // Comment TextField
                TextField("Tell us what you think (minimum 15 characters)", text: $userComment, axis: .vertical)
                    .textFieldStyle(.roundedBorder)
                    .lineLimit(4...6)
                    .padding()
                
                Spacer()
            }
            .padding()
            .navigationBarItems(
                leading: Button("Cancel") {
                    // You'll need to add a dismiss binding or use @Environment
                },
                trailing: Button("Submit") {
                    onSubmit()
                }
                .disabled(userComment.count < 15 || selectedEmoji == nil)
            )
        }
    }
}

struct FeedbackPromptButton: View {
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: "message")
                Text("How was this feedback?")
                Spacer()
                Image(systemName: "chevron.right")
            }
            .padding()
            .background(Color.blue.opacity(0.1))
            .cornerRadius(10)
        }
    }
}
