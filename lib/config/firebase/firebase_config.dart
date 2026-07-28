/// Firebase configuration placeholder for HealthFit Heal.
///
/// Firebase is scaffolded but NOT initialised yet.
/// To activate Firebase:
///   1. Create a Firebase project at https://console.firebase.google.com
///   2. Run `flutterfire configure` to generate google-services.json
///      and replace the placeholder in android/app/google-services.json
///   3. Uncomment [FirebaseConfig.init] and add `await FirebaseConfig.init()`
///      to [main.dart] before [runApp].
///   4. Add required Firebase service packages (e.g. firebase_auth,
///      cloud_firestore, firebase_messaging) to pubspec.yaml.
///
/// See: https://firebase.flutter.dev/docs/overview
abstract final class FirebaseConfig {
  // ── Feature Flags ─────────────────────────────────────────────────────────
  static const bool enableAnalytics = false;
  static const bool enableCrashlytics = false;
  static const bool enableRemoteConfig = false;
  static const bool enableMessaging = false;
  static const bool enablePerformance = false;

  // ── Initialisation ────────────────────────────────────────────────────────
  // TODO: Uncomment when Firebase is configured.
  //
  // static Future<void> init() async {
  //   await Firebase.initializeApp(
  //     options: DefaultFirebaseOptions.currentPlatform,
  //   );
  //
  //   if (enableCrashlytics) {
  //     await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(
  //       !kDebugMode,
  //     );
  //     FlutterError.onError =
  //         FirebaseCrashlytics.instance.recordFlutterFatalError;
  //     PlatformDispatcher.instance.onError = (error, stack) {
  //       FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
  //       return true;
  //     };
  //   }
  //
  //   if (enableAnalytics) {
  //     await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(
  //       !kDebugMode,
  //     );
  //   }
  //
  //   if (enableRemoteConfig) {
  //     final remoteConfig = FirebaseRemoteConfig.instance;
  //     await remoteConfig.setConfigSettings(
  //       RemoteConfigSettings(
  //         fetchTimeout: const Duration(seconds: 10),
  //         minimumFetchInterval: const Duration(hours: 1),
  //       ),
  //     );
  //     await remoteConfig.fetchAndActivate();
  //   }
  // }
}
