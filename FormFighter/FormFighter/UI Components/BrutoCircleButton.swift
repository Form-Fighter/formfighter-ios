import SwiftUI

struct BrutoCircleButton: View {
    
    // Public
    @Binding var text: String?
    @Binding var image: Image?
    @State var backgroundColor: Color
    @State var accentColor: Color
    @State var shadowOpacity: CGFloat
    @State var strokeWidth: CGFloat
    var action: () -> Void
    
    // Private
    private let offset: CGFloat = 5
    @State private var tapped = false
    
    init(text: Binding<String?> = .constant(nil),
         image: Binding<Image?> = .constant(nil),
         backgroundColor: Color = .customBackground,
         accentColor: Color = .primary,
         shadowOpacity: CGFloat = 1,
         strokeWidth: CGFloat = 5,
         action: @escaping () -> Void = {}) {
        _text = text
        _image = image
        self.backgroundColor = backgroundColor
        self.accentColor = accentColor
        self.shadowOpacity = shadowOpacity
        self.strokeWidth = strokeWidth
        self.action = action
    }
    
    var body: some View {
        Button {
            action()
        } label: {
            Circle()
                .fill(accentColor.opacity(shadowOpacity))
                .offset(x: tapped ? 0 : offset, y: tapped ? 0 : offset)
            
                .overlay(
                    ZStack {
                        Circle()
                            .fill(backgroundColor)
                            .overlay{
                                Circle()
                                    .stroke(accentColor, lineWidth: strokeWidth)
                            }
                        
                        if let image {
                            image
                                .fontWeight(.medium)
                        } else if let text {
                            Text(text)
                                .foregroundColor(accentColor)
                        }
                    }
                )
                .offset(x: tapped ? offset : 0, y: tapped ? offset : 0)
        }
        .buttonStyle(BrutoButtonStyle())
        ._onButtonGesture { _ in
            Haptic.shared.selectionChanged()
            tapped.toggle()
        } perform: {
            Haptic.shared.selectionChanged()
        }
    }
}

#Preview {
    BrutoCircleButton(text: .constant("OK"))
        .frame(width: 80)
        .font(.system(size: 30))
        .fontWeight(.black)
}
