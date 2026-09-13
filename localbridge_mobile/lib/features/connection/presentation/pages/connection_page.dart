import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/shared/widgets/app_status_card.dart';
import '../../../../injection_container.dart';
import '../../../phone_files/domain/usecases/get_phone_server_status_stream.dart';
import '../cubit/connection_cubit.dart';
import '../cubit/connection_state.dart' as app_connection_state;

class ConnectionPage extends StatelessWidget {
  const ConnectionPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => locator<ConnectionCubit>()..start(),
      child: const _ConnectionPageView(),
    );
  }
}

class _ConnectionPageView extends StatefulWidget {
  const _ConnectionPageView();

  @override
  State<_ConnectionPageView> createState() => _ConnectionPageViewState();
}

class _ConnectionPageViewState extends State<_ConnectionPageView> {
  final _getPhoneServerStatusStream = locator<GetPhoneServerStatusStream>();
  StreamSubscription<bool>? _serverStatusSubscription;
  bool _isServerRunning = false;

  @override
  void initState() {
    super.initState();
    _serverStatusSubscription = _getPhoneServerStatusStream().listen((
      isRunning,
    ) {
      if (!mounted) return;
      setState(() => _isServerRunning = isRunning);
    });
  }

  @override
  void dispose() {
    _serverStatusSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F172A),
      appBar: AppBar(
        title: const Text('Connection'),
        actions: [
          IconButton(
            onPressed: () => context.read<ConnectionCubit>().refresh(),
            icon: const Icon(Icons.refresh),
            tooltip: 'Check connection',
          ),
        ],
      ),
      body: BlocBuilder<ConnectionCubit, app_connection_state.ConnectionState>(
        builder: (context, state) {
          final connected = state.backendReachable;

          return ListView(
            padding: const EdgeInsets.all(20),
            children: [
              AppStatusCard(
                label: 'Overall connection',
                value: connected ? 'Live' : 'Offline',
                icon: connected ? Icons.link : Icons.link_off,
                color: connected ? Colors.greenAccent : Colors.redAccent,
              ),
              const SizedBox(height: 12),
              AppStatusCard(
                label: 'PC session',
                value: state.backendReachable ? 'Reachable' : 'Unavailable',
                icon: Icons.computer,
                color: state.backendReachable
                    ? Colors.greenAccent
                    : Colors.orangeAccent,
              ),
              const SizedBox(height: 12),
              AppStatusCard(
                label: 'Phone server',
                value: _isServerRunning ? 'Running' : 'Stopped',
                icon: Icons.phone_android,
                color: _isServerRunning ? Colors.greenAccent : Colors.white54,
              ),
              const SizedBox(height: 20),
              Text(
                state.lastChecked == null
                    ? 'Checking connection...'
                    : 'Last checked ${state.lastChecked!.toLocal()}',
                style: const TextStyle(color: Colors.white54),
              ),
            ],
          );
        },
      ),
    );
  }
}
