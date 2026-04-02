# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [1.2.0] - 2026-04-01

### Added
- Dynamic app version in home screen footer (reads from package info instead of hardcoded string)
- CHANGELOG.md for tracking release history
- GitHub Actions release workflow with automatic version tagging
- `package_info_plus` dependency for runtime version detection

### Changed
- Home screen footer now dynamically displays the version from pubspec.yaml

## [1.1.0] - 2025

### Added
- Firebase Crashlytics integration for crash reporting
- "Coming Soon" ribbon badge on gated Scan Table feature
- Hard UI gate preventing navigation to unfinished Camera screen
- Table position awareness with 9-seat model (UTG through BB)
- Position-adjusted decision thresholds
- Visual position selector (oval poker table with tappable seats)
- Villain position tracking with range-pressure multipliers
- Hand history persistence with Hive
- Dark/Light mode toggle persisted via SharedPreferences
- Poker table visualization on results screen
- Animated decision badge (bounce-in elastic scale)
- Staggered results animations
- Responsive two-column layout for tablets
- Recent Activity section on home screen
- Monte Carlo equity simulation running in background isolate
- Camera screen with live preview, capture, and gallery pick
- TFLite on-device card detection (placeholder model)
- Detection review screen for card assignment

### Fixed
- Privacy Policy updated to reference correct technologies (TFLite, Hive)

## [1.0.0] - 2025

### Added
- Initial release
- Texas Hold'em poker math engine
- Manual card input with 52-card interactive grid
- Monte Carlo equity calculator (10,000 iterations)
- Pot odds calculator
- Expected Value (EV) computation
- Decision engine (Fold / Call / Raise)
- Color-coded decision badges
