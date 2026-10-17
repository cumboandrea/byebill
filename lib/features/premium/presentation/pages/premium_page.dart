import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:math';

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
  
  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);
    final isPremium = settingsAsync.valueOrNull?.isPremium ?? false;

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
                            onPressed: () {
                              // Aquí iría la lógica de compras In-App
                              // Para la demo, simplemente cerramos si ya es premium
                              if (isPremium) {
                                context.pop();
                              } else {
                                // Lógica de In-App Purchase de Google/Apple
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
                            child: Text(
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
                            onTap: () {
                              // Restaurar compras
                            },
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