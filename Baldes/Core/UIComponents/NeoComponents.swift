import SwiftUI

// MARK: - Reusable Neo Components

struct NeoCard<Content: View>: View {
    var borderColor: Color = .borderStrong
    var borderWidth: CGFloat = 2
    var shadowColor: Color = .shadowOrange
    @ViewBuilder var content: Content

    var body: some View {
        content
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(Color.white)
            )
            .clipShape(RoundedRectangle(cornerRadius: 14))
            .overlay(
                RoundedRectangle(cornerRadius: 14)
                    .strokeBorder(borderColor, lineWidth: borderWidth)
            )
            .background(
                RoundedRectangle(cornerRadius: 14)
                    .fill(shadowColor)
                    .offset(x: 4, y: 4)
            )
    }
}

struct NeoDivider: View {
    var body: some View {
        Rectangle()
            .fill(Color.dividerColor)
            .frame(height: 1)
            .padding(.horizontal, 16)
    }
}
