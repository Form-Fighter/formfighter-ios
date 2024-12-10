import SwiftUI

struct JabComparisonView: View {
    let currentScore: Double
    let currentExtension: Double
    let currentGuard: Double
    let currentRetraction: Double
    
    let bestScore: Double
    let bestExtension: Double
    let bestGuard: Double
    let bestRetraction: Double
    
    private func scoreColor(_ current: Double, _ best: Double) -> Color {
        if current > best { return .green }
        if current < best { return .red }
        return .primary
    }
    
    private func differenceText(_ current: Double, _ best: Double) -> String {
        let diff = current - best
        if abs(diff) < 0.1 { return "=" }
        return String(format: "%.1f", diff)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Compared with Your Best")
                .font(.headline)
                .padding(.bottom, 4)
            
            HStack(spacing: 20) {
                // Labels Column
                VStack(alignment: .leading, spacing: 16) {
                    Text("Overall")
                        .fontWeight(.medium)
                    Text("Extension")
                        .fontWeight(.medium)
                        .font(.caption)
                    Text("Guard")
                        .fontWeight(.medium)
                        .font(.caption)
                    Text("Retraction")
                        .fontWeight(.medium)
                        .font(.caption)
                }
                
                // Current Scores Column
                VStack(alignment: .trailing, spacing: 16) {
                    Text("Current")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    Text(String(format: "%.1f", currentScore))
                    Text(String(format: "%.1f", currentExtension))
                        .font(.subheadline)
                    Text(String(format: "%.1f", currentGuard))
                        .font(.subheadline)
                    Text(String(format: "%.1f", currentRetraction))
                        .font(.subheadline)
                }
                .foregroundColor(.primary)
                
                // Best Scores Column
                VStack(alignment: .trailing, spacing: 16) {
                    Text("Best")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    Text(String(format: "%.1f", bestScore))
                    Text(String(format: "%.1f", bestExtension))
                        .font(.subheadline)
                    Text(String(format: "%.1f", bestGuard))
                        .font(.subheadline)
                    Text(String(format: "%.1f", bestRetraction))
                        .font(.subheadline)
                }
                .foregroundColor(.secondary)
                
                // Difference Column
                VStack(alignment: .center, spacing: 16) {
                    Text("Diff")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.bottom, 4)
                    Text(differenceText(currentScore, bestScore))
                        .foregroundColor(scoreColor(currentScore, bestScore))
                    Text(differenceText(currentExtension, bestExtension))
                        .font(.subheadline)
                        .foregroundColor(scoreColor(currentExtension, bestExtension))
                    Text(differenceText(currentGuard, bestGuard))
                        .font(.subheadline)
                        .foregroundColor(scoreColor(currentGuard, bestGuard))
                    Text(differenceText(currentRetraction, bestRetraction))
                        .font(.subheadline)
                        .foregroundColor(scoreColor(currentRetraction, bestRetraction))
                }
                .fontWeight(.bold)
            }
        }
        .padding()
        .background(ThemeColors.primary.opacity(0.1))
        .cornerRadius(12)
    }
} 