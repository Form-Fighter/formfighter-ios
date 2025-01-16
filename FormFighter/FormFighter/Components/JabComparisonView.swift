import SwiftUI

struct JabComparisonView: View {
    @Binding var compareWithLastPunch: Bool
    
    // Current punch metrics
    let handVelocityExtension: Double
    let handVelocityRetraction: Double
    let footVelocityExtension: Double
    let footVelocityRetraction: Double
    let powerGeneration: Double
    
    // Comparison metrics (either last punch or average)
    let comparisonHandVelocityExtension: Double
    let comparisonHandVelocityRetraction: Double
    let comparisonFootVelocityExtension: Double
    let comparisonFootVelocityRetraction: Double
    let comparisonPowerGeneration: Double
    
    private func calculatePercentageChange(_ current: Double, _ comparison: Double) -> Double {
        guard comparison != 0 else { return 0 }
        return ((current - comparison) / comparison) * 100
    }
    
    private func formatPercentage(_ value: Double) -> String {
        if abs(value) < 0.1 { return "=" }
        return String(format: "%+.1f%%", value)
    }
    
    private var hasLastPunchData: Bool {
        compareWithLastPunch && 
        comparisonHandVelocityExtension == 0 && 
        comparisonHandVelocityRetraction == 0 && 
        comparisonFootVelocityExtension == 0 && 
        comparisonFootVelocityRetraction == 0
    }
    
    private func formatSpeed(_ speed: Double) -> String {
        if speed == 0 { return "N/A" }
        return String(format: "%.1f m/s", speed)
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Title and Toggle
            HStack {
                Text("Performance Comparison")
                    .font(.headline)
                Spacer()
                VStack(alignment: .trailing) {
                    Text(compareWithLastPunch ? "vs Last Punch" : "vs Average")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Toggle("Compare with last punch", isOn: $compareWithLastPunch)
                        .labelsHidden()
                }
            }
            .padding(.bottom, 4)
            
            if hasLastPunchData {
                Text("No previous punch data available")
                    .foregroundColor(.secondary)
                    .italic()
                    .padding(.vertical)
            } else {
                // Hands Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lead Hand")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Extension")
                                .font(.caption)
                            Text(formatSpeed(handVelocityExtension))
                                .fontWeight(.medium)
                            Text(formatPercentage(calculatePercentageChange(
                                handVelocityExtension,
                                comparisonHandVelocityExtension
                            )))
                            .foregroundColor(handVelocityExtension >= comparisonHandVelocityExtension ? .green : .red)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Retraction")
                                .font(.caption)
                            Text(formatSpeed(handVelocityRetraction))
                                .fontWeight(.medium)
                            Text(formatPercentage(calculatePercentageChange(
                                handVelocityRetraction,
                                comparisonHandVelocityRetraction
                            )))
                            .foregroundColor(handVelocityRetraction >= comparisonHandVelocityRetraction ? .green : .red)
                        }
                    }
                }
                
                // Lead Foot Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Lead Foot")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        VStack(alignment: .leading) {
                            Text("Extension")
                                .font(.caption)
                            Text(formatSpeed(footVelocityExtension))
                                .fontWeight(.medium)
                            Text(formatPercentage(calculatePercentageChange(
                                footVelocityExtension,
                                comparisonFootVelocityExtension
                            )))
                            .foregroundColor(footVelocityExtension >= comparisonFootVelocityExtension ? .green : .red)
                        }
                        Spacer()
                        VStack(alignment: .trailing) {
                            Text("Retraction")
                                .font(.caption)
                            Text(formatSpeed(footVelocityRetraction))
                                .fontWeight(.medium)
                            Text(formatPercentage(calculatePercentageChange(
                                footVelocityRetraction,
                                comparisonFootVelocityRetraction
                            )))
                            .foregroundColor(footVelocityRetraction >= comparisonFootVelocityRetraction ? .green : .red)
                        }
                    }
                }
                
                // Power Generation Section
                VStack(alignment: .leading, spacing: 8) {
                    Text("Power Generation")
                        .font(.subheadline)
                        .fontWeight(.medium)
                    
                    HStack {
                        Text(String(format: "%.1f N", powerGeneration))
                            .fontWeight(.medium)
                        Text(formatPercentage(calculatePercentageChange(
                            powerGeneration,
                            comparisonPowerGeneration
                        )))
                        .foregroundColor(powerGeneration >= comparisonPowerGeneration ? .green : .red)
                    }
                }
            }
        }
        .padding()
        .background(ThemeColors.primary.opacity(0.1))
        .cornerRadius(12)
    }
} 