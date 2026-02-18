import SwiftUI

struct HomeView: View {
    @State private var selectedDayIndex = 0

    private let weekDays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
    private let weekDates = [15, 16, 17, 18, 19, 20, 21]

    var body: some View {
        ZStack(alignment: .bottom) {
            // Background gradient
            LinearGradient(
                colors: [Color.accentOrangeLight, Color.white.opacity(0)],
                startPoint: .top,
                endPoint: UnitPoint(x: 0.5, y: 0.4)
            )
            .ignoresSafeArea()

            ScrollView(.vertical, showsIndicators: false) {
                VStack(spacing: 28) {
                    headerSection
                    greetingSection
                    activitySection
                    dayStripSection
                }
                .padding(.bottom, 100)
            }
        }
    }

    // MARK: - Header

    private var headerSection: some View {
        HStack {
            Image("logo")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12))
                .overlay(
                    RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(Color.borderStrong, lineWidth: 2)
                )

            Spacer()

            Button(action: {}) {
                Image(systemName: "person")
                    .font(.system(size: 20))
                    .foregroundStyle(Color.textTertiary)
                    .frame(width: 48, height: 48)
            }
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Greeting

    private var greetingSection: some View {
        VStack(alignment: .leading, spacing: 2) {
            Text("Saturday, February 15")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textSecondary)
            Text("Hey, Mateus!")
                .font(.system(size: 26, weight: .black))
                .tracking(-0.5)
                .foregroundStyle(Color.textPrimary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }

    // MARK: - Activity Section

    private var activitySection: some View {
        ActivityGridView()
            .padding(.horizontal, 24)
    }

    // MARK: - Day Strip Section

    private var dayStripSection: some View {
        VStack(spacing: 16) {
            // Month header with arrows
            HStack {
                Text("February 2026")
                    .font(.system(size: 18, weight: .black))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                HStack(spacing: 10) {
                    Button(action: {}) {
                        Image(systemName: "chevron.left")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                    }
                    Button(action: {}) {
                        Image(systemName: "chevron.right")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundStyle(Color.textPrimary)
                    }
                }
            }

            // Day picker
            HStack {
                ForEach(0..<7, id: \.self) { index in
                    dayCell(index: index)
                    if index < 6 { Spacer() }
                }
            }

            // Scheduled habits card
            scheduledHabitsCard

            // Anytime section
            anytimeSection
        }
        .padding(.horizontal, 24)
    }

    // MARK: - Day Cell

    private func dayCell(index: Int) -> some View {
        let isSelected = index == selectedDayIndex

        return VStack(spacing: 6) {
            Text(weekDays[index])
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isSelected ? Color.textPrimary : Color.textTertiary)

            if isSelected {
                // Selected day with shadow effect
                ZStack {
                    RoundedRectangle(cornerRadius: 21)
                        .fill(Color.accentOrange)
                        .frame(width: 42, height: 42)
                        .offset(x: 3, y: 3)

                    ZStack {
                        RoundedRectangle(cornerRadius: 21)
                            .fill(Color.white)
                            .frame(width: 42, height: 42)
                        RoundedRectangle(cornerRadius: 21)
                            .strokeBorder(Color.borderStrong, lineWidth: 2)
                            .frame(width: 42, height: 42)
                        Text("\(weekDates[index])")
                            .font(.system(size: 16, weight: .bold, design: .default))
                            .foregroundStyle(Color.textPrimary)
                            .rotationEffect(.degrees(-0.19))
                    }
                }
                .frame(width: 45, height: 45)
            } else {
                ZStack {
                    Circle()
                        .fill(Color.clear)
                        .frame(width: 42, height: 42)
                    Text("\(weekDates[index])")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(Color.textSecondary)
                }
            }
        }
        .onTapGesture {
            withAnimation(.easeInOut(duration: 0.2)) {
                selectedDayIndex = index
            }
        }
    }

    // MARK: - Scheduled Habits Card

    private var scheduledHabitsCard: some View {
        VStack(spacing: 0) {
            ForEach(Array(Habit.sampleScheduled.enumerated()), id: \.element.id) { index, habit in
                HabitRowView(
                    habit: habit,
                    isFirst: index == 0,
                    isLast: index == Habit.sampleScheduled.count - 1
                )

                if index < Habit.sampleScheduled.count - 1 {
                    Rectangle()
                        .fill(Color.dividerColor)
                        .frame(height: 1)
                }
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .strokeBorder(Color.borderStrong, lineWidth: 2)
        )
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color.shadowOrange)
                .offset(x: 4, y: 4)
        )
    }

    // MARK: - Anytime Section

    private var anytimeSection: some View {
        VStack(spacing: 12) {
            // Anytime header
            HStack {
                HStack(spacing: 8) {
                    Image(systemName: "infinity")
                        .font(.system(size: 16, weight: .regular))
                        .foregroundStyle(Color.accentOrange)
                    Text("Anytime")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundStyle(Color.textPrimary)
                }
                Spacer()
                Text("3 habits")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }

            // Anytime habits card
            VStack(spacing: 0) {
                ForEach(Array(AnytimeHabit.samples.enumerated()), id: \.element.id) { index, habit in
                    AnytimeHabitRowView(
                        habit: habit,
                        isFirst: index == 0,
                        isLast: index == AnytimeHabit.samples.count - 1
                    )

                    if index < AnytimeHabit.samples.count - 1 {
                        Rectangle()
                            .fill(Color.dividerColor)
                            .frame(height: 1)
                    }
                }
            }
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(Color.borderStrong, lineWidth: 2)
            )
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color.shadowOrange)
                    .offset(x: 4, y: 4)
            )
        }
    }
}

#Preview {
    HomeView()
}
