//
//  ThemeManager.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-08-29.
//

import SwiftUI
import RevenueCat

// MARK: - Theme Model
struct AppTheme: Identifiable {
    let id: String
    let name: String
    let lightGradient: [Color]
    let darkGradient: [Color]
    let calendarStyle: CalendarStyle
    let isPremium: Bool
    let calendarBorderColor: Color?
    let calendarBorderWidth: CGFloat
    let calendarTextFont: Font
    let calendarTextColor: Color
    let calendarGlow: Bool
    let buttonGradientLight: [Color]
    let buttonGradientDark: [Color]
    let buttonTextColor: Color
    
    func gradient(for colorScheme: ColorScheme) -> [Color] {
        return colorScheme == .dark ? darkGradient : lightGradient
    }
    
    func buttonGradient(for colorScheme: ColorScheme) -> [Color] {
        return colorScheme == .dark ? buttonGradientDark : buttonGradientLight
    }
}

// MARK: - Theme Manager
class ThemeManager: ObservableObject {
    @Published var selectedTheme: AppTheme
    @Published var isPremiumUnlocked: Bool = false
    
    static let premiumEntitlementID = "premium"
    
    static func premiumActive(from info: CustomerInfo) -> Bool {
        // Primary path: specific entitlement id
        if info.entitlements.all[ThemeManager.premiumEntitlementID]?.isActive == true {
            return true
        }
        // Fallback: if any entitlement is active, treat as premium to avoid dashboard-id drift
        if !info.entitlements.active.isEmpty {
            #if DEBUG
            print("DEBUG: premium entitlement '\(premiumEntitlementID)' not active. Active entitlements: \(info.entitlements.active.keys)")
            #endif
            return true
        }
        return false
    }
    
    init() {
        if let savedID = UserDefaults.standard.string(forKey: "selectedThemeID"),
           let theme = ThemeManager.allThemes.first(where: { $0.id == savedID }) {
            self.selectedTheme = theme
        } else {
            self.selectedTheme = ThemeManager.defaultTheme
        }
        refreshEntitlements()
    }
    
    func selectTheme(_ theme: AppTheme) {
        selectedTheme = theme
        UserDefaults.standard.set(theme.id, forKey: "selectedThemeID")
    }

    func trySelectTheme(_ theme: AppTheme, completion: @escaping (Bool) -> Void) {
        guard theme.isPremium else {
            self.selectTheme(theme)
            completion(true)
            return
        }
        
        // Premium path
        if isPremiumUnlocked {
            self.selectTheme(theme)
            completion(true)
        } else {
            completion(false) // caller should present paywall
        }
    }
    
    func refreshEntitlements(_ completion: (() -> Void)? = nil) {
        Purchases.shared.getCustomerInfo { customerInfo, _ in
            DispatchQueue.main.async {
                if let info = customerInfo {
                    self.isPremiumUnlocked = ThemeManager.premiumActive(from: info)
                } else {
                    self.isPremiumUnlocked = false
                }
                completion?()
            }
        }
    }
    
    // MARK: - Available Themes
    static let defaultTheme = AppTheme(
        id: "default",
        name: "Default",
        lightGradient: [Color.mint.opacity(0.6), Color.pink.opacity(0.4)],
        darkGradient: [Color.mint.opacity(0.7),  Color.black.opacity(0.4)],
        calendarStyle: .circle,
        isPremium: false,
        calendarBorderColor: nil,
        calendarBorderWidth: 0,
        calendarTextFont: .callout,
        calendarTextColor: .white,
        calendarGlow: false,
        buttonGradientLight: [Color.blue.opacity(0.9), Color.teal.opacity(0.9)],
        buttonGradientDark: [Color.indigo.opacity(0.9), Color.mint.opacity(0.9)],
        buttonTextColor: .white
    )
    
    static let allThemes: [AppTheme] = [
        defaultTheme,
        AppTheme(
            id: "sunset",
            name: "Neon ☀️",
            lightGradient: [Color.orange, Color.pink, Color.purple],
            darkGradient: [Color.purple.opacity(0.8), Color.black.opacity(0.9)],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: .purple,
            calendarBorderWidth: 2,
            calendarTextFont: .headline,
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [Color.orange, Color.pink],
            buttonGradientDark: [Color.purple, Color.orange],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "ocean",
            name: "Indigo 🌊",
            lightGradient: [Color.teal, Color.blue, Color.teal],
            darkGradient: [Color.indigo, Color.black.opacity(0.85)],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: .blue,
            calendarBorderWidth: 2,
            calendarTextFont: .system(.body, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [Color.teal, Color.blue],
            buttonGradientDark: [Color.indigo, Color.blue],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "tropicalFizz",
            name: "Tropical Fizz 🏝️",
            lightGradient: [
                Color(red: 0.98, green: 0.88, blue: 0.60),
                Color(red: 0.86, green: 0.98, blue: 0.76)
            ],
            darkGradient: [
                Color(red: 0.16, green: 0.32, blue: 0.18),
                Color(red: 0.08, green: 0.16, blue: 0.10)
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 0.62, green: 0.86, blue: 0.40),
            calendarBorderWidth: 2.0,
            calendarTextFont: .system(.subheadline, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 0.98, green: 0.68, blue: 0.32),
                Color(red: 0.40, green: 0.78, blue: 0.44)
            ],
            buttonGradientDark: [
                Color(red: 0.90, green: 0.56, blue: 0.24),
                Color(red: 0.30, green: 0.72, blue: 0.38)
            ],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "noirRose",
            name: "Noir Rose 🌹",
            lightGradient: [
                Color(red: 0.72, green: 0.64, blue: 0.72),
                Color(red: 0.54, green: 0.46, blue: 0.56)
            ],
            darkGradient: [
                Color(red: 0.12, green: 0.08, blue: 0.16),
                Color(red: 0.06, green: 0.04, blue: 0.10)
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 0.98, green: 0.48, blue: 0.62),
            calendarBorderWidth: 2.2,
            calendarTextFont: .system(.subheadline, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 0.98, green: 0.58, blue: 0.72),
                Color(red: 0.58, green: 0.44, blue: 0.88)
            ],
            buttonGradientDark: [
                Color(red: 0.90, green: 0.42, blue: 0.60),
                Color(red: 0.44, green: 0.30, blue: 0.68)
            ],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "auroraDawn",
            name: "Aurora Dawn 👾",
            lightGradient: [
                Color(red: 0.98, green: 0.62, blue: 0.58),
                Color(red: 0.99, green: 0.76, blue: 0.63),
                Color(red: 1.00, green: 0.88, blue: 0.69)
            ],
            darkGradient: [
                Color(red: 0.36, green: 0.18, blue: 0.38),
                Color(red: 0.18, green: 0.08, blue: 0.25)
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 0.99, green: 0.76, blue: 0.35),
            calendarBorderWidth: 2.0,
            calendarTextFont: .system(.subheadline, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 0.98, green: 0.46, blue: 0.48),
                Color(red: 1.00, green: 0.72, blue: 0.40)
            ],
            buttonGradientDark: [
                Color(red: 0.94, green: 0.36, blue: 0.68),
                Color(red: 0.98, green: 0.62, blue: 0.35)
            ],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "glacierMint",
            name: "Glacier Mint 🧊",
            lightGradient: [
                Color(red: 0.80, green: 0.94, blue: 0.92),
                Color(red: 0.55, green: 0.82, blue: 0.82)
            ],
            darkGradient: [
                Color(red: 0.08, green: 0.20, blue: 0.28),
                Color(red: 0.02, green: 0.06, blue: 0.12)
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 0.42, green: 0.90, blue: 0.92),
            calendarBorderWidth: 2.0,
            calendarTextFont: .system(.subheadline, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 0.36, green: 0.74, blue: 0.78),
                Color(red: 0.19, green: 0.56, blue: 0.80)
            ],
            buttonGradientDark: [
                Color(red: 0.24, green: 0.78, blue: 0.82),
                Color(red: 0.16, green: 0.44, blue: 0.84)
            ],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "solarFlare",
            name: "Solar Flare 🌄",
            lightGradient: [
                Color(red: 0.98, green: 0.78, blue: 0.38),
                Color(red: 0.99, green: 0.86, blue: 0.62)
            ],
            darkGradient: [
                Color(red: 0.60, green: 0.27, blue: 0.12),
                Color(red: 0.14, green: 0.09, blue: 0.22)
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 1.00, green: 0.66, blue: 0.24),
            calendarBorderWidth: 2.0,
            calendarTextFont: .system(.subheadline, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 0.98, green: 0.62, blue: 0.24),
                Color(red: 0.91, green: 0.18, blue: 0.51)
            ],
            buttonGradientDark: [
                Color(red: 1.00, green: 0.46, blue: 0.08),
                Color(red: 0.90, green: 0.17, blue: 0.54)
            ],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "midnightGalaxy",
            name: "Midnight Galaxy 🌌",
            lightGradient: [
                Color(red: 0.92, green: 0.90, blue: 0.98),
                Color(red: 0.82, green: 0.85, blue: 0.95)
            ],
            darkGradient: [
                Color(red: 0.05, green: 0.05, blue: 0.25),
                Color(red: 0.00, green: 0.00, blue: 0.05)
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 0.70, green: 0.40, blue: 1.00),
            calendarBorderWidth: 2.0,
            calendarTextFont: .system(.subheadline, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 0.40, green: 0.20, blue: 0.80),
                Color(red: 0.20, green: 0.40, blue: 0.90)
            ],
            buttonGradientDark: [
                Color(red: 0.50, green: 0.20, blue: 0.90),
                Color(red: 0.30, green: 0.50, blue: 1.00)
            ],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "enchantedForest",
            name: "Enchanted Forest 🌲",
            lightGradient: [
                Color(red: 0.93, green: 0.96, blue: 0.90),
                Color(red: 0.85, green: 0.92, blue: 0.85)
            ],
            darkGradient: [
                Color(red: 0.08, green: 0.24, blue: 0.16),
                Color(red: 0.02, green: 0.10, blue: 0.05)
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 0.85, green: 0.70, blue: 0.30),
            calendarBorderWidth: 2.0,
            calendarTextFont: .system(.subheadline, design: .serif),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 0.30, green: 0.60, blue: 0.40),
                Color(red: 0.50, green: 0.70, blue: 0.30)
            ],
            buttonGradientDark: [
                Color(red: 0.20, green: 0.50, blue: 0.30),
                Color(red: 0.40, green: 0.60, blue: 0.20)
            ],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "royalVelvet",
            name: "Royal Velvet 👑",
            lightGradient: [
                Color(red: 0.98, green: 0.95, blue: 0.90),
                Color(red: 0.95, green: 0.90, blue: 0.85)
            ],
            darkGradient: [
                Color(red: 0.25, green: 0.05, blue: 0.10),
                Color(red: 0.10, green: 0.02, blue: 0.05)
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 1.00, green: 0.84, blue: 0.00),
            calendarBorderWidth: 2.0,
            calendarTextFont: .system(.subheadline, design: .serif),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 0.60, green: 0.10, blue: 0.20),
                Color(red: 0.80, green: 0.60, blue: 0.20)
            ],
            buttonGradientDark: [
                Color(red: 0.70, green: 0.10, blue: 0.25),
                Color(red: 0.90, green: 0.70, blue: 0.10)
            ],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "electricBerry",
            name: "Electric Berry 🫐",
            lightGradient: [
                Color(red: 0.85, green: 0.20, blue: 0.40), // Raspberry
                Color(red: 0.40, green: 0.20, blue: 0.80)  // Violet
            ],
            darkGradient: [
                Color(red: 0.30, green: 0.00, blue: 0.10), // Dark Maroon
                Color(red: 0.10, green: 0.00, blue: 0.30)  // Deep Indigo
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 0.60, green: 0.90, blue: 1.00), // Pale Cyan
            calendarBorderWidth: 2.0,
            calendarTextFont: .system(.subheadline, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 0.85, green: 0.20, blue: 0.40),
                Color(red: 0.40, green: 0.20, blue: 0.80)
            ],
            buttonGradientDark: [
                Color(red: 0.60, green: 0.10, blue: 0.30),
                Color(red: 0.30, green: 0.10, blue: 0.60)
            ],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "cyberDusk",
            name: "Cyber Dusk 🌆",
            lightGradient: [
                Color(red: 1.00, green: 0.40, blue: 0.70), // Hot Pink
                Color(red: 0.20, green: 0.60, blue: 1.00)  // Dodger Blue
            ],
            darkGradient: [
                Color(red: 0.50, green: 0.00, blue: 0.30), // Deep Magenta
                Color(red: 0.00, green: 0.20, blue: 0.50)  // Navy
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color(red: 1.00, green: 0.80, blue: 0.00), // Gold
            calendarBorderWidth: 2.0,
            calendarTextFont: .system(.subheadline, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 1.00, green: 0.40, blue: 0.70),
                Color(red: 0.20, green: 0.60, blue: 1.00)
            ],
            buttonGradientDark: [
                Color(red: 0.70, green: 0.20, blue: 0.50),
                Color(red: 0.10, green: 0.30, blue: 0.70)
            ],
            buttonTextColor: .white
        ),
        AppTheme(
            id: "citrusZest",
            name: "Citrus Zest 🍋",
            lightGradient: [
                Color(red: 1.00, green: 0.90, blue: 0.20), // Lemon
                Color(red: 1.00, green: 0.40, blue: 0.50)  // Grapefruit
            ],
            darkGradient: [
                Color(red: 0.40, green: 0.35, blue: 0.00), // Dark Gold
                Color(red: 0.40, green: 0.10, blue: 0.20)  // Dark Red
            ],
            calendarStyle: .circle,
            isPremium: true,
            calendarBorderColor: Color.white,
            calendarBorderWidth: 2.0,
            calendarTextFont: .system(.subheadline, design: .rounded),
            calendarTextColor: .white,
            calendarGlow: true,
            buttonGradientLight: [
                Color(red: 1.00, green: 0.90, blue: 0.20),
                Color(red: 1.00, green: 0.40, blue: 0.50)
            ],
            buttonGradientDark: [
                Color(red: 0.80, green: 0.70, blue: 0.10),
                Color(red: 0.80, green: 0.20, blue: 0.30)
            ],
            buttonTextColor: .white
        )
    ]
}
