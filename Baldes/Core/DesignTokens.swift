import SwiftUI

// MARK: - Design System Tokens

enum DesignTokens {
    
    // MARK: - Colors
    
    enum Colors {
        static let backgroundMuted = Color(hex: "F5F5F5")
        static let divider = Color(hex: "E0E0E0")
        static let toggleGreen = Color(hex: "34C759")
    }
    
    // MARK: - Typography
    
    enum Typography {
        
        // Headers
        static let headerLarge = Font.system(size: 24, weight: .bold)
        static let headerMedium = Font.system(size: 18, weight: .semibold)
        
        // Body
        static let bodyLarge = Font.system(size: 15, weight: .medium)
        static let bodyRegular = Font.system(size: 15)
        static let bodySmall = Font.system(size: 14)
        static let bodyBold = Font.system(size: 14, weight: .bold)
        static let bodySemibold = Font.system(size: 14, weight: .semibold)
        
        // Labels
        static let labelLarge = Font.system(size: 13, weight: .semibold)
        static let labelMedium = Font.system(size: 13, weight: .medium)
        static let labelSmall = Font.system(size: 12, weight: .semibold)
        static let labelMini = Font.system(size: 11, weight: .medium)
        static let labelTiny = Font.system(size: 10, weight: .medium)
        static let labelCaption = Font.system(size: 10)
        
        // Special
        static let number = Font.system(size: 20, weight: .semibold)
    }
    
    // MARK: - Spacing
    
    enum Spacing {
        static let xs: CGFloat = 4
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
        static let xl: CGFloat = 24
    }
    
    // MARK: - Corner Radius
    
    enum CornerRadius {
        static let sm: CGFloat = 8
        static let md: CGFloat = 12
        static let lg: CGFloat = 16
    }
    
    // MARK: - Dimensions
    
    enum Dimensions {
        static let fieldHeight: CGFloat = 50
        static let buttonHeight: CGFloat = 44
        static let iconSize: CGFloat = 14
    }
}

// MARK: - Convenience Extensions

extension View {
    func backgroundMuted() -> some View {
        self.background(DesignTokens.Colors.backgroundMuted)
    }
    
    func fieldStyle() -> some View {
        self
            .padding(.horizontal, 16)
            .frame(height: DesignTokens.Dimensions.fieldHeight)
            .background(DesignTokens.Colors.backgroundMuted)
            .cornerRadius(DesignTokens.CornerRadius.lg)
    }
}
