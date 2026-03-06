import SwiftData
import SwiftUI

struct QuickAddHabitView: View {
    @State private var viewModel: AddHabitViewModel
    @Environment(\.dismiss) private var dismiss
    @Environment(\.modelContext) private var modelContext
    @Query private var allHabits: [HabitEntry]

    @State private var selectedType: HabitType?
    @State private var showConfig = false
    @State private var selectedDetent: PresentationDetent = .medium
    @State private var emojiFieldFocused = false
    @FocusState private var isFocused: Bool

    var dismissSheet: (() -> Void)?

    init(
        initialType: HabitType? = nil,
        dismissSheet: (() -> Void)? = nil
    ) {
        let typeToUse = initialType ?? .dailyGoals
        _viewModel = State(
            initialValue: AddHabitViewModel(
                habitType: typeToUse,
                dismissSheet: dismissSheet
            ))
        _selectedType = State(initialValue: initialType)
        self.dismissSheet = dismissSheet
    }

    private var accentColor: Color {
        selectedType?.color ?? .accentOrange
    }

    private var nameIsEmpty: Bool {
        viewModel.habitName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private var canProceedToStep2: Bool {
        !nameIsEmpty && selectedType != nil
    }

    private var navigationTitle: String {
        showConfig ? configurationTitle : "New Habit"
    }

    private var configurationTitle: String {
        switch viewModel.habitType {
        case .timed: "Set up Timer"
        case .metrics: "Set up Metric"
        case .todo: "Set up Checklist"
        case .routes: "Set up Route"
        case .budgets: "Set up Budget"
        case .notes: "Set up Notes"
        case .journal: "Set up Journal"
        case .dailyGoals: "Finish Habit"
        }
    }

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            Group {
                if showConfig {
                    HabitConfigurationContent(viewModel: viewModel)
                        .transition(.push(from: .trailing))
                } else {
                    step1Body(vm: $vm)
                        .transition(.push(from: .leading))
                }
            }
            .background(Color.bgPage)
            .navigationTitle(navigationTitle)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    if showConfig {
                        Button {
                            withAnimation(.easeInOut(duration: 0.3)) {
                                showConfig = false
                                selectedDetent = .medium
                            }
                        } label: {
                            Image(systemName: "chevron.left")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(accentColor)
                        }
                    } else {
                        Button {
                            if let dismissSheet {
                                dismissSheet()
                            } else {
                                dismiss()
                            }
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 16, weight: .semibold))
                                .foregroundStyle(Color.textSecondary)
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    if showConfig {
                        Button {
                            viewModel.save(
                                modelContext: modelContext,
                                allHabitsCount: allHabits.count,
                                dismiss: dismiss
                            )
                            if let dismissSheet {
                                dismissSheet()
                            }
                        } label: {
                            Image(systemName: "checkmark")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(accentColor)
                        }
                    } else {
                        Button {
                            isFocused = false
                            withAnimation(.easeInOut(duration: 0.3)) {
                                selectedDetent = .large
                                showConfig = true
                            }
                        } label: {
                            Image(systemName: "chevron.right")
                                .font(.system(size: 16, weight: .bold))
                                .foregroundStyle(
                                    canProceedToStep2 ? accentColor : Color.textTertiary)
                        }
                        .disabled(!canProceedToStep2)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.hidden)
    }

    // MARK: - Step 1: Habit Info

    @ViewBuilder
    private func step1Body(vm: Bindable<AddHabitViewModel>) -> some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 20) {
                // Name + Emoji
                HStack(alignment: .top, spacing: 12) {
                    ZStack {
                        EmojiTextField(emoji: vm.habitEmoji, shouldFocus: emojiFieldFocused) {
                            emojiFieldFocused = false
                        }
                        .frame(width: 44, height: 44)

                        Button {
                            isFocused = false
                            emojiFieldFocused = true
                        } label: {
                            Text(viewModel.habitEmoji)
                                .font(.system(size: 24))
                                .frame(width: 44, height: 44)
                                .background(
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color(hex: "F5F5F5"))
                                )
                        }
                        .buttonStyle(.plain)
                    }

                    TextField("What's your next good habit?", text: vm.habitName)
                        .focused($isFocused)
                        .font(.body)
                        .foregroundStyle(Color.textPrimary)
                        .onSubmit { isFocused = false }
                        .frame(minHeight: 40)
                }
                .padding(.top, 8)

                // Motivation
                HabitFormQuoteField(
                    accentColor: accentColor,
                    text: vm.motivationQuote
                )

                // Habit Type
                VStack(alignment: .leading, spacing: 10) {
                    Text("Type")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)

                    LazyVGrid(
                        columns: Array(
                            repeating: GridItem(.flexible(), spacing: 10), count: 4),
                        spacing: 10
                    ) {
                        ForEach(HabitType.allCases) { type in
                            let isSelected = selectedType == type

                            Button {
                                withAnimation(.spring(duration: 0.25)) {
                                    if selectedType == type {
                                        selectedType = nil
                                    } else {
                                        selectedType = type
                                        viewModel.habitType = type
                                    }
                                }
                            } label: {
                                VStack(spacing: 5) {
                                    Image(systemName: type.iconName)
                                        .font(.system(size: 18, weight: .semibold))
                                        .foregroundStyle(
                                            isSelected ? .white : type.color
                                        )
                                        .frame(width: 40, height: 40)
                                        .background(
                                            RoundedRectangle(cornerRadius: 12)
                                                .fill(
                                                    isSelected
                                                        ? type.color
                                                        : type.tagBackgroundColor
                                                )
                                        )

                                    Text(type.title)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(
                                            isSelected
                                                ? type.color : Color.textSecondary
                                        )
                                        .lineLimit(1)
                                }
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .scrollDismissesKeyboard(.interactively)
    }
}

// MARK: - Preview

#Preview {
    Color.clear
        .sheet(isPresented: .constant(true)) {
            QuickAddHabitView()
        }
        .modelContainer(for: HabitEntry.self, inMemory: true)
}
