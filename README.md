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


- 🎨 **System / Light / Dark mode** — three-way theme selector, persisted via `SharedPreferences`
- 🃏 **Poker table visualization** — oval felt table with player seat, community cards, opponent indicators, and pot display
- 📜 **Hand history** — every analyzed hand is automatically saved; browse, delete, or clear all entries from the History screen
- 🔔 **Animated decision badge** — bounce-in elastic scale animation on the FOLD/CALL/RAISE badge with icon and haptic feedback
- 📊 **Staggered results animation** — each result section fades and slides in sequentially
- 📱 **Responsive Manual Input** — two-column layout on screens wider than 600px (tablet/desktop)
- 🕐 **Recent Activity** — home screen shows the last 3 analyzed hands at a glance

## Tech Stack

| Layer | Technology |
|---|---|
| Framework | Flutter (Dart 3) |
| State | `StatefulWidget` + `ChangeNotifier` |
| Poker math | Custom Dart engine (hand evaluator + Monte Carlo) |
| Persistence | Hive |
| Date formatting | `intl` |
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
│   ├── equity_isolate.dart             # Background isolate helper
│   ├── pot_odds.dart                   # Pot odds math
│   └── decision_engine.dart            # Fold / Call / Raise recommendation
├── services/
│   ├── history_service.dart            # Hand history persistence
│   └── theme_service.dart              # Theme mode persistence
├── ui/
│   ├── screens/
│   │   ├── home_screen.dart            # Landing screen (Manual Input + history)
│   │   ├── history_screen.dart         # Hand history browser
│   │   ├── manual_input_screen.dart    # Card selection + game info (responsive)
│   │   ├── range_chart_screen.dart     # Position-based hand range charts
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
    ├── app_colors.dart                 # Shared color constants
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
└── ui/
    ├── screens/
    └── widgets/
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

## Release Signing (Android)

To build a signed release APK/AAB for Google Play, create `android/key.properties` (already gitignored) based on the template at `android/key.properties.example`:

```
storePassword=<your keystore password>
keyPassword=<your key password>
keyAlias=<your key alias>
storeFile=<absolute or relative path to your .jks/.keystore file>
```

When `android/key.properties` is present, the release build type automatically uses the release signing config. Without it, the build falls back to debug keys (suitable for local testing only).

## How It Works

### Home Screen
The home screen shows:
- A prominent **Manual Input** button — tap to start a new hand analysis
- A **Hand Ranges** card — browse position-based opening range charts
- **Recent Activity** — the last 3 analyzed hands at a glance

### Manual Input Flow
1. Tap **✍️ Manual Input** on the home screen
2. Select your 2 hole cards from the card grid
3. Optionally select 0–5 community cards
4. Enter pot size, bet to call, and number of opponents
5. Tap **"Calculate Best Move"** — the engine runs 10,000 simulations

### Decision Logic

| Condition | Action |
|---|---|
| `equity < pot_odds_required` | **FOLD** (negative EV) |
| `pot_odds_required ≤ equity < pot_odds_required × (1.5 / pos_mult)` | **CALL** (marginally profitable) |
| `equity ≥ pot_odds_required × (1.5 / pos_mult)` | **RAISE** (strong edge) |

`pos_mult` is 1.0 when no position is provided. On the Button it is 1.15 (easier to raise); UTG it is 0.80 (must be stronger to raise).

## Roadmap

- **Phase 1** ✅ Poker math engine + manual input UI
- **Phase 2** ✅ UI polish — table visualization, hand history, dark/light/system theming, responsive layout
- **Phase 3** ✅ Edge case testing + performance optimization
- **Phase 4** ✅ Table position awareness — position-adjusted decision thresholds + visual seat selector
- **Phase 5** 🔜 App Store / Google Play deployment

## Contributing / Development

Contributions are welcome! See [CONTRIBUTING.md](CONTRIBUTING.md) for setup instructions, code style notes, and PR guidelines.

CI runs `flutter analyze && flutter test` on every pull request to `main`. Make sure both pass before opening a PR.

## Privacy Policy

The privacy policy is available at **https://kvesen.github.io/PokerHandSuggester/**

To activate GitHub Pages hosting:
1. Go to **Settings → Pages**
2. Set **Source** to "Deploy from a branch"
3. Select **Branch**: `main`, **Folder**: `/docs`
4. Save — the policy will be live within a few minutes

The policy source is also available in [`PRIVACY_POLICY.md`](PRIVACY_POLICY.md).
