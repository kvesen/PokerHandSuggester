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

### Phase 2 — Camera Integration & Card Detection ✅
- 📸 **Scan Table** — take a photo (or pick from gallery) and have cards automatically detected
- 🔍 **On-device ML** — Google ML Kit text recognition runs entirely on device (no server required)
- 🃏 **Multi-format parsing** — detects cards in unicode (`A♠`), letter (`Ks`), and full-name (`Ace of Spades`) notation
- 🔎 **Detection Review Screen** — inspect detected cards, remove false positives, add missed cards, and assign each card to "My Hand" or "Community"
- ⚡ **Pre-populated input** — confirmed cards flow directly into the Manual Input screen
- 🏠 **Updated Home Screen** — two equal-prominence buttons: **📸 Scan Table** and **✍️ Manual Input**

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart 3) |
| State | `StatefulWidget` (local state) |
| Poker math | Custom Dart engine (hand evaluator + Monte Carlo) |
| Card recognition | Google ML Kit Text Recognition |
| Camera | `camera` plugin |
| Image processing | `image` package |
| Permissions | `permission_handler` |
| UI | Material Design 3 |
| Tests | `flutter_test` |

## Project Structure

```
lib/
├── main.dart                           # App entry point
├── models/
│   ├── card.dart                       # PokerCard, Suit, Rank
│   ├── hand.dart                       # Hand (hole + community cards)
│   └── game_state.dart                 # Table state
├── engine/
│   ├── hand_evaluator.dart             # Best 5-card hand from up to 7 cards
│   ├── equity_calculator.dart          # Monte Carlo equity simulation
│   ├── pot_odds.dart                   # Pot odds math
│   └── decision_engine.dart            # Fold / Call / Raise recommendation
├── recognition/
│   ├── card_detector.dart              # ML Kit OCR → PokerCard list
│   └── image_processor.dart            # Grayscale, contrast, crop, rotate
├── services/
│   └── camera_service.dart             # Camera lifecycle & permissions
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart            # Landing screen (Scan + Manual buttons)
│   │   ├── camera_screen.dart          # Live preview, capture, gallery pick
│   │   ├── detection_review_screen.dart# Review & assign detected cards
│   │   ├── manual_input_screen.dart    # Card selection + game info
│   │   └── results_screen.dart         # Decision + stats display
│   └── widgets/
│       ├── card_widget.dart            # Visual playing card
│       ├── card_selector.dart          # 52-card interactive grid
│       └── decision_badge.dart         # FOLD/CALL/RAISE badge
└── utils/
    └── constants.dart                  # Suit symbols, rank labels, defaults
test/
├── models/card_test.dart
├── engine/
│   ├── hand_evaluator_test.dart
│   ├── equity_calculator_test.dart
│   ├── pot_odds_test.dart
│   └── decision_engine_test.dart
└── recognition/
    └── card_detector_test.dart         # Text-parsing logic tests
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
3. The app pre-processes the image (grayscale + contrast enhancement) and runs on-device ML
4. Review detected cards on the **Detection Review** screen:
   - Swipe left to remove false positives
   - Tap the chip to toggle between **My Hand** and **Community**
   - Tap **"Add Card Manually"** for any missed cards
5. Tap **"Continue"** — cards are pre-populated in the Manual Input screen

### Decision Logic

| Condition | Action |
|---|---|
| `equity < pot_odds_required` | **FOLD** (negative EV) |
| `pot_odds_required ≤ equity < pot_odds_required × 1.5` | **CALL** (marginally profitable) |
| `equity ≥ pot_odds_required × 1.5` | **RAISE** (strong edge) |

## Roadmap

- **Phase 1** ✅ Poker math engine + manual input UI
- **Phase 2** ✅ Camera integration + ML card detection + detection review
- **Phase 3** 🔜 UI polish — table visualization, hand history, theming
- **Phase 4** 🔜 Edge case testing + performance optimization
- **Phase 5** 🔜 App Store / Google Play deployment