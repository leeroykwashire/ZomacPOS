import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../database/app_database.dart';
import '../services/barcode_scanning_service.dart';
import '../services/sales_completion_service.dart';
import 'database_providers.dart';

// Barcode Scanning Service Provider
final barcodeScanningServiceProvider = Provider<BarcodeScanningService>((ref) {
  final database = ref.watch(databaseProvider);
  return BarcodeScanningService(
    database.productsDao,
    database.cartDao,
  );
});

// Sales Completion Service Provider
final salesCompletionServiceProvider = Provider<SalesCompletionService>((ref) {
  final database = ref.watch(databaseProvider);
  return SalesCompletionService(database);
});

// Current scanning session provider
final scanningSessionProvider = StateNotifierProvider<ScanningSessionNotifier, ScanningSession>((ref) {
  return ScanningSessionNotifier();
});

// Scanning session state
class ScanningSession {
  final bool isActive;
  final String sessionId;
  final List<ScanResult> scans;
  final ScanMode mode;

  ScanningSession({
    this.isActive = false,
    this.sessionId = '',
    this.scans = const [],
    this.mode = ScanMode.addToCart,
  });

  ScanningSession copyWith({
    bool? isActive,
    String? sessionId,
    List<ScanResult>? scans,
    ScanMode? mode,
  }) {
    return ScanningSession(
      isActive: isActive ?? this.isActive,
      sessionId: sessionId ?? this.sessionId,
      scans: scans ?? this.scans,
      mode: mode ?? this.mode,
    );
  }
}

// Scanning modes
enum ScanMode {
  addToCart,
  productLookup,
  priceVerification,
  inventoryCount,
}

// Scanning session notifier
class ScanningSessionNotifier extends StateNotifier<ScanningSession> {
  ScanningSessionNotifier() : super(ScanningSession());

  void startSession({ScanMode mode = ScanMode.addToCart}) {
    final sessionId = DateTime.now().millisecondsSinceEpoch.toString();
    state = ScanningSession(
      isActive: true,
      sessionId: sessionId,
      scans: [],
      mode: mode,
    );
  }

  void endSession() {
    state = ScanningSession();
  }

  void addScanResult(ScanResult result) {
    if (state.isActive) {
      state = state.copyWith(
        scans: [...state.scans, result],
      );
    }
  }

  void clearScans() {
    if (state.isActive) {
      state = state.copyWith(scans: []);
    }
  }

  void changeMode(ScanMode mode) {
    if (state.isActive) {
      state = state.copyWith(mode: mode);
    }
  }
}

// Recent scan results provider
final recentScanResultsProvider = StateNotifierProvider<RecentScanResultsNotifier, List<ScanResult>>((ref) {
  return RecentScanResultsNotifier();
});

class RecentScanResultsNotifier extends StateNotifier<List<ScanResult>> {
  RecentScanResultsNotifier() : super([]);

  void addScanResult(ScanResult result) {
    state = [result, ...state.take(9)].toList(); // Keep last 10 scans
  }

  void clearResults() {
    state = [];
  }
}

// Scan statistics provider
final scanStatisticsProvider = StateNotifierProvider<ScanStatisticsNotifier, ScanStatistics>((ref) {
  return ScanStatisticsNotifier();
});

class ScanStatistics {
  final int totalScans;
  final int successfulScans;
  final int failedScans;
  final DateTime? lastScanTime;

  ScanStatistics({
    this.totalScans = 0,
    this.successfulScans = 0,
    this.failedScans = 0,
    this.lastScanTime,
  });

  double get successRate => totalScans > 0 ? (successfulScans / totalScans) * 100 : 0;

  ScanStatistics copyWith({
    int? totalScans,
    int? successfulScans,
    int? failedScans,
    DateTime? lastScanTime,
  }) {
    return ScanStatistics(
      totalScans: totalScans ?? this.totalScans,
      successfulScans: successfulScans ?? this.successfulScans,
      failedScans: failedScans ?? this.failedScans,
      lastScanTime: lastScanTime ?? this.lastScanTime,
    );
  }
}

class ScanStatisticsNotifier extends StateNotifier<ScanStatistics> {
  ScanStatisticsNotifier() : super(ScanStatistics());

  void recordScan(bool success) {
    state = state.copyWith(
      totalScans: state.totalScans + 1,
      successfulScans: success ? state.successfulScans + 1 : state.successfulScans,
      failedScans: success ? state.failedScans : state.failedScans + 1,
      lastScanTime: DateTime.now(),
    );
  }

  void resetStatistics() {
    state = ScanStatistics();
  }
}
