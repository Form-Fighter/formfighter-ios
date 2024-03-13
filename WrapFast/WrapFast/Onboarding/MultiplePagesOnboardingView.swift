import SwiftUI

struct MultiplePagesOnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var selectedTab = 0
    @State private var navigate = false
    
    // MARK: - Place in the array as many onboarding pages as you want.
    // Recommended 3 to 5 max. Don't overwhelm the user. Be clear and concise in your texts.
    @State private var pages: [MultiplePagesOnboardingFeatureModel] = [
        .init(imageName: "app-logo", title: "Welcome to 🌯\(Const.appName)⚡️!", description: ""),
        .init(imageName: "onboarding1", title: "Save time", description: "The easiest way of counting calories"),
        .init(imageName: "onboarding2", title: "Macros at one shot", description: "Just take a picture and check your meal's macros and calories"),
        .init(imageName: "onboarding3", title: "Store your meals", description: "Your meals securely stored in the cloud")
    ]
    
    init() {
        setupPageIndicatorColor()
    }
    
    private func setupPageIndicatorColor() {
        UIPageControl.appearance().currentPageIndicatorTintColor = .brand
        UIPageControl.appearance().pageIndicatorTintColor = UIColor.brand.withAlphaComponent(0.2)
    }
    
    var body: some View {
        ZStack {
            VStack(spacing: 24) {
                TabView(selection: $selectedTab) {
                    ForEach(Array(pages.enumerated()), id: \.element) { index, page in
                        MultiplePagesOnboardingFeature(model: page)
                            .tag(index)
                    }
                }
                .tabViewStyle(.page(indexDisplayMode: .always))
                
                RoundedButton(title: "Continue") {
                    advanceIfPossible()
                }
            }
            .padding(20)
        }
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
    
    private func advanceIfPossible() {
        if selectedTab < (pages.count - 1) {
            withAnimation {
                selectedTab += 1
            }
        } else {
            // MARK: - If you wish to end the onboarding here, rather than request review and authentication, just
            // remove the navigation below and uncomment hasCompletedOnboarding
            navigate.toggle()
//            hasCompletedOnboarding = true
        }
    }
}

#Preview {
    MultiplePagesOnboardingView()
}
