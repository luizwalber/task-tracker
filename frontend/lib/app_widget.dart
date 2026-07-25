import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'modules/auth/presentation/bloc/auth_bloc.dart';

/// Sits below [ModularApp] (which owns DI + routing) and bridges the
/// Modular-constructed [AuthBloc] singleton into flutter_bloc's own
/// InheritedWidget mechanism, so every page underneath can use the ordinary
/// `BlocBuilder`/`BlocConsumer`/`context.read<AuthBloc>()` API.
class AppRoot extends StatelessWidget {
  const AppRoot({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: inject<AuthBloc>(),
      child: MaterialApp.router(
        title: 'Tracker Pessoal de Desempenho',
        routerConfig: ModularApp.routerConfigOf(context),
      ),
    );
  }
}
