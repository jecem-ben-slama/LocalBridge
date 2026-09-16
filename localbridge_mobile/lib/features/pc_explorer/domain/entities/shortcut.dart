import 'package:flutter/material.dart';

/// Icon choices for shortcuts. Kept as an enum (rather than storing
/// IconData directly) so shortcuts can be serialized to JSON safely.
enum ShortcutIcon {
  desktop,
  downloads,
  documents,
  pictures,
  music,
  videos,
  folder,
  star,
  work,
  games,
  code,
}

extension ShortcutIconX on ShortcutIcon {
  IconData get data {
    switch (this) {
      case ShortcutIcon.desktop:
        return Icons.desktop_windows_rounded;
      case ShortcutIcon.downloads:
        return Icons.download_rounded;
      case ShortcutIcon.documents:
        return Icons.description_rounded;
      case ShortcutIcon.pictures:
        return Icons.image_rounded;
      case ShortcutIcon.music:
        return Icons.music_note_rounded;
      case ShortcutIcon.videos:
        return Icons.movie_rounded;
      case ShortcutIcon.folder:
        return Icons.folder_rounded;
      case ShortcutIcon.star:
        return Icons.star_rounded;
      case ShortcutIcon.work:
        return Icons.work_rounded;
      case ShortcutIcon.games:
        return Icons.sports_esports_rounded;
      case ShortcutIcon.code:
        return Icons.code_rounded;
    }
  }

  String get label {
    switch (this) {
      case ShortcutIcon.desktop:
        return 'Desktop';
      case ShortcutIcon.downloads:
        return 'Downloads';
      case ShortcutIcon.documents:
        return 'Documents';
      case ShortcutIcon.pictures:
        return 'Pictures';
      case ShortcutIcon.music:
        return 'Music';
      case ShortcutIcon.videos:
        return 'Videos';
      case ShortcutIcon.folder:
        return 'Folder';
      case ShortcutIcon.star:
        return 'Favorite';
      case ShortcutIcon.work:
        return 'Work';
      case ShortcutIcon.games:
        return 'Games';
      case ShortcutIcon.code:
        return 'Code';
    }
  }
}

/// A saved jump-to location in the PC's file tree. There are no
/// built-ins anymore — every shortcut is user-created.
class PcShortcut {
  final String id;
  final String name;
  final String? path;
  final ShortcutIcon icon;

  const PcShortcut({
    required this.id,
    required this.name,
    required this.path,
    required this.icon,
  });

  factory PcShortcut.custom({
    required String name,
    required String path,
    required ShortcutIcon icon,
  }) {
    return PcShortcut(
      id: 'custom_${DateTime.now().microsecondsSinceEpoch}',
      name: name,
      path: path,
      icon: icon,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'path': path,
    'icon': icon.name,
  };

  factory PcShortcut.fromJson(Map<String, dynamic> json) => PcShortcut(
    id: json['id'] as String,
    name: json['name'] as String,
    path: json['path'] as String?,
    icon: ShortcutIcon.values.firstWhere(
      (e) => e.name == json['icon'],
      orElse: () => ShortcutIcon.folder,
    ),
  );
}
