import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Shared breakpoints and spacing for phones, tablets, and wide layouts.
class DarLayoutMetrics {
  DarLayoutMetrics._(this.width, this.height);

  final double width;
  final double height;

  static const compactBreakpoint = 380.0;
  static const tabletBreakpoint = 600.0;
  static const wideBreakpoint = 900.0;
  static const navigationRailBreakpoint = 840.0;
  static const desktopBreakpoint = 1200.0;

  bool get isCompact => width < compactBreakpoint;
  bool get isTablet => width >= tabletBreakpoint;
  bool get isWide => width >= wideBreakpoint;
  bool get useNavigationRail => width >= navigationRailBreakpoint;
  bool get isDesktop => width >= desktopBreakpoint;

  /// Max width for scrollable page content (centered on larger screens).
  double get maxContentWidth {
    if (isDesktop) return 960;
    if (isWide) return 840;
    if (isTablet) return 720;
    return width;
  }

  double get horizontalPadding => isCompact ? 12 : (isTablet ? 24 : 16);

  /// Bottom inset for scroll views above the bottom tab bar.
  double get bottomNavClearance => useNavigationRail ? 28 : 100;

  EdgeInsets scrollPadding({double top = 12, double? bottom}) {
    return EdgeInsets.fromLTRB(
      horizontalPadding,
      top,
      horizontalPadding,
      bottom ?? bottomNavClearance,
    );
  }

  /// Clamp content to the smaller of [maxContentWidth] and [availableWidth].
  double contentWidthFor(double availableWidth, {double? cap}) {
    if (availableWidth <= 0) return cap ?? maxContentWidth;
    final limit = cap ?? maxContentWidth;
    return math.min(limit, availableWidth);
  }

  /// Official shop product grid columns.
  int get shopGridColumns {
    if (isWide) return 4;
    if (isTablet) return 3;
    return 2;
  }

  double get shopGridAspectRatio {
    if (isWide) return 0.72;
    if (isTablet) return 0.68;
    return 0.62;
  }

  /// Starting / match lineup player grid (5 across on tablet+).
  int get lineupGridColumns => isTablet ? 5 : 3;

  /// Narrow forms (attendance token, feedback, etc.).
  double get formMaxWidth => 560;

  /// Login / signup / verify forms.
  double get authFormMaxWidth => isTablet ? 480 : 450;

  static DarLayoutMetrics of(BuildContext context) {
    final size = MediaQuery.sizeOf(context);
    return fromDimensions(size.width, size.height);
  }

  static DarLayoutMetrics fromDimensions(double width, double height) {
    return DarLayoutMetrics._(width, height);
  }
}
