import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localbridge_mobile/core/errors/user_message.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/core/feedback/app_feedback.dart';
import 'package:localbridge_mobile/features/connection/presentation/pages/qr_scanner_page.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/pages/pc_explorer_page.dart';
import 'package:localbridge_mobile/features/navbar/presentation/cubit/navbar_cubit.dart';
import 'package:localbridge_mobile/features/navbar/presentation/cubit/navbar_state.dart';
import 'package:localbridge_mobile/features/phone_files/presentation/pages/connection_page.dart';
import 'package:localbridge_mobile/features/phone_files/presentation/pages/phone_files_page.dart';
import 'package:localbridge_mobile/features/shared_files/presentation/pages/recent_shared_page.dart';
import 'package:localbridge_mobile/injection_container.dart';

class Navbar extends StatelessWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<NavbarCubit>()..start(),
      child: const _NavbarView(),
    );
  }
}

class _NavbarView extends StatelessWidget {
  const _NavbarView();

  void _navigateToScanner(BuildContext context) {
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(builder: (_) => const QrScannerScreen()),
      (_) => false,
    );
  }

  Future<void> _handleDisconnect(BuildContext context) async {
    try {
      await context.read<NavbarCubit>().disconnect();
      if (context.mounted) {
        _navigateToScanner(context);
      }
    } catch (error) {
      if (context.mounted) {
        showAppFeedback(
          context,
          userMessage(error, fallback: 'Could not disconnect.'),
          type: FeedbackType.error,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    final screens = const [
      PcExplorerTab(),
      PhoneFilesPage(),
      RecentSharedPage(),
      ConnectionPage(),
    ];

    return BlocConsumer<NavbarCubit, NavbarState>(
      listenWhen: (previous, current) =>
          previous.pcReachable != current.pcReachable ||
          previous.error != current.error,
      listener: (context, state) {
        if (!state.pcReachable) {
          showAppFeedback(
            context,
            'Connection lost with PC.',
            type: FeedbackType.warning,
          );
          _navigateToScanner(context);
        } else if (state.error != null) {
          showAppFeedback(context, state.error!, type: FeedbackType.error);
        }
      },
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.darkest,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                _HeaderBar(
                  state: state,
                  onDisconnect: () => _handleDisconnect(context),
                ),
                Expanded(
                  child: IndexedStack(
                    index: state.currentIndex,
                    children: screens,
                  ),
                ),
              ],
            ),
          ),
          bottomNavigationBar: _NavbarBottomBar(
            currentIndex: state.currentIndex,
            onTap: (index) => context.read<NavbarCubit>().setIndex(index),
          ),
        );
      },
    );
  }
}

class _HeaderBar extends StatelessWidget {
  final NavbarState state;
  final VoidCallback onDisconnect;

  const _HeaderBar({required this.state, required this.onDisconnect});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: colors.card.withValues(alpha: 0.85),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: colors.borderSoft, width: 1),
            ),
            child: Row(
              children: [
                // App Logo / Title
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: colors.primary.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    Icons.devices_rounded,
                    color: colors.primary,
                    size: 18,
                  ),
                ),
                const SizedBox(width: 10),
                Text(
                  'LocalBridge',
                  style: TextStyle(
                    color: colors.text,
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    letterSpacing: -0.3,
                  ),
                ),
                const Spacer(),

                // Status Indicator Pill
                _StatusBadge(
                  isReachable: state.pcReachable,
                  onTap: () => context.read<NavbarCubit>().start(),
                ),
                const SizedBox(width: 8),

                // Disconnect Button
                InkWell(
                  onTap: onDisconnect,
                  borderRadius: BorderRadius.circular(10),
                  child: Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: colors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      Icons.power_settings_new_rounded,
                      color: colors.error,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final bool isReachable;
  final VoidCallback onTap;

  const _StatusBadge({required this.isReachable, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;
    final statusColor = isReachable ? colors.success : colors.warning;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.3),
            width: 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: statusColor,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              isReachable ? 'Online' : 'Offline',
              style: TextStyle(
                color: statusColor,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavbarBottomBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;

  const _NavbarBottomBar({required this.currentIndex, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colors = context.appColors;

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        border: Border(top: BorderSide(color: colors.borderSoft)),
      ),
      child: BottomNavigationBar(
        backgroundColor: colors.card,
        selectedItemColor: colors.primary,
        unselectedItemColor: colors.mutedDark,
        currentIndex: currentIndex,
        type: BottomNavigationBarType.fixed,
        elevation: 0,
        selectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.normal,
        ),
        onTap: onTap,
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.computer_rounded),
            activeIcon: Icon(Icons.computer_rounded),
            label: 'PC Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.smartphone_rounded),
            activeIcon: Icon(Icons.smartphone_rounded),
            label: 'Phone Files',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_rounded),
            activeIcon: Icon(Icons.history_rounded),
            label: 'Recent Shared',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.wifi_rounded),
            activeIcon: Icon(Icons.wifi_rounded),
            label: 'Connection',
          ),
        ],
      ),
    );
  }
}
