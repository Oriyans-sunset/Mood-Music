# 🎵 MoodMusic

MoodMusic is a beautifully simple iOS app that recommends songs based on how you're feeling. Tap your mood, get a vibe — it’s that easy. 

[App Store Link](https://apps.apple.com/in/app/moodmusic-daily-check-in/id6745494875)📱

---

## ✨ Features

- 🎧 Mood-based song suggestions
- 💡 Uses OpenAI API for GPT-40-mini model to generate unique music recommendations
- 🎨 Colorful mood selector with emoji interface
- 🗓️ Mood calendar to track your week
- 🖼️ Song cards with cover art & Apple Music link
- ⚙️ Settings page with app info, privacy, and support

---

## 📱 Screenshots

| Mood Selector | Song Card |
|---------------|-----------|
| <img src="https://github.com/user-attachments/assets/2826ad28-97a0-417f-98e3-d0aeda84d902" width="200" alt="Screenshot 1 iPhone 15"> | <img src="https://github.com/user-attachments/assets/2bbf25e4-7b5a-4335-b274-2ebe0a96fb77" width="200" alt="Screenshot 2 iPhone 15"> |

---

## 🚀 Tech Stack

- **SwiftUI** – declarative UI framework
- **OpenAI API** – to generate song recommendations
- **iTunes Search API** – to fetch album art and track links
- **UserDefaults** – lightweight local storage
- **Custom JSON File** – to store user mood/song history offline

---

## 🔐 API Key Setup (Required!)

To clone and run MoodMusic locally, you **must provide your own OpenAI API key**. Without it, the app will not function.

### 🔧 How to set your key in Xcode:

1. Go to `Product > Scheme > Edit Scheme`
2. Under the `Run` section, open the **Arguments** tab
3. In the **Environment Variables** section, add:

Name: OPENAI_API_KEY

Value: sk-…your key here…

You can get your API key from [OpenAI’s dashboard](https://platform.openai.com/account/api-keys)

> ‼️**Important:** Never commit your API key to source control.

---

## 🔐 Privacy

MoodMusic does **not** collect, store, or track any personal user data. All mood and song suggestions are processed via third-party APIs without any form of user tracking.

---

## 🙌 Acknowledgements

- 🎨 Font: [Pacifico by Vernon Adams](https://fonts.google.com/specimen/Pacifico/about)
- 🎵 Music suggestions powered by [OpenAI](https://openai.com/)
- 🎧 Album art and links from [iTunes Search API](https://developer.apple.com/library/archive/documentation/AudioVideo/Conceptual/iTuneSearchAPI/)
- 🔧 Built entirely with [SwiftUI](https://developer.apple.com/xcode/swiftui/)

---

## 💬 Feedback & Support

If you encounter bugs or have suggestions:
- Email me directly → [ryzenlyve@gmail.com](mailto:ryzenlyve@gmail.com)

---

## 📄 License

This project is licensed under the **MIT License**.  
See [LICENSE](LICENSE) for details.
