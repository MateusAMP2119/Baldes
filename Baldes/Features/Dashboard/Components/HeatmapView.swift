import SwiftUI

struct HeatmapView: View {
    // 7 rows for days of the week
    let rows = 7
    // Calculate columns based on available width or fixed count?
    // User said "contained within screen".
    // Let's assume a fixed number of weeks that fits or calculate dynamically.
    // For a static "activity" view, maybe ~20 weeks?
    let columns = 14
    
    // Whites to Reds
    let colors: [Color] = [
        Color(white: 0.95), // Empty
        Color(red: 1.0, green: 0.8, blue: 0.8),
        Color(red: 1.0, green: 0.6, blue: 0.6),
        Color(red: 1.0, green: 0.4, blue: 0.4),
        Color(red: 1.0, green: 0.2, blue: 0.2)
    ]
    
    var body: some View {
        VStack(alignment: .leading, spacing: 5) {
            // Using a grid layout
            HStack(spacing: 3) {
                ForEach(0..<columns, id: \.self) { _ in
                    VStack(spacing: 3) {
                        ForEach(0..<rows, id: \.self) { _ in
                            RoundedRectangle(cornerRadius: 2)
                                .fill(colors.randomElement()!)
                                .aspectRatio(1, contentMode: .fit)
                        }
                    }
                }
            }
        }
    }
}

#Preview {
    HeatmapView()
}
