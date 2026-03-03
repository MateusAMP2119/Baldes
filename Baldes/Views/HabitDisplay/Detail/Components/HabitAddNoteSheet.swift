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
                            // SwiftData structs in arrays must often be fully reassigned
                            // to trigger `.onChange` properly across all views.
                            var updatedLog = habit.activityLog

                            for id in group.entryIDs {
                                if let index = updatedLog.firstIndex(where: { $0.id == id }) {
                                    // If a legacy note was stored in `detail` instead of `note`, clear it out
                                    // when we explicitly save a new note to avoid "Old Note • New Note" duplication
                                    if updatedLog[index].detail == updatedLog[index].note
                                        || (updatedLog[index].note == nil
                                            && updatedLog[index].detail != nil)
                                    {
                                        updatedLog[index].detail = nil
                                    }
                                    updatedLog[index].note = newNote
                                }
                            }

                            habit.activityLog = updatedLog
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
                if let group = selectedGroup {
                    if let existingNote = group.entry.note {
                        noteText = existingNote
                    } else if let detailText = group.entry.detail,
                        group.entry.type != .completed && group.entry.type != .taskAdded
                    {
                        // Only prepopulate detail as note if it isn't a native detail string like "Read 20 pages"
                        noteText = detailText
                    }
                }
                isFocused = true
            }
        }
    }
}
