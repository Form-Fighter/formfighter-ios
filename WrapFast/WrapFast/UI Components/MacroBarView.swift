import SwiftUI

struct MacroBarView: View {
    @State var value: Int
    @State var name: String
    @State var height: CGFloat
    @State var barColor: Color
    @State var startAnimations = false
    
    var body: some View {
        VStack {
            Text("\(value)g")
            RoundedRectangle(cornerRadius: 8)
                .frame(width: 48, height: startAnimations ? height : 5)
                .foregroundStyle(barColor.gradient)
            Text(name)
        }
        .font(.special(.body, weight: .bold))
        .onAppear {
            DispatchQueue.main.async {
                withAnimation(.snappy(duration: 1).delay(0.4)) {
                    startAnimations = true
                }
            }
        }
    }
}

#Preview {
    MacroBarView(value: 42, name: "Carbs", height: 160, barColor: .red)
}
