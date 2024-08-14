import SwiftUI

struct CircularProgressView: View {
    @Binding var progress: Double
    var lineWidth: CGFloat = 10
    var color: Color = .accentColor
    var showPercentage = true
    
    var body: some View {
        ZStack {
            Circle()
                .stroke(
                    color.opacity(0.5),
                    lineWidth: lineWidth
                )
            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    color,
                    style: StrokeStyle(
                        lineWidth: lineWidth,
                        lineCap: .round
                    )
                )
                .rotationEffect(.degrees(-90))
                .animation(.snappy(duration: 0.6), value: progress)
            
            if showPercentage {
                Text(progress.percentageString)
            }
        }
    }
}

#Preview {
    // Changing progress does not work on Preview, but it does in a real View.
    @State var progress = 0.33
    
    return ZStack {
        VStack {
            CircularProgressView(progress: $progress, lineWidth: 15, color: .red, showPercentage: true)
                .font(.special(.title, weight: .bold))
                .frame(width: 150)
            
            Button("Change progress") {
                progress = 0.75
            }
        }
    }
}
