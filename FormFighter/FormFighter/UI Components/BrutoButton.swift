import SwiftUI

struct BrutoButtonStyle: ButtonStyle {
    @ViewBuilder
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
    }
}

struct BrutoButton: View {
    
    // Public
    @Binding var text: String
    @State var backgroundColor: Color
    @State var accentColor: Color
    @State var shadowOpacity: CGFloat
    @State var strokeWidth: CGFloat
    var action: () -> Void
    
    // Private
    private let offset: CGFloat = 4
    @State private var tapped = false
    
    init(text: Binding<String>,
         backgroundColor: Color = .customBackground,
         accentColor: Color = .primary,
         shadowOpacity: CGFloat = 1,
         strokeWidth: CGFloat = 6,
         action: @escaping () -> Void = {}) {
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
                        
                        Text(text)
                            .foregroundColor(accentColor)
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

struct BrutoButton_Previews: PreviewProvider {
    static var previews: some View {
        BrutoButton(text: .constant("33"),
                    backgroundColor: .white,
                    strokeWidth: 8)
        .frame(maxWidth: 80, maxHeight: 80)
        .font(.system(.title, design: .rounded, weight: .black))
    }
}
