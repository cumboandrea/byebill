import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';

import '../../services/ad_service.dart';

/// Banner adaptativo (ancho completo) mostrado de forma fija encima de la
/// barra de navegación en la versión FREE.
class AdBannerWidget extends StatefulWidget {
  const AdBannerWidget({super.key});

  @override
  State<AdBannerWidget> createState() => _AdBannerWidgetState();
}

class _AdBannerWidgetState extends State<AdBannerWidget> {
  static const Duration _retryDelay = Duration(seconds: 30);

  BannerAd? _bannerAd;
  AdSize? _adSize;
  bool _isLoaded = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    // MediaQuery.of no puede usarse hasta que initState termina: se difiere
    // la creación del banner al primer frame (necesita el ancho de pantalla).
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _createBannerAd();
    });
  }

  Future<void> _createBannerAd() async {
    _retryTimer?.cancel();
    if (_isLoaded) return;
    _bannerAd?.dispose();
    _bannerAd = null;
    try {
      // Anchored adaptive banner: usa el ancho real disponible.
      final width = MediaQuery.of(context).size.width.toInt();
      AdSize? size;
      try {
        size = await AdSize.getLargeAnchoredAdaptiveBannerAdSize(width);
      } catch (_) {
        // ignore: avoid_print
        print('[ADS] ⚠️ tamaño adaptativo no disponible, se usa 320x50');
      }
      if (!mounted) return;
      final bannerAd = BannerAd(
        size: size ?? AdSize.banner,
        adUnitId: AdUnitIds.banner,
        listener: BannerAdListener(
          onAdLoaded: (ad) {
            final loadedBanner = ad as BannerAd;
            // ignore: avoid_print
            print('[ADS] ✅ banner cargado ${loadedBanner.size.width}x${loadedBanner.size.height}');
            if (mounted) {
              setState(() {
                _adSize = loadedBanner.size;
                _isLoaded = true;
              });
            }
          },
          onAdFailedToLoad: (ad, error) {
            // ignore: avoid_print
            print('[ADS] ❌ banner fallo: ${error.code} - ${error.message}');
            ad.dispose();
            _scheduleRetry();
          },
        ),
        request: const AdRequest(),
      );
      _bannerAd = bannerAd;
      bannerAd.load();
    } catch (e) {
      // ignore: avoid_print
      print('[ADS] ❌ banner: $e');
      _scheduleRetry();
    }
  }

  /// Reintenta la carga en segundo plano: el banner puede fallar una primera
  /// vez (ej. sin anuncios disponibles) y debe aparecer solo cuando AdMob
  /// vuelva a tener fill, sin necesidad de reiniciar la app.
  void _scheduleRetry() {
    if (!mounted || _isLoaded) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (mounted && !_isLoaded) _createBannerAd();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _bannerAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Sin altura explícita el PlatformView del banner puede colapsar a 0px;
    // se fija el alto real del anuncio para garantizar que siempre renderice.
    if (_bannerAd == null || !_isLoaded || _adSize == null) {
      return const SizedBox.shrink();
    }
    return Container(
      width: double.infinity,
      color: Colors.white,
      alignment: Alignment.bottomCenter,
      child: SizedBox(
        width: _adSize!.width.toDouble(),
        height: _adSize!.height.toDouble(),
        child: AdWidget(ad: _bannerAd!),
      ),
    );
  }
}

/// Anuncio nativo mostrado en la lista del Home (entre "Atención requerida"
/// y "Suscripciones activas") en la versión FREE.
class AdNativeWidget extends StatefulWidget {
  const AdNativeWidget({super.key});

  @override
  State<AdNativeWidget> createState() => _AdNativeWidgetState();
}

class _AdNativeWidgetState extends State<AdNativeWidget> {
  static const Duration _retryDelay = Duration(seconds: 30);

  NativeAd? _nativeAd;
  bool _isLoaded = false;
  Timer? _retryTimer;

  @override
  void initState() {
    super.initState();
    _createNativeAd();
  }

  void _createNativeAd() {
    _retryTimer?.cancel();
    if (_isLoaded) return;
    _nativeAd?.dispose();
    _nativeAd = null;
    try {
      final nativeAd = NativeAd(
        adUnitId: AdUnitIds.native,
        request: const AdRequest(),
        nativeTemplateStyle: NativeTemplateStyle(
          templateType: TemplateType.medium,
          mainBackgroundColor: Colors.white,
          cornerRadius: 16,
        ),
        listener: NativeAdListener(
          onAdLoaded: (_) {
            // ignore: avoid_print
            print('[ADS] ✅ nativo cargado');
            if (mounted) setState(() => _isLoaded = true);
          },
          onAdFailedToLoad: (ad, error) {
            // ignore: avoid_print
            print('[ADS] ❌ nativo fallo: ${error.code} - ${error.message}');
            ad.dispose();
            _scheduleRetry();
          },
        ),
      );
      _nativeAd = nativeAd;
      nativeAd.load();
    } catch (e) {
      // ignore: avoid_print
      print('[ADS] ❌ nativo: $e');
      _scheduleRetry();
    }
  }

  /// Reintenta la carga en segundo plano (misma lógica que el banner).
  void _scheduleRetry() {
    if (!mounted || _isLoaded) return;
    _retryTimer?.cancel();
    _retryTimer = Timer(_retryDelay, () {
      if (mounted && !_isLoaded) _createNativeAd();
    });
  }

  @override
  void dispose() {
    _retryTimer?.cancel();
    _nativeAd?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_nativeAd == null || !_isLoaded) {
      return const SizedBox.shrink();
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        color: Colors.white,
        child: SizedBox(
          height: 150,
          child: AdWidget(ad: _nativeAd!),
        ),
      ),
    );
  }
}