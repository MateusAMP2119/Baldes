import SwiftUI

struct GreetingView: View {
    private var greetingDateString: String {
        let fmt = DateFormatter()
        fmt.dateFormat = "EEEE, MMMM d"
        return fmt.string(from: Date())
    }

    var body: some View {
        HStack(spacing: 12) {
            Image("logo")
                .resizable()
                .scaledToFill()
                .frame(width: 44, height: 44)
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 2) {
                Text(greetingDateString)
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundStyle(Color.textSecondary)
                Text("Hey, Mateus!")
                    .font(.system(size: 26, weight: .black))
                    .tracking(-0.5)
                    .foregroundStyle(Color.textPrimary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
    }
}

#Preview {
    GreetingView()
        .padding(.vertical)
}
