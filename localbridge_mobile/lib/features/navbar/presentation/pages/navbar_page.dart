import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localbridge_mobile/core/errors/user_message.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/core/feedback/app_feedback.dart';
import 'package:localbridge_mobile/features/connection/presentation/connectionwraper.dart';
import 'package:localbridge_mobile/features/connection/presentation/pages/connection_page.dart';
import 'package:localbridge_mobile/features/connection/presentation/pages/qr_scanner_page.dart';
import 'package:localbridge_mobile/features/navbar/presentation/cubit/navbar_cubit.dart';
import 'package:localbridge_mobile/features/navbar/presentation/cubit/navbar_state.dart';
import 'package:localbridge_mobile/features/navbar/presentation/pages/widgets/appbar/header_bar.dart';
import 'package:localbridge_mobile/features/navbar/presentation/pages/widgets/navbar/bottom_bar.dart';
import 'package:localbridge_mobile/features/pc_explorer/presentation/pages/pc_explorer_page.dart';
import 'package:localbridge_mobile/features/phone_files/presentation/pages/phone_files_page.dart';
import 'package:localbridge_mobile/features/shared_files/presentation/pages/recent_shared_page.dart';
import 'package:localbridge_mobile/injection_container.dart';

class Navbar extends StatelessWidget {
  const Navbar({super.key});

  @override
  Widget build(BuildContext context) {
    // Wrapped here, once, so every place that navigates to Navbar() — the
    // initial post-scan push, and any future reconnect push — is covered
    // without needing to remember to wrap it at the call site.
    return ConnectionListenerWrapper(
      child: BlocProvider(
        create: (_) => locator<NavbarCubit>()..start(),
        child: const _NavbarView(),
      ),
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
      listener: (context, state) {},
      builder: (context, state) {
        return Scaffold(
          backgroundColor: colors.darkest,
          body: SafeArea(
            bottom: false,
            child: Column(
              children: [
                //* AppBar
                HeaderBar(
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
          //* Bottom Navigation Bar
          bottomNavigationBar: NavbarBottomBar(
            currentIndex: state.currentIndex,
            onTap: (index) => context.read<NavbarCubit>().setIndex(index),
          ),
        );
      },
    );
  }
}
