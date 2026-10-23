import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../features/settings/presentation/providers/settings_provider.dart';

/// Identificadores de las unidades de anuncio reales de ByeBill (AdMob).
class AdUnitIds {
  AdUnitIds._();

  static const String banner = 'ca-app-pub-2359082752179381/3324135439';
  static const String native = 'ca-app-pub-2359082752179381/1819482079';
  static const String interstitial = 'ca-app-pub-2359082752179381/2940992054';
}

/// Proveedor: la publicidad SOLO se muestra en la versión FREE.
final adsEnabledProvider = Provider<bool>((ref) {
  final settings = ref.watch(settingsProvider).valueOrNull;
  return !(settings?.isPremium ?? false);
});

/// Servicio central de publicidad.
///
/// Se encarga de inicializar AdMob, de recoger el consentimiento GDPR (UMP)
/// y de gestionar el intersticial: precarga en segundo plano y limita su
/// frecuencia a 1 como mucho cada 15 minutos (persistido en SharedPreferences).
class AdService {
  AdService() {
    _preloadInterstitial();
  }

  static const String _keyLastInterstitial = 'ads_last_interstitial_ts';
  static const Duration _interstitialCooldown = Duration(minutes: 15);

  InterstitialAd? _interstitial;
  bool _loadingInterstitial = false;

  /// Inicialización única de AdMob + consentimiento UMP (GDPR).
  /// Debe llamarse una sola vez al arrancar la app (desde `main()`).
  static Future<void> initMobileAds() async {
    try {
      await MobileAds.instance.initialize();
      // Dispositivo de prueba: el Xiaomi de desarrollo siempre recibe
      // anuncios de prueba (sin invalidar la cuenta ni mover dinero).
      MobileAds.instance.updateRequestConfiguration(
        RequestConfiguration(
          testDeviceIds: <String>['23272BAA460932945AA7FFB52D5A9D23'],
        ),
      );
    } catch (e) {
      // ignore: avoid_print
      print('[ADS] ❌ MobileAds.initialize: $e');
    }
    await _requestConsent();
  }

  static Future<void> _requestConsent() async {
    try {
      // La petición de actualización es asíncrona por callbacks (void) y
      // dispara el formulario de consentimiento cuando es necesario (UE/EEE).
      ConsentInformation.instance.requestConsentInfoUpdate(
        ConsentRequestParameters(),
        () async {
          // Si el formulario de consentimiento está disponible, mostrarlo
          // antes de cargar anuncios personalizados.
          if (await ConsentInformation.instance.isConsentFormAvailable()) {
            await ConsentForm.loadAndShowConsentFormIfRequired(
              (formError) {
                // ignore: avoid_print
                print('[ADS] ${formError == null ? '✅ consentimiento UMP correcto' : '⚠️ consentimiento UMP: ${formError.message}'}');
              },
            );
          }
        },
        (error) {
          // ignore: avoid_print
          print('[ADS] ❌ error consentimiento UMP: ${error.message}');
        },
      );
    } catch (e) {
      // ignore: avoid_print
      print('[ADS] ❌ excepción consentimiento UMP: $e');
    }
  }

  /// Precarga el intersticial en segundo plano para tenerlo listo cuando se
  /// necesite (tras marcar una suscripción como cancelada).
  void _preloadInterstitial() {
    if (_loadingInterstitial || _interstitial != null) return;
    _loadingInterstitial = true;
    InterstitialAd.load(
      adUnitId: AdUnitIds.interstitial,
      request: const AdRequest(),
      adLoadCallback: InterstitialAdLoadCallback(
        onAdLoaded: (ad) {
          _interstitial = ad;
          _loadingInterstitial = false;
        },
        onAdFailedToLoad: (error) {
          _loadingInterstitial = false;
          // Reintento pasivo para no dejar el canal sin anuncio disponible.
          Future.delayed(const Duration(seconds: 30), _preloadInterstitial);
        },
      ),
    );
  }

  /// Indica si es el momento de mostrar el intersticial: que haya uno cargado
  /// y que haya pasado el límite de 1 cada 15 minutos.
  Future<bool> _canShowInterstitial() async {
    if (_interstitial == null) return false;
    final prefs = await SharedPreferences.getInstance();
    final last = prefs.getInt(_keyLastInterstitial) ?? 0;
    final elapsed = DateTime.now().millisecondsSinceEpoch - last;
    return elapsed >= _interstitialCooldown.inMilliseconds;
  }

  /// Muestra el intersticial si es el momento (máx. 1 cada 15 min).
  /// Devuelve `true` si llegó a mostrarse.
  Future<bool> maybeShowInterstitial() async {
    final ad = _interstitial;
    if (ad == null) return false;
    if (!await _canShowInterstitial()) return false;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(
      _keyLastInterstitial,
      DateTime.now().millisecondsSinceEpoch,
    );

    ad.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (_) {
        _interstitial = null;
        _preloadInterstitial();
      },
      onAdFailedToShowFullScreenContent: (_, __) {
        _interstitial = null;
        _preloadInterstitial();
      },
    );

    await ad.show();
    return true;
  }

  void dispose() {
    _interstitial?.dispose();
    _interstitial = null;
  }
}

final adServiceProvider = Provider<AdService>((ref) {
  final service = AdService();
  ref.onDispose(service.dispose);
  return service;
});