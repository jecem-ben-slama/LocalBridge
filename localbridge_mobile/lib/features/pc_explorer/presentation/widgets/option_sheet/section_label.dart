import 'package:flutter/material.dart';

class SectionLabel extends StatelessWidget {
  final String text;
  final dynamic colors;
  const SectionLabel(this.text, {super.key, required this.colors});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: TextStyle(
        color: colors.muted,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}
