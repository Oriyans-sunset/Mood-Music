//
//  NotificationManager.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-08-22.
//

import Foundation
import UserNotifications

class NotificationManager {
    static let shared = NotificationManager()
    
    private init() {}

    func requestPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if let error = error {
                print("Notification permission error: \(error)")
            } else {
                print("Notifications permission granted: \(granted)")
            }
        }
    }

    func scheduleDailyReminder(at time: Date) {
        let content = UNMutableNotificationContent()
        content.title = "Time to check in 🎵"
        content.body = "Log your mood and get your daily song suggestion!"
        content.sound = UNNotificationSound.default

        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: time)
        dateComponents.second = 0

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(identifier: "dailyMoodReminder", content: content, trigger: trigger)

        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyMoodReminder"])
        UNUserNotificationCenter.current().add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error)")
            }
        }
    }

    func cancelReminders() {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: ["dailyMoodReminder"])
    }
}
