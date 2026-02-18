import SwiftUI

// MARK: - Gradient Background

struct HabitFormBackground: View {
    let gradientColor: Color

    var body: some View {
        LinearGradient(
            colors: [gradientColor, .white.opacity(0)],
            startPoint: .top,
            endPoint: UnitPoint(x: 0.5, y: 0.45)
        )
        .ignoresSafeArea()
    }
}

// MARK: - Mascot Section

struct HabitFormMascotSection: View {
    let imageName: String
    let title: String
    let subtitle: String

    var body: some View {
        VStack(spacing: 8) {
            Image(imageName)
                .resizable()
                .scaledToFit()
                .frame(width: 120, height: 120)

            Text(title)
                .font(.system(size: 24, weight: .heavy))
                .foregroundStyle(Color.textPrimary)

            Text(subtitle)
                .font(.system(size: 14))
                .foregroundStyle(Color.textSecondary)
                .multilineTextAlignment(.center)
                .frame(maxWidth: 280)
        }
    }
}

// MARK: - Text Input Field

struct HabitFormTextField: View {
    let label: String
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            TextField(placeholder, text: $text)
                .font(.system(size: 15))
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
        }
    }
}

// MARK: - Quote / Motivation Field

struct HabitFormQuoteField: View {
    let accentColor: Color
    let placeholder: String
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Daily Motivation")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            VStack(alignment: .leading, spacing: 0) {
                Image(systemName: "quote.opening")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(accentColor)

                TextField(placeholder, text: $text, axis: .vertical)
                    .font(.system(size: 13))
                    .lineLimit(3...5)
            }
            .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
            .frame(minHeight: 92, alignment: .topLeading)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
    }
}

// MARK: - Category Field

struct HabitFormCategoryField: View {
    @Binding var type: HabitType

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Category")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Menu {
                Picker("Category", selection: $type) {
                    ForEach(HabitType.allCases) { habitType in
                        Label(habitType.title, systemImage: habitType.iconName)
                            .tag(habitType)
                    }
                }
            } label: {
                HStack {
                    Text(type.title)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(Color.textPrimary)
                    Spacer()
                    Image(systemName: "chevron.up.chevron.down")
                        .font(.system(size: 13, weight: .medium))
                        .foregroundStyle(Color.textTertiary)
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
            }

            HStack(spacing: 6) {
                Image(systemName: type.iconName)
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(type.color)
                Text(type.title)
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(type.color)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(type.tagBackgroundColor)
            .cornerRadius(12)
            .animation(.easeInOut(duration: 0.2), value: type)
        }
    }
}

// MARK: - Picker / Dropdown Field

struct HabitFormPickerField: View {
    let label: String
    let value: String
    var trailingIcon: String = "chevron.down"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack {
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: trailingIcon)
                    .font(.system(size: 14, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
    }
}

// MARK: - Field Pair (side-by-side)

struct HabitFormFieldPair<Left: View, Right: View>: View {
    let left: Left
    let right: Right

    init(@ViewBuilder left: () -> Left, @ViewBuilder right: () -> Right) {
        self.left = left()
        self.right = right()
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            left
            right
        }
    }
}

// MARK: - Schedule Type Picker

struct HabitFormScheduleTypePicker: View {
    @Binding var selectedIndex: Int

    private let options = ["Scheduled", "Anytime"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schedule Type")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            Picker("Schedule Type", selection: $selectedIndex) {
                ForEach(options.indices, id: \.self) { index in
                    Text(options[index]).tag(index)
                }
            }
            .pickerStyle(.segmented)
        }
    }
}

// MARK: - Active Days Row

struct HabitFormActiveDays: View {
    let accentColor: Color
    @Binding var selectedDays: Set<Int>
    private let dayLabels = ["M", "T", "W", "T", "F", "S", "S"]

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Active Days")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack {
                ForEach(0..<7, id: \.self) { index in
                    let isSelected = selectedDays.contains(index)

                    Button {
                        if isSelected {
                            selectedDays.remove(index)
                        } else {
                            selectedDays.insert(index)
                        }
                    } label: {
                        Text(dayLabels[index])
                            .font(.system(size: 14, weight: .bold))
                            .foregroundStyle(isSelected ? .white : Color.textTertiary)
                            .frame(width: 42, height: 42)
                            .background(
                                Circle()
                                    .fill(isSelected ? accentColor : Color(hex: "F5F5F5"))
                            )
                    }
                    .buttonStyle(.plain)

                    if index < 6 { Spacer() }
                }
            }
        }
    }
}

// MARK: - Reminder Toggle Row

struct HabitFormReminderToggle: View {
    let accentColor: Color
    let label: String
    @Binding var isOn: Bool

    init(accentColor: Color, label: String = "Reminder", isOn: Binding<Bool>) {
        self.accentColor = accentColor
        self.label = label
        self._isOn = isOn
    }

    var body: some View {
        HStack {
            HStack(spacing: 12) {
                Image(systemName: "bell.badge.fill")
                    .font(.system(size: 18))
                    .foregroundStyle(accentColor)
                Text(label)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }
            Spacer()
            Toggle("", isOn: $isOn)
                .labelsHidden()
                .tint(Color(hex: "34C759"))
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 14)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(16)
    }
}

// MARK: - Schedule Time Field

struct HabitFormScheduleField: View {
    let value: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Schedule")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack {
                Text(value)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(Color.textPrimary)
                Spacer()
                Image(systemName: "clock")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(Color.textTertiary)
            }
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(16)
        }
    }
}

// MARK: - Direction Selector (Increase / Decrease)

struct HabitFormDirectionPicker: View {
    let accentColor: Color
    @Binding var isIncrease: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tracking Direction")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 10) {
                Button {
                    isIncrease = true
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.up.right")
                            .font(.system(size: 14, weight: .medium))
                        Text("Increase")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(isIncrease ? .white : Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(isIncrease ? accentColor : Color(hex: "F5F5F5"))
                    )
                }
                .buttonStyle(.plain)

                Button {
                    isIncrease = false
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: "arrow.down.right")
                            .font(.system(size: 14, weight: .medium))
                        Text("Decrease")
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(!isIncrease ? .white : Color.textSecondary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 44)
                    .background(
                        RoundedRectangle(cornerRadius: 14)
                            .fill(!isIncrease ? accentColor : Color(hex: "F5F5F5"))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Option Chips Row

struct HabitFormChipRow: View {
    let options: [(label: String, icon: String)]
    let accentColor: Color
    @Binding var selectedIndex: Int

    var body: some View {
        HStack(spacing: 8) {
            ForEach(options.indices, id: \.self) { index in
                let isSelected = selectedIndex == index

                Button {
                    selectedIndex = index
                } label: {
                    HStack(spacing: 6) {
                        Image(systemName: options[index].icon)
                            .font(.system(size: 13, weight: .medium))
                        Text(options[index].label)
                            .font(.system(size: 13, weight: .semibold))
                    }
                    .foregroundStyle(isSelected ? .white : Color.textSecondary)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(isSelected ? accentColor : Color(hex: "F5F5F5"))
                    )
                }
                .buttonStyle(.plain)
            }
        }
    }
}

// MARK: - Checklist Item Row

struct HabitFormChecklistItem: View {
    let placeholder: String
    let accentColor: Color

    var body: some View {
        HStack(spacing: 10) {
            RoundedRectangle(cornerRadius: 6)
                .strokeBorder(accentColor, lineWidth: 2)
                .frame(width: 22, height: 22)

            Text(placeholder)
                .font(.system(size: 14))
                .foregroundStyle(Color.textTertiary)

            Spacer()
        }
        .padding(.horizontal, 14)
        .frame(height: 44)
        .background(Color(hex: "F5F5F5"))
        .cornerRadius(14)
    }
}

// MARK: - Add Item Button (neo-brutalist)

struct HabitFormAddButton: View {
    let label: String
    let accentColor: Color
    let shadowColor: Color

    var body: some View {
        HStack(spacing: 10) {
            Image(systemName: "plus")
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(accentColor)
            Text(label)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(accentColor)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(Color.white)
        .cornerRadius(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(shadowColor)
                .offset(x: 4, y: 4)
        )
    }
}

// MARK: - Currency Selector

struct HabitFormCurrencyPicker: View {
    let accentColor: Color
    @Binding var selectedIndex: Int
    private let currencies = ["$ USD", "€ EUR", "£ GBP", "R$ BRL"]

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Currency")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 8) {
                ForEach(currencies.indices, id: \.self) { index in
                    let isSelected = selectedIndex == index

                    Button {
                        selectedIndex = index
                    } label: {
                        Text(currencies[index])
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundStyle(isSelected ? .white : Color.textSecondary)
                            .frame(maxWidth: .infinity)
                            .frame(height: 44)
                            .background(
                                RoundedRectangle(cornerRadius: 14)
                                    .fill(isSelected ? accentColor : Color(hex: "F5F5F5"))
                            )
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Tag Chip

struct HabitFormTagChip: View {
    let label: String
    let color: Color
    let isFilled: Bool

    var body: some View {
        HStack(spacing: 6) {
            if !isFilled {
                Image(systemName: "plus")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(color)
            }
            Text(label)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(isFilled ? .white : color)
            if isFilled {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.white.opacity(0.8))
            }
        }
        .padding(.horizontal, 14)
        .padding(.vertical, 6)
        .background(
            Capsule()
                .fill(isFilled ? color : .clear)
                .overlay(
                    Capsule()
                        .strokeBorder(isFilled ? .clear : color, lineWidth: 1.5)
                )
        )
    }
}


