/// Formats [dt] as "Today · 14:02", "Yesterday · 09:15", or
/// "14/9/2026 · 09:15" for older dates.
///
/// Extracted from `SharedFileTile._formatDate` — a general-purpose
/// formatting utility doesn't belong buried as a private method on a
/// single widget, and other list/tile widgets (e.g. a future PC Explorer
/// "modified date" column) can reuse it.
String formatRelativeDateTime(DateTime dt) {
  final local = dt.toLocal();
  final now = DateTime.now();
  final today = DateTime(now.year, now.month, now.day);
  final that = DateTime(local.year, local.month, local.day);
  final diff = today.difference(that).inDays;
  final time =
      '${local.hour.toString().padLeft(2, '0')}:${local.minute.toString().padLeft(2, '0')}';
  if (diff == 0) return 'Today · $time';
  if (diff == 1) return 'Yesterday · $time';
  return '${local.day}/${local.month}/${local.year} · $time';
}
