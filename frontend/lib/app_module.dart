import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'core/api_client.dart';
import 'modules/auth/data/datasources/firebase_auth_datasource.dart';
import 'modules/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'modules/auth/domain/repositories/auth_repository.dart';
import 'modules/auth/presentation/bloc/auth_bloc.dart';
import 'modules/auth/presentation/pages/auth_gate_page.dart';
import 'modules/home/data/repositories/me_repository_impl.dart';
import 'modules/home/domain/repositories/me_repository.dart';
import 'modules/home/presentation/pages/home_page.dart';

final appModule = createModule(
  register: (c) {
    c
      ..addSingleton<FirebaseAuthDatasource>(
        () => FirebaseAuthDatasource(FirebaseAuth.instance),
      )
      ..addSingleton<AuthRepository>(FirebaseAuthRepositoryImpl.new)
      ..addSingleton<AuthBloc>(AuthBloc.new)
      ..addSingleton<ApiClient>(ApiClient.new)
      ..addSingleton<MeRepository>(MeRepositoryImpl.new)
      ..route('/', child: (ctx, state) => const AuthGatePage())
      ..route('/home', child: (ctx, state) => const HomePage());
  },
);
