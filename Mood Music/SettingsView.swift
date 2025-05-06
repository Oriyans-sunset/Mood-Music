//
//  SettingsView.swift
//  Mood Music
//
//  Created by Priyanshu Rastogi on 2025-05-02.
//

import SwiftUI

struct SettingsView: View {
    @State private var showingPrivacy = false
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
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
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
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "N/A")
                        .foregroundColor(.gray)
                }
            }
            
            Section(header: Text("Powered By")) {
                Text("MoodMusic uses the OpenAI API for song recommendations.")
                Text("Song previews and album art are provided by the iTunes Search API.")
                Link("OpenAI Terms", destination: URL(string: "https://openai.com/policies/terms-of-use")!)
                Link("Apple Media Services Terms", destination: URL(string: "https://www.apple.com/legal/internet-services/itunes/dev/stdeula/")!)
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
                Link("Feedback", destination: URL(string: "mailto:ryzenlyve@gmail.com?subject=MoodMusic%20Feedback")!)
                
                Link("Acknowledgements", destination: URL(string: "https://fonts.google.com/specimen/Pacifico/about")!)
            }
        }
        .navigationTitle("Settings")
        .sheet(isPresented: $showingPrivacy) {
            VStack(spacing: 20) {
                Text("Privacy Policy")
                    .font(.title2)
                    .fontWeight(.bold)
                    .padding()
                
                Image(systemName: "hand.raised.circle.fill")
                    .font(.system(size: 100))
                    .foregroundColor(.accentColor)

                Text("MoodMusic does not collect, store, or share any personal data. All song suggestions are processed through third-party APIs without any form of user tracking.")
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
