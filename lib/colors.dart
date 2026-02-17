/// ============================================================================
/// colors.dart - App Color Palette & Theme Constants
/// ============================================================================
///
/// This file demonstrates the Dart pattern of using a static class to define
/// a centralized color palette. Benefits of this approach:
///
/// 1. **Single source of truth** - All colors defined in one place
/// 2. **Compile-time constants** - Using `const` enables compiler optimizations
/// 3. **Type safety** - IDE autocomplete and error checking
/// 4. **Easy theming** - Switch palettes by changing this file
///
/// FLUTTER CONCEPT: Color class
/// The `Color` class represents colors using ARGB (Alpha, Red, Green, Blue).
/// The format `0xFFRRGGBB` uses hex notation where:
/// - `FF` = Alpha channel (opacity, FF = fully opaque)
/// - Next 6 digits = RGB color in hex
/// ============================================================================

import 'package:flutter/material.dart';

/// A static class containing all color constants used throughout the app.
///
/// DART CONCEPT: Static Class Pattern
/// By making all members `static const`, this class acts as a namespace for
/// constants. The class itself is never instantiated - we access colors via
/// `AppColors.primary`, etc.
///
/// This is preferred over top-level constants because:
/// - Provides namespacing (avoiding pollution of the global namespace)
/// - Groups related constants logically
/// - Enables better IDE discoverability
class AppColors {
  // Private constructor prevents instantiation of this utility class.
  // DART CONCEPT: Private constructors are named with underscore prefix.
  AppColors._();

  // ─────────────────────────────────────────────────────────────────────────
  // Primary Brand Colors
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary brand color - deep navy blue
  /// Used for: primary buttons, headers, key UI elements
  static const primary = Color(0xFF0D1B2A);

  /// Secondary accent color - slate blue
  /// Used for: secondary buttons, hover states, borders
  static const secondary = Color(0xFF1B263B);

  /// Accent color - vibrant teal
  /// Used for: call-to-action elements, highlights, interactive elements
  static const accent = Color(0xFF00B4D8);

  // ─────────────────────────────────────────────────────────────────────────
  // Background Colors
  // ─────────────────────────────────────────────────────────────────────────

  /// Main background color - dark blue-gray
  static const background = Color(0xFF0D1B2A);

  /// Surface color for cards and elevated content
  static const surface = Color(0xFF1B263B);

  /// Slightly elevated surface for nested cards
  static const surfaceElevated = Color(0xFF243447);

  // ─────────────────────────────────────────────────────────────────────────
  // Text Colors
  // ─────────────────────────────────────────────────────────────────────────

  /// Primary text - high contrast for main content
  static const textPrimary = Color(0xFFE0E6ED);

  /// Secondary text - lower emphasis for supporting content
  static const textSecondary = Color(0xFF8892A0);

  /// Muted text - lowest emphasis for hints and disabled states
  static const textMuted = Color(0xFF5C6370);

  // ─────────────────────────────────────────────────────────────────────────
  // Semantic Colors (for game state feedback)
  // ─────────────────────────────────────────────────────────────────────────

  /// Success state - winning, achieved nil
  static const success = Color(0xFF00C853);

  /// Warning state - approaching bag penalty
  static const warning = Color(0xFFFFB300);

  /// Error/danger state - failed bid, bag penalty, losing
  static const error = Color(0xFFFF5252);

  /// Info state - neutral information
  static const info = Color(0xFF00B4D8);

  // ─────────────────────────────────────────────────────────────────────────
  // Card Game Specific Colors
  // ─────────────────────────────────────────────────────────────────────────

  /// Spade suit color - matches the game theme
  static const spade = Color(0xFF415A77);

  /// Team A indicator color
  static const teamA = Color(0xFF00B4D8);

  /// Team B indicator color
  static const teamB = Color(0xFFE07A5F);
}
