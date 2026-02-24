import SwiftUI

struct SettingsRow: View {
    let iconName: String
    let title: String
    var iconColor: Color = .textSecondary
    var iconBg: Color = .bgMuted
    var subtitle: String? = nil

    @State private var isPressed = false

    var body: some View {
        Button {
            // Navigate
        } label: {
            HStack(spacing: 14) {
                // Colored icon pill with neo border
                ZStack {
                    RoundedRectangle(cornerRadius: 9)
                        .fill(iconBg)
                        .frame(width: 36, height: 36)
                        .overlay(
                            RoundedRectangle(cornerRadius: 9)
                                .strokeBorder(iconColor.opacity(0.2), lineWidth: 1)
                        )

                    Image(systemName: iconName)
                        .font(.system(size: 15, weight: .semibold))
                        .foregroundColor(iconColor)
                }

                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(.system(size: 15, weight: .bold))
                        .foregroundColor(.textPrimary)

                    if let subtitle {
                        Text(subtitle)
                            .font(.system(size: 11, weight: .medium))
                            .foregroundColor(.textTertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(.textTertiary)
                    .frame(width: 20, height: 20)
                    .background(
                        Circle().fill(Color.bgMuted.opacity(0.6))
                    )
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 13)
            .background(isPressed ? Color.bgMuted.opacity(0.4) : Color.clear)
            .contentShape(Rectangle())
        }
        .buttonStyle(SettingsButtonStyle(isPressed: $isPressed))
    }
}

// Custom button style for press feedback
private struct SettingsButtonStyle: ButtonStyle {
    @Binding var isPressed: Bool

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? 0.98 : 1.0)
            .animation(.easeInOut(duration: 0.15), value: configuration.isPressed)
            .onChange(of: configuration.isPressed) { _, newValue in
                isPressed = newValue
            }
    }
}
