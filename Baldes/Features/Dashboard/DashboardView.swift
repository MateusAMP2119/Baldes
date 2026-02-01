import SwiftData
import SwiftUI

struct DashboardView: View {
    @State private var showingNewActivitySheet = false
    @Environment(\.modelContext) private var modelContext
    @Query private var activities: [Activity]

    var body: some View {
        ZStack {
            // Background color
            Color.white.ignoresSafeArea()

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
        List {
            // Header Section
            Group {
                Text("Actividades")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                    .padding(.horizontal)
                    .padding(.top, 16)

                CalendarStripView(
                    activities: activities,
                    onScheduleActivity: scheduleActivity
                )
                .offset(y: -8)
                .padding(.bottom, 8)
            }
            .listRowSeparator(.hidden)
            .listRowInsets(EdgeInsets())
            .listRowBackground(Color.clear)

            // Content Section
            ForEach(activities) { activity in
                ActivityCardView(activity: activity)
                    .background(
                        NavigationLink(destination: ActivityDetailsView(activity: activity)) {
                            EmptyView()
                        }
                        .opacity(0)
                    )
                    .onDrag {
                        NSItemProvider(object: activity.id.uuidString as NSString)
                    }
                    .listRowSeparator(.hidden)
                    .listRowBackground(Color.clear)
                    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                        Button(role: .destructive) {
                            deleteActivity(activity)
                        } label: {
                            Label("Eliminar", systemImage: "trash")
                        }
                        .tint(.red)
                    }
            }

            // Bottom Spacing within List
            Color.clear
                .frame(height: 80)
                .listRowSeparator(.hidden)
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets())
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)  // Removes default gray background
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
                    .foregroundStyle(.black)

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
                    .foregroundStyle(.black)
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
                                .fill(Color.white)
                                .stroke(Color.black, lineWidth: 1)
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
