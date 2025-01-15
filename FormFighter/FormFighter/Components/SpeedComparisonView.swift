import SwiftUI

struct SpeedComparisonView: View {
    let extensionSpeed: Double
    let retractionSpeed: Double
    let title: String
    @State private var showingHelp = false
    
    private var speedDifference: Double {
        extensionSpeed - retractionSpeed
    }
    
    private var arrowSystemName: String {
        if abs(speedDifference) < 0.1 { return "equal.circle" }
        return speedDifference > 0 ? "arrow.up.circle.fill" : "arrow.down.circle.fill"
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.subheadline)
                    .fontWeight(.medium)
                
                Button {
                    showingHelp = true
                } label: {
                    Image(systemName: "info.circle")
                        .foregroundColor(.secondary)
                }
            }
            
            HStack {
                // Extension speed
                VStack(alignment: .leading) {
                    Text("Extension")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f m/s", extensionSpeed))
                        .font(.body)
                        .fontWeight(.medium)
                }
                
                Spacer()
                
                // Arrow indicator
                Image(systemName: arrowSystemName)
                    .foregroundColor(speedDifference > 0 ? .green : .red)
                
                Spacer()
                
                // Retraction speed
                VStack(alignment: .trailing) {
                    Text("Retraction")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(String(format: "%.1f m/s", retractionSpeed))
                        .font(.body)
                        .fontWeight(.medium)
                }
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .alert("Speed Comparison", isPresented: $showingHelp) {
            Button("OK", role: .cancel) { }
        } message: {
            Text("A slower retraction than extension speed may leave you vulnerable by creating gaps in your defense.")
        }
        .onAppear {
            print("""
            🔍 \(title) Values:
            - Extension: \(extensionSpeed)
            - Retraction: \(retractionSpeed)
            """)
        }
    }
}

