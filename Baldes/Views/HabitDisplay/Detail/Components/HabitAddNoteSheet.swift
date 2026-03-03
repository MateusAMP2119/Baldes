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
            VStack(spacing: 0) {
                TextEditor(text: $noteText)
                    .focused($isFocused)
                    .font(.body)
                    .foregroundStyle(Color.textPrimary)
                    .scrollContentBackground(.hidden)
                    .padding(.horizontal, 24)
                    .padding(.top, 16)
                    
                Spacer()
            }
            .background(Color.bgPage)
            .navigationTitle("Add Note")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        onDismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundStyle(Color.textSecondary)
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button {
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
                    } label: {
                        Image(systemName: "checkmark")
                            .font(.system(size: 16, weight: .bold))
                            .foregroundStyle(habit.habitType.color)
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
