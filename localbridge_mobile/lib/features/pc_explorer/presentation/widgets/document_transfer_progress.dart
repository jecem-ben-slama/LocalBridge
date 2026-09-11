import 'package:flutter/material.dart';

class DocumentTransferProgress extends StatelessWidget {
  final String label;
  final String fileName;
  final double progress;
  final Color color;
  final VoidCallback? onCancel;

  const DocumentTransferProgress({
    super.key,
    required this.label,
    required this.fileName,
    required this.progress,
    required this.color,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        LinearProgressIndicator(value: progress, color: color),
        Padding(
          padding: const EdgeInsets.all(8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  '$label $fileName...',
                  style: const TextStyle(color: Colors.grey, fontSize: 11),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (onCancel != null)
                SizedBox(
                  width: 80,
                  height: 32,
                  child: ElevatedButton.icon(
                    onPressed: onCancel,
                    icon: const Icon(Icons.close, size: 16),
                    label: const Text('Cancel', style: TextStyle(fontSize: 11)),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red.withValues(alpha: 0.7),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 8),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
