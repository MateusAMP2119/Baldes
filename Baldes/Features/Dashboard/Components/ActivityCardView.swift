import SwiftData
import SwiftUI

struct ActivityCardView: View {
    let activity: Activity
    var onEdit: (() -> Void)? = nil

    private var activityColor: Color {
        Color(hex: activity.colorHex)
    }

    // MARK: - Goal Display Helpers

    private var goalTypeLabel: String {
        if activity.goalTimeSeconds != nil {
            return "Tempo diário"
        } else if activity.metricTarget != nil {
            return "Meta numérica"
        } else {
            return "Atividade"
        }
    }

    private var goalTypeIcon: String {
        if activity.goalTimeSeconds != nil {
            return "clock.fill"
        } else if activity.metricTarget != nil {
            return "number.circle.fill"
        } else {
            return "checkmark.circle.fill"
        }
    }

    private var formattedGoal: String {
        if let seconds = activity.goalTimeSeconds {
            let hours = Int(seconds) / 3600
            let minutes = (Int(seconds) % 3600) / 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes) min"
            }
        } else if let target = activity.metricTarget, let unit = activity.metricUnit {
            let formattedTarget =
                target.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", target)
                : String(format: "%.1f", target)
            return "\(formattedTarget) \(unit)"
        }
        return ""
    }

    var body: some View {
        HStack(spacing: 12) {
            // Activity Icon
            activityIcon

            // Main Content
            VStack(alignment: .leading, spacing: 6) {
                // Activity Name
                Text(activity.name)
                    .font(.headline)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)
                    .lineLimit(1)

                // Goal Info Row
                HStack(spacing: 6) {
                    Image(systemName: goalTypeIcon)
                        .font(.caption)
                        .foregroundStyle(activityColor)

                    Text(goalTypeLabel)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    if !formattedGoal.isEmpty {
                        Text("•")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(formattedGoal)
                            .font(.caption)
                            .fontWeight(.medium)
                            .foregroundStyle(activityColor)
                    }
                }
            }

            Spacer()

            // Edit Button
            if let onEdit = onEdit {
                Button(action: onEdit) {
                    Image(systemName: "slider.horizontal.3")
                        .font(.system(size: 18))
                        .foregroundStyle(.gray)
                }
                .buttonStyle(.plain)
            }
        }
        .padding()
        .background(Color.white)
        .cornerRadius(16)
        // Card Border and Shadow 3D effect
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 1.5)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(activityColor.opacity(0.3))
                .offset(x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 1.5)
                        .offset(x: 0, y: 5)
                )
                .zIndex(-1)
        )
        .padding(.bottom, 6)
    }

    // MARK: - Subviews

    private var activityIcon: some View {
        ZStack {
            Circle()
                .fill(activityColor.opacity(0.2))
                .frame(width: 50, height: 50)

            Text(activity.symbol)
                .font(.title2)
        }
        .overlay(
            Circle()
                .stroke(Color.black, lineWidth: 1.5)
        )
    }
}
