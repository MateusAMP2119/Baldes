import SwiftUI

// MARK: - Checklist Grouped Card

/// A grouped iOS-style card that displays checklist items in a unified
/// card with inline editing, matching the style of MetricsGroupedCard,
/// TimerGroupedCard, and ScheduleGroupedCard.
struct ChecklistGroupedCard: View {
    let label: String
    let accentColor: Color
    @Binding var items: [String]

    @State private var newItemText = ""
    @FocusState private var isNewItemFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // MARK: - Existing Items
                ForEach(items.indices, id: \.self) { index in
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
        }
        .animation(.spring(duration: 0.3), value: items)
    }

    // MARK: - Item Row

    private func itemRow(at index: Int) -> some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(accentColor, lineWidth: 2)
                .frame(width: 22, height: 22)

            TextField("Item name", text: $items[index])
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Button {
                items.remove(at: index)
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Empty State

    private var emptyStateRow: some View {
        VStack(spacing: 4) {
            Image(systemName: "checklist")
                .font(.system(size: 24))
                .foregroundStyle(Color.textTertiary)

            Text("Add the items you want to\ncheck off daily")
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
        items.append(trimmed)
        newItemText = ""
        isNewItemFocused = true
    }

    private var divider: some View {
        Divider()
            .padding(.horizontal, 16)
    }
}

// MARK: - Preview

#Preview("With Items") {
    struct PreviewWrapper: View {
        @State private var items = ["Morning meditation", "Water the plants", "Review tasks"]

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
        @State private var items: [String] = []

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
