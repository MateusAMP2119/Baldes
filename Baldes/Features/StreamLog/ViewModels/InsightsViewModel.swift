import Foundation
import SwiftData
import SwiftUI

@Observable
class InsightsViewModel {
    var modelContext: ModelContext? = nil
    var activities: [Activity] = []
    var historyEvents: [HistoryEvent] = []

    var currentStreak: Int = 0
    var totalTimeSeconds: TimeInterval = 0
    var heatmapData: [Date: Int] = [:] // Date -> Intensity (0, 1, 2)
    var weeklyPerformance: [Int: Double] = [:] // Weekday (1-7) -> Percentage (0.0 - 1.0)
    var bestWeekday: Int? = nil // 1-7 (Sunday-Saturday)
    var betterConsistencyPercent: Int = 0
    
    // Fun Fact Data
    var funFactTitle: String = "Curiosidade"
    var funFactDescription: String = "Continue registando atividades para desbloquear factos divertidos!"

    func updateData(context: ModelContext) {
        self.modelContext = context
        fetchData()
        calculateMetrics()
    }

    private func fetchData() {
        guard let context = modelContext else { return }
        
        do {
            let activityDescriptor = FetchDescriptor<Activity>()
            self.activities = try context.fetch(activityDescriptor)

            let historyDescriptor = FetchDescriptor<HistoryEvent>(sortBy: [SortDescriptor(\.date, order: .forward)])
            self.historyEvents = try context.fetch(historyDescriptor)
        } catch {
            print("Error fetching data: \(error)")
        }
    }

    private func calculateMetrics() {
        calculateTotalTime()
        calculateStreak()
        generateHeatmapData()
        calculateWeeklyPerformance()
        generateFunFact()
    }

    private func calculateTotalTime() {
        // Simple sum of all durations
        totalTimeSeconds = historyEvents.reduce(0) { $0 + $1.duration }
    }

    private func calculateStreak() {
        // Algorithm:
        // 1. Get all unique dates from history and today.
        // 2. Iterate backwards from today.
        // 3. For each day, check if ANY activity was scheduled.
        //    - If NO activity was scheduled: Streak continues (skip day).
        //    - If YES activity was scheduled:
        //      - Did we do it? (Check history)
        //        - YES: Streak++
        //        - NO: Break streak.
        
        var streak = 0
        let calendar = Calendar.current
        var checkDate = calendar.startOfDay(for: Date())
        
        // Safety break to prevent infinite loops (e.g. check last 365 days)
        for _ in 0..<365 {
            let dayEvents = historyEvents.filter { calendar.isDate($0.date, inSameDayAs: checkDate) && $0.type == .completed }
            
            // Check if ANY activity was scheduled for this 'checkDate'
            let scheduledActivities = activities.filter { $0.isScheduledFor(date: checkDate) }
            
            if scheduledActivities.isEmpty {
                // Nothing scheduled today.
                // If we did something anyway (extra credit), it counts!
                if !dayEvents.isEmpty {
                    streak += 1
                }
                // If we did nothing, streak is preserved (don't reset, but don't increment).
                // Wait, usually streaks count *consecutive active days*.
                // But the requirement says "If I skip a day... if configured Mon/Wed... skip Tue... streak should NOT break".
                // This implies "Tue" is just ignored.
            } else {
                // Something was scheduled.
                if !dayEvents.isEmpty {
                    streak += 1
                } else {
                    // Missed a scheduled day!
                    // Exception: If checkDate is TODAY, and we haven't done it YET, don't break streak (unless it's late?).
                    // Let's be strict: if it's today and empty, current streak is based on yesterday?
                    // Usually "Current Streak" includes today if done, or up to yesterday.
                    if calendar.isDateInToday(checkDate) {
                        // If today is empty, we don't break, just don't increment yet.
                        // Continue to yesterday
                    } else {
                        break // Broken streak
                    }
                }
            }
            
            guard let prevDate = calendar.date(byAdding: .day, value: -1, to: checkDate) else { break }
            checkDate = prevDate
        }
        
        self.currentStreak = streak
    }

    private func generateHeatmapData() {
        let calendar = Calendar.current
        var map: [Date: Int] = [:]
        
        // Populate last 3 months (approx 90 days)
        let today = calendar.startOfDay(for: Date())
        for i in 0..<92 {
            if let date = calendar.date(byAdding: .day, value: -i, to: today) {
                let dayEvents = historyEvents.filter { calendar.isDate($0.date, inSameDayAs: date) && $0.type == .completed }
                
                if dayEvents.isEmpty {
                    map[date] = 0 // Gray
                } else {
                    // Check duration or count
                    let totalDuration = dayEvents.reduce(0) { $0 + $1.duration }
                    if totalDuration > 30 * 60 { // > 30 mins
                        map[date] = 2 // Dark Purple
                    } else {
                        map[date] = 1 // Light Purple
                    }
                }
            }
        }
        self.heatmapData = map
    }

    private func calculateWeeklyPerformance() {
        // Map: Weekday (1=Sun) -> Success Rate (0.0 - 1.0)
        var dayStats: [Int: (completed: Int, scheduled: Int)] = [:]
        let calendar = Calendar.current
        
        // Analyze last 30 days
        let today = calendar.startOfDay(for: Date())
        for i in 0..<30 {
            guard let date = calendar.date(byAdding: .day, value: -i, to: today) else { continue }
            let weekday = calendar.component(.weekday, from: date)
            
            let scheduledCount = activities.filter { $0.isScheduledFor(date: date) }.count
            let completedCount = historyEvents.filter { calendar.isDate($0.date, inSameDayAs: date) && $0.type == .completed }.count
            
            // Normalize: If scheduled 0, but completed 1, counts as 1/1 bonus? Or ignore?
            // Let's simplify: Track "Consistency" = Completed / Scheduled (capped at 1.0)
            
            if scheduledCount > 0 {
                let current = dayStats[weekday] ?? (0, 0)
                dayStats[weekday] = (current.completed + min(completedCount, scheduledCount), current.scheduled + scheduledCount)
            }
        }
        
        var performance: [Int: Double] = [:]
        for (day, stats) in dayStats {
            if stats.scheduled > 0 {
                performance[day] = Double(stats.completed) / Double(stats.scheduled)
            } else {
                performance[day] = 0.0
            }
        }
        self.weeklyPerformance = performance
        
        // Find best day
        let sortedDays = performance.sorted { $0.value > $1.value }
        if let best = sortedDays.first {
            self.bestWeekday = best.key
            // Compare with average of others? Or worst?
            // "20% more consistent on Tuesdays"
            let othersAvg = sortedDays.dropFirst().map(\.value).reduce(0, +) / max(1, Double(sortedDays.count - 1))
            if othersAvg > 0 {
                self.betterConsistencyPercent = Int(((best.value - othersAvg) / othersAvg) * 100)
            } else {
                self.betterConsistencyPercent = 100
            }
        }
    }
    
    private func generateFunFact() {
        // "You've practiced 'Reading' for 48 hours. That's equivalent to watching LOTR trilogy 4 times!"
        
        // Find activity with most duration
        let grouped = Dictionary(grouping: historyEvents) { $0.activityName }
        let sorted = grouped.map { (key, value) -> (String, TimeInterval) in
            (key, value.reduce(0) { $0 + $1.duration })
        }.sorted { $0.1 > $1.1 }
        
        if let top = sorted.first {
            let hours = top.1 / 3600
            
            if hours > 10 {
                let lotrTrilogyHours = 11.4 // Extended edition obviously
                let times = max(1, Int(hours / lotrTrilogyHours))
                
                funFactTitle = "Mestre em \(top.0)"
                funFactDescription = "Você já praticou '\(top.0)' por \(Int(hours)) horas. Isso equivale a assistir a trilogia O Senhor dos Anéis \(times) vezes!"
            } else if hours > 2 {
                funFactTitle = "Bom começo!"
                funFactDescription = "Você já dedicou \(Int(hours)) horas a '\(top.0)'. Continue assim!"
            } else {
                funFactTitle = "Primeiros Passos"
                funFactDescription = "Cada minuto conta. Você já começou sua jornada em '\(top.0)'."
            }
        }
    }
    
    // Helper for formatting
    func formattedTotalTime() -> String {
        let hours = Int(totalTimeSeconds) / 3600
        let minutes = (Int(totalTimeSeconds) % 3600) / 60
        return "\(hours)h \(minutes)m"
    }
}
