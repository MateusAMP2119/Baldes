import SwiftUI

struct MomentumCard: View {
    let streakDays: Int
    let totalTime: String
    
    var body: some View {
        HStack(spacing: 0) {
            // Left: Streak
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("🔥")
                        .font(.title2)
                    Text("\(streakDays) Dias")
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("TextPrimary"))
                }
                Text("Sequência Atual")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
            
            Divider()
                .frame(height: 40)
            
            // Right: Volume
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text("⏳")
                        .font(.title2)
                    Text(totalTime)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundStyle(Color("TextPrimary"))
                }
                Text("Tempo Total")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding()
        }
        .background(Color("CardBackground"))
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

#Preview {
    MomentumCard(streakDays: 12, totalTime: "14h 30m")
        .padding()
        .background(Color("AppBackground"))
}
