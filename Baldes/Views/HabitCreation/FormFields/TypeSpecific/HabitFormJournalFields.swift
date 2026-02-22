import SwiftUI

/// A grouped iOS-style card that combines a journaling prompt text area
/// and a feelings log toggle into a single unified card.
struct JournalGroupedCard: View {
    let label: String
    let accentColor: Color
    @Binding var prompt: String
    @Binding var wordGoalEnabled: Bool
    @Binding var wordGoalTarget: Int
    @Binding var feelingsLogEnabled: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(spacing: 0) {
                // MARK: - Prompt Input
                promptRow

                divider

                // MARK: - Word Goal Toggle
                wordGoalToggleRow

                if wordGoalEnabled {
                    divider
                    wordGoalTargetRow
                }

                divider

                // MARK: - Feelings Log Toggle
                feelingsToggleRow
            }
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
        .animation(.spring(duration: 0.3), value: wordGoalEnabled)
    }

    // MARK: - Prompt Row

    private var promptRow: some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "brain.head.profile")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(accentColor)
                .padding(.top, 2)

            TextField("e.g. What triggered this feeling?", text: $prompt, axis: .vertical)
                .font(.system(size: 15))
                .foregroundStyle(Color.textPrimary)
                .lineLimit(3...5)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Word Goal Toggle

    private var wordGoalToggleRow: some View {
        HStack {
            Image(systemName: "text.word.spacing")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(accentColor)

            Text("Word Goal")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Toggle("Word Goal", isOn: $wordGoalEnabled)
                .labelsHidden()
                .tint(accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Word Goal Target

    private var wordGoalTargetRow: some View {
        HStack {
            Text("Target Words")
                .font(.system(size: 14, weight: .medium))
                .foregroundStyle(Color.textSecondary)

            Spacer()

            TextField("0", value: $wordGoalTarget, format: .number)
                .font(.system(size: 17, weight: .semibold))
                .foregroundStyle(Color.textPrimary)
                .multilineTextAlignment(.trailing)
                .keyboardType(.numberPad)
                .frame(maxWidth: 120)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .transition(.opacity.combined(with: .move(edge: .top)))
    }

    // MARK: - Feelings Log Toggle

    private var feelingsToggleRow: some View {
        HStack {
            Image(systemName: "face.smiling")
                .font(.system(size: 22, weight: .regular))
                .foregroundStyle(accentColor)

            Text("Feelings Log")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Spacer()

            Toggle("Feelings Log", isOn: $feelingsLogEnabled)
                .labelsHidden()
                .tint(accentColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
    }

    // MARK: - Divider

    private var divider: some View {
        Divider()
            .padding(.horizontal, 16)
    }
}

// MARK: - Previews

#Preview("Default") {
    struct PreviewWrapper: View {
        @State private var prompt = ""
        @State private var wordGoalEnabled = false
        @State private var wordGoalTarget = 100
        @State private var feelingsLogEnabled = true

        var body: some View {
            ScrollView {
                JournalGroupedCard(
                    label: "Journal",
                    accentColor: .purple,
                    prompt: $prompt,
                    wordGoalEnabled: $wordGoalEnabled,
                    wordGoalTarget: $wordGoalTarget,
                    feelingsLogEnabled: $feelingsLogEnabled
                )
                .padding(.horizontal, 24)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}

#Preview("With Word Goal") {
    struct PreviewWrapper: View {
        @State private var prompt = "What triggered this feeling?"
        @State private var wordGoalEnabled = true
        @State private var wordGoalTarget = 150
        @State private var feelingsLogEnabled = true

        var body: some View {
            ScrollView {
                JournalGroupedCard(
                    label: "Journal",
                    accentColor: .purple,
                    prompt: $prompt,
                    wordGoalEnabled: $wordGoalEnabled,
                    wordGoalTarget: $wordGoalTarget,
                    feelingsLogEnabled: $feelingsLogEnabled
                )
                .padding(.horizontal, 24)
            }
            .background(Color(hex: "F8F8F8"))
        }
    }

    return PreviewWrapper()
}
