import SwiftUI

// MARK: - Date Field with Native DatePicker

struct HabitFormDateField: View {
    let label: String
    @Binding var date: Date
    var trailingIcon: String = "calendar"

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            DatePicker(
                "",
                selection: $date,
                displayedComponents: .date
            )
            .datePickerStyle(.compact)
            .labelsHidden()
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 16)
            .frame(height: 50)
            .background(Color(hex: "F5F5F5"))
            .cornerRadius(12)
        }
    }
}

// MARK: - Track Duration Field (Start Date + Duration Menu)

struct HabitFormTrackDurationField: View {
    let label: String
    @Binding var startDate: Date
    @Binding var durationType: Int // 0 = 7 days, 1 = 30 days, 2 = custom
    @Binding var customEndDate: Date
    
    private var durationText: String {
        switch durationType {
        case 0: return "7 days"
        case 1: return "30 days"
        case 2:
            let formatter = DateFormatter()
            formatter.dateStyle = .medium
            return formatter.string(from: customEndDate)
        default: return "30 days"
        }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 12) {
                // Start Date
                VStack(alignment: .leading, spacing: 4) {
                    Text("Start")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                    
                    DatePicker(
                        "",
                        selection: $startDate,
                        in: ...Date().addingTimeInterval(365 * 24 * 60 * 60),
                        displayedComponents: .date
                    )
                    .datePickerStyle(.compact)
                    .labelsHidden()
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
                
                // Duration Menu
                VStack(alignment: .leading, spacing: 4) {
                    Text("Duration")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundStyle(Color.textSecondary)
                    
                    Menu {
                        Button {
                            durationType = 0
                        } label: {
                            Label("7 days", systemImage: durationType == 0 ? "checkmark" : "")
                        }
                        
                        Button {
                            durationType = 1
                        } label: {
                            Label("30 days", systemImage: durationType == 1 ? "checkmark" : "")
                        }
                        
                        Button {
                            durationType = 2
                        } label: {
                            Label("Custom date", systemImage: durationType == 2 ? "checkmark" : "")
                        }
                    } label: {
                        HStack {
                            Text(durationText)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(Color.textPrimary)
                            Spacer()
                            Image(systemName: "chevron.down")
                                .font(.system(size: 13, weight: .medium))
                                .foregroundStyle(Color.textTertiary)
                        }
                    }
                }
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .frame(height: 50)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
            }
            
            // Custom end date picker (only shown when custom is selected)
            if durationType == 2 {
                DatePicker(
                    "End Date",
                    selection: $customEndDate,
                    in: startDate...,
                    displayedComponents: .date
                )
                .datePickerStyle(.graphical)
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
                .transition(.blurReplace)
            }
        }
        .animation(.spring(duration: 0.3), value: durationType)
    }
}
