# Privacy Policy

> This policy is also available at https://kvesen.github.io/PokerHandSuggester/

**Last updated: 2026**

This Privacy Policy describes how the Poker Hand Suggester app ("the App") handles information.

## Camera Usage

The App uses your device's camera to scan playing cards. All image processing is performed **entirely on-device** using a TensorFlow Lite (TFLite) object detection model. No images or camera data are ever uploaded, transmitted, or stored beyond the immediate analysis session.

## On-Device Processing

All card recognition and poker hand calculations are performed locally on your device. The App does not communicate with any external servers or APIs during normal operation.

## Data Collection

**The App collects no personal data.** Specifically:

- No account registration or login is required
- No personally identifiable information (PII) is collected
- No location data is accessed or stored
- No device identifiers are collected or transmitted

## Local Storage

Hand history is stored **locally on your device only** using Hive (device-local database storage). Theme preferences are stored using SharedPreferences. This data never leaves your device and can be cleared at any time by uninstalling the app or clearing app data.

## Analytics and Tracking

The App currently includes **no analytics, tracking, or advertising** of any kind. No usage data is collected or transmitted.

## Third-Party Services

The App uses the following on-device libraries:

- **TensorFlow Lite (via tflite_flutter)** — Runs an object detection model entirely on-device for playing card recognition. No data is sent to any external server. See <a href="https://policies.google.com/privacy">TensorFlow's Privacy Policy</a> for general information.
- **Hive** — Local on-device database for hand history persistence. All data stays on your device.

## Data Sharing

We do not share, sell, rent, or trade any user data with third parties because we do not collect any user data.

## Children's Privacy

The App does not knowingly collect any information from children under 13.

## Changes to This Policy

If we make material changes to this Privacy Policy, we will update the "Last updated" date above and post the revised policy in this repository.

## Contact

If you have questions about this Privacy Policy, please open an issue on the GitHub repository:
[https://github.com/kvesen/PokerHandSuggester](https://github.com/kvesen/PokerHandSuggester)
