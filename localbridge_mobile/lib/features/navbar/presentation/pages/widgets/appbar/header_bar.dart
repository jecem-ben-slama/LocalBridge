import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/navbar/presentation/cubit/navbar_state.dart';
import 'package:localbridge_mobile/features/navbar/presentation/pages/widgets/appbar/header_expanded.dart';
import 'package:localbridge_mobile/features/navbar/presentation/pages/widgets/appbar/header_tile.dart';

class HeaderBar extends StatefulWidget {
  final NavbarState state;
  final VoidCallback onDisconnect;

  const HeaderBar({super.key, required this.state, required this.onDisconnect});

  @override
  State<HeaderBar> createState() => _HeaderBarState();
}

class _HeaderBarState extends State<HeaderBar> {
  bool _isExpanded = false;

  void _toggleExpanded() {
    setState(() {
      _isExpanded = !_isExpanded;
    });
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = context.colorScheme;
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 16, sigmaY: 16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 300),
            curve: Curves.fastOutSlowIn,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: colorScheme.surface.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(
                color: _isExpanded
                    ? colors.primary.withValues(alpha: 0.4)
                    : colors.borderSoft.withValues(alpha: 0.6),
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(
                    alpha: _isExpanded ? 0.35 : 0.15,
                  ),
                  blurRadius: _isExpanded ? 20 : 10,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                HeaderTitleRow(
                  phoneServerStatus: widget.state.isServerRunning,
                  isExpanded: _isExpanded,
                  isReachable: widget.state.pcReachable,
                  onToggle: _toggleExpanded,
                  onDisconnect: widget.onDisconnect,
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox(width: double.infinity),
                  secondChild: HeaderExpandedDetails(
                    isReachable: widget.state.pcReachable,
                    isServerRunning: widget.state.isServerRunning,
                    onDisconnect: () {
                      _toggleExpanded();
                      widget.onDisconnect();
                    },
                  ),
                  crossFadeState: _isExpanded
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 250),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
