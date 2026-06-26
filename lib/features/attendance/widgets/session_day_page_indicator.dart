import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import 'package:dar_city_app/core/theme/dar_theme.dart';

/// Page dots for multi-day session pickers — shrinks, scrolls, or shows a counter
/// when there are too many pages for the available width.
class SessionDayPageIndicator extends StatefulWidget {
  const SessionDayPageIndicator({
    super.key,
    required this.totalPages,
    required this.currentPage,
    required this.onPageSelected,
  });

  final int totalPages;
  final int currentPage;
  final ValueChanged<int> onPageSelected;

  @override
  State<SessionDayPageIndicator> createState() =>
      _SessionDayPageIndicatorState();
}

class _SessionDayPageIndicatorState extends State<SessionDayPageIndicator> {
  final _scrollController = ScrollController();
  final _dotKeys = <int, GlobalKey>{};

  @override
  void initState() {
    super.initState();
    _scheduleScrollToActive();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(SessionDayPageIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentPage != widget.currentPage ||
        oldWidget.totalPages != widget.totalPages) {
      _scheduleScrollToActive();
    }
  }

  void _scheduleScrollToActive() {
    SchedulerBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      _scrollToActive();
    });
  }

  void _scrollToActive() {
    final key = _dotKeys[widget.currentPage];
    final ctx = key?.currentContext;
    if (ctx == null) return;
    Scrollable.ensureVisible(
      ctx,
      alignment: 0.5,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.totalPages <= 1) return const SizedBox.shrink();

    return LayoutBuilder(
      builder: (context, constraints) {
        final maxWidth = constraints.maxWidth;
        final useCounter = _shouldUseCounter(widget.totalPages, maxWidth);

        if (useCounter) {
          return Center(child: _pageCounter());
        }

        final compact =
            widget.totalPages * _dotSlotWidth(compact: false) > maxWidth;
        final dotHeight = compact ? 5.0 : 6.0;
        final inactiveWidth = compact ? 5.0 : 6.0;
        final activeWidth = compact ? 14.0 : 18.0;
        final margin = compact ? 2.0 : 3.0;

        final dots = Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(widget.totalPages, (i) {
            _dotKeys.putIfAbsent(i, GlobalKey.new);
            final active = i == widget.currentPage;
            return GestureDetector(
              key: _dotKeys[i],
              onTap: () => widget.onPageSelected(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: active ? activeWidth : inactiveWidth,
                height: dotHeight,
                margin: EdgeInsets.symmetric(horizontal: margin),
                decoration: BoxDecoration(
                  color: active
                      ? DarColors.accentRed
                      : DarColors.muted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(dotHeight / 2),
                ),
              ),
            );
          }),
        );

        if (!compact) {
          return Center(child: dots);
        }

        return SingleChildScrollView(
          controller: _scrollController,
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          child: dots,
        );
      },
    );
  }

  double _dotSlotWidth({required bool compact}) {
    final inactive = compact ? 5.0 : 6.0;
    final margin = compact ? 2.0 : 3.0;
    return inactive + margin * 2;
  }

  bool _shouldUseCounter(int totalPages, double maxWidth) {
    if (totalPages > 20) return true;
    return totalPages * _dotSlotWidth(compact: true) > maxWidth * 1.35;
  }

  Widget _pageCounter() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: DarColors.cardDark,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: DarColors.muted.withValues(alpha: 0.2)),
      ),
      child: Text(
        'Page ${widget.currentPage + 1} of ${widget.totalPages}',
        style: TextStyle(
          color: DarColors.muted,
          fontSize: 11,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}
