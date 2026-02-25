import SwiftUI

// MARK: - Checklist Grouped Card

/// A grouped iOS-style card that displays checklist items in a unified
/// card with inline editing, matching the style of MetricsGroupedCard,
/// TimerGroupedCard, and ScheduleGroupedCard.
struct ChecklistGroupedCard: View {
    let label: String
    let accentColor: Color
    @Binding var items: [TodoItem]

    @State private var newItemText = ""
    @State private var expandedDeadlineIndex: Int? = nil
    @State private var recentlyDeleted: (item: TodoItem, index: Int)? = nil
    @FocusState private var isNewItemFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // MARK: - Existing Items
                ForEach(Array(items.enumerated()), id: \.element.id) { index, _ in
                    if index > 0 {
                        divider
                    }

                    itemRow(at: index)
                }

                if items.isEmpty {
                    // MARK: - Empty State
                    emptyStateRow
                    divider
                } else {
                    divider
                }

                // MARK: - Add New Item Row
                addItemRow
            }
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)

            // Undo banner
            if let deleted = recentlyDeleted {
                HStack(spacing: 8) {
                    Image(systemName: "trash")
                        .font(.system(size: 12))
                    Text("\"\(deleted.item.title)\" removed")
                        .font(.system(size: 13, weight: .medium))
                        .lineLimit(1)
                    Spacer()
                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            let safeIndex = min(deleted.index, items.count)
                            items.insert(deleted.item, at: safeIndex)
                            recentlyDeleted = nil
                        }
                    } label: {
                        Text("Undo")
                            .font(.system(size: 13, weight: .bold))
                            .foregroundStyle(accentColor)
                    }
                    .buttonStyle(.plain)
                }
                .foregroundStyle(Color.textSecondary)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color(hex: "F5F5F5"))
                )
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }
        }
        .animation(.spring(duration: 0.3), value: items)
        .animation(.spring(duration: 0.25), value: recentlyDeleted?.item.id)
    }

    // MARK: - Item Row

    private func itemRow(at index: Int) -> some View {
        VStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
                // Title row: checkbox + text field + deadline + delete
                HStack(spacing: 10) {
                    RoundedRectangle(cornerRadius: 6)
                        .strokeBorder(accentColor, lineWidth: 2)
                        .frame(width: 22, height: 22)

                    TextField("Item name", text: $items[index].title)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textPrimary)

                    // Add deadline button (only when no deadline set)
                    if items[index].deadline == nil {
                        Button {
                            withAnimation(.spring(duration: 0.25)) {
                                items[index].deadline = Calendar.current.date(
                                    byAdding: .day, value: 1, to: Date()
                                )
                                expandedDeadlineIndex = index
                            }
                        } label: {
                            Image(systemName: "calendar.badge.plus")
                                .font(.system(size: 14))
                                .foregroundStyle(Color.textTertiary)
                        }
                        .buttonStyle(.plain)
                    }

                    Button {
                        withAnimation(.spring(duration: 0.25)) {
                            if expandedDeadlineIndex == index {
                                expandedDeadlineIndex = nil
                            }
                            let deleted = items.remove(at: index)
                            recentlyDeleted = (item: deleted, index: index)
                        }
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 12, weight: .medium))
                            .foregroundStyle(Color.textTertiary)
                    }
                    .buttonStyle(.plain)
                }

                // Deadline badge (only when deadline exists AND picker is closed)
                if let deadline = items[index].deadline,
                   expandedDeadlineIndex != index {
                    HStack(spacing: 8) {
                        Color.clear.frame(width: 22, height: 1)

                        Button {
                            withAnimation(.spring(duration: 0.25)) {
                                expandedDeadlineIndex = index
                            }
                        } label: {
                            let isOverdue = deadline < Date()
                            HStack(spacing: 4) {
                                Image(systemName: "clock")
                                    .font(.system(size: 10))
                                Text(shortDate(deadline))
                                    .font(.system(size: 11, weight: .semibold))
                            }
                            .foregroundStyle(isOverdue ? .red : accentColor)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule().fill(
                                    (isOverdue ? Color.red : accentColor).opacity(0.1)
                                )
                            )
                        }
                        .buttonStyle(.plain)

                        Spacer()
                    }
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)

            // Inline deadline picker
            if expandedDeadlineIndex == index {
                VStack(spacing: 8) {
                    DatePicker(
                        "Deadline",
                        selection: deadlineBinding(for: index),
                        displayedComponents: [.date, .hourAndMinute]
                    )
                    .datePickerStyle(.compact)
                    .tint(accentColor)

                    HStack(spacing: 16) {
                        Button {
                            withAnimation(.spring(duration: 0.25)) {
                                items[index].deadline = nil
                                expandedDeadlineIndex = nil
                            }
                        } label: {
                            HStack(spacing: 4) {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 12))
                                Text("Remove")
                                    .font(.system(size: 12, weight: .medium))
                            }
                            .foregroundStyle(Color.textTertiary)
                        }
                        .buttonStyle(.plain)

                        Spacer()

                        Button {
                            withAnimation(.spring(duration: 0.25)) {
                                expandedDeadlineIndex = nil
                            }
                        } label: {
                            Text("Done")
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(accentColor)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 16)
                .padding(.bottom, 12)
                .transition(.opacity.combined(with: .move(edge: .top)))
            }
        }
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Empty State

    private var emptyStateRow: some View {
        VStack(spacing: 4) {
            Image(systemName: "checklist")
                .font(.system(size: 24))
                .foregroundStyle(Color.textTertiary)

            Text("Add the items you want to\ncheck off")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .transition(.opacity)
    }

    // MARK: - Add Item Row

    private var addItemRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "square.and.pencil")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accentColor)

            TextField("Write a task...", text: $newItemText)
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)
                .focused($isNewItemFocused)
                .onSubmit {
                    addItem()
                }

            if !newItemText.isEmpty {
                Button {
                    addItem()
                } label: {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(accentColor)
                }
                .buttonStyle(.plain)
                .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .animation(.spring(duration: 0.2), value: newItemText.isEmpty)
    }

    // MARK: - Helpers

    private func addItem() {
        let trimmed = newItemText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        items.append(TodoItem(title: trimmed))
        newItemText = ""
        isNewItemFocused = true
    }

    private func deadlineBinding(for index: Int) -> Binding<Date> {
        Binding<Date>(
            get: { items[index].deadline ?? Date() },
            set: { items[index].deadline = $0 }
        )
    }

    private func shortDate(_ date: Date) -> String {
        let calendar = Calendar.current
        let formatter = DateFormatter()

        if calendar.isDateInToday(date) {
            formatter.dateFormat = "'Today' h:mm a"
        } else if calendar.isDateInTomorrow(date) {
            formatter.dateFormat = "'Tomorrow' h:mm a"
        } else if calendar.isDate(date, equalTo: Date(), toGranularity: .year) {
            formatter.dateFormat = "MMM d"
        } else {
            formatter.dateFormat = "MMM d, yyyy"
        }
        return formatter.string(from: date)
    }

    private var divider: some View {
        Divider()
            .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("With Items") {
    struct PreviewWrapper: View {
        @State private var items = [
            TodoItem(title: "Morning meditation"),
            TodoItem(title: "Water the plants", deadline: Calendar.current.date(byAdding: .day, value: 1, to: Date())),
            TodoItem(title: "Review tasks", deadline: Date().addingTimeInterval(-3600)),
        ]

        var body: some View {
            ScrollView {
                ChecklistGroupedCard(
                    label: "Checklist",
                    accentColor: .purple,
                    items: $items
                )
                .padding(.horizontal, 24)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}

#Preview("Empty") {
    struct PreviewWrapper: View {
        @State private var items: [TodoItem] = []

        var body: some View {
            ScrollView {
                ChecklistGroupedCard(
                    label: "Checklist",
                    accentColor: .purple,
                    items: $items
                )
                .padding(.horizontal, 24)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}
