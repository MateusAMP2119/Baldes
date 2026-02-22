import SwiftUI

// MARK: - Wrapping HStack Layout

/// A layout that arranges views horizontally and wraps to the next line when needed.
struct WrappingHStack: Layout {
    var horizontalSpacing: CGFloat = 8
    var verticalSpacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var height: CGFloat = 0
        for (index, row) in rows.enumerated() {
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            height += rowHeight
            if index < rows.count - 1 {
                height += verticalSpacing
            }
        }
        return CGSize(width: proposal.width ?? 0, height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let rows = computeRows(proposal: proposal, subviews: subviews)
        var y = bounds.minY
        for row in rows {
            let rowHeight = row.map { subviews[$0].sizeThatFits(.unspecified).height }.max() ?? 0
            var x = bounds.minX
            for index in row {
                let size = subviews[index].sizeThatFits(.unspecified)
                subviews[index].place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
                x += size.width + horizontalSpacing
            }
            y += rowHeight + verticalSpacing
        }
    }

    private func computeRows(proposal: ProposedViewSize, subviews: Subviews) -> [[Int]] {
        let maxWidth = proposal.width ?? .infinity
        var rows: [[Int]] = [[]]
        var currentRowWidth: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let size = subview.sizeThatFits(.unspecified)
            if currentRowWidth + size.width > maxWidth && !rows[rows.count - 1].isEmpty {
                rows.append([])
                currentRowWidth = 0
            }
            rows[rows.count - 1].append(index)
            currentRowWidth += size.width + horizontalSpacing
        }
        return rows
    }
}

// MARK: - Notes Grouped Card

/// A grouped iOS-style card that combines note format selection and editable tags
/// into a single unified card, matching the GroupedCard pattern.
struct NotesGroupedCard: View {
    let label: String
    let accentColor: Color
    @Binding var formatIndex: Int    // 0=Plain Text, 1=Markdown, 2=Voice Memo
    @Binding var tags: [String]

    @State private var newTagText = ""
    @FocusState private var isNewTagFocused: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // MARK: - Format Picker
                formatRow

                // MARK: - Tags Display
                if tags.isEmpty {
                    emptyStateRow
                } else {
                    tagsDisplayRow
                }

                divider

                // MARK: - Add Tag Row
                addTagRow
            }
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
        .animation(.spring(duration: 0.3), value: tags)
        .animation(.spring(duration: 0.3), value: formatIndex)
    }

    // MARK: - Format Row

    private var formatRow: some View {
        Picker("Format", selection: $formatIndex) {
            Text("Plain Text").tag(0)
            Text("Markdown").tag(1)
            Text("Voice Memo").tag(2)
        }
        .pickerStyle(.segmented)
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Tags Display

    private var tagsDisplayRow: some View {
        WrappingHStack(horizontalSpacing: 8, verticalSpacing: 8) {
            ForEach(tags, id: \.self) { tag in
                HabitFormTagChip(label: tag, color: accentColor, isFilled: true)
                    .onTapGesture {
                        if let index = tags.firstIndex(of: tag) {
                            tags.remove(at: index)
                        }
                    }
                    .transition(.scale.combined(with: .opacity))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }

    // MARK: - Empty State

    private var emptyStateRow: some View {
        VStack(spacing: 4) {
            Image(systemName: "tag")
                .font(.system(size: 24))
                .foregroundStyle(Color.textTertiary)

            Text("Add tags to organize\nyour notes")
                .font(.system(size: 13))
                .foregroundStyle(Color.textTertiary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .transition(.opacity)
    }

    // MARK: - Add Tag Row

    private var addTagRow: some View {
        HStack(spacing: 10) {
            Image(systemName: "tag")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(accentColor)

            TextField("Add a tag...", text: $newTagText)
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)
                .focused($isNewTagFocused)
                .onSubmit {
                    addTag()
                }

            if !newTagText.isEmpty {
                Button {
                    addTag()
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
        .animation(.spring(duration: 0.2), value: newTagText.isEmpty)
    }

    // MARK: - Helpers

    private func addTag() {
        let trimmed = newTagText.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        guard !tags.contains(trimmed) else {
            newTagText = ""
            return
        }
        tags.append(trimmed)
        newTagText = ""
        isNewTagFocused = true
    }

    private var divider: some View {
        Divider()
            .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#Preview("With Tags") {
    struct PreviewWrapper: View {
        @State private var formatIndex = 0
        @State private var tags = ["Ideas", "Work", "Personal"]

        var body: some View {
            ScrollView {
                NotesGroupedCard(
                    label: "Notes",
                    accentColor: .yellow,
                    formatIndex: $formatIndex,
                    tags: $tags
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
        @State private var formatIndex = 0
        @State private var tags: [String] = []

        var body: some View {
            ScrollView {
                NotesGroupedCard(
                    label: "Notes",
                    accentColor: .yellow,
                    formatIndex: $formatIndex,
                    tags: $tags
                )
                .padding(.horizontal, 24)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}

#Preview("Voice Memo") {
    struct PreviewWrapper: View {
        @State private var formatIndex = 2
        @State private var tags = ["Meetings", "Reminders"]

        var body: some View {
            ScrollView {
                NotesGroupedCard(
                    label: "Notes",
                    accentColor: .yellow,
                    formatIndex: $formatIndex,
                    tags: $tags
                )
                .padding(.horizontal, 24)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}
