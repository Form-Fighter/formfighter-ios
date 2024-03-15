import SwiftUI

struct BrutoImageButton: View {
    
    // Public
    @State var image: Image
    @State var imagePrimaryColor: Color
    @State var imageSecondaryColor: Color
    @Binding var text: String
    @State var backgroundColor: Color
    @State var accentColor: Color
    @State var shadowOpacity: CGFloat
    @State var strokeWidth: CGFloat
    var action: () -> Void
    
    // Private
    private let offset: CGFloat = 4
    @State private var tapped = false
    
    init(image: Image,
         imagePrimaryColor: Color = .primary,
         imageSecondaryColor: Color = .secondary,
         text: Binding<String>,
         backgroundColor: Color = .customBackground,
         accentColor: Color = .primary,
         shadowOpacity: CGFloat = 1,
         strokeWidth: CGFloat = 6,
         action: @escaping () -> Void = {}) {
        self.image = image
        self.imagePrimaryColor = imagePrimaryColor
        self.imageSecondaryColor = imageSecondaryColor
        _text = text
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
            Rectangle()
                .background(backgroundColor).opacity(shadowOpacity)
                .cornerRadius(5)
                .offset(x: tapped ? 0 : offset, y: tapped ? 0 : offset)
                .overlay(
                    ZStack {
                        Rectangle()
                            .stroke(accentColor, lineWidth: strokeWidth)
                            .background(backgroundColor)
                            .cornerRadius(5)
                        
                        HStack(spacing: 8) {
                            image
                                .resizable()
                                .scaledToFit()
                                .frame(maxWidth: 30, maxHeight: 30)
                                .fontWeight(.medium)
                                .foregroundStyle(imagePrimaryColor, imageSecondaryColor)
                            
                            Text(text)
                                .foregroundColor(accentColor)
                        }
                        .padding(.horizontal)
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
    BrutoImageButton(image: .init(systemName: "apple.logo"), text: .constant("Button with Image"))
        .frame(width: 250, height: 50)
        .font(.system(.title3, design: .rounded, weight: .bold))
}
