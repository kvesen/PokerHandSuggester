/// Shared color constants for the PokerHandSuggester app.
library;

import 'package:flutter/material.dart';

// ── Light-theme constants ────────────────────────────────────────────────────

/// Deep poker-green — primary brand color (light theme).
const Color kPrimaryGreen = Color(0xFF1B5E20);

/// Slightly lighter green — used for button hover / gradient start (light).
const Color kMediumGreen = Color(0xFF2E7D32);

/// Very light green tint — used for card slots, section backgrounds (light).
const Color kLightGreenBackground = Color(0xFFF1F8E9);

/// Light green border — used alongside [kLightGreenBackground] containers.
const Color kLightGreenBorder = Color(0xFFC8E6C9);

/// Light green for empty card slot borders (light theme).
const Color kCardSlotBorder = Color(0xFFA5D6A7);

/// Light green for empty card slot icon (light theme).
const Color kCardSlotIcon = Color(0xFF81C784);

/// Warm off-white — scaffold/body background color (light theme).
const Color kOffWhiteBackground = Color(0xFFFAFAF8);

// ── Dark-theme constants ─────────────────────────────────────────────────────

/// Bright green for dark backgrounds — primary brand color (dark theme).
const Color kPrimaryGreenDark = Color(0xFF4ADE80);

/// Medium bright green — used for button hover / gradient start (dark theme).
const Color kMediumGreenDark = Color(0xFF22C55E);

/// Dark green-tinted surface — used for card slots, section backgrounds (dark).
const Color kDarkGreenBackground = Color(0xFF1A2E23);

/// Subtle green border on dark backgrounds.
const Color kDarkGreenBorder = Color(0xFF2D4A3A);

/// Dark green for empty card slot borders (dark theme).
const Color kCardSlotBorderDark = Color(0xFF3A5C4A);

/// Bright green for empty card slot icon (dark theme).
const Color kCardSlotIconDark = Color(0xFF4ADE80);

/// Near-black scaffold background (dark theme).
const Color kDarkBackground = Color(0xFF0A0A0A);
