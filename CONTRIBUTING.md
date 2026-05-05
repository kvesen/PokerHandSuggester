# Contributing to Poker Buddy

Thank you for your interest in contributing! This guide explains how to get
the project set up, run tests, submit changes, and follow our code conventions.

---

## Table of Contents

1. [Development Environment Setup](#development-environment-setup)
2. [Running Tests](#running-tests)
3. [Running the Linter](#running-the-linter)
4. [Branch Naming Conventions](#branch-naming-conventions)
5. [Pull Request Guidelines](#pull-request-guidelines)
6. [Code Style](#code-style)

---

## Development Environment Setup

**Prerequisites**

| Tool | Minimum Version |
|------|----------------|
| Flutter | 3.x (stable channel) |
| Dart | 3.6 or later |

1. **Clone the repository**

   ```bash
   git clone https://github.com/kvesen/PokerHandSuggester.git
   cd PokerHandSuggester
   ```

2. **Install dependencies**

   ```bash
   flutter pub get
   ```

3. **Verify the setup**

   ```bash
   flutter analyze
   flutter test
   ```

   Both commands should exit with no errors on a clean clone.

4. *(Optional)* Open in VS Code or Android Studio. Both editors support
   Flutter out of the box via their respective Flutter plugins.

---

## Running Tests

```bash
# Run all unit and widget tests
flutter test

# Run a single test file
flutter test test/engine/equity_calculator_test.dart

# Run tests with verbose output
flutter test --reporter expanded
```

All new functionality **must** include tests. Keep existing tests passing.

---

## Running the Linter

```bash
flutter analyze --fatal-infos
```

The CI pipeline runs `flutter analyze --fatal-infos`, so any info-level
diagnostics are treated as errors. Resolve all lints before opening a PR.

---

## Branch Naming Conventions

| Prefix | When to use |
|--------|-------------|
| `feature/short-description` | New features or enhancements |
| `fix/short-description` | Bug fixes |
| `chore/short-description` | Maintenance, dependency updates, CI changes |
| `docs/short-description` | Documentation-only changes |
| `test/short-description` | Adding or fixing tests only |

Examples:

```
feature/position-aware-equity
fix/history-hive-crash
chore/update-dependencies
```

---

## Pull Request Guidelines

1. **Link to an issue** — reference the relevant issue in the PR description
   (e.g. `Closes #42`).
2. **Describe your changes** — explain *what* changed and *why*. Screenshots
   or screen recordings are welcome for UI changes.
3. **Keep the scope small** — one logical change per PR makes review faster.
4. **Keep tests passing** — `flutter test` must pass with no failures before
   requesting review.
5. **No breaking changes to the engine** — do not modify poker engine logic,
   decision thresholds, or equity calculations without explicit discussion.
6. **Rebase on `main`** — keep your branch up to date with `main` before
   opening a PR to avoid merge conflicts.

---

## Code Style

The project follows the rules defined in `analysis_options.yaml` and the
[Dart style guide](https://dart.dev/effective-dart/style).

Key conventions:

- **Formatting** — run `dart format .` before committing. CI does not
  auto-format, but inconsistent formatting will trigger linter errors.
- **Library directives** — every source file starts with `library;` and a
  doc comment (see any existing file for the pattern).
- **Widget accessibility** — wrap interactive widgets with `Semantics` nodes
  that provide descriptive labels for screen readers.
- **Error handling** — never swallow errors silently in production. Log via
  `CrashReportingService.recordError` or `debugPrint` at minimum.
- **No direct Hive usage outside `HistoryService`** — all persistence goes
  through the service layer.
- **No poker engine changes without tests** — any change to
  `lib/engine/` must be accompanied by updated or new tests in `test/engine/`.
