# Mood Jar 🫙

Mood Jar is a modern, intuitive Flutter application designed to help you track your emotional well-being. Log your daily moods, reflect on your feelings, and gain valuable insights into your emotional patterns with the help of AI.

## ✨ Features

*   **Mood Tracking**: Easily log your daily mood with a beautiful, interactive interface. Choose from a variety of emotions like Happy, Sad, Tired, Anxious, and more.
*   **Journaling**: Add notes to your mood logs to capture the "why" behind your feelings.
*   **History & Calendar**: View your mood history on a calendar to visualize your emotional journey over time.
*   **AI Insights**: Get personalized daily wisdom and deep insights into your specific mood entries powered by Gemini AI.
*   **Weekly Overview**: Visualize your mood trends with interactive charts and statistics.
*   **Wellness Tips**: Swipe through daily wellness tips categorized by Mindfulness, Health, Activity, and more.
*   **Secure & Private**: Your data is yours. Optional App Lock with biometric authentication ensures your journal remains private.
*   **Customizable**: Toggle between Light and Dark modes to suit your preference.

## 📱 Screenshots

| Home Screen | Log Mood | History | Insights |
|:---:|:---:|:---:|:---:|
| ![Home Screen](screenshots/home.png) | ![Log Mood](screenshots/log_mood.png) | ![History](screenshots/history.png) | ![Insights](screenshots/insights.png) |

*(Screenshots coming soon)*

## 🛠️ Tech Stack

*   **Framework**: Flutter
*   **Language**: Dart
*   **Backend**: Firebase (Auth, Firestore)
*   **AI**: Google Gemini API
*   **State Management**: Flutter Bloc / Cubit
*   **Local Storage**: Shared Preferences
*   **Charts**: FL Chart

## 🚀 Getting Started

### Prerequisites

*   Flutter SDK installed
*   Firebase project set up
*   Gemini API Key

### Installation

1.  **Clone the repository:**
    ```bash
    git clone https://github.com/yourusername/mood-jar.git
    cd mood-jar
    ```

2.  **Install dependencies:**
    ```bash
    flutter pub get
    ```

3.  **Configure Firebase:**
    *   **Important**: This project requires `firebase_options.dart` which is git-ignored for security.
    *   Install the FlutterFire CLI:
        ```bash
        dart pub global activate flutterfire_cli
        ```
    *   Run the configuration command in the project root:
        ```bash
        flutterfire configure
        ```
    *   Follow the prompts to select your Firebase project and platforms. This will automatically generate the `lib/firebase_options.dart` file.
    *   Alternatively, you can manually place your `google-services.json` (Android) and `GoogleService-Info.plist` (iOS) in the respective directories, but generating `firebase_options.dart` is recommended.

4.  **Configure Gemini API:**
    *   Get an API key from Google AI Studio.
    *   Add your API key to your project configuration (e.g., in a `.env` file or directly in the repository class if testing locally).

5.  **Run the app:**
    ```bash
    flutter run
    ```

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.
