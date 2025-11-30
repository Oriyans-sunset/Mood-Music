//
//  Mood_MusicApp.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-04-23.
//

import SwiftUI
import RevenueCat

@main
struct Mood_MusicApp: App {
    @StateObject private var themeManager: ThemeManager
    
    init() {
        Purchases.configure(withAPIKey: "appl_tFBaXrDfxMlofPVKJbGBXTcMZYT")
        _themeManager = StateObject(wrappedValue: ThemeManager())
    }
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(themeManager)
                .onAppear {
                    themeManager.refreshEntitlements()
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.willEnterForegroundNotification)) { _ in
                    themeManager.refreshEntitlements()
                }
        }
    }
}
