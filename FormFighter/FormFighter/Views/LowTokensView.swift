import SwiftUI

struct LowTokensView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var purchasesManager: PurchasesManager
    @State private var isProcessingPurchase = false
    @State private var errorMessage: String? = nil

    var body: some View {
        VStack(spacing: 20) {
            Text("You have 0 tokens")
                .font(.title)
                .foregroundColor(.white)
            Text("Buy a Premium One-Time Purchase and get 7 tokens.")
                .foregroundColor(.gray)
            if isProcessingPurchase {
                ProgressView()
            } else {
                Button(action: {
                    Task {
                        isProcessingPurchase = true
                        do {
                            try await purchasesManager.purchasePremiumOneTime()
                        } catch {
                            errorMessage = error.localizedDescription
                        }
                        isProcessingPurchase = false
                    }
                }, label: {
                    Text("Buy One-Time Purchase")
                        .padding()
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                })
            }
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .foregroundColor(.red)
            }
        }
        .padding()
        .background(Color.black)
        .edgesIgnoringSafeArea(.all)
    }
}

struct LowTokensView_Previews: PreviewProvider {
    static var previews: some View {
        LowTokensView()
            .environmentObject(UserManager.shared)
            .environmentObject(PurchasesManager.shared)
    }
} 