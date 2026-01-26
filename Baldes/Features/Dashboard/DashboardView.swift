import SwiftData
import SwiftUI

struct DashboardView: View {
    @State private var showingNewActivitySheet = false
    @State private var activityToEdit: Activity?
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
        .navigationTitle("Activities")
        .sheet(isPresented: $showingNewActivitySheet) {
            NewActivityView()
        }
        .sheet(item: $activityToEdit) { activity in
            ActivityEditView(activity: activity)
        }
    }

    private var activitiesList: some View {
        ScrollView {
            VStack(spacing: 16) {
                ForEach(activities) { activity in
                    ActivityCardView(activity: activity) {
                        activityToEdit = activity
                    }
                }

                // Add button at bottom of list too? Or just toolbar?
                // For now, let's keep the main + button accessible maybe via toolbar or floating
                // But the request implies the empty state was the main issue.
                // Let's add a "New Activity" button at the end of the list as well or floating.

                Button(action: { showingNewActivitySheet = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Novo Balde")
                    }
                    .font(.headline)
                    .foregroundStyle(.gray)
                    .padding(.vertical, 20)
                }
            }
            .padding()
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
