import SwiftUI

struct OnboardingSurveyStep {
    let title: String
    let questions: [SurveyQuestion]
    let stepNumber: Int
}

struct SurveyQuestion {
    let question: String
    let options: [String]
    let allowsMultipleSelection: Bool
    let isOpenEnded: Bool
}

struct SurveyResponse {
    let questionId: String
    var answers: Set<String>
}

struct OnePageOnboardingView: View {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @State private var currentStep = 0
    @State private var showPaywall = false
    @State private var selectedAnswers: [String: Set<String>] = [:]
    @State private var openEndedResponse: String = ""
    @State private var animateBackground = false
    @State private var insightPage = 1 // 1 = insights, 2 = comparison
    
    let surveySteps = [
        OnboardingSurveyStep(
            title: "Your Goals",
            questions: [
                SurveyQuestion(
                    question: "Why are you here?",
                    options: ["To perfect my technique", "To improve my fitness", "To perform better in sparring/fights", "Other"],
                    allowsMultipleSelection: false,
                    isOpenEnded: false
                )
            ],
            stepNumber: 1
        ),
        OnboardingSurveyStep(
            title: "Experience Level",
            questions: [
                SurveyQuestion(
                    question: "How long have you been training?",
                    options: ["Less than 6 months", "6 months to 1 year", "1–3 years", "Over 3 years"],
                    allowsMultipleSelection: false,
                    isOpenEnded: false
                )
            ],
            stepNumber: 2
        ),
        OnboardingSurveyStep(
            title: "Training Background",
            questions: [
                SurveyQuestion(
                    question: "What discipline(s) do you train?",
                    options: ["Muay Thai", "Boxing", "MMA", "Other"],
                    allowsMultipleSelection: true,
                    isOpenEnded: false
                )
            ],
            stepNumber: 3
        ),
        OnboardingSurveyStep(
            title: "Feedback Experience",
            questions: [
                SurveyQuestion(
                    question: "How often do you get feedback on your technique?",
                    options: ["Never", "1–2 times per month", "Weekly", "Multiple times per week"],
                    allowsMultipleSelection: false,
                    isOpenEnded: false
                )
            ],
            stepNumber: 4
        ),
        OnboardingSurveyStep(
            title: "Training Investment",
            questions: [
                SurveyQuestion(
                    question: "How much do you spend monthly on gym classes?",
                    options: ["Less than $50", "$50–$100", "$100–$200", "Over $200"],
                    allowsMultipleSelection: false,
                    isOpenEnded: false
                ),
                SurveyQuestion(
                    question: "How much do you spend monthly on private coaching?",
                    options: ["$0 (No private coaching)", "$100–$200", "$200–$400", "Over $400"],
                    allowsMultipleSelection: false,
                    isOpenEnded: false
                )
            ],
            stepNumber: 5
        ),
        // OnboardingSurveyStep(
        //     title: "Personal Impact",
        //     questions: [
        //         SurveyQuestion(
        //             question: "What have you noticed since focusing on your technique?",
        //             options: [],
        //             allowsMultipleSelection: false,
        //             isOpenEnded: true
        //         )
        //     ],
        //     stepNumber: 6
        // )
    ]
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // Premium animated background
                BackgroundView(animate: $animateBackground)
                
                VStack(spacing: 0) {
                    if currentStep == 0 {
                        welcomeView
                    } else if currentStep <= surveySteps.count {
                        surveyStepView(step: surveySteps[currentStep - 1])
                            .transition(.asymmetric(
                                insertion: .move(edge: .trailing).combined(with: .opacity),
                                removal: .move(edge: .leading).combined(with: .opacity)
                            ))
                    } else {
                        insightsView
                            .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
            }
        }
        .ignoresSafeArea()
    }
    
    private var welcomeView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 40) {
                LogoSection(animateBackground: $animateBackground)
                
                WelcomeTextSection()
                
                WelcomeButtonSection(action: {
                    withAnimation {
                        currentStep += 1
                    }
                })
                
                Button("Skip") {
                    hasCompletedOnboarding = true 
                }
                .foregroundColor(.white.opacity(0.6))
                .padding(.top, 8)
                
                Spacer()
                    .frame(height: 20)
            }
        }
    }
    
    // Break out the logo section
    private struct LogoSection: View {
        @Binding var animateBackground: Bool
        
        var body: some View {
            ZStack {
                // Animated rings
                AnimatedRings(animate: animateBackground)
                
                // New App Logo
                Image("app-logo-new")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 180, height: 180)
                    .shadow(color: .brand.opacity(0.5), radius: 20, x: 0, y: 10)
            }
            .onAppear { animateBackground = true }
        }
    }
    
    // Animated rings component
    private struct AnimatedRings: View {
        let animate: Bool
        
        var body: some View {
            ForEach(0..<3) { i in
                Circle()
                    .stroke(Color.brand.opacity(0.5), lineWidth: 1)
                    .frame(width: 220 + CGFloat(i * 40), height: 220 + CGFloat(i * 40))
                    .scaleEffect(animate ? 1.1 : 1.0)
                    .animation(
                        .easeInOut(duration: 1.5)
                        .repeatForever(autoreverses: true)
                        .delay(Double(i) * 0.2),
                        value: animate
                    )
            }
        }
    }
    
    // Text section component
    private struct WelcomeTextSection: View {
        var body: some View {
            VStack(spacing: 24) {
                GeometryReader { geometry in
                    Text("Welcome to\nForm Fighter")
                        .font(.special(.extraLargeTitle, weight: .black))
                        .minimumScaleFactor(0.5)
                        .multilineTextAlignment(.center)
                        .foregroundStyle(.linearGradient(
                            colors: [.white, .white.opacity(0.8)],
                            startPoint: .top,
                            endPoint: .bottom
                        ))
                        .frame(
                            width: geometry.size.width,
                            height: geometry.size.height,
                            alignment: .center
                        )
                }
                .frame(height: 120)
                
                Text("Let's tailor your experience to help you master your technique.")
                    .font(.special(.title3, weight: .medium))
                    .multilineTextAlignment(.center)
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal, 24)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.horizontal)
        }
    }
    
    // Button section component
    private struct WelcomeButtonSection: View {
        let action: () -> Void
        
        var body: some View {
            Button(action: action) {
                Text("Start Your Journey")
                    .font(.special(.title3, weight: .bold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 60)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.brand)
                            .overlay(
                                RoundedRectangle(cornerRadius: 16)
                                    .stroke(Color.white.opacity(0.3), lineWidth: 1)
                            )
                            .shadow(color: .brand.opacity(0.5), radius: 20, x: 0, y: 10)
                    )
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
    }
    
    private func surveyStepView(step: OnboardingSurveyStep) -> some View {
        VStack(spacing: 24) {
            ProgressView(value: Double(step.stepNumber), total: Double(surveySteps.count))
                .tint(.brand)
            
            Text("Step \(step.stepNumber) of \(surveySteps.count)")
                .font(.subheadline)
                .foregroundColor(.secondary)
            
            Text(step.title)
                .font(.special(.title2, weight: .bold))
                .foregroundColor(.white)
            
            ScrollView {
                VStack(spacing: 20) {
                    ForEach(step.questions, id: \.question) { question in
                        QuestionView(
                            question: question,
                            selectedAnswers: $selectedAnswers,
                            openEndedResponse: $openEndedResponse
                        )
                    }
                }
            }
            
            RoundedButton(title: "Continue") {
                withAnimation {
                    if step.stepNumber == surveySteps.count {
                        currentStep = surveySteps.count + 1 // Show insights
                        hasCompletedOnboarding = true // Set onboarding as completed
                    } else {
                        currentStep += 1
                    }
                }
            }
            .buttonStyle(PrimaryButtonStyle())
            .disabled(!isStepValid(step))
        }
        .padding(24)
    }
    
    private var insightsView: some View {
        ScrollView(showsIndicators: false) {
            VStack(spacing: 24) {
                // Simplified savings message
                Text("With Form Fighter, you'll save")
                    .font(.special(.title, weight: .bold))
                    .multilineTextAlignment(.center)
                    .padding(.top)
                
                // Large savings amount
                if let savings = calculateSavings() {
                    Text("$\(savings)")
                        .font(.system(size: 64, weight: .heavy))
                        .foregroundColor(.brand)
                        .padding(.vertical, 8)
                }
                
                Text("per year")
                    .font(.special(.title3, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
                
                // Comparison table
                ComparisonTableView()
                    .padding(.top, 24)
                
                // CTA Button
                RoundedButton(title: "Get Started Now") {
                    hasCompletedOnboarding = true
                }
                .buttonStyle(PremiumButtonStyle())
                .padding(.horizontal)
                .padding(.vertical, 24)
            }
            .padding(.horizontal)
        }
    }
    
    // New helper method to calculate savings
    private func calculateSavings() -> Int? {
        if let monthlyCoaching = selectedAnswers["How much do you spend monthly on private coaching?"]?.first {
            let yearlyCoachingSpending = calculateYearlyCoachingSpending(from: monthlyCoaching)
            let yearlyAppCost = 780 // $14.99 * 52 weeks
            return yearlyCoachingSpending - yearlyAppCost
        }
        return nil
    }
    
    private func isStepValid(_ step: OnboardingSurveyStep) -> Bool {
        for question in step.questions {
            if question.isOpenEnded {
                if openEndedResponse.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    return false
                }
            } else {
                let answers = selectedAnswers[question.question] ?? Set<String>()
                if answers.isEmpty {
                    return false
                }
            }
        }
        return true
    }
    
    private func generateInsights() -> [String] {
        var insights: [String] = []
        
        // Calculate yearly costs based on user's actual spending
        if let monthlyGymSpending = selectedAnswers["How much do you spend monthly on gym classes?"]?.first,
           let monthlyCoaching = selectedAnswers["How much do you spend monthly on private coaching?"]?.first {
            
            let yearlyGymSpending = calculateYearlySpending(from: monthlyGymSpending)
            let yearlyCoachingSpending = calculateYearlyCoachingSpending(from: monthlyCoaching)
            let totalYearlySpending = yearlyGymSpending + yearlyCoachingSpending
            
            insights.append("You currently invest $\(totalYearlySpending) per year in your training.")
            
            // Our app costs
            let monthlyFeedbackCost = 60 // Our monthly subscription cost
            let yearlyAppCost = monthlyFeedbackCost * 12
            
            if monthlyCoaching == "$0 (No private coaching)" {
                // They don't have coaching, show potential value
                let potentialPrivateSessionCost = 100 // Average cost of a private session
                let yearlyPrivateSessions = 24 // Assuming twice monthly private sessions
                let yearlyPotentialCost = potentialPrivateSessionCost * yearlyPrivateSessions
                
                insights.append("Private coaching typically costs $\(yearlyPotentialCost)/year for twice-monthly sessions.")
                insights.append("With Form Fighter, you'll get unlimited feedback for just $\(yearlyAppCost)/year, saving you $\(yearlyPotentialCost - yearlyAppCost) compared to private coaching.")
            } else {
                // They have coaching, show actual savings
                let actualSavings = yearlyCoachingSpending - yearlyAppCost
                insights.append("You currently spend $\(yearlyCoachingSpending) per year on private coaching.")
                insights.append("With Form Fighter, you'll get unlimited feedback for just $\(yearlyAppCost)/year, saving you $\(actualSavings).")
            }
        }
        
        // Training experience insight
        if let trainingDuration = selectedAnswers["How long have you been training?"]?.first {
            insights.append("With \(trainingDuration.lowercased()) of training, you understand the importance of proper technique.")
        }
        
        // Feedback frequency insight
        if let feedbackFrequency = selectedAnswers["How often do you get feedback on your technique?"]?.first {
            if feedbackFrequency == "Never" || feedbackFrequency == "1–2 times per month" {
                insights.append("You're currently getting limited feedback. Form Fighter can provide instant feedback whenever you need it.")
            } else {
                insights.append("You actively seek feedback to improve. Form Fighter makes this even easier with 24/7 availability.")
            }
        }
        
        return insights
    }
    
    private func calculateYearlySpending(from monthlySpending: String) -> Int {
        let monthlyAmount: Int
        switch monthlySpending {
        case "Less than $50":
            monthlyAmount = 50
        case "$50–$100":
            monthlyAmount = 75
        case "$100–$200":
            monthlyAmount = 150
        case "Over $200":
            monthlyAmount = 250
        default:
            monthlyAmount = 100
        }
        return monthlyAmount * 12
    }
    
    private func calculateYearlyCoachingSpending(from monthlyCoaching: String) -> Int {
        let monthlyAmount: Int
        switch monthlyCoaching {
        case "$0 (No private coaching)":
            monthlyAmount = 0
        case "$100–$200":
            monthlyAmount = 150
        case "$200–$400":
            monthlyAmount = 300
        case "Over $400":
            monthlyAmount = 500
        default:
            monthlyAmount = 0
        }
        return monthlyAmount * 12
    }
    
    // ... Add other views and helper methods ...
}


struct PrimaryButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.brand)
            .cornerRadius(12)
            .opacity(configuration.isPressed ? 0.8 : 1.0)
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
    }
}

struct QuestionView: View {
    let question: SurveyQuestion
    @Binding var selectedAnswers: [String: Set<String>]
    @Binding var openEndedResponse: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(question.question)
                .font(.special(.title3, weight: .bold))
                .foregroundColor(.white)
                .padding(.bottom, 4)
            
            if question.isOpenEnded {
                TextEditor(text: $openEndedResponse)
                    .frame(height: 100)
                    .padding(8)
                    .background(Color.secondary.opacity(0.2))
                    .cornerRadius(8)
            } else {
                VStack(spacing: 12) {
                    ForEach(question.options, id: \.self) { option in
                        OptionButton(
                            option: option,
                            isSelected: isOptionSelected(option),
                            allowsMultipleSelection: question.allowsMultipleSelection
                        ) {
                            toggleOption(option)
                        }
                    }
                }
            }
        }
    }
    
    private func isOptionSelected(_ option: String) -> Bool {
        selectedAnswers[question.question]?.contains(option) ?? false
    }
    
    private func toggleOption(_ option: String) {
        var currentAnswers = selectedAnswers[question.question] ?? Set<String>()
        
        if question.allowsMultipleSelection {
            if currentAnswers.contains(option) {
                currentAnswers.remove(option)
            } else {
                currentAnswers.insert(option)
            }
        } else {
            currentAnswers = [option]
        }
        
        selectedAnswers[question.question] = currentAnswers
    }
}

struct OptionButton: View {
    let option: String
    let isSelected: Bool
    let allowsMultipleSelection: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack {
                Text(option)
                    .font(.special(.body, weight: .medium))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.9))
                Spacer()
                Image(systemName: allowsMultipleSelection ? 
                      (isSelected ? "checkmark.square.fill" : "square") :
                      (isSelected ? "checkmark.circle.fill" : "circle"))
                    .foregroundColor(isSelected ? .white : .white.opacity(0.6))
            }
            .padding()
            .background(isSelected ? Color.brand : Color.white.opacity(0.1))
            .cornerRadius(12)
        }
    }
}

// Enhanced InsightCard with animations
private struct InsightCard: View {
    let text: String
    @State private var isHovered = false
    
    var isCostInsight: Bool {
        text.contains("saving you $")
    }
    
    var attributedText: AttributedString {
        var attributed = AttributedString(text)
        
        if isCostInsight, 
           let range = text.range(of: "saving you \\$\\d+", options: .regularExpression) {
            let attributedRange = Range(range, in: attributed)!
            attributed[attributedRange].foregroundColor = .brand
            attributed[attributedRange].font = .special(.title3, weight: .black)
        }
        
        return attributed
    }
    
    var body: some View {
        Text(attributedText)
            .font(.body)
            .foregroundColor(.white)
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.secondary.opacity(0.2))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(
                                LinearGradient(
                                    colors: [.white.opacity(0.3), .brand.opacity(0.3)],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                ),
                                lineWidth: 1
                            )
                    )
                    .shadow(
                        color: .brand.opacity(0.2),
                        radius: isHovered ? 12 : 8,
                        x: 0,
                        y: isHovered ? 8 : 4
                    )
            )
            .scaleEffect(isHovered ? 1.02 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: isHovered)
            .onHover { hovering in
                isHovered = hovering
            }
    }
}

// Premium button style with animations
private struct PremiumButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(.headline)
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .padding()
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.brand)
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color.white.opacity(0.3), lineWidth: 1)
                    )
                    .shadow(
                        color: .brand.opacity(0.5),
                        radius: configuration.isPressed ? 8 : 15,
                        x: 0,
                        y: configuration.isPressed ? 2 : 5
                    )
            )
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .opacity(configuration.isPressed ? 0.9 : 1.0)
            .animation(.spring(response: 0.3, dampingFraction: 0.7), value: configuration.isPressed)
    }
}

// Premium background view
struct BackgroundView: View {
    @Binding var animate: Bool
    
    var body: some View {
        ZStack {
            // Updated gradient only
            LinearGradient(
                colors: [
                    .brand.opacity(0.4),
                    .black.opacity(0.5),
                    .black.opacity(0.3)
                ],
                startPoint: .top,
                endPoint: .bottom
            )
            
            // Keeping original animated circles
            GeometryReader { geometry in
                ZStack {
                    Circle()
                        .fill(Color.brand.opacity(0.1))
                        .frame(width: geometry.size.width * 0.8)
                        .offset(x: animate ? 100 : -100, y: -200)
                        .blur(radius: 60)
                    
                    Circle()
                        .fill(Color.brand.opacity(0.1))
                        .frame(width: geometry.size.width * 0.8)
                        .offset(x: animate ? -100 : 100, y: 200)
                        .blur(radius: 60)
                }
                .animation(
                    .easeInOut(duration: 8)
                    .repeatForever(autoreverses: true),
                    value: animate
                )
            }
        }
        .ignoresSafeArea()
    }
}

private struct ComparisonTableView: View {
    var body: some View {
        VStack(spacing: 16) {
            VStack(spacing: 2) {
                ComparisonRow(
                    feature: "Feature",
                    coaching: "Private Coach",
                    app: "Form Fighter",
                    isHeader: true
                )
                
                Divider()
                    .background(Color.white.opacity(0.2))
                
                ComparisonRow(
                    feature: "Cost",
                    coaching: "$400+/month",
                    app: "$59.96/month"
                )
                
                ComparisonRow(
                    feature: "Feedback",
                    coaching: "Limited hours",
                    app: "24/7 access"
                )
                
                ComparisonRow(
                    feature: "Analysis",
                    coaching: "Varies by coach",
                    app: "Every rep"
                )
            }
            .background(Color.black.opacity(0.3))
            .cornerRadius(12)
        }
    }
}

// Simplified ComparisonRow
private struct ComparisonRow: View {
    let feature: String
    let coaching: String
    let app: String
    var isHeader: Bool = false
    
    var body: some View {
        HStack(spacing: 4) {
            Text(feature)
                .frame(width: 70, alignment: .leading)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            Text(coaching)
                .frame(maxWidth: .infinity)
            
            Divider()
                .background(Color.white.opacity(0.2))
            
            Text(app)
                .frame(maxWidth: .infinity)
                .foregroundColor(isHeader ? .white : .brand)
        }
        .font(.special(isHeader ? .caption : .caption2, weight: isHeader ? .bold : .regular))
        .padding(.vertical, 8)
        .padding(.horizontal, 12)
    }
}

#Preview {
    OnePageOnboardingView()
}


// .navigationDestination(isPresented: $navigate) {
        //     // MARK: - If you want to skip request review and navigate directly to LoginView or
        //     // any other view, just comment the line below and add the proper view you wish.
        //     // Even that requesting the review without trying the app could feel dumb, evidences
        //     // have demonstrated that this converts so much:
        //     // https://x.com/evgeniymikholap/status/1714612296117608571?s=20
        //     // Other strategy is requesting review after a success moment. For example in a to-do list app,
        //     // after completing one ore several tasks.
        //     // It's important to know that you only have 3 ATTEMPTS PER YEAR to request a review, so place them wisely.
        //    // RequestReviewView()
