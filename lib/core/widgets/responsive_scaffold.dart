import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/widgets/responsive_content.dart';
import 'package:flutter/material.dart';

/// Centers scaffold body on tablets. Set [fullBleed] for landscape game console, etc.
Widget darResponsiveBody(
  Widget child, {
  double? maxWidth,
  bool fullBleed = false,
}) {
  if (fullBleed) return child;
  return ResponsiveContent(maxWidth: maxWidth, child: child);
}

/// Auth / login forms — narrow centered column.
class ResponsiveAuthShell extends StatelessWidget {
  const ResponsiveAuthShell({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final maxW = DarLayoutMetrics.of(context).authFormMaxWidth;
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxW),
        child: child,
      ),
    );
  }
}

/// Drop-in [Scaffold] with responsive body wrapping.
class DarResponsiveScaffold extends StatelessWidget {
  const DarResponsiveScaffold({
    super.key,
    this.appBar,
    required this.body,
    this.backgroundColor,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.resizeToAvoidBottomInset,
    this.fullBleed = false,
    this.maxBodyWidth,
  });

  final PreferredSizeWidget? appBar;
  final Widget body;
  final Color? backgroundColor;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final bool? resizeToAvoidBottomInset;
  final bool fullBleed;
  final double? maxBodyWidth;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: appBar,
      backgroundColor: backgroundColor,
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      body: darResponsiveBody(
        body,
        fullBleed: fullBleed,
        maxWidth: maxBodyWidth,
      ),
    );
  }
}
