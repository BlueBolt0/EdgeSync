# EdgeSync: An Intelligent Camera Application

## 1. Project Overview

EdgeSync is a feature-rich, intelligent camera application built with Flutter. It goes beyond standard camera functionality by integrating on-device AI to provide smart features like automatic smile detection, voice-activated controls, and a unique privacy-preserving noise injection system. The application is designed to be performant on a wide range of devices through its adaptive performance-tuning capabilities.

## 2. Technical Features & Implementation

This section details the advanced, technically-driven features of the EdgeSync application.

### 🔒 Privacy Mode (Noise Injection)

- **Concept**: This mode applies a layer of AI-generated noise to an image, preserving privacy while maintaining the general structure of the photo.
- **Implementation**: It uses a TFLite model to predict noise parameters for the injection process.
- **Current Status (Important)**: The TFLite model inference is currently **commented out** in `lib/noise_injection/android_noise_injector.dart`. This is a temporary workaround to prevent a native `SIGSEGV` crash. The system currently falls back to using default noise parameters.
- **Gallery Integration**: Images processed with Privacy Mode are saved directly to the public device gallery using the `gal` package to ensure they are immediately visible.

### 😊 Smile Capture

- **Automatic Photo Capture**: The app uses on-device face detection (`google_mlkit_face_detection`) to detect smiling faces in the camera's view.
- **Countdown Timer**: When a majority of detected faces are smiling, a 3-second countdown is automatically triggered, after which a photo is taken. This allows for hands-free group photos without a manual shutter press.

### 🎤 Voice Commands

- **Hands-Free Control**: A microphone button enables voice commands to control the camera, using the `speech_to_text` package for on-device recognition.
- **Functionality**: Users can execute commands like "take picture", "start video", "stop video", and "switch camera".
- **Implementation**: The voice command service listens for a command and then automatically turns off, preventing continuous listening.

### 🖼️ Dynamic & Animated Gallery

- **Dynamic Updates**: The gallery is not just a static view. When a new "privacy" image is generated, it is dynamically added to the gallery's `PageView` for immediate viewing.
- **Animated UI**: In the gallery, the Harmonizer and Privacy buttons are not always visible. They appear with a smooth fade and scale animation when the user taps on a photo, providing a clean and interactive UI.

### ✨ Harmonizer Service

- The Harmonizer is a feature designed to process images for aesthetic improvements. When enabled, it presents a dialog after a photo is captured to apply its effects, showcasing post-processing capabilities.

## 3. Performance Optimization

The application includes a robust system to ensure it runs smoothly on both old and new devices.

- **Automatic Detection**: On startup, the app runs a quick benchmark to determine if the device is "old" or "new".
- **Dynamic Processing Intervals**:
  - **Old Device Mode**: Uses a longer interval (1500ms) between face detection frames to reduce CPU load and prevent crashes.
  - **New Device Mode**: Uses a shorter interval (500ms) for more responsive detection.
- **Manual Toggle**: A "speed" icon in the UI allows the user to manually override the performance mode, with a SnackBar providing clear feedback.

## 4. Setup and Installation

### Prerequisites

- Flutter SDK
- Android Studio or Xcode
- A physical Android device with a camera

### Installation Steps

1.  **Clone the repository.**
    ```bash
    git clone https://github.com/BlueBolt0/EdgeSync.git
    cd EdgeSync
    ```
2.  **Install Flutter Dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the App**:
    ```bash
    flutter run
    ```
4.  **Get and enter groq api key** in the app when asked for it. Get api keys from https://console.groq.com/keys

## 5. Python Environment Setup (Optional)

This setup is **only required if you intend to run the Python-based test scripts** for testing and verifying features like the noise injection validation (e.g., `test/ssim_comparison.py`). It is not needed for running the main Flutter application.

1.  **Install Python** (if you haven't already).
2.  **Install the required packages** using the `requirements.txt` file:
    ```bash
    pip install -r requirements.txt
    ```

## 6. Project Structure

```
lib/
├── main.dart                   # App entry point
├── camera_app.dart             # Main camera UI and core logic
├──
├── screens/
│   ├── gallery_screen.dart     # Full-screen, swipeable media gallery
│   └── harmonizer_settings_screen.dart
├──
├── services/
│   ├── harmonizer_service.dart # Logic for the harmonizer feature
│   └── voice_command_service.dart  # Handles voice recognition
├──
├── noise_injection/
│   └── android_noise_injector.dart # Handles privacy noise injection
├──
└── widgets/
    ├── harmonizer_dialog.dart
    └── ui_components.dart      # Reusable UI widgets
```

## 7. Submissions

- **Video URL**: [Link to Video Demonstration]
