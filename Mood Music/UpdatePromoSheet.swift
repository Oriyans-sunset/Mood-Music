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
        VStack(alignment: .leading, spacing: 16) {
            HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Spotify integration is now live 🎉")
                        .font(.system(size: 22, weight: .bold, design: .rounded))
                        .foregroundColor(.primary)
                    Text("""
                    Navigate to settings to choose between Apple Music or Spotify as your music provider of choice.
                    """)
                        .font(.callout)
                        .foregroundColor(.secondary)
                }
                Spacer()
                Button(action: { onClose() }) {
                    Image(systemName: "xmark.circle.fill")
                        .font(.title2)
                        .foregroundColor(.secondary)
                }
                .accessibilityLabel("Close update notes")
            }

            Divider()

            VStack(alignment: .leading, spacing: 8) {
                Text("Try my new app: TagTrail📍")
                    .font(.system(size: 18, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                Text("Pin quick notes to places and get reminded when you’re nearby. Great for errands, campus life, and ‘don’t forget this’ moments.")
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
    }
}
