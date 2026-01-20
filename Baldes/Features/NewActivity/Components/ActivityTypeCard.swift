import SwiftUI

struct ActivityTypeCard: View {
    let title: String
    let description: String
    let examples: [ActivityExample]
    let shadowColor: Color

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
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

            Spacer()
                .frame(height: 2)

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
