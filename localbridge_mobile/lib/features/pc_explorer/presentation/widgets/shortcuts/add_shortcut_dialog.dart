import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/pc_explorer/domain/entities/shortcut.dart';

/// Form dialog for naming a new shortcut and picking an icon for it.
/// When [initialPath] is provided (pinning the folder you're currently
/// in), the path field is pre-filled and the name defaults to the
/// folder's last path segment; both stay editable.
class AddShortcutDialog extends StatefulWidget {
  final String? initialPath;

  const AddShortcutDialog({super.key, this.initialPath});

  static Future<({String name, String path, ShortcutIcon icon})?> show(
    BuildContext context, {
    String? initialPath,
  }) {
    return showDialog(
      context: context,
      builder: (_) => AddShortcutDialog(initialPath: initialPath),
    );
  }

  @override
  State<AddShortcutDialog> createState() => _AddShortcutDialogState();
}

class _AddShortcutDialogState extends State<AddShortcutDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _pathController;
  ShortcutIcon _selectedIcon = ShortcutIcon.folder;

  @override
  void initState() {
    super.initState();
    final path = widget.initialPath;
    _nameController = TextEditingController(
      text: (path != null && path.isNotEmpty) ? path.split('/').last : '',
    );
    _pathController = TextEditingController(text: path ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _pathController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return AlertDialog(
      backgroundColor: colors.elevated,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      contentPadding: const EdgeInsets.fromLTRB(24, 16, 24, 8),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: colors.primary.withOpacity(0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(_selectedIcon.data, color: colors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          Text(
            'New shortcut',
            style: TextStyle(
              color: colors.text,
              fontSize: 18,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
      content: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _nameController,
                autofocus: true,
                style: TextStyle(color: colors.text),
                decoration: const InputDecoration(labelText: 'Name'),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a name' : null,
              ),
              const SizedBox(height: 14),
              TextFormField(
                controller: _pathController,
                style: TextStyle(color: colors.text),
                decoration: const InputDecoration(
                  labelText: 'Path',
                  hintText: 'e.g. Documents/Projects',
                ),
                validator: (v) =>
                    (v == null || v.trim().isEmpty) ? 'Enter a path' : null,
              ),
              const SizedBox(height: 18),
              Text(
                'ICON',
                style: TextStyle(
                  color: colors.mutedDark,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                ),
              ),
              const SizedBox(height: 10),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: ShortcutIcon.values.map((icon) {
                  final selected = icon == _selectedIcon;
                  return GestureDetector(
                    onTap: () => setState(() => _selectedIcon = icon),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: selected
                            ? colors.primary.withOpacity(0.18)
                            : colors.darkest,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: selected ? colors.primary : colors.borderSoft,
                          width: selected ? 1.6 : 1,
                        ),
                      ),
                      child: Icon(
                        icon.data,
                        size: 20,
                        color: selected ? colors.primary : colors.muted,
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.of(context).pop((
              name: _nameController.text.trim(),
              path: _pathController.text.trim(),
              icon: _selectedIcon,
            ));
          },
          child: const Text('Save'),
        ),
      ],
    );
  }
}
