import SwiftData
import SwiftUI

struct ActivityCardView: View {
    let activity: Activity
    var onEdit: (() -> Void)? = nil

    var body: some View {
        HStack {
            // Circle Icon
            ZStack {
                Circle()
                    .fill(Color(hex: activity.colorHex).opacity(0.3))  // Lighter background
                    .frame(width: 50, height: 50)

                Image(systemName: activity.symbol)
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundStyle(Color(hex: activity.colorHex).opacity(0.8))  // Darker icon
            }
            .overlay(
                Circle()
                    .stroke(Color.black, lineWidth: 1.5)
            )
            .padding(.trailing, 8)

            // Text Content
            VStack(alignment: .leading, spacing: 4) {
                Text(activity.name)
                    .font(.body)
                    .fontWeight(.semibold)
                    .foregroundStyle(.black)

                // We can add logic to show progress here later
                // For now, static or based on properties
                if activity.goalTimeSeconds != nil {
                    Text("0 m")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else if let unit = activity.metricUnit, let target = activity.targetCount {
                    Text("0 / \(target) \(unit)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                } else {
                    Text("This Week")
                        .font(.caption)
                        .foregroundStyle(.secondary)
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
                .padding(.trailing, 8)
            }

            // Trailing info (e.g. "0 mi" in screenshot)
            VStack(alignment: .trailing) {
                if let target = activity.metricTarget, let unit = activity.metricUnit {
                    Text("0 \(unit)")
                        .font(.headline)
                        .foregroundStyle(Color(hex: activity.colorHex))
                    Text("This Week")
                        .font(.caption2)
                        .foregroundStyle(.black)
                } else {
                    // Empty for now or custom
                }
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
        .shadow(color: Color.black.opacity(0.0), radius: 0, x: 0, y: 0)  // Reset default shadow
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(hex: activity.colorHex).opacity(0.3))
                .offset(x: 0, y: 5)
                .overlay(
                    RoundedRectangle(cornerRadius: 16)
                        .stroke(Color.black, lineWidth: 1.5)
                        .offset(x: 0, y: 5)
                )
                .zIndex(-1)
        )
        .padding(.bottom, 6)  // For the shadow offset
    }
}
