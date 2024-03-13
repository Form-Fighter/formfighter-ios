import SwiftUI

struct OnePageOnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var navigate = false
    
    var body: some View {
        ZStack {
            VStack {
                Spacer()
                Text("Welcome to\n🌯\(Const.appName)⚡️")
                    .font(.special(.largeTitle, weight: .black))
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 24)
                
                //MARK: - List your features. Be simple, don't overwhelm the user.
                //Use systemImages or pass your custom Image as parameter.
                VStack(alignment: .leading, spacing: 16) {
                    OnboardingFeature(image: Image(systemName: "clock"),
                                      imageColor: .brand,
                                      title: "Save time",
                                      description: "The easiest way of counting calories")
                    OnboardingFeature(image: Image(systemName: "camera"),
                                      imageColor: .ruby,
                                      title: "Macros at one shot",
                                      description: "Just take a picture and check your meal's macros and calories")
                    OnboardingFeature(image: Image(systemName: "cloud"),
                                      imageColor: .blue,
                                      title: "Store your meals",
                                      description: "Your meals securely stored in the cloud")
                }
                .frame(maxWidth: /*@START_MENU_TOKEN@*/.infinity/*@END_MENU_TOKEN@*/, alignment: .leading)
                
                Spacer()
                
                RoundedButton(title: "Continue") {
                    Haptic.shared.lightImpact()
                    // MARK: - If you wish to end the onboarding here, rather than request review and authentication, just
                    // remove the navigation below and uncomment hasCompletedOnboarding
                    navigate.toggle()
                    // hasCompletedOnboarding = true
                }
            }
            .padding(40)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.customBackground)
        .navigationDestination(isPresented: $navigate) {
            // MARK: - If you want to skip request review and navigate directly to LoginView or
            // any other view, just comment the line below and add the proper view you wish.
            // Even that requesting the review without trying the app could feel dumb, evidences
            // have demonstrated that this converts so much:
            // https://x.com/evgeniymikholap/status/1714612296117608571?s=20
            // Other strategy is requesting review after a success moment. For example in a to-do list app,
            // after completing one ore several tasks.
            // It's important to know that you only have 3 ATTEMPTS PER YEAR to request a review, so place them wisely.
            RequestReviewView()
        }
    }
}

#Preview {
    OnePageOnboardingView()
}
