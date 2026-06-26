import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/widgets/responsive_content.dart';
import 'package:flutter/material.dart';

/// Full-screen route body — centers and caps width on tablets.
class ResponsivePageBody extends StatelessWidget {
  const ResponsivePageBody({
    super.key,
    required this.child,
    this.maxWidth,
    this.padding,
  });

  final Widget child;
  final double? maxWidth;
  final EdgeInsets? padding;

  @override
  Widget build(BuildContext context) {
    Widget content = child;
    if (padding != null) {
      content = Padding(padding: padding!, child: content);
    }

    return ResponsiveContent(
      maxWidth: maxWidth,
      child: content,
    );
  }
}

/// Scrollable page with responsive horizontal padding and bottom clearance.
class ResponsiveScrollPage extends StatelessWidget {
  const ResponsiveScrollPage({
    super.key,
    required this.children,
    this.controller,
    this.physics,
    this.top = 12,
    this.bottom,
    this.maxWidth,
  });

  final List<Widget> children;
  final ScrollController? controller;
  final ScrollPhysics? physics;
  final double top;
  final double? bottom;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final layout = DarLayoutMetrics.of(context);

    return ResponsivePageBody(
      maxWidth: maxWidth,
      child: ListView(
        controller: controller,
        physics: physics ??
            const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
        padding: layout.scrollPadding(top: top, bottom: bottom),
        children: children,
      ),
    );
  }
}
