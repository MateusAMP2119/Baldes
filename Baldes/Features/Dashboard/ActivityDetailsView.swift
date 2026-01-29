import SwiftData
import SwiftUI

struct ActivityDetailsView: View {
    let activity: Activity

    private var activityColor: Color {
        Color(hex: activity.colorHex)
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                // Header / Hero Section
                headerSection
                    .padding(.top)

                // Motivation Section
                if !activity.motivation.isEmpty {
                    motivationSection
                }

                // Configuration / Stats
                configurationSection

                Spacer()
            }
            .padding(.horizontal)
        }
        .navigationTitle(activity.name)
        .navigationBarTitleDisplayMode(.inline)
        .background(Color.gray.opacity(0.1))
    }

    // MARK: - Header
    private var headerSection: some View {
        HStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(activityColor.opacity(0.2))
                    .frame(width: 80, height: 80)
                Text(activity.symbol)
                    .font(.system(size: 40))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(.primary)

                if let summary = activity.recurringPlanSummary, !summary.isEmpty {
                    Label(summary, systemImage: "calendar")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Motivation
    private var motivationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Motivação")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(alignment: .leading, spacing: 8) {
                HStack(alignment: .top) {
                    Image(systemName: "quote.opening")
                        .font(.caption)
                        .foregroundStyle(activityColor)

                    Text(activity.motivation)
                        .font(.body)
                        .foregroundStyle(.primary)
                        .italic()

                    Image(systemName: "quote.closing")
                        .font(.caption)
                        .foregroundStyle(activityColor)
                }

                if let author = activity.motivationAuthor, !author.isEmpty {
                    Text("- \(author)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .foregroundStyle(.secondary)
                        .frame(maxWidth: .infinity, alignment: .trailing)
                }
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .strokeBorder(activityColor.opacity(0.3), lineWidth: 1)
            )
        }
    }

    // MARK: - Configuration
    private var configurationSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Definições")
                .font(.headline)
                .foregroundStyle(.primary)

            VStack(spacing: 16) {
                if let seconds = activity.goalTimeSeconds {
                    detailRow(title: "Meta de Tempo", value: formatTime(seconds), icon: "timer")
                }

                if let count = activity.targetCount {
                    detailRow(title: "Meta de Contagem", value: "\(count) vezes", icon: "number")
                }

                if let target = activity.metricTarget, let unit = activity.metricUnit {
                    detailRow(
                        title: "Meta Métrica", value: "\(formatMetric(target)) \(unit)",
                        icon: "ruler")
                }

                detailRow(
                    title: "Criado em",
                    value: activity.creationDate.formatted(date: .long, time: .omitted),
                    icon: "calendar.badge.plus")
            }
            .padding()
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    private func detailRow(title: String, value: String, icon: String) -> some View {
        HStack {
            Label(title, systemImage: icon)
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.medium)
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Helpers
    private func formatTime(_ seconds: TimeInterval) -> String {
        let hours = Int(seconds) / 3600
        let minutes = (Int(seconds) % 3600) / 60
        if hours > 0 {
            return "\(hours)h \(minutes)m"
        } else {
            return "\(minutes)m"
        }
    }

    private func formatMetric(_ value: Double) -> String {
        return value.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", value)
            : String(format: "%.1f", value)
    }
}

#Preview {
    NavigationStack {
        ActivityDetailsView(
            activity: Activity(
                name: "Correr",
                symbol: "🏃",
                colorHex: "4A5D23",
                motivation: "Manter a saúde e energia!",
                motivationAuthor: "Eu mesmo",
                recurringPlanSummary: "Seg, Qua, Sex",
                creationDate: Date(),
                targetCount: 1
            )
        )
    }
}
