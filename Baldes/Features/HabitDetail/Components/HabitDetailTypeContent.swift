import SwiftUI

struct HabitDetailTypeContent: View {
    let habit: HabitEntry
    let selectedDate: Date
    let calendar = Calendar.current

    var onLogCompletion: () -> Void
    var onUndo: () -> Void
    var onLogPast: () -> Void
    var onStartCountdown: () -> Void
    var onStartStopwatch: () -> Void
    var onAddNote: (GroupedActivity) -> Void
    var onDeleteMemory: ([ActivityLogEntry]) -> Void

    @State private var isEditingLog = false
    @State private var selectedLogIDs: Set<UUID> = []
    @State private var showAllActivity = false

    var body: some View {
        mainContentInner
    }

    @ViewBuilder
    private var mainContentInner: some View {
        switch habit.habitType {
        case .timed:
            timedContent
        case .metrics:
            metricsContent
        case .dailyGoals:
            dailyGoalsContent
        case .todo:
            checklistContent
        case .routes:
            routeContent
        case .budgets:
            budgetContent
        case .notes, .journal:
            notesContent
        }
    }

    private var timedContent: some View {
        HabitDetailTimedContent(
            habit: habit,
            selectedDate: selectedDate,
            onStartCountdown: onStartCountdown,
            onStartStopwatch: onStartStopwatch,
            onUndo: onUndo
        )
    }

    // MARK: - Metrics Content

    private var metricsContent: some View {
        HabitDetailMetricsContent(
            habit: habit,
            selectedDate: selectedDate,
            onLogCompletion: onLogCompletion,
            onUndo: onUndo,
            onAddNote: onAddNote,
            onDeleteMemory: onDeleteMemory,
            isEditingLog: $isEditingLog,
            selectedLogIDs: $selectedLogIDs,
            showAllActivity: $showAllActivity
        )
    }

    // MARK: - Daily Goals Content

    private var dailyGoalsContent: some View {
        HabitDetailDailyGoalsContent(
            habit: habit,
            selectedDate: selectedDate,
            onLogCompletion: onLogCompletion,
            onUndo: onUndo
        )
    }

    // MARK: - Checklist Content

    private var checklistContent: some View {
        HabitDetailChecklistContent(
            habit: habit,
            selectedDate: selectedDate
        )
    }

    // MARK: - Route Content

    private var routeContent: some View {
        HabitDetailRouteContent(
            habit: habit,
            selectedDate: selectedDate,
            onLogCompletion: onLogCompletion,
            onUndo: onUndo
        )
    }

    // MARK: - Budget Content

    private var budgetContent: some View {
        HabitDetailBudgetContent(
            habit: habit,
            selectedDate: selectedDate,
            onLogCompletion: onLogCompletion,
            onUndo: onUndo
        )
    }

    // MARK: - Notes / Journal Content

    private var notesContent: some View {
        HabitDetailNotesContent(
            habit: habit,
            selectedDate: selectedDate,
            onLogCompletion: onLogCompletion,
            onUndo: onUndo
        )
    }
}
