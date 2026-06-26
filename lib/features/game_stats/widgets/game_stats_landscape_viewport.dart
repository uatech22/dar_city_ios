import 'package:flutter/material.dart';

/// Renders [child] as a landscape console while the device stays in portrait.
///
/// The long edge of the phone becomes the horizontal width (90° rotation).
class GameStatsLandscapeViewport extends StatelessWidget {
  const GameStatsLandscapeViewport({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final mediaQuery = MediaQuery.of(context);
    if (mediaQuery.orientation == Orientation.landscape) {
      return child;
    }

    final screenSize = mediaQuery.size;
    final landscapeSize = Size(screenSize.height, screenSize.width);

    return ClipRect(
      child: Center(
        child: RotatedBox(
          quarterTurns: 1,
          child: SizedBox(
            width: landscapeSize.width,
            height: landscapeSize.height,
            child: MediaQuery(
              data: mediaQuery.copyWith(size: landscapeSize),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}
