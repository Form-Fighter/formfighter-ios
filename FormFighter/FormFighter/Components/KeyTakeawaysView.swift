import SwiftUI

struct KeyTakeawaysResponse: Codable {
    let metric: String
    let score: Double
    let key_takeaways: String
}

struct KeyTakeawaysView: View {
    let feedbackId: String
    let existingTakeaways: (metric: String?, score: Double?, key_takeaways: String?)?
    
    @AppStorage("keyTakeawaysRequestCount") private var requestCount = 0
    @AppStorage("lastRequestWeek") private var lastRequestWeek = Calendar.current.component(.weekOfYear, from: Date())
    
    @State private var isLoading = false
    @State private var error: String?
    @State private var takeaways: KeyTakeawaysResponse?
    @State private var showingConfirmation = false
    
    private let maxWeeklyRequests = 5
    
    init(feedbackId: String, feedback: FeedbackModels.ModelFeedback?) {
        self.feedbackId = feedbackId
        if let feedback = feedback {
            self.existingTakeaways = (
                metric: feedback.lowest_metric?.name,
                score: feedback.lowest_metric?.score,
                key_takeaways: feedback.key_takeaways
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
    
    private func displayTakeawaysView(metric: String, score: Double, keyTakeaways: String) -> some View {
        VStack(alignment: .leading, spacing: 12) {
          
            
            Text(metric)
                .font(.headline)
                .padding(.vertical, 4)
            
            Text(keyTakeaways)
                .font(.body)
                .lineSpacing(4)
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
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
}

