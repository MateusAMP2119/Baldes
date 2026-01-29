import SwiftUI

struct BucketWidgetView: View {
    // 0.0 to 1.0
    var fillPercentage: Double
    
    @State private var waveOffset = 0.0
    
    var body: some View {
        GeometryReader { geometry in
            ZStack {
                // 1. Glass Container Background (The "Air" inside)
                RoundedRectangle(cornerRadius: 22)
                    .fill(.ultraThinMaterial)
                    .shadow(color: .black.opacity(0.1), radius: 10, x: 0, y: 5)
                
                // 2. The Liquid
                WaveShape(progress: fillPercentage, waveHeight: 5, offset: waveOffset)
                    .fill(
                        LinearGradient(
                            colors: [
                                Color(red: 0.906, green: 0.365, blue: 0.227), // #e75d3a
                                Color(red: 1.0, green: 0.5, blue: 0.3)
                            ],
                            startPoint: .bottom,
                            endPoint: .top
                        )
                    )
                    .mask(
                        // Masking to a "Bucket" shape (slightly tapered rectangle)
                        BucketShape()
                            .padding(12)
                    )
                    .opacity(0.9)
                    
                // 3. The Glass Reflection / Glare
                RoundedRectangle(cornerRadius: 22)
                    .strokeBorder(
                        LinearGradient(
                            colors: [.white.opacity(0.5), .white.opacity(0.1)],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        lineWidth: 1
                    )
                
                // 4. Content Overlay (Text)
                VStack {
                    Spacer()
                    HStack {
                        Spacer()
                        Text("\(Int(fillPercentage * 100))%")
                            .font(.system(size: 32, weight: .bold, design: .rounded))
                            .foregroundStyle(fillPercentage > 0.5 ? .white : .primary)
                            .shadow(radius: fillPercentage > 0.5 ? 2 : 0)
                        Spacer()
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            withAnimation(.linear(duration: 2.5).repeatForever(autoreverses: false)) {
                waveOffset = .pi * 2
            }
        }
    }
}

// Simple Tapered Rect for the bucket interior
struct BucketShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()
        // Taper the bottom slightly
        let taper: CGFloat = rect.width * 0.1
        
        path.move(to: CGPoint(x: 0, y: 0))
        path.addLine(to: CGPoint(x: rect.width, y: 0))
        path.addLine(to: CGPoint(x: rect.width - taper, y: rect.height))
        path.addLine(to: CGPoint(x: taper, y: rect.height))
        path.closeSubpath()
        return path
    }
}

#Preview {
    HStack {
        BucketWidgetView(fillPercentage: 0.3)
            .frame(width: 170, height: 170)
        BucketWidgetView(fillPercentage: 0.75)
            .frame(width: 170, height: 170)
    }
    .padding()
    .background(Color.gray.opacity(0.2))
}
