import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:flutter/material.dart';

/// Centers page content and caps width on tablets / wide screens.
class ResponsiveContent extends StatelessWidget {
  const ResponsiveContent({
    super.key,
    required this.child,
    this.alignment = Alignment.topCenter,
    this.maxWidth,
  });

  final Widget child;
  final Alignment alignment;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final metrics = DarLayoutMetrics.of(context);
        final cap = maxWidth ?? metrics.maxContentWidth;
        final width = metrics.contentWidthFor(constraints.maxWidth, cap: cap);

        if (width >= constraints.maxWidth) {
          return child;
        }

        return Align(
          alignment: alignment,
          child: SizedBox(
            width: width,
            child: child,
          ),
        );
      },
    );
  }
}
