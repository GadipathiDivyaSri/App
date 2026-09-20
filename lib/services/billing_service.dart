import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Singleton Service handling live Google Play Billing for WrindhaOS
class BillingService extends ChangeNotifier {
  static final BillingService _instance = BillingService._internal();
  factory BillingService() => _instance;
  BillingService._internal();

  static const String proSubscriptionId = 'wrindha_pro_monthly';

  final InAppPurchase _iap = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _purchaseSubscription;

  bool isAvailable = false;
  ProductDetails? proProduct;
  bool isProcessing = false;
  String? errorMessage;
  Function(bool)? _onProStatusChanged;

  /// Returns localized price string directly from Google Play Store or default fallback
  String get formattedPrice => proProduct?.price ?? '₹49 / month';

  /// Initialize early in app lifecycle (AppProvider / main)
  Future<void> initialize({Function(bool)? onProStatusChanged}) async {
    _onProStatusChanged = onProStatusChanged;

    try {
      isAvailable = await _iap.isAvailable();
    } catch (e) {
      isAvailable = false;
      if (kDebugMode) {
        print('[BILLING SERVICE] Play Billing check error: $e');
      }
    }

    if (!isAvailable) {
      if (kDebugMode) {
        print('[BILLING SERVICE] Google Play Store Billing is not available on this device/environment.');
      }
      notifyListeners();
      return;
    }

    // Subscribe to continuous purchase updates
    _purchaseSubscription?.cancel();
    _purchaseSubscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onDone: () => _purchaseSubscription?.cancel(),
      onError: (error) {
        errorMessage = error.toString();
        notifyListeners();
      },
    );

    // Load live Product Details from Google Play Store
    await queryProducts();
  }

  /// Query Google Play Store for the wrindha_pro_monthly product
  Future<void> queryProducts() async {
    try {
      isAvailable = await _iap.isAvailable();
    } catch (e) {
      isAvailable = false;
    }

    if (!isAvailable) {
      errorMessage = 'Google Play Store billing is unavailable on this device.';
      if (kDebugMode) {
        print('[BILLING SERVICE] Google Play Store Billing is not available on this device/environment.');
      }
      notifyListeners();
      return;
    }

    // Subscribe to continuous purchase updates if not already subscribed
    if (_purchaseSubscription == null) {
      _purchaseSubscription = _iap.purchaseStream.listen(
        _handlePurchaseUpdates,
        onDone: () => _purchaseSubscription?.cancel(),
        onError: (error) {
          errorMessage = error.toString();
          notifyListeners();
        },
      );
    }

    try {
      final ProductDetailsResponse response = await _iap.queryProductDetails({proSubscriptionId});
      if (response.error != null) {
        errorMessage = response.error!.message;
        if (kDebugMode) {
          print('[BILLING SERVICE] Query Product Error: ${response.error!.message}');
        }
      } else if (response.productDetails.isNotEmpty) {
        proProduct = response.productDetails.first;
        errorMessage = null;
        if (kDebugMode) {
          print('[BILLING SERVICE] Found Product: ${proProduct!.id} - Price: ${proProduct!.price}');
        }
      } else {
        errorMessage = 'Product "$proSubscriptionId" pending Play Console activation or app download via Play Store link.';
        if (kDebugMode) {
          print('[BILLING SERVICE] Product "$proSubscriptionId" not found in Google Play Console.');
        }
      }
    } catch (e) {
      errorMessage = e.toString();
      if (kDebugMode) {
        print('[BILLING SERVICE] Exception querying products: $e');
      }
    }
    notifyListeners();
  }

  /// Trigger live Google Play purchase flow
  Future<bool> buyProSubscription() async {
    if (!isAvailable) {
      errorMessage = 'Google Play Store billing is not available on this device.';
      notifyListeners();
      return false;
    }

    if (proProduct == null) {
      await queryProducts();
    }

    if (proProduct == null) {
      if (errorMessage == null || errorMessage!.isEmpty) {
        errorMessage = 'Subscription product "$proSubscriptionId" details not returned by Google Play.';
      }
      notifyListeners();
      return false;
    }

    isProcessing = true;
    errorMessage = null;
    notifyListeners();

    try {
      final PurchaseParam purchaseParam = PurchaseParam(productDetails: proProduct!);
      final bool success = await _iap.buyNonConsumable(purchaseParam: purchaseParam);
      if (!success) {
        isProcessing = false;
        errorMessage = 'Failed to launch Google Play purchase sheet.';
        notifyListeners();
      }
      return success;
    } catch (e) {
      isProcessing = false;
      errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  /// Handle incoming transactions from Google Play
  void _handlePurchaseUpdates(List<PurchaseDetails> purchaseDetailsList) async {
    for (var purchase in purchaseDetailsList) {
      if (purchase.productID == proSubscriptionId) {
        switch (purchase.status) {
          case PurchaseStatus.purchased:
          case PurchaseStatus.restored:
            isProcessing = false;
            if (_onProStatusChanged != null) {
              _onProStatusChanged!(true);
            }
            // Mandatory: complete purchase with Google Play to finalize transaction
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            break;
          case PurchaseStatus.error:
            isProcessing = false;
            errorMessage = purchase.error?.message ?? 'Purchase failed or was canceled.';
            if (purchase.pendingCompletePurchase) {
              await _iap.completePurchase(purchase);
            }
            break;
          case PurchaseStatus.pending:
            isProcessing = true;
            break;
          case PurchaseStatus.canceled:
            isProcessing = false;
            errorMessage = 'Purchase was canceled.';
            break;
        }
      }
    }
    notifyListeners();
  }

  @override
  void dispose() {
    _purchaseSubscription?.cancel();
    super.dispose();
  }
}
