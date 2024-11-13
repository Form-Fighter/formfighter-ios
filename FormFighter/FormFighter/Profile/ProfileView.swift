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
        VStack(alignment: .leading) {
            Text("Statistics")
                .font(.largeTitle)
                .padding(.top)
                .padding(.horizontal)
                
            if viewModel.isLoading {
                LoadingView()
            } else if viewModel.feedbacks.isEmpty {
                Text("No feedback history yet")
                    .font(.headline)
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                TabView(selection: $selectedTab) {
                    StatsView(timeInterval: .day, feedbacks: viewModel.feedbacks)
                        .tag(TimePeriod.week)
                        .tabItem { Text("24 Hours").font(.headline) }
                    StatsView(timeInterval: .week, feedbacks: viewModel.feedbacks)
                        .tag(TimePeriod.week)
                        .tabItem { Text("7 Days").font(.headline) }
                    StatsView(timeInterval: .month, feedbacks: viewModel.feedbacks)
                        .tag(TimePeriod.month)
                        .tabItem { Text("Month").font(.headline) }
                    StatsView(timeInterval: .year, feedbacks: viewModel.feedbacks)
                        .tag(TimePeriod.year)
                        .tabItem { Text("Year").font(.headline) }
                }
                .padding(.horizontal)
                
                PunchListView(viewModel: viewModel, sortOption: $sortOption)
                    .padding(.horizontal)
            }
        }
        .onAppear {
            viewModel.fetchUserFeedback(userId: userManager.userId)
        }
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
            if !feedback.isCompleted {
                ProgressView()
                    .scaleEffect(0.7)
            }
            Text(feedback.date.formatted(date: .abbreviated, time: .shortened))
            Spacer()
            if feedback.isCompleted {
                Text("Score: \(Int(feedback.score))")
            } else {
                Text(feedback.status.capitalized)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .contentShape(Rectangle())
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


