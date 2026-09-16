import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:localbridge_mobile/features/pc_explorer/domain/entities/shortcut.dart';

/// Loads/persists the user's custom shortcuts. There are no built-ins —
/// every shortcut is created by the user. Deliberately not registered
/// in the DI container — it's cheap, local-only state scoped to one
/// screen.
class ShortcutsController extends ChangeNotifier {
  static const _prefsKey = 'pc_explorer_custom_shortcuts';

  List<PcShortcut> _custom = [];
  bool _loaded = false;

  List<PcShortcut> get all => _custom;
  bool get isLoaded => _loaded;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getStringList(_prefsKey) ?? [];
      _custom = raw
          .map(
            (s) => PcShortcut.fromJson(jsonDecode(s) as Map<String, dynamic>),
          )
          .toList();
    } catch (_) {
      _custom = [];
    } finally {
      _loaded = true;
      notifyListeners();
    }
  }

  Future<void> add({
    required String name,
    required String path,
    required ShortcutIcon icon,
  }) async {
    _custom = [
      ..._custom,
      PcShortcut.custom(name: name, path: path, icon: icon),
    ];
    notifyListeners();
    await _persist();
  }

  Future<void> remove(String id) async {
    _custom = _custom.where((s) => s.id != id).toList();
    notifyListeners();
    await _persist();
  }

  /// Adds [path] as a shortcut if it isn't pinned yet, otherwise removes
  /// its existing shortcut. Used by the folder long-press quick-pin,
  /// which has no dialog, so it defaults to a plain folder icon.
  Future<bool> togglePin({required String path, required String name}) async {
    final existing = _custom.where((s) => s.path == path).toList();
    if (existing.isNotEmpty) {
      await remove(existing.first.id);
      return false; // now unpinned
    }
    await add(name: name, path: path, icon: ShortcutIcon.folder);
    return true; // now pinned
  }

  bool isPinned(String path) => _custom.any((s) => s.path == path);

  Future<void> _persist() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setStringList(
      _prefsKey,
      _custom.map((s) => jsonEncode(s.toJson())).toList(),
    );
  }
}
