//
//  UpdatePromoSheet.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-09-02.
//

import SwiftUI

struct UpdatePromoSheet: View {
    let tagTrailURL: URL?
    let onClose: () -> Void

    @Environment(\.openURL) private var openURL
    @Environment(\.colorScheme) private var colorScheme

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // MARK: - Header
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("What's New in MoodMusic")
                            .font(.system(size: 22, weight: .bold, design: .rounded))
                            .foregroundColor(.primary)
                        Text("This update brings new free features and introduces MoodMusic Extra.")
                            .font(.callout)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                    Button(action: { onClose() }) {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundColor(.secondary.opacity(0.8))
                    }
                    .accessibilityLabel("Close update notes")
                }

                // MARK: - Free Feature
                VStack(alignment: .leading, spacing: 12) {
                    Text("NEW FOR EVERYONE")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    FeatureView(
                        icon: "music.note.list",
                        color: .pink,
                        title: "Spotify Integration",
                        subtitle: "You can now choose Spotify as your preferred music provider in Settings."
                    )
                    FeatureView(
                        icon: "app.gift.fill",
                        color: .brown,
                        title: "Festive New Icon",
                        subtitle: "Happy holidays folks! The app has a new icon, a temporary festive look to celebrate the season."
                    )
                }
                .padding(.top, 8)

                // MARK: - Premium Features
                VStack(alignment: .leading, spacing: 12) {
                    Text("MOODMUSIC EXTRA ✨")
                        .font(.system(size: 12, weight: .bold, design: .rounded))
                        .foregroundColor(.secondary)
                    FeatureView(
                        icon: "paintbrush.fill",
                        color: .purple,
                        title: "Exclusive Themes",
                        subtitle: "Customize your app with a variety of new, beautiful gradients and calender styles."
                    )
                    FeatureView(
                        icon: "chart.bar.xaxis",
                        color: .blue,
                        title: "In-Depth Statistics",
                        subtitle: "Visualize your mood trends and history in the new Stats view."
                    )
                    FeatureView(
                        icon: "doc.text.fill",
                        color: .green,
                        title: "PDF Export",
                        subtitle: "Export your monthly mood calendar and song timeline as a keepsake."
                    )
                }
                .padding(.vertical, 8)

                Divider()

                // MARK: - TagTrail Promo (Unchanged)
                VStack(alignment: .leading, spacing: 8) {
                    Text("Try my new app: TagTrail📍")
                        .font(.system(size: 18, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("Pin quick notes to places and get reminded when you're nearby. Great for errands, campus life, and 'don't forget this' moments.")
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 12) {
                    Button(action: { onClose() }) {
                        Text("Nice!")
                            .fontWeight(.semibold)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 12)
                            .background(Color(UIColor.secondarySystemBackground))
                            .cornerRadius(12)
                    }

                    Button(action: {
                        if let url = tagTrailURL { openURL(url) }
                        onClose()
                    }) {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.up.right.square.fill")
                            Text("TagTrail")
                                .fontWeight(.semibold)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: colorScheme == .dark
                                    ? [Color.indigo.opacity(0.95), Color.blue.opacity(0.9)]
                                    : [Color.blue.opacity(0.95), Color.teal.opacity(0.9)]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .foregroundColor(.white)
                        .cornerRadius(12)
                    }
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 16)
            // Extra bottom padding to avoid clipping buttons in shorter detents
            .padding(.bottom, 12)
        }
    }
}

// MARK: - Helper View for Features
private struct FeatureView: View {
    let icon: String
    let color: Color
    let title: String
    let subtitle: String

    var body: some View {
        HStack(spacing: 14) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(color)
                .frame(width: 28, height: 28)
                .background(color.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 1) {
                Text(title)
                    .font(.system(size: 15, weight: .semibold))
                Text(subtitle)
                    .font(.system(size: 13))
                    .foregroundColor(.secondary)
            }
        }
    }
}

#Preview {
    UpdatePromoSheet(
        tagTrailURL: URL(string: "https://apple.com"),
        onClose: { print("Preview close tapped.") }
    )
}
