import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_modular/flutter_modular.dart';

import 'core/api_client.dart';
import 'modules/auth/data/datasources/firebase_auth_datasource.dart';
import 'modules/auth/data/repositories/firebase_auth_repository_impl.dart';
import 'modules/auth/domain/repositories/auth_repository.dart';
import 'modules/auth/presentation/bloc/auth_bloc.dart';
import 'modules/auth/presentation/pages/auth_gate_page.dart';
import 'modules/calendar/data/repositories/calendar_repository_impl.dart';
import 'modules/calendar/data/repositories/occurrence_repository_impl.dart';
import 'modules/calendar/domain/repositories/calendar_repository.dart';
import 'modules/calendar/domain/repositories/occurrence_repository.dart';
import 'modules/calendar/presentation/bloc/calendar_bloc.dart';
import 'modules/calendar/presentation/pages/calendar_page.dart';
import 'modules/task/data/repositories/task_repository_impl.dart';
import 'modules/task/domain/repositories/task_repository.dart';
import 'modules/task/presentation/cubit/task_cubit.dart';

final appModule = createModule(
  register: (c) {
    c
      ..addSingleton<FirebaseAuthDatasource>(
        () => FirebaseAuthDatasource(FirebaseAuth.instance),
      )
      ..addSingleton<AuthRepository>(FirebaseAuthRepositoryImpl.new)
      ..addSingleton<AuthBloc>(AuthBloc.new)
      ..addSingleton<ApiClient>(ApiClient.new)
      ..addSingleton<TaskRepository>(TaskRepositoryImpl.new)
      ..addSingleton<CalendarRepository>(CalendarRepositoryImpl.new)
      ..addSingleton<OccurrenceRepository>(OccurrenceRepositoryImpl.new)
      ..addSingleton<TaskCubit>(TaskCubit.new)
      ..add<CalendarBloc>(CalendarBloc.new)
      ..route('/', child: (ctx, state) => const AuthGatePage())
      ..route('/home', child: (ctx, state) => const CalendarPage());
  },
);
