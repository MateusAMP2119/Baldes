import SwiftData
import SwiftUI

struct ArchivedHabitsView: View {
    @Query private var allHabits: [HabitEntry]
    @Environment(\.modelContext) private var modelContext

    private var archivedHabits: [HabitEntry] {
        allHabits
            .filter { $0.archivedDate != nil || $0.isCompleted(on: Date()) }
            .sorted {
                // Most recently archived first
                let dateA = $0.archivedDate ?? .distantPast
                let dateB = $1.archivedDate ?? .distantPast
                return dateA > dateB
            }
    }

    var body: some View {
        Group {
            if archivedHabits.isEmpty {
                emptyState
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(spacing: 0) {
                        ForEach(Array(archivedHabits.enumerated()), id: \.element.id) {
                            index, habit in
                            NavigationLink(value: habit) {
                                archivedRow(habit: habit)
                            }
                            .buttonStyle(.plain)

                            if index < archivedHabits.count - 1 {
                                Rectangle()
                                    .fill(Color.dividerColor)
                                    .frame(height: 1)
                                    .padding(.horizontal, 16)
                            }
                        }
                    }
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 14))
                    .overlay(
                        RoundedRectangle(cornerRadius: 14)
                            .strokeBorder(Color.borderStrong, lineWidth: 2)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(Color.shadowOrange)
                            .offset(x: 4, y: 4)
                    )
                    .padding(.horizontal, 20)
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
            }
        }
        .background(Color.bgPage.ignoresSafeArea())
        .navigationTitle("Archived")
        .navigationBarTitleDisplayMode(.large)
    }

    // MARK: - Row

    private func archivedRow(habit: HabitEntry) -> some View {
        HStack(spacing: 14) {
            Text(habit.emoji)
                .font(.system(size: 24))

            VStack(alignment: .leading, spacing: 3) {
                Text(habit.name)
                    .font(.system(size: 15, weight: .bold))
                    .foregroundStyle(Color.textPrimary)

                HStack(spacing: 6) {
                    // Type tag
                    Text(habit.categoryName)
                        .font(.system(size: 10, weight: .heavy))
                        .foregroundStyle(habit.accentColor)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 3)
                        .background(
                            Capsule().fill(habit.accentColor.opacity(0.12))
                        )

                    // Status
                    if habit.isCompleted(on: Date()) {
                        Text("Completed")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.accentGreen)
                    } else if let date = habit.archivedDate {
                        Text("Archived \(formattedRelativeDate(date))")
                            .font(.system(size: 11, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                    }
                }
            }

            Spacer()

            // Context menu for actions
            Menu {
                Button {
                    restoreHabit(habit)
                } label: {
                    Label("Restore", systemImage: "arrow.uturn.backward.circle")
                }

                Button(role: .destructive) {
                    deleteHabitPermanently(habit)
                } label: {
                    Label("Delete Permanently", systemImage: "trash")
                }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 32, height: 32)
                    .contentShape(Rectangle())
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .contentShape(Rectangle())
    }

    // MARK: - Empty State

    private var emptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "archivebox")
                .font(.system(size: 48, weight: .light))
                .foregroundStyle(Color.textTertiary)

            VStack(spacing: 6) {
                Text("No archived habits")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color.textSecondary)

                Text("Habits you archive or complete\nwill appear here")
                    .font(.system(size: 14))
                    .foregroundStyle(Color.textTertiary)
                    .multilineTextAlignment(.center)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(.vertical, 80)
    }

    // MARK: - Actions

    private func restoreHabit(_ habit: HabitEntry) {
        withAnimation(.spring(duration: 0.3)) {
            habit.unarchive()
        }
    }

    private func deleteHabitPermanently(_ habit: HabitEntry) {
        NotificationManager.shared.cancelNotifications(for: habit)
        withAnimation(.easeOut(duration: 0.3)) {
            modelContext.delete(habit)
        }
    }

    // MARK: - Helpers

    private func formattedRelativeDate(_ date: Date) -> String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: date, relativeTo: Date())
    }
}

#Preview {
    NavigationStack {
        ArchivedHabitsView()
            .modelContainer(for: HabitEntry.self, inMemory: true)
    }
}
