import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localbridge_mobile/core/errors/user_message.dart';
import 'package:localbridge_mobile/core/feedback/app_feedback.dart';
import 'package:localbridge_mobile/features/connection/presentation/pages/qr_scanner_page.dart';
import 'package:localbridge_mobile/features/document_viewer/presentation/pages/pc_explorer_page.dart';
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

  Future<void> _disconnect(BuildContext context) async {
    try {
      await context.read<NavbarCubit>().disconnect();
      if (context.mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (_) => const QrScannerScreen()),
          (_) => false,
        );
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
    final screens = const [
      PcExplorerTab(),
      PhoneFilesPage(),
      RecentSharedPage(),
      ConnectionPage(),
    ];

    return BlocBuilder<NavbarCubit, NavbarState>(
      builder: (context, state) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('LocalBridge'),
            actions: [
              IconButton(
                onPressed: () => context.read<NavbarCubit>().start(),
                tooltip: state.pcReachable
                    ? 'PC session connected'
                    : 'PC session unavailable',
                icon: Icon(
                  state.pcReachable ? Icons.cloud_done : Icons.cloud_off,
                  color: state.pcReachable
                      ? Colors.greenAccent
                      : Colors.orangeAccent,
                ),
              ),
              IconButton(
                onPressed: () => context.read<NavbarCubit>().setIndex(1),
                tooltip: 'Phone server',
                icon: Icon(
                  state.isServerRunning
                      ? Icons.phone_android
                      : Icons.phone_disabled,
                  color: state.isServerRunning
                      ? Colors.greenAccent
                      : Colors.white54,
                ),
              ),
              IconButton(
                onPressed: () => _disconnect(context),
                tooltip: 'Disconnect',
                icon: const Icon(Icons.link_off),
              ),
            ],
          ),
          body: IndexedStack(index: state.currentIndex, children: screens),
          bottomNavigationBar: BottomNavigationBar(
            backgroundColor: const Color(0xFF1E293B),
            selectedItemColor: Colors.blueAccent,
            unselectedItemColor: Colors.grey,
            currentIndex: state.currentIndex,
            onTap: (index) => context.read<NavbarCubit>().setIndex(index),
            items: const [
              BottomNavigationBarItem(
                icon: Icon(Icons.computer),
                label: 'PC Files',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.phone_android),
                label: 'Phone Files',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.history),
                label: 'Recent Shared',
              ),
              BottomNavigationBarItem(
                icon: Icon(Icons.wifi),
                label: 'Connection',
              ),
            ],
          ),
        );
      },
    );
  }
}
