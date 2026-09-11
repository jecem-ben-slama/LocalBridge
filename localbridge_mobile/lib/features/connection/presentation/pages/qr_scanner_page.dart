import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:localbridge_mobile/core/extensions/theme_extensions.dart';
import 'package:localbridge_mobile/features/connection/presentation/pages/widgets/custom_button.dart';
import 'package:localbridge_mobile/features/connection/presentation/pages/widgets/manual_code_dialog.dart';
import 'package:localbridge_mobile/features/connection/presentation/pages/widgets/qr_scanner_view.dart';
import 'package:localbridge_mobile/features/connection/presentation/pages/widgets/qr_welcome_card.dart';
import 'package:localbridge_mobile/features/navbar/presentation/pages/navbar_page.dart';
import 'package:localbridge_mobile/injection_container.dart';
import 'package:localbridge_mobile/core/errors/user_message.dart';
import 'package:localbridge_mobile/core/feedback/app_feedback.dart';
import '../cubit/qr_scanner_cubit.dart';
import '../cubit/qr_scanner_state.dart';

class QrScannerScreen extends StatefulWidget {
  const QrScannerScreen({super.key});

  @override
  State<QrScannerScreen> createState() => _QrScannerScreenState();
}

class _QrScannerScreenState extends State<QrScannerScreen> {
  bool _isScanning = false;
  final TextEditingController _manualHostController = TextEditingController();
  final TextEditingController _manualCodeController = TextEditingController();

  @override
  void dispose() {
    _manualHostController.dispose();
    _manualCodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      // Fetch our clean presentation controller directly via locator configuration rules
      create: (_) => locator<QrScannerCubit>(),
      child: BlocConsumer<QrScannerCubit, QrScannerState>(
        listener: (context, state) {
          // Manage asynchronous side-effects safely inside the listener
          if (state.isSuccess) {
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (_) => const Navbar()),
            );
          }
          if (state.error != null) {
            showAppFeedback(
              context,
              userMessage(
                state.error!,
                fallback: 'Could not connect to LocalBridge.',
              ),
              type: FeedbackType.error,
            );
          }
        },
        builder: (context, state) {
          return Scaffold(
            backgroundColor: context.theme.scaffoldBackgroundColor,
            body: state.isConnecting
                ? const Center(
                    child: CircularProgressIndicator(
                      color: Colors.lightBlueAccent,
                    ),
                  )
                : _isScanning
                //* mobile scanner
                ? QrScannerView(
                    onScanComplete: (scannedValue) {
                      setState(() => _isScanning = false);
                      context.read<QrScannerCubit>().pairWithQr(scannedValue);
                    },
                  )
                : SafeArea(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24),
                        child: ConstrainedBox(
                          constraints: const BoxConstraints(maxWidth: 420),
                          child: SingleChildScrollView(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                //* welcome card
                                const QrWelcomeCard(),
                                const SizedBox(height: 26),
                                //* scan button
                                CustomButton(
                                  onPressed: () =>
                                      setState(() => _isScanning = true),
                                  label: 'Scan Qr Code',
                                  icon: Icons.qr_code_scanner_rounded,
                                ),
                                const SizedBox(height: 14),
                                //* manual code button
                                CustomButton(
                                  onPressed: () =>
                                      showManualCodeDialog(context),
                                  label: 'Type Code',
                                  icon: Icons.keyboard_rounded,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
          );
        },
      ),
    );
  }
}
