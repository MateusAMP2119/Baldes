import SwiftUI

struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        ScrollView(.vertical, showsIndicators: false) {
            VStack(spacing: 0) {

                // MARK: - Profile Banner
                ProfileBannerSection()
                    .padding(.bottom, 48)  // room for the overlapping avatar

                // MARK: - Stats Strip
                StatsStripView()
                    .padding(.horizontal, 20)

                // MARK: - Activity Graph
                NeoCard(shadowColor: .shadowOrange) {
                    VStack(alignment: .leading, spacing: 14) {
                        HStack {
                            Label {
                                Text("Activity")
                                    .font(.system(size: 17, weight: .heavy))
                                    .foregroundColor(.textPrimary)
                            } icon: {
                                Image(systemName: "chart.bar.fill")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundColor(.accentOrange)
                            }

                            Spacer()

                            // Sticker-style tag
                            Text("🔥 4-month view")
                                .font(.system(size: 10, weight: .black))
                                .foregroundColor(.white)
                                .padding(.horizontal, 10)
                                .padding(.vertical, 4)
                                .background(
                                    Capsule().fill(Color.accentOrange)
                                )
                                .rotationEffect(.degrees(-2))
                        }

                        ContributionGraphView()
                    }
                    .padding(18)
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // MARK: - Achievements
                VStack(alignment: .leading, spacing: 12) {
                    HStack(alignment: .firstTextBaseline) {
                        Text("Achievements")
                            .font(.system(size: 19, weight: .heavy))
                            .foregroundColor(.textPrimary)

                        // Sticker badge count
                        Text("4")
                            .font(.system(size: 11, weight: .black))
                            .foregroundColor(.white)
                            .frame(width: 22, height: 22)
                            .background(Circle().fill(Color.accentOrange))
                            .rotationEffect(.degrees(8))
                            .offset(y: -2)

                        Spacer()

                        Button {
                            // View all
                        } label: {
                            HStack(spacing: 4) {
                                Text("See All")
                                    .font(.system(size: 13, weight: .bold))
                                Image(systemName: "arrow.right")
                                    .font(.system(size: 11, weight: .bold))
                            }
                            .foregroundColor(.accentOrange)
                        }
                    }
                    .padding(.horizontal, 4)

                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: 14) {
                            AchievementRow(
                                title: "On Fire",
                                description: "30-day streak",
                                iconSystemName: "flame.fill",
                                baseColor: .accentOrange,
                                lightColor: .accentOrangeLight,
                                progress: 0.8
                            )
                            .rotationEffect(.degrees(-1.5))

                            AchievementRow(
                                title: "Early Bird",
                                description: "50 morning logs",
                                iconSystemName: "sun.max.fill",
                                baseColor: .accentBlue,
                                lightColor: .accentBlueLightBg,
                                progress: 0.54
                            )
                            .rotationEffect(.degrees(1))

                            AchievementRow(
                                title: "All-Star",
                                description: "100% in a week",
                                iconSystemName: "star.fill",
                                baseColor: .accentPurple,
                                lightColor: .accentPurpleLightBg,
                                progress: 1.0
                            )
                            .rotationEffect(.degrees(-0.8))

                            AchievementRow(
                                title: "Zen Mode",
                                description: "7 journals in a row",
                                iconSystemName: "leaf.fill",
                                baseColor: .accentGreen,
                                lightColor: .accentGreenLight,
                                progress: 0.28
                            )
                            .rotationEffect(.degrees(1.5))
                        }
                        .padding(.horizontal, 4)
                        .padding(.vertical, 10)  // room for rotated cards
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // MARK: - Settings
                VStack(alignment: .leading, spacing: 12) {
                    Text("Settings")
                        .font(.system(size: 19, weight: .heavy))
                        .foregroundColor(.textPrimary)
                        .padding(.horizontal, 4)

                    NeoCard(borderColor: .dividerColor, borderWidth: 1.5, shadowColor: .clear) {
                        VStack(spacing: 0) {
                            SettingsRow(
                                iconName: "person.fill",
                                title: "Account",
                                iconColor: .accentOrange,
                                iconBg: .accentOrangeLight
                            )
                            NeoDivider()
                            SettingsRow(
                                iconName: "bell.fill",
                                title: "Notifications",
                                iconColor: .accentBlue,
                                iconBg: .accentBlueLightBg
                            )
                            NeoDivider()
                            SettingsRow(
                                iconName: "shield.fill",
                                title: "Privacy",
                                iconColor: .accentPurple,
                                iconBg: .accentPurpleLightBg
                            )
                            NeoDivider()
                            SettingsRow(
                                iconName: "square.and.arrow.down.fill",
                                title: "Export Data",
                                iconColor: .accentGreen,
                                iconBg: .accentGreenLight
                            )
                            NeoDivider()
                            SettingsRow(
                                iconName: "archivebox.fill",
                                title: "Archived",
                                iconColor: .accentOrange,
                                iconBg: .accentOrangeLight
                            ) {
                                ArchivedHabitsView()
                            }
                            NeoDivider()
                            SettingsRow(
                                iconName: "questionmark.circle.fill",
                                title: "Help & Support",
                                iconColor: .accentYellow,
                                iconBg: Color(hex: "FEF3C7")
                            )
                            NeoDivider()
                            SettingsRow(
                                iconName: "exclamationmark.triangle.fill",
                                title: "Storage Backdoor",
                                iconColor: .red,
                                iconBg: Color.red.opacity(0.15)
                            ) {
                                StorageBackdoorView()
                            }
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                // MARK: - Sign Out
                Button {
                    // Sign out
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "rectangle.portrait.and.arrow.right")
                            .font(.system(size: 14, weight: .bold))
                        Text("Sign Out")
                            .font(.system(size: 15, weight: .bold))
                    }
                    .foregroundColor(.accentOrange)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 14)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentOrangeLight)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .strokeBorder(Color.accentOrange.opacity(0.4), lineWidth: 2)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.accentOrange.opacity(0.15))
                            .offset(x: 3, y: 3)
                    )
                }
                .padding(.horizontal, 20)
                .padding(.top, 24)

                Text("Baldes v1.0")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundColor(.textTertiary)
                    .padding(.top, 12)
                    .padding(.bottom, 24)
            }
        }
        .background {
            ZStack {
                Color.bgPage.ignoresSafeArea()

                // Warm gradient at top
                LinearGradient(
                    colors: [Color.accentOrangeLight, Color.accentOrangeLight.opacity(0)],
                    startPoint: .top,
                    endPoint: UnitPoint(x: 0.5, y: 0.3)
                )
                .ignoresSafeArea()

                // Decorative dots pattern (neobrutalist texture)
                GeometryReader { geo in
                    Canvas { context, size in
                        let dotSize: CGFloat = 2.5
                        let spacing: CGFloat = 28
                        let cols = Int(size.width / spacing) + 1
                        let rows = min(Int(size.height / spacing) + 1, 12)
                        for row in 0..<rows {
                            for col in 0..<cols {
                                let x =
                                    CGFloat(col) * spacing
                                    + (row.isMultiple(of: 2) ? spacing / 2 : 0)
                                let y = CGFloat(row) * spacing
                                let rect = CGRect(
                                    x: x - dotSize / 2, y: y - dotSize / 2, width: dotSize,
                                    height: dotSize)
                                context.fill(
                                    Circle().path(in: rect),
                                    with: .color(.accentOrange.opacity(0.06)))
                            }
                        }
                    }
                }
                .ignoresSafeArea()
            }
        }
        .navigationTitle("Profile")
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .cancellationAction) {
                Button("Done") { dismiss() }
                    .font(.system(size: 16, weight: .bold))
            }
        }
    }
}

// MARK: - Previews

#Preview {
    NavigationStack {
        ProfileView()
    }
}
