import SwiftUI

struct ActivityConfigurationView: View {
    let activityType: ActivityType
    @Environment(\.dismiss) private var dismiss
    
    // MARK: - State
    @State private var name: String = ""
    @State private var symbol: String = ""
    @State private var selectedColor: Color = .blue
    
    // Measurements
    @State private var useMeasurements: Bool = true
    @State private var measuringType: MeasuringType = .weight
    @State private var preferredUnit: MeasurementUnit = .kg
    
    // More Options
    @State private var isMoreOptionsExpanded: Bool = true
    @State private var hideWidgets: Bool = false
    
    var body: some View {
        ZStack {
            Color(uiColor: .systemGroupedBackground)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 24) {
                    // Header Title
                    HStack {
                        Text(activityType.title)
                            .font(.system(size: 34, weight: .bold))
                            .foregroundStyle(.primary)
                        Spacer()
                    }
                    .padding(.top, 10)
                    
                    // Basic Info Section
                    VStack(spacing: 20) {
                        // Name
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Name")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            TextField("Required", text: $name)
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Symbol
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Symbol")
                                .font(.headline)
                                .foregroundStyle(.secondary)
                            
                            TextField("", text: $symbol) // Placeholder for symbol picker
                                .padding()
                                .frame(height: 50)
                                .background(Color(uiColor: .systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                        }
                        
                        // Color
                        VStack(alignment: .leading, spacing: 8) {
                            ContainerRelativeShape()
                                .fill(Color(uiColor: .systemBackground))
                                .frame(height: 60)
                                .clipShape(RoundedRectangle(cornerRadius: 16))
                                .overlay {
                                    HStack {
                                        Text("Color")
                                            .font(.body)
                                        Spacer()
                                        Circle()
                                            .fill(selectedColor)
                                            .frame(width: 30, height: 30)
                                            .overlay(
                                                Circle()
                                                    .strokeBorder(Color.gray.opacity(0.3), lineWidth: 1)
                                            )
                                            .overlay {
                                                ColorPicker("", selection: $selectedColor)
                                                    .labelsHidden()
                                                    .opacity(0.015)
                                            }
                                    }
                                    .padding(.horizontal)
                                }
                        }
                    }
                    
                    // Measurements Section
                    VStack(alignment: .leading, spacing: 16) {
                        Text("Measurements")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        
                        VStack(spacing: 0) {
                            Toggle("Use Measurements", isOn: $useMeasurements)
                                .padding()
                            
                            if useMeasurements {
                                Divider()
                                    .padding(.leading)
                                
                                HStack {
                                    Text("Measuring")
                                    Spacer()
                                    Picker("Measuring", selection: $measuringType) {
                                        ForEach(MeasuringType.allCases) { type in
                                            Text(type.rawValue).tag(type)
                                        }
                                    }
                                    .tint(.primary)
                                }
                                .padding()
                                
                                Divider()
                                    .padding(.leading)
                                
                                HStack {
                                    Text("Preferred Unit")
                                    Spacer()
                                    Picker("Preferred Unit", selection: $preferredUnit) {
                                        ForEach(MeasurementUnit.allCases) { unit in
                                            Text(unit.rawValue).tag(unit)
                                        }
                                    }
                                    .tint(.primary)
                                }
                                .padding()
                            }
                            
                            // Footer Text
                            if useMeasurements {
                                VStack(alignment: .leading) {
                                    Text("All Measurements are automatically converted to display in your Preferred Unit.")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal)
                                        .padding(.bottom)
                                }
                                .padding(.top, 4)
                            }
                        }
                        .background(Color(uiColor: .systemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                    }
                    
                    // More Options Section
                    VStack(spacing: 16) {
                        Button {
                            withAnimation {
                                isMoreOptionsExpanded.toggle()
                            }
                        } label: {
                            HStack {
                                Text("More Options")
                                    .font(.headline)
                                    .foregroundStyle(.primary)
                                    Spacer()
                                Image(systemName: isMoreOptionsExpanded ? "minus" : "plus")
                                    .font(.system(size: 14, weight: .bold))
                                    .foregroundStyle(.primary)
                            }
                            .padding()
                            .background(Color(uiColor: .systemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                        }
                        
                        if isMoreOptionsExpanded {
                            // Goals
                            VStack(alignment: .leading, spacing: 8) {
                                Text("Goals")
                                    .font(.headline)
                                    .foregroundStyle(.secondary)
                                    .padding(.leading, 4)
                                
                                VStack(spacing: 0) {
                                    HStack {
                                        Text("Weekly")
                                        Spacer()
                                        HStack(spacing: 4) {
                                            Image(systemName: "trophy")
                                            Text("9.00 mi / week")
                                        }
                                        .foregroundStyle(Color.green.opacity(0.7))
                                    }
                                    .padding()
                                    .background(Color(uiColor: .systemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 20)) // Individual card look
                                    
                                    Button {
                                        // Add goal action
                                    } label: {
                                        HStack {
                                            Image(systemName: "sun.max")
                                            Text("Add Goal")
                                        }
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                        .frame(maxWidth: .infinity)
                                        .padding()
                                        .background(Color(uiColor: .systemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 20))
                                    }
                                    .padding(.top, 12)
                                }
                            }
                            
                            // Edit Recurring Plan
                            Button {
                                // Action
                            } label: {
                                HStack {
                                    Image(systemName: "sun.max")
                                    Text("Edit Recurring Plan")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            
                            Text("Create a Recurring Plan for the My Day tab.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                            
                            // Stacks
                            Button {
                                // Action
                            } label: {
                                HStack {
                                    Image(systemName: "line.3.horizontal")
                                    Text("Stacks")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text("1 Stack")
                                        .foregroundStyle(.secondary)
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            }
                            
                            Text("Create Stacks to organize and filter your Activities.")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 4)
                            
                            // Hide Widgets
                            Toggle("Hide Widgets in Expanded List", isOn: $hideWidgets)
                                .padding()
                                .background(Color(uiColor: .systemBackground))
                                .clipShape(RoundedRectangle(cornerRadius: 20))
                            
                            HStack(alignment: .top, spacing: 4) {
                                Text("Widgets are always hidden in Classic and Compact List modes.")
                                Text("🐱") // Placeholder for cat emoji
                            }
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal, 4)
                        }
                    }
                    
                    Spacer(minLength: 40)
                }
                .padding()
            }
        }
        .navigationBarBackButtonHidden(true)
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    dismiss()
                } label: {
                    Image(systemName: "xmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.red)
                        .frame(width: 30, height: 30)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
            
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    // Save action
                } label: {
                    Image(systemName: "checkmark")
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(.green)
                        .frame(width: 30, height: 30)
                        .background(Color.white)
                        .clipShape(Circle())
                        .shadow(color: .black.opacity(0.05), radius: 2, x: 0, y: 1)
                }
            }
        }
    }
}

// MARK: - Helper Types

enum MeasuringType: String, CaseIterable, Identifiable {
    case weight = "Weight"
    case distance = "Distance"
    case time = "Time"
    
    var id: String { rawValue }
}

enum MeasurementUnit: String, CaseIterable, Identifiable {
    case kg = "Kilogram (kg)"
    case lbs = "Pounds (lbs)"
    case mi = "Mile (mi)"
    case km = "Kilometer (km)"
    
    var id: String { rawValue }
}

#Preview {
    ActivityConfigurationView(
        activityType: ActivityType(
            title: "Measured Tally",
            description: "Description",
            examples: [],
            shadowColor: .pink
        )
    )
}
