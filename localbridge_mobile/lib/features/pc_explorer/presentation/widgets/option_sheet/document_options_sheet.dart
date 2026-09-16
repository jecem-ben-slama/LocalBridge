import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/pc_explorer/domain/entities/document_filter_sort.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/option_sheet/option_toggle.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/widgets/option_sheet/section_label.dart';

/// Bottom sheet holding grid/list toggle, type filter chips, and sort
/// choices. Callbacks fire immediately (no confirm step) so the caller's
/// state updates live while the sheet is open.
class DocumentViewOptionsSheet extends StatefulWidget {
  final bool isGridView;
  final DocumentTypeFilter typeFilter;
  final DocumentSortOption sortOption;
  final ValueChanged<bool> onGridViewChanged;
  final ValueChanged<DocumentTypeFilter> onTypeFilterChanged;
  final ValueChanged<DocumentSortOption> onSortChanged;

  const DocumentViewOptionsSheet({
    super.key,
    required this.isGridView,
    required this.typeFilter,
    required this.sortOption,
    required this.onGridViewChanged,
    required this.onTypeFilterChanged,
    required this.onSortChanged,
  });

  static const sortChoices = [
    DocumentSortOption(DocumentSortField.name, true),
    DocumentSortOption(DocumentSortField.name, false),
    DocumentSortOption(DocumentSortField.date, false),
    DocumentSortOption(DocumentSortField.date, true),
    DocumentSortOption(DocumentSortField.size, false),
    DocumentSortOption(DocumentSortField.size, true),
    DocumentSortOption(DocumentSortField.type, true),
  ];

  static Future<void> show(
    BuildContext context, {
    required bool isGridView,
    required DocumentTypeFilter typeFilter,
    required DocumentSortOption sortOption,
    required ValueChanged<bool> onGridViewChanged,
    required ValueChanged<DocumentTypeFilter> onTypeFilterChanged,
    required ValueChanged<DocumentSortOption> onSortChanged,
  }) {
    final colors = context.appColors;
    return showModalBottomSheet(
      context: context,
      backgroundColor: colors.elevated,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => DocumentViewOptionsSheet(
        isGridView: isGridView,
        typeFilter: typeFilter,
        sortOption: sortOption,
        onGridViewChanged: onGridViewChanged,
        onTypeFilterChanged: onTypeFilterChanged,
        onSortChanged: onSortChanged,
      ),
    );
  }

  @override
  State<DocumentViewOptionsSheet> createState() =>
      _DocumentViewOptionsSheetState();
}

class _DocumentViewOptionsSheetState extends State<DocumentViewOptionsSheet> {
  late bool _isGridView = widget.isGridView;
  late DocumentTypeFilter _typeFilter = widget.typeFilter;
  late DocumentSortOption _sortOption = widget.sortOption;

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return SafeArea(
      top: false,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: colors.borderSoft,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'View & sort',
                    style: TextStyle(
                      color: colors.text,
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    icon: Icon(
                      Icons.close_rounded,
                      color: colors.muted,
                      size: 20,
                    ),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              SectionLabel('View', colors: colors),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: OptionToggle(
                      label: 'Grid',
                      icon: Icons.grid_view_rounded,
                      selected: _isGridView,
                      onTap: () {
                        setState(() => _isGridView = true);
                        widget.onGridViewChanged(true);
                      },
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OptionToggle(
                      label: 'List',
                      icon: Icons.view_list_rounded,
                      selected: !_isGridView,
                      onTap: () {
                        setState(() => _isGridView = false);
                        widget.onGridViewChanged(false);
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SectionLabel('Filter', colors: colors),
              const SizedBox(height: 8),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: DocumentTypeFilter.values.map((filter) {
                  final selected = filter == _typeFilter;
                  return ChoiceChip(
                    label: Text(filter.label),
                    selected: selected,
                    selectedColor: colors.primary,
                    backgroundColor: colors.card.withValues(alpha: 0.5),
                    labelStyle: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: selected ? colors.darkest : colors.muted,
                    ),
                    side: BorderSide(color: colors.borderSoft),
                    onSelected: (_) {
                      setState(() => _typeFilter = filter);
                      widget.onTypeFilterChanged(filter);
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),
              SectionLabel('Sort by', colors: colors),
              ...DocumentViewOptionsSheet.sortChoices.map(
                (opt) => RadioListTile<DocumentSortOption>(
                  contentPadding: EdgeInsets.zero,
                  dense: true,
                  value: opt,
                  groupValue: _sortOption,
                  activeColor: colors.primary,
                  title: Text(
                    opt.label,
                    style: TextStyle(color: colors.text, fontSize: 14),
                  ),
                  onChanged: (value) {
                    setState(() => _sortOption = value!);
                    widget.onSortChanged(value!);
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

