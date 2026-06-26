import 'package:dar_city_app/core/theme/dar_theme.dart';
import 'package:flutter/material.dart';

class MultiSelectOption<T extends Object> {
  const MultiSelectOption({
    required this.id,
    required this.title,
    this.subtitle,
    this.leading,
  });

  final T id;
  final String title;
  final String? subtitle;
  final Widget? leading;
}

/// Compact tap field that opens a searchable multi-select bottom sheet.
class DarMultiSelectField<T extends Object> extends StatelessWidget {
  const DarMultiSelectField({
    super.key,
    required this.label,
    required this.options,
    required this.selectedIds,
    required this.onChanged,
    this.placeholder = 'Tap to select',
    this.searchHint = 'Search...',
    this.emptyMessage = 'No matches found',
  });

  final String label;
  final List<MultiSelectOption<T>> options;
  final Set<T> selectedIds;
  final ValueChanged<Set<T>> onChanged;
  final String placeholder;
  final String searchHint;
  final String emptyMessage;

  List<MultiSelectOption<T>> get _selectedOptions =>
      options.where((o) => selectedIds.contains(o.id)).toList();

  String get _summary {
    final count = selectedIds.length;
    if (count == 0) return placeholder;
    if (count == 1) return _selectedOptions.first.title;
    return '$count selected';
  }

  Future<void> _openSheet(BuildContext context) async {
    final result = await showModalBottomSheet<Set<T>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: DarColors.cardDark,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => _MultiSelectSheet<T>(
        title: label,
        options: options,
        initialSelected: Set<T>.from(selectedIds),
        searchHint: searchHint,
        emptyMessage: emptyMessage,
      ),
    );
    if (result != null) onChanged(result);
  }

  @override
  Widget build(BuildContext context) {
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
        const SizedBox(height: 8),
        Material(
          color: DarColors.inputBrown,
          borderRadius: BorderRadius.circular(12),
          child: InkWell(
            onTap: () => _openSheet(context),
            borderRadius: BorderRadius.circular(12),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      _summary,
                      style: TextStyle(
                        color: selectedIds.isEmpty
                            ? DarColors.muted
                            : Colors.white,
                        fontSize: 15,
                        fontWeight: selectedIds.isEmpty
                            ? FontWeight.w400
                            : FontWeight.w600,
                      ),
                    ),
                  ),
                  Icon(Icons.unfold_more, color: DarColors.muted, size: 22),
                ],
              ),
            ),
          ),
        ),
        if (_selectedOptions.isNotEmpty) ...[
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: _selectedOptions.map((option) {
              return InputChip(
                label: Text(
                  option.title,
                  style: const TextStyle(color: Colors.white, fontSize: 12),
                ),
                backgroundColor: DarColors.cardBrown,
                deleteIconColor: DarColors.muted,
                side: BorderSide(color: DarColors.muted.withValues(alpha: 0.3)),
                onDeleted: () {
                  final next = Set<T>.from(selectedIds)..remove(option.id);
                  onChanged(next);
                },
              );
            }).toList(),
          ),
        ],
      ],
    );
  }
}

class _MultiSelectSheet<T extends Object> extends StatefulWidget {
  const _MultiSelectSheet({
    required this.title,
    required this.options,
    required this.initialSelected,
    required this.searchHint,
    required this.emptyMessage,
  });

  final String title;
  final List<MultiSelectOption<T>> options;
  final Set<T> initialSelected;
  final String searchHint;
  final String emptyMessage;

  @override
  State<_MultiSelectSheet<T>> createState() => _MultiSelectSheetState<T>();
}

class _MultiSelectSheetState<T extends Object> extends State<_MultiSelectSheet<T>> {
  late Set<T> _selected;
  String _query = '';

  @override
  void initState() {
    super.initState();
    _selected = Set<T>.from(widget.initialSelected);
  }

  List<MultiSelectOption<T>> get _filtered {
    if (_query.trim().isEmpty) return widget.options;
    final q = _query.toLowerCase();
    return widget.options.where((o) {
      return o.title.toLowerCase().contains(q) ||
          (o.subtitle?.toLowerCase().contains(q) ?? false);
    }).toList();
  }

  void _toggleAll(bool selectAll) {
    setState(() {
      if (selectAll) {
        _selected = _filtered.map((o) => o.id).toSet();
      } else {
        for (final o in _filtered) {
          _selected.remove(o.id);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    final allFilteredSelected = filtered.isNotEmpty &&
        filtered.every((o) => _selected.contains(o.id));

    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.72,
      minChildSize: 0.45,
      maxChildSize: 0.92,
      builder: (_, scrollController) {
        return Column(
          children: [
            const SizedBox(height: 10),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: DarColors.muted.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Cancel'),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: TextField(
                onChanged: (v) => setState(() => _query = v),
                style: const TextStyle(color: Colors.white),
                decoration: InputDecoration(
                  hintText: widget.searchHint,
                  hintStyle: TextStyle(color: DarColors.muted),
                  prefixIcon: Icon(Icons.search, color: DarColors.muted),
                  filled: true,
                  fillColor: DarColors.inputBrown,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 0),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${_selected.length} selected',
                    style: TextStyle(color: DarColors.muted, fontSize: 13),
                  ),
                  TextButton(
                    onPressed: filtered.isEmpty
                        ? null
                        : () => _toggleAll(!allFilteredSelected),
                    child: Text(
                      allFilteredSelected ? 'Clear filtered' : 'Select all',
                      style: const TextStyle(color: DarColors.accentRed),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: filtered.isEmpty
                  ? Center(
                      child: Text(
                        widget.emptyMessage,
                        style: TextStyle(color: DarColors.muted),
                      ),
                    )
                  : ListView.separated(
                      controller: scrollController,
                      padding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
                      itemCount: filtered.length,
                      separatorBuilder: (_, __) => Divider(
                        height: 1,
                        color: DarColors.muted.withValues(alpha: 0.15),
                      ),
                      itemBuilder: (_, index) {
                        final option = filtered[index];
                        final checked = _selected.contains(option.id);
                        return CheckboxListTile(
                          value: checked,
                          activeColor: DarColors.accentRed,
                          checkColor: Colors.white,
                          side: BorderSide(color: DarColors.muted),
                          title: Text(
                            option.title,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          subtitle: option.subtitle != null
                              ? Text(
                                  option.subtitle!,
                                  style: TextStyle(
                                    color: DarColors.muted,
                                    fontSize: 13,
                                  ),
                                )
                              : null,
                          secondary: option.leading,
                          onChanged: (_) {
                            setState(() {
                              if (checked) {
                                _selected.remove(option.id);
                              } else {
                                _selected.add(option.id);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () => Navigator.pop(context, _selected),
                    style: FilledButton.styleFrom(
                      backgroundColor: DarColors.accentRed,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      _selected.isEmpty
                          ? 'Done'
                          : 'Done (${_selected.length})',
                      style: const TextStyle(fontWeight: FontWeight.w700),
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
