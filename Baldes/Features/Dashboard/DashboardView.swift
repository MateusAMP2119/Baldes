import SwiftData
import SwiftUI

struct DashboardView: View {
    @State private var showingNewActivitySheet = false
    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [Activity]

    var body: some View {
        ZStack {
            // Background color
            Color("AppBackground").ignoresSafeArea()

            // Content
            if activities.isEmpty {
                activitiesEmptyState
                    .padding(.bottom, 80)
            } else {
                activitiesList
            }
        }

        .sheet(isPresented: $showingNewActivitySheet) {
            NewActivityView()
        }
    }

    private var activitiesList: some View {
        VStack(spacing: 0) {
            // Header outside of List - so drop works
            VStack(alignment: .leading, spacing: 0) {
                Text("Actividades")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top, 18)

                CalendarStripView(
                    activities: activities,
                    onScheduleActivity: scheduleActivity
                )
                .padding(.bottom, 10)
            }
            .padding(.horizontal)
            .padding(.bottom, 10)
            .background(Color("AppBackground"))  // Ensure header is opaque over any scrolling content if it were to go under directly
            .zIndex(1)  // Ensure header stays on top

            // List only for activity cards - native swipe works
            ZStack(alignment: .top) {
                List {
                    ForEach(activities) { activity in
                        ActivityCardView(activity: activity)
                            .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 16))
                            .onDrag {
                                NSItemProvider(object: activity.id.uuidString as NSString)
                            }
                            .background(
                                NavigationLink(destination: ActivityDetailsView(activity: activity))
                                {
                                    EmptyView()
                                }
                                .opacity(0)
                            )
                            .listRowSeparator(.hidden)
                            .listRowBackground(Color.clear)
                            .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    deleteActivity(activity)
                                } label: {
                                    Label("Eliminar", systemImage: "trash")
                                }
                            }
                    }

                    // Bottom Spacing
                    Color.clear
                        .frame(height: 80)
                        .listRowSeparator(.hidden)
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets())
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)

                // Gradient Overlay
                LinearGradient(
                    stops: [
                        .init(color: Color("AppBackground"), location: 0.0),
                        .init(color: Color("AppBackground").opacity(0), location: 1.0),
                    ],
                    startPoint: .top,
                    endPoint: .bottom
                )
                .frame(height: 12)
                .allowsHitTesting(false)  // Let touches pass through to the list
            }
        }
    }

    // MARK: - Schedule Activity

    private func scheduleActivity(activityId: UUID, at scheduledTime: Date) {
        guard let activity = activities.first(where: { $0.id == activityId }) else { return }

        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: scheduledTime)
        let minute = calendar.component(.minute, from: scheduledTime)

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            // Check if it's a recurring activity
            if let days = activity.recurringDays, !days.isEmpty {
                // Create or update exception for this specific date
                let startOfDay = calendar.startOfDay(for: scheduledTime)

                if let existingException = activity.exceptions?.first(where: {
                    calendar.isDate($0.originalDate, inSameDayAs: startOfDay)
                }) {
                    existingException.newHour = hour
                    existingException.newMinute = minute
                } else {
                    let exception = ActivityScheduleException(
                        originalDate: startOfDay,
                        newHour: hour,
                        newMinute: minute
                    )
                    if activity.exceptions == nil {
                        activity.exceptions = []
                    }
                    activity.exceptions?.append(exception)
                }
            } else {
                // Non-recurring: update global schedule
                activity.scheduledTime = scheduledTime
                activity.scheduledHour = hour
                activity.scheduledMinute = minute
            }
        }

        // Update notifications to reflect schedule changes
        NotificationManager.shared.updateNotifications(for: activity)
    }

    private func deleteActivity(_ activity: Activity) {
        // Cancel notifications before deleting
        NotificationManager.shared.cancelNotifications(for: activity)

        withAnimation {
            modelContext.delete(activity)
        }
    }

    private var activitiesEmptyState: some View {
        VStack(spacing: 16) {
            Spacer()

            // Empty State Image
            Image("Empty")
                .resizable()
                .scaledToFill()
                .frame(width: 220, height: 220)
                .clipped()

            VStack(spacing: 8) {
                Text("Sem Baldes criados!")
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundStyle(Color("TextPrimary"))

                Text("Vamos criar um novo Balde para começar.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
            .padding(.bottom, 16)
            .multilineTextAlignment(.center)

            // 3D Button "Add Activity"
            Button(action: { showingNewActivitySheet = true }) {
                Text("Novo Balde")
                    .font(.system(size: 17, weight: .bold))
                    .foregroundStyle(Color("TextPrimary"))
                    .padding(.horizontal, 32)
                    .padding(.vertical, 16)
                    .background(Color("CardBackground"))
                    .clipShape(RoundedRectangle(cornerRadius: 16))
                    .overlay(
                        RoundedRectangle(cornerRadius: 16)
                            .stroke(Color("Border"), lineWidth: 2)
                    )
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color.accentColor)
                            .offset(x: 4, y: 4)
                    )
                    .contentShape(Rectangle())
            }
            .buttonStyle(PlainButtonStyle())  // Prevent default opacity effect on press if desired

            // Demo Link
            Button(action: {}) {
                HStack(spacing: 4) {
                    Image(systemName: "sparkles")
                    Text("Ver exemplos")
                }
                .font(.subheadline)
                .foregroundStyle(.gray)
                .padding(.top, 8)
            }

            Spacer()
        }
    }
}

#Preview {
    DashboardView()
}
