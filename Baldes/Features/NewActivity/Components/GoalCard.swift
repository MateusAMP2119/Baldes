import SwiftUI

struct GoalCard: View {
    let scope: ActivityScope
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
            .background(Color("CardBackground"))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color("Border"), lineWidth: 1.5)
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
