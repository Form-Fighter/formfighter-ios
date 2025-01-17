import SwiftUI

struct DrawerSection<Content: View>: View {
    let title: String
    let content: Content
    @State private var isExpanded = false
    @State private var isAnimating = false
    
    init(title: String, @ViewBuilder content: () -> Content) {
        self.title = title
        self.content = content()
    }
    
    var body: some View {
        VStack {
            Button(action: {
                guard !isAnimating else { return }
                isAnimating = true
                
                withAnimation(.easeInOut(duration: 0.5)) {
                    isExpanded.toggle()
                }
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    isAnimating = false
                }
            }) {
                HStack {
                    Text(title)
                        .font(.headline)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .rotationEffect(.degrees(isExpanded ? 90 : 0))
                }
                .padding()
                .background(Color(.systemBackground))
                .cornerRadius(10)
            }
            
            if isExpanded {
                content
                    .padding(.horizontal)
                    .padding(.top, 16)
                    .transition(.move(edge: .top).combined(with: .opacity))
            }
        }
    }
}