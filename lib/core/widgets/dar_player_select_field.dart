import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:dar_city_app/core/widgets/dar_widgets.dart';
import 'package:dar_city_app/models/person.dart';
import 'package:flutter/material.dart';

/// Single-player roster picker — compact field + searchable bottom sheet with filters.
class DarPlayerSelectField extends StatelessWidget {
  const DarPlayerSelectField({
    super.key,
    required this.players,
    required this.selectedId,
    required this.onChanged,
    this.label = 'Select Player',
    this.placeholder = 'Tap to search or pick from squad',
    this.searchHint = 'Search name, jersey #, or position',
    this.emptyMessage = 'No players match your search',
  });

  final List<Person> players;
  final int? selectedId;
  final ValueChanged<int?> onChanged;
  final String label;
  final String placeholder;
  final String searchHint;
  final String emptyMessage;

  Person? get _selected =>
      selectedId == null ? null : players.where((p) => p.id == selectedId).firstOrNull;

  Future<void> _openSheet(BuildContext context) async {
    final result = await showModalBottomSheet<int>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DarColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _PlayerSelectSheet(
        title: label,
        players: players,
        initialSelectedId: selectedId,
        searchHint: searchHint,
        emptyMessage: emptyMessage,
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
    final selected = _selected;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
        const SizedBox(height: 10),
        Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: () => _openSheet(context),
            borderRadius: BorderRadius.circular(16),
            child: Ink(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: selected != null
                      ? [
                          DarColors.accentRed.withValues(alpha: 0.22),
                          DarColors.cardDark,
                        ]
                      : [DarColors.cardDark, DarColors.surfaceElevated],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border.all(
                  color: selected != null
                      ? DarColors.accentRed.withValues(alpha: 0.65)
                      : DarColors.muted.withValues(alpha: 0.25),
                  width: selected != null ? 1.5 : 1,
                ),
                boxShadow: selected != null
                    ? [
                        BoxShadow(
                          color: DarColors.accentRed.withValues(alpha: 0.18),
                          blurRadius: 18,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                child: Row(
                  children: [
                    if (selected != null) ...[
                      Stack(
                        clipBehavior: Clip.none,
                        children: [
                          DarPlayerAvatar(
                            name: selected.fullName,
                            size: 46,
                            imageUrl: selected.image,
                          ),
                          Positioned(
                            right: -2,
                            bottom: -2,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(
                                color: DarColors.accentRed,
                                shape: BoxShape.circle,
                              ),
                              child: const Icon(Icons.check, size: 10, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              selected.fullName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 15,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '#${selected.jerseyNumber ?? '—'} · ${selected.position.isNotEmpty ? selected.position : 'Squad'}',
                              style: TextStyle(color: DarColors.muted, fontSize: 12),
                            ),
                          ],
                        ),
                      ),
                      TextButton(
                        onPressed: () => onChanged(null),
                        style: TextButton.styleFrom(
                          foregroundColor: DarColors.muted,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                          minimumSize: Size.zero,
                          tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                        ),
                        child: const Text('Clear'),
                      ),
                    ] else ...[
                      Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: DarColors.surface,
                          border: Border.all(
                            color: DarColors.muted.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Icon(Icons.person_search, color: DarColors.muted, size: 22),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          placeholder,
                          style: TextStyle(
                            color: DarColors.muted,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                    Icon(Icons.keyboard_arrow_up_rounded, color: DarColors.accentRed, size: 26),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _PlayerSelectSheet extends StatefulWidget {
  const _PlayerSelectSheet({
    required this.title,
    required this.players,
    required this.initialSelectedId,
    required this.searchHint,
    required this.emptyMessage,
  });

  final String title;
  final List<Person> players;
  final int? initialSelectedId;
  final String searchHint;
  final String emptyMessage;

  @override
  State<_PlayerSelectSheet> createState() => _PlayerSelectSheetState();
}

class _PlayerSelectSheetState extends State<_PlayerSelectSheet> {
  late int? _selectedId;
  String _query = '';
  String _positionFilter = 'All';

  @override
  void initState() {
    super.initState();
    _selectedId = widget.initialSelectedId;
  }

  List<String> get _positions {
    final set = <String>{};
    for (final p in widget.players) {
      final pos = p.position.trim();
      if (pos.isNotEmpty) set.add(pos);
    }
    final list = set.toList()..sort();
    return ['All', ...list];
  }

  List<Person> get _filtered {
    final q = _query.trim().toLowerCase();
    return widget.players.where((p) {
      if (_positionFilter != 'All' && p.position != _positionFilter) return false;
      if (q.isEmpty) return true;
      final jersey = p.jerseyNumber?.toString() ?? '';
      return p.fullName.toLowerCase().contains(q) ||
          p.position.toLowerCase().contains(q) ||
          jersey.contains(q) ||
          p.firstName.toLowerCase().contains(q) ||
          p.lastName.toLowerCase().contains(q);
    }).toList()
      ..sort((a, b) {
        final aj = a.jerseyNumber ?? 999;
        final bj = b.jerseyNumber ?? 999;
        if (aj != bj) return aj.compareTo(bj);
        return a.fullName.compareTo(b.fullName);
      });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final bottomInset = MediaQuery.viewInsetsOf(context).bottom;

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.78,
      minChildSize: 0.5,
      maxChildSize: 0.94,
      builder: (_, scrollController) {
        return Column(
          children: [
              const SizedBox(height: 10),
              Container(
                width: 44,
                height: 4,
                decoration: BoxDecoration(
                  color: DarColors.muted.withValues(alpha: 0.35),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 12, 4),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${widget.players.length} squad members',
                            style: TextStyle(color: DarColors.muted, fontSize: 13),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => Navigator.pop(context),
                      icon: Icon(Icons.close, color: DarColors.muted),
                    ),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(14),
                    gradient: LinearGradient(
                      colors: [
                        DarColors.accentRed.withValues(alpha: 0.35),
                        DarColors.muted.withValues(alpha: 0.15),
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(1.2),
                    child: TextField(
                      autofocus: true,
                      onChanged: (v) => setState(() => _query = v),
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        hintText: widget.searchHint,
                        hintStyle: TextStyle(color: DarColors.muted, fontSize: 14),
                        prefixIcon: Icon(Icons.search_rounded, color: DarColors.accentRed),
                        suffixIcon: _query.isNotEmpty
                            ? IconButton(
                                onPressed: () => setState(() => _query = ''),
                                icon: Icon(Icons.clear_rounded, color: DarColors.muted, size: 20),
                              )
                            : null,
                        filled: true,
                        fillColor: DarColors.cardDark,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(13),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ),
              ),
              if (_positions.length > 2) ...[
                const SizedBox(height: 14),
                SizedBox(
                  height: 36,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    itemCount: _positions.length,
                    separatorBuilder: (_, __) => const SizedBox(width: 8),
                    itemBuilder: (_, i) {
                      final pos = _positions[i];
                      final active = _positionFilter == pos;
                      return FilterChip(
                        label: Text(pos),
                        selected: active,
                        showCheckmark: false,
                        labelStyle: TextStyle(
                          color: active ? Colors.white : DarColors.muted,
                          fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 12,
                        ),
                        backgroundColor: DarColors.cardDark,
                        selectedColor: DarColors.accentRed.withValues(alpha: 0.85),
                        side: BorderSide(
                          color: active
                              ? DarColors.accentRed
                              : DarColors.muted.withValues(alpha: 0.25),
                        ),
                        onSelected: (_) => setState(() => _positionFilter = pos),
                      );
                    },
                  ),
                ),
              ],
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 6),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${filtered.length} shown',
                      style: TextStyle(color: DarColors.muted, fontSize: 12),
                    ),
                    if (_selectedId != null)
                      Text(
                        '1 selected',
                        style: TextStyle(
                          color: DarColors.accentRed,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                child: filtered.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.person_off_outlined, size: 40, color: DarColors.muted),
                            const SizedBox(height: 10),
                            Text(widget.emptyMessage, style: TextStyle(color: DarColors.muted)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: scrollController,
                        padding: EdgeInsets.fromLTRB(16, 0, 16, 12 + bottomInset),
                        itemCount: filtered.length,
                        itemBuilder: (_, index) {
                          final p = filtered[index];
                          final selected = _selectedId == p.id;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Material(
                              color: Colors.transparent,
                              child: InkWell(
                                onTap: () => setState(() => _selectedId = p.id),
                                borderRadius: BorderRadius.circular(16),
                                child: AnimatedContainer(
                                  duration: const Duration(milliseconds: 200),
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(16),
                                    gradient: selected
                                        ? LinearGradient(
                                            colors: [
                                              DarColors.accentRed.withValues(alpha: 0.2),
                                              DarColors.cardBrown,
                                            ],
                                            begin: Alignment.centerLeft,
                                            end: Alignment.centerRight,
                                          )
                                        : null,
                                    color: selected ? null : DarColors.cardDark,
                                    border: Border.all(
                                      color: selected
                                          ? DarColors.accentRed.withValues(alpha: 0.7)
                                          : DarColors.muted.withValues(alpha: 0.12),
                                      width: selected ? 1.5 : 1,
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      DarPlayerAvatar(
                                        name: p.fullName,
                                        size: 48,
                                        imageUrl: p.image,
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              p.fullName,
                                              style: TextStyle(
                                                color: Colors.white,
                                                fontWeight: selected
                                                    ? FontWeight.w700
                                                    : FontWeight.w600,
                                                fontSize: 15,
                                              ),
                                            ),
                                            const SizedBox(height: 3),
                                            Text(
                                              '#${p.jerseyNumber ?? '—'} · ${p.position.isNotEmpty ? p.position : 'Squad'}',
                                              style: TextStyle(
                                                color: DarColors.muted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      AnimatedContainer(
                                        duration: const Duration(milliseconds: 200),
                                        width: 26,
                                        height: 26,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: selected
                                              ? DarColors.accentRed
                                              : Colors.transparent,
                                          border: Border.all(
                                            color: selected
                                                ? DarColors.accentRed
                                                : DarColors.muted.withValues(alpha: 0.45),
                                            width: 2,
                                          ),
                                        ),
                                        child: selected
                                            ? const Icon(Icons.check, size: 14, color: Colors.white)
                                            : null,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
              SafeArea(
                top: false,
                child: Padding(
                  padding: EdgeInsets.fromLTRB(20, 8, 20, 16 + bottomInset),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: _selectedId == null
                          ? null
                          : () => Navigator.pop(context, _selectedId),
                      style: FilledButton.styleFrom(
                        backgroundColor: DarColors.accentRed,
                        disabledBackgroundColor: DarColors.cardBrown,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: Text(
                        _selectedId == null ? 'Select a player' : 'Confirm player',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ),
                ),
              ),
            ],
        );
      },
    );
  }
}
