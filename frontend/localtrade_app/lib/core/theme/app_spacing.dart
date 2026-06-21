import 'package:flutter/material.dart';

class AppSpacing {
  AppSpacing._();

  // ── Gaps ──────────────────────────────────────────────────────
  static const double gapXs = 6;
  static const double gapSm = 8;
  static const double gapMd = 10;
  static const double gapLg = 12;
  static const double gapXl = 14;

  // ── Card padding ──────────────────────────────────────────────
  static const double cardPaddingSm = 12;
  static const double cardPaddingMd = 14;
  static const double cardPaddingLg = 18;

  // ── Screen padding ────────────────────────────────────────────
  static const double screenPaddingH = 16;
  static const double screenPaddingTop = 12;

  // ── Border radius ─────────────────────────────────────────────
  static const double radiusSm = 8;
  static const double radiusMd = 12;
  static const double radiusLg = 16;
  static const double radiusHero = 24;

  // ── Touch targets ─────────────────────────────────────────────
  static const double touchTarget = 44;
  static const double touchTargetPrimary = 52;

  // ── Button heights ────────────────────────────────────────────
  static const double buttonHeight = 48;
  static const double buttonHeightPrimary = 52;

  // ── Common EdgeInsets ─────────────────────────────────────────
  static const EdgeInsets padH = EdgeInsets.symmetric(horizontal: screenPaddingH);
  static const EdgeInsets padCard = EdgeInsets.all(cardPaddingMd);
  static const EdgeInsets padCardLg = EdgeInsets.all(cardPaddingLg);
}
