import SwiftData
import SwiftUI
import UIKit

struct HabitDetailView: View {
    let habit: HabitEntry
    let selectedDate: Date

    @State private var showLogPastSheet = false
    @State private var pastLogDate = Date()
    @State private var showCompletionFeedback = false
    @State private var showEditSheet = false
    @State private var showArchiveConfirm = false
    @State private var refreshToken = UUID()
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    private let calendar = Calendar.current

    // MARK: - Computed Properties

    private var streakCount: Int {
        guard !habit.completionLogs.isEmpty else { return 0 }
        let today = calendar.startOfDay(for: Date())
        var streak = 0
        var checkDate = today

        while true {
            let hasCompletion = habit.completionLogs.contains {
                calendar.isDate($0, inSameDayAs: checkDate)
            }
            if hasCompletion {
                streak += 1
                checkDate = calendar.date(byAdding: .day, value: -1, to: checkDate)!
            } else {
                break
            }
        }
        return streak
    }

    // MARK: - Body

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                if habit.habitType != .todo {
                    HabitDetailMascotCard(
                        habit: habit, selectedDate: selectedDate, streakCount: streakCount)
                    HabitDetailQuoteCard(habit: habit)
                } else {
                    HStack(alignment: .bottom, spacing: 0) {
                        Image(habit.habitType.mascotImageName)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 86, height: 86)
                            .offset(y: 4)

                        HabitDetailQuoteCard(habit: habit)
                    }
                }

                HabitDetailInfoRows(habit: habit)

                HabitDetailTypeContent(
                    habit: habit,
                    selectedDate: selectedDate,
                    onLogCompletion: logCompletion,
                    onUndo: undoCompletion,
                    onLogPast: {
                        pastLogDate = selectedDate
                        showLogPastSheet = true
                    }
                )

                HabitDetailStats(
                    habit: habit,
                    selectedDate: selectedDate,
                    onRemoveLastCompletion: { date in
                        withAnimation(.spring(duration: 0.3)) {
                            habit.removeLastCompletion(on: date)
                            refreshToken = UUID()
                        }
                    },
                    onRemoveAllCompletions: { date in
                        withAnimation(.spring(duration: 0.3)) {
                            habit.removeAllCompletions(on: date)
                            refreshToken = UUID()
                        }
                    },
                    onRemoveCompletionsFrom: { date in
                        withAnimation(.spring(duration: 0.3)) {
                            habit.removeCompletions(from: date)
                            refreshToken = UUID()
                        }
                    }
                )
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .padding(.bottom, 40)
            .id(refreshToken)
        }
        .background(
            LinearGradient(
                colors: [habit.habitType.gradientColor, .white],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.35)
            )
            .ignoresSafeArea()
        )
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                VStack(spacing: 1) {
                    Text(habit.name)
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    if streakCount > 0 {
                        HStack(spacing: 3) {
                            Text("\(streakCount) Day Streak")
                                .font(.system(size: 11, weight: .medium))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        showEditSheet = true
                    } label: {
                        Label("Edit", systemImage: "pencil")
                    }
                    Button {
                    } label: {
                        Label("Share", systemImage: "square.and.arrow.up")
                    }
                    Button(role: .destructive) {
                        showArchiveConfirm = true
                    } label: {
                        Label("Archive", systemImage: "archivebox")
                    }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
        .tint(habit.habitType.color)
        .sheet(isPresented: $showLogPastSheet) {
            logPastSheet
        }
        .sheet(isPresented: $showEditSheet) {
            NavigationStack {
                AddHabitFormView(
                    habitType: habit.habitType,
                    existingHabit: habit,
                    dismissSheet: { showEditSheet = false }
                )
            }
        }
        .confirmationDialog(
            "Archive Habit", isPresented: $showArchiveConfirm, titleVisibility: .visible
        ) {
            Button("Archive", role: .destructive) {
                NotificationManager.shared.cancelNotifications(for: habit)
                habit.archivedDate = selectedDate
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This habit will be moved to your archive. You can restore it later.")
        }
    }

    // MARK: - Actions

    private func logCompletion() {
        withAnimation(.spring(duration: 0.3)) {
            habit.addCompletion(on: selectedDate)
            refreshToken = UUID()
        }
        let impact = UIImpactFeedbackGenerator(style: .medium)
        impact.impactOccurred()
    }

    private func undoCompletion() {
        let isToday = calendar.isDateInToday(selectedDate)
        withAnimation(.spring(duration: 0.3)) {
            if isToday {
                habit.removeLastCompletion(on: selectedDate)
            } else {
                habit.removeCompletions(from: selectedDate)
            }
            refreshToken = UUID()
        }
    }

    // MARK: - Log Past Activity Sheet

    private var logPastSheet: some View {
        NavigationStack {
            VStack(spacing: 24) {
                VStack(spacing: 8) {
                    Text(habit.emoji)
                        .font(.system(size: 40))
                    Text("Log Past Activity")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                    Text("Select a date to log a completion for \(habit.name)")
                        .font(.system(size: 14))
                        .foregroundStyle(Color.textSecondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.top, 8)

                DatePicker(
                    "Date",
                    selection: $pastLogDate,
                    in: habit.startDate...Date(),
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .tint(habit.habitType.color)

                let pastCount = habit.completionCount(on: pastLogDate)
                if pastCount > 0 {
                    HStack(spacing: 6) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 14))
                            .foregroundStyle(habit.habitType.color)
                        Text("Already \(pastCount)\u{00D7} logged on this date")
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(Color.textSecondary)
                        Spacer()
                        Menu {
                            Button(role: .destructive) {
                                withAnimation(.spring(duration: 0.3)) {
                                    habit.removeLastCompletion(on: pastLogDate)
                                    refreshToken = UUID()
                                }
                            } label: {
                                Label("Remove 1 Entry", systemImage: "minus.circle")
                            }
                            Button(role: .destructive) {
                                withAnimation(.spring(duration: 0.3)) {
                                    habit.removeCompletions(from: pastLogDate)
                                    refreshToken = UUID()
                                }
                            } label: {
                                Label(
                                    "Remove From Here Onwards", systemImage: "arrow.uturn.backward")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 13))
                                Text("Remove")
                                    .font(.system(size: 12, weight: .semibold))
                            }
                            .foregroundStyle(.red)
                        }
                    }
                }

                Button {
                    withAnimation(.spring(duration: 0.3)) {
                        habit.addCompletion(on: pastLogDate)
                    }
                    let impact = UIImpactFeedbackGenerator(style: .medium)
                    impact.impactOccurred()
                    showLogPastSheet = false
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "checkmark.circle.fill")
                            .font(.system(size: 16))
                        Text("Log Completion")
                            .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(Capsule().fill(habit.habitType.color))
                }
                .padding(.horizontal, 20)

                Spacer()
            }
            .padding(.horizontal, 20)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        showLogPastSheet = false
                    }
                }
            }
        }
        .presentationDetents([.large])
        .presentationBackground(Color.bgPage)
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var habit: HabitEntry?
        let container: ModelContainer

        init() {
            let config = ModelConfiguration(isStoredInMemoryOnly: true)
            let c = try! ModelContainer(for: HabitEntry.self, configurations: config)
            self.container = c
        }

        var body: some View {
            NavigationStack {
                if let habit {
                    HabitDetailView(habit: habit, selectedDate: .now)
                }
            }
            .modelContainer(container)
            .onAppear {
                let h = HabitEntry(
                    name: "Morning Run",
                    emoji: "\u{1F3C3}",
                    habitTypeRaw: "timed",
                    motivationQuote: "The only true wisdom is in knowing you know nothing.",
                    hasTime: true,
                    scheduleTime: Calendar.current.date(
                        bySettingHour: 7, minute: 0, second: 0, of: Date()),
                    frequency: 1,
                    selectedDays: [],
                    startDate: Calendar.current.date(byAdding: .month, value: -1, to: Date())!,
                    endDateEnabled: false,
                    endDate: nil,
                    reminderEnabled: false,
                    reminderTime: nil,
                    completionLogs: [
                        Date(),
                        Date(),
                        Calendar.current.date(byAdding: .day, value: -1, to: Date())!,
                        Calendar.current.date(byAdding: .day, value: -2, to: Date())!,
                    ]
                )
                container.mainContext.insert(h)
                habit = h
            }
        }
    }

    return PreviewWrapper()
}
