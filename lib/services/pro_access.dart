import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum ProPlan { free, pro, ultra }

enum FeatureAccess {
  basicText,
  basicUrl,
  advancedTextScan,
  advancedUrlScan,
  screenshot,
  fullPatterns,
  advancedDashboard,
  advancedQuiz,
  multiplePdf,
  customRules,
  extendedHistory,
  advancedAnalytics,
  basicRecovery,
  safetyGuides,
}

class PlanConfiguration {
  const PlanConfiguration({required this.aiPerDay, required this.pdfPerMonth});
  final int? aiPerDay;
  final int? pdfPerMonth;

  static const values = <ProPlan, PlanConfiguration>{
    ProPlan.free: PlanConfiguration(aiPerDay: 0, pdfPerMonth: 2),
    ProPlan.pro: PlanConfiguration(aiPerDay: 10, pdfPerMonth: 10),
    ProPlan.ultra: PlanConfiguration(aiPerDay: null, pdfPerMonth: null),
  };
}

class ProAccess extends ChangeNotifier {
  ProAccess._();
  static final ProAccess instance = ProAccess._();
  static const products = <ProPlan, String>{
    ProPlan.pro: String.fromEnvironment(
      'AEGIS_PRO_PRODUCT_ID',
      defaultValue: 'aegis_pro',
    ),
    ProPlan.ultra: String.fromEnvironment(
      'AEGIS_ULTRA_PRODUCT_ID',
      defaultValue: 'aegis_ultra',
    ),
  };
  static const _storage = FlutterSecureStorage();
  static const simulatorEnabled =
      kDebugMode || bool.fromEnvironment('AEGIS_OWNER_TESTING');
  InAppPurchase get store => InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  Timer? _restoreTimeout;
  final Map<String, ProductDetails> offers = {};
  ProPlan _purchasedPlan = ProPlan.free;
  ProPlan? _debugPlan;
  ProPlan get plan =>
      simulatorEnabled ? (_debugPlan ?? _purchasedPlan) : _purchasedPlan;
  PlanConfiguration get limits => PlanConfiguration.values[plan]!;
  bool available = false, busy = false, usageReady = false;
  String? error;
  String? statusMessage;
  int aiRequestsToday = 0, pdfExportsThisMonth = 0;
  DateTime? _aiDay, _pdfMonth;
  bool _aiReserved = false, _pdfReserved = false;

  static const names = <ProPlan, String>{
    ProPlan.free: 'Free',
    ProPlan.pro: 'Pro',
    ProPlan.ultra: 'Ultra',
  };

  bool allows(FeatureAccess feature) {
    if (feature == FeatureAccess.basicText ||
        feature == FeatureAccess.basicUrl ||
        feature == FeatureAccess.basicRecovery ||
        feature == FeatureAccess.safetyGuides) {
      return true;
    }
    if (feature == FeatureAccess.screenshot) {
      return plan == ProPlan.pro || plan == ProPlan.ultra;
    }
    return plan == ProPlan.pro || plan == ProPlan.ultra;
  }

  int? get aiLimit => limits.aiPerDay;
  int? get pdfLimit => limits.pdfPerMonth;
  int? get aiRemaining =>
      aiLimit == null ? null : (aiLimit! - aiRequestsToday).clamp(0, aiLimit!);
  int? get pdfRemaining => pdfLimit == null
      ? null
      : (pdfLimit! - pdfExportsThisMonth).clamp(0, pdfLimit!);
  DateTime get nextAiReset {
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day + 1);
  }

  DateTime get nextPdfReset {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1);
  }

  Future<void> initialize() async {
    await _loadUsage();
    if (kIsWeb) {
      available = false;
      notifyListeners();
      return;
    }
    try {
      _subscription ??= store.purchaseStream.listen(
        _onPurchases,
        onError: (Object _) {
          error =
              'The store could not complete that request. Please try again.';
          busy = false;
          notifyListeners();
        },
      );
      available = await store.isAvailable();
      final ids = products.values.where((id) => id.isNotEmpty).toSet();
      if (available && ids.isNotEmpty) {
        final response = await store.queryProductDetails(ids);
        offers.addEntries(
          response.productDetails.map((p) => MapEntry(p.id, p)),
        );
        if (response.error != null) {
          statusMessage =
              'Some plans could not be loaded. Please try again later.';
        }
      }
      final cached = await _storage.read(key: 'aegis_purchase_product');
      if (cached != null && products.values.contains(cached)) {
        await store.restorePurchases();
      }
    } catch (_) {
      available = false;
      statusMessage =
          'The store could not be reached. You can try again later.';
    }
    notifyListeners();
  }

  Future<void> _loadUsage() async {
    try {
      final p = await SharedPreferences.getInstance();
      final now = DateTime.now();
      final storedDay = DateTime.tryParse(p.getString('aegis_ai_day') ?? '');
      final storedMonth = DateTime.tryParse(
        p.getString('aegis_pdf_month') ?? '',
      );
      _aiDay = DateTime(now.year, now.month, now.day);
      _pdfMonth = DateTime(now.year, now.month);
      aiRequestsToday = storedDay != null && _sameDay(storedDay, now)
          ? (p.getInt('aegis_ai_used') ?? 0).clamp(0, 1000000)
          : 0;
      pdfExportsThisMonth =
          storedMonth != null &&
              storedMonth.year == now.year &&
              storedMonth.month == now.month
          ? (p.getInt('aegis_pdf_used') ?? 0).clamp(0, 1000000)
          : 0;
      await p.setString('aegis_ai_day', _aiDay!.toIso8601String());
      await p.setInt('aegis_ai_used', aiRequestsToday);
      await p.setString('aegis_pdf_month', _pdfMonth!.toIso8601String());
      await p.setInt('aegis_pdf_used', pdfExportsThisMonth);
    } catch (_) {
      aiRequestsToday = 0;
      pdfExportsThisMonth = 0;
    }
    usageReady = true;
  }

  bool _sameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
  Future<void> _refreshPeriods() async {
    final now = DateTime.now();
    final day = DateTime(now.year, now.month, now.day);
    final month = DateTime(now.year, now.month);
    var changed = false;
    if (_aiDay == null || !_sameDay(_aiDay!, day)) {
      _aiDay = day;
      aiRequestsToday = 0;
      changed = true;
    }
    if (_pdfMonth == null ||
        _pdfMonth!.year != now.year ||
        _pdfMonth!.month != now.month) {
      _pdfMonth = month;
      pdfExportsThisMonth = 0;
      changed = true;
    }
    if (changed) await _persistUsage();
  }

  Future<void> _persistUsage() async {
    try {
      final p = await SharedPreferences.getInstance();
      await p.setString(
        'aegis_ai_day',
        (_aiDay ?? DateTime.now()).toIso8601String(),
      );
      await p.setInt('aegis_ai_used', aiRequestsToday);
      await p.setString(
        'aegis_pdf_month',
        (_pdfMonth ?? DateTime.now()).toIso8601String(),
      );
      await p.setInt('aegis_pdf_used', pdfExportsThisMonth);
    } catch (_) {}
  }

  Future<bool> reserveAiRequest() async {
    await _refreshPeriods();
    if (plan == ProPlan.free ||
        _aiReserved ||
        (aiLimit != null && aiRequestsToday >= aiLimit!)) {
      return false;
    }
    _aiReserved = true;
    return true;
  }

  Future<void> finishAiRequest({required bool succeeded}) async {
    if (!_aiReserved) return;
    _aiReserved = false;
    if (succeeded) {
      await _refreshPeriods();
      aiRequestsToday++;
      await _persistUsage();
      notifyListeners();
    }
  }

  Future<bool> reservePdfExport() async {
    await _refreshPeriods();
    if (_pdfReserved ||
        (pdfLimit != null && pdfExportsThisMonth >= pdfLimit!)) {
      return false;
    }
    _pdfReserved = true;
    return true;
  }

  Future<void> finishPdfExport({required bool succeeded}) async {
    if (!_pdfReserved) return;
    _pdfReserved = false;
    if (succeeded) {
      await _refreshPeriods();
      pdfExportsThisMonth++;
      await _persistUsage();
      notifyListeners();
    }
  }

  Future<void> resetDailyUsage() async {
    aiRequestsToday = 0;
    final n = DateTime.now();
    _aiDay = DateTime(n.year, n.month, n.day);
    await _persistUsage();
    notifyListeners();
  }

  Future<void> resetMonthlyUsage() async {
    pdfExportsThisMonth = 0;
    final n = DateTime.now();
    _pdfMonth = DateTime(n.year, n.month);
    await _persistUsage();
    notifyListeners();
  }

  Future<void> clearUsage() async {
    aiRequestsToday = 0;
    pdfExportsThisMonth = 0;
    final n = DateTime.now();
    _aiDay = DateTime(n.year, n.month, n.day);
    _pdfMonth = DateTime(n.year, n.month);
    await _persistUsage();
    notifyListeners();
  }

  @visibleForTesting
  Future<void> loadUsageForTest() => _loadUsage();

  void setDebugPlan(ProPlan value) {
    if (!simulatorEnabled) return;
    _debugPlan = value;
    notifyListeners();
  }

  Future<void> buy(ProPlan selected) async {
    if (selected == ProPlan.free) return;
    final id = products[selected] ?? '';
    final product = offers[id];
    if (id.isEmpty || product == null) {
      error = available
          ? 'This plan is not available in this store listing yet.'
          : 'Purchases are supported in the configured Aegis Android app.';
      notifyListeners();
      return;
    }
    busy = true;
    error = null;
    notifyListeners();
    try {
      await store.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: product),
      );
    } catch (_) {
      busy = false;
      error = 'We could not start the purchase. Please try again.';
      notifyListeners();
    }
  }

  Future<void> restore() async {
    busy = true;
    error = null;
    notifyListeners();
    try {
      await store.restorePurchases();
      _restoreTimeout?.cancel();
      _restoreTimeout = Timer(const Duration(seconds: 4), () {
        if (busy) {
          busy = false;
          statusMessage ??=
              'The store found no completed purchases to restore.';
          notifyListeners();
        }
      });
    } catch (_) {
      busy = false;
      error = 'Purchases could not be restored right now. Please try again.';
      notifyListeners();
    }
  }

  void simulatePurchase(ProPlan selected) => setDebugPlan(selected);

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    _restoreTimeout?.cancel();
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        final match = products.entries
            .where((e) => e.value.isNotEmpty && e.value == purchase.productID)
            .firstOrNull;
        if (match != null &&
            purchase.verificationData.serverVerificationData.isNotEmpty) {
          _purchasedPlan = match.key;
          statusMessage =
              'Your ${match.key.name} purchase is active on this device.';
          try {
            await _storage.write(
              key: 'aegis_purchase_product',
              value: purchase.productID,
            );
          } catch (_) {
            statusMessage =
                'Purchase is active for this session. Restore it from the store if needed later.';
          }
        }
      } else if (purchase.status == PurchaseStatus.error) {
        error = 'The purchase did not complete. You were not charged by Aegis.';
      } else if (purchase.status == PurchaseStatus.canceled) {
        statusMessage = 'Purchase canceled. Your plan has not changed.';
      } else if (purchase.status == PurchaseStatus.pending) {
        statusMessage =
            'Purchase pending. Access will update after the store confirms it.';
      }
      if (purchase.pendingCompletePurchase) {
        try {
          await store.completePurchase(purchase);
        } catch (_) {
          statusMessage =
              'Purchase processing needs another store sync. Restore purchases if access does not appear.';
        }
      }
    }
    busy = false;
    notifyListeners();
  }

  @visibleForTesting
  void setPlanForTest(ProPlan value) {
    if (!kDebugMode) return;
    _purchasedPlan = value;
    _debugPlan = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _restoreTimeout?.cancel();
    _subscription?.cancel();
    super.dispose();
  }
}
