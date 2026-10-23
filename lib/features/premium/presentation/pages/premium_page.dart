import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

import '../../../../core/services/billing_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../settings/presentation/providers/settings_provider.dart';

class PremiumPage extends ConsumerStatefulWidget {
  const PremiumPage({super.key});

  @override
  ConsumerState<PremiumPage> createState() => _PremiumPageState();
}

class _PremiumPageState extends ConsumerState<PremiumPage> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  int _selectedPlanIndex = 2; // 0: Mensual, 1: Anual, 2: De por vida
  bool _buying = false;
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();

    final billing = ref.read(billingServiceProvider);
    // Cuando una compra o restauración se completa, aplica el plan en los
    // ajustes (Guardarlo en SharedPreferences + activar Premium).
    billing.onPremiumGranted = (productId, expiryTs) =>
        ref.read(settingsProvider.notifier).grantPremium(productId, expiryTs);
    // Apaga el spinner cuando el flujo de compra/restauración termina
    // (éxito, error o cancelación), porque es el único caso en que no llega
    // la notificación vía isPremium.
    billing.purchasing.addListener(_onPurchasingChanged);
    // Precarga precios y escucha el flujo de compras (idempotente).
    // ignore: unawaited_futures
    billing.init();
  }

  void _onPurchasingChanged() {
    if (!mounted || !_buying) return;
    if (ref.read(billingServiceProvider).purchasing.value) return;
    // El flujo terminó sin conceder el plan (fallo o cancelación).
    setState(() => _buying = false);
  }

  /// Lanza la compra del plan seleccionado.
  Future<void> _buyPlan() async {
    final productId = switch (_selectedPlanIndex) {
      0 => PremiumProductIds.monthly,
      1 => PremiumProductIds.yearly,
      _ => PremiumProductIds.lifetime,
    };

    setState(() => _buying = true);
    final ok = await ref.read(billingServiceProvider).buy(productId);
    if (!mounted) return;
    if (!ok) {
      _showError(AppStrings.t(
        'No se pudo iniciar el proceso de compra. Inténtalo de nuevo.',
        'Unable to start the purchase. Please try again.',
        'Impossibile avviare l\'acquisto. Riprova.',
      ));
    }
  }

  /// Restaura compras anteriores (al reinstalar o cambiar de dispositivo).
  Future<void> _restorePurchases() async {
    setState(() => _buying = true);
    final ok = await ref.read(billingServiceProvider).restore();
    if (!mounted) return;
    if (!ok) {
      _showError(AppStrings.t(
        'No se pudo restaurar las compras. Inténtalo de nuevo.',
        'Unable to restore purchases. Please try again.',
        'Impossibile ripristinare gli acquisti. Riprova.',
      ));
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  void dispose() {
    final billing = ref.read(billingServiceProvider);
    billing.purchasing.removeListener(_onPurchasingChanged);
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final isPremium = settingsAsync.valueOrNull?.isPremium ?? false;
    // Gira el spinner mientras se compra/restaura; se apaga solo cuando el
    // plan ya está concedido (el watch cambia isPremium) o si la compra falla
    // antes de arrancar (en cuyo caso _buying se resetea en _buyPlan).
    final showBuySpinner = _buying && !isPremium;

    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Fondo animado / Gradiente
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    AppColors.primary.withValues(alpha: 0.1),
                    AppColors.background,
                    AppColors.background,
                  ],
                ),
              ),
            ),
          ),
          
          SafeArea(
            child: Column(
              children: [
                // Header (Close button)
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.close, color: AppColors.onSurface, size: 28),
                        onPressed: () => context.pop(),
                      ),
                    ],
                  ),
                ),
                
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const SizedBox(height: 10),
                          // Icono Premium animado
                          AnimatedBuilder(
                            animation: _controller,
                            builder: (context, child) {
                              return Transform.rotate(
                                angle: sin(_controller.value * 2 * pi) * 0.1,
                                child: Container(
                                  padding: const EdgeInsets.all(20),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    shape: BoxShape.circle,
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.amber.withValues(alpha: 0.3),
                                        blurRadius: 30,
                                        spreadRadius: 5,
                                      )
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.workspace_premium,
                                    color: Colors.amber,
                                    size: 60,
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 30),
                          
                          // Titulo
                          Text(
                            AppStrings.t('ByeBill Premium', 'ByeBill Premium', 'ByeBill Premium'),
                            style: const TextStyle(
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                              color: AppColors.onSurface,
                              letterSpacing: -1,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Text(
                            AppStrings.t(
                              'Toma el control total de tus suscripciones y ahorra aún más dinero.',
                              'Take full control of your subscriptions and save even more money.',
                              'Prendi il controllo totale dei tuoi abbonamenti e risparmia ancora di più.',
                            ),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: AppColors.secondary,
                              height: 1.4,
                            ),
                          ),
                          
                          const SizedBox(height: 40),
                          
                          // Ventajas
                          _buildBenefitRow(
                            icon: Icons.notifications_active_outlined,
                            title: AppStrings.t('Avisos anticipados (7 días)', 'Early warnings (7 days)', 'Avvisi anticipati (7 giorni)'),
                            description: AppStrings.t(
                              'No te lleves sustos. Te avisamos una semana antes del cobro.',
                              'No surprises. We warn you a week before the charge.',
                              'Niente sorprese. Ti avvisiamo una settimana prima dell\'addebito.',
                            ),
                          ),
                          _buildBenefitRow(
                            icon: Icons.not_interested,
                            title: AppStrings.premiumBenefitAdFreeTitle,
                            description: AppStrings.premiumBenefitAdFreeDesc,
                          ),
                          _buildBenefitRow(
                            icon: Icons.all_inclusive,
                            title: AppStrings.t('Suscripciones ilimitadas', 'Unlimited subscriptions', 'Abbonamenti illimitati'),
                            description: AppStrings.t(
                              'Añade tantos servicios como necesites sin restricciones.',
                              'Add as many services as you need without restrictions.',
                              'Aggiungi tutti i servizi di cui hai bisogno senza restrizioni.',
                            ),
                          ),
                          
                          const SizedBox(height: 10),
                          
                          // Selector de Planes
                          if (!isPremium) ...[
                            _buildPlanSelector(settingsAsync.valueOrNull?.currency ?? '€'),
                            const SizedBox(height: 30),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
                
                // Botón Inferior
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.onSurface.withValues(alpha: 0.05),
                        offset: const Offset(0, -10),
                        blurRadius: 20,
                      )
                    ],
                  ),
                  child: SafeArea(
                    top: false,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                          SizedBox(
                          width: double.infinity,
                          height: 56,
                          child: ElevatedButton(
                            onPressed: _buying
                                ? null
                                : () {
                                    if (isPremium) {
                                      context.pop();
                                    } else {
                                      _buyPlan();
                                    }
                                  },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: isPremium ? Colors.grey.shade400 : AppColors.primary,
                              foregroundColor: Colors.white,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                            ),
                            child: showBuySpinner
                                ? const SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: Colors.white,
                                      strokeWidth: 3,
                                    ),
                                  )
                                : Text(
                                    isPremium
                                      ? AppStrings.t('Ya eres Premium', 'You are Premium', 'Sei già Premium')
                                      : _getCTAButtonText(settingsAsync.valueOrNull?.currency ?? '€'),
                                    style: const TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                          ),
                        ),
                        if (!isPremium) ...[
                          const SizedBox(height: 16),
                          GestureDetector(
                            onTap: _buying ? null : _restorePurchases,
                            child: Text(
                              AppStrings.t('Restaurar compras', 'Restore purchases', 'Ripristina acquisti'),
                              style: const TextStyle(
                                color: AppColors.secondary,
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitRow({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: AppColors.primary, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.secondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _getCTAButtonText(String c) {
    if (_selectedPlanIndex == 0) {
      return AppStrings.t('Suscribirse por 2,99 $c/mes', 'Subscribe for 2.99 $c/mo', 'Abbonati per 2,99 $c/mese');
    } else if (_selectedPlanIndex == 1) {
      return AppStrings.t('Suscribirse por 19,99 $c/año', 'Subscribe for 19.99 $c/yr', 'Abbonati per 19,99 $c/anno');
    }
    return AppStrings.t('Desbloquear por 34,99 $c', 'Unlock for 34.99 $c', 'Sblocca per 34,99 $c');
  }

  Widget _buildPlanSelector(String currency) {
    return Column(
      children: [
        _buildPlanCard(
          index: 0,
          title: AppStrings.premiumPlanMonthly,
          price: AppStrings.premiumPlanMonthlyPrice(currency),
        ),
        _buildPlanCard(
          index: 1,
          title: AppStrings.premiumPlanAnnual,
          price: AppStrings.premiumPlanAnnualPrice(currency),
          subtitle: AppStrings.premiumPlanAnnualDesc(currency),
        ),
        _buildPlanCard(
          index: 2,
          title: AppStrings.premiumPlanLifetime,
          price: AppStrings.premiumPlanLifetimePrice(currency),
          subtitle: AppStrings.premiumPlanLifetimeDesc,
          isMostPopular: true,
        ),
      ],
    );
  }

  Widget _buildPlanCard({
    required int index,
    required String title,
    required String price,
    String? subtitle,
    bool isMostPopular = false,
  }) {
    final isSelected = _selectedPlanIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedPlanIndex = index;
        });
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.shade200,
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Row(
                children: [
                  Icon(
                    isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
                    color: isSelected ? AppColors.primary : Colors.grey.shade400,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                            color: AppColors.onSurface,
                          ),
                        ),
                        if (subtitle != null) ...[
                          const SizedBox(height: 2),
                          Text(
                            subtitle,
                            style: const TextStyle(
                              fontSize: 13,
                              color: AppColors.secondary,
                            ),
                          ),
                        ]
                      ],
                    ),
                  ),
                  Text(
                    price,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w700,
                      color: AppColors.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            if (isMostPopular)
              Positioned(
                top: -10,
                right: 20,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.amber,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    AppStrings.premiumMostPopular,
                    style: const TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w900,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}