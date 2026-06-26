import 'package:flutter/material.dart';

import 'package:dar_city_app/core/layout/dar_layout_metrics.dart';
import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/features/attendance/models/attendance_models.dart';
import 'package:dar_city_app/features/discipline/models/discipline_models.dart';
import 'package:dar_city_app/features/discipline/services/discipline_service.dart';
import 'package:dar_city_app/features/player/widgets/player_premium.dart';
import 'package:dar_city_app/features/shared/auto_refresh_mixin.dart';
import 'package:dar_city_app/features/shared/widgets/feature_async_body.dart';

enum _HistoryFilter { all, rewards, penalties }

class DisciplineTokenPenaltyScreen extends StatefulWidget {
  const DisciplineTokenPenaltyScreen({super.key});

  @override
  State<DisciplineTokenPenaltyScreen> createState() =>
      _DisciplineTokenPenaltyScreenState();
}

class _DisciplineTokenPenaltyScreenState extends State<DisciplineTokenPenaltyScreen>
    with TickerProviderStateMixin, AutoRefreshStateMixin {
  _HistoryFilter _filter = _HistoryFilter.all;
  late Future<DisciplineSummary> _summaryFuture;
  late PlayerMotion _motion;

  @override
  void initState() {
    super.initState();
    _motion = PlayerMotion(this);
    _load();
    startAutoRefresh(_load);
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final apiFilter = switch (_filter) {
      _HistoryFilter.all => null,
      _HistoryFilter.rewards => 'tokens',
      _HistoryFilter.penalties => 'penalties',
    };
    final future = DisciplineService.fetchPlayerDiscipline(filter: apiFilter);
    setState(() => _summaryFuture = future);
    await future;
  }

  void _setFilter(_HistoryFilter filter) {
    if (_filter == filter) return;
    setState(() => _filter = filter);
    _load();
  }

  IconData _iconForKey(String key) {
    switch (key) {
      case 'warning':
        return Icons.warning_amber_rounded;
      case 'verified':
        return Icons.verified_rounded;
      case 'schedule':
        return Icons.schedule_rounded;
      case 'calendar_today':
        return Icons.calendar_today_rounded;
      case 'fitness_center':
        return Icons.fitness_center_rounded;
      default:
        return Icons.circle;
    }
  }

  String _formatTokenChange(DisciplineHistoryItem item) {
    final raw = item.tokenChange.trim();
    if (raw.isEmpty) return item.isPenalty ? 'Penalty' : 'Reward';
    if (raw.contains('token')) return raw;
    return '$raw tokens';
  }

  @override
  Widget build(BuildContext context) {
    return PlayerScreenScaffold(
      title: 'Rewards & Penalties',
      body: FeatureAsyncBody<DisciplineSummary>(
        future: _summaryFuture,
        onRetry: _load,
        builder: (context, data) {
          final rewards = data.history.where((h) => !h.isPenalty).length;
          final penalties = data.history.where((h) => h.isPenalty).length;

          return RefreshIndicator(
            color: DarColors.accentRed,
            onRefresh: () async {
              _load();
              await _summaryFuture;
            },
            child: LayoutBuilder(
              builder: (context, constraints) {
                final maxWidth =
                    constraints.maxWidth > 640 ? 560.0 : constraints.maxWidth;

                return Align(
                  alignment: Alignment.topCenter,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(maxWidth: maxWidth),
                    child: ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: DarLayoutMetrics.of(context).scrollPadding(top: 12, bottom: 32),
                      children: [
                        PlayerHeroCard(
                          motion: _motion,
                          badge: 'DISCIPLINE',
                          title: 'Merit & conduct',
                          subtitle: 'Your token score, pay impact & history',
                          chips: [PlayerLiveChip(motion: _motion)],
                        ),
                        const SizedBox(height: 16),
                        _explainerCard(),
                        const SizedBox(height: 16),
                        _scoreCard(data.tokenBalance),
                        const SizedBox(height: 12),
                        _salaryCard(data),
                        if (data.history.isNotEmpty) ...[
                          const SizedBox(height: 12),
                          _summaryRow(rewards: rewards, penalties: penalties),
                        ],
                        const SizedBox(height: 24),
                        const PlayerSectionHeader(
                          label: 'Your history',
                          icon: Icons.history_rounded,
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Each row is one event — not your total score',
                          style: TextStyle(color: DarColors.muted, fontSize: 12),
                        ),
                        const SizedBox(height: 12),
                        _filterRow(),
                        const SizedBox(height: 12),
                        if (data.history.isEmpty)
                          _emptyHistory()
                        else
                          ...data.history.map(
                            (h) => _historyItem(h, _iconForKey(h.iconKey)),
                          ),
                      ],
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _explainerCard() {
    return PlayerPremiumTile(
      highlight: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.help_outline_rounded, color: DarColors.eliteGold, size: 20),
              const SizedBox(width: 8),
              const Text(
                'How this works',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _explainerRow(
            icon: Icons.toll_rounded,
            title: 'Merit score (big number)',
            body: 'Your running total. Good behaviour adds points; '
                'penalties take points away.',
          ),
          const SizedBox(height: 8),
          _explainerRow(
            icon: Icons.history_rounded,
            title: 'History (list below)',
            body: 'Each line is one reward or penalty — e.g. '
                '“−20 tokens” for being late, “+5” for early arrival.',
          ),
          const SizedBox(height: 8),
          _explainerRow(
            icon: Icons.payments_outlined,
            title: 'Salary impact',
            body: 'Some penalties also affect projected pay (TZS). '
                'That is separate from your merit score.',
          ),
        ],
      ),
    );
  }

  Widget _explainerRow({
    required IconData icon,
    required String title,
    required String body,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 16, color: DarColors.mutedPink),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                body,
                style: TextStyle(
                  color: DarColors.muted,
                  fontSize: 12,
                  height: 1.35,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _scoreCard(int balance) {
    final isNegative = balance < 0;
    final accent = isNegative ? DarColors.accentRedBright : DarColors.eliteGold;
    final hint = balance == 0
        ? 'No rewards or penalties recorded yet'
        : isNegative
            ? 'Below zero — improve attendance & conduct'
            : 'Keep it up — rewards boost your standing';

    return PlayerAccentCard(
      motion: _motion,
      child: Column(
        children: [
          Text(
            'YOUR MERIT SCORE',
            style: TextStyle(
              color: DarColors.muted,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$balance',
            style: TextStyle(
              color: accent,
              fontSize: 48,
              fontWeight: FontWeight.w800,
              height: 1,
            ),
          ),
          Text(
            'tokens total',
            style: TextStyle(color: DarColors.mutedPink, fontSize: 13),
          ),
          const SizedBox(height: 8),
          Text(
            hint,
            textAlign: TextAlign.center,
            style: TextStyle(color: DarColors.muted, fontSize: 12),
          ),
        ],
      ),
    );
  }

  Widget _salaryCard(DisciplineSummary data) {
    final value = data.salaryImpactValue.trim();
    final isPositive = value.startsWith('+');
    final accent = isPositive ? DarColors.greenBright : DarColors.eliteGold;

    return PlayerPremiumTile(
      accentColor: accent,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.trending_up_rounded, color: accent, size: 22),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pay impact',
                  style: TextStyle(color: DarColors.muted, fontSize: 11),
                ),
                Text(
                  value.isEmpty ? '—' : value,
                  style: TextStyle(
                    color: accent,
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                Text(
                  _friendlySalaryLabel(data.salaryImpactLabel),
                  style: TextStyle(color: DarColors.mutedPink, fontSize: 11),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _friendlySalaryLabel(String label) {
    final lower = label.toLowerCase();
    if (lower.contains('projected') || lower.contains('salary')) {
      return 'Estimated effect on your salary';
    }
    return label;
  }

  Widget _summaryRow({required int rewards, required int penalties}) {
    return Row(
      children: [
        Expanded(
          child: PlayerStatCard(
            motion: _motion,
            index: 0,
            icon: Icons.add_circle_outline_rounded,
            label: 'Rewards',
            value: '$rewards',
            color: DarColors.greenBright,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: PlayerStatCard(
            motion: _motion,
            index: 1,
            icon: Icons.remove_circle_outline_rounded,
            label: 'Penalties',
            value: '$penalties',
            color: DarColors.accentRedBright,
          ),
        ),
      ],
    );
  }

  Widget _filterRow() {
    return Row(
      children: [
        PlayerFilterChip(
          label: 'All',
          selected: _filter == _HistoryFilter.all,
          onTap: () => _setFilter(_HistoryFilter.all),
        ),
        PlayerFilterChip(
          label: 'Rewards',
          selected: _filter == _HistoryFilter.rewards,
          onTap: () => _setFilter(_HistoryFilter.rewards),
        ),
        PlayerFilterChip(
          label: 'Penalties',
          selected: _filter == _HistoryFilter.penalties,
          onTap: () => _setFilter(_HistoryFilter.penalties),
        ),
      ],
    );
  }

  Widget _emptyHistory() {
    return const PlayerEmptyState(
      icon: Icons.inbox_outlined,
      message:
          'When your coach gives you a reward or penalty, it will show up in this list.',
    );
  }

  Widget _historyItem(DisciplineHistoryItem item, IconData icon) {
    final isPenalty = item.isPenalty;
    final accent = isPenalty ? DarColors.accentRedBright : DarColors.greenBright;
    final badgeLabel = isPenalty ? 'PENALTY' : 'REWARD';
    final showMoney = item.totalAmount != null && item.totalAmount! > 0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PlayerPremiumTile(
        accentColor: accent,
        child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: accent.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: accent, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: accent.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        badgeLabel,
                        style: TextStyle(
                          color: accent,
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      item.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                      ),
                    ),
                    if (item.subtitle.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        item.subtitle,
                        style: TextStyle(color: DarColors.muted, fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    _formatTokenChange(item),
                    style: TextStyle(
                      color: accent,
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  Text(
                    'this event',
                    style: TextStyle(color: DarColors.muted, fontSize: 10),
                  ),
                ],
              ),
            ],
          ),
          if (showMoney) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Icon(Icons.payments_outlined, size: 14, color: DarColors.mutedPink),
                  const SizedBox(width: 6),
                  Text(
                    'Salary deduction: ${formatPenaltyMoney(item.totalAmount!, item.currency ?? 'TZS')}',
                    style: TextStyle(color: DarColors.mutedPink, fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
      ),
    );
  }
}
