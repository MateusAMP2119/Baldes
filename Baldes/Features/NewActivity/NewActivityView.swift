import SwiftUI

struct NewActivityView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    
                    // Main Activity Types
                    VStack(spacing: 16) {
                        ActivityTypeCard(
                            title: "Timed Activity",
                            description: "Unlimited sessions, unlimited possibilities.",
                            examples: [
                                ActivityExample(emoji: "📚", text: "Reading", detail: "45m Today"),
                                ActivityExample(emoji: "🥊", text: "Muay Thai", detail: "75% W"),
                                ActivityExample(emoji: "🥦", text: "Cooking", detail: "1h")
                            ],
                            shadowColor: Color(red: 0.8, green: 0.2, blue: 0.8) // Purple/Pink
                        )
                        
                        ActivityTypeCard(
                            title: "Simple Tally",
                            description: "Great for habits or simple activities.",
                            examples: [
                                ActivityExample(emoji: "💪", text: "Pull-ups", detail: "25 Today"),
                                ActivityExample(emoji: "🌅", text: "Alcohol-free Days", detail: ""),
                                ActivityExample(emoji: "🪴", text: "Water Plants", detail: "")
                            ],
                            shadowColor: Color(red: 0.9, green: 0.3, blue: 0.3) // Red/Pink
                        )
                        
                        ActivityTypeCard(
                            title: "Measured Tally",
                            description: "For measurements beyond time.",
                            examples: [
                                ActivityExample(emoji: "🔻", text: "Weighted Pull-ups", detail: "5 × 30kg"),
                                ActivityExample(emoji: "🏔️", text: "Hiking", detail: "9mi Today"),
                                ActivityExample(emoji: "🏋️", text: "Clean & Jerk", detail: "3 × 10")
                            ],
                            shadowColor: Color(red: 0.3, green: 0.3, blue: 0.9) // Blue/Purple
                        )
                    }
                    .padding(.horizontal)
                    
                    // Inspiration Sections
                    InspirationSection(title: "Timed Activities", activities: [
                        InspirationItem(emoji: "🌿", title: "Walking", type: "Timed Activity", color: .green),
                        InspirationItem(emoji: "📚", title: "Reading", type: "Timed Activity", color: .blue),
                        InspirationItem(emoji: "🐶", title: "Dog walking", type: "Timed Activity", color: .red)

                    ])
                    
                    InspirationSection(title: "Simple Tallies", activities: [
                        InspirationItem(emoji: "☀️", title: "Wake Up Early", type: "Simple Tally", color: .cyan),
                        InspirationItem(emoji: "🪴", title: "Water Plants", type: "Simple Tally", color: .green),
                        InspirationItem(emoji: "🍳", title: "Cook at Home", type: "Simple Tally", color: .orange)
                    ])
                    
                    InspirationSection(title: "Measured Tallies", activities: [
                        InspirationItem(emoji: "💧", title: "Daily Hydration", type: "Measured Tally", color: .blue),
                        InspirationItem(emoji: "⛰️", title: "Hiking", type: "Measured Tally", color: .brown),
                        InspirationItem(emoji: "🚴", title: "Cycling", type: "Measured Tally", color: .red)
                    ])
                    
                    // Spacer for bottom padding
                    Color.clear.frame(height: 20)
                }
                .padding(.top, 20)
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Text("Novo Balde de actividades")
                        .font(.system(size: 16, weight: .bold)) // Larger custom title
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .padding(.leading, 8) // Adjust alignment
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(Color.black)
                            .font(.system(size: 16))
                    }
                }
            }
        }
    }
}

// MARK: - Supporting Views

struct ActivityTypeCard: View {
    let title: String
    let description: String
    let examples: [ActivityExample]
    let shadowColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "chevron.right")
                    .fontWeight(.semibold)
            }
            
            Text(description)
                .font(.subheadline)
                .foregroundStyle(.primary)
            
            // Examples Row
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(examples, id: \.text) { example in
                        HStack(spacing: 4) {
                            Text(example.emoji)
                            Text(example.text)
                                .fontWeight(.medium)
                            if !example.detail.isEmpty {
                                Text("•")
                                    .foregroundStyle(.secondary)
                                Text(example.detail)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .font(.caption)
                        .padding(.vertical, 4)
                        .padding(.horizontal, 8)
//                        .background(Color.gray.opacity(0.1))
//                        .cornerRadius(8)
                    }
                }
            }
            .scrollDisabled(true) // Just visual for now, or minimal interaction
        }
        .padding(20)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 1.5)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(shadowColor)
                .offset(x: 0, y: 4)
        )
    }
}

struct ActivityExample {
    let emoji: String
    let text: String
    let detail: String
}

struct InspirationSection: View {
    let title: String
    let activities: [InspirationItem]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title2)
                .fontWeight(.bold)
                .padding(.horizontal)
            
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 12) {
                    ForEach(activities, id: \.title) { item in
                        InspirationCard(item: item)
                    }
                }
                .padding(.horizontal)
                .padding(.bottom, 8) // For shadow
            }
        }
    }
}

struct InspirationItem {
    let emoji: String
    let title: String
    let type: String
    let color: Color
}

struct InspirationCard: View {
    let item: InspirationItem
    
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ZStack {
                Circle()
                    .fill(item.color.opacity(0.2))
                    .frame(width: 48, height: 48)
                
                Text(item.emoji)
                    .font(.title2)
            }
            .overlay(
                Circle()
                    .stroke(Color.black, lineWidth: 1)
            )
            .padding(.bottom, 8)
            
            Text(item.title)
                .font(.headline)
            
            Text(item.type)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(width: 140, height: 160, alignment: .topLeading)
        .padding(16)
        .background(Color.white)
        .cornerRadius(16)
        .overlay(
            RoundedRectangle(cornerRadius: 16)
                .stroke(Color.black, lineWidth: 1.5)
        )
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(item.color.opacity(0.3)) // Matches the theme in screenshots roughly
                .offset(x: 2, y: 4)
        )
    }
}

#Preview {
    NewActivityView()
}
