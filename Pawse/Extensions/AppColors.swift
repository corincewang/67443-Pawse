//
//  AppColors.swift
//  Pawse
//
//  App color palette and theme colors
//

import SwiftUI

extension Color {
    // MARK: - App Color Palette
    
    /// Cream/Off-white - #FFFDF4
    static let pawseOffWhite = Color(hex: "FFFDF4")
    
    /// Coral Red - #F96D6D
    static let pawseCoralRed = Color(hex: "F96D6D")
    
    /// Light Coral/Pink - #FF8686
    static let pawseLightCoral = Color(hex: "FF8686")
    
    /// Olive Green - #769341
    static let pawseOliveGreen = Color(hex: "769341")
    
    /// Orange/Peach - #FB7849
    static let pawseOrange = Color(hex: "FB7849")
    
    /// Golden Yellow - #F7B455
    static let pawseGolden = Color(hex: "F7B455")

    static let bottomBarBackground = Color(hex: "F6DDB2")
    
    /// Brown/Taupe - #84665C
    static let pawseBrown = Color(hex: "84665C")
    
    // MARK: - Semantic Color Names (Optional - for easier usage)
    
    /// Primary accent color
    static let pawsePrimary = pawseCoralRed
    
    /// Secondary accent color
    static let pawseSecondary = pawseOrange
    
    /// Background color
    static let pawseBackground = pawseOffWhite
    
    /// Success/positive color
    static let pawseSuccess = pawseOliveGreen
    
    /// Warning color
    static let pawseWarning = pawseGolden
    
    /// Neutral/muted color
    static let pawseNeutral = pawseBrown
}

// MARK: - Color Extension (for hex colors)
extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 6: // RGB
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue:  Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
