import SwiftUI

struct NewActivityView: View {
    @Environment(\.dismiss) private var dismiss
    @State private var navigationPath = NavigationPath()
    
    // MARK: - Data Models
    struct ActivityScope: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let description: String
        let color: Color
        let types: [ActivityType]
        
        static func == (lhs: ActivityScope, rhs: ActivityScope) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    struct ActivityType: Identifiable, Hashable {
        let id = UUID()
        let title: String
        let description: String
        let examples: [ActivityExample]
        let shadowColor: Color
        
        static func == (lhs: ActivityType, rhs: ActivityType) -> Bool {
            lhs.id == rhs.id
        }
        
        func hash(into hasher: inout Hasher) {
            hasher.combine(id)
        }
    }
    
    struct ActivityExample: Hashable {
        let emoji: String
        let text: String
        let detail: String
    }
    
    // MARK: - Data
    private let inputs: [ActivityScope] = [
        ActivityScope(
            title: "Track & Build Habits",
            description: "Log time, count reps, or measure progress.",
            color: Color(red: 0.8, green: 0.2, blue: 0.8),
            types: [
                ActivityType(
                    title: "Timed Activity",
                    description: "Unlimited sessions, unlimited possibilities.",
                    examples: [
                        ActivityExample(emoji: "📚", text: "Reading", detail: "45m Today"),
                        ActivityExample(emoji: "🥊", text: "Muay Thai", detail: "75% W"),
                        ActivityExample(emoji: "🥦", text: "Cooking", detail: "1h")
                    ],
                    shadowColor: Color(red: 0.8, green: 0.2, blue: 0.8)
                ),
                ActivityType(
                    title: "Simple Tally",
                    description: "Great for habits or simple activities.",
                    examples: [
                        ActivityExample(emoji: "💪", text: "Pull-ups", detail: "25 Today"),
                        ActivityExample(emoji: "🌅", text: "Alcohol-free Days", detail: ""),
                        ActivityExample(emoji: "🪴", text: "Water Plants", detail: "")
                    ],
                    shadowColor: Color(red: 0.9, green: 0.3, blue: 0.3)
                ),
                ActivityType(
                    title: "Measured Tally",
                    description: "For measurements beyond time.",
                    examples: [
                        ActivityExample(emoji: "🔻", text: "Weighted Pull-ups", detail: "5 × 30kg"),
                        ActivityExample(emoji: "🏔️", text: "Hiking", detail: "9mi Today"),
                        ActivityExample(emoji: "🏋️", text: "Clean & Jerk", detail: "3 × 10")
                    ],
                    shadowColor: Color(red: 0.3, green: 0.3, blue: 0.9)
                )
            ]
        ),
        ActivityScope(
            title: "Plan & Organize",
            description: "Checklists for trips, errands, or projects.",
            color: Color(red: 0.9, green: 0.6, blue: 0.2),
            types: [
                ActivityType(
                    title: "Checklist",
                    description: "Keep track of tasks and to-dos.",
                    examples: [
                        ActivityExample(emoji: "🛒", text: "Grocery List", detail: "5/12 items"),
                        ActivityExample(emoji: "🎒", text: "Packing List", detail: "Ready"),
                        ActivityExample(emoji: "✅", text: "Daily Tasks", detail: "3 left")
                    ],
                    shadowColor: Color(red: 0.9, green: 0.6, blue: 0.2)
                ),
                ActivityType(
                    title: "Itinerary",
                    description: "Plan trips and sites to see.",
                    examples: [
                        ActivityExample(emoji: "🗼", text: "Tokyo Trip", detail: "Oct 2026"),
                        ActivityExample(emoji: "🏖️", text: "Summer Vacation", detail: "Booked"),
                        ActivityExample(emoji: "📍", text: "Places to Visit", detail: "12 spots")
                    ],
                    shadowColor: Color(red: 0.2, green: 0.6, blue: 0.6)
                )
            ]
        ),
        ActivityScope(
            title: "Write & Reflect",
            description: "Journal entries or freeform notes.",
            color: Color(red: 0.3, green: 0.7, blue: 0.4),
            types: [
                ActivityType(
                    title: "Journal",
                    description: "Write down your thoughts and memories.",
                    examples: [
                        ActivityExample(emoji: "📓", text: "Daily Journal", detail: ""),
                        ActivityExample(emoji: "💭", text: "Thoughts", detail: "Morning"),
                        ActivityExample(emoji: "✨", text: "Gratitude", detail: "Evening")
                    ],
                    shadowColor: Color(red: 0.3, green: 0.7, blue: 0.4)
                ),
                ActivityType(
                    title: "Notes",
                    description: "General note taking for anything.",
                    examples: [
                        ActivityExample(emoji: "📝", text: "Quick Notes", detail: ""),
                        ActivityExample(emoji: "💡", text: "Ideas", detail: "Project A"),
                        ActivityExample(emoji: "🏗️", text: "Meeting Notes", detail: "Weekly")
                    ],
                    shadowColor: Color(red: 0.5, green: 0.5, blue: 0.5)
                )
            ]
        )
    ]
    
    var body: some View {
        NavigationStack(path: $navigationPath) {
            GoalSelectionView(scopes: inputs) { selectedScope in
                navigationPath.append(selectedScope)
            }
            .navigationTitle("Novo Balde de atividades")
            .font(.system(size: 16, weight: .bold))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark")
                            .foregroundColor(Color.black)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .navigationDestination(for: ActivityScope.self) { scope in
                ActivityTypeSelectionView(scope: scope)
            }
        }
    }
}

// MARK: - Step 1: Goal Selection View

struct GoalSelectionView: View {
    let scopes: [NewActivityView.ActivityScope]
    let onSelect: (NewActivityView.ActivityScope) -> Void
    
    var body: some View {
        ZStack(alignment: .bottom) {
            ScrollView {
                VStack(alignment: .leading, spacing: 24) {
                    Text("Por onde começar?")
                        .font(.largeTitle)
                        .fontWeight(.bold)
                        .padding(.horizontal)
                        .padding(.top, 20)
                    
                    VStack(spacing: 16) {
                        ForEach(scopes) { scope in
                            GoalCard(scope: scope) {
                                onSelect(scope)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
                Color.clear.frame(height: 250)
            }
            
            Image("Think")
                .resizable()
                .scaledToFit()
                .frame(height: 250)
                .ignoresSafeArea(edges: .bottom)
        }
    }
}

struct GoalCard: View {
    let scope: NewActivityView.ActivityScope
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(scope.title)
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundStyle(.primary)
                    
                    Text(scope.description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                }
                
                Spacer()
                
                Image(systemName: "chevron.right")
                    .foregroundStyle(.tertiary)
                    .fontWeight(.semibold)
            }
            .padding(20)
            .background(Color.white)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.black, lineWidth: 1.5)
            )
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(scope.color)
                    .offset(x: 0, y: 4)
            )
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Step 2: Activity Type Selection View

struct ActivityTypeSelectionView: View {
    let scope: NewActivityView.ActivityScope
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 24) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(scope.title)
                        .font(.largeTitle)
                        .fontWeight(.bold)
                    
                    Text("Choose a template to get started")
                        .font(.body)
                        .foregroundStyle(.secondary)
                }
                .padding(.horizontal)
                .padding(.top, 20)
                
                VStack(spacing: 16) {
                    ForEach(scope.types) { type in
                        ActivityTypeCard(
                            title: type.title,
                            description: type.description,
                            examples: type.examples,
                            shadowColor: type.shadowColor
                        )
                    }
                }
                .padding(.horizontal)
                
                Color.clear.frame(height: 20)
            }
        }
    }
}

// MARK: - Supporting Views

struct ActivityTypeCard: View {
    let title: String
    let description: String
    let examples: [NewActivityView.ActivityExample]
    let shadowColor: Color
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text(title)
                    .font(.title2)
                    .fontWeight(.bold)
                Spacer()
                Image(systemName: "plus")
                    .fontWeight(.semibold)
                    .padding(6)
                    .background(Color.black.opacity(0.05))
                    .clipShape(Circle())
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
                        .background(Color.gray.opacity(0.1))
                        .cornerRadius(8)
                    }
                }
            }
            .scrollDisabled(true) // Just visual for now
        }
        .padding(20)
        .background(Color.white)
        .clipShape(RoundedRectangle(cornerRadius: 16))
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

#Preview {
    NewActivityView()
}
