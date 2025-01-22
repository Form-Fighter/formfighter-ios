//
//  ProfileView.swift
//  FormFighter
//
//  Created by Julian Parker on 10/4/24.
//
import SwiftUI
import ConfettiSwiftUI

enum ProfileSection {
    case analytics, history
}

// Break down the tab button into its own view
struct ProfileTabButton: View {
    let section: ProfileSection
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 8) {
                Image(systemName: section == .analytics ? "chart.bar.fill" : "clock.fill")
                    .font(.system(size: 16))
                Text(section == .analytics ? "Analytics" : "History")
                    .font(.system(.body, design: .rounded))
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .background(
                Capsule()
                    .fill(
                        isSelected ?
                        AnyShapeStyle(
                            LinearGradient(
                                colors: [Color.brand, Color.brand.opacity(0.8)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        ) :
                        AnyShapeStyle(Color.clear)
                    )
            )
            .foregroundColor(isSelected ? .white : .gray)
        }
    }
}

// Simplified ProfileSectionTabs
struct ProfileSectionTabs: View {
    @Binding var selectedSection: ProfileSection
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach([ProfileSection.analytics, .history], id: \.self) { section in
                ProfileTabButton(
                    section: section,
                    isSelected: selectedSection == section,
                    action: {
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                            selectedSection = section
                        }
                    }
                )
            }
        }
        .padding(4)
        .background(
            Capsule()
                .fill(Color.gray.opacity(0.15))
        )
        .padding(.horizontal)
    }
}

struct ProfileView: View {
    @StateObject private var viewModel = ProfileVM()
    @EnvironmentObject private var userManager: UserManager
    @EnvironmentObject private var feedbackManager: FeedbackManager
    @State private var selectedTab: TimePeriod = .week
    @State private var sortOption: SortOption = .date
    @State private var selectedSection: ProfileSection = .analytics
    @State private var selectedFeedbackId: String?
    @State private var showFeedbackView = false
    @State private var showStreakCelebration = false {
        didSet {
            print("🎯 ProfileView - showStreakCelebration changed to: \(showStreakCelebration)")
        }
    }
    @State private var triggerConfetti = 0
    @State private var showingBadgeCelebration = false
    @State private var earnedBadge: Badge?
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: true) {
            VStack(alignment: .leading, spacing: 24) {
                ProfileHeader()
                
                if !viewModel.isAuthenticated {
                    // Show sign in prompt
                    VStack(spacing: 16) {
                        Image(systemName: "person.crop.circle.badge.exclamationmark")
                            .font(.system(size: 50))
                            .foregroundColor(.secondary)
                        Text("Sign in to view your profile")
                            .font(.headline)
                    }
                } else if viewModel.isLoading {
                    LoadingView()
                } else if viewModel.feedbacks.isEmpty {
                    EmptyStateView()
                } else {
                    if selectedSection == .analytics {
                        GamificationStats(showStreakCelebration: $showStreakCelebration)
                            .onAppear {
                                print("🎯 GamificationStats appeared - current streak: \(userManager.currentStreak)")
                            }
                        
                        
                    }
                    else if selectedSection == .history {
BadgeGridView(
                            badges: viewModel.badges,
                            earnedBadges: viewModel.earnedBadges,
                            progress: viewModel.badgeProgress
                        )
                    }
                    
                    ProfileSectionTabs(selectedSection: $selectedSection)
                    
                    if selectedSection == .analytics {
                        AnalyticsSection(selectedTab: $selectedTab, viewModel: viewModel)
                    } else {
                        HistorySection(viewModel: viewModel, sortOption: $sortOption)
                    }
                }
            }
            .onChange(of: userManager.currentStreak) { newValue in
                print("🎯 ProfileView - Streak changed to: \(newValue)")
                if newValue == 1 && !showStreakCelebration {
                    print("🎯 ProfileView - Triggering celebration")
                    celebrate()
                }
            }
            .confettiCannon(counter: $triggerConfetti, num: 50, openingAngle: Angle(degrees: 0), closingAngle: Angle(degrees: 360), radius: 200)
            .onReceive(NotificationCenter.default.publisher(for: .badgeEarned)) { notification in
                if let badgeId = notification.userInfo?["badgeId"] as? String,
                   let badge = viewModel.getBadge(id: badgeId) {
                    earnedBadge = badge
                    showingBadgeCelebration = true
                    triggerConfetti += 1
                }
            }
            .overlay {
                if showingBadgeCelebration, let badge = earnedBadge {
                    Color.black.opacity(0.3)
                        .ignoresSafeArea()
                        .overlay {
                            BadgeCelebrationView(
                                badge: badge,
                                isPresented: $showingBadgeCelebration
                            )
                            .padding()
                        }
                }
            }
        }
        .background(ThemeColors.background)
        .onReceive(NotificationCenter.default.publisher(for: NSNotification.Name("OpenFeedback"))) { notification in
            if let feedbackId = notification.userInfo?["feedbackId"] as? String {
                selectedFeedbackId = feedbackId
                showFeedbackView = true
            }
        }
        .sheet(isPresented: $showFeedbackView) {
            if let feedbackId = selectedFeedbackId {
                NavigationView {
                    FeedbackView(feedbackId: feedbackId, videoURL: nil)
                        .environmentObject(UserManager.shared)
                        .environmentObject(PurchasesManager.shared)
                        .environmentObject(FeedbackManager.shared)
                }
            }
        }
    }
    
    private func celebrate() {
        print("🎯 ProfileView - Celebration started")
        Task { @MainActor in
            showStreakCelebration = true
            triggerConfetti += 1
            Haptic.shared.success()
            
            try? await Task.sleep(nanoseconds: 3_000_000_000) // 3 seconds
            showStreakCelebration = false
            print("🎯 ProfileView - Celebration ended")
        }
    }
}

// Separate content view
struct ProfileContent: View {
    @ObservedObject var viewModel: ProfileVM
    @Binding var selectedTab: TimePeriod
    @Binding var sortOption: SortOption
    @Binding var selectedSection: ProfileSection
    @Binding var showStreakCelebration: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            ProfileHeader()
            
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.feedbacks.isEmpty {
                EmptyStateView()
            } else {
                ProfileMainContent(
                    viewModel: viewModel,
                    selectedTab: $selectedTab,
                    sortOption: $sortOption,
                    selectedSection: $selectedSection,
                    showStreakCelebration: $showStreakCelebration
                )
            }
        }
    }
}

// Header component
struct ProfileHeader: View {
    var body: some View {
        Text("Fighter Profile")
            .font(.system(.largeTitle, design: .rounded, weight: .bold))
            .foregroundColor(ThemeColors.primary)
            .padding(.top, 20)
            .padding(.horizontal)
    }
}

// Main content component
struct ProfileMainContent: View {
    @ObservedObject var viewModel: ProfileVM
    @Binding var selectedTab: TimePeriod
    @Binding var sortOption: SortOption
    @Binding var selectedSection: ProfileSection
    @Binding var showStreakCelebration: Bool
    
    var body: some View {
        VStack(spacing: 24) {
            if selectedSection == .analytics {
                GamificationStats(showStreakCelebration: $showStreakCelebration)
            }
            
            ProfileSectionTabs(selectedSection: $selectedSection)
            
            if selectedSection == .analytics {
                AnalyticsSection(selectedTab: $selectedTab, viewModel: viewModel)
            } else {
                HistorySection(viewModel: viewModel, sortOption: $sortOption)
            }
        }
    }
}

// Gamification Stats component
struct GamificationStats: View {
    @EnvironmentObject var userManager: UserManager
    @EnvironmentObject var feedbackManager: FeedbackManager
    @Binding var showStreakCelebration: Bool
    
    var body: some View {
        HStack(spacing: 16) {
            StreakView(count: userManager.currentStreak, showCelebration: $showStreakCelebration)
            Spacer()
            PersonalBestView(score: feedbackManager.personalBest)
        }
        .padding(.horizontal)
    }
}

// Analytics Section component
struct AnalyticsSection: View {
    @Binding var selectedTab: TimePeriod
    @ObservedObject var viewModel: ProfileVM
    
    var body: some View {
      
      
            
            TabView(selection: $selectedTab) {
                StatsView(timeInterval: .day, feedbacks: viewModel.feedbacks, viewModel: viewModel)
                    .tag(TimePeriod.day)
                    .tabItem { 
                        Label("24h", systemImage: "clock")
                            .font(.headline) 
                    }
                StatsView(timeInterval: .week, feedbacks: viewModel.feedbacks, viewModel: viewModel)
                    .tag(TimePeriod.week)
                    .tabItem { 
                        Label("Week", systemImage: "calendar")
                            .font(.headline) 
                    }
                StatsView(timeInterval: .month, feedbacks: viewModel.feedbacks, viewModel: viewModel)
                    .tag(TimePeriod.month)
                    .tabItem { 
                        Label("Month", systemImage: "calendar.badge.clock")
                            .font(.headline) 
                    }
            }
            .frame(height: 600)
            .padding(.bottom, 50)
     
    }
}

// History Section component
struct HistorySection: View {
    @ObservedObject var viewModel: ProfileVM
    @Binding var sortOption: SortOption
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            PunchListView(viewModel: viewModel, sortOption: $sortOption)
                .padding(.horizontal)
        }
    }
}

struct EmptyStateView: View {
    var body: some View {
        VStack(spacing: 20) {
            Image(systemName: "figure.boxing")
                .font(.system(size: 50))
                .foregroundColor(ThemeColors.primary)
            Text("No training sessions yet")
                .font(.headline)
                .foregroundColor(.secondary)
            Text("Complete your first session to see your stats")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding()
    }
}

enum TimePeriod: String {
    case day = "24h"
    case week = "Week"
    case month = "Month"
}

enum SortOption: String {
    case date, velocity, power
}

struct StatsView: View {
    var timeInterval: TimePeriod
    var feedbacks: [FeedbackListItem]
    @ObservedObject var viewModel: ProfileVM
    
    private var feedbacksInInterval: [FeedbackListItem] {
        filterFeedbacks(for: timeInterval, from: feedbacks)
    }
    
    private var averageScore: Int {
        calculateAverageScore(for: feedbacksInInterval)
    }
    
    // Convert feedbacks to PunchStats for the chart
    var chartData: [PunchStats] {
        let sortedFeedbacks = feedbacksInInterval
            .filter { $0.isCompleted }
            .sorted { $0.date < $1.date }
        
        return sortedFeedbacks.map { feedback in
            PunchStats(
                timestamp: feedback.date,
                score: feedback.score,
                count: 1  // We can enhance this later if needed
            )
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 24) {
            HStack(spacing: 16) {
                StatBox(
                    title: "Training Sessions",
                    value: "\(feedbacksInInterval.count)",
                    icon: "figure.boxing"
                )
                
                StatBox(
                    title: "Average Score",
                    value: "\(averageScore)",
                    icon: "star.fill"
                )
            }
            .padding(.horizontal)
            .padding(.vertical, 16)
            
            // Line Chart
            Group {
                if !chartData.isEmpty {
                    LineChartView(data: chartData, timeInterval: timeInterval)
                        .frame(maxWidth: .infinity)
                        .frame(height: 400)
                        .padding(.horizontal)
                } else {
                    Text("No data available for this time period")
                        .foregroundColor(.secondary)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding()
                        .frame(height: 400)
                }
            }
        }
    }
    
    private func filterFeedbacks(for interval: TimePeriod, from feedbacks: [FeedbackListItem]) -> [FeedbackListItem] {
        let currentDate = Date()
        let calendar = Calendar.current
        
        return feedbacks.filter { feedback in
            switch interval {
            case .day:
                return calendar.isDate(feedback.date, inSameDayAs: currentDate)
            case .week:
                let weekAgo = calendar.date(byAdding: .day, value: -7, to: currentDate)!
                return feedback.date >= weekAgo
            case .month:
                let monthAgo = calendar.date(byAdding: .month, value: -1, to: currentDate)!
                return feedback.date >= monthAgo
            }
        }
    }
    
    private func calculateAverageScore(for feedbacks: [FeedbackListItem]) -> Int {
        let completedFeedbacks = feedbacks.filter { $0.isCompleted }
        guard !completedFeedbacks.isEmpty else { return 0 }
        let totalScore = completedFeedbacks.reduce(0.0) { $0 + $1.score }
        return Int(totalScore / Double(completedFeedbacks.count))
    }
}

struct StatBox: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .foregroundColor(ThemeColors.primary)
                .font(.system(size: 18))
            
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.system(.caption, design: .rounded))
                    .foregroundColor(.secondary)
                    .lineLimit(1)
                
                Text(value)
                    .font(.system(.callout, design: .rounded, weight: .bold))
                    .foregroundColor(ThemeColors.primary)
            }
            
            Spacer()
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(ThemeColors.background)
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(ThemeColors.primary.opacity(0.1), lineWidth: 1)
        )
    }
}
    



struct LoadingView: View {
    var body: some View {
        VStack {
            ProgressView()
            Text("Loading...")
        }
        .padding()
    }
}



struct PunchListView: View {
    @EnvironmentObject var userManager: UserManager
    @ObservedObject var viewModel: ProfileVM
    @Binding var sortOption: SortOption
    
    // Grouped feedbacks
    private var groupedFeedbacks: [(String, [FeedbackListItem])] {
        let sorted = sortedFeedbacks
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        
        return Dictionary(grouping: sorted) { feedback -> String in
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: feedback.date), to: today).day!
            switch days {
            case 0: return "Today"
            case 1: return "Yesterday"
            case 2...7: return "This Week"
            case 8...30: return "This Month"
            default: return "Earlier"
            }
        }
        .sorted { group1, group2 in
            let order = ["Today", "Yesterday", "This Week", "This Month", "Earlier"]
            return order.firstIndex(of: group1.key)! < order.firstIndex(of: group2.key)!
        }
    }
    
    // Helper function to extract number from strings like "1.16 meters/second" or "281.9 Newtons"
    private func extractNumber(from string: String) -> Double {
        let numbers = string.components(separatedBy: CharacterSet.decimalDigits.inverted)
            .joined(separator: ".")
            .components(separatedBy: ".")
        if numbers.count >= 2 {
            return Double("\(numbers[0]).\(numbers[1])") ?? 0.0
        }
        return Double(numbers[0]) ?? 0.0
    }
    
    private var sortedFeedbacks: [FeedbackListItem] {
        switch sortOption {
        case .date:
            return viewModel.feedbacks.sorted(by: { $0.date > $1.date })
            
        case .velocity:
            return viewModel.feedbacks.compactMap { feedback in
                // Only include feedbacks that have velocity data
                guard let velocityMetric = feedback.modelFeedback?.body?.overall_velocity_extension?.metric_values else {
                    return nil
                }
                return feedback
            }.sorted { first, second in
                guard let firstValue = first.modelFeedback?.body?.overall_velocity_extension?.metric_values,
                      let secondValue = second.modelFeedback?.body?.overall_velocity_extension?.metric_values else {
                    return false
                }
                return extractNumber(from: firstValue) > extractNumber(from: secondValue)
            }
            
        case .power:
            return viewModel.feedbacks.compactMap { feedback in
                // Try KO potential first, then metric_values
                guard let powerMetric = feedback.modelFeedback?.body?.force_generation_extension,
                      let powerValue = powerMetric.knockout_potential ?? powerMetric.metric_values else {
                    return nil
                }
                return feedback
            }.sorted { first, second in
                guard let firstMetric = first.modelFeedback?.body?.force_generation_extension,
                      let secondMetric = second.modelFeedback?.body?.force_generation_extension else {
                    return false
                }
                
                // Get values, preferring KO potential over metric_values
                let firstValue = firstMetric.knockout_potential ?? firstMetric.metric_values ?? "0"
                let secondValue = secondMetric.knockout_potential ?? secondMetric.metric_values ?? "0"
                
                return extractNumber(from: firstValue) > extractNumber(from: secondValue)
            }
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Picker("Sort by", selection: $sortOption) {
                Text("Date").tag(SortOption.date)
                Text("Velocity").tag(SortOption.velocity)
                Text("Power").tag(SortOption.power)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            // Existing ScrollView with grouped feedbacks
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    ForEach(groupedFeedbacks, id: \.0) { group in
                        VStack(alignment: .leading, spacing: 12) {
                            Text(group.0)
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                                .foregroundColor(.secondary)
                                .padding(.horizontal)
                            
                            ForEach(group.1) { feedback in
                                NavigationLink(destination: FeedbackView(feedbackId: feedback.id, videoURL: nil)
                                    .environmentObject(UserManager.shared)
                                    .environmentObject(PurchasesManager.shared)
                                    .environmentObject(FeedbackManager.shared)) {
                                    FeedbackRowView(feedback: feedback, sortOption: sortOption)
                                }
                                .buttonStyle(PlainButtonStyle())
                                .transition(.opacity.combined(with: .offset(y: 5)))
                            }
                        }
                    }
                }
                .padding(.top, 8)
            }
        }
    }
}

// Helper Views for Future Features
struct StreakView: View {
    let count: Int
    @Binding var showCelebration: Bool
    @State private var showingTooltip = false
    @State private var scale: CGFloat = 1.0
    @State private var confettiCounter = 0
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "flame.fill")
                .foregroundColor(.orange)
                .scaleEffect(scale)
            Text("\(count) day streak")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .scaleEffect(scale)
        }
        .onAppear {
            print("🔥 StreakView appeared with count: \(count)")
        }
        .onChange(of: showCelebration) { newValue in
            print("🔥 StreakView - Celebration changed to: \(newValue)")
            if newValue {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                    scale = 1.3
                }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.5)) {
                        scale = 1.0
                    }
                }
                confettiCounter += 1
                showCelebration = false
            }
        }
        .onTapGesture {
            showingTooltip.toggle()
        }
        .popover(isPresented: $showingTooltip) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Training Streak")
                    .font(.headline)
                Text("Complete one training session every day to maintain your streak. Keep training to unlock special badges!")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            .padding()
            .frame(maxWidth: 300, idealHeight: 150)
            .presentationCompactAdaptation(.popover)
        }
        .confettiCannon(counter: $confettiCounter, num: 50, radius: 200)
    }
}

struct PersonalBestView: View {
    let score: Double
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: "trophy.fill")
                .foregroundColor(.yellow)
            Text("Best: \(Int(score))")
                .font(.system(.caption, design: .rounded, weight: .medium))
        }
    }
}

// New helper views
struct FeedbackRowView: View {
    let feedback: FeedbackListItem
    let sortOption: SortOption
    
    private func getDisplayValue() -> String? {
        switch sortOption {
        case .date, .velocity:
            guard let velocityValue = feedback.modelFeedback?.body?.overall_velocity_extension?.metric_values else {
                return nil
            }
            return velocityValue
            
        case .power:
            guard let powerMetric = feedback.modelFeedback?.body?.force_generation_extension,
                  let koPotential = powerMetric.knockout_potential?.replacingOccurrences(of: " %", with: "") else {
                return nil
            }
            // Convert to Double, round to nearest integer, and format with K.O. Potential label
            if let koValue = Double(koPotential) {
                return "\(Int(round(koValue)))% K.O."
            }
            return nil
        }
    }
    
    var body: some View {
        HStack {
            // Status Icon
            if feedback.isLoading {
                ProgressView()
                    .scaleEffect(0.7)
                    .overlay(
                        Text(feedback.status.message)
                            .font(.caption)
                            .foregroundColor(.secondary)
                            .offset(y: 20)
                    )
            } else if feedback.isCompleted {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundColor(ThemeColors.primary)
            }
            
            VStack(alignment: .leading, spacing: 5) {
                Text("Training Session")
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                Text(feedback.date.formatted(date: .abbreviated, time: .shortened))
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            if feedback.isCompleted, let displayValue = getDisplayValue() {
                Text(displayValue)
                    .foregroundColor(ThemeColors.primary)
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
        }
        .padding()
        .background(ThemeColors.background)
        .cornerRadius(8)
        .overlay(
            RoundedRectangle(cornerRadius: 8)
                .stroke(ThemeColors.primary.opacity(0.2), lineWidth: 1)
        )
    }
}

struct PaginationControls: View {
    @Binding var currentPage: Int
    let totalPages: Int
    
    var body: some View {
        HStack {
            if currentPage > 1 {
                Button("Previous") {
                    currentPage -= 1
                }
                .padding()
            }
            Spacer()
            if currentPage < totalPages {
                Button("Next") {
                    currentPage += 1
                }
                .padding()
            }
        }
    }
}

#Preview {
    ProfileView()
}


