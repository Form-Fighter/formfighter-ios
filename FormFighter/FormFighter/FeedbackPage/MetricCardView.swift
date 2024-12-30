import SwiftUI

struct MetricCardView: View {
    let title: String
    let metric: FeedbackModels.MetricDetails
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with Score and Tier
            HStack {
                Text(title.replacingOccurrences(of: "_", with: " "))
                    .font(.title3)
                    .fontWeight(.semibold)
                    .foregroundColor(.white)
                
                Spacer()
                
                VStack(alignment: .trailing) {
                    if let score = metric.metric_score {
                        Text("\(String(format: "%.2f", score))/10")
                            .font(.title2)
                            .fontWeight(.bold)
                            .foregroundColor(ThemeColors.primary)
                    }
                    
                    if let tier = metric.tier {
                        Text("Tier: \(tier)")
                            .font(.subheadline)
                            .fontWeight(.medium)
                            .foregroundColor(.yellow)
                    }
                }
            }
            
            // Motion Sequence Section
            if let sequence = metric.ordered_sequence {
                MotionSequenceView(
                    sequence: sequence,
                    isCorrect: metric.sequence_correct ?? false,
                    timingDifferences: metric.timing_differences
                )
            }
            
            // Metric Values
            if let values = metric.metric_values, !values.isEmpty {
                Text(values)
                    .foregroundColor(.gray)
            }
            
            // Velocity with Tier
            if let velocity = metric.velocity {
                VStack(alignment: .leading) {
                    HStack {
                        Text(velocity)
                            .foregroundColor(.blue)
                        Spacer()
                        if let tier = metric.tier {
                            Text("Performance Tier: \(tier)")
                                .font(.subheadline)
                                .foregroundColor(.yellow)
                        }
                    }
                }
                .padding()
                .background(Color.blue.opacity(0.1))
                .cornerRadius(8)
            }
            
            // Description
            if let description = metric.description {
                ForEach(description, id: \.self) { desc in
                    Text(desc)
                        .italic()
                        .foregroundColor(.gray)
                }
            }
            
            // Buffer Zone Warning
            if let bufferZone = metric.buffer_zone {
                Text(bufferZone)
                    .fontWeight(.medium)
                    .foregroundColor(.yellow)
            }
            
            // K.O. Warning
            if let ko = metric.ko {
                Text(ko)
                    .fontWeight(.bold)
                    .foregroundColor(.red)
            }
            
            // Main Sections
            MetricSectionView(title: "Pros", items: metric.pros, color: .green)
            MetricSectionView(title: "Cons", items: metric.cons, color: .red)
            
            // Strategic Section
            Divider()
                .background(ThemeColors.primary.opacity(0.2))
            
            MetricSectionView(title: "Tactical Advantages", items: metric.tactical_advantages, color: .yellow)
            MetricSectionView(title: "Strategic Advantages", items: metric.strategic_advantages, color: .blue)
            MetricSectionView(title: "Biomechanical Efficiency", items: metric.biomechanical_efficiency, color: .purple)
            MetricSectionView(title: "Counter Opportunities", items: metric.counter_opportunities, color: .red)
            MetricSectionView(title: "Optimal Follow-ups", items: metric.optimal_followups, color: .green)
            MetricSectionView(title: "Strategic Applications", items: metric.strategic_applications, color: .cyan)
        }
        .padding()
        .background(Color(.systemGray6).opacity(0.3))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ThemeColors.primary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct MetricSectionView: View {
    let title: String
    let items: [String]?
    let color: Color
    
    var body: some View {
        if let items = items, !items.isEmpty {
            VStack(alignment: .leading, spacing: 8) {
                Text(title)
                    .font(.headline)
                    .foregroundColor(color)
                
                ForEach(items, id: \.self) { item in
                    HStack(alignment: .top) {
                        Text("•")
                            .foregroundColor(color)
                        Text(item)
                            .foregroundColor(.gray)
                    }
                }
            }
            .padding(.vertical, 4)
        }
    }
}

struct MotionSequenceView: View {
    let sequence: String
    let isCorrect: Bool
    let timingDifferences: String?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Motion Sequence Analysis")
                .font(.title3)
                .fontWeight(.semibold)
                .foregroundColor(.blue)
            
            // Sequence Status
            HStack {
                Image(systemName: isCorrect ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                Text(isCorrect ? "Correct Sequence" : "Incorrect Sequence")
            }
            .padding()
            .background(isCorrect ? Color.green.opacity(0.2) : Color.red.opacity(0.2))
            .cornerRadius(8)
            .foregroundColor(isCorrect ? .green : .red)
            
            // Sequence Visualization
            VStack(alignment: .leading, spacing: 8) {
                Text("Detected Sequence:")
                    .foregroundColor(.gray)
                
                VStack(spacing: 12) {
                    ForEach(sequence.components(separatedBy: "->"), id: \.self) { part in
                        VStack(spacing: 4) {
                            Text(part.trimmingCharacters(in: .whitespaces))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                            
                            if part != sequence.components(separatedBy: "->").last {
                                Image(systemName: "arrow.down")
                                    .foregroundColor(.red)
                                    .padding(.vertical, 4)
                            }
                        }
                    }
                }
            }
            
            // Timing Differences
            if let timingDifferences = timingDifferences {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Timing Analysis:")
                        .font(.headline)
                        .foregroundColor(.yellow)
                    Text(timingDifferences)
                        .foregroundColor(.gray)
                }
                .padding()
                .background(Color.yellow.opacity(0.1))
                .cornerRadius(8)
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
} 