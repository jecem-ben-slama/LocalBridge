import 'package:flutter/material.dart';

class EmptyDocumentState extends StatelessWidget {
  final bool isSearching;
  final VoidCallback onClearSearch;

  const EmptyDocumentState({
    super.key,
    required this.isSearching,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSearching ? Icons.search_off : Icons.folder_open,
              color: Colors.white24,
              size: 56,
            ),
            const SizedBox(height: 14),
            Text(
              isSearching ? 'No matching files' : 'This folder is empty',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              isSearching
                  ? 'Try a different name or clear the search.'
                  : 'Upload a file or choose another folder.',
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.white54, fontSize: 13),
            ),
            if (isSearching) ...[
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: onClearSearch,
                icon: const Icon(Icons.clear),
                label: const Text('Clear search'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
