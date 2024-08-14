import SwiftUI

struct CopiedToClipboardView: View {
    var body: some View {
        Text("Copied to Clipboard")
            .font(.special(.body, weight: .semibold))
            .foregroundStyle(.white)
            .padding()
            .background(Color.ruby.cornerRadius(16))
            .shadow(radius: 5)
            .padding(.bottom)
            .transition(.move(edge: .bottom))
            .frame(maxHeight: .infinity, alignment: .bottom)
    }
}

#Preview {
    CopiedToClipboardView()
}
