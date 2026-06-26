import 'package:flutter/material.dart';

import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/coach/models/training_session.dart';
import 'package:dar_city_app/features/coach/services/coach_training_session_service.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

/// Link to an upcoming training session (drill create / assign / attendance).
class TrainingSessionPicker extends StatefulWidget {
  const TrainingSessionPicker({
    super.key,
    required this.selectedTrainingId,
    required this.onChanged,
    this.label = 'Training session (optional)',
    this.hint = 'Auto — uses default session',
    this.required = false,
    this.includeAllSessions = false,
    this.sessions,
  });

  final String? selectedTrainingId;
  final ValueChanged<String?> onChanged;
  final String label;
  final String hint;
  final bool required;
  /// When true, loads upcoming + past sessions (matches Drills hub filter).
  final bool includeAllSessions;
  /// When set, skips internal fetch (use for screens that already load sessions).
  final List<TrainingSession>? sessions;

  @override
  State<TrainingSessionPicker> createState() => _TrainingSessionPickerState();
}

class _TrainingSessionPickerState extends State<TrainingSessionPicker> {
  Future<List<TrainingSession>>? _sessionsFuture;

  @override
  void initState() {
    super.initState();
    if (widget.sessions == null) {
      _sessionsFuture = _loadSessions();
    }
  }

  @override
  void didUpdateWidget(covariant TrainingSessionPicker oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.sessions == null && oldWidget.sessions != null) {
      _sessionsFuture = _loadSessions();
    }
  }

  Future<List<TrainingSession>> _loadSessions() async {
    if (!widget.includeAllSessions) {
      return CoachTrainingSessionService.fetchSessions(status: 'upcoming');
    }
    final results = await Future.wait([
      CoachTrainingSessionService.fetchSessions(status: 'upcoming'),
      CoachTrainingSessionService.fetchSessions(status: 'past'),
    ]);
    final byId = <String, TrainingSession>{};
    for (final session in [...results[0], ...results[1]]) {
      byId[session.id] = session;
    }
    return byId.values.toList();
  }

  void _reload() {
    setState(() {
      _sessionsFuture = _loadSessions();
    });
  }

  String _sessionLabel(TrainingSession session) =>
      '${session.title} · ${session.subtitle}';

  Widget _labelText(String text, {Color color = Colors.white}) {
    return Text(
      text,
      style: TextStyle(color: color),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
      softWrap: false,
    );
  }

  InputDecoration _fieldDecoration() {
    return InputDecoration(
      filled: true,
      fillColor: DarColors.inputBrown,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide.none,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.sessions != null) {
      return _buildPicker(widget.sessions!);
    }

    return FeatureAsyncBody<List<TrainingSession>>(
      future: _sessionsFuture!,
      onRetry: _reload,
      loading: _loadingBox(),
      builder: (_, sessions) => _buildPicker(sessions),
    );
  }

  Widget _loadingBox() {
    return Container(
      height: 52,
      alignment: Alignment.centerLeft,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: DarColors.inputBrown,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const SizedBox(
        width: 22,
        height: 22,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          color: DarColors.accentRed,
        ),
      ),
    );
  }

  Widget _buildPicker(List<TrainingSession> sessions) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 8),
        _dropdown(sessions),
      ],
    );
  }

  Widget _dropdown(List<TrainingSession> sessions) {
    if (sessions.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: DarColors.inputBrown,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          widget.required
              ? 'No sessions — create one in the Session tab first'
              : 'No sessions available',
          style: TextStyle(color: DarColors.muted, fontSize: 13),
        ),
      );
    }

    final validValue = widget.selectedTrainingId != null &&
            sessions.any((s) => s.id == widget.selectedTrainingId)
        ? widget.selectedTrainingId
        : null;

    final optionalItem = DropdownMenuItem<String?>(
      value: null,
      child: _labelText(widget.hint, color: Colors.white70),
    );
    final sessionItems = sessions
        .map(
          (s) => DropdownMenuItem<String?>(
            value: s.id,
            child: _labelText(_sessionLabel(s)),
          ),
        )
        .toList();

    return DropdownButtonFormField<String?>(
      isExpanded: true,
      value: validValue,
      dropdownColor: DarColors.cardDark,
      decoration: _fieldDecoration(),
      hint: _labelText(widget.hint, color: Colors.white54),
      selectedItemBuilder: (context) => widget.required
          ? sessions.map((s) => _labelText(_sessionLabel(s))).toList()
          : [
              _labelText(widget.hint, color: Colors.white70),
              ...sessions.map((s) => _labelText(_sessionLabel(s))),
            ],
      items: widget.required ? sessionItems : [optionalItem, ...sessionItems],
      onChanged: widget.onChanged,
    );
  }
}
