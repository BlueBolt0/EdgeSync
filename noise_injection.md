# EdgeSync Noise Injection System

## Overview
This document explains the noise injection technique implemented in EdgeSync, referencing key research papers and detailing how the system works for AI poisoning (adversarial attacks).

---

## 1. Background & Motivation

Modern AI models, especially in computer vision, are vulnerable to adversarial attacks—small, carefully crafted perturbations to input images that cause models to make incorrect predictions while remaining imperceptible to humans. EdgeSync leverages this by injecting noise that is:
- **Imperceptible to humans**
- **Highly effective at fooling AI models**
- **Parameterizable and adaptive**

---

## 2. Key Techniques & References

### a. Frequency Domain Attacks
- **Reference:** Zhou et al., "Adversarial Attacks in the Frequency Domain" ([arXiv:1801.01944](https://arxiv.org/abs/1801.01944))
- **Summary:** Attacks in the frequency domain (using sine/cosine, phase, amplitude) are more effective and less perceptible than pixel-domain noise. By targeting specific frequency bands, adversarial noise can be made robust and hard to detect visually.
- **Our Implementation:**
  - We convert images to Lab color space and operate on the L (brightness) channel.
  - Noise is injected in the frequency domain using parameterized sine/cosine patterns, phase shifts, and spatial blending.

### b. Ensemble Adversarial Training
- **Reference:** Tramèr et al., "Ensemble Adversarial Training: Attacks and Defenses" ([arXiv:1705.07204](https://arxiv.org/abs/1705.07204))
- **Summary:** Using an ensemble of models to generate adversarial examples increases the transferability and robustness of attacks. It makes the noise more likely to fool a wide range of AI models.
- **Our Implementation:**
  - We use a 3-model TensorFlow Lite ensemble to predict optimal noise parameters for each image.
  - The ensemble's outputs (amplitude, frequency, phase, etc.) are used to control the noise injection process.

### c. Imperceptible and Robust Attacks
- **Reference:** Goodfellow et al., "Explaining and Harnessing Adversarial Examples" ([arXiv:1412.6572](https://arxiv.org/abs/1412.6572))
- **Summary:** Adversarial noise can be made highly effective with minimal visual impact by optimizing perturbations in a way that exploits model weaknesses while remaining below human perceptual thresholds.
- **Our Implementation:**
  - The noise is blended with the original image using a blend factor, ensuring the result is visually indistinguishable from the original.
  - The attack is adaptive: parameters are chosen per-image, not fixed.

---

## 3. Implementation Details

- **Lab Color Space:**
  - We convert images to Lab color space to separate luminance (L) from color (a, b), allowing more natural-looking perturbations.
- **Frequency-Domain Noise:**
  - Noise is generated using sine/cosine functions, phase, amplitude, and spatial weighting.
  - Parameters are predicted by the ensemble models or simulated if models are unavailable.
- **Adaptive Parameters:**
  - Amplitude, frequency, phase, spatial, temporal, and blend factors are all tunable and can be predicted per-image.
- **Reconstruction:**
  - The noised L channel is merged back with the original a/b channels and converted to RGB for saving/display.

---

## 4. Why This Is Effective

- **Transferability:** Ensemble-generated noise is more likely to fool a variety of models, not just one.
- **Imperceptibility:** Frequency-domain and Lab-space perturbations are hard for humans to notice.
- **Robustness:** Adaptive, per-image parameters make the attack more effective and less likely to be filtered out by simple defenses.

---

## 5. References
- Zhou et al., "Adversarial Attacks in the Frequency Domain" ([arXiv:1801.01944](https://arxiv.org/abs/1801.01944))
- Tramèr et al., "Ensemble Adversarial Training: Attacks and Defenses" ([arXiv:1705.07204](https://arxiv.org/abs/1705.07204))
- Goodfellow et al., "Explaining and Harnessing Adversarial Examples" ([arXiv:1412.6572](https://arxiv.org/abs/1412.6572))

---

## 6. Summary
EdgeSync’s noise injection system is based on state-of-the-art adversarial attack research, using frequency-domain, model-driven, and ensemble-based techniques to create robust, imperceptible, and highly effective AI poisoning attacks.
