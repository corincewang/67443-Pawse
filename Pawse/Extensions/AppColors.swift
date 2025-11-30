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
    
    /// background color for pet cards
    static let pawseLightCoral = Color(hex: "FF8686")

    static let pawseLightCoralBackground = Color(hex: "FF8686").opacity(0.3)

    static let pawseYellow = Color(hex: "F0CC8D")

    static let pawseYellowBackground = Color(hex: "F0CC8D").opacity(0.3)

    static let pawseLightGreen = Color(hex: "9ABA5F")

    static let pawseLightGreenBackground = Color(hex: "9ABA5F").opacity(0.3)
    
    // MARK: - Pet Card Colors
    static let petCardColors: [(background: Color, accent: Color)] = [
        (pawseLightCoralBackground, pawseLightCoral),
        (pawseYellowBackground, pawseYellow),
        (pawseLightGreenBackground, pawseLightGreen)
    ]
    
    /// Olive Green - #769341
    static let pawseOliveGreen = Color(hex: "769341")
    
    /// Orange/Peach - #FB7849
    static let pawseOrange = Color(hex: "FB7849")

    static let pawseDarkCoral = Color(hex: "DE5B5B");
    
    /// Golden Yellow - #F7B455
    static let pawseGolden = Color(hex: "F7B455")

    static let bottomBarBackground = Color(hex: "F6DDB2")
    
    /// Brown/Taupe - #84665C
    static let pawseBrown = Color(hex: "84665C")

    static let PawseGrey = Color(hex: "6B68A9")
    
    /// PawseGrey with 8% opacity (for pet info card background)
    static let pawseGreyBackground = Color(hex: "6B68A9").opacity(0.08)

    static let pawseWarmGrey = Color(hex: "D9CAB0")
    
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

extension Color {
    /// Returns a background + accent pair from the fixed palette for a given identifier.
    static func petColorPair(for identifier: String) -> (background: Color, accent: Color) {
        guard !petCardColors.isEmpty else {
            return (pawseLightCoralBackground, pawseLightCoral)
        }
        let index = abs(identifier.hashValue) % petCardColors.count
        return petCardColors[index]
    }
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
