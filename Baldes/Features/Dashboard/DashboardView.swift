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

        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            activity.scheduledTime = scheduledTime
        }
    }

    private func deleteActivity(_ activity: Activity) {
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
                    .background(
                        ZStack {
                            // Shadow/Depth layer
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(red: 0.906, green: 0.365, blue: 0.227))  // #e75d3a
                                .offset(y: 4)

                            // Top layer
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color("CardBackground"))
                                .overlay(
                                    Circle()
                                        .stroke(Color("Border"), lineWidth: 1)
                                )
                        }
                    )
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
