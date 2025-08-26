//
//  SettingsView.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-05-02.
//

import SwiftUI
import UserNotifications

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
            
            Section(header: Text("Daily Mood Reminder")) {
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


            Section(header: Text("Check out my other app")) {
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
            
            Text("Shout out to my best friend for the design inspiration!💛")
                .font(.footnote)
                .foregroundColor(.gray)
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(1)

        }
        .onAppear {
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
    }
    
}

#Preview {
    SettingsView()
}
