import SwiftData
import SwiftUI
import UIKit

struct HabitDetailView: View {
    let habit: HabitEntry
    @State var selectedDate: Date

    init(habit: HabitEntry, selectedDate: Date) {
        self.habit = habit
        self._selectedDate = State(initialValue: selectedDate)
    }

    @State var showLogPastSheet = false
    @State var pastLogDate = Date()
    @State private var showCompletionFeedback = false
    @State private var showEditSheet = false
    @State private var showArchiveConfirm = false
    @State private var showCountdownSheet = false
    @State private var showStopwatchSheet = false
    @State private var selectedLogGroupForNote: GroupedActivity?

    // Undo buffer elevated from Content
    @State var deletedEntries: [ActivityLogEntry] = []
    @State var showUndoSnackbar = false
    @State var undoTimer: Timer? = nil

    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    private let calendar = Calendar.current

    // MARK: - Day Navigation

    private var canGoBack: Bool {
        let previous = calendar.date(byAdding: .day, value: -1, to: selectedDate)!
        return calendar.startOfDay(for: previous) >= calendar.startOfDay(for: habit.startDate)
    }

    private var canGoForward: Bool {
        let next = calendar.date(byAdding: .day, value: 1, to: selectedDate)!
        let upperBound = habit.endDateEnabled ? (habit.endDate ?? Date()) : Date()
        return calendar.startOfDay(for: next) <= calendar.startOfDay(for: upperBound)
    }

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

    private var dynamicTitle: String {
        let calendar = Calendar.current
        if calendar.isDateInToday(selectedDate) {
            return "Details"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Details (Yesterday)"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Details (Tomorrow)"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MMM d"
            return "Details (\(formatter.string(from: selectedDate)))"
        }
    }

    // MARK: - Day Navigation (toolbar title)

    private var dayNavigationTitle: String {
        if calendar.isDateInToday(selectedDate) {
            return "Today"
        } else if calendar.isDateInYesterday(selectedDate) {
            return "Yesterday"
        } else if calendar.isDateInTomorrow(selectedDate) {
            return "Tomorrow"
        } else {
            let formatter = DateFormatter()
            formatter.dateFormat = "EEE, MMM d"
            return formatter.string(from: selectedDate)
        }
    }

    // MARK: - Body

    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 0) {
                    // Compact header
                    HStack(spacing: 10) {
                        Text(habit.emoji)
                            .font(.system(size: 28))

                        VStack(alignment: .leading, spacing: 2) {
                            Text(habit.name)
                                .font(.system(size: streakCount > 0 ? 16 : 18, weight: .bold))
                                .foregroundStyle(Color.textPrimary)
                                .lineLimit(1)

                            if streakCount > 0 {
                                HStack(spacing: 3) {
                                    Text("\(streakCount)d streak")
                                        .font(.system(size: 11, weight: .semibold))
                                }
                                .foregroundStyle(habit.habitType.color)
                                .transition(.opacity)
                            }
                        }
                        .frame(height: 38, alignment: .leading)
                        .animation(.smooth(duration: 0.2), value: streakCount > 0)

                        Spacer()
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 4)
                    .padding(.bottom, 16)

                    // Motivation quote
                    if !habit.motivationQuote.isEmpty {
                        HabitDetailQuoteCard(habit: habit)
                            .padding(.horizontal, 20)
                            .padding(.bottom, 16)
                    }

                    // Info
                    HabitDetailInfoRows(habit: habit)
                        .padding(.horizontal, 20)
                        .padding(.bottom, 16)

                    // Type-specific content
                    HabitDetailTypeContent(
                        habit: habit,
                        selectedDate: selectedDate,
                        onLogCompletion: logCompletion,
                        onLogTimedCompletion: logTimedCompletion,
                        onLogMultiple: logMultipleCompletions,
                        onUndo: undoCompletion,
                        onLogPast: {
                            pastLogDate = selectedDate
                            showLogPastSheet = true
                        },
                        onStartCountdown: { showCountdownSheet = true },
                        onStartStopwatch: { showStopwatchSheet = true },
                        onAddNote: { group in
                            selectedLogGroupForNote = group
                        },
                        onDeleteMemory: { entries in
                            showSnackbar(for: entries)
                        }
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                }
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            if showUndoSnackbar, !deletedEntries.isEmpty {
                undoSnackbarView
            }
        }
        .background(Color(UIColor.systemBackground).ignoresSafeArea())
        .navigationBarBackButtonHidden()
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                }
            }

            ToolbarItem(placement: .principal) {
                HStack(spacing: 6) {
                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = calendar.date(
                                byAdding: .day, value: -1, to: selectedDate)!
                        }
                    } label: {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(canGoBack ? Color.textSecondary : .clear)
                    }
                    .disabled(!canGoBack)

                    Text(dayNavigationTitle)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    Button {
                        withAnimation(.easeInOut(duration: 0.2)) {
                            selectedDate = calendar.date(
                                byAdding: .day, value: 1, to: selectedDate)!
                        }
                    } label: {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 11, weight: .semibold))
                            .foregroundStyle(canGoForward ? Color.textSecondary : .clear)
                    }
                    .disabled(!canGoForward)
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
                    Button {
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
        .tint(Color.textPrimary)
        .sheet(isPresented: $showLogPastSheet) {
            logPastActivitySheet
        }
        .sheet(isPresented: $showCountdownSheet) {
            CountdownSessionView(habit: habit) {
                logCompletion()
                showCountdownSheet = false
            }
            .presentationDetents([.large])
            .presentationBackground(Color.bgPage)
        }
        .sheet(isPresented: $showStopwatchSheet) {
            StopwatchSessionView(habit: habit) {
                logCompletion()
                showStopwatchSheet = false
            }
            .presentationDetents([.large])
            .presentationBackground(Color.bgPage)
        }
        .sheet(item: $selectedLogGroupForNote) { group in
            HabitAddNoteSheet(habit: habit, selectedDate: selectedDate, selectedGroup: group) {
                selectedLogGroupForNote = nil
            }
            .presentationDetents([.medium])
            .presentationBackground(Color.bgPage)
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
                habit.logActivity(.archived)
                habit.archivedDate = selectedDate
                dismiss()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This habit will be moved to your archive. You can restore it later.")
        }
    }

}
