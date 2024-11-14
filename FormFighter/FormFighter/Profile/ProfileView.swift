//
//  ProfileView.swift
//  FormFighter
//
//  Created by Julian Parker on 10/4/24.
//
import SwiftUI

struct ProfileView: View {
    @StateObject private var viewModel = ProfileVM()
    @EnvironmentObject private var userManager: UserManager
    @State private var selectedTab: TimePeriod = .week
    @State private var sortOption: SortOption = .date
    
    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(alignment: .leading, spacing: 30) {
                // Fighter Profile Header
                Text("Fighter Profile")
                    .font(.system(.largeTitle, design: .rounded, weight: .bold))
                    .foregroundColor(ThemeColors.primary)
                    .padding(.top, 20)
                    .padding(.horizontal)
                
                if viewModel.isLoading {
                    LoadingView()
                        .frame(maxWidth: .infinity)
                        .padding(.top, 40)
                } else if viewModel.feedbacks.isEmpty {
                    EmptyStateView()
                        .padding(.top, 40)
                } else {
                    // Analytics Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Analytics")
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .foregroundColor(ThemeColors.accent)
                            .padding(.horizontal)
                        
                        TabView(selection: $selectedTab) {
                            StatsView(timeInterval: .day, feedbacks: viewModel.feedbacks)
                                .tag(TimePeriod.week)
                                .tabItem { 
                                    Label("24h", systemImage: "clock")
                                        .font(.headline) 
                                }
                            StatsView(timeInterval: .week, feedbacks: viewModel.feedbacks)
                                .tag(TimePeriod.week)
                                .tabItem { 
                                    Label("Week", systemImage: "calendar")
                                        .font(.headline) 
                                }
                            StatsView(timeInterval: .month, feedbacks: viewModel.feedbacks)
                                .tag(TimePeriod.month)
                                .tabItem { 
                                    Label("Month", systemImage: "calendar.badge.clock")
                                        .font(.headline) 
                                }
                        }
                        .frame(height: 200)
                        .padding(.horizontal)
                    }
                    .padding(.vertical, 20)
                    .background(ThemeColors.background.opacity(0.5))
                    .cornerRadius(12)
                    .padding(.horizontal)
                    
                    // Training History Section
                    VStack(alignment: .leading, spacing: 15) {
                        Text("Training History")
                            .font(.system(.title2, design: .rounded, weight: .semibold))
                            .foregroundColor(ThemeColors.accent)
                            .padding(.top)
                            .padding(.horizontal)
                        
                        PunchListView(viewModel: viewModel, sortOption: $sortOption)
                            .padding(.horizontal)
                    }
                    .padding(.bottom, 30)
                }
            }
        }
        .background(ThemeColors.background.opacity(0.3))
        .onAppear {
            viewModel.fetchUserFeedback(userId: userManager.userId)
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
    case day, week, month, year
}

enum SortOption: String {
    case date, score
}

struct StatsView: View {
    var timeInterval: TimePeriod
    var feedbacks: [ProfileVM.FeedbackListItem]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(timeInterval.rawValue.capitalized) Stats")
                .font(.title2)
                .padding(.vertical)
            
            let feedbacksInInterval = filterFeedbacks(for: timeInterval, from: feedbacks)
            let averageScore = calculateAverageScore(for: feedbacksInInterval)
            
            Text("Feedbacks: \(feedbacksInInterval.count)")
            Text("Average Score: \(averageScore)")
        }
    }
    
    private func filterFeedbacks(for timeInterval: TimePeriod, from feedbacks: [ProfileVM.FeedbackListItem]) -> [ProfileVM.FeedbackListItem] {
        let currentDate = Date()
        let calendar = Calendar.current
        
        return feedbacks.filter { feedback in
            switch timeInterval {
            case .day:
                return calendar.isDate(feedback.date, inSameDayAs: currentDate)
            case .week:
                let weekAgo = calendar.date(byAdding: .day, value: -7, to: currentDate)!
                return feedback.date >= weekAgo
            case .month:
                let monthAgo = calendar.date(byAdding: .month, value: -1, to: currentDate)!
                return feedback.date >= monthAgo
            case .year:
                let yearAgo = calendar.date(byAdding: .year, value: -1, to: currentDate)!
                return feedback.date >= yearAgo
            }
        }
    }
    
    private func calculateAverageScore(for feedbacks: [ProfileVM.FeedbackListItem]) -> Int {
        let completedFeedbacks = feedbacks.filter { $0.isCompleted }
        guard !completedFeedbacks.isEmpty else { return 0 }
        let totalScore = completedFeedbacks.reduce(0.0) { $0 + $1.score }
        return Int(totalScore / Double(completedFeedbacks.count))
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
    @State private var currentPage: Int = 1
    private let itemsPerPage = 5
    
    // Add computed properties for pagination
    private var sortedFeedbacks: [ProfileVM.FeedbackListItem] {
        switch sortOption {
        case .date:
            return viewModel.feedbacks.sorted(by: { $0.date > $1.date })
        case .score:
            return viewModel.feedbacks.sorted(by: { $0.score > $1.score })
        }
    }
    
    private var paginatedFeedbacks: [ProfileVM.FeedbackListItem] {
        let startIndex = (currentPage - 1) * itemsPerPage
        return Array(sortedFeedbacks.dropFirst(startIndex).prefix(itemsPerPage))
    }
    
    private var totalPages: Int {
        Int(ceil(Double(sortedFeedbacks.count) / Double(itemsPerPage)))
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker("Sort by", selection: $sortOption) {
                Text("Date").tag(SortOption.date)
                Text("Score").tag(SortOption.score)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(paginatedFeedbacks, id: \.id) { feedback in
                        NavigationLink(destination: FeedbackView(feedbackId: feedback.id, videoURL: nil)) {
                            FeedbackRowView(feedback: feedback)
                        }
                        .buttonStyle(PlainButtonStyle())
                    }
                }
            }
            
            PaginationControls(currentPage: $currentPage, totalPages: totalPages)
        }
        .onAppear {
            viewModel.fetchUserFeedback(userId: userManager.userId)
        }
    }
}

// New helper views
struct FeedbackRowView: View {
    let feedback: ProfileVM.FeedbackListItem
    
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
            if feedback.isCompleted {
                Text("Score: \(Int(feedback.score))")
                    .foregroundColor(ThemeColors.primary)
                    .font(.system(.body, design: .rounded, weight: .semibold))
            }
        }
        .padding()
        .background(ThemeColors.background.opacity(0.5))
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


