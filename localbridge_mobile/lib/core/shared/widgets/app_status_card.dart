import 'package:flutter/material.dart';

class AppStatusCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;

  const AppStatusCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final card = Card(
      color: const Color(0xFF111C2E),
      child: ListTile(
        onTap: onTap,
        leading: Icon(icon, color: color),
        title: Text(label, style: const TextStyle(color: Colors.white70)),
        trailing: Text(
          value,
          style: TextStyle(color: color, fontWeight: FontWeight.w700),
        ),
      ),
    );

    return card;
  }
}
