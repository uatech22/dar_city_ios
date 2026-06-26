import 'dart:async';

import 'package:dar_city_app/config/api_config.dart';
import 'package:flutter/material.dart';

/// Polls the backend on an interval while the screen is mounted.
/// Skips a tick if the previous refresh is still in flight (avoids stacked requests).
mixin AutoRefreshStateMixin<T extends StatefulWidget> on State<T> {
  Timer? _autoRefreshTimer;
  bool _refreshInFlight = false;

  /// [onRefresh] must return a [Future] that completes when the fetch finishes.
  /// Defaults to [ApiConfig.refreshIntervalSlow] (50s) for list/dashboard screens.
  void startAutoRefresh(
    Future<void> Function() onRefresh, {
    Duration interval = ApiConfig.refreshIntervalSlow,
  }) {
    _autoRefreshTimer?.cancel();
    _autoRefreshTimer = Timer.periodic(interval, (_) {
      if (!mounted || _refreshInFlight) return;
      _refreshInFlight = true;
      onRefresh().whenComplete(() {
        if (mounted) _refreshInFlight = false;
      });
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }
}
