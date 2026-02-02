import SwiftUI

struct WeekdayPicker: View {
    @Binding var selectedDays: Set<Weekday>
    let accentColor: Color

    // Sorted weekdays starting from Sunday (rawValue 1)
    private let weekdays: [Weekday] = Weekday.allCases.sorted { $0.rawValue < $1.rawValue }

    var body: some View {
        HStack(spacing: 8) {
            ForEach(weekdays) { day in
                WeekdayButton(
                    day: day,
                    isSelected: selectedDays.contains(day),
                    color: accentColor,
                    action: { toggle(day) }
                )
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
    }

    private func toggle(_ day: Weekday) {
        if selectedDays.contains(day) {
            selectedDays.remove(day)
        } else {
            selectedDays.insert(day)
        }
    }
}

private struct WeekdayButton: View {
    let day: Weekday
    let isSelected: Bool
    let color: Color
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(day.shortName.prefix(1)) // Use first letter (D, S, T...)
                .font(.system(size: 14, weight: .bold))
                .foregroundStyle(isSelected ? .white : .primary)
                .frame(width: 36, height: 36)
                .background(
                    Circle()
                        .fill(isSelected ? color : Color(.systemGray5))
                )
                .overlay(
                    Circle()
                        .stroke(isSelected ? color : .clear, lineWidth: 1)
                )
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    @Previewable @State var days: Set<Weekday> = [.monday, .friday]
    return VStack {
        WeekdayPicker(selectedDays: $days, accentColor: .purple)
    }
    .padding()
    .background(Color.gray.opacity(0.1))
}
