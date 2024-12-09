import SwiftUI

struct BadgeCelebrationView: View {
    let badge: Badge
    @Binding var isPresented: Bool
    @State private var scale: CGFloat = 0.5
    @State private var opacity: Double = 0
    
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: badge.iconName)
                .font(.system(size: 60))
                .foregroundColor(.brand)
            
            Text("New Badge Earned!")
                .font(.title2.bold())
            
            Text(badge.name)
                .font(.headline)
            
            Text(badge.description)
                .font(.body)
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
            
            Button("Awesome!") {
                withAnimation {
                    isPresented = false
                }
            }
            .buttonStyle(.bordered)
            .tint(.brand)
        }
        .padding()
        .background(Color(UIColor.systemBackground))
        .cornerRadius(20)
        .shadow(radius: 10)
        .scaleEffect(scale)
        .opacity(opacity)
        .onAppear {
            withAnimation(.spring()) {
                scale = 1
                opacity = 1
            }
        }
    }
} 