import SwiftUI

struct HabitAddNoteSheet: View {
    let habit: HabitEntry
    let selectedDate: Date
    let selectedGroup: HabitDetailTypeContent.GroupedActivity?
    var onDismiss: () -> Void

    @State private var noteText = ""
    @FocusState private var isFocused: Bool

    var body: some View {
        NavigationStack {
            VStack(spacing: 16) {
                TextEditor(text: $noteText)
                    .focused($isFocused)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .scrollContentBackground(.hidden)
                    .frame(minHeight: 120)
                    .padding(12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.textTertiary.opacity(0.08))
                    )

                Spacer()
            }
            .padding(.horizontal, 20)
            .padding(.top, 8)
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        onDismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
                        let newNote: String? = trimmed.isEmpty ? nil : trimmed
                        
                        if let group = selectedGroup {
                            // Apply the note to every entry in the group so they stay batched together
                            for id in group.entryIDs {
                                if let index = habit.activityLog.firstIndex(where: { $0.id == id }) {
                                    habit.activityLog[index].note = newNote
                                }
                            }
                        }
                        onDismiss()
                    }
                }
            }
            .onAppear {
                if let group = selectedGroup, let existingNote = group.entry.note {
                    noteText = existingNote
                }
                isFocused = true
            }
        }
    }
}
