import SwiftUI
import Charts

struct AveragedPunchStats: Identifiable, Equatable {
    let id = UUID()
    let timestamp: Date
    let score: Double
    let count: Int  // Number of punches averaged
    
    static func == (lhs: AveragedPunchStats, rhs: AveragedPunchStats) -> Bool {
        lhs.timestamp == rhs.timestamp &&
        lhs.score == rhs.score &&
        lhs.count == rhs.count
    }
}

struct LineChartView: View {
    let data: [PunchStats]
    let timeInterval: TimePeriod
    @State private var selectedPoint: AveragedPunchStats?
    
    private var averagedData: [AveragedPunchStats] {
        let calendar = Calendar.current
        
        // Get the latest timestamp and round it up
        guard let latestDate = data.map({ $0.timestamp }).max() else { return [] }
        
        let components: Set<Calendar.Component> = {
            switch timeInterval {
            case .day: return [.year, .month, .day, .hour]
            case .week, .month: return [.year, .month, .day]
            }
        }()
        
        let roundedLatestDate = calendar.date(from: calendar.dateComponents(components, from: latestDate))!
        
        // Calculate the start date based on the time interval
        let startDate: Date = {
            switch timeInterval {
            case .day:
                return calendar.date(byAdding: .hour, value: -23, to: roundedLatestDate)!
            case .week:
                return calendar.date(byAdding: .day, value: -6, to: roundedLatestDate)!
            case .month:
                return calendar.date(byAdding: .day, value: -29, to: roundedLatestDate)!
            }
        }()
        
        // Create time slots with appropriate grouping
        var timeSlots: [Date] = []
        var currentDate = startDate
        
        while currentDate <= roundedLatestDate {
            timeSlots.append(currentDate)
            switch timeInterval {
            case .day:
                currentDate = calendar.date(byAdding: .hour, value: 3, to: currentDate)! // 3-hour intervals
            case .week:
                currentDate = calendar.date(byAdding: .day, value: 1, to: currentDate)! // Daily intervals
            case .month:
                currentDate = calendar.date(byAdding: .day, value: 7, to: currentDate)! // Weekly intervals
            }
        }
        
        // Group and average the data
        let rawAveraged = timeSlots.map { slotDate in
            let slotData = data.filter { stat in
                switch timeInterval {
                case .day:
                    // Check if stat falls within 3-hour interval
                    let intervalEnd = calendar.date(byAdding: .hour, value: 3, to: slotDate)!
                    return stat.timestamp >= slotDate && stat.timestamp < intervalEnd
                case .week:
                    return calendar.compare(stat.timestamp, to: slotDate, toGranularity: .day) == .orderedSame
                case .month:
                    // Check if stat falls within the week
                    let weekEnd = calendar.date(byAdding: .day, value: 7, to: slotDate)!
                    return stat.timestamp >= slotDate && stat.timestamp < weekEnd
                }
            }
            
            let averageScore = slotData.isEmpty ? 0 : slotData.map { $0.score }.reduce(0, +) / Double(slotData.count)
            return AveragedPunchStats(timestamp: slotDate, score: averageScore, count: slotData.count)
        }
        
        // Filter out zeros and consecutive zero periods
        return rawAveraged.enumerated().compactMap { index, stat in
            if stat.count == 0 {
                // Keep single zero between non-zero values
                let prevHasData = index > 0 && rawAveraged[index - 1].count > 0
                let nextHasData = index < rawAveraged.count - 1 && rawAveraged[index + 1].count > 0
                return prevHasData && nextHasData ? stat : nil
            }
            return stat
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Selected point info
            if let selected = selectedPoint {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(ThemeColors.primary)
                    Text("Avg Score: \(Int(selected.score))")
                        .font(.headline)
                        .foregroundColor(ThemeColors.primary)
                    Text("(\(selected.count) punches)")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                    Text("at \(formatDate(selected.timestamp, for: timeInterval))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .transition(.opacity)
            }
            
            // Chart
            Chart {
                ForEach(averagedData) { stat in
                    LineMark(
                        x: .value("Time", stat.timestamp),
                        y: .value("Score", stat.score)
                    )
                    .foregroundStyle(ThemeColors.primary)
                    
                    PointMark(
                        x: .value("Time", stat.timestamp),
                        y: .value("Score", stat.score)
                    )
                    .foregroundStyle(ThemeColors.primary)
                    .symbolSize(selectedPoint?.timestamp == stat.timestamp ? 150 : 100)
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let date = value.as(Date.self) {
                            Text(formatDate(date, for: timeInterval))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let score = value.as(Double.self) {
                            Text("\(Int(score))")
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                    }
                }
            }
            .frame(height: 250)
            .padding(.horizontal, 20)
            .padding(.vertical, 10)
            .chartOverlay { proxy in
                GeometryReader { geometry in
                    Rectangle()
                        .fill(.clear)
                        .contentShape(Rectangle())
                        .gesture(
                            DragGesture(minimumDistance: 0)
                                .onChanged { value in
                                    let xPosition = value.location.x
                                    if let date = proxy.value(atX: xPosition, as: Date.self) {
                                        selectedPoint = averagedData.min(by: {
                                            abs($0.timestamp.timeIntervalSince(date)) < abs($1.timestamp.timeIntervalSince(date))
                                        })
                                    }
                                }
                                .onEnded { _ in
                                    // Optionally clear selection when done dragging
                                    // selectedPoint = nil
                                }
                        )
                }
            }
        }
        .padding()
        .background(ThemeColors.background.opacity(0.5))
        .cornerRadius(12)
        .animation(.easeInOut(duration: 0.2), value: selectedPoint)
    }
    
    private func formatDate(_ date: Date, for period: TimePeriod) -> String {
        switch period {
        case .day:
            return date.formatted(.dateTime.hour())
        case .week:
            return date.formatted(.dateTime.weekday(.abbreviated))
        case .month:
            return date.formatted(.dateTime.month(.abbreviated)) + " " + 
                   date.formatted(.dateTime.day())
        }
    }
} 
