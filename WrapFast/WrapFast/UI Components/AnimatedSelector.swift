import SwiftUI

struct AnimatedSelector: View {
    
    // Change this model for the proper case you need.
    @Binding var selectedType: AnimatedSelectorType
    
    // This boolean is used to disable the animated hand
    @State var touchedAnySocialMedia = false
    
    // You can tweak these values up to your needs
    @State var handOffset: CGFloat = -10
    @State var logosRotation: CGFloat = 45
    @State var logosYOffset: CGFloat = 16
    
    var body: some View {
        HStack {
            Spacer()
            ForEach(AnimatedSelectorType.allCases, id: \.self) { type in
                
                Image(type.iconName)
                    .resizable()
                    .scaledToFit()
                    .frame(maxHeight: 52)
                    .cornerRadius(8)
                    .opacity(type == selectedType ? 1 : 0.2)
                    .scaleEffect(type == selectedType ? 1 : 0.8)
                    .rotationEffect(.degrees(type == selectedType ? 0 : getLogosRotation(for: type)))
                    .offset(y: type == selectedType ? 0 : getLogosYOffset(for: type))
                    .onTapGesture {
                        Haptic.shared.lightImpact()
                        DispatchQueue.main.async {
                            withAnimation(.bouncy(duration: 0.3)) {
                                touchedAnySocialMedia = true
                                selectedType = type
                            }}
                        
                    }
                Spacer()
            }
        }
        .padding(.vertical)
        .overlay {
            
            if !touchedAnySocialMedia {
                ZStack(alignment: .bottomTrailing) {
                    Text("👆")
                        .font(.system(.largeTitle))
                        .rotationEffect(Angle(degrees: -25))
                        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomTrailing)
                        .offset(x: -20, y: handOffset)
                    
                }
                .transition(.opacity)
            }
        }
        .onAppear {
            DispatchQueue.main.async {
                withAnimation(.easeInOut(duration: 1.5).repeatForever()) {
                    handOffset = 10
                }
            }
        }
    }
    
    func getLogosRotation(for type: AnimatedSelectorType) -> CGFloat {
        let index = AnimatedSelectorType.allCases.firstIndex(of: type) ?? 0
        return (index % 2 == 0) ? -logosRotation : logosRotation
    }
    
    func getLogosYOffset(for type: AnimatedSelectorType) -> CGFloat {
        let index = AnimatedSelectorType.allCases.firstIndex(of: type) ?? 0
        return (index % 2 == 0) ? -logosYOffset : logosYOffset
    }
}

// Change this model for the proper case you need.
enum AnimatedSelectorType: String, CaseIterable {
    case instagram
    case twitter
    case facebook
    case linkedin
    case tinder
    
    // Change names up to your needs
    var name: String {
        switch self {
        case .instagram:
            "Instagram"
        case .twitter:
            "Twitter"
        case .facebook:
            "Facebook"
        case .linkedin:
            "LinkedIn"
        case .tinder:
            "Tinder"
        }
    }
    
    // These are the icon asset names. Change them up to your needs.
    var iconName: String {
        switch self {
        case .instagram:
            "instagram"
        case .twitter:
            "x-icon"
        case .facebook:
            "facebook"
        case .linkedin:
            "linkedin"
        case .tinder:
            "tinder"
        }
    }
}

// How to use it: we pass a State variable as parameter to the Binding property of the subview
private struct AnimatedSelectorPreviewContainer : View {
    @State private var animatedSelectorType: AnimatedSelectorType = .instagram
    
    var body: some View {
        AnimatedSelector(selectedType: $animatedSelectorType)
    }
}

#Preview {
    AnimatedSelectorPreviewContainer()
}
