import SwiftUI

struct UnlockPremiumView: View {
    @State var color: Color = .ruby
    
    var body: some View {
        ZStack {
            HStack(spacing: 0) {
                Image(systemName: "lock.open")
                    .font(.system(size: 30, weight: .semibold))
                Text("Unlock Premium")
                    .font(.special(.title2, weight: .bold))
                    .padding()
            }
        }
        .frame(maxWidth: .infinity, maxHeight: 96)
        .background(color.gradient)
        .cornerRadius(28)
        .shadow(radius: 10)
    }
}

#Preview {
    UnlockPremiumView()
}
