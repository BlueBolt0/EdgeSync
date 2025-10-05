# EdgeSync AI: Intelligent Camera Application

## Team Details

### Team Name - BlueBlot
- **Member 1**: Shashank Padanad
- **Member 2**: Ishan Chitkarsh
- **Member 3**: Himanshu Ranjan
- **Member 4**: Prafull Anand

## Submissions

### Demonstration Materials
- **Video Presentation**: [Insert Video Link Here] - Complete feature walkthrough
- **PowerPoint Presentation**: [Insert PPT Link Here] - 
- **Documentation (DOCX)**: [Insert DOCX Link Here] - Detailed technical documentation

## Overview

EdgeSync is an innovative Flutter-based camera application that leverages on-device AI and machine learning to deliver advanced features beyond standard photography. It combines real-time sensing, privacy-preserving transformations, and natural user interactions to create an intelligent camera experience optimized for modern mobile devices.

The application features privacy mode with AI-driven noise injection, automatic smile capture for hands-free group photos, voice-activated controls, and harmonizer for content-aware assistance. Built with performance in mind, EdgeSync adapts to device capabilities through dynamic benchmarking and resource management.


## Key Features

###  Privacy Mode (Noise Injection)
- **AI-Powered Protection**: Uses TensorFlow Lite models to generate adaptive noise that preserves visual content while reducing automated analysis effectiveness
- **On-Device Processing**: All transformations occur locally without requiring internet connectivity
- **Fallback Mechanism**: Graceful degradation to default parameters if model inference fails
- **Gallery Integration**: Processed images are automatically saved to device gallery
<div align="center">
    <img src="https://ibb.co/rGBVGg0K" alt="Privacy Mode Demo" style="width:60%; max-width:400px; border-radius:10px; box-shadow:0 2px 6px rgba(0,0,0,0.3); margin-top:12px;">
    <p><em>Figure: Privacy Mode in action — adaptive noise applied to protect sensitive regions.</em></p>
</div>
### Harmonizer Service
- **Content Analysis**: OCR and entity recognition to extract dates, contacts, and tasks from images
- **Actionable Suggestions**: Generates calendar events, reminders, and contact additions
- **Cloud Assistance**: Optional Groq API integration for enhanced contextual understanding
- **User Consent**: All actions require explicit confirmation before execution

### Smile Capture
- **Automatic Detection**: Real-time face detection using Google ML Kit to identify smiling faces
- **Majority Voting**: Triggers capture when majority of visible faces are smiling
- **Countdown Timer**: 3-second validation period prevents spurious captures
- **Hands-Free Photography**: Ideal for group photos and self-portraits

### Voice Commands
- **Natural Interaction**: Speech-to-text recognition for hands-free camera control
- **Supported Commands**: "take picture", "start video", "stop video", "switch camera", "toggle flash", "toggle harmonizer"
- **Privacy-First**: On-device processing with optional cloud transcription opt-out
- **Debounced Execution**: Prevents accidental repeated commands



## Technology Stack

### Core Framework
- **Flutter**: Cross-platform UI framework for iOS and Android
- **Dart**: Programming language with strong typing and async support

### AI & ML
- **TensorFlow Lite**: On-device machine learning for noise injection
- **Google ML Kit**: Face detection, text recognition, and commons
- **TFLite Flutter**: Dart bindings for TensorFlow Lite

### Media & Camera
- **Camera Plugin**: Native camera access and controls
- **Video Player**: In-app video playback
- **Image Processing**: Advanced image manipulation library
- **GAL**: Gallery access for media saving

### Utilities
- **Speech-to-Text**: Voice command recognition
- **Permission Handler**: Runtime permission management
- **Shared Preferences**: Local data persistence
- **URL Launcher**: External app integration (calendar, contacts)
- **HTTP**: API communication for cloud features

## Installation & Setup

### Prerequisites
- Flutter SDK (version 3.9.0 or higher)
- Android Studio or Xcode (with Android SDK/iOS SDK)
- Physical Android/iOS device with camera
- Git for repository cloning

### Installation Steps

1. **Clone Repository**
   ```bash
   git clone https://github.com/BlueBolt0/EdgeSync.git
   cd EdgeSync
   ```

2. **Project Location**
   > **Important**: Move the project to a path without spaces (e.g., `C:\dev\EdgeSync`) to avoid Gradle build issues on Windows.

3. **Clean Project**
   ```bash
   flutter clean
   ```

4. **Install Dependencies**
   ```bash
   flutter pub get
   ```

5. **Configure API Key**
   - Obtain Groq API key from [https://console.groq.com/keys](https://console.groq.com/keys)
   - Enter the key when prompted during Harmonizer usage

6. **Run Application**
   ```bash
   flutter run
   ```

### Python Environment (Optional)
Required only for running test scripts in `test/` directory:
```bash
pip install -r requirements.txt
```


## Project Structure

```
lib/
├── main.dart                   # Application entry point
├── camera_app.dart             # Main camera interface and logic
├── camera_app2.dart            # Alternative camera implementation
├── main_new.dart               # Updated entry point
├── main_old.dart               # Legacy entry point
├── ml/                         # Machine learning utilities
├── noise_injection/            # Privacy mode implementation
├── screens/                    # UI screens
│   ├── gallery_screen.dart
│   └── harmonizer_settings_screen.dart
├── services/                   # Business logic services
│   ├── harmonizer_service.dart
│   └── voice_command_service.dart
├── smile_detection/            # Smile capture functionality
└── widgets/                    # Reusable UI components
    ├── harmonizer_dialog.dart
    └── ui_components.dart

assets/
├── icons/                      # App icons and assets
├── models/                     # TFLite model files
└── demoImg1.jpg, demoImg2.jpg  # Demo images

test/                           # Test suites and validation scripts
docs/                           # Documentation files
android/, ios/, windows/, etc.  # Platform-specific code
```
















---
