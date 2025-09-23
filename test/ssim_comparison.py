#!/usr/bin/env python3
"""
SSIM (Structural Similarity Index Measure) Comparison Tool for EdgeSync Noise Injection

This script compares the structural similarity between original and AI-poisoned images
to verify that the noise injection is working correctly while maintaining imperceptibility.

Purpose:
- Validate that noise injection actually modifies the image (SSIM < 1.0)
- Ensure modifications are imperceptible to humans (SSIM > 0.95 typically)
- Provide quantitative evidence that AI poisoning is effective but subtle

Expected SSIM Values:
-1.0: Identical images no noise introduced
-0.99-0.90: may not provide enough noise for effective AI poisoning
0.8-0.87: Effective range against AI poisoning

Usage:
1. Place original image as 'input.jpg' in the test folder
2. Generate noised version using EdgeSync app (saves as 'input_noisy.jpg')
3. Run: python test/ssim_comparison.py

Dependencies:
- opencv-python: pip install opencv-python
- scikit-image: pip install scikit-image
- numpy: pip install numpy
"""

import cv2
import numpy as np
from skimage.metrics import structural_similarity as ssim
import os
import sys

# Get the directory where this script is located (test folder)
BASE_DIR = os.path.dirname(os.path.abspath(__file__))

def load_img(filename):
    """
    Load an image from the test directory and convert to RGB format.
    
    Args:
        filename (str): Name of the image file (e.g., 'input.jpg')
        
    Returns:
        numpy.ndarray: RGB image array
        
    Raises:
        FileNotFoundError: If the image file doesn't exist
    """
    path = os.path.join(BASE_DIR, filename)
    img = cv2.imread(path)
    if img is None:
        raise FileNotFoundError(f"Image not found: {path}")
    # Convert from BGR (OpenCV default) to RGB for proper color representation
    return cv2.cvtColor(img, cv2.COLOR_BGR2RGB)

def compare_images(original, noisy):
    """
    Compare two images using SSIM and provide interpretation of results.
    
    Args:
        original (numpy.ndarray): Original image array
        noisy (numpy.ndarray): AI-poisoned image array
        
    The SSIM metric measures structural similarity between images:
    - Uses luminance, contrast, and structure comparisons
    - Values closer to 1.0 indicate higher similarity
    - For AI poisoning, we want high SSIM (imperceptible) but not 1.0 (unchanged)
    """
    # Calculate SSIM with proper parameters for color images
    # channel_axis=2 indicates color channels are in the last dimension
    # data_range=255 specifies the range of pixel values (0-255 for uint8)
    ssim_value = ssim(original, noisy, channel_axis=2, data_range=255)
    
    print(f"SSIM (AI-Poisoned vs Original): {ssim_value:.6f}")
    print(f"Difference: {(1.0 - ssim_value) * 100:.4f}%")
    
    # Provide interpretation of the SSIM value
    if ssim_value == 1.0:
        print("⚠️  WARNING: Images are identical - noise injection may have failed!")
    elif ssim_value >= 0.99:
        print("✅ EXCELLENT: Noise is imperceptible to humans but present for AI poisoning")
    elif ssim_value >= 0.95:
        print("✅ GOOD: Noise is subtle and effective for AI poisoning")
    elif ssim_value >= 0.90:
        print("⚠️  ACCEPTABLE: Noise may be slightly visible but still effective")
    else:
        print("❌ WARNING: Noise is too strong and may be easily detectable")
    
    # Additional statistics
    print(f"\nImage dimensions: {original.shape}")
    print(f"Pixel value range - Original: [{original.min()}, {original.max()}]")
    print(f"Pixel value range - Noisy: [{noisy.min()}, {noisy.max()}]")
    
    # Calculate mean absolute difference
    mad = np.mean(np.abs(original.astype(float) - noisy.astype(float)))
    print(f"Mean Absolute Difference: {mad:.4f} (lower is more imperceptible)")

def main():
    """
    Main function to run SSIM comparison between original and AI-poisoned images.
    
    This validates that EdgeSync's noise injection is working correctly:
    1. Confirms that noise was actually added (SSIM < 1.0)
    2. Verifies that noise is imperceptible (SSIM > 0.95)
    3. Provides quantitative evidence of AI poisoning effectiveness
    """
    try:
        print("EdgeSync AI Poisoning - SSIM Validation Tool")
        print("=" * 50)
        print("Loading images from test directory...")
        
        # Load the original and AI-poisoned images
        original = load_img("input.jpg")
        noisy = load_img("input_noisy.jpg")
        
        print(f"✅ Successfully loaded images")
        print(f"Original image: input.jpg")
        print(f"AI-poisoned image: input_noisy.jpg")
        print()
        
        # Perform the SSIM comparison
        compare_images(original, noisy)
        
        print("\n" + "=" * 50)
        print("Analysis complete. Use these results to validate your AI poisoning implementation.")
        
    except FileNotFoundError as e:
        print(f"❌ Error: {e}")
        print("\nTo use this tool:")
        print("1. Place your original image as 'input.jpg' in the test folder")
        print("2. Generate the AI-poisoned version using EdgeSync app")
        print("3. Save the poisoned image as 'input_noisy.jpg' in the test folder")
        print("4. Run this script again")
        sys.exit(1)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        sys.exit(1)

if __name__ == "__main__":
    main()
