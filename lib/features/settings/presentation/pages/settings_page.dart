import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_strings.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/app_settings.dart';
import '../providers/settings_provider.dart';
import '../../../../core/services/calendar_service.dart';
import '../../../../core/services/notification_service.dart';
import '../../../subscriptions/presentation/providers/subscription_list_provider.dart';

class SettingsPage extends ConsumerStatefulWidget {
  const SettingsPage({super.key});

  @override
  ConsumerState<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends ConsumerState<SettingsPage> {
  String _appVersion = '';
  bool _notificationsEnabled = false;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
    _checkNotificationStatus();
  }

  // Refrescar el estado cada vez que volvemos a esta pantalla
  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _checkNotificationStatus();
  }

  Future<void> _checkNotificationStatus() async {
    final notifService = ref.read(notificationServiceProvider);
    final isEnabled = await notifService.checkExactPermissionStatus();
    if (mounted) {
      setState(() {
        _notificationsEnabled = isEnabled;
      });
    }
  }

  Future<void> _loadAppVersion() async {
    final info = await PackageInfo.fromPlatform();
    if (mounted) {
      setState(() {
        _appVersion = '${info.version} (${info.buildNumber})';
      });
    }
  }

  Future<void> _onCalendarToggle(bool value) async {
    // Al desactivar se borran los eventos creados: pedir confirmación explícita.
    if (!value) {
      final bool? confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: Text(AppStrings.t(
            'Desactivar avisos en el calendario',
            'Disable calendar reminders',
            'Disattivare i promemoria del calendario',
          )),
          content: Text(AppStrings.t(
            'Los eventos de cobro creados por ByeBill se eliminarán de tu calendario. ¿Continuar?',
            'The charge events created by ByeBill will be removed from your calendar. Continue?',
            'Gli eventi di addebito creati da ByeBill verranno rimossi dal tuo calendario. Continuare?',
          )),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(AppStrings.t('Cancelar', 'Cancel', 'Annulla')),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                AppStrings.t('Sí, borrar', 'Yes, delete', 'Sì, elimina'),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    final bool ok =
        await ref.read(settingsProvider.notifier).setCalendarEnabled(value);
    if (value && !ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t(
            'Necesitas dar permiso de calendario. Actívalo en los Ajustes del sistema.',
            'Calendar permission is required. Enable it in system Settings.',
            'È necessario concedere il permesso del calendario. Attivalo nelle Impostazioni di sistema.',
          )),
        ),
      );
    }
  }

  Future<void> _pickCalendar() async {
    final cs = ref.read(calendarServiceProvider);
    if (!await cs.hasPermissions()) {
      final bool ok = await cs.requestPermissions();
      if (!ok) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(AppStrings.t(
                'No se ha podido acceder al calendario.',
                'Could not access the calendar.',
                'Impossibile accedere al calendario.',
              )),
            ),
          );
        }
        return;
      }
    }

    final List<CalendarChoice> choices = await cs.getCalendarChoices();
    if (!mounted) return;
    final settings = ref.read(settingsProvider).valueOrNull;
    final String? currentId = settings?.calendarId;

    final ({String kind, String id})? selected =
        await showModalBottomSheet<({String kind, String id})>(
      context: context,
      showDragHandle: true,
      backgroundColor: AppColors.surface,
      builder: (ctx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                AppStrings.t(
                  '¿Dónde guardamos los avisos?',
                  'Where should we save reminders?',
                  'Dove salviamo i promemoria?',
                ),
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.onSurface,
                ),
              ),
            ),
            if (choices.isEmpty)
              _calendarChoiceTile(
                ctx: ctx,
                icon: Icons.event_note,
                title: AppStrings.t(
                  'No hay una agenda disponible',
                  'No calendar available',
                  'Nessun calendario disponibile',
                ),
                subtitle: AppStrings.t(
                  'Añade una cuenta en los ajustes del dispositivo',
                  'Add an account in your device settings',
                  'Aggiungi un account nelle impostazioni del dispositivo',
                ),
                selected: false,
                onTap: null,
              )
            else
              for (final c in choices)
                _calendarChoiceTile(
                  ctx: ctx,
                  icon:
                      c.isGoogle ? Icons.cloud_outlined : Icons.phone_android,
                  title: c.isGoogle
                      ? 'Google Calendar'
                      : AppStrings.t(
                          'Calendario del teléfono',
                          'Phone calendar',
                          'Calendario del telefono',
                        ),
                  subtitle: c.accountName.isEmpty ? null : c.accountName,
                  selected: c.id == currentId,
                  onTap: () => Navigator.pop(
                    ctx,
                    (kind: c.isGoogle ? 'google' : 'phone', id: c.id),
                  ),
                ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );

    if (selected != null && mounted) {
      final String? selectedAccount = choices
          .where((c) => c.id == selected.id)
          .map((c) => c.accountName)
          .firstOrNull;
      await ref.read(settingsProvider.notifier).setCalendarKind(
            selected.kind,
            selected.id,
            accountName: selectedAccount,
          );
    }
  }

  /// Muestra un diálogo de diagnóstico con el estado del calendario (la
  /// agenda guardada y los eventos registrados) y permite recrear los
  /// eventos de las suscripciones activas sin desactivar el aviso.
  Future<void> _showCalendarDiagnostics() async {
    final cs = ref.read(calendarServiceProvider);
    final subs = ref.read(subscriptionListProvider).valueOrNull ?? const [];
    if (!mounted) return;

    String summary = await cs.debugSummary();
    if (!mounted) return;

    showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Diagnóstico del calendario'),
        content: SingleChildScrollView(
          child: Text(
            summary,
            style: const TextStyle(
              fontSize: 13,
              fontFamily: 'monospace',
              color: AppColors.onSurface,
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Resincronizando eventos...'),
                  duration: Duration(seconds: 2),
                ),
              );
              await cs.backfillAll(subs);
              if (!mounted) return;
              final String after = await cs.debugSummary();
              if (!mounted) return;
              showDialog<void>(
                context: context,
                builder: (ctx2) => AlertDialog(
                  title: const Text('Eventos recreados'),
                  content: SingleChildScrollView(
                    child: Text(
                      after,
                      style: const TextStyle(
                        fontSize: 13,
                        fontFamily: 'monospace',
                        color: AppColors.onSurface,
                      ),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx2),
                      child: const Text('OK'),
                    ),
                  ],
                ),
              );
            },
            child: const Text('Recrear eventos'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  /// Restablece la app a su estado inicial con doble confirmación explícita.
  /// Borra suscripciones, eventos de calendario y notificaciones; conserva las
  /// preferencias (idioma, moneda, hora, calendario y plan).
  Future<void> _onResetData() async {
    final bool? first = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(
          'Restablecer todos los datos',
          'Reset all data',
          'Ripristina tutti i dati',
        )),
        content: Text(AppStrings.t(
          'Se eliminarán todas las suscripciones (activas e históricas), sus eventos del calendario y las notificaciones programadas. Tus ajustes (idioma, moneda, hora de aviso, calendario y plan) se conservan.',
          'All subscriptions (active and history), their calendar events and scheduled notifications will be deleted. Your settings (language, currency, reminder time, calendar and plan) are kept.',
          'Verranno eliminate tutte le sottoscrizioni (attive e storiche), i relativi eventi del calendario e le notifiche programmate. Le tue impostazioni (lingua, valuta, orario avviso, calendario e piano) verranno conservate.',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.t('Cancelar', 'Cancel', 'Annulla')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppStrings.t('Sí, borrar todo', 'Yes, delete all', 'Sì, elimina tutto'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (first != true || !mounted) return;

    // Segunda confirmación: acción destructiva e irreversible.
    final bool? second = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.t(
          '¿Seguro?',
          'Are you sure?',
          'Sei sicuro?',
        )),
        content: Text(AppStrings.t(
          'Esta acción no se puede deshacer. ¿Deseas continuar?',
          'This action cannot be undone. Do you want to continue?',
          'Questa azione non può essere annullata. Vuoi continuare?',
        )),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(AppStrings.t('Cancelar', 'Cancel', 'Annulla')),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(
              AppStrings.t('Restablecer', 'Reset', 'Ripristina'),
              style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
            ),
          ),
        ],
      ),
    );
    if (second != true || !mounted) return;

    await ref.read(subscriptionListProvider.notifier).resetAllData();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(AppStrings.t(
            'Datos restablecidos',
            'Data reset',
            'Dati ripristinati',
          )),
        ),
      );
    }
  }

  /// Abre los documentos legales alojados en GitHub Pages:
  /// versión en español por defecto (e italiano), en inglés si así está la app.
  Future<void> _openLegalDocuments() async {
    final bool english = AppStrings.currentLanguage == 'en';
    final String base = english
        ? 'https://cumboandrea.github.io/byebill/legal/privacy.html'
        : 'https://cumboandrea.github.io/byebill/legal/privacidad.html';
    final Uri uri = Uri.parse(base);
    try {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (e) {
      // ignore: avoid_print
      print('Error abriendo documento legal: $e');
    }
  }

  /// Tarjeta de restablecimiento, destacada en rojo por ser destructiva.
  Widget _buildResetTile() {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: _onResetData,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.red.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.restart_alt, color: Colors.red, size: 22),
        ),
        title: Text(
          AppStrings.t('Restablecer datos', 'Reset data', 'Ripristina dati'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.red,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.secondary,
          size: 20,
        ),
      ),
    );
  }

  /// Tarjeta de selección dentro del Bottom Sheet del calendario: una por
  /// cada cuenta disponible, con la elegida resaltada.
  Widget _calendarChoiceTile({
    required BuildContext ctx,
    required IconData icon,
    required String title,
    required bool selected,
    required VoidCallback? onTap,
    String? subtitle,
  }) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? AppColors.primary : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: ListTile(
          onTap: onTap,
          enabled: onTap != null,
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: AppColors.primary, size: 22),
          ),
          title: Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: AppColors.onSurface,
            ),
          ),
          subtitle: subtitle != null
              ? Text(
                  subtitle,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.secondary,
                  ),
                )
              : null,
          trailing: selected
              ? const Icon(
                  Icons.check_circle,
                  color: AppColors.primary,
                  size: 22,
                )
              : const Icon(
                  Icons.chevron_right,
                  color: AppColors.secondary,
                  size: 20,
                ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final settingsAsync = ref.watch(settingsProvider);

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        toolbarHeight: 64,
        backgroundColor: Colors.transparent,
        elevation: 0,
        titleSpacing: 20,
        title: Text(
          AppStrings.t('Ajustes', 'Settings', 'Impostazioni'),
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: AppColors.onSurface,
            letterSpacing: -0.5,
          ),
        ),
        centerTitle: false,
      ),
      body: settingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator(color: AppColors.primary)),
        error: (e, _) => Center(child: Text('Error: $e')),
        data: (settings) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            children: [
              _buildSectionTitle(AppStrings.t('PREFERENCIAS', 'PREFERENCES', 'PREFERENZE')),
              _buildDropdownTile(
                icon: Icons.language,
                title: AppStrings.t('Idioma', 'Language', 'Lingua'),
                value: settings.language,
                options: const {
                  'es': 'Español',
                  'en': 'English',
                  'it': 'Italiano',
                },
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateLanguage(val);
                  }
                },
              ),
              _buildDropdownTile(
                icon: Icons.payments_outlined,
                title: AppStrings.t('Moneda', 'Currency', 'Valuta'),
                value: settings.currency,
                options: {
                  '€': 'Euro (€)',
                  '\$': 'Dólar (\$)',
                },
                onChanged: (val) {
                  if (val != null) {
                    ref.read(settingsProvider.notifier).updateCurrency(val);
                  }
                },
              ),
              _buildTimeTile(
                icon: Icons.access_time,
                title: AppStrings.t('Hora de aviso', 'Notification time', 'Ora di avviso'),
                value: settings.notificationTime,
                isLocked: !settings.isPremium,
                onTap: () async {
                  if (!settings.isPremium) {
                    context.push('/premium');
                    return;
                  }
                  final time = await showTimePicker(
                    context: context,
                    initialTime: settings.notificationTime,
                    builder: (context, child) {
                      return Theme(
                        data: Theme.of(context).copyWith(
                          colorScheme: const ColorScheme.light(
                            primary: AppColors.primary,
                            onPrimary: Colors.white,
                            onSurface: AppColors.onSurface,
                          ),
                        ),
                        child: child!,
                      );
                    },
                  );
                  if (time != null) {
                    ref.read(settingsProvider.notifier).updateNotificationTime(time);
                  }
                },
              ),
              _buildInfoTile(
                icon: _notificationsEnabled ? Icons.notifications_active_outlined : Icons.notifications_off_outlined,
                title: AppStrings.t('Notificaciones', 'Notifications', 'Notifiche'),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _notificationsEnabled 
                        ? AppStrings.t('Activadas', 'Enabled', 'Attivate') 
                        : AppStrings.t('Desactivadas', 'Disabled', 'Disattivate'),
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: _notificationsEnabled ? Colors.green.shade600 : Colors.red.shade600,
                      ),
                    ),
                    if (!_notificationsEnabled) ...[
                      const SizedBox(width: 4),
                      const Icon(Icons.error_outline, color: Colors.red, size: 16),
                    ]
                  ],
                ),
                onTap: () async {
                  if (!_notificationsEnabled) {
                    final notifService = ref.read(notificationServiceProvider);
                    await notifService.openAppNativeSettings();
                  }
                },
              ),

              const SizedBox(height: 8),
              _buildSwitchTile(
                icon: Icons.calendar_month_outlined,
                title: AppStrings.t(
                  'Avisos en el calendario',
                  'Calendar reminders',
                  'Promemoria calendario',
                ),
                value: settings.calendarEnabled,
                onChanged: _onCalendarToggle,
              ),
              if (settings.calendarEnabled) ...[
                _buildCalendarPickerTile(settings),
              ],
              
              const SizedBox(height: 30),
              _buildSectionTitle(AppStrings.t('CUENTA Y APP', 'ACCOUNT & APP', 'ACCOUNT E APP')),
              _buildInfoTile(
                icon: Icons.star_border,
                title: AppStrings.t('Plan actual', 'Current plan', 'Piano attuale'),
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: settings.isPremium 
                      ? Colors.amber.withValues(alpha: 0.15) 
                      : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    settings.isPremium
                      ? AppStrings.t('Premium', 'Premium', 'Premium')
                      : AppStrings.t('Gratuito', 'Free', 'Gratuito'),
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: settings.isPremium ? Colors.amber.shade700 : AppColors.primary,
                    ),
                  ),
                ),
                onTap: () {
                  context.push('/premium');
                },
              ),
              _buildResetTile(),
              _buildInfoTile(
                icon: Icons.info_outline,
                title: AppStrings.t('Versión de la app', 'App version', 'Versione app'),
                trailing: Text(
                  _appVersion,
                  style: const TextStyle(
                    fontSize: 14,
                    color: AppColors.secondary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
              _buildInfoTile(
                icon: Icons.description_outlined,
                title: AppStrings.t('Términos y Privacidad', 'Terms & Privacy', 'Termini e Privacy'),
                trailing: const Icon(Icons.chevron_right, color: AppColors.secondary, size: 20),
                onTap: _openLegalDocuments,
              ),

              const SizedBox(height: 30),
              _buildSectionTitle('DEBUG (Solo Desarrollo)'),
              _buildInfoTile(
                icon: Icons.developer_mode,
                title: 'Activar/Desactivar Premium',
                trailing: Switch(
                  value: settings.isPremium,
                  onChanged: (val) {
                    ref.read(settingsProvider.notifier).setPremium(val);
                  },
                ),
              ),
              _buildInfoTile(
                icon: Icons.event_note,
                title: 'Diagnóstico del calendario',
                trailing: const Icon(
                  Icons.chevron_right,
                  color: AppColors.secondary,
                  size: 20,
                ),
                onTap: _showCalendarDiagnostics,
              ),
              const SizedBox(height: 20),
            ],
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 8, bottom: 8, top: 10),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.secondary,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  Widget _buildDropdownTile({
    required IconData icon,
    required String title,
    required String value,
    required Map<String, String> options,
    required ValueChanged<String?> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        trailing: DropdownButtonHideUnderline(
          child: DropdownButton<String>(
            value: value,
            icon: const Icon(Icons.expand_more, color: AppColors.secondary),
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.primary,
            ),
            items: options.entries.map((e) {
              return DropdownMenuItem(
                value: e.key,
                child: Text(e.value),
              );
            }).toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeTile({
    required IconData icon,
    required String title,
    required TimeOfDay value,
    required VoidCallback onTap,
    bool isLocked = false,
  }) {
    final timeStr = '${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLocked) ...[
              const Icon(Icons.lock_outline, color: Colors.amber, size: 16),
              const SizedBox(width: 6),
            ],
            Text(
              timeStr,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: isLocked ? AppColors.secondary : AppColors.primary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, color: AppColors.secondary, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoTile({
    required IconData icon,
    required String title,
    required Widget trailing,
    VoidCallback? onTap,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        trailing: trailing,
      ),
    );
  }

  Widget _buildSwitchTile({
    required IconData icon,
    required String title,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, color: AppColors.primary, size: 22),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        trailing: Switch(
          value: value,
          activeTrackColor: AppColors.primary,
          activeThumbColor: Colors.white,
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildCalendarPickerTile(AppSettings settings) {
    final String calendarLabel = switch (settings.calendarKind) {
      'phone' => AppStrings.t(
          'Calendario del teléfono',
          'Phone calendar',
          'Calendario del telefono',
        ),
      'google' => 'Google Calendar',
      _ => AppStrings.t('Por defecto', 'Default', 'Predefinito'),
    };
    final String account =
        settings.calendarAccount ?? '';
    final String subtitle = account.isEmpty ? calendarLabel : '$calendarLabel · $account';
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.onSurface.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ListTile(
        onTap: _pickCalendar,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.08),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.event_note, color: AppColors.primary, size: 22),
        ),
        title: Text(
          AppStrings.t('Calendario', 'Calendar', 'Calendario'),
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
        subtitle: Text(
          subtitle,
          style: const TextStyle(
            fontSize: 13,
            color: AppColors.secondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        trailing: const Icon(
          Icons.chevron_right,
          color: AppColors.secondary,
          size: 20,
        ),
      ),
    );
  }
}