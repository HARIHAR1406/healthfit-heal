import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/auth_local_datasource.dart';
import '../../data/datasources/auth_remote_datasource.dart';
import '../../data/repositories/auth_repository_impl.dart';
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

// ── Data Sources ──────────────────────────────────────────────────────────────

/// Remote data source provider.
final authRemoteDatasourceProvider = Provider<AuthRemoteDatasource>(
  (ref) => AuthRemoteDatasource(),
  name: 'authRemoteDatasourceProvider',
);

/// Local data source provider.
final authLocalDatasourceProvider = Provider<AuthLocalDatasource>(
  (ref) => AuthLocalDatasource(),
  name: 'authLocalDatasourceProvider',
);

// ── Repository ────────────────────────────────────────────────────────────────

/// Auth repository provider — exposes the [AuthRepository] interface.
final authRepositoryProvider = Provider<AuthRepository>(
  (ref) => AuthRepositoryImpl(
    remote: ref.watch(authRemoteDatasourceProvider),
    local: ref.watch(authLocalDatasourceProvider),
  ),
  name: 'authRepositoryProvider',
);

// ── Use Cases ─────────────────────────────────────────────────────────────────

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

// ── Auth Notifier ─────────────────────────────────────────────────────────────

/// The primary auth state provider.
///
/// Watch this in the router, app bar, and any auth-gated widget.
final authNotifierProvider =
    StateNotifierProvider<AuthNotifier, AuthState>(
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

// ── Convenience Selectors ─────────────────────────────────────────────────────

/// Provides the current [UserEntity] or null if not authenticated.
final currentUserProvider = Provider<UserEntity?>(
  (ref) => ref.watch(authNotifierProvider).user,
  name: 'currentUserProvider',
);

/// True when a valid session exists.
final isAuthenticatedProvider = Provider<bool>(
  (ref) => ref.watch(authNotifierProvider).isAuthenticated,
  name: 'isAuthenticatedProvider',
);

/// True when an auth operation is in progress.
final authIsLoadingProvider = Provider<bool>(
  (ref) => ref.watch(authNotifierProvider).isLoading,
  name: 'authIsLoadingProvider',
);

// ── Session Service ────────────────────────────────────────────────────────────

/// Session service provider.
final sessionServiceProvider = Provider<SessionService>(
  (ref) => SessionService(
    localDatasource: ref.watch(authLocalDatasourceProvider),
  ),
  name: 'sessionServiceProvider',
);
