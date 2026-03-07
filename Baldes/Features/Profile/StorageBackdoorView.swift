import SwiftData
import SwiftUI

struct StorageBackdoorView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \HabitEntry.createdAt, order: .reverse) private var allHabits: [HabitEntry]

    var body: some View {
        List {
            Section(header: Text("Raw Local Storage (\(allHabits.count))")) {
                ForEach(allHabits) { habit in
                    VStack(alignment: .leading, spacing: 4) {
                        Text("\(habit.emoji) \(habit.name)")
                            .font(.headline)
                        Group {
                            Text("ID: \(habit.id.uuidString)")
                            Text("Type: \(habit.habitTypeRaw)")
                            Text("Schedule: \(habit.frequency) (0=Once, 1=Daily, 2=Custom)")
                            Text("Created: \(habit.createdAt.formatted())")
                            if habit.habitTypeRaw == "Metrics" {
                                Text("Metrics Target: \(habit.metricTargetValue)")
                            }
                            if habit.habitTypeRaw == "To-Do" {
                                Text("To-Do Items: \(habit.activeTodoItems.count)")
                            }
                        }
                        .font(.caption)
                        .foregroundColor(.secondary)
                    }
                    .padding(.vertical, 4)
                }
            }
        }
        .navigationTitle("Storage Backdoor")
        .navigationBarTitleDisplayMode(.inline)
    }
}

#Preview {
    NavigationStack {
        StorageBackdoorView()
            .modelContainer(for: HabitEntry.self, inMemory: true)
    }
}
