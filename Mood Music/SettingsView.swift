//
//  SettingsView.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-05-02.
//

import SwiftUI
import UserNotifications
import RevenueCat
import RevenueCatUI

enum MusicProvider: String, CaseIterable, Identifiable {
    case appleMusic = "Apple Music"
    case spotify = "Spotify"

    var id: String { self.rawValue }
}

struct SettingsView: View {
    @State private var showingPrivacy = false
    @AppStorage("notificationTime") private var notificationTime: Date = {
        var components = DateComponents()
        components.hour = 9
        components.minute = 0
        return Calendar.current.date(from: components) ?? Date()
    }()
    @State private var notificationsEnabled = false
    @State private var notificationsDenied = false
    @State private var showingNotificationAlert = false
    @Environment(\.colorScheme) private var colorScheme
    @AppStorage("preferredMusicProvider") private var preferredMusicProvider: MusicProvider = .appleMusic
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showThemeChangedToast = false
    
    @State private var showingPaywall = false
    @State private var currentOffering: RevenueCat.Offering?
    @State private var pendingThemeSelection: AppTheme?
    @State private var isFetchingOffering = false
    @State private var paywallError: String?
    
    var body: some View {

        let styledText: AttributedString = {
            var result = AttributedString("MoodMusic")

            if let range = result.range(of: "Mood") {
                result[range].foregroundColor = .mint
            }
            if let range = result.range(of: "Music") {
                result[range].foregroundColor = .pink
            }

            return result
        }()

        List {

            Section {
                VStack(spacing: 8) {
                    Image("appstore")
                        .resizable()
                        .frame(width: 100, height: 100)
                        .clipShape(
                            RoundedRectangle(
                                cornerRadius: 16,
                                style: .continuous
                            )
                        )
                        .shadow(radius: 4)

                    Text(styledText)
                        .font(.title)
                        .fontWeight(.bold)
                        .font(.title)
                        .fontWeight(.bold)

                    Text("By priyanshu")
                        .font(.headline)
                        .foregroundColor(.gray)
                }
                .frame(maxWidth: .infinity)
                .listRowBackground(Color.clear)
            }
            
            if !themeManager.isPremiumUnlocked {
                Section {
                    Button(action: {
                        showingPaywall = true
                        if currentOffering == nil {
                            fetchOfferingsIfNeeded()
                        }
                    }) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("Upgrade to Extra ✨")
                                    .fontWeight(.semibold)
                                Text("Unlock premium themes, stats, and exports.")
                                    .font(.footnote)
                                    .foregroundColor(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.up.dotted.2")
                                .foregroundColor(.blue)
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
            
            Section(header: Text("Daily Log Reminder")) {
                Toggle("Enable Reminder", isOn: $notificationsEnabled)
                    .onChange(of: notificationsEnabled) { isOn in
                        if isOn {
                            NotificationManager.shared.requestPermission()
                            NotificationManager.shared.scheduleDailyReminder(at: notificationTime)
                            // Check current settings after requesting permission
                            UNUserNotificationCenter.current().getNotificationSettings { settings in
                                DispatchQueue.main.async {
                                    notificationsDenied = (settings.authorizationStatus == .denied)
                                }
                            }
                        } else {
                            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
                            notificationsDenied = false
                        }
                    }

                if notificationsEnabled {
                    DatePicker("Reminder Time", selection: $notificationTime, displayedComponents: .hourAndMinute)
                        .onChange(of: notificationTime) { newTime in
                            NotificationManager.shared.scheduleDailyReminder(at: newTime)
                        }
                }

                if notificationsEnabled && notificationsDenied {
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundColor(.red)
                            .onTapGesture {
                                showingNotificationAlert = true
                            }
                        Text("Notifications are off in system settings.")
                            .font(.footnote)
                            .foregroundColor(.red)
                            .onTapGesture {
                                showingNotificationAlert = true
                            }
                    }
                }
            }

            Section(header: Text("Music Service")) {
                Picker("Preferred Provider", selection: $preferredMusicProvider) {
                    ForEach(MusicProvider.allCases) { provider in
                        Text(provider.rawValue).tag(provider)
                    }
                }
                .pickerStyle(.menu)
            }
            
            Section(header: Text("Themes")) {
                ForEach(ThemeManager.allThemes) { theme in
                    HStack {
                        RoundedRectangle(cornerRadius: 8)
                            .fill(
                                LinearGradient(
                                    gradient: Gradient(colors: theme.gradient(for: colorScheme)),
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 60, height: 40)
                        Text(theme.name)
                        Spacer()
                        if themeManager.selectedTheme.id == theme.id {
                            Image(systemName: "checkmark")
                                .foregroundColor(.blue)
                        }
                        if theme.isPremium && !themeManager.isPremiumUnlocked {
                            Image(systemName: "lock.fill")
                                .foregroundColor(.gray)
                        }
                    }
                    .contentShape(Rectangle())
                    .onTapGesture {
                        handleThemeTap(theme)
                    }
                }
            }
            
            Section(header: Text("Check Out My Other App")) {
                HStack(alignment: .center, spacing: 16) {
                    Image("tagtrail")
                        .resizable()
                        .frame(width: 80, height: 80)
                        .cornerRadius(8)
                    VStack(alignment: .leading, spacing: 2) {
                        Text("TagTrail")
                            .font(.headline)
                        Text("Location-based reminders made easy.")
                            .font(.subheadline)
                            .foregroundColor(.gray)
                    }
                    Spacer()
                    Button(action: {
                        if let url = URL(
                            string:
                                "https://apps.apple.com/us/app/tagtrail/id6749494325"
                        ) {
                            UIApplication.shared.open(url)
                        }
                    }) {
                        Text("GET")
                            .fontWeight(.bold)
                            .foregroundColor(.blue)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 8)
                            .background(
                                Capsule()
                                    .fill(Color.blue.opacity(0.1))
                            )
                    }
                }
                .padding(.vertical)
                
            }

            Section(header: Text("Powered By")) {
                Text("MoodMusic uses the OpenAI API for song recommendations.")
                Text(
                    "Song previews and album art are provided by the iTunes Search API."
                )
                Link(
                    "OpenAI Terms",
                    destination: URL(
                        string: "https://openai.com/policies/terms-of-use"
                    )!
                )
                Link(
                    "Apple Media Services Terms",
                    destination: URL(
                        string:
                            "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/"
                    )!
                )
            }

            Section(header: Text("Legal")) {
                Button(action: {
                    // open privacy sheet
                    showingPrivacy = true
                }) {
                    Text("Privacy")
                }
            }

            Section(header: Text("Support")) {
                Link(
                    "Feedback",
                    destination: URL(
                        string:
                            "mailto:ryzenlyve@gmail.com?subject=MoodMusic%20Feedback"
                    )!
                )

                Link(
                    "Acknowledgements",
                    destination: URL(
                        string:
                            "https://fonts.google.com/specimen/Pacifico/about"
                    )!
                )
            }
            
            Section(header: Text("About")) {

                HStack {
                    Text("App Version")
                    Spacer()
                    Text(
                        Bundle.main.infoDictionary?[
                            "CFBundleShortVersionString"
                        ] as? String ?? "N/A"
                    )
                    .foregroundColor(.gray)
                }
            }
            
            Text("Shout out to my best friend for the design inspiration!💛")
                .font(.footnote)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(1)

        }
        .overlay(
            Group {
                if showThemeChangedToast {
                    Text("Theme changed to \(themeManager.selectedTheme.name)")
                        .font(.subheadline)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 10)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                        .shadow(radius: 3)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                        .padding(.bottom, 40)
                }
            },
            alignment: .bottom
        )
        .onAppear {
            //load offering on appear
            fetchOfferingsIfNeeded()
            
            UNUserNotificationCenter.current().getNotificationSettings { settings in
                DispatchQueue.main.async {
                    notificationsDenied = (settings.authorizationStatus == .denied)
                    notificationsEnabled = (settings.authorizationStatus == .authorized || settings.authorizationStatus == .provisional)

                    // Reschedule to ensure new settings apply
                    if notificationsEnabled {
                        NotificationManager.shared.scheduleDailyReminder(at: notificationTime)
                    }
                }
            }
        }
        .navigationTitle("Settings")
        .alert(isPresented: $showingNotificationAlert) {
            Alert(
                title: Text("Notifications Disabled"),
                message: Text("Notifications are enabled in the app, but turned off in your system settings. You can enable them in Settings > Notifications > MoodMusic."),
                dismissButton: .default(Text("OK"))
            )
        }
        .sheet(isPresented: $showingPaywall) {
            if let offering = currentOffering {
                if offering.availablePackages.isEmpty {
                    VStack(spacing: 12) {
                        Text("Purchases unavailable right now.")
                            .font(.headline)
                        Text("No purchase packages are currently available. Please try again later.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                        Button("Close") {
                            showingPaywall = false
                        }
                        .buttonStyle(.borderedProminent)
                    }
                    .padding()
                } else {
                    PaywallView(offering: offering)
                        .onPurchaseCompleted { customerInfo in
                            print("RC purchase entitlements - all: \(customerInfo.entitlements.all.keys), active: \(customerInfo.entitlements.active.keys)")
                            let isUnlocked = ThemeManager.premiumActive(from: customerInfo)
                            themeManager.isPremiumUnlocked = isUnlocked
                            
                            if isUnlocked {
                                showingPaywall = false
                                // If unlocked, apply pending theme
                                if let pending = pendingThemeSelection {
                                    themeManager.selectTheme(pending)
                                    pendingThemeSelection = nil
                                    showThemeChangedToast = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            showThemeChangedToast = false
                                        }
                                    }
                                }
                            }
                        }
                        .onRestoreCompleted { customerInfo in
                            print("RC restore entitlements - all: \(customerInfo.entitlements.all.keys), active: \(customerInfo.entitlements.active.keys)")
                            let isUnlocked = ThemeManager.premiumActive(from: customerInfo)
                            themeManager.isPremiumUnlocked = isUnlocked
                            
                            if isUnlocked {
                                showingPaywall = false
                                // If unlocked, apply pending theme
                                if let pending = pendingThemeSelection {
                                    themeManager.selectTheme(pending)
                                    pendingThemeSelection = nil
                                    showThemeChangedToast = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            showThemeChangedToast = false
                                        }
                                    }
                                }
                            }
                        }
                        .onDisappear {
                            // Refresh entitlements after paywall closes, then apply if unlocked
                            themeManager.refreshEntitlements {
                                if themeManager.isPremiumUnlocked, let pending = pendingThemeSelection {
                                    themeManager.selectTheme(pending)
                                    pendingThemeSelection = nil
                                    showThemeChangedToast = true
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.6) {
                                        withAnimation(.easeOut(duration: 0.25)) {
                                            showThemeChangedToast = false
                                        }
                                    }
                                }
                            }
                        }
                }
            } else {
                Text("Loading...")
                    .onAppear { fetchOfferingsIfNeeded() }
            }
        }
        .sheet(isPresented: $showingPrivacy) {
            VStack(spacing: 20) {
                Text("Privacy Policy")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()

                Image(systemName: "hand.raised.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.accentColor)

                Text(
                    "MoodMusic does not collect, store, or share any personal data. All song suggestions are processed through third-party APIs without any form of user tracking."
                )
                .multilineTextAlignment(.center)
                .padding()

                Button(action: {
                    showingPrivacy = false
                }) {

                    Text("Close")
                        .font(.system(size: 20))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.primary)
                        .cornerRadius(20)
                }

                Spacer()
            }
            .padding()
        }
        .alert("Paywall unavailable", isPresented: Binding(get: { paywallError != nil }, set: { _ in paywallError = nil })) {
            Button("OK", role: .cancel) { paywallError = nil }
        } message: {
            Text(paywallError ?? "Something went wrong. Please try again.")
        }
    }
    
}

// MARK: - Helpers
extension SettingsView {
    private func handleThemeTap(_ theme: AppTheme) {
        themeManager.trySelectTheme(theme) { unlocked in
            if unlocked {
                let generator = UIImpactFeedbackGenerator(style: .light)
                generator.impactOccurred()
            } else {
                pendingThemeSelection = theme
                showingPaywall = true
                if currentOffering == nil {
                    fetchOfferingsIfNeeded()
                }
            }
        }
    }
    
    private func fetchOfferingsIfNeeded() {
        guard !isFetchingOffering else { return }
        isFetchingOffering = true
        Purchases.shared.getOfferings { offerings, error in
            DispatchQueue.main.async {
                isFetchingOffering = false
                if let offering = offerings?.current {
                    if offering.availablePackages.isEmpty {
                        currentOffering = nil
                        paywallError = "No purchase options available right now. Please try again later."
                        showingPaywall = false
                    } else {
                        currentOffering = offering
                    }
                } else if let error = error {
                    paywallError = error.localizedDescription
                } else {
                    paywallError = "Unable to load paywall right now."
                }
            }
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
}
