<div align="center">

  <img src="assets/icon.png" alt="Mood Jar Logo" width="150" height="150">

# Mood Jar 🫙

**Your personal AI-powered emotional companion.**

[![Flutter](https://img.shields.io/badge/Flutter-%2302569B.svg?style=for-the-badge&logo=Flutter&logoColor=white)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/dart-%230175C2.svg?style=for-the-badge&logo=dart&logoColor=white)](https://dart.dev/)
[![Firebase](https://img.shields.io/badge/firebase-%23039BE5.svg?style=for-the-badge&logo=firebase)](https://firebase.google.com/)
[![Gemini AI](https://img.shields.io/badge/Google%20Gemini-8E75B2?style=for-the-badge&logo=google%20gemini&logoColor=white)](https://deepmind.google/technologies/gemini/)

  <p>
    <a href="#-features">Features</a> •
    <a href="#-screenshots">Screenshots</a> •
    <a href="#-tech-stack">Tech Stack</a> •
    <a href="#-getting-started">Getting Started</a> •
    <a href="#-contributing">Contributing</a>
  </p>
</div>

---

## 📖 About

**Mood Jar** is a modern, intuitive Flutter application designed to help you track your emotional well-being. Beyond
simple tracking, it helps you reflect on your feelings and gain valuable insights into your emotional patterns with the
help of AI.

Whether you are looking to identify triggers, practice mindfulness, or simply keep a record of your journey, Mood Jar
provides the tools you need in a secure, private environment.

## ✨ Features

| Feature                   | Description                                                                                                  |
|:--------------------------|:-------------------------------------------------------------------------------------------------------------|
| **🎨 Mood Tracking**      | Log daily moods with a beautiful, interactive interface. Select emotions like Happy, Sad, Anxious, and more. |
| **📝 Smart Journaling**   | Attach notes to your logs to capture the "why" behind your feelings.                                         |
| **🤖 AI Insights**        | Powered by **Google Gemini**, get personalized daily wisdom and deep analysis of your journal entries.       |
| **📅 History & Calendar** | visualize your emotional journey over time with an easy-to-read calendar view.                               |
| **📊 Weekly Overview**    | Interactive charts and statistics to help you spot trends in your well-being.                                |
| **🌿 Wellness Tips**      | Swipe through daily tips categorized by Mindfulness, Health, Activity, and Social.                           |
| **🔒 Secure & Private**   | Optional App Lock with **Biometric Authentication** ensures your thoughts remain yours alone.                |
| **🌗 Theming**            | Fully customizable Light and Dark modes.                                                                     |

## 📱 Screenshots

|                          Home Screen                           |                            Log Mood                             |                            History                            |                            Insights                             |
|:--------------------------------------------------------------:|:---------------------------------------------------------------:|:-------------------------------------------------------------:|:---------------------------------------------------------------:|
| <img src="screenshots/home.png" width="200" alt="Home Screen"> | <img src="screenshots/log_mood.png" width="200" alt="Log Mood"> | <img src="screenshots/history.png" width="200" alt="History"> | <img src="screenshots/insights.png" width="200" alt="Insights"> |

## 🛠️ Tech Stack

Mood Jar is built with a focus on scalability and clean architecture.

* **Framework:** [Flutter](https://flutter.dev)
* **Language:** [Dart](https://dart.dev)
* **State Management:** [Flutter Bloc](https://pub.dev/packages/flutter_bloc) / Cubit
* **Backend:** Firebase (Auth, Firestore)
* **Artificial Intelligence:** Google Gemini API
* **Local Storage:** Shared Preferences
* **Visualization:** [FL Chart](https://pub.dev/packages/fl_chart)

## 🚀 Getting Started

Follow these steps to get a local copy up and running.

### Prerequisites

* **Flutter SDK**: [Install Flutter](https://docs.flutter.dev/get-started/install)
* **Firebase Account**: [Create a project](https://console.firebase.google.com/)
* **Google AI Studio Key**: [Get API Key](https://aistudio.google.com/app/apikey)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/mood-jar.git
   cd mood-jar
   ```

2. **Install dependencies**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase**
    * *Note: `firebase_options.dart` is git-ignored for security.*
    * Install the FlutterFire CLI:
      ```bash
      dart pub global activate flutterfire_cli
      ```
    * Run the configuration command in the root directory:
      ```bash
      flutterfire configure
      ```

    * Follow the prompts to select your project and platforms (Android/iOS).

4. **Configure Gemini API**
    * Obtain your API Key from Google AI Studio.
    * Create a `.env` file in the root of your project (if using `flutter_dotenv`) or add it to your
      configuration
      class.
    * *Example `.env` format:*
      ```bash
      GEMINI_API_KEY=your_api_key_here
      ```

5. **Run the app**
   ```bash
   flutter run
   ```

## 📂 Project Structure

A quick look at the top-level directory structure:

```text
lib/
├── core/ # Shared resources (theme, constants, utils)
├── data/ # Data layer (repositories, data sources, models)
├── logic/ # Business logic (Blocs/Cubits)
├── presentation/ # UI Layer (Screens, Widgets)
│ ├── home/
│ ├── mood_logging/
│ ├── insights/
│ └── settings/
├── firebase_options.dart
└── main.dart

```

## 🤝 Contributing

Contributions are what make the open-source community such an amazing place to learn, inspire, and create. Any
contributions you make are **greatly appreciated**.

1. Fork the Project
2. Create your Feature Branch (`git checkout -b feature/AmazingFeature`)
3. Commit your Changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the Branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

<div align="center">
  <small>Made with ❤️ and Flutter</small>
</div>