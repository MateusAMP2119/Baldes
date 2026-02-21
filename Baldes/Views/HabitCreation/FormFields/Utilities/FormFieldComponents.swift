import SwiftUI

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
