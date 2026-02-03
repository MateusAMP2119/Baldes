import SwiftData
import SwiftUI

struct StreamLogView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var viewModel = InsightsViewModel()

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                if viewModel.historyEvents.count < 1 {
                    ZeroStateView()
                } else {
                    // 1. Hero Section: Momentum
                    MomentumCard(
                        streakDays: viewModel.currentStreak,
                        totalTime: viewModel.formattedTotalTime()
                    )

                    // 2. Consistency Map: History
                    ConsistencyHeatmap(data: viewModel.heatmapData)

                    // 3. The Debugger: Weekly Performance
                    WeeklyPerformanceChart(
                        data: viewModel.weeklyPerformance,
                        bestDay: viewModel.bestWeekday,
                        improvementPercent: viewModel.betterConsistencyPercent
                    )

                    // 4. The Fun Card: Context
                    FunContextCard(
                        title: viewModel.funFactTitle,
                        description: viewModel.funFactDescription
                    )
                }
            }
            .padding()
            .padding(.bottom, 80) // Space for tab bar
        }
        .background(Color("AppBackground").ignoresSafeArea())
        .onAppear {
            viewModel.updateData(context: modelContext)
        }
        .refreshable {
            viewModel.updateData(context: modelContext)
        }
    }
}

#Preview {
    StreamLogView()
}
