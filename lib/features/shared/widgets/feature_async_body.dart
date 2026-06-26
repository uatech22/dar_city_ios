import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/shared/api/feature_api_client.dart';
import 'package:flutter/material.dart';

/// Loading / error wrapper for feature screens backed by [FeatureApiClient].
class FeatureAsyncBody<T> extends StatefulWidget {
  const FeatureAsyncBody({
    super.key,
    required this.future,
    required this.builder,
    this.onRetry,
    this.loading,
  });

  final Future<T> future;
  final Widget Function(BuildContext context, T data) builder;
  final VoidCallback? onRetry;
  final Widget? loading;

  @override
  State<FeatureAsyncBody<T>> createState() => _FeatureAsyncBodyState<T>();
}

class _FeatureAsyncBodyState<T> extends State<FeatureAsyncBody<T>> {
  T? _cachedData;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      future: widget.future,
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          _cachedData = snapshot.data;
        }

        if (snapshot.connectionState == ConnectionState.waiting &&
            _cachedData == null) {
          return widget.loading ??
              const Center(
                child: CircularProgressIndicator(color: DarColors.accentRed),
              );
        }
        if (snapshot.hasError && _cachedData == null) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: DarColors.accentRed, size: 40),
                  const SizedBox(height: 12),
                  Text(
                    featureErrorMessage(snapshot.error),
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white70),
                  ),
                  if (widget.onRetry != null) ...[
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: widget.onRetry,
                      style: FilledButton.styleFrom(backgroundColor: DarColors.accentRed),
                      child: const Text('Retry'),
                    ),
                  ],
                ],
              ),
            ),
          );
        }
        final data = snapshot.hasData ? snapshot.data as T : _cachedData;
        if (data == null) {
          return const Center(child: Text('No data', style: TextStyle(color: Colors.white70)));
        }
        return widget.builder(context, data);
      },
    );
  }
}

String featureErrorMessage(Object? error) {
  if (error is FeatureApiException) {
    return error.message?.toString() ?? 'Request failed (${error.statusCode})';
  }
  return error?.toString() ?? 'Something went wrong';
}

void showFeatureSnackBar(BuildContext context, String message, {bool isError = false}) {
  ScaffoldMessenger.of(context).clearSnackBars();
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      behavior: SnackBarBehavior.floating,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      backgroundColor: isError ? DarColors.accentRed : const Color(0xFF1B3D2F),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isError
              ? DarColors.accentRed
              : DarColors.greenBright.withValues(alpha: 0.5),
        ),
      ),
      content: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle_outline,
            color: isError ? Colors.white : DarColors.greenBright,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
      duration: Duration(seconds: isError ? 4 : 3),
    ),
  );
}
