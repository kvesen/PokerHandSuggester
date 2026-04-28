# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.0.0] - 2026-04-28

First public release on the Google Play Store.

### Added
- Texas Hold'em poker math engine
- Manual card input with 52-card interactive grid
- Monte Carlo equity simulation running in a background isolate (10,000 iterations)
- Pot odds calculator
- Expected Value (EV) computation
- Decision engine with Fold / Call / Raise recommendations and color-coded badges
- Table position awareness with 9-seat model (UTG through BB)
- Position-adjusted decision thresholds and villain range-pressure multipliers
- Visual position selector (oval poker table with tappable seats)
- Poker table visualization on results screen
- Hand history persistence stored locally with Hive
- Recent Activity section on home screen
- Dark/Light mode toggle persisted via SharedPreferences
- Animated decision badge and staggered results animations
- Responsive two-column layout for tablets
- Dynamic app version displayed in home screen footer
- Firebase Crashlytics integration for crash reporting
- "Coming Soon" badge on Scan Table feature (card scanning not yet available)
