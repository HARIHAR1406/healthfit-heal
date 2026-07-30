import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

/// Network connectivity information — abstracts [connectivity_plus].
///
/// Use this for:
///   - Pre-flight connectivity checks before network calls
///   - Triggering offline sync queue processing on reconnect
///   - Showing offline UI banners
abstract class NetworkInfo {
  /// Returns true if any network interface is connected.
  Future<bool> get isConnected;

  /// Stream of connectivity changes.
  Stream<bool> get onConnectivityChanged;
}

// ══════════════════════════════════════════════════════════════════════════════
// IMPLEMENTATION
// ══════════════════════════════════════════════════════════════════════════════

class NetworkInfoImpl implements NetworkInfo {
  const NetworkInfoImpl(this._connectivity);

  final Connectivity _connectivity;

  @override
  Future<bool> get isConnected async {
    final results = await _connectivity.checkConnectivity();
    return _isOnline(results);
  }

  @override
  Stream<bool> get onConnectivityChanged =>
      _connectivity.onConnectivityChanged.map(_isOnline);

  bool _isOnline(List<ConnectivityResult> results) =>
      results.any((r) => r != ConnectivityResult.none);
}

// ── Riverpod Providers ─────────────────────────────────────────────────────────

final connectivityProvider = Provider<Connectivity>(
  (_) => Connectivity(),
  name: 'connectivityProvider',
);

final networkInfoProvider = Provider<NetworkInfo>(
  (ref) => NetworkInfoImpl(ref.watch(connectivityProvider)),
  name: 'networkInfoProvider',
);

/// Stream provider for real-time connectivity changes.
/// Watch this in widgets that need to respond to offline/online transitions.
final isOnlineProvider = StreamProvider<bool>(
  (ref) => ref.watch(networkInfoProvider).onConnectivityChanged,
  name: 'isOnlineProvider',
);
