import SwiftData
import SwiftUI

struct ActivityCardView: View {
    let activity: Activity
    var onEdit: (() -> Void)? = nil

    private var activityColor: Color {
        Color(hex: activity.colorHex)
    }

    // MARK: - Goal Display Helpers

    private var formattedStat: String {
        if let seconds = activity.goalTimeSeconds {
            let hours = Int(seconds) / 3600
            let minutes = (Int(seconds) % 3600) / 60
            if hours > 0 {
                return "\(hours)h \(minutes)m"
            } else {
                return "\(minutes)m"
            }
        } else if let target = activity.metricTarget, let unit = activity.metricUnit {
            let formattedTarget =
                target.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", target)
                : String(format: "%.1f", target)
            return "\(formattedTarget) \(unit)"
        } else if let count = activity.targetCount {
            return "\(count)"
        }
        return "0"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            // Header Row
            headerRow

            // Details Section
            detailsSection
        }
        .padding(16)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 1.5)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(activityColor)
                .offset(x: 0, y: 4)
        )
    }

    // MARK: - Header Row

    private var headerRow: some View {
        HStack(spacing: 12) {
            // Activity Icon
            activityIcon

            // Activity Name
            Text(activity.name)
                .font(.headline)
                .fontWeight(.semibold)
                .foregroundStyle(.primary)
                .lineLimit(1)

            Spacer()

            // Stats
            VStack(alignment: .trailing, spacing: 2) {
                Text(formattedStat)
                    .font(.subheadline)
                    .fontWeight(.semibold)
                    .foregroundStyle(activityColor)

                Text("This Week")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Motivation
            if !activity.motivation.isEmpty {
                HStack(alignment: .top, spacing: 8) {
                    Image(systemName: "quote.opening")
                        .font(.caption)
                        .foregroundStyle(activityColor)

                    Text(
                        "\(Text(activity.motivation).font(.caption).foregroundStyle(.secondary).italic())  \(Text(Image(systemName: "quote.closing")).font(.caption).foregroundStyle(activityColor))"
                    )
                    .lineLimit(10)
                }

                if let author = activity.motivationAuthor {
                    HStack {
                        Spacer()
                        Text("- \(author)")
                            .font(.caption2)
                            .fontWeight(.medium)
                            .foregroundStyle(activityColor)
                    }
                }
            }

            // Recurring Plan
            if let planSummary = activity.recurringPlanSummary, !planSummary.isEmpty {
                HStack(spacing: 8) {
                    Image(systemName: "calendar.badge.clock")
                        .font(.caption)
                        .foregroundStyle(activityColor)

                    Text(planSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    Spacer()

                    // Progress dots (completed vs total)
                    recurringPlanProgress
                }
            }
        }
    }

    // MARK: - Activity Icon

    private var activityIcon: some View {
        ZStack {
            Circle()
                .fill(activityColor.opacity(0.2))
                .frame(width: 44, height: 44)

            Text(activity.symbol)
                .font(.title3)
        }
    }

    // MARK: - Recurring Plan Progress

    private var recurringPlanProgress: some View {
        // Count total days from the plan summary (comma-separated days)
        let totalDays = activity.recurringPlanSummary?.components(separatedBy: ", ").count ?? 0
        // For now, completed is 0 since we don't have session tracking yet
        let completedDays = 0

        return HStack(spacing: 4) {
            // Filled circles for completed days
            ForEach(0..<completedDays, id: \.self) { _ in
                Circle()
                    .fill(activityColor)
                    .frame(width: 8, height: 8)
            }
            // Empty circles for remaining days
            ForEach(0..<(totalDays - completedDays), id: \.self) { _ in
                Circle()
                    .stroke(activityColor, lineWidth: 1.5)
                    .frame(width: 8, height: 8)
            }
        }
    }
}

#Preview {
    VStack(spacing: 24) {
        ActivityCardView(
            activity: Activity(
                name: "Running",
                symbol: "🏃",
                colorHex: "4A5D23",
                motivation: "Stay healthy and energized every day!",
                recurringPlanSummary: "Seg, Qua, Sex",
                metricTarget: 0,
                metricUnit: "mi"
            )
        )

        ActivityCardView(
            activity: Activity(
                name: "Reading",
                symbol: "📚",
                colorHex: "8B7355",
                motivation: "Knowledge is power",
                goalTimeSeconds: 33180
            )
        )
    }
    .padding()
}
