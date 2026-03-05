import SwiftUI

// MARK: - Quick Add Toolbar

struct QuickAddToolbar: View {
    let habitType: HabitType
    @Binding var expandedSection: QuickAddSection?

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 10) {
                toolbarButton(
                    icon: "calendar",
                    label: "Schedule",
                    section: .schedule,
                    color: .accentOrange
                )

                toolbarButton(
                    icon: habitType.iconName,
                    label: habitType.title,
                    section: .type,
                    color: habitType.color
                )

                toolbarButton(
                    icon: "tag",
                    label: "Category",
                    section: .category,
                    color: .accentPurple
                )

                toolbarButton(
                    icon: "ellipsis",
                    label: "More",
                    section: .more,
                    color: .textSecondary
                )
            }
            .padding(.horizontal, 4)
        }
    }

    private func toolbarButton(
        icon: String, label: String, section: QuickAddSection, color: Color
    ) -> some View {
        let isActive = expandedSection == section

        return Button {
            withAnimation(.spring(duration: 0.3)) {
                if expandedSection == section {
                    expandedSection = nil
                } else {
                    expandedSection = section
                }
            }
        } label: {
            HStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.system(size: 14, weight: .semibold))

                Text(label)
                    .font(.system(size: 13, weight: .medium))
                    .lineLimit(1)
            }
            .foregroundStyle(isActive ? .white : color)
            .padding(.horizontal, 14)
            .padding(.vertical, 9)
            .background(
                isActive
                    ? AnyShapeStyle(color)
                    : AnyShapeStyle(color.opacity(0.1))
            )
            .cornerRadius(12)
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Section Enum

enum QuickAddSection: Hashable {
    case schedule
    case type
    case category
    case more
    case typeSpecific
}
