import SwiftUI

struct WeekdayPicker: View {
    @Binding var selectedDays: Set<Weekday>
    let accentColor: Color

    // Sorted weekdays starting from Sunday (rawValue 1)
    private let weekdays: [Weekday] = Weekday.allCases.sorted { $0.rawValue < $1.rawValue }

    var body: some View {
        HStack(spacing: 6) {
            ForEach(weekdays) { day in
                WeekdayToggle(
                    day: day,
                    isSelected: selectedDays.contains(day),
                    color: accentColor,
                    action: { toggle(day) }
                )
            }
        }
    }

    private func toggle(_ day: Weekday) {
        withAnimation(.easeInOut(duration: 0.15)) {
            if selectedDays.contains(day) {
                selectedDays.remove(day)
            } else {
                selectedDays.insert(day)
            }
        }
    }
}

private struct WeekdayToggle: View {
    let day: Weekday
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    private let size: CGFloat = 26

    var body: some View {
        Button(action: action) {
            Text(day.shortName.prefix(1))
                .font(.system(size: 12, weight: isSelected ? .semibold : .regular))
                .foregroundStyle(isSelected ? Color.white : Color.secondary)
                .frame(width: size, height: size)
                .background(
                    Circle()
                        .fill(isSelected ? Color.clear : .secondary.opacity(0.1))
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? color : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
        // 3D offset shadow - applied OUTSIDE the button for proper layering
        .background(
            Circle()
                .fill(isSelected ? color.opacity(0.5) : .clear)
                .frame(width: size, height: size)
                .offset(x: 2, y: 2)
        )
        .sensoryFeedback(.selection, trigger: isSelected)
    }
}

#Preview {
    @Previewable @State var days: Set<Weekday> = [.monday, .friday]
    VStack {
        WeekdayPicker(selectedDays: $days, accentColor: .purple)
    }
    .padding()
    .background(Color(.systemBackground))
}
