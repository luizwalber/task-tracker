import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart' hide ModularStateX;

import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../domain/repositories/me_repository.dart';

/// The authenticated shell shown right after login. No business features live
/// here yet — this is the empty casca de tela authenticated by ticket 14. It
/// calls GET /me (through MeRepository, never ApiClient directly) to prove
/// the Firebase ID token actually round-trips to the backend; the
/// calendar/task modules land in later tickets.
class HomePage extends StatefulWidget {
  /// [meRepository] is normally omitted — the page resolves it from Modular's
  /// DI. Tests pass a fake here directly, without touching the DI container.
  const HomePage({super.key, MeRepository? meRepository})
    : _meRepository = meRepository;

  final MeRepository? _meRepository;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late final MeRepository _meRepository =
      widget._meRepository ?? inject<MeRepository>();
  late final Future<String> _meFuture = _fetchMe();

  Future<String> _fetchMe() async {
    try {
      return await _meRepository.getMe();
    } catch (error) {
      return 'GET /me failed: $error';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Tracker Pessoal de Desempenho'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () =>
                context.read<AuthBloc>().add(const AuthLogoutRequested()),
          ),
        ],
      ),
      body: Center(
        child: FutureBuilder<String>(
          future: _meFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState != ConnectionState.done) {
              return const CircularProgressIndicator();
            }
            // _fetchMe() always catches its own failures into the returned
            // string, so this future never actually rejects — snapshot.data
            // is always set once connectionState is done.
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('Você está autenticado.\nGET /me → ${snapshot.data}'),
            );
          },
        ),
      ),
    );
  }
}
