import SwiftUI

// MARK: - Add Habit View

struct AddHabitView: View {
    @Environment(\.dismiss) private var dismiss
    var dismissSheet: (() -> Void)?

    var body: some View {
        ZStack {
            LinearGradient(
                colors: [Color.accentOrangeLight, .white.opacity(0)],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.45)
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 18) {
                    mascotSection

                    VStack(spacing: 12) {
                        ForEach(HabitType.allCases) { type in
                            NavigationLink(value: type) {
                                HabitTypeCard(type: type)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 24)
            }
        }
        .navigationTitle("New Habit")
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: HabitType.self) { type in
            AddHabitFormView(habitType: type, dismissSheet: dismissSheet)
        }
        .toolbar {
            ToolbarItem(placement: .confirmationAction) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                }
            }
        }
    }

    private var mascotSection: some View {
        VStack(spacing: 4) {
            Image("new")
                .resizable()
                .scaledToFit()
                .frame(width: 96, height: 96)

            Text("What would you like to track?")
                .font(.system(size: 24, weight: .heavy, design: .default))
                .foregroundStyle(Color.textPrimary)

            Text("Pick a habit type to get started.\nEach one is tailored to help you succeed!")
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 300)
        }
    }
}

// MARK: - Preview

#Preview {
    NavigationStack {
        AddHabitView()
    }
}
