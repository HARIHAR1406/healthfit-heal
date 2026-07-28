import 'package:logger/logger.dart';

/// Singleton application logger for HealthFit Heal.
///
/// Wraps the [logger] package with a production-safe configuration.
/// In release builds, only [Level.warning] and above are printed.
/// In debug builds, all levels including [Level.trace] are shown.
class AppLogger {
  AppLogger._();

  static final AppLogger _instance = AppLogger._();

  /// The singleton [AppLogger] instance.
  static AppLogger get instance => _instance;

  late final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 2,
      errorMethodCount: 8,
      lineLength: 80,
      colors: true,
      printEmojis: true,
      dateTimeFormat: DateTimeFormat.onlyTimeAndSinceStart,
    ),
    level: _resolveLevel(),
    output: MultiOutput([ConsoleOutput()]),
  );

  static Level _resolveLevel() {
    // ignore: do_not_use_environment
    const isRelease = bool.fromEnvironment('dart.vm.product');
    return isRelease ? Level.warning : Level.trace;
  }

  // ── Public API ────────────────────────────────────────────────────────────

  /// Logs a trace message (verbose debugging).
  void trace(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.t(message, error: error, stackTrace: stackTrace);

  /// Logs a debug message.
  void debug(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.d(message, error: error, stackTrace: stackTrace);

  /// Logs an informational message.
  void info(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.i(message, error: error, stackTrace: stackTrace);

  /// Logs a warning.
  void warning(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.w(message, error: error, stackTrace: stackTrace);

  /// Logs an error.
  void error(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.e(message, error: error, stackTrace: stackTrace);

  /// Logs a fatal/critical error.
  void fatal(dynamic message, {Object? error, StackTrace? stackTrace}) =>
      _logger.f(message, error: error, stackTrace: stackTrace);
}

/// Convenience top-level logger instance.
final log = AppLogger.instance;
