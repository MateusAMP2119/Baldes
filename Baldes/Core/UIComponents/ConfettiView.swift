import SwiftUI

struct ConfettiView: View {
    @State private var particles: [ConfettiParticle] = []
    @State private var animating = false

    private let colors: [Color] = [
        .accentOrange, .accentGreen, .accentBlue,
        .accentPurple, .accentYellow, .accentPink, .accentTeal
    ]

    private let shapes = ["circle.fill", "star.fill", "heart.fill", "diamond.fill"]

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(particles) { particle in
                    Image(systemName: particle.shape)
                        .font(.system(size: particle.size))
                        .foregroundStyle(particle.color)
                        .rotationEffect(.degrees(animating ? particle.spinEnd : 0))
                        .offset(
                            x: particle.x + (animating ? particle.driftX : 0),
                            y: animating ? geo.size.height + 40 : particle.y
                        )
                        .opacity(animating ? 0 : 1)
                }
            }
            .onAppear {
                particles = (0..<40).map { _ in
                    ConfettiParticle(
                        x: CGFloat.random(in: 0...geo.size.width),
                        y: CGFloat.random(in: -60...(-10)),
                        size: CGFloat.random(in: 6...12),
                        color: colors.randomElement()!,
                        shape: shapes.randomElement()!,
                        driftX: CGFloat.random(in: -60...60),
                        spinEnd: Double.random(in: 180...720)
                    )
                }
                withAnimation(.easeIn(duration: 1.8)) {
                    animating = true
                }
            }
        }
    }
}

private struct ConfettiParticle: Identifiable {
    let id = UUID()
    let x: CGFloat
    let y: CGFloat
    let size: CGFloat
    let color: Color
    let shape: String
    let driftX: CGFloat
    let spinEnd: Double
}
