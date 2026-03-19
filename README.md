# Poker Hand Suggester 🃏

A Flutter mobile app (Android & iOS) that calculates the **mathematically optimal poker decision** — Fold, Call, or Raise — based on the current game state.

## Features

- ♠️ **Full Texas Hold'em support** — preflop through river
- 🃏 **Interactive card selector** — tap to select hole cards and community cards from a visual 52-card grid
- 🧮 **Monte Carlo equity simulation** — 10,000 random runouts for accurate win-probability estimates
- 📊 **Pot odds calculator** — `cost_to_call / (pot + cost_to_call)` breakeven analysis
- 💰 **Expected value (EV)** — `EV = equity × pot − (1 − equity) × cost_to_call`
- 🎯 **Decision engine** — clear Fold / Call / Raise recommendation with explanation
- 🟢🟡🔴 **Color-coded badge** — green = RAISE, amber = CALL, red = FOLD

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart 3) |
| State | `StatefulWidget` (local state) |
| Poker math | Custom Dart engine (hand evaluator + Monte Carlo) |
| UI | Material Design 3 |
| Tests | `flutter_test` |

## Project Structure

```
lib/
├── main.dart                       # App entry point
├── models/
│   ├── card.dart                   # PokerCard, Suit, Rank
│   ├── hand.dart                   # Hand (hole + community cards)
│   └── game_state.dart             # Table state
├── engine/
│   ├── hand_evaluator.dart         # Best 5-card hand from up to 7 cards
│   ├── equity_calculator.dart      # Monte Carlo equity simulation
│   ├── pot_odds.dart               # Pot odds math
│   └── decision_engine.dart        # Fold / Call / Raise recommendation
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart        # Landing screen
│   │   ├── manual_input_screen.dart # Card selection + game info
│   │   └── results_screen.dart     # Decision + stats display
│   └── widgets/
│       ├── card_widget.dart        # Visual playing card
│       ├── card_selector.dart      # 52-card interactive grid
│       └── decision_badge.dart     # FOLD/CALL/RAISE badge
└── utils/
    └── constants.dart              # Suit symbols, rank labels, defaults
test/
├── models/card_test.dart
└── engine/
    ├── hand_evaluator_test.dart
    ├── equity_calculator_test.dart
    ├── pot_odds_test.dart
    └── decision_engine_test.dart
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

## How It Works

1. **Select your hole cards** — tap 2 cards from the grid
2. **Select community cards** — tap 0–5 board cards (optional)
3. **Enter game info** — pot size, bet to call, number of opponents
4. **Tap "Calculate Best Move"** — the engine runs 10,000 simulations and recommends an action

### Decision Logic

| Condition | Action |
|---|---|
| `equity < pot_odds_required` | **FOLD** (negative EV) |
| `pot_odds_required ≤ equity < pot_odds_required × 1.5` | **CALL** (marginally profitable) |
| `equity ≥ pot_odds_required × 1.5` | **RAISE** (strong edge) |

## Screenshots

> *(Coming soon — run `flutter run` to see the live UI)*

## Roadmap

- **Phase 1** ✅ Poker math engine + manual input UI
- **Phase 2** 📱 UI polish — table visualization, hand history
- **Phase 3** 📸 Camera integration + ML card recognition (Google ML Kit / TFLite)
- **Phase 4** 🧪 Edge case testing + performance optimization
- **Phase 5** 🚀 App Store / Google Play deployment