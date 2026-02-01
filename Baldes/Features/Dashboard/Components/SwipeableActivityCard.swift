import SwiftUI

struct SwipeableActivityCard: View {
    let activity: Activity
    let onDelete: () -> Void
    
    @State private var offset: CGFloat = 0
    @State private var isSwiped: Bool = false
    @State private var cardHeight: CGFloat = 100
    
    private let deleteButtonWidth: CGFloat = 80
    private let swipeThreshold: CGFloat = -60
    private let fullSwipeThreshold: CGFloat = -200
    
    var body: some View {
        ZStack(alignment: .trailing) {
            // Delete background - revealed when swiping
            GeometryReader { geometry in
                HStack(spacing: 0) {
                    Spacer()
                    
                    // Delete action area
                    Button(action: performDelete) {
                        ZStack {
                            Color.red
                            
                            Image(systemName: "trash.fill")
                                .font(.system(size: 20, weight: .semibold))
                                .foregroundStyle(.white)
                        }
                    }
                    .frame(width: max(-offset, 0))
                }
            }
            .frame(height: cardHeight)
            .clipShape(RoundedRectangle(cornerRadius: 16))
            
            // Main card
            ActivityCardView(activity: activity)
                .background(
                    GeometryReader { geometry in
                        Color.clear
                            .onAppear {
                                cardHeight = geometry.size.height
                            }
                            .onChange(of: geometry.size.height) { _, newHeight in
                                cardHeight = newHeight
                            }
                    }
                )
                .background(
                    NavigationLink(destination: ActivityDetailsView(activity: activity)) {
                        EmptyView()
                    }
                    .opacity(0)
                )
                .contentShape(.dragPreview, RoundedRectangle(cornerRadius: 16))
                .onDrag {
                    NSItemProvider(object: activity.id.uuidString as NSString)
                }
                .offset(x: offset)
                .gesture(
                    DragGesture(minimumDistance: 10)
                        .onChanged { value in
                            // Only allow horizontal swipes (more horizontal than vertical)
                            guard abs(value.translation.width) > abs(value.translation.height) else { return }
                            
                            if value.translation.width < 0 {
                                // Swiping left - add resistance after threshold
                                let drag = value.translation.width
                                if drag < swipeThreshold {
                                    // Add rubber band effect
                                    let extra = drag - swipeThreshold
                                    offset = swipeThreshold + extra * 0.3
                                } else {
                                    offset = drag
                                }
                            } else if isSwiped {
                                // Allow closing the swipe
                                offset = -deleteButtonWidth + value.translation.width
                                if offset > 0 { offset = 0 }
                            }
                        }
                        .onEnded { value in
                            let velocity = value.predictedEndTranslation.width - value.translation.width
                            
                            withAnimation(.spring(response: 0.35, dampingFraction: 0.75)) {
                                // Full swipe to delete
                                if offset < fullSwipeThreshold || velocity < -500 {
                                    offset = -UIScreen.main.bounds.width
                                    performDelete()
                                }
                                // Show delete button
                                else if offset < swipeThreshold || velocity < -100 {
                                    offset = -deleteButtonWidth
                                    isSwiped = true
                                }
                                // Reset
                                else {
                                    offset = 0
                                    isSwiped = false
                                }
                            }
                        }
                )
        }
        .onTapGesture {
            if isSwiped {
                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                    offset = 0
                    isSwiped = false
                }
            }
        }
    }
    
    private func performDelete() {
        // Haptic feedback
        let generator = UIImpactFeedbackGenerator(style: .medium)
        generator.impactOccurred()
        
        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
            onDelete()
        }
    }
}

#Preview {
    SwipeableActivityCard(
        activity: Activity(
            name: "Test Activity",
            symbol: "🎯",
            colorHex: "#FF6B6B",
            motivation: "Test motivation"
        ),
        onDelete: {}
    )
    .padding()
}
