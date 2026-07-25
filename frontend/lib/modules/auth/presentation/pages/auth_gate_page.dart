import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_modular/flutter_modular.dart' hide ModularStateX;

import '../bloc/auth_bloc.dart';
import '../bloc/auth_event.dart';
import '../bloc/auth_state.dart';
import 'login_page.dart';

/// The `/` route's actual content. Checks for an existing Firebase session
/// before deciding what to show — a returning user skips straight past
/// [LoginPage] instead of seeing it flash before redirecting to `/home`.
class AuthGatePage extends StatefulWidget {
  /// Called once the session check finds an existing user. Defaults to
  /// navigating to `/home`; tests override it to avoid needing a real router.
  const AuthGatePage({super.key, this.onAuthenticated});

  final void Function(BuildContext context)? onAuthenticated;

  @override
  State<AuthGatePage> createState() => _AuthGatePageState();
}

class _AuthGatePageState extends State<AuthGatePage> {
  late final void Function(BuildContext context) _onAuthenticated =
      widget.onAuthenticated ?? (ctx) => ctx.navigate('/home');

  @override
  void initState() {
    super.initState();
    context.read<AuthBloc>().add(const AuthCheckRequested());
  }

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _onAuthenticated(context);
        }
      },
      // Exhaustive over AuthState (a sealed class) — the compiler flags it
      // if a new state is ever added without deciding what this gate does
      // with it, instead of silently falling through to "show LoginPage".
      builder: (context, state) => switch (state) {
        // AuthInitial: the session check is still in flight. AuthAuthenticated:
        // transient — about to navigate away, never render the login form for it.
        AuthInitial() || AuthAuthenticated() => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        AuthUnauthenticated() ||
        AuthLoading() ||
        AuthError() => const LoginPage(),
      },
    );
  }
}
