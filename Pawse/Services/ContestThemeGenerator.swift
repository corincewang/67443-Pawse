import Foundation

/// Service to generate contest themes
class ContestThemeGenerator {
    
    /// Pre-generated contest themes
    static let themes: [String] = [
        // Cute themes
        "Most Adorable Sleeping Position",
        "Cutest Puppy Dog Eyes",
        "Most Photogenic Pet",
        "Sweetest Snuggle Moment",
        "Tiniest Paws",
        
        // Funny themes
        "Funniest Derp Face",
        "Silliest Sitting Position",
        "Most Dramatic Pet",
        "Caught in the Act",
        "Weirdest Sleeping Spot",
        "Best Photobomb",
        
        // Active themes
        "Best Action Shot",
        "Fastest Zoomies",
        "Most Athletic Pet",
        "Best Jump or Leap",
        "Mid-Air Moment",
        
        // Expressive themes
        "Most Expressive Face",
        "Happiest Pet",
        "Grumpiest Looking Pet",
        "Most Surprised Expression",
        
        // Seasonal themes
        "Best Winter Outfit",
        "Coziest Fall Photo",
        "Summer Fun",
        "Spring Blossoms",
        
        // Special themes
        "Best Costume",
        "Cutest Yawn",
        "Fluffiest Fur",
        "Most Unique Markings",
        "Best Side-Eye",
        "Longest Tongue",
        "Wettest Nose",
        "Best Ear Flop",
        
        // Personality themes
        "Most Mischievous",
        "Laziest Pet",
        "Most Energetic",
        "Shyest Pet",
        "Biggest Personality",
        
        // Relationship themes
        "Best Pet-Owner Selfie",
        "Cutest Pet Duo",
        "Most Loyal Companion",
        
        // Food themes
        "Hungriest Looking Pet",
        "Best Food Begging Face",
        "Messiest Eater",
        
        // Adventure themes
        "Best Outdoor Adventure",
        "Most Adventurous Explorer",
        "Best Nature Photo",
        
        // Relaxation themes
        "Most Zen Pet",
        "Comfiest Nap Spot",
        "Best Chill Vibes"
    ]
    
    /// Get a random contest theme
    static func getRandomTheme() -> String {
        return themes.randomElement() ?? "Most Adorable Pet"
    }
    
    /// Get multiple unique random themes
    static func getRandomThemes(count: Int) -> [String] {
        return Array(themes.shuffled().prefix(count))
    }
}
