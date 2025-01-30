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
    @ObservedObject var userManager: UserManager
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
                    options: ["Muay Thai", "Boxing", "MMA", "Kickboxing", "Other"],
                    allowsMultipleSelection: true,
                    isOpenEnded: false
                )
            ],
            stepNumber: 3
        ),
        OnboardingSurveyStep(
            title: "Jab Analysis",
            questions: [
                SurveyQuestion(
                    question: "What's your most common feedback during sparring with your jab?",
                    options: ["I get countered easily", "My jab lacks power", "I'm too slow to retract", "I drop my hands after jabbing"],
                    allowsMultipleSelection: false,
                    isOpenEnded: false
                ),
                SurveyQuestion(
                    question: "What aspect of your jab do you want to improve most?",
                    options: ["Speed and explosiveness", "Technical form", "Defense while jabbing", "Power generation"],
                    allowsMultipleSelection: false,
                    isOpenEnded: false
                ),
                SurveyQuestion(
                    question: "What's your biggest technical challenge with the jab?",
                    options: ["My elbow flares out", "I telegraph my jab", "My footwork is off", "My jab isn't straight"],
                    allowsMultipleSelection: false,
                    isOpenEnded: false
                )
            ],
            stepNumber: 4
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
            stepNumber: 5
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
            stepNumber: 6
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
                    } else if currentStep == surveySteps.count + 1 {
                        LoadingAnalysisView {
                            updatePinnedMetrics()
                            withAnimation {
                                currentStep += 1
                            }
                        }
                        .transition(.opacity)
                    } else if currentStep == surveySteps.count + 2 {
                        OnboardingRecommendedFocusAreasView(
                            userManager: userManager,
                            selectedAnswers: selectedAnswers,
                            onContinue: {
                                withAnimation {
                                    currentStep += 1
                                }
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    } else if currentStep == surveySteps.count + 3 {
                        SavingsView(
                            selectedAnswers: selectedAnswers,
                            onContinue: {
                                hasCompletedOnboarding = true
                            }
                        )
                        .transition(.scale.combined(with: .opacity))
                    }
                }
                .animation(.spring(response: 0.6, dampingFraction: 0.8), value: currentStep)
            }
            .padding(.vertical, 10)
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
                
                // Button("Skip") {
                //     hasCompletedOnboarding = true 
                // }
                // .foregroundColor(.white.opacity(0.6))
                // .padding(.top, 8)
                
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
                
                // Text("Let's tailor your experience to help you master your technique.")
                //     .font(.special(.title3, weight: .medium))
                //     .multilineTextAlignment(.center)
                //     .foregroundColor(.white.opacity(0.7))
                //     .padding(.horizontal, 24)
                //     .fixedSize(horizontal: false, vertical: true)
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
                        updatePinnedMetrics()
                        currentStep = surveySteps.count + 1 // Show recommendations
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
            
            // If they spend $0 on coaching, show them potential value instead of negative savings
            if yearlyCoachingSpending == 0 {
                return 1080 // Example value of what they could save compared to getting coaching
            }
            
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
    
    private func convertToStringDict(_ dict: [String: Set<String>]) -> [String: String] {
        var result: [String: String] = [:]
        for (key, value) in dict {
            if let firstValue = value.first {
                result[key] = firstValue
            }
        }
        return result
    }
    
    private func convertToJabQuestions(_ steps: [OnboardingSurveyStep]) -> [JabMetricQuestion] {
        return steps.flatMap { step in
            step.questions.map { question in
                JabMetricQuestion(
                    question: question.question,
                    options: question.options,
                    relatedMetrics: [:] // Add appropriate metrics mapping if needed
                )
            }
        }
    }
    
    private func updatePinnedMetrics() {
        var recommendedMetrics = Set<String>()
        
        // Map survey questions to metrics using jabQuizQuestions mapping
        for (question, answers) in selectedAnswers {
            switch question {
            case "What's your most common feedback during sparring with your jab?":
                if let answer = answers.first {
                    recommendedMetrics.insert("Hand_Velocity_Extension")
                    recommendedMetrics.insert("Chin_Tucked_Extension")
                    if answer == "I get countered easily" {
                        recommendedMetrics.insert("Jab_Straight_Line_Extension")
                    } else if answer == "My jab lacks power" {
                        recommendedMetrics.insert("Force_Generation_Extension")
                    } else if answer == "I'm too slow to retract" {
                        recommendedMetrics.insert("Hand_Velocity_Retraction")
                    } else if answer == "I drop my hands after jabbing" {
                        recommendedMetrics.insert("Hands_Above_Shoulders_Guard")
                    }
                }
            case "What aspect of your jab do you want to improve most?":
                if let answer = answers.first {
                    if answer == "Speed and explosiveness" {
                        recommendedMetrics.insert("Overall_Velocity_Extension")
                        recommendedMetrics.insert("Hand_Velocity_Extension")
                    } else if answer == "Technical form" {
                        recommendedMetrics.insert("Jab_Straight_Line_Extension")
                        recommendedMetrics.insert("Jab_Arm_Extension")
                    } else if answer == "Defense while jabbing" {
                        recommendedMetrics.insert("Rear_Hand_In_Guard_Extension")
                        recommendedMetrics.insert("Chin_Tucked_Extension")
                    } else if answer == "Power generation" {
                        recommendedMetrics.insert("Force_Generation_Extension")
                        recommendedMetrics.insert("Motion_Sequence")
                    }
                }
            case "What's your biggest technical challenge with the jab?":
                if let answer = answers.first {
                    if answer == "My elbow flares out" {
                        recommendedMetrics.insert("Elbow_Flare_Extension")
                        recommendedMetrics.insert("Elbow_Protection_Extension")
                    } else if answer == "I telegraph my jab" {
                        recommendedMetrics.insert("Hand_Drop_Before_Extension")
                        recommendedMetrics.insert("Motion_Sequence")
                    } else if answer == "My footwork is off" {
                        recommendedMetrics.insert("Foot_Placement_Extension")
                        recommendedMetrics.insert("Step_Distance_Extension")
                    } else if answer == "My jab isn't straight" {
                        recommendedMetrics.insert("Jab_Straight_Line_Extension")
                        recommendedMetrics.insert("Elbow_Straight_Line_Extension")
                    }
                }
            default:
                break
            }
        }
        
        // Update user's pinned metrics (limit to 3)
        userManager.pinnedMetrics = Array(recommendedMetrics.prefix(3)).map { metricId in
            PinnedMetric(
                id: metricId,
                category: getCategoryForMetric(metricId),
                displayName: getDisplayName(for: metricId)
            )
        }
    }
    
    private func getCategoryForMetric(_ metricId: String) -> String {
        for (category, metrics) in MetricsConstants.groupedMetrics {
            if metrics.contains(metricId) {
                return category
            }
        }
        return "overall"
    }
    
    private func getDisplayName(for metricId: String) -> String {
        metricId.replacingOccurrences(of: "_", with: " ")
            .capitalized
    }
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

struct OnboardingMetricsSelectionView: View {
    @Binding var selectedAnswers: [String: Set<String>]
    @Binding var currentStep: Int
    @State private var showDirectSelection = false
    @ObservedObject var userManager: UserManager
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Your Personalized Focus Areas")
                .font(.special(.title2, weight: .bold))
                .foregroundColor(.white)
                .padding(.top)
            
            Text("Based on your responses, we recommend focusing on these key metrics:")
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            // Quiz-based recommendations
            ForEach(userManager.pinnedMetrics, id: \.id) { metric in
                MetricExplanationCard(metric: metric)
            }
            
            // Divider with "or"
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.white.opacity(0.3))
                Text("or")
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal)
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            
            // Manual selection button
            Button(action: { showDirectSelection = true }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Choose Your Own Metrics")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Select from all 50+ available metrics")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            
            // Continue button
            Button(action: { currentStep += 1 }) {
                Text("Continue")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brand)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .padding()
        .sheet(isPresented: $showDirectSelection) {
            MetricsDirectSelectionView(userManager: userManager)
                .presentationDetents([.large])
        }
    }
}

struct OnboardingRecommendedFocusAreasView: View {
    @ObservedObject var userManager: UserManager
    let selectedAnswers: [String: Set<String>]
    let onContinue: () -> Void
    @State private var showDirectSelection = false
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Your Personalized Focus Areas")
                .font(.special(.title2, weight: .bold))
                .foregroundColor(.white)
                .padding(.top)
            
            Text("Based on your responses, we recommend focusing on these key metrics:")
                .foregroundColor(.white.opacity(0.7))
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            ScrollView {
                VStack(spacing: 16) {
                    ForEach(userManager.pinnedMetrics, id: \.id) { metric in
                        MetricExplanationCard(metric: metric)
                    }
                }
                .padding(.vertical)
            }
            
            // Divider with "or"
            HStack {
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.white.opacity(0.3))
                Text("or")
                    .foregroundColor(.white.opacity(0.7))
                    .padding(.horizontal)
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.white.opacity(0.3))
            }
            .padding()
            
            Button(action: { showDirectSelection = true }) {
                HStack {
                    VStack(alignment: .leading) {
                        Text("Choose Your Own Metrics")
                            .font(.headline)
                            .foregroundColor(.white)
                        Text("Select from all 50+ available metrics")
                            .font(.subheadline)
                            .foregroundColor(.white.opacity(0.7))
                    }
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(.white)
                }
                .padding()
                .background(Color.white.opacity(0.1))
                .cornerRadius(12)
            }
            
            Button(action: onContinue) {
                Text("Get Started Now")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brand)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .padding()
        .sheet(isPresented: $showDirectSelection) {
            MetricsDirectSelectionView(userManager: userManager)
        }
    }
}

struct SavingsView: View {
    let selectedAnswers: [String: Set<String>]
    let onContinue: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Text("Your Potential Savings")
                .font(.special(.title2, weight: .bold))
                .foregroundColor(.white)
                .padding(.top)
            
            if let savings = calculateSavings() {
                Text("$\(savings)")
                    .font(.system(size: 64, weight: .heavy))
                    .foregroundColor(.brand)
                    .padding(.vertical, 8)
                
                Text("per year")
                    .font(.special(.title3, weight: .medium))
                    .foregroundColor(.white.opacity(0.7))
            }
            
            // ComparisonTableView()
            //     .padding(.top, 24)
            
            Button(action: onContinue) {
                Text("Get Started Now")
                    .font(.headline)
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(Color.brand)
                    .cornerRadius(12)
            }
            .padding(.top)
        }
        .padding()
    }
    
    private func calculateSavings() -> Int? {
        if let monthlyCoaching = selectedAnswers["How much do you spend monthly on private coaching?"]?.first {
            let yearlyCoachingSpending = calculateYearlyCoachingSpending(from: monthlyCoaching)
            let yearlyAppCost = 780 // $14.99 * 52 weeks
            
            // If they spend $0 on coaching, show them potential value instead of negative savings
            if yearlyCoachingSpending == 0 {
                return 1080 // Example value of what they could save compared to getting coaching
            }
            
            return yearlyCoachingSpending - yearlyAppCost
        }
        return nil
    }
    
    private func calculateYearlyCoachingSpending(from monthlyCoaching: String) -> Int {
        let monthlyAmount: Int
        switch monthlyCoaching {
        case "$0 (No private coaching)": monthlyAmount = 0
        case "$100–$200": monthlyAmount = 150
        case "$200–$400": monthlyAmount = 300
        case "Over $400": monthlyAmount = 500
        default: monthlyAmount = 0
        }
        return monthlyAmount * 12
    }
}

struct LoadingAnalysisView: View {
    @State private var currentMessage = 0
    let messages = [
        "Analyzing your technique with AI...",
        "Crunching the numbers...",
        "Finding your best improvements...",
        "Personalizing your experience..."
    ]
    
    let timer = Timer.publish(every: 1.5, on: .main, in: .common).autoconnect()
    @State private var progress: Double = 0
    let onComplete: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            Spacer()
            
            ProgressView()
                .scaleEffect(1.5)
                .tint(.brand)
                .padding()
            
            Text(messages[currentMessage])
                .font(.special(.title3, weight: .medium))
                .foregroundColor(.white)
                .multilineTextAlignment(.center)
                .transition(.opacity)
                .animation(.easeInOut, value: currentMessage)
            
            Spacer()
        }
        .padding()
        .onReceive(timer) { _ in
            if currentMessage < messages.count - 1 {
                currentMessage += 1
            } else if progress >= 1.0 {
                onComplete()
            }
            progress += 0.25
        }
    }
}

// #Preview {
//     OnePageOnboardingView(userManager: UserManager())
// }


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
