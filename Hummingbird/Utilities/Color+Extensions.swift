import SwiftUI

extension Color {
    // MARK: - Apple Standard Accent Colors
    
    /// Standard Apple blue color
    static let appleBlue = Color(red: 0/255, green: 122/255, blue: 255/255)
    
    /// Standard Apple green color
    static let appleGreen = Color(red: 52/255, green: 199/255, blue: 89/255)
    
    /// Standard Apple indigo color
    static let appleIndigo = Color(red: 88/255, green: 86/255, blue: 214/255)
    
    /// Standard Apple orange color
    static let appleOrange = Color(red: 255/255, green: 149/255, blue: 0/255)
    
    /// Standard Apple pink color
    static let applePink = Color(red: 255/255, green: 45/255, blue: 85/255)
    
    /// Standard Apple purple color
    static let applePurple = Color(red: 175/255, green: 82/255, blue: 222/255)
    
    /// Standard Apple red color
    static let appleRed = Color(red: 255/255, green: 59/255, blue: 48/255)
    
    /// Standard Apple teal color
    static let appleTeal = Color(red: 90/255, green: 200/255, blue: 250/255)
    
    /// Standard Apple yellow color
    static let appleYellow = Color(red: 255/255, green: 204/255, blue: 0/255)
    
    // MARK: - Semantic Colors
    
    /// Success color (Apple green)
    static let success = Color.appleGreen
    
    /// Error/Danger color (Apple red)
    static let error = Color.appleRed
    
    /// Warning color (Apple yellow) 
    static let warning = Color.appleYellow
    
    /// Information color (Apple blue)
    static let info = Color.appleBlue
} 