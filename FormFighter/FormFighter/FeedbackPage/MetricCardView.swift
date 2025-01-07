import SwiftUI

struct MetricCardView: View {
    let title: String
    let metric: FeedbackModels.MetricDetails
    
    private var isBooleanMetric: Bool {
        if let value = metric.metric_values?.lowercased() {
            return value == "true" || value == "false"
        }
        return false
    }
    
    private var booleanValue: Bool {
        return metric.metric_values?.lowercased() == "true"
    }
    
    private var isVelocityMetric: Bool {
        return title.lowercased().contains("velocity")
    }
    
    private var shouldHideScore: Bool {
        let hideScoreMetrics = [
            "Motion_Sequence",
            "Whip_Effect_Extension",
            "Return_Position_Difference_Retraction",
            "Rear_Hand_In_Guard_Extension",
            "Hands_Above_Shoulders_Guard",
            "Foot_Steps_With_Punch_Diff_Extension"
        ]
        return hideScoreMetrics.contains(title)
    }
    
    private func tierColor(_ tier: String) -> Color {
        switch tier.lowercased() {
        case "elite": return .purple
        case "professional": return .blue
        case "advanced": return .green
        case "intermediate": return .yellow
        case "fitness": return .orange
        default: return .gray
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Title handling
            if title == "Motion_Sequence" {
                Text("Motion Sequence Analysis")
                    .font(.title3)
                    .fontWeight(.bold)
                    .foregroundColor(.primary)
                
                // Special handling for Motion Sequence
                if let sequence = metric.metric_values,
                   let isCorrect = metric.metric_score.map({ $0 > 0.5 }),
                   let timingDiffs = metric.timing_differences {
                    MotionSequenceView(
                        sequence: sequence,
                        isCorrect: isCorrect,
                        timingDifferences: timingDiffs
                    )
                }
            } else {
                // Special title for Force Generation
                if title == "Force_Generation_Extension" {
                    Text("Knock Out Power")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(.primary)
                } else {
                    Text(formatTitle(title))
                        .font(.headline)
                        .foregroundColor(.primary)
                }
                
                // Special handling for Force Generation
                if title == "Force_Generation_Extension" {
                    if let koPotential = metric.knockout_potential?.replacingOccurrences(of: " %", with: ""),
                       let koValue = Double(koPotential) {
                        VStack(alignment: .leading, spacing: 4) {
                            // K.O. Potential Progress Bar
                            ProgressView(value: koValue, total: 100)
                                .tint(.red)
                                .scaleEffect(x: 1, y: 2, anchor: .center)
                            
                            // Percentage text
                            Text("\(Int(koValue))% K.O. Potential")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                        .padding(.vertical, 4)
                        
                        // Force value
                        if let force = metric.metric_values {
                            Text("Approximately \(force)")
                                .font(.subheadline)
                                .foregroundColor(.gray)
                        }
                    }
                } else if isBooleanMetric {
                    // Boolean indicator
                    HStack {
                        Image(systemName: booleanValue ? "checkmark.circle.fill" : "x.circle.fill")
                            .foregroundColor(booleanValue ? .green : .red)
                            .font(.title)
                        Text(booleanValue ? "Correct" : "Incorrect")
                            .foregroundColor(booleanValue ? .green : .red)
                            .font(.headline)
                    }
                    .padding(.vertical, 4)
                } else if isVelocityMetric {
                    if !shouldHideScore, let score = metric.metric_score {
                        Text("Score: \(String(format: "%.2f", score))")
                            .font(.subheadline)
                    }
                    
                    if let velocity = metric.metric_values, let tier = metric.tier {
                        HStack(spacing: 4) {
                            Text(velocity)
                                .font(.subheadline)
                            Text("•")
                                .foregroundColor(.gray)
                            Text(tier + " Tier")
                                .font(.subheadline)
                                .foregroundColor(tierColor(tier))
                        }
                    }
                } else {
                    // Regular metrics
                    if !shouldHideScore {
                        if let score = metric.metric_score {
                            Text("Score: \(String(format: "%.2f", score))")
                                .font(.subheadline)
                        }
                        
                        if let values = metric.metric_values {
                            Text("Value: \(values)")
                                .font(.subheadline)
                        }
                    }
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
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(12)
        .shadow(radius: 2)
    }
    
    private func formatTitle(_ title: String) -> String {
        return title.replacingOccurrences(of: "_", with: " ")
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
    let timingDifferences: [Int]?
    
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
                    let parts = sequence.components(separatedBy: "->")
                    ForEach(Array(parts.enumerated()), id: \.element) { index, part in
                        VStack(spacing: 4) {
                            Text(part.trimmingCharacters(in: .whitespaces))
                                .padding(.horizontal, 12)
                                .padding(.vertical, 8)
                                .background(Color(.systemGray5))
                                .cornerRadius(8)
                            
                            if index < parts.count - 1, let timingDifferences = timingDifferences, index < timingDifferences.count {
                                VStack(spacing: 2) {
                                    Image(systemName: "arrow.down")
                                        .foregroundColor(.red)
                                    Text("\(timingDifferences[index]) frames")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .padding(.vertical, 2)
                            }
                        }
                    }
                }
            }
        }
        .padding()
        .background(Color.blue.opacity(0.1))
        .cornerRadius(12)
    }
}
