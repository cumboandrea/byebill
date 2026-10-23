import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../domain/entities/subscription.dart';
import '../../domain/enums/subscription_status.dart';
import '../../domain/enums/subscription_type.dart';
//import '../../domain/enums/billing_cycle.dart';
import '../providers/subscription_detail_provider.dart';
import '../providers/subscription_list_provider.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/ad_service.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/top_services.dart';
import '../../../../core/utils/date_utils.dart' as du;
//import 'add_subscription_page.dart';

class DetailSubscriptionPage extends ConsumerWidget {
  const DetailSubscriptionPage({super.key, required this.id});

  factory DetailSubscriptionPage.fromGoRouterState(GoRouterState state) {
    final id = state.pathParameters['id'] ?? '';
    return DetailSubscriptionPage(id: id);
  }

  final String id;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settingsAsync = ref.watch(settingsProvider);
    final currencySymbol = settingsAsync.valueOrNull?.currency ?? '€';

    return Scaffold(
      key: const ValueKey('detail_page'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        title: Text(
          'ByeBill',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: AppColors.primary,
          ),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20)
              .copyWith(top: 16, bottom: 200),
          child: ref.watch(subscriptionDetailProvider(id)).when(
                loading: () => Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                ),
                error: (e, _) => Center(
                  child: Text(
                    AppStrings.generalError,
                    style: TextStyle(color: AppColors.danger),
                  ),
                ),
                data: (sub) {
                  if (sub == null) {
                    Future<void>.microtask(() {
                      if (context.mounted) context.go('/home');
                    });
                    return Center(
                      child: CircularProgressIndicator(color: AppColors.primary),
                    );
                  }
                  return _DetailContent(
                    subscription: sub,
                    currencySymbol: currencySymbol,
                    isPremium: settingsAsync.valueOrNull?.isPremium ?? false,
                    notificationTime: settingsAsync.valueOrNull?.notificationTime ?? const TimeOfDay(hour: 9, minute: 0),
                  );
                },
              ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: ref.watch(subscriptionDetailProvider(id)).maybeWhen(
                data: (s) =>
                    s == null ? const SizedBox.shrink() : _ActionsBar(subscription: s),
                orElse: () => const SizedBox.shrink(),
              ),
        ),
      ),
    );
  }
}

class _DetailContent extends StatelessWidget {
  const _DetailContent({
    required this.subscription,
    required this.currencySymbol,
    required this.isPremium,
    required this.notificationTime,
  });

  final Subscription subscription;
  final String currencySymbol;
  final bool isPremium;
  final TimeOfDay notificationTime;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: _SubscriptionLogo(
                      logoPath: subscription.logoPath,
                      type: subscription.type,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          subscription.name,
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                        const SizedBox(height: 6),
                        _statusBadge(subscription.status),
                      ],
                    ),
                  ),
                ],
              ),
              if (subscription.description != null &&
                  subscription.description!.trim().isNotEmpty) ...[
                const SizedBox(height: 16),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.background,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.notes_outlined,
                          size: 18, color: AppColors.secondary),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          subscription.description!,
                          style: TextStyle(
                            fontSize: 13,
                            height: 1.4,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              const SizedBox(height: 24),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.background,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Importe',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          du.formatCurrency(subscription.amount, currencySymbol),
                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: AppColors.onSurface,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Fecha de cobro',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          du.formatDate(subscription.chargeDate),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppColors.onSurface,
                          ),
                        ),
                        if (subscription.startDate != null) ...[
                          const SizedBox(height: 4),
                          Text(
                            'Desde: ${du.formatDate(subscription.startDate!)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppColors.secondary,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.repeat,
                      label: 'Ciclo',
                      value: subscription.cycle.label,
                      valueBadge: subscription.type == SubscriptionType.freeTrial
                          ? AppStrings.freeTrialBadge
                          : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.payments_outlined,
                      label: 'Moneda',
                      value: subscription.currency,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.category_outlined,
                      label: 'Tipo',
                      value: subscription.type.label,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _InfoTile(
                      icon: Icons.notifications_active_outlined,
                      label: AppStrings.detailNextAlerts.split(' ')[0],
                      value: AppStrings.badgeDays(
                          du.daysUntil(subscription.chargeDate)),
                      highlight: du.daysUntil(subscription.chargeDate) <= 7,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppColors.onSurface.withValues(alpha: 0.04),
                blurRadius: 16,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                AppStrings.detailNextAlerts,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              _NextAlertsList(
                subscriptionId: subscription.id,
                chargeDate: subscription.chargeDate,
                isPremium: isPremium,
                notificationTime: notificationTime,
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Registro creado: ${du.formatDate(subscription.createdAt)}',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.secondary,
          ),
          textAlign: TextAlign.center,
        ),
        if (subscription.cancelledAt != null) ...[
          const SizedBox(height: 4),
          Text(
            'Dejaste de pagar el: ${du.formatDate(subscription.cancelledAt!)}',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.success,
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
        if (subscription.cancellationUrl != null) ...[
          const SizedBox(height: 24),
          _CancellationShortcutCard(subscription: subscription),
        ],
      ],
    );
  }
}

class _CancellationShortcutCard extends StatelessWidget {
  const _CancellationShortcutCard({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context) {
    final topService = topServices.where((s) => s.logoPath == subscription.logoPath || s.name.toLowerCase() == subscription.name.toLowerCase()).firstOrNull;
    final instructions = topService?.cancellationInstructions;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.bolt, color: AppColors.primary),
              const SizedBox(width: 8),
              const Text(
                'Atajo de cancelación directa',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: AppColors.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Te llevamos directamente a la página oficial de cancelación o gestionamos la plantilla.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (instructions != null) ...[
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.background,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.secondary.withValues(alpha: 0.1)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline, size: 16, color: AppColors.secondary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      instructions,
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.secondary,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
          GestureDetector(
            onTap: () async {
              final messenger = ScaffoldMessenger.of(context);
              messenger.showSnackBar(
                SnackBar(content: Text('Abriendo enlace de cancelación oficial...')),
              );
              final Uri? uri =
                  Uri.tryParse(subscription.cancellationUrl ?? '');
              if (uri == null || !uri.hasScheme) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.generalError),
                    backgroundColor: AppColors.danger,
                  ),
                );
                return;
              }
              final bool launched = await launchUrl(
                uri,
                mode: LaunchMode.externalApplication,
              );
              if (!launched) {
                messenger.showSnackBar(
                  SnackBar(
                    content: Text(AppStrings.generalError),
                    backgroundColor: AppColors.danger,
                  ),
                );
              }
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.verified, size: 16, color: AppColors.onSurface),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Abrir enlace oficial de ${subscription.name}',
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: AppColors.onSurface,
                          ),
                        ),
                        Text(
                          'Enlace cifrado y comprobado por ByeBill',
                          style: TextStyle(
                            fontSize: 12,
                            color: AppColors.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(Icons.open_in_new, color: AppColors.primary, size: 20),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubscriptionLogo extends StatelessWidget {
  const _SubscriptionLogo({required this.logoPath, required this.type});

  final String? logoPath;
  final SubscriptionType type;

  @override
  Widget build(BuildContext context) {
    final path = logoPath;
    if (path == null || path.isEmpty) {
      return Icon(
        type == SubscriptionType.freeTrial
            ? Icons.event_available
            : Icons.autorenew,
        size: 36,
        color: AppColors.primary,
      );
    }
    final Widget fallback = Icon(
      Icons.cloud_outlined,
      color: AppColors.primary,
      size: 26,
    );
    return ClipOval(
      child: path.toLowerCase().endsWith('.svg')
          ? SvgPicture.asset(
              path,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              placeholderBuilder: (context) => Container(
                width: 36,
                height: 36,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: fallback,
              ),
            )
          : Image.asset(
              path,
              width: 36,
              height: 36,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) => Container(
                width: 36,
                height: 36,
                color: AppColors.primary.withValues(alpha: 0.1),
                child: fallback,
              ),
            ),
    );
  }
}

Widget _statusBadge(SubscriptionStatus s) {
  final isCancelled = s == SubscriptionStatus.cancelled;
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
    decoration: BoxDecoration(
      color: isCancelled
          ? AppColors.success.withValues(alpha: 0.12)
          : AppColors.primary.withValues(alpha: 0.1),
      borderRadius: BorderRadius.circular(8),
    ),
    child: Text(
      s.label,
      style: TextStyle(
        fontSize: 12,
        fontWeight: FontWeight.w700,
        color: isCancelled ? AppColors.success : AppColors.primary,
      ),
    ),
  );
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.label,
    required this.value,
    required this.icon,
    this.highlight = false,
    this.valueBadge,
  });

  final String label;
  final String value;
  final IconData icon;
  final bool highlight;
  final String? valueBadge;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 18,
            color: highlight ? AppColors.warning : AppColors.secondary,
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: AppColors.secondary,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: highlight ? AppColors.warning : AppColors.onSurface,
                ),
              ),
              if (valueBadge != null) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    valueBadge!,
                    style: const TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: AppColors.success,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}

class _NextAlertsList extends ConsumerWidget {
  const _NextAlertsList({
    required this.subscriptionId,
    required this.chargeDate,
    required this.isPremium,
    required this.notificationTime,
  });

  final String subscriptionId;
  final DateTime chargeDate;
  final bool isPremium;
  final TimeOfDay notificationTime;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final ns = ref.watch(notificationServiceProvider);
    ns.countPendingFor(subscriptionId);
    
    final formattedTime = '${notificationTime.hour.toString().padLeft(2, '0')}:${notificationTime.minute.toString().padLeft(2, '0')}';
    
    return Column(
      children: [
        if (isPremium)
          _alertRow(7, Icons.notifications_active_outlined, chargeDate, 'En 7 días', notificationTime, formattedTime),
        _alertRow(2, Icons.warning_amber_outlined, chargeDate, 'En 2 días', notificationTime, formattedTime),
        _alertRow(0, Icons.alarm_on_outlined, chargeDate, 'Día del cobro ($formattedTime)', notificationTime, formattedTime),
      ],
    );
  }
}

Widget _alertRow(
    int daysBefore, IconData icon, DateTime charge, String label, TimeOfDay time, String formattedTime) {
  final date = charge
      .subtract(Duration(days: daysBefore))
      .copyWith(hour: time.hour, minute: time.minute);
  final isPast = date.isBefore(DateTime.now());
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isPast
                ? AppColors.secondary.withValues(alpha: 0.1)
                : AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(
            icon,
            size: 18,
            color: isPast ? AppColors.secondary : AppColors.primary,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: isPast ? AppColors.secondary : AppColors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${du.formatDate(date)} $formattedTime',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.secondary,
                ),
              ),
            ],
          ),
        ),
        if (isPast)
          Icon(
            Icons.check_circle,
            color: AppColors.secondary.withValues(alpha: 0.6),
            size: 16,
          )
        else
          Icon(
            Icons.schedule,
            color: AppColors.primary,
            size: 16,
          ),
      ],
    ),
  );
}

class _ActionsBar extends ConsumerWidget {
  const _ActionsBar({required this.subscription});

  final Subscription subscription;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (subscription.type == SubscriptionType.freeTrial && subscription.status == SubscriptionStatus.expired)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton.icon(
                onPressed: () async {
                  await ref
                      .read(subscriptionListProvider.notifier)
                      .transformToPaid(subscription.id);
                  if (context.mounted) {
                    final hasError = ref.read(subscriptionListProvider).hasError;
                    if (hasError) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(AppStrings.generalError),
                          backgroundColor: AppColors.danger,
                        ),
                      );
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: const Text('Convertida en suscripción de pago'),
                          backgroundColor: AppColors.success,
                        ),
                      );
                      context.go('/home');
                    }
                  }
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                icon: const Icon(Icons.autorenew, size: 20),
                label: const Text('He renovado y ahora es de pago'),
              ),
            ),
          ),
        if (subscription.status == SubscriptionStatus.active)
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton.icon(
              onPressed: () async {
                // Fecha en la que el usuario dejó de pagar. Por defecto hoy,
                // pero admite retroactividad: si la suscripción se renovó
                // automáticamente porque el usuario no abrió la app, puede
                // indicar que realmente la interrumpió el día que caducó.
                DateTime cancelledAt = DateTime.now();
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (c) => StatefulBuilder(
                    builder: (c, setState) => AlertDialog(
                      title: const Text('Confirmar cancelación'),
                      content: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(AppStrings.detailCancelConfirm),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              Expanded(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      AppStrings.cancelSinceLabel,
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.secondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      du.formatDate(cancelledAt),
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: AppColors.background,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: IconButton(
                                  onPressed: () async {
                                    final picked = await showDatePicker(
                                      context: c,
                                      initialDate: cancelledAt,
                                      firstDate: DateTime(2000),
                                      lastDate: DateTime.now(),
                                    );
                                    if (picked != null) {
                                      setState(() => cancelledAt = picked);
                                    }
                                  },
                                  icon: const Icon(
                                    Icons.event,
                                    size: 22,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: AppStrings.cancelChangeDate,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      actions: [
                        TextButton(
                          onPressed: () => Navigator.pop(c, false),
                          child: const Text('Volver'),
                        ),
                        FilledButton(
                          style: ButtonStyle(
                            backgroundColor:
                                WidgetStatePropertyAll(AppColors.success),
                          ),
                          onPressed: () => Navigator.pop(c, true),
                          child: Text(
                            AppStrings.detailCancelConfirmCta,
                            style: const TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
                if (confirm == true) {
                  await ref
                      .read(subscriptionListProvider.notifier)
                      .markCancelled(subscription.id, cancelledAt: cancelledAt);
                  // Intersticial tras la acción completada (solo FREE y
                  // como mucho 1 cada 15 min). No bloquea la navegación.
                  if (ref.read(adsEnabledProvider)) {
                    // ignore: unawaited_futures
                    ref.read(adServiceProvider).maybeShowInterstitial();
                  }
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.snackbarCancelled),
                        backgroundColor: AppColors.success,
                      ),
                    );
                    context.go('/home');
                  }
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.success,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                ),
              ),
              icon: const Icon(Icons.check_circle_outline, size: 20),
              label: Text(AppStrings.detailCancelCta),
            ),
          ),
        if (subscription.status == SubscriptionStatus.active)
          const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 52,
          child: OutlinedButton.icon(
            onPressed: () => context.push('/add', extra: subscription),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: BorderSide(color: AppColors.primary, width: 1.5),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              textStyle: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.edit_outlined, size: 18),
            label: Text(AppStrings.detailEditCta),
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: TextButton.icon(
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (c) => AlertDialog(
                  title: const Text('Eliminar suscripción'),
                  content: Text(AppStrings.detailDeleteConfirm),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(c, false),
                      child: const Text('Cancelar'),
                    ),
                    FilledButton(
                      style: ButtonStyle(
                        backgroundColor:
                            WidgetStatePropertyAll(AppColors.danger),
                      ),
                      onPressed: () => Navigator.pop(c, true),
                      child: Text(
                        AppStrings.detailDeleteConfirmCta,
                        style: const TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              );
              if (confirm == true) {
                await ref
                    .read(subscriptionListProvider.notifier)
                    .deleteSubscription(subscription.id);
                if (context.mounted) {
                  final hasError = ref.read(subscriptionListProvider).hasError;
                  if (hasError) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.generalError),
                        backgroundColor: AppColors.danger,
                      ),
                    );
                  } else {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(AppStrings.snackbarDeleted),
                        backgroundColor: AppColors.secondary,
                      ),
                    );
                    context.go('/home');
                  }
                }
              }
            },
            style: TextButton.styleFrom(
              foregroundColor: AppColors.danger,
              textStyle: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
              ),
            ),
            icon: const Icon(Icons.delete_outline, size: 18),
            label: Text(AppStrings.detailDeleteCta),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          AppStrings.detailDeleteHint,
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 12,
            height: 1.4,
            color: AppColors.onSurface.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
