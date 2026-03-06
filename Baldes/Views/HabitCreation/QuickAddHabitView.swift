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

    var body: some View {
        @Bindable var vm = viewModel

        NavigationStack {
            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 20) {
                    // Name
                    ZStack(alignment: .topLeading) {
                        if vm.habitName.isEmpty {
                            Text("What's your next good habit?")
                                .font(.body)
                                .foregroundStyle(Color.textTertiary)
                                .padding(.top, 8)
                                .padding(.leading, 5)
                                .allowsHitTesting(false)
                        }

                        TextEditor(text: $vm.habitName)
                            .focused($isFocused)
                            .font(.body)
                            .foregroundStyle(Color.textPrimary)
                            .scrollContentBackground(.hidden)
                            .frame(minHeight: 40)
                    }
                    .padding(.top, 8)

                    // Motivation
                    HabitFormQuoteField(
                        accentColor: accentColor,
                        text: $vm.motivationQuote
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
                                            vm.habitType = type
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
            .background(Color.bgPage)
            .navigationTitle("New Habit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
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

                ToolbarItem(placement: .confirmationAction) {
                    Button {
                        isFocused = false
                        withAnimation {
                            selectedDetent = .large
                        }
                        showConfig = true
                    } label: {
                        Text("Next")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(canProceedToStep2 ? accentColor : Color.textTertiary)
                    }
                    .disabled(!canProceedToStep2)
                }
            }
            .navigationDestination(isPresented: $showConfig) {
                HabitConfigurationView(
                    viewModel: viewModel,
                    dismissSheet: dismissSheet ?? { dismiss() }
                )
            }
            .onAppear {
                isFocused = true
            }
        }
        .presentationDetents([.medium, .large], selection: $selectedDetent)
        .presentationDragIndicator(.hidden)
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
