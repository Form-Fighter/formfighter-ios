import SwiftUI
import AVFoundation

struct KeyTakeawaysResponse: Codable {
    let metric: String?
    let score: Double?
    let key_takeaways: String?
    let key_takeaways_audio: AudioDetails?
    
    struct AudioDetails: Codable {
        let duration: Double?
        let fileSize: Int?
        let model: String?
        let url: String?
        let voiceId: String?
    }
}

struct KeyTakeawaysView: View {
    let feedbackId: String
    let videoUrl: String?
    var existingTakeaways: (metric: String?, score: Double?, key_takeaways: String?, key_takeaways_audio: KeyTakeawaysResponse.AudioDetails?, videoUrl: String?)?
    
    @AppStorage("keyTakeawaysRequestCount") private var requestCount = 0
    @AppStorage("lastRequestWeek") private var lastRequestWeek = Calendar.current.component(.weekOfYear, from: Date())
    
    @State private var isLoading = false
    @State private var error: String?
    @State private var takeaways: KeyTakeawaysResponse?
    @State private var showingConfirmation = false
    
    @State private var audioPlayer: AVPlayer?
    @State private var isPlayingAudio = false
    
    @State private var selectedSentence: String? = nil
    @State private var poseHighlightKey = UUID()
    
    @State private var showingPoseOverlay: Bool = false
    
    private let maxWeeklyRequests = 5
    
    init(feedbackId: String, feedback: FeedbackModels.ModelFeedback?, videoUrl: String?) {
        self.feedbackId = feedbackId
        self.videoUrl = videoUrl
        if let feedback = feedback {
            self.existingTakeaways = (
                metric: feedback.lowest_metric?.name,
                score: feedback.lowest_metric?.score,
                key_takeaways: feedback.key_takeaways,
                key_takeaways_audio: feedback.key_takeaways_audio.map { KeyTakeawaysResponse.AudioDetails(
                    duration: $0.duration,
                    fileSize: $0.fileSize,
                    model: $0.model,
                    url: $0.url,
                    voiceId: $0.voiceId
                )},
                videoUrl: videoUrl
            )
        } else {
            self.existingTakeaways = nil
        }
    }
    
    private var remainingRequests: Int {
        checkAndResetWeeklyCounter()
        return maxWeeklyRequests - requestCount
    }
    
    private var isButtonDisabled: Bool {
        remainingRequests <= 0 || isLoading
    }
    
    var body: some View {
        VStack(spacing: 16) {
            if let existing = existingTakeaways,
               let metric = existing.metric,
               let score = existing.score,
               let keyTakeaways = existing.key_takeaways {
                // Display existing takeaways from feedback
                displayTakeawaysView(metric: metric, score: score, keyTakeaways: keyTakeaways)
            } else if remainingRequests <= 0 {
                // No more requests available this week
                noRequestsRemainingView
            } else {
                // Show either request button or loading state
                if isLoading {
                    loadingView
                } else if let takeaways = takeaways {
                    displayTakeawaysView(
                        metric: takeaways.metric,
                        score: takeaways.score,
                        keyTakeaways: takeaways.key_takeaways
                    )
                } else {
                    requestButtonView
                }
                
                // Error Message
                if let error = error {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.subheadline)
                        .multilineTextAlignment(.center)
                }
            }
        }
        .padding()
        .onAppear {
            checkAndResetWeeklyCounter()
        }
    }
    
    private var loadingView: some View {
        VStack {
            ProgressView()
            Text("Fetching takeaways...")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
    }
    
    private var noRequestsRemainingView: some View {
        VStack(spacing: 12) {
            Text("No Requests Remaining")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Text("You've used all your key takeaway requests for this week. Check back next week for more insights!")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
            
            Text("Next reset: \(nextResetDate(), style: .relative)")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 1)
    }
    
    private var requestButtonView: some View {
        VStack {
            Text("Remaining requests this week: \(remainingRequests)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Button(action: { showingConfirmation = true }) {
                Text("Get Key Takeaways")
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(ThemeColors.primary)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .confirmationDialog(
                "Use 1 of \(remainingRequests) remaining requests?",
                isPresented: $showingConfirmation,
                titleVisibility: .visible
            ) {
                Button("Get Takeaways") {
                    fetchKeyTakeaways()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("You can request key takeaways 5 times per week")
            }
        }
    }
    
    private func displayTakeawaysView(metric: String?, score: Double?, keyTakeaways: String?) -> some View {
        ZStack {
            // Main content
            VStack(alignment: .leading, spacing: 12) {
                if let metric = metric {
                    Text(metric.replacingOccurrences(of: "_", with: " ").capitalized)
                        .font(.headline)
                        .padding(.vertical, 4)
                }
                
                // Audio button
                if let audioUrlString = existingTakeaways?.key_takeaways_audio?.url ?? takeaways?.key_takeaways_audio?.url,
                   let audioUrl = URL(string: audioUrlString) {
                    audioPlayButton(url: audioUrl)
                }
                
                // Interactive takeaways with highlights
                if let keyTakeaways = keyTakeaways {
                    let sentences = keyTakeaways.components(separatedBy: ". ")
                    ForEach(sentences, id: \.self) { sentence in
                        HStack(spacing: 8) {
                            let highlightInfo = PoseHighlightMapping.analyzeMetric(metricName: metric ?? "", sentence: sentence)
                            let highlightColor = highlightInfo.type.color
                            
                            Circle()
                                .fill(Color(highlightColor))
                                .frame(width: 8, height: 8)
                            
                            HStack {
                                Text(sentence)
                                    .font(.body)
                                    .lineSpacing(4)
                                
                                Spacer()
                                
                                Image(systemName: "chevron.right")
                                    .foregroundColor(.gray)
                                    .opacity(selectedSentence == sentence ? 1 : 0.5)
                            }
                            .padding(.vertical, 8)
                            .padding(.horizontal, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 8)
                                    .fill(selectedSentence == sentence ? 
                                          Color(highlightColor).opacity(0.15) : 
                                          Color.gray.opacity(0.05))
                            )
                            .overlay(
                                RoundedRectangle(cornerRadius: 8)
                                    .stroke(selectedSentence == sentence ? 
                                           Color(highlightColor).opacity(0.3) : 
                                           Color.gray.opacity(0.1))
                            )
                        }
                        .onTapGesture {
                            print("🔵 Sentence tapped: \(sentence)")
                            withAnimation {
                                if selectedSentence == sentence {
                                    poseHighlightKey = UUID()
                                }
                                selectedSentence = sentence
                                showingPoseOverlay = true
                            }
                        }
                    }
                } else {
                    Text("No takeaways available")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .lineSpacing(4)
                }
                
                // Pass selected sentence to PoseHighlightView
                // if let metric = metric,
                //    let videoUrl = self.videoUrl,
                //    let url = URL(string: videoUrl) {
                //     PoseHighlightView(
                //         videoURL: url,
                //         metricName: metric,
                //         selectedSentence: selectedSentence
                //     )
                //     .id(poseHighlightKey)
                //     .padding(.top, 8)
                //     .onTapGesture {
                //         withAnimation {
                //             showingPoseOverlay = true
                //         }
                //     }
                // }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
        .sheet(isPresented: $showingPoseOverlay) {
            if let metric = metric,
               let videoUrl = self.videoUrl,
               let url = URL(string: videoUrl) {
                
                VStack {
                    PoseHighlightView(
                        videoURL: url,
                        metricName: metric,
                        selectedSentence: selectedSentence
                    )
                }
                .padding()
                .background(Color(.systemBackground))
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
                
            } else {
                VStack {
                    Text("Unable to load content")
                        .foregroundColor(.secondary)
                }
                .padding()
                .background(Color(.systemBackground))
                .presentationDetents([.large])
                .presentationDragIndicator(.visible)
            }
        }
        .onDisappear {
            stopAudio()
        }
    }
    
    private func audioPlayButton(url: URL) -> some View {
        Button(action: toggleAudio) {
            HStack {
                Image(systemName: isPlayingAudio ? "pause.circle.fill" : "play.circle.fill")
                    .font(.title2)
                Text(isPlayingAudio ? "Pause" : "Play Audio")
                    .font(.subheadline)
            }
            .foregroundColor(ThemeColors.primary)
            .padding(.vertical, 4)
        }
    }
    
    private func checkAndResetWeeklyCounter() {
        let currentWeek = Calendar.current.component(.weekOfYear, from: Date())
        if currentWeek != lastRequestWeek {
            requestCount = 0
            lastRequestWeek = currentWeek
        }
    }
    
    private func fetchKeyTakeaways() {
        guard !isButtonDisabled else { return }
        
        isLoading = true
        error = nil
        
        Task {
            do {
                let url = URL(string: "https://www.form-fighter.com/api/feedback/key-takeaways")!
                var request = URLRequest(url: url)
                request.httpMethod = "POST"
                request.setValue("application/json", forHTTPHeaderField: "Content-Type")
                
                let body = ["feedbackId": feedbackId]
                request.httpBody = try JSONEncoder().encode(body)
                
                let (data, response) = try await URLSession.shared.data(for: request)
                
                guard let httpResponse = response as? HTTPURLResponse else {
                    throw URLError(.badServerResponse)
                }
                
                guard httpResponse.statusCode == 200 else {
                    throw URLError(.badServerResponse)
                }
                
                takeaways = try JSONDecoder().decode(KeyTakeawaysResponse.self, from: data)
                requestCount += 1
                
            } catch {
                self.error = "Failed to fetch takeaways: \(error.localizedDescription)"
            }
            
            isLoading = false
        }
    }
    
    private func nextResetDate() -> Date {
        let calendar = Calendar.current
        let currentDate = Date()
        
        // Get the start of next week
        var components = DateComponents()
        components.weekOfYear = calendar.component(.weekOfYear, from: currentDate) + 1
        components.yearForWeekOfYear = calendar.component(.yearForWeekOfYear, from: currentDate)
        components.weekday = calendar.firstWeekday // Usually Sunday
        components.hour = 0
        components.minute = 0
        components.second = 0
        
        return calendar.date(from: components) ?? Date().addingTimeInterval(7 * 24 * 60 * 60)
    }
    
    private func toggleAudio() {
        if isPlayingAudio {
            audioPlayer?.pause()
            isPlayingAudio = false
        } else {
            // Check both existing and new takeaways for audio URL
            if let audioUrlString = existingTakeaways?.key_takeaways_audio?.url ?? takeaways?.key_takeaways_audio?.url,
               let audioUrl = URL(string: audioUrlString) {
                if audioPlayer == nil {
                    audioPlayer = AVPlayer(url: audioUrl)
                    audioPlayer?.actionAtItemEnd = .pause
                    
                    // Add observer for playback ended
                    NotificationCenter.default.addObserver(
                        forName: .AVPlayerItemDidPlayToEndTime,
                        object: audioPlayer?.currentItem,
                        queue: .main
                    ) { _ in
                        isPlayingAudio = false
                    }
                }
                audioPlayer?.seek(to: .zero)
                audioPlayer?.play()
                isPlayingAudio = true
            }
        }
    }
    
    private func stopAudio() {
        audioPlayer?.pause()
        audioPlayer = nil
        isPlayingAudio = false
    }
}

