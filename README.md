# 🎵 MoodMusic

MoodMusic is a beautifully simple iOS app that recommends songs based on how you're feeling. Tap your mood, get a vibe — it’s that easy.

![screenshot](Assets/screenshot.png) <!-- Replace with your actual screenshot path -->

---

## ✨ Features

- 🎧 Mood-based song suggestions
- 💡 Uses OpenAI to generate unique music recommendations
- 🎨 Colorful mood selector with emoji interface
- 🗓️ Mood calendar to track your week
- 🖼️ Song cards with cover art & Apple Music link
- ⚙️ Settings page with app info, privacy, and support

---

## 📱 Screenshots

| Mood Selector | Song Card | Calendar View |
|---------------|-----------|----------------|
| *(Insert image)* | *(Insert image)* | *(Insert image)* |

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

MoodMusic does **not** collect, store, or track any personal user data. All mood and song suggestions are processed locally or via third-party APIs.

---

## 🧪 TestFlight

Once beta testing begins, you’ll be able to try **Mood Music** via [TestFlight](https://testflight.apple.com/join/your-link-here).  
_(Link will be available after TestFlight setup.)_

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
