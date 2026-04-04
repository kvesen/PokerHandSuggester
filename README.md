# Poker Hand Suggester 🃏

A Flutter mobile app (Android & iOS) that calculates the **mathematically optimal poker decision** — Fold, Call, or Raise — based on the current game state.

## Features

### Phase 1 — Poker Math Engine & Manual Input
- ♠️ **Full Texas Hold'em support** — preflop through river
- 🃏 **Interactive card selector** — tap to select hole cards and community cards from a visual 52-card grid
- 🧮 **Monte Carlo equity simulation** — 10,000 random runouts for accurate win-probability estimates
- 📊 **Pot odds calculator** — `cost_to_call / (pot + cost_to_call)` breakeven analysis
- 💰 **Expected value (EV)** — `EV = equity × pot − (1 − equity) × cost_to_call`
- 🎯 **Decision engine** — clear Fold / Call / Raise recommendation with explanation
- 🟢🟡🔴 **Color-coded badge** — green = RAISE, amber = CALL, red = FOLD

### Phase 5 — Table Position Awareness ✅
- 🪑 **9-seat position model** — UTG, UTG+1, MP, MP+1, HJ, CO, BTN, SB, BB with individual multipliers
- 🎯 **Position-adjusted thresholds** — Button plays looser (1.15×), UTG plays tighter (0.80×); raise and free-check thresholds scale with your seat
- 🗺️ **Visual position selector** — oval poker table UI with 9 tappable seats; tap to select your seat, tap again to deselect
- 📋 **Collapsible input** — the position picker is tucked in an `ExpansionTile` labelled "Table Position (optional) — Improves accuracy" so it never clutters the UI
- 🏷️ **Position shown in results** — hero seat abbreviation (e.g. BTN, CO) appears in the game-info summary and in the explanation text
- 🔄 **Fully backward compatible** — all position fields are optional/nullable; existing flows work unchanged


- ⚡ **Background isolate computation** — Monte Carlo simulation runs in a separate `Isolate` via `Isolate.run()`, keeping the UI fully responsive during calculation
- 🛡️ **Input validation hardening** — pot size must be > 0; bet to call must be ≥ 0; community cards must be 0, 3, 4, or 5 (no invalid board states); opponents 1–9
- 🧪 **Comprehensive edge case tests** — straight flush vs. four-of-a-kind ranking, ace-low straight ordering, full house tie-breaking, pocket aces equity, river determinism, multi-opponent equity scaling, free-check never folds, extreme pot-odds scenarios, and more


- 🎨 **Dark / Light mode toggle** — persisted via `SharedPreferences`
- 🃏 **Poker table visualization** — oval felt table with player seat, community cards, opponent indicators, and pot display
- 📜 **Hand history** — every analyzed hand is automatically saved; browse, delete, or clear all entries from the History screen
- 🔔 **Animated decision badge** — bounce-in elastic scale animation on the FOLD/CALL/RAISE badge
- 📊 **Staggered results animation** — each result section fades and slides in sequentially
- 📱 **Responsive Manual Input** — two-column layout on screens wider than 600px (tablet/desktop)
- 🕐 **Recent Activity** — home screen shows the last 3 analyzed hands at a glance


- 📸 **Scan Table** — take a photo (or pick from gallery) and have cards automatically detected
- 🔍 **On-device ML** — TFLite object detection model runs entirely on device (no server required)
- 🃏 **Visual card recognition** — detects playing cards by appearance, not OCR text; works with stylized fonts, suit graphics, and real table conditions
- 🔎 **Detection Review Screen** — inspect detected cards, remove false positives, add missed cards, and assign each card to "My Hand" or "Community"
- ⚡ **Pre-populated input** — confirmed cards flow directly into the Manual Input screen
- 🏠 **Updated Home Screen** — two equal-prominence buttons: **📸 Scan Table** and **✍️ Manual Input**

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart 3) |
| State | `StatefulWidget` + `ChangeNotifier` |
| Poker math | Custom Dart engine (hand evaluator + Monte Carlo) |
| Card recognition | TFLite Object Detection (custom playing card model) |
| Camera | `camera` plugin |
| Image processing | `image` package |
| Persistence | Hive |
| Crash reporting | Firebase Crashlytics (graceful no-op if unconfigured) |
| Date formatting | `intl` |
| Permissions | `permission_handler` |
| UI | Material Design 3 |
| Tests | `flutter_test` |

## Project Structure

```
lib/
├── main.dart                           # App entry point (ThemeService init)
├── models/
│   ├── card.dart                       # PokerCard, Suit, Rank
│   ├── hand.dart                       # Hand (hole + community cards)
│   ├── game_state.dart                 # Table state (+ heroPosition)
│   ├── position.dart                   # TablePosition enum + multiplier helpers
│   └── hand_record.dart                # Persisted analyzed hand
├── engine/
│   ├── hand_evaluator.dart             # Best 5-card hand from up to 7 cards
│   ├── equity_calculator.dart          # Monte Carlo equity simulation
│   ├── pot_odds.dart                   # Pot odds math
│   └── decision_engine.dart            # Fold / Call / Raise recommendation
├── recognition/
│   ├── card_detector.dart              # TFLite object detection → PokerCard list
│   └── image_processor.dart            # Grayscale, contrast, crop, rotate
├── services/
│   ├── camera_service.dart             # Camera lifecycle & permissions
│   ├── crash_reporting_service.dart    # Firebase Crashlytics wrapper
│   ├── history_service.dart            # Hand history persistence
│   └── theme_service.dart              # Theme mode persistence
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart            # Landing screen (Scan + Manual + history)
│   │   ├── camera_screen.dart          # Live preview, capture, gallery pick
│   │   ├── detection_review_screen.dart# Review & assign detected cards
│   │   ├── history_screen.dart         # Hand history browser
│   │   ├── manual_input_screen.dart    # Card selection + game info (responsive)
│   │   └── results_screen.dart         # Decision + stats + table visualization
│   ├── utils/
│   │   └── page_transitions.dart       # Slide-up / fade route helpers
│   └── widgets/
│       ├── card_widget.dart            # Visual playing card
│       ├── card_selector.dart          # 52-card interactive grid
│       ├── decision_badge.dart         # Animated FOLD/CALL/RAISE badge
│       ├── position_selector.dart      # Oval table with 9 tappable seats
│       └── table_widget.dart           # Oval poker table visualization
└── utils/
    └── constants.dart                  # Suit symbols, rank labels, defaults
test/
├── models/
│   ├── card_test.dart
│   └── hand_record_test.dart
├── engine/
│   ├── hand_evaluator_test.dart
│   ├── equity_calculator_test.dart
│   ├── pot_odds_test.dart
│   ├── decision_engine_test.dart
│   └── decision_engine_position_test.dart
├── services/
│   └── history_service_test.dart
└── recognition/
    └── card_detector_test.dart         # TFLite label-to-card mapping tests
```

## Setup & Installation

### Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) ≥ 3.0
- Dart ≥ 3.0
- Android Studio / Xcode (for device/emulator)

### Install dependencies

```bash
flutter pub get
```

### Run the app

```bash
flutter run
```

### Run tests

```bash
flutter test
```

## Firebase Setup

Crash reporting via Firebase Crashlytics requires project-specific config files. The app includes placeholder stubs so it compiles and runs fine without them — crash reporting simply won't send data until you replace the stubs.

### Steps

1. Go to [https://console.firebase.google.com](https://console.firebase.google.com) and create a new Firebase project.
2. **Android**: Register an Android app with package name `com.kvesen.pokerbuddy`. Download `google-services.json` and replace the placeholder at `android/app/google-services.json`.
3. **iOS**: Register an iOS app with bundle ID `com.kvesen.pokerbuddy`. Download `GoogleService-Info.plist` and replace the placeholder at `ios/Runner/GoogleService-Info.plist`.
4. Enable **Crashlytics** in the Firebase Console for your project.

> **Note:** The app works fine without real Firebase config files — crash reporting is simply disabled (no-op) in that case.

## Release Signing (Android)

To build a signed release APK/AAB for Google Play, create `android/key.properties` (already gitignored) based on the template at `android/key.properties.example`:

```
storePassword=<your keystore password>
keyPassword=<your key password>
keyAlias=<your key alias>
storeFile=<absolute or relative path to your .jks/.keystore file>
```

When `android/key.properties` is present, the release build type automatically uses the release signing config. Without it, the build falls back to debug keys (suitable for local testing only).

## Camera Permissions Setup

### Android

The required permissions are already present in `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
```

### iOS

The required usage descriptions are already present in `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>This app needs camera access to scan playing cards on the poker table.</string>
<key>NSPhotoLibraryUsageDescription</key>
<string>This app needs photo library access to select images of poker tables.</string>
```

## How It Works

### Manual Input Flow
1. Tap **✍️ Manual Input** on the home screen
2. Select your 2 hole cards from the card grid
3. Optionally select 0–5 community cards
4. Enter pot size, bet to call, and number of opponents
5. Tap **"Calculate Best Move"** — the engine runs 10,000 simulations

### Camera Scan Flow
1. Tap **📸 Scan Table** on the home screen
2. Point the camera at your poker table and tap the shutter button (or pick from gallery)
3. The app pre-processes the image (grayscale + contrast enhancement) and runs on-device TFLite object detection
4. Review detected cards on the **Detection Review** screen:
   - Swipe left to remove false positives
   - Tap the chip to toggle between **My Hand** and **Community**
   - Tap **"Add Card Manually"** for any missed cards
5. Tap **"Continue"** — cards are pre-populated in the Manual Input screen

> **Note:** The TFLite model file (`assets/models/card_detection_model.tflite`) is a placeholder stub.
> You must supply your own trained model. See [`assets/models/README.md`](assets/models/README.md) for instructions on obtaining or training one from Roboflow.

### Decision Logic

| Condition | Action |
|---|---|
| `equity < pot_odds_required` | **FOLD** (negative EV) |
| `pot_odds_required ≤ equity < pot_odds_required × (1.5 / pos_mult)` | **CALL** (marginally profitable) |
| `equity ≥ pot_odds_required × (1.5 / pos_mult)` | **RAISE** (strong edge) |

`pos_mult` is 1.0 when no position is provided. On the Button it is 1.15 (easier to raise); UTG it is 0.80 (must be stronger to raise).

## Roadmap

- **Phase 1** ✅ Poker math engine + manual input UI
- **Phase 2** ✅ Camera integration + ML card detection + detection review
- **Phase 3** ✅ UI polish — table visualization, hand history, dark/light theming, responsive layout
- **Phase 4** ✅ Edge case testing + performance optimization
- **Phase 5** ✅ Table position awareness — position-adjusted decision thresholds + visual seat selector
- **Phase 6** 🔜 App Store / Google Play deployment

## Privacy Policy

The privacy policy is available at **https://kvesen.github.io/PokerHandSuggester/**

To activate GitHub Pages hosting:
1. Go to **Settings → Pages**
2. Set **Source** to "Deploy from a branch"
3. Select **Branch**: `main`, **Folder**: `/docs`
4. Save — the policy will be live within a few minutes

The policy source is also available in [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md).