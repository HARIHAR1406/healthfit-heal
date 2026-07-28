import 'package:flutter/material.dart';

/// Animation duration and curve constants for HealthFit Heal.
///
/// All animation timings and curves are centralised here to ensure
/// consistent motion design across the app.
abstract final class AppAnimations {
  // ── Durations ─────────────────────────────────────────────────────────────

  /// Ultra-fast — for micro-feedback (ripple, focus)
  static const Duration durationUltraFast = Duration(milliseconds: 100);

  /// Fast — for simple state changes (toggle, checkbox)
  static const Duration durationFast = Duration(milliseconds: 150);

  /// Normal — for most UI transitions (card expand, menu)
  static const Duration durationNormal = Duration(milliseconds: 250);

  /// Moderate — for route/page transitions
  static const Duration durationModerate = Duration(milliseconds: 300);

  /// Slow — for complex animations (hero, bottom sheet)
  static const Duration durationSlow = Duration(milliseconds: 400);

  /// Very slow — for dramatic/feature reveals
  static const Duration durationVerySlow = Duration(milliseconds: 600);

  /// Extra slow — for onboarding / splash sequences
  static const Duration durationExtraSlow = Duration(milliseconds: 800);

  // ── Lottie Durations ──────────────────────────────────────────────────────
  static const Duration lottieSuccess = Duration(milliseconds: 1500);
  static const Duration lottieLoading = Duration(milliseconds: 1000);
  static const Duration lottieEmpty = Duration(milliseconds: 2000);

  // ── Curves ────────────────────────────────────────────────────────────────
  static const Curve easeIn = Curves.easeIn;
  static const Curve easeOut = Curves.easeOut;
  static const Curve easeInOut = Curves.easeInOut;
  static const Curve decelerate = Curves.decelerate;
  static const Curve fastOutSlowIn = Curves.fastOutSlowIn;
  static const Curve elasticOut = Curves.elasticOut;
  static const Curve bounceOut = Curves.bounceOut;
  static const Curve linear = Curves.linear;

  // ── Stagger Delays ────────────────────────────────────────────────────────
  static const Duration staggerSmall = Duration(milliseconds: 50);
  static const Duration staggerMedium = Duration(milliseconds: 80);
  static const Duration staggerLarge = Duration(milliseconds: 120);
}
