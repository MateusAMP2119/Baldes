import SwiftUI

// MARK: - Undo Snackbar and Log Past Sheet Extensions
extension HabitDetailView {

    // MARK: - Undo Snackbar

    var undoSnackbarView: some View {
        HStack(spacing: 8) {
            Image(systemName: "trash")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textPrimary)

            if deletedEntries.count == 1, let entry = deletedEntries.first {
                Text(entry.subtitle(unit: habit.metricUnit))
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                    .lineLimit(1)
            } else {
                Text("\(deletedEntries.count) items")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            Spacer()

            Button {
                withAnimation(.spring(duration: 0.3)) {
                    // Restore to completionLogs if they were .completed
                    for entry in deletedEntries {
                        if entry.type == .completed {
                            habit.completionLogs.append(entry.date)
                        }
                    }

                    habit.activityLog.append(contentsOf: deletedEntries)
                    habit.activityLog.sort { $0.date > $1.date }  // Keep chronological sort
                    deletedEntries.removeAll()
                    showUndoSnackbar = false
                    undoTimer?.invalidate()
                }
            } label: {
                Image(systemName: "arrow.uturn.backward.circle.fill")
                    .font(.system(size: 24))
                    .foregroundStyle(habit.habitType.color)
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .frame(maxWidth: 300)
        .glassEffect()
        .clipShape(Capsule())
        .padding(.bottom, 24)
        .shadow(color: Color.black.opacity(0.1), radius: 10, y: 5)
        .transition(.move(edge: .bottom).combined(with: .opacity).combined(with: .scale))
    }

    func showSnackbar(for entries: [ActivityLogEntry]) {
        deletedEntries = entries
        withAnimation(.spring(duration: 0.3)) {
            showUndoSnackbar = true
        }

        undoTimer?.invalidate()
        undoTimer = Timer.scheduledTimer(withTimeInterval: 4.0, repeats: false) { _ in
            withAnimation(.spring(duration: 0.3)) {
                showUndoSnackbar = false
                deletedEntries.removeAll()
            }
        }
    }

    // MARK: - Log Past Activity Sheet

    var logPastActivitySheet: some View {
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

                                }
                            } label: {
                                Label("Remove 1 Entry", systemImage: "minus.circle")
                            }
                            Button(role: .destructive) {
                                withAnimation(.spring(duration: 0.3)) {
                                    habit.removeCompletions(from: pastLogDate)

                                }
                            } label: {
                                Label(
                                    "Remove From Here Onwards", systemImage: "arrow.uturn.backward")
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "minus.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(Color.red)
                                Text("Remove")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundStyle(Color.red)
                            }
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
