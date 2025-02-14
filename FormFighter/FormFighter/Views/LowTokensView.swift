import SwiftUI

struct LowTokensView: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var purchasesManager: PurchasesManager
    @State private var isProcessingPurchase = false
    @State private var errorMessage: String? = nil
    @State private var animateGradient = false

    var body: some View {
        ZStack {
            // Animated background using custom colors that fit the app aesthetic.
            LinearGradient(
                gradient: Gradient(colors: [Color("PrimaryColor"), Color("SecondaryColor")]),
                startPoint: animateGradient ? .topLeading : .bottomTrailing,
                endPoint: animateGradient ? .bottomTrailing : .topLeading
            )
            .animation(
                Animation.linear(duration: 10)
                    .repeatForever(autoreverses: true),
                value: animateGradient
            )
            .onAppear {
                animateGradient.toggle()
            }
            .edgesIgnoringSafeArea(.all)
            
            VStack(spacing: 30) {
                // Title and token count with token symbols.
                VStack {
                    Text("Your Token Bank")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .foregroundColor(.white)
                        .shadow(radius: 3)
                    
                    HStack(alignment: .center, spacing: 8) {
                        // Use a diamond emoji as a token symbol.
                        Text("💎")
                            .font(.title)
                        Text("\(userManager.user?.tokens ?? 0) 🔸")
                            .font(.title2)
                            .fontWeight(.semibold)
                            .foregroundColor(.white)
                    }
                }
                
                // Purchase instruction message.
                Text("Buy 5 tokens and get back to punching!")
                    .font(.headline)
                    .foregroundColor(.white)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal)
                
                // Display a progress indicator while processing, or else show the CTA.
                if isProcessingPurchase {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: .white))
                } else {
                    Button {
                        Task {
                            isProcessingPurchase = true
                            do {
                                try await purchasesManager.purchasePremiumOneTime()
                            } catch {
                                errorMessage = error.localizedDescription
                            }
                            isProcessingPurchase = false
                        }
                    } label: {
                        Text("Buy Now")
                            .font(.headline)
                            .padding()
                            .frame(maxWidth: .infinity)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color("AccentColor"), Color("ButtonColor")]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(10)
                            .shadow(color: Color.black.opacity(0.3), radius: 5, x: 0, y: 3)
                            .padding(.horizontal)
                    }
                }
                
                // Display error message if there's an issue.
                if let errorMessage = errorMessage {
                    Text(errorMessage)
                        .foregroundColor(.red)
                        .padding(.horizontal)
                        .multilineTextAlignment(.center)
                }
            }
            .padding()
        }
    }
}

struct LowTokensView_Previews: PreviewProvider {
    static var previews: some View {
        LowTokensView()
            .environmentObject(UserManager.shared)
            .environmentObject(PurchasesManager.shared)
    }
} 