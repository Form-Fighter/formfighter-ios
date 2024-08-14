import SwiftUI
import StoreKit

struct RequestReviewView: View {
    @Environment(\.requestReview) var requestReview
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State var navigate = false
    @State var buttonPressed = false
    
    // MARK: This delay is to give time to the users to do the review rather than
    //leaving them to another view instantly. You can tweak it as you want.
    @State var advanceToNextViewDelay: CGFloat = 2
    
    var body: some View {
        VStack {
            Text("Help Us Grow")
                .minimumScaleFactor(0.7)
                .font(.special(.largeTitle, weight: .bold))
                .padding()
            
            HeartView(heartColor: Color.ruby, showPulses: false)
                .ignoresSafeArea()
                .padding(.vertical)
                .frame(width: UIScreen.width, height: UIScreen.width)
                .fixedSize(horizontal: true, vertical: true)
            
            Text("Show your love by giving as a review on the App Store")
                .font(.special(.title2, weight: .regular))
                .minimumScaleFactor(0.7)
                .multilineTextAlignment(.center)
                .lineLimit(/*@START_MENU_TOKEN@*/2/*@END_MENU_TOKEN@*/)
                .padding(.horizontal)
        }
        .navigationBarBackButtonHidden()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.customBackground)
        .navigationDestination(isPresented: $navigate, destination: {
            LoginView(showPaywallInTheOnboarding: true)
        })
        .safeAreaInset(edge: .bottom, content: {
            ZStack {
                RoundedButton(title: buttonPressed ? "" : "Continue") {
                    buttonPressed = true
                    requestReview()
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + advanceToNextViewDelay, execute: {
                        buttonPressed = false
                        // MARK: - If you wish to end the onboarding here, rather than request authentication, just
                        // remove the navigation below and uncomment hasCompletedOnboarding
                        navigate.toggle()
                        // hasCompletedOnboarding = true
                    })
                }
                .padding()
                
                if buttonPressed {
                    ProgressView()
                        .offset(y: -50)
                }
            }
        })
    }
}

#Preview {
    RequestReviewView()
}
