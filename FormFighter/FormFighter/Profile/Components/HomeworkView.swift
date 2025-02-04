import SwiftUI
import FirebaseAuth
import FirebaseFirestore

struct Homework: Codable, Identifiable {
    @DocumentID var id: String?
    let coachId: String?
    let title: String?
    let description: String?
    let assignedDate: Timestamp?
    let date: Timestamp?
    let createdAt: Timestamp?
    let punchCount: Int?
    let students: [String]?
    let status: String?
    let completedFeedbackIds: [String]?
    let focusMetric: String?
    
    var remainingPunches: Int {
        (punchCount ?? 0) - (completedFeedbackIds?.count ?? 0)
    }
    
    enum CodingKeys: String, CodingKey {
        case id
        case coachId
        case title
        case description
        case assignedDate
        case date
        case createdAt
        case punchCount
        case students
        case status
        case completedFeedbackIds
        case focusMetric
    }
}

struct HomeworkView: View {
    @EnvironmentObject var userManager: UserManager
    let homework: Homework
    let feedbacks: [FeedbackListItem]
    @State private var timeRemaining: TimeInterval = 0
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Description
            Text(homework.title ?? "")
                .font(.headline)
                .frame(maxWidth: .infinity, alignment: .leading)
            Text(homework.description ?? "")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .frame(maxWidth: .infinity, alignment: .leading)
            
            // Progress
            HStack {
                Image(systemName: "figure.boxing")
                Text("\(homework.remainingPunches) \(homework.remainingPunches == 1 ? "jab" : "jabs") remaining")
                    .foregroundColor(ThemeColors.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Time Remaining
            HStack {
                Image(systemName: "clock")
                Text(timeString(from: timeRemaining))
                    .foregroundColor(timeRemaining < 3600 ? .red : ThemeColors.primary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            
            // Punch Status
            HStack(spacing: 0) {
                ForEach(0..<(homework.punchCount ?? 0), id: \.self) { index in
                    PunchStatusView(index: index)
                        .frame(maxWidth: .infinity)
                }
            }
            .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 80)
            .padding(.vertical, 8)
        }
        .padding()
        .frame(maxWidth: .infinity)
        .background(ThemeColors.primary.opacity(0.1))
        .cornerRadius(12)
        .shadow(radius: 2)
        .border(Color.gray.opacity(0.2), width: 1)
        .onReceive(timer) { _ in
            let now = Date()
            let dueDate = Calendar.current.date(bySettingHour: 23, minute: 59, second: 59, of: homework.assignedDate?.dateValue() ?? Date())!
            timeRemaining = dueDate.timeIntervalSince(now)
        }
    }
    
    private func timeString(from timeInterval: TimeInterval) -> String {
        guard timeInterval > 0 else { return "Time's up!" }
        
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        
        if hours > 0 {
            return "Due in \(hours)h \(minutes)m"
        } else {
            return "Due in \(minutes)m"
        }
    }
    
    private func PunchStatusView(index: Int) -> some View {
        let homeworkFeedbacks = feedbacks
            .filter { $0.homeworkId == homework.id }
            .sorted { $0.date > $1.date }
        
        let feedback = index < homeworkFeedbacks.count ? homeworkFeedbacks[index] : nil
        
        return Group {
            if let feedback = feedback {
                switch feedback.status {
                    case .pending:
                        statusCell(number: index + 1) {
                            ProgressView()
                                .scaleEffect(0.7)
                        }
                    case .error:
                        statusCell(number: index + 1) {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundColor(.red)
                        }
                    case .completed:
                        statusCell(number: index + 1) {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    default:
                        statusCell(number: index + 1) {
                            Image(systemName: "xmark")
                                .font(.title2)
                                .foregroundColor(.red)
                        }
                }
            } else {
                statusCell(number: index + 1) {
                    Image(systemName: "xmark")
                        .font(.title2)
                        .foregroundColor(.red)
                }
            }
        }
    }
    
    private func statusCell(number: Int, @ViewBuilder content: () -> some View) -> some View {
        VStack(spacing: 4) {
            Text("\(number)")
                .font(.headline)
                .foregroundColor(.secondary)
            content()
                .imageScale(.large)
        }
        .frame(maxWidth: .infinity, minHeight: 80, maxHeight: 80)
        .background(Color(.systemBackground))
        .overlay(
            RoundedRectangle(cornerRadius: 0)
                .stroke(ThemeColors.primary.opacity(0.2), lineWidth: 1)
        )
    }
}

// Preview provider
// struct HomeworkView_Previews: PreviewProvider {
//     static var previews: some View {
//         HomeworkView(homework: Homework(
//             id: "1",
//             coachId: "COACH_ID",
//             title: "Do 1 jab",
//             description: "do 1 jab today and watch your hips",
//             assignedDate: Date(),
//             punchCount: 3,
//             students: ["USER_ID"],
//             status: "assigned",
//             completedFeedbackIds: []
//         ))
//         .environmentObject(UserManager.shared)
//         .environmentObject(FeedbackManager.shared)
//         .padding()
//     }
// }

func updateHomeworkProgress(homeworkId: String, feedbackId: String) {
    guard let userId = Auth.auth().currentUser?.uid else { return }
    
    let db = Firestore.firestore()
    let homeworkRef = db.collection("homework").document(homeworkId)
    
    homeworkRef.updateData([
        "completedFeedbackIds": FieldValue.arrayUnion([feedbackId])
    ]) { error in
        if let error = error {
            print("Error updating homework progress: \(error.localizedDescription)")
        }
    }
} 