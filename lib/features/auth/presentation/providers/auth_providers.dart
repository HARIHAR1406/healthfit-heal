import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../config/env/environment.dart';
import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/datasources/firebase_auth_datasource.dart';
import '../../data/datasources/firebase_auth_token_provider.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../data/repositories/firebase_auth_repository_impl.dart';
import '../../domain/entities/user_entity.dart';
import '../../domain/repositories/auth_repository.dart';
import '../../domain/usecases/check_auth_status_usecase.dart';
import '../../domain/usecases/forgot_password_usecase.dart';
import '../../domain/usecases/get_current_user_usecase.dart';
import '../../domain/usecases/login_usecase.dart';
import '../../domain/usecases/logout_usecase.dart';
import '../../domain/usecases/register_usecase.dart';
import '../../services/session_service.dart';
import 'auth_notifier.dart';
import 'auth_state.dart';

// ══════════════════════════════════════════════════════════════════════════════
// FIREBASE AUTH DATASOURCE
// ══════════════════════════════════════════════════════════════════════════════

/// Firebase Auth datasource — active when [Environment.enableFirebase] is true.
final firebaseAuthDatasourceProvider = Provider<FirebaseAuthDatasource>(
  (_) => FirebaseAuthDatasource(),
  name: 'firebaseAuthDatasourceProvider',
);

/// Firebase-backed token provider for [AuthInterceptor].
final firebaseAuthTokenProvider = Provider<FirebaseAuthTokenProvider>(
  (ref) => FirebaseAuthTokenProvider(
    firebaseAuth: ref.watch(firebaseAuthDatasourceProvider),
  ),
  name: 'firebaseAuthTokenProvider',
);

// ══════════════════════════════════════════════════════════════════════════════
// DATA SOURCES
// ══════════════════════════════════════════════════════════════════════════════

/// Remote data source provider.
///
/// When [Environment.enableFirebase] is true, uses the mock datasource
/// as a pass-through — the Firebase datasource is wired directly into
/// [AuthRepositoryImpl] via [firebaseAuthDatasourceProvider].
/// When Firebase is disabled, mock is used for development.
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>(
  (ref) => AuthRemoteDatasource(),
  name: 'authRemoteDatasourceProvider',
);

/// Local data source provider.
final authLocalDatasourceProvider = Provider<AuthLocalDatasource>(
  (ref) => AuthLocalDatasource(),
  name: 'authLocalDatasourceProvider',
);

// ══════════════════════════════════════════════════════════════════════════════
// REPOSITORY
// ══════════════════════════════════════════════════════════════════════════════

/// Auth repository provider — selects the implementation based on environment.
///
/// Production (Firebase enabled): uses [FirebaseAuthDatasource] for all auth ops.
/// Development (Firebase disabled): uses mock [AuthRemoteDatasource].
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) {
    if (Environment.enableFirebase) {
      return FirebaseAuthRepositoryImpl(
        firebase: ref.watch(firebaseAuthDatasourceProvider),
        local: ref.watch(authLocalDatasourceProvider),
      );
    }
    return AuthRepositoryImpl(
      remote: ref.watch(authRemoteDatasourceProvider),
      local: ref.watch(authLocalDatasourceProvider),
    );
  },
  name: 'authRepositoryProvider',
);

// ══════════════════════════════════════════════════════════════════════════════
// USE CASES
// ══════════════════════════════════════════════════════════════════════════════

final loginUseCaseProvider = Provider<LoginUseCase>(
  (ref) => LoginUseCase(ref.watch(authRepositoryProvider)),
  name: 'loginUseCaseProvider',
);

final registerUseCaseProvider = Provider<RegisterUseCase>(
  (ref) => RegisterUseCase(ref.watch(authRepositoryProvider)),
  name: 'registerUseCaseProvider',
);

final logoutUseCaseProvider = Provider<LogoutUseCase>(
  (ref) => LogoutUseCase(ref.watch(authRepositoryProvider)),
  name: 'logoutUseCaseProvider',
);

final forgotPasswordUseCaseProvider = Provider<ForgotPasswordUseCase>(
  (ref) => ForgotPasswordUseCase(ref.watch(authRepositoryProvider)),
  name: 'forgotPasswordUseCaseProvider',
);

final getCurrentUserUseCaseProvider = Provider<GetCurrentUserUseCase>(
  (ref) => GetCurrentUserUseCase(ref.watch(authRepositoryProvider)),
  name: 'getCurrentUserUseCaseProvider',
);

final checkAuthStatusUseCaseProvider = Provider<CheckAuthStatusUseCase>(
  (ref) => CheckAuthStatusUseCase(ref.watch(authRepositoryProvider)),
  name: 'checkAuthStatusUseCaseProvider',
);

// ══════════════════════════════════════════════════════════════════════════════
// AUTH NOTIFIER
// ══════════════════════════════════════════════════════════════════════════════

/// The primary auth state provider.
final authNotifierProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (ref) => AuthNotifier(
    loginUseCase: ref.watch(loginUseCaseProvider),
    registerUseCase: ref.watch(registerUseCaseProvider),
    logoutUseCase: ref.watch(logoutUseCaseProvider),
    forgotPasswordUseCase: ref.watch(forgotPasswordUseCaseProvider),
    getCurrentUserUseCase: ref.watch(getCurrentUserUseCaseProvider),
    checkAuthStatusUseCase: ref.watch(checkAuthStatusUseCaseProvider),
  ),
  name: 'authNotifierProvider',
);

// ══════════════════════════════════════════════════════════════════════════════
// CONVENIENCE SELECTORS
// ══════════════════════════════════════════════════════════════════════════════

final currentUserProvider = Provider<UserEntity?>(
  (ref) => ref.watch(authNotifierProvider).user,
  name: 'currentUserProvider',
);

final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authNotifierProvider).isAuthenticated,
  name: 'isAuthenticatedProvider',
);

final authIsLoadingProvider = Provider<bool>(
  (ref) => ref.watch(authNotifierProvider).isLoading,
  name: 'authIsLoadingProvider',
);

// ══════════════════════════════════════════════════════════════════════════════
// SESSION SERVICE
// ══════════════════════════════════════════════════════════════════════════════

final sessionServiceProvider = Provider<SessionService>(
  (ref) => SessionService(
    localDatasource: ref.watch(authLocalDatasourceProvider),
  ),
  name: 'sessionServiceProvider',
);
