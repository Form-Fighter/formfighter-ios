import SwiftUI
import Charts

struct LineChartView: View {
    let data: [PunchStats]
    let timeInterval: TimePeriod
    @State private var selectedPoint: PunchStats?
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Selected point info
            if let selected = selectedPoint {
                HStack {
                    Image(systemName: "target")
                        .foregroundColor(ThemeColors.primary)
                    Text("Score: \(Int(selected.score))")
                        .font(.headline)
                        .foregroundColor(ThemeColors.primary)
                    Text("at \(formatDate(selected.timestamp, for: timeInterval))")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }
                .padding(.horizontal)
                .transition(.opacity)
            }
            
            // Chart
            Chart {
                ForEach(data, id: \.timestamp) { stat in
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
                                        selectedPoint = data.min(by: {
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
            return date.formatted(.dateTime.day())
       
        }
    }
} 
