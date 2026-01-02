import 'package:get_it/get_it.dart';
import '../../features/walking_challenge/data/datasources/route_local_datasource.dart';
import '../../features/walking_challenge/data/repositories/route_repository_impl.dart';
import '../../features/walking_challenge/domain/repositories/route_repository.dart';
import '../../features/walking_challenge/domain/usecases/calculate_progress_usecase.dart';
import '../../features/walking_challenge/domain/usecases/get_landmarks_usecase.dart';
import '../../features/walking_challenge/domain/usecases/load_route_usecase.dart';
import '../../features/walking_challenge/presentation/bloc/route_bloc.dart';

final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> init() async {
  // BLoC
  sl.registerFactory(
    () => RouteBloc(
      loadRouteUseCase: sl(),
      calculateProgressUseCase: sl(),
      getLandmarksUseCase: sl(),
    ),
  );

  // Use cases
  sl.registerLazySingleton(() => LoadRouteUseCase(sl()));
  sl.registerLazySingleton(() => CalculateProgressUseCase(sl()));
  sl.registerLazySingleton(() => GetLandmarksUseCase(sl()));

  // Repository
  sl.registerLazySingleton<RouteRepository>(
    () => RouteRepositoryImpl(localDataSource: sl()),
  );

  // Data sources
  sl.registerLazySingleton<RouteLocalDataSource>(
    () => RouteLocalDataSourceImpl(),
  );
}
