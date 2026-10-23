import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Identificadores de los productos Premium (deben coincidir EXACTAMENTE
/// con los creados en Play Console → Productos in-app y App Store Connect).
class PremiumProductIds {
  /// Suscripción auto-renovable mensual.
  static const String monthly = 'premium_mensual';

  /// Suscripción auto-renovable anual.
  static const String yearly = 'premium_anual';

  /// Compra única de por vida (no consumible).
  static const String lifetime = 'premium_vitalicio';

  static const Set<String> all = {monthly, yearly, lifetime};

  /// Marca de tiempo UNIX (segundos) que representa "nunca expira" para el
  /// plan vitalicio. Corresponde aproximadamente al año 2100.
  static const int lifeUntilTs = 4102444800;
}

/// Encargado de toda la lógica de compras in-app de Google Play / App Store.
///
/// - Escucha el flujo de compras ([purchaseStream]) y notifica vía
///   [onPremiumGranted] cuando un plan se compra o se restaura con éxito
///   (el `SettingsNotifier` aplica el plan y calcula su expiración).
/// - Precarga la información de precios de los productos ([products]).
/// - Expone la compra de un plan ([buy]) y la restauración ([restore]).
class BillingService {
  BillingService({InAppPurchase? iap}) : _iap = iap ?? InAppPurchase.instance;

  final InAppPurchase _iap;
  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Productos disponibles del store (id → detalles con precios), rellenados
  /// al inicializar. La UI lo observa para pintar precios reales.
  final ValueNotifier<Map<String, ProductDetails>> products =
      ValueNotifier(const {});

  /// `true` mientras se lanza un flujo de compra o restauración.
  final ValueNotifier<bool> purchasing = ValueNotifier(false);

  /// Callback invocado cuando una compra se completa/restaura con éxito.
  /// Recibe el id del producto y la marca de tiempo de expiración (segundos).
  Future<void> Function(String productId, int expiryTs)? onPremiumGranted;

  bool _listening = false;

  /// Inicia la escucha del flujo de compras y precarga los productos.
  ///
  /// Es idempotente: se puede llamar desde el arranque de la app y desde la
  /// pantalla Premium sin riesgo de abrir varias suscripciones al stream.
  Future<void> init() async {
    if (_listening) return;
    _listening = true;

    _subscription = _iap.purchaseStream.listen(
      _onPurchases,
      onError: (Object e) {
        // ignore: avoid_print
        print('[BILLING] ❌ purchaseStream error: $e');
      },
    );

    await refreshProducts();
  }

  /// Consulta al store los precios de los productos y actualiza [products].
  Future<void> refreshProducts() async {
    try {
      final response = await _iap.queryProductDetails(PremiumProductIds.all);
      products.value = <String, ProductDetails>{
        for (final p in response.productDetails) p.id: p,
      };
      if (response.notFoundIDs.isNotEmpty) {
        // ignore: avoid_print
        print('[BILLING] ⚠️ Productos no encontrados en la consola: '
            '${response.notFoundIDs}');
      }
    } catch (e) {
      // ignore: avoid_print
      print('[BILLING] ❌ queryProductDetails error: $e');
    }
  }

  ProductDetails? productFor(String id) => products.value[id];

  /// Lanza el flujo de compra del plan indicado.
  ///
  /// El resultado no llega por el valor devuelto: llega por [purchaseStream]
  /// (el sistema abre su propia pantalla de confirmación). Devuelve `false`
  /// solo si no se pudo arrancar el flujo (p. ej. producto sin configurar).
  Future<bool> buy(String productId) async {
    var details = productFor(productId);
    if (details == null) {
      await refreshProducts();
      details = productFor(productId);
    }
    if (details == null) {
      // ignore: avoid_print
      print('[BILLING] ❌ Producto $productId no disponible (¿creado en la '
          'consola y con la app publicada?).');
      return false;
    }

    purchasing.value = true;
    try {
      // En Google Play y App Store tanto las suscripciones como la compra de
      // por vida se tramitan como producto no consumible.
      await _iap.buyNonConsumable(
        purchaseParam: PurchaseParam(productDetails: details),
      );
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('[BILLING] ❌ buy($productId) error: $e');
      return false;
    } finally {
      purchasing.value = false;
    }
  }

  /// Restaura las compras (para usuarios que cambian de dispositivo o
  /// reinstalan). Las compras/restauraciones llegan por [purchaseStream]
  /// (estado `restored`), que ya está escuchado en [_onPurchases] y aplica
  /// el plan correspondiente.
  Future<bool> restore() async {
    purchasing.value = true;
    try {
      await _iap.restorePurchases();
      return true;
    } catch (e) {
      // ignore: avoid_print
      print('[BILLING] ❌ restore() error: $e');
      return false;
    } finally {
      purchasing.value = false;
    }
  }

  Future<void> _onPurchases(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      switch (purchase.status) {
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          final granted = await _grant(purchase);
          if (granted && purchase.pendingCompletePurchase) {
            try {
              await _iap.completePurchase(purchase);
            } catch (e) {
              // ignore: avoid_print
              print('[BILLING] ❌ completePurchase error: $e');
            }
          }
        case PurchaseStatus.pending:
          // El pago está en curso (p. ej. compra diferida): esperar.
        case PurchaseStatus.canceled:
          // El usuario cerró la pantalla de pago: no hacer nada.
        case PurchaseStatus.error:
          // ignore: avoid_print
          print('[BILLING] ❌ compra con error: '
              '${purchase.error?.message ?? 'desconocido'}');
      }
    }
  }

  /// Aplica el plan comprado: calcula la expiración según el ciclo y delega
  /// en [onPremiumGranted] (que es quien actualiza los ajustes de la app).
  Future<bool> _grant(PurchaseDetails purchase) async {
    final String id = purchase.productID;
    if (!PremiumProductIds.all.contains(id)) return false;

    final nowMs = DateTime.now().millisecondsSinceEpoch;
    final purchasedSec =
        (int.tryParse(purchase.transactionDate ?? '') ?? nowMs) ~/ 1000;
    const day = 86400;

    // Duración de la validez del plan (las suscripciones auto-renovables se
    // estiman con la fecha de la última transacción + su ciclo; Play/Billing
    // renueva y la app prolonga al arrancar o al recibir la renovación).
    final expirySec = switch (id) {
      PremiumProductIds.monthly => purchasedSec + 30 * day,
      PremiumProductIds.yearly => purchasedSec + 365 * day,
      PremiumProductIds.lifetime => PremiumProductIds.lifeUntilTs,
      _ => 0,
    };

    final callback = onPremiumGranted;
    if (callback == null) {
      // ignore: avoid_print
      print('[BILLING] ⚠️ Compra válida pero sin callback (onPremiumGranted).');
      return false;
    }
    await callback(id, expirySec);
    return true;
  }

  /// Cancela la escucha (no se usa en producción: el servicio vive toda la
  /// vida de la app, pero se deja por completitud).
  void dispose() {
    unawaited(_subscription?.cancel());
    _subscription = null;
    purchasing.dispose();
  }
}

final billingServiceProvider = Provider<BillingService>(
  (ref) => BillingService(),
);