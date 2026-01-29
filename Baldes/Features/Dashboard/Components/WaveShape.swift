import SwiftUI

struct WaveShape: Shape {
    var progress: CGFloat
    var waveHeight: CGFloat
    var offset: CGFloat
    
    var animatableData: CGFloat {
        get { offset }
        set { offset = newValue }
    }
    
    func path(in rect: CGRect) -> Path {
        var path = Path()
        path.move(to: .zero)
        
        let progressHeight: CGFloat = (1 - progress) * rect.height
        let height = rect.height
        let width = rect.width
        
        path.move(to: CGPoint(x: 0, y: progressHeight))
        
        for x in stride(from: 0, to: width + 10, by: 10) {
            let y = progressHeight + waveHeight * sin(((x / rect.width) * .pi * 2) + offset)
            path.addLine(to: CGPoint(x: x, y: y))
        }
        
        path.addLine(to: CGPoint(x: width, y: height))
        path.addLine(to: CGPoint(x: 0, y: height))
        path.closeSubpath()
        
        return path
    }
}
