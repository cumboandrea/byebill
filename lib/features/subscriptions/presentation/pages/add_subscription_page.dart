import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../../domain/entities/subscription.dart';
import '../../domain/enums/subscription_type.dart';
import '../../domain/enums/billing_cycle.dart';
import '../providers/permission_controller_provider.dart';
import '../providers/subscription_list_provider.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/constants/top_services.dart';
import '../../../../core/constants/service_categories.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../settings/presentation/providers/settings_provider.dart';
import '../../../../core/utils/date_utils.dart' as app_date_utils;

class AddSubscriptionPage extends ConsumerStatefulWidget {
  const AddSubscriptionPage({super.key, this.initialSubscription});

  final Subscription? initialSubscription;

  bool get isEditMode => initialSubscription != null;

  @override
  ConsumerState<AddSubscriptionPage> createState() => _AddSubscriptionPageState();
}

class _AddSubscriptionPageState extends ConsumerState<AddSubscriptionPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _amountController;
  late final TextEditingController _dateController;
  DateTime? _selectedDate;
  late final TextEditingController _startDateController;
  DateTime? _selectedStartDate;
  late final TextEditingController _descriptionController;
  late SubscriptionType _selectedType;
  late BillingCycle _selectedCycle;
  TopService? _selectedTopService;
  ServiceCategory? _selectedCategory;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialSubscription?.name ?? '');
    final String currency =
        ref.read(settingsProvider).valueOrNull?.currency ?? '€';
    _amountController = TextEditingController(
      text: widget.initialSubscription != null
          ? widget.initialSubscription!.amount
              .toStringAsFixed(2)
              .replaceAll('.', _decimalSeparatorFor(currency))
          : '',
    );
    _selectedDate = widget.initialSubscription?.chargeDate;
    _dateController = TextEditingController(
      text: _selectedDate != null ? app_date_utils.formatDate(_selectedDate!) : '',
    );
    _selectedType = widget.initialSubscription?.type ?? SubscriptionType.subscription;
    _selectedCycle = widget.initialSubscription?.cycle ?? BillingCycle.monthly;
    _selectedStartDate = widget.initialSubscription?.startDate;
    _startDateController = TextEditingController(
      text: _selectedStartDate != null
          ? app_date_utils.formatDate(_selectedStartDate!)
          : '',
    );
    _descriptionController = TextEditingController(
      text: widget.initialSubscription?.description ?? '',
    );

    if (widget.initialSubscription != null) {
      try {
        _selectedTopService = topServices.firstWhere(
            (s) => s.name.toLowerCase() == widget.initialSubscription!.name.toLowerCase() || 
                   s.logoPath == widget.initialSubscription!.logoPath);
      } catch (_) {}
      if (_selectedTopService == null) {
        try {
          _selectedCategory = serviceCategories.firstWhere(
              (c) => c.iconPath == widget.initialSubscription!.logoPath);
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _amountController.dispose();
    _dateController.dispose();
    _startDateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _onTopServiceSelected(TopService service) {
    setState(() {
      _selectedTopService = service;
      _selectedCategory = null;
      _nameController.text = service.name;
    });
  }

  void _onCategorySelected(ServiceCategory category) {
    setState(() {
      _selectedCategory = category;
      _selectedTopService = null;
      // Si el campo está vacío (o ya tiene el nombre de la categoría),
      // se autocompleta. El usuario siempre puede refinarlo después.
      final current = _nameController.text.trim();
      if (current.isEmpty || current == category.name) {
        _nameController.text = category.name;
      }
    });
  }

  /// Chip de selección rápida compartido por los servicios TOP y las
  /// categorías, dentro de una única línea horizontal desplazable.
  Widget _serviceChip({
    required String logoPath,
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 80,
        decoration: BoxDecoration(
          color: isSelected
              ? AppColors.primary.withValues(alpha: 0.1)
              : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected
                ? AppColors.primary
                : AppColors.secondary.withValues(alpha: 0.12),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: logoPath.toLowerCase().endsWith('.svg')
                  ? SvgPicture.asset(
                      logoPath,
                      width: 40,
                      height: 40,
                      placeholderBuilder: (context) => const Icon(
                          Icons.image,
                          size: 40,
                          color: AppColors.secondary),
                    )
                  : Image.asset(
                      logoPath,
                      width: 40,
                      height: 40,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: AppColors.secondary),
                    ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 10,
                fontWeight:
                    isSelected ? FontWeight.bold : FontWeight.normal,
                color: isSelected ? AppColors.primary : AppColors.onSurface,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  void _setDate(DateTime date) {
    setState(() {
      _selectedDate = date;
      _dateController.text = app_date_utils.formatDate(date);
    });
  }

  void _setStartDate(DateTime date) {
    setState(() {
      _selectedStartDate = date;
      _startDateController.text = app_date_utils.formatDate(date);
    });
  }

  Future<void> _selectStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedStartDate ?? DateTime.now(),
      firstDate: DateTime(2000),
      lastDate: DateTime.now(),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      _setStartDate(picked);
    }
  }

  InputDecoration _inputDecoration({
    required String hintText,
    required IconData prefixIcon,
    Widget? suffixIcon,
    String? suffixText,
  }) {
    return InputDecoration(
      filled: true,
      fillColor: Colors.white,
      hintText: hintText,
      hintStyle: TextStyle(
        color: AppColors.secondary.withValues(alpha: 0.6),
        fontSize: 14,
      ),
      prefixIcon: Icon(prefixIcon, color: AppColors.secondary, size: 22),
      suffixText: suffixText,
      suffixStyle: const TextStyle(color: AppColors.secondary),
      suffixIcon: suffixIcon,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.secondary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: AppColors.secondary.withValues(alpha: 0.12),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.primary, width: 1.5),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: AppColors.danger, width: 1),
      ),
    );
  }

  Widget _labelText(String text) => Padding(
        padding: const EdgeInsets.only(left: 2),
        child: Text(
          text,
          style: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.onSurface,
          ),
        ),
      );

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 7)),
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
      locale: const Locale('es', 'ES'),
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
        _dateController.text = app_date_utils.formatDate(picked);
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _selectedDate == null) return;
    final name = _nameController.text.trim();
    final amount = double.parse(_amountController.text.replaceAll(',', '.'));
    final messenger = ScaffoldMessenger.of(context);
    final navigator = GoRouter.of(context);
    if (widget.isEditMode) {
      final currency = ref.read(settingsProvider).valueOrNull?.currency ?? '€';
      final edited = widget.initialSubscription!.copyWith(
        name: name,
        amount: amount,
        chargeDate: _selectedDate!,
        type: _selectedType,
        currency: currency,
        cycle: _selectedCycle,
        cancellationUrl: _selectedTopService?.cancellationUrl ??
            widget.initialSubscription!.cancellationUrl,
        logoPath: _selectedTopService?.logoPath ??
            _selectedCategory?.iconPath ??
            widget.initialSubscription!.logoPath,
        startDate: _selectedStartDate,
        category: _selectedCategory?.id,
        description: _descriptionController.text.trim(),
      );
      await ref
          .read(subscriptionListProvider.notifier)
          .updateSubscription(edited);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppStrings.snackbarUpdated),
            backgroundColor: AppColors.primary,
          ),
        );
        navigator.pop();
      }
    } else {
      final currentList = ref.read(subscriptionListProvider).valueOrNull ?? const [];
      final bool isFirstSubscription = currentList.isEmpty;
      await ref.read(subscriptionListProvider.notifier).addSubscription(
            name: name,
            amount: amount,
            chargeDate: _selectedDate!,
            type: _selectedType,
            cycle: _selectedCycle,
            cancellationUrl: _selectedTopService?.cancellationUrl,
            logoPath:
                _selectedTopService?.logoPath ?? _selectedCategory?.iconPath,
            startDate: _selectedStartDate,
            category: _selectedCategory?.id,
            description: _descriptionController.text.trim(),
          );
      if (mounted && isFirstSubscription) {
        try {
          final bool granted = await ref
              .read(permissionControllerProvider)
              .requestNotificationInContext();
          if (!granted && mounted) {
            messenger.showSnackBar(
              SnackBar(
                content: Text(AppStrings.snackbarPermissionDenied),
                backgroundColor: AppColors.danger,
                behavior: SnackBarBehavior.floating,
              ),
            );
          }
        } catch (_) {}
      }
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(AppStrings.snackbarSaved),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
        navigator.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final subscriptionListAsync = ref.watch(subscriptionListProvider);
    final String currency =
        ref.watch(settingsProvider).valueOrNull?.currency ?? '€';
    return Scaffold(
      key: const ValueKey('add_page'),
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go('/home');
            }
          },
        ),
        centerTitle: true,
        title: Text(
          widget.isEditMode ? AppStrings.editTitle : AppStrings.addTitle,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: AppColors.onSurface,
          ),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24)
              .copyWith(bottom: 200),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _labelText('Servicios Populares'),
                const SizedBox(height: 8),
                SizedBox(
                  height: 90,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: topServices.length + serviceCategories.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(width: 12),
                    itemBuilder: (context, index) {
                      if (index < topServices.length) {
                        final service = topServices[index];
                        return _serviceChip(
                          logoPath: service.logoPath,
                          label: service.name,
                          isSelected: _selectedTopService?.id == service.id,
                          onTap: () => _onTopServiceSelected(service),
                        );
                      }
                      final category =
                          serviceCategories[index - topServices.length];
                      return _serviceChip(
                        logoPath: category.iconPath,
                        label: category.name,
                        isSelected: _selectedCategory?.id == category.id,
                        onTap: () => _onCategorySelected(category),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 20),
                _labelText(AppStrings.addServiceLabel),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _nameController,
                  keyboardType: TextInputType.text,
                  textCapitalization: TextCapitalization.words,
                  style: const TextStyle(color: AppColors.onSurface),
                  decoration: _inputDecoration(
                    hintText: AppStrings.addServiceHint,
                    prefixIcon: Icons.inbox_outlined,
                  ),
                  validator: (v) =>
                      (v == null || v.trim().isEmpty) ? 'Introduce un nombre' : null,
                ),
                const SizedBox(height: 16),
                _labelText('Descripción (opcional)'),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _descriptionController,
                  keyboardType: TextInputType.multiline,
                  maxLength: 200,
                  maxLines: 3,
                  minLines: 1,
                  style: const TextStyle(color: AppColors.onSurface),
                  decoration: _inputDecoration(
                    hintText:
                        'Notas: renovación, tarjeta, contacto del servicio…',
                    prefixIcon: Icons.notes_outlined,
                  ),
                ),
                const SizedBox(height: 24),
                const Text(
                  'Tipo',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: [
                    Expanded(
                      child: _TypeCard(
                        selected: _selectedType == SubscriptionType.subscription,
                        onTap: () => setState(
                            () => _selectedType = SubscriptionType.subscription),
                        type: SubscriptionType.subscription,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _TypeCard(
                        selected: _selectedType == SubscriptionType.freeTrial,
                        onTap: () =>
                            setState(() => _selectedType = SubscriptionType.freeTrial),
                        type: SubscriptionType.freeTrial,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                const Text(
                  'Ciclo de facturación',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.onSurface,
                  ),
                ),
                const SizedBox(height: 10),
                SegmentedButton<BillingCycle>(
                  style: SegmentedButton.styleFrom(
                    selectedForegroundColor: Colors.white,
                    selectedBackgroundColor: AppColors.primary,
                    foregroundColor: AppColors.onSurface,
                  ),
                  segments: const [
                    ButtonSegment(
                      value: BillingCycle.monthly,
                      label: Text('Mensual'),
                    ),
                    ButtonSegment(
                      value: BillingCycle.yearly,
                      label: Text('Anual'),
                    ),
                  ],
                  selected: {_selectedCycle},
                  onSelectionChanged: (newSelection) {
                    setState(() {
                      _selectedCycle = newSelection.first;
                    });
                  },
                ),
                const SizedBox(height: 20),
                _labelText(_selectedType == SubscriptionType.freeTrial 
                    ? 'Importe después de la Prueba Gratuita' 
                    : AppStrings.addAmountLabel),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _amountController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                    signed: false,
                  ),
                  inputFormatters: [
                    _AmountInputFormatter(
                        decimalSeparator: _decimalSeparatorFor(currency)),
                  ],
                  style: const TextStyle(color: AppColors.onSurface),
                  decoration: _inputDecoration(
                    hintText: AppStrings.addAmountHint,
                    prefixIcon: Icons.price_change_outlined,
                    suffixText: '$currency / ${_selectedCycle == BillingCycle.monthly ? 'mes' : 'año'}',
                  ),
                  validator: (v) {
                    final n = double.tryParse(v?.replaceAll(',', '.') ?? '');
                    if (n == null || n <= 0) return 'Importe mayor que 0';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _labelText(AppStrings.addDateLabel),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _dateController,
                  readOnly: true,
                  style: const TextStyle(color: AppColors.onSurface),
                  decoration: _inputDecoration(
                    hintText: AppStrings.addDateHint,
                    prefixIcon: Icons.calendar_month_outlined,
                    suffixIcon: IconButton(
                      onPressed: _selectDate,
                      icon: const Icon(
                        Icons.calendar_today,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  onTap: _selectDate,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  validator: (v) {
                    if (_selectedDate == null) return 'Selecciona una fecha';
                    final DateTime now = DateTime.now();
                    final DateTime today =
                        DateTime(now.year, now.month, now.day);
                    final DateTime pickedDay = DateTime(
                      _selectedDate!.year,
                      _selectedDate!.month,
                      _selectedDate!.day,
                    );
                    if (pickedDay.isBefore(today)) {
                      return 'La fecha debe ser hoy o posterior';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 36,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _DateQuickButton(
                          label: '+7 días',
                          onTap: () => _setDate(DateTime.now().add(const Duration(days: 7)))),
                      const SizedBox(width: 8),
                      _DateQuickButton(
                          label: '+1 mes',
                          onTap: () => _setDate(DateTime(DateTime.now().year, DateTime.now().month + 1, DateTime.now().day))),
                      const SizedBox(width: 8),
                      _DateQuickButton(
                          label: '+3 meses',
                          onTap: () => _setDate(DateTime(DateTime.now().year, DateTime.now().month + 3, DateTime.now().day))),
                      const SizedBox(width: 8),
                      _DateQuickButton(
                          label: '+6 meses',
                          onTap: () => _setDate(DateTime(DateTime.now().year, DateTime.now().month + 6, DateTime.now().day))),
                      const SizedBox(width: 8),
                      _DateQuickButton(
                          label: '+1 año',
                          onTap: () => _setDate(DateTime(DateTime.now().year + 1, DateTime.now().month, DateTime.now().day))),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                _labelText(AppStrings.addStartDateLabel),
                const SizedBox(height: 8),
                TextFormField(
                  controller: _startDateController,
                  readOnly: true,
                  style: const TextStyle(color: AppColors.onSurface),
                  decoration: _inputDecoration(
                    hintText: AppStrings.addStartDateHint,
                    prefixIcon: Icons.history_outlined,
                    suffixIcon: IconButton(
                      onPressed: _selectStartDate,
                      icon: const Icon(
                        Icons.event,
                        size: 20,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  onTap: _selectStartDate,
                ),
                if (_selectedTopService != null) ...[
                  const SizedBox(height: 32),
                  _CancellationShortcutCard(service: _selectedTopService!),
                ],
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                textStyle: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
              child: subscriptionListAsync.isLoading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : Text(
                      widget.isEditMode
                          ? AppStrings.addSaveCta
                          : AppStrings.addSaveCta,
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

class _DateQuickButton extends StatelessWidget {
  const _DateQuickButton({required this.label, required this.onTap});

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return ActionChip(
      label: Text(label, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
      backgroundColor: Colors.white,
      side: BorderSide(color: AppColors.secondary.withValues(alpha: 0.2)),
      onPressed: onTap,
    );
  }
}

class _CancellationShortcutCard extends StatelessWidget {
  const _CancellationShortcutCard({required this.service});

  final TopService service;

  @override
  Widget build(BuildContext context) {
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
            service.cancellationText ?? 'Te llevamos directamente a la página oficial de cancelación.',
            style: TextStyle(
              fontSize: 14,
              color: AppColors.secondary,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 16),
          if (service.cancellationInstructions != null) ...[
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
                      service.cancellationInstructions!,
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
          if (service.cancellationUrl != null)
            GestureDetector(
              onTap: () {
                // url_launcher should be used here if configured
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Abriendo enlace de cancelación oficial...')),
                );
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
                            'Abrir enlace oficial de ${service.name}',
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

class _TypeCard extends StatelessWidget {
  const _TypeCard({
    required this.selected,
    required this.onTap,
    required this.type,
  });

  final bool selected;
  final VoidCallback onTap;
  final SubscriptionType type;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(14, 18, 18, 14),
        clipBehavior: Clip.none,
        decoration: BoxDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? AppColors.primary
                : AppColors.secondary.withValues(alpha: 0.12),
            width: selected ? 1.5 : 1,
          ),
          boxShadow: !selected
              ? [
                  BoxShadow(
                    color: AppColors.onSurface.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Column(
          children: [
            SizedBox(
              width: double.infinity,
              child: Stack(
                alignment: Alignment.topRight,
                clipBehavior: Clip.none,
                children: [
                  Center(
                    child: Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.08),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        type == SubscriptionType.freeTrial
                            ? Icons.event
                            : Icons.autorenew,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                  ),
                  if (selected)
                    Positioned(
                      right: -2,
                      top: -10,
                      child: Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppColors.success,
                        ),
                        child: const Icon(
                          Icons.check,
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: 10),
            Text(
              type.label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: selected ? AppColors.primary : AppColors.onSurface,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Separador decimal según la moneda: coma para el euro, punto para el resto.
String _decimalSeparatorFor(String currency) => currency == '€' ? ',' : '.';

/// Formatea el importe según la moneda seleccionada:
///   - € → solo coma (","), se convierte un "." tecleado en ","
///   - $ → solo punto ("."), se convierte una "," tecleada en "."
/// Solo admite dígitos, un único separador y máximo 2 decimales.
class _AmountInputFormatter extends TextInputFormatter {
  _AmountInputFormatter({required this.decimalSeparator});

  final String decimalSeparator;

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    final String other = decimalSeparator == ',' ? '.' : ',';
    final String text = newValue.text.replaceAll(other, decimalSeparator);

    final StringBuffer buffer = StringBuffer();
    bool separatorSeen = false;
    int decimals = 0;
    for (final int rune in text.runes) {
      final String c = String.fromCharCode(rune);
      final bool isDigit = c.codeUnitAt(0) >= 0x30 && c.codeUnitAt(0) <= 0x39;
      if (isDigit) {
        if (separatorSeen) {
          if (decimals < 2) {
            buffer.write(c);
            decimals++;
          }
        } else {
          buffer.write(c);
        }
      } else if (c == decimalSeparator && !separatorSeen && buffer.isNotEmpty) {
        separatorSeen = true;
        buffer.write(c);
      }
    }

    return TextEditingValue(
      text: buffer.toString(),
      selection: TextSelection.collapsed(offset: buffer.length),
    );
  }
}
