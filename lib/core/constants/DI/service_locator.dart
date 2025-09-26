import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';

import '../../../features/auth/data/datasources/auth_data_source.dart';
import '../../../features/auth/data/repositories/auth_repo.dart';
import '../../../features/auth/presentation/cubits/auth_cubit.dart';
import 'package:get_it/get_it.dart';
final sl = GetIt.instance;

class ServiceLocator {
  Future<void> init() async {
    // Initialize Firebase
    await Firebase.initializeApp();

    // Register FirebaseAuth and FirebaseFirestore as singletons
    sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
    sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

    // Register AuthDataSource using FirebaseAuth and FirebaseFirestore instances
    sl.registerLazySingleton<AuthDataSource>(
            () => AuthDataSource(sl<FirebaseAuth>(), sl<FirebaseFirestore>())
    );

    // Register AuthRepository
    sl.registerLazySingleton<AuthRepository>(
            () => AuthRepository(sl<AuthDataSource>())
    );

    // Register AuthCubit
    sl.registerFactory<AuthCubit>(
            () => AuthCubit(sl<AuthRepository>())
    );
  }
}
