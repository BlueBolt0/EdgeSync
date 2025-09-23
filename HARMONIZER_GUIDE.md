# EdgeSync Camera App - Harmonizer Feature

## Overview

EdgeSync is a camera app with advanced smile detection and a powerful new **Harmonizer** feature that uses OCR + AI to extract actionable content from your photos.

## Features

### 🔹 Existing Features
- **Smile Detection**: Automatically captures photos when smiles are detected
- **Photo & Video Modes**: Full camera functionality
- **Performance Optimization**: Adaptive processing for different device capabilities

### 🆕 Harmonizer Feature
The Harmonizer feature uses OCR (Optical Character Recognition) combined with AI to analyze text in your photos and suggest relevant actions:

- **📅 Calendar Events**: Detects meetings, appointments, and deadlines
- **⏰ Reminders**: Identifies tasks and follow-ups to save
- **📞 Contacts**: Extracts contact information (names, phones, emails)
- **📝 Notes**: Saves important information and ideas

## How to Use the Harmonizer

### 1. Setup
1. Open the app and tap the **Settings** icon (gear) in the top toolbar
2. Navigate to the **Harmonizer Settings**
3. Enter your **Groq API Key** (get one free from [console.groq.com](https://console.groq.com))
4. Save the API key

### 2. Taking Photos with Harmonizer
1. In the camera view, tap the **Harmonizer** button in the bottom control panel
2. The button will turn teal when active
3. Take a photo normally (either manually or using smile detection)
4. The Harmonizer dialog will automatically appear after photo capture

### 3. Processing Results
The Harmonizer will:
1. **Extract text** from your photo using OCR
2. **Analyze content** using AI to identify actionable items
3. **Present suggestions** organized by category:
   - 📅 Calendar events to add
   - ⏰ Reminders to save
   - 📞 Contacts to store
   - 📝 Notes to keep

### 4. Taking Action
For each suggestion, tap the action button to:
- **Calendar**: Opens Google Calendar to create the event
- **Reminders**: Saves to app's reminder list
- **Contacts**: Adds to device contacts (requires permission)
- **Notes**: Saves to app's notes collection

## Use Cases

### Business Cards
- Capture business cards and automatically extract contact information
- One-tap to add contacts with names, phone numbers, emails, and companies

### Event Flyers
- Photo event posters and automatically detect dates, times, and details
- Quick calendar integration for meetings and events

### Whiteboards & Notes
- Capture meeting notes or brainstorming sessions
- Extract important action items and deadlines

### Documents
- Photo important documents and extract key information
- Save relevant details as organized notes

## Privacy & Security

- **Local Processing**: OCR is performed on-device
- **Secure API**: Only extracted text is sent to Groq AI service
- **Privacy Mode**: Use the Privacy button to disable all AI processing
- **Data Control**: Clear saved data anytime in settings

## Technical Details

### Dependencies
- **google_mlkit_text_recognition**: On-device OCR
- **http**: API communication with Groq
- **contacts_service**: Device contact integration
- **url_launcher**: Calendar and external app integration
- **shared_preferences**: Local data storage

### AI Model
- Uses **Llama 3 8B** model via Groq API for text analysis
- Optimized prompts for extracting actionable content
- JSON-structured responses for reliable parsing

### Performance
- **Adaptive processing**: Optimizes for device capabilities
- **Background processing**: OCR and AI analysis don't block UI
- **Efficient caching**: Minimizes API calls and processing overhead

## Getting Your Groq API Key

1. Visit [console.groq.com](https://console.groq.com)
2. Sign up for a free account
3. Navigate to API Keys section
4. Create a new API key
5. Copy and paste into the app settings

The free tier provides generous usage limits perfect for personal use.

## Troubleshooting

### "No text found in image"
- Ensure good lighting when taking photos
- Text should be clear and readable
- Try different angles or distances

### "API key not configured"
- Check that you've entered a valid Groq API key in settings
- Ensure you have internet connection for AI analysis

### Contacts permission required
- Allow contacts permission when prompted
- Check app permissions in device settings if needed

### Poor OCR results
- Use good lighting and stable camera position
- Ensure text is not too small or blurry
- Clean camera lens for better image quality

## Updates & Roadmap

Future enhancements planned:
- **Offline AI**: Local processing for complete privacy
- **Custom Categories**: User-defined action types
- **Smart Scheduling**: AI-powered optimal meeting times
- **Export Options**: PDF, CSV, and other format exports
- **Cloud Sync**: Cross-device synchronization

---

**Built with Flutter • Powered by Groq AI • Made with ❤️**
