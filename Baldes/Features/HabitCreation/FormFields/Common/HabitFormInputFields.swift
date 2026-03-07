import SwiftUI

// MARK: - Number Field with Stepper

struct HabitFormNumberField: View {
    let label: String
    let unit: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 1...999

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 12) {
                HStack {
                    Text("\(value)")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(unit)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)

                VStack(spacing: 4) {
                    Button {
                        if value < range.upperBound {
                            value += 1
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 50, height: 23)
                            .background(Color(hex: "F5F5F5"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button {
                        if value > range.lowerBound {
                            value -= 1
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 50, height: 23)
                            .background(Color(hex: "F5F5F5"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Decimal Number Field with Stepper

struct HabitFormDecimalField: View {
    let label: String
    let unit: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...999999
    var step: Double = 1.0

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(label)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(Color.textPrimary)

            HStack(spacing: 12) {
                HStack {
                    Text(String(format: "%.0f", value))
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundStyle(Color.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text(unit)
                        .font(.system(size: 15))
                        .foregroundStyle(Color.textSecondary)
                }
                .padding(.horizontal, 16)
                .frame(height: 50)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)

                VStack(spacing: 4) {
                    Button {
                        if value + step <= range.upperBound {
                            value += step
                        }
                    } label: {
                        Image(systemName: "plus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 50, height: 23)
                            .background(Color(hex: "F5F5F5"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)

                    Button {
                        if value - step >= range.lowerBound {
                            value -= step
                        }
                    } label: {
                        Image(systemName: "minus")
                            .font(.system(size: 14, weight: .semibold))
                            .foregroundStyle(Color.textPrimary)
                            .frame(width: 50, height: 23)
                            .background(Color(hex: "F5F5F5"))
                            .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
        }
    }
}

// MARK: - Slider Field for Percentages

struct HabitFormSliderField: View {
    let label: String
    @Binding var value: Double
    var range: ClosedRange<Double> = 0...100

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(label)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
                
                Spacer()
                
                Text("\(Int(value))%")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(Color.textPrimary)
            }

            Slider(value: $value, in: range, step: 5)
                .tint(Color.accentOrange)
                .padding(.horizontal, 16)
                .padding(.vertical, 12)
                .background(Color(hex: "F5F5F5"))
                .cornerRadius(16)
        }
    }
}
