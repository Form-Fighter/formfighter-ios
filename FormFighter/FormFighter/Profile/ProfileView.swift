//
//  ProfileView.swift
//  FormFighter
//
//  Created by Julian Parker on 10/4/24.
//
import SwiftUI

struct ProfileView: View {
    @State private var punches: [Punch] = [
        Punch(date: Date().addingTimeInterval(-86400), score: 75),
        Punch(date: Date().addingTimeInterval(-172800), score: 80),
        Punch(date: Date().addingTimeInterval(-259200), score: 90),
        Punch(date: Date().addingTimeInterval(-345600), score: 85),
        Punch(date: Date().addingTimeInterval(-432000), score: 70),
        Punch(date: Date().addingTimeInterval(-518400), score: 95),
        Punch(date: Date().addingTimeInterval(-604800), score: 88),
        Punch(date: Date().addingTimeInterval(-691200), score: 92),
        Punch(date: Date().addingTimeInterval(-777600), score: 78),
        Punch(date: Date().addingTimeInterval(-864000), score: 82),
        Punch(date: Date().addingTimeInterval(-950400), score: 85),
        Punch(date: Date().addingTimeInterval(-1036800), score: 89),
        Punch(date: Date().addingTimeInterval(-1123200), score: 93),
        Punch(date: Date().addingTimeInterval(-1209600), score: 74),
        Punch(date: Date().addingTimeInterval(-1296000), score: 79),
        Punch(date: Date().addingTimeInterval(-1382400), score: 91),
        Punch(date: Date().addingTimeInterval(-1468800), score: 87),
        Punch(date: Date().addingTimeInterval(-1555200), score: 77),
        Punch(date: Date().addingTimeInterval(-1641600), score: 81),
        Punch(date: Date().addingTimeInterval(-1728000), score: 86),
        Punch(date: Date().addingTimeInterval(-1814400), score: 83),
        Punch(date: Date().addingTimeInterval(-1900800), score: 94),
        Punch(date: Date().addingTimeInterval(-1987200), score: 72),
        Punch(date: Date().addingTimeInterval(-2073600), score: 76),
        Punch(date: Date().addingTimeInterval(-2160000), score: 84)
    ]
    @State private var isLoading = true
    @State private var selectedTab: TimePeriod = .week
    @State private var sortOption: SortOption = .date
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("Statistics")
                .font(.largeTitle)
                .padding(.top)
                .padding(.horizontal)
                
            TabView(selection: $selectedTab) {
                StatsView(timeInterval: .day, punches: punches)
                    .tag(TimePeriod.week)
                    .tabItem { Text("24 Hours").font(.headline) }
                StatsView(timeInterval: .week, punches: punches)
                    .tag(TimePeriod.week)
                    .tabItem { Text("7 Days").font(.headline) }
                StatsView(timeInterval: .month, punches: punches)
                    .tag(TimePeriod.month)
                    .tabItem { Text("Month").font(.headline) }
                StatsView(timeInterval: .year, punches: punches)
                    .tag(TimePeriod.year)
                    .tabItem { Text("Year").font(.headline) }
            }
            .padding(.horizontal)
            
            if isLoading {
                LoadingView()
            } else {
                PunchListView(punches: punches, sortOption: $sortOption)
                    .padding(.horizontal)
            }
        }
        .onAppear {
            fetchPunchData()
        }
    }
    
    private func fetchPunchData() {
        // Placeholder logic for fetching punch data
        isLoading = false
        // Fake delay to simulate loading
        DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
            isLoading = false
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
    var punches: [Punch]
    
    var body: some View {
        VStack(alignment: .leading) {
            Text("\(timeInterval.rawValue.capitalized) Stats")
                .font(.title2)
                .padding(.vertical)
            
            let punchesInInterval = filterPunches(for: timeInterval, from: punches)
            let averageScore = calculateAverageScore(for: punchesInInterval)
            
            Text("Punches: \(punchesInInterval.count)")
            Text("Average Score: \(averageScore)")
        }
    }
    
    private func filterPunches(for timeInterval: TimePeriod, from punches: [Punch]) -> [Punch] {
        let currentDate = Date()
        switch timeInterval {
        case .day:
            return punches.filter { $0.date >= Calendar.current.startOfDay(for: currentDate) }
        case .week:
            return punches.filter { $0.date >= Calendar.current.date(byAdding: .day, value: -7, to: currentDate)! }
        case .month:
            return punches.filter { $0.date >= Calendar.current.date(byAdding: .month, value: -1, to: currentDate)! }
        case .year:
            return punches.filter { $0.date >= Calendar.current.date(byAdding: .year, value: -1, to: currentDate)! }
        }
    }
    
    private func calculateAverageScore(for punches: [Punch]) -> Int {
        return punches.isEmpty ? 0 : punches.map { $0.score }.reduce(0, +) / punches.count
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
    var punches: [Punch]
    @Binding var sortOption: SortOption
    @State private var currentPage: Int = 1
    private let itemsPerPage = 5
    
    var sortedPunches: [Punch] {
        switch sortOption {
        case .date:
            return punches.sorted { $0.date > $1.date }
        case .score:
            return punches.sorted { $0.score > $1.score }
        }
    }
    
    var paginatedPunches: [Punch] {
        let startIndex = (currentPage - 1) * itemsPerPage
        let endIndex = min(startIndex + itemsPerPage, sortedPunches.count)
        return Array(sortedPunches[startIndex..<endIndex])
    }
    
    var totalPages: Int {
        (sortedPunches.count + itemsPerPage - 1) / itemsPerPage
    }
    
    var body: some View {
        VStack(alignment: .leading) {
            Picker("Sort by", selection: $sortOption) {
                Text("Date").tag(SortOption.date)
                Text("Score").tag(SortOption.score)
            }
            .pickerStyle(SegmentedPickerStyle())
            
            List(paginatedPunches) { punch in
                NavigationLink(destination: FeedbackView()) {
                    HStack {
                        Text(punch.dateFormatted)
                        Spacer()
                        Text("Score: \(punch.score)")
                    }
                    .contentShape(Rectangle())
                }
            }
            
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
}


struct Punch: Identifiable {
    var id = UUID().uuidString
    var date: Date = Date()
    var score: Int = 0
    
    var dateFormatted: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

#Preview {
    ProfileView()
}


