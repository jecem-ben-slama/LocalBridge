import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';

class DocumentExplorerHeader extends StatelessWidget {
  final String locationLabel;
  final int itemCount;
  final TextEditingController searchController;
  final String searchQuery;
  final VoidCallback onClearSearch;
  final ValueChanged<String> onSearchChanged;

  const DocumentExplorerHeader({
    super.key,
    required this.locationLabel,
    required this.itemCount,
    required this.searchController,
    required this.searchQuery,
    required this.onClearSearch,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.dark,
        border: Border(bottom: BorderSide(color: colors.borderSoft)),
      ),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Icon(Icons.computer_rounded, color: colors.primary, size: 18),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  locationLabel,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: colors.text,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              Text(
                '$itemCount item${itemCount == 1 ? '' : 's'}',
                style: TextStyle(color: colors.muted, fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: searchController,
            onChanged: onSearchChanged,
            style: TextStyle(fontSize: 14, color: colors.text),
            cursorColor: colors.primary,
            decoration: InputDecoration(
              hintText: 'Search this folder',
              hintStyle: TextStyle(color: colors.mutedDark),
              prefixIcon: Icon(
                Icons.search_rounded,
                size: 20,
                color: colors.muted,
              ),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Clear search',
                      icon: Icon(
                        Icons.close_rounded,
                        size: 18,
                        color: colors.muted,
                      ),
                      onPressed: onClearSearch,
                    ),
              filled: true,
              fillColor: colors.card,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.borderSoft),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.borderSoft),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: colors.primary),
              ),
              contentPadding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
