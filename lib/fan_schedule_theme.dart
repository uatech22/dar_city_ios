import 'dart:math' as math;

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:flutter/material.dart';

/// Dar City fan app brand tokens (matches Schedule / Home screens).
abstract final class FanSchedulePalette {
  // App shell — same as fanSchedules / fanMainDashboard
  static const bgDeep = Color(0xFF0F0F0F);
  static const bgCard = Color(0xFF1A1A1A);
  static const bgCardDeep = Color(0xFF121212);
  static const bgElevated = Color(0xFF2A2A2A);
  static const bgCell = Color(0xFF161616);
  static const bgCellEmpty = Color(0xFF111111);

  // Brand accents
  static const accentRed = Color(0xFFE53935);
  static const accentRedDeep = Color(0xFFB71C1C);
  static const purpleMid = Color(0xFF552583);
  static const purpleSoft = Color(0xFF6B3FA0);
  static const gold = Color(0xFFFDB927);
  static const goldDeep = Color(0xFFD4A017);

  // Text on dark
  static const textPrimary = Color(0xFFFFFFFF);
  static const textSecondary = Color(0xFFB0B0B0);
  static const textMuted = Color(0xFF707070);

  // Lines & states
  static const line = Color(0xFF333333);
  static const lineSoft = Color(0xFF252525);
  static const win = Color(0xFF34D399);
  static const loss = Color(0xFFEF4444);
  static const today = accentRed;

  static const cardGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1E1E1E), Color(0xFF121212)],
  );

  static const headerGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFF1A1A1A), Color(0xFF0F0F0F)],
  );
}

class FanScheduleMetrics {
  FanScheduleMetrics._(this.width, this.height);

  final double width;
  final double height;

  bool get isCompact => width < DarLayoutMetrics.compactBreakpoint;
  bool get isTablet => width >= DarLayoutMetrics.tabletBreakpoint;
  bool get isWide => width >= DarLayoutMetrics.wideBreakpoint;

  double get maxContentWidth =>
      DarLayoutMetrics.fromDimensions(width, height).maxContentWidth;

  double get headerHeight => isCompact ? 52 : 58;
  double get weekdayHeight => isCompact ? 28 : 32;
  double get detailMinHeight => isCompact ? 190 : (isTablet ? 230 : 210);

  double get monthFontSize => isCompact ? 13 : 15;
  double get weekdayFontSize => isCompact ? 8.5 : 9.5;
  double get dayNumberFontSize => isCompact ? 9 : 10;
  double get cellFooterFontSize => isCompact ? 6.5 : 7.5;
  double get bannerFontSize => isCompact ? 6 : 7;
  double get detailLogoSize => isCompact ? 46 : (isTablet ? 62 : 54);
  double get detailScoreFontSize => isCompact ? 28 : 34;
  double get detailMatchupFontSize => isCompact ? 18 : 22;
  double get detailTimeFontSize => isCompact ? 26 : 32;

  double get horizontalPadding =>
      DarLayoutMetrics.fromDimensions(width, height).horizontalPadding;
  double get cardRadius => isTablet ? 18 : 14;

  /// Logo size scaled to actual cell row height — prevents overflow on any device.
  double cellLogoSizeFor(double rowHeight, {required bool hasGame}) {
    if (!hasGame || rowHeight < 44) return 0;
    if (rowHeight < 52) return 12;
    return (rowHeight * 0.28).clamp(14.0, isTablet ? 28.0 : 24.0);
  }

  bool cellIsTight(double rowHeight) => rowHeight < 50;

  static FanScheduleMetrics of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return FanScheduleMetrics._(size.width, size.height);
  }

  static double calendarHostHeight(
    BuildContext context, {
    required double topChrome,
  }) {
    final m = of(context);
    final available = m.height - topChrome;
    final maxH = m.height * 0.84;
    // clamp() throws if min > max — on short windows (Linux desktop) max can be < 460.
    final minH = math.min(460.0, maxH);
    return available.clamp(minH, math.max(minH, maxH));
  }

  double gridHeightFor(double totalHeight, int rowCount) {
    final reserved = headerHeight + weekdayHeight + detailMinHeight + 6;
    final available = totalHeight - reserved;
    final minForRows = rowCount * 46.0;
    final maxGrid = totalHeight * 0.56;
    final minH = math.min(minForRows, maxGrid);
    return available.clamp(minH, math.max(minH, maxGrid));
  }
}

TextStyle fanScheduleLabel({
  required double size,
  Color color = FanSchedulePalette.textPrimary,
  FontWeight weight = FontWeight.w700,
  double letterSpacing = 0.6,
  double? height,
}) {
  return TextStyle(
    fontSize: size,
    fontWeight: weight,
    color: color,
    letterSpacing: letterSpacing,
    height: height,
  );
}
