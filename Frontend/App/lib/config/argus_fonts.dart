import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// ArgusX typography system.
///
/// Uses GoogleFonts for dynamic font downloading and local caching of:
/// - Zen Dots (display font)
/// - Outfit (body copy font)
/// - Space Mono / Murosia (telemetry data)
class ArgusFonts {
  ArgusFonts._();

  // ── Display / Headings — Zen Dots ──────────────────────────────────────────
  /// Use for: section headers, screen titles, HUD state labels, panel titles,
  ///           button text, nav labels, short all-caps identifiers.
  static TextStyle display({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.zenDots(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
      decoration: decoration,
    );
  }

  // ── Body / Labels — Outfit ────────────────────────────────────────────────
  /// Use for: body copy, descriptions, toggle/toggle sublabels,
  ///           input hints, footer text, chip labels, multi-line content.
  static TextStyle body({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
    TextDecoration? decoration,
  }) {
    return GoogleFonts.outfit(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
      decoration: decoration,
    );
  }

  // ── Telemetry / Data Readouts — Murosia / Space Mono ───────────────────────
  /// Use for: speed readouts, GPS coords, scores, sensor values,
  ///           any live numeric/data display that needs a clean mono-ish feel.
  static TextStyle telemetry({
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
    TextDecoration? decoration,
  }) {
    return const TextStyle(
      fontFamily: 'Murosia',
    ).merge(GoogleFonts.spaceMono(
      color: color,
      fontSize: fontSize,
      fontWeight: fontWeight,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
      decoration: decoration,
    ));
  }
}
