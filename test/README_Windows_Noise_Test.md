# 🖥️ Windows Noise Injection Test App

## Overview
This is a standalone Windows desktop application that demonstrates the EdgeSync noise injection system with a visual before/after comparison interface.

## Features

### 🎯 **Core Functionality**
- **Image Selection**: Pick any image file (JPG, PNG, BMP) from your computer
- **Real-time Processing**: Apply noise injection with live parameter adjustment
- **Side-by-Side Comparison**: See original and noised images simultaneously
- **Parameter Control**: Adjust all noise parameters with sliders
- **AI Toggle**: Switch between AI ensemble prediction and manual parameters
- **Save Results**: Export the processed image to your preferred location

### 🎛️ **Interactive Controls**
- **Amplitude Factor** (0.0 - 1.0): Controls noise strength
- **Frequency Factor** (0.0 - 1.0): Affects noise frequency patterns
- **Phase Factor** (0.0 - 1.0): Modulates phase relationships
- **Spatial Factor** (0.0 - 1.0): Spatial distribution of noise
- **Temporal Factor** (0.0 - 1.0): Temporal characteristics
- **Blend Factor** (0.0 - 1.0): How noise blends with original
- **Use AI Ensemble**: Toggle between AI prediction and manual control

## How to Run

### **Prerequisites**
- Windows 10/11
- Flutter SDK with Windows desktop support enabled
- EdgeSync project with noise injection integrated

### **Launch Command**
```bash
# From EdgeSync project root directory
flutter run -d windows test/noise_injection_test_windows.dart
```

### **Alternative Launch**
```bash
# If you have multiple Windows devices
flutter devices  # List available devices
flutter run -d [windows-device-id] test/noise_injection_test_windows.dart
```

## Usage Instructions

### **Step 1: Initialize**
- App launches with "Initializing..." status
- Wait for green "Ready!" status before proceeding
- If initialization fails, check console for ML model loading issues

### **Step 2: Load Image**
1. Click **"Select Image"** button
2. Choose an image file from your computer
3. Image appears in the left panel (Original Image)
4. Status shows: "Image loaded: [filename]"

### **Step 3: Configure Parameters**
- **For AI Mode**: Leave "Use AI Ensemble" enabled (recommended)
- **For Manual Mode**: Disable AI toggle and adjust sliders manually
- **Real-time Preview**: Changes apply when you click "Apply Noise"

### **Step 4: Apply Noise Injection**
1. Click **"Apply Noise"** button
2. Watch "Processing..." status with spinner
3. Processed image appears in right panel (Noised Image)
4. Status shows processing time (typically 1-2 seconds)

### **Step 5: Save Results**
1. Click **"Save Result"** button
2. Choose output location and filename
3. Image saved as high-quality JPG

## Interface Layout

```
┌─────────────────────────────────────────────────────────────┐
│                    EdgeSync Noise Injection Test            │
├─────────────────────────────────────────────────────────────┤
│ [Status Bar: Ready/Processing/Error messages]               │
├─────────────────────────────────────────────────────────────┤
│ [Select Image] [Apply Noise] [Save Result]                  │
├─────────────────────────────────────────────────────────────┤
│ Parameter Controls:                      Use AI Ensemble: ☑ │
│ Amplitude: ████████░░ 0.50  Spatial:  ████████░░ 0.60      │
│ Frequency: ██████░░░░ 0.30  Temporal: ████░░░░░░ 0.20      │
│ Phase:     ████████░░ 0.40  Blend:    ████████████ 0.80    │
├─────────────────────────────────────────────────────────────┤
│ ┌─────────────────┐    ┌─────────────────┐                  │
│ │   Original      │    │   Noised        │                  │
│ │   Image         │    │   Image         │                  │
│ │                 │    │                 │                  │
│ │                 │    │                 │                  │
│ │                 │    │                 │                  │
│ └─────────────────┘    └─────────────────┘                  │
└─────────────────────────────────────────────────────────────┘
```

## Testing Scenarios

### **Basic Test**
1. Load a simple photo (portrait, landscape, etc.)
2. Use AI ensemble mode (default settings)
3. Apply noise and observe subtle enhancement

### **Parameter Exploration**
1. Load the same image multiple times
2. Try different parameter combinations:
   - High amplitude (0.8+) for stronger effects
   - Low frequency (0.1-0.3) for smoother patterns
   - Various blend factors (0.5-1.0) for different intensities

### **Performance Test**
1. Load large images (>2MB)
2. Measure processing time
3. Verify memory usage remains stable

### **Format Compatibility**
- Test with JPG, PNG, BMP files
- Try different resolutions (small thumbnails to high-res photos)
- Verify output quality

## Troubleshooting

### **"Failed to initialize" Error**
- Check that ML model files are present in `assets/models/`
- Ensure TensorFlow Lite models are properly copied
- Verify Windows has proper graphics drivers

### **"Error picking image" Message**
- Try different image formats
- Check file permissions
- Ensure image file is not corrupted

### **Slow Processing**
- Large images take longer (normal behavior)
- Disable AI ensemble for faster processing
- Close other applications to free memory

### **Save Errors**
- Check destination folder permissions
- Ensure sufficient disk space
- Try different output locations

## Technical Notes

### **Performance Characteristics**
- **Initialization**: ~1-3 seconds (loads ML models)
- **Image Loading**: Instant (memory-based)
- **AI Prediction**: ~200-500ms
- **Noise Processing**: ~500-2000ms (depends on image size)
- **Total Time**: Usually under 3 seconds

### **Memory Usage**
- Base app: ~50-100MB
- ML models: ~20-50MB
- Image processing: Variable (depends on image size)
- Typical total: <200MB for standard photos

### **File Support**
- **Input**: JPG, JPEG, PNG, BMP
- **Output**: High-quality JPG
- **Max size**: Limited by available RAM
- **Recommended**: <10MB images for optimal performance

---

## 🎯 Perfect for Testing!

This Windows app provides the ideal environment for:
- **Testing noise injection parameters**
- **Comparing results visually**
- **Demonstrating capabilities to others**
- **Batch processing workflows**
- **Quality assurance verification**

Launch it and start experimenting with AI-powered image enhancement! 🚀
