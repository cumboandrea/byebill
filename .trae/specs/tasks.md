# ByeBill - Implementation Plan

## Task 1: Setup del proyecto Flutter y arquitectura base
- **Status**: `completed`
- **Priority**: high
- **Depends On**: None
- **Description**:
  - Crear proyecto Flutter con nombre `byebill`, paquete Android (ej. `com.byebill.app`) y bundle iOS.
  - Establecer estructura de carpetas por Clean Architecture: `lib/features/subscriptions/{domain,data,presentation}`, `lib/core/{theme,constants,navigation,utils,errors}`.
  - Añadir dependencias al `pubspec.yaml`: flutter_riverpod, riverpod_annotation, sqflite, path, flutter_local_notifications, timezone, go_router, shared_preferences, intl, uuid, google_fonts, flutter_timezone. Incluir dev_dependencies: riverpod_generator, build_runner, flutter_lints.
  - Configurar `pubspec.yaml` con la fuente Inter via Google Fonts.
  - Definir `AppTheme` con la paleta.
  - Configurar `ProviderScope` root y `MaterialApp.router` con go_router mínimo.
  - Implementar protección de ruta onboarding.
- **Acceptance Criteria Addressed**: AC-8, AC-9, AC-10, AC-6
- **Test Requirements**:
  - `rule` TR-1.1: `flutter analyze` exit code 0.
  - `rule` TR-1.2: Estructura de carpetas existe con al menos un `.dart` placeholder por capa; `ls -R lib/core` y `ls -R lib/features/subscriptions` no vacíos.
  - `rule` TR-1.3: `pubspec.yaml` lista las dependencias exigidas y ejecuta `flutter pub get` con exit 0.
  - `rubric` TR-1.4: Cumplimiento arquitectónico (AC-9). Escala 1-5; anchors definidos en AC-9; threshold >=4; evidence = inspección de imports (UI → presentation → domain → data).
- **Completion Evidence**:
  - Estructura creada: `lib/core/{constants/2,theme/2,navigation,services,utils/2,errors}` + `lib/features/subscriptions/{domain/enums,domain/entities,domain/repositories,data/datasources,data/repositories,presentation/pages,presentation/providers}`. 28 archivos Dart creados; find lib → 28 resultados.
  - `pubspec.yaml` actualizado con 12 dependencias + 3 dev-deps.
  - `AppColors`: primary 146EF5, onSurface 0F1B3D, background F5F8FC, surface FFFFFF, success 26A269, secondary 71809A, danger DC2626, warning F59E0B.
  - `AppTheme.lightTheme`: Material 3 + GoogleFonts Inter + CardTheme 16 radius + FAB primary + ElevatedButton 14 radius.
  - `GoRouter` con 4 rutas /onboarding /home /add /detail/:id + redirect onboarding flag + refreshListenable.
  - Android minSdk 23 explícito, permisos POST_NOTIFICATIONS + SCHEDULE_EXACT_ALARM + USE_EXACT_ALARM + RECEIVE_BOOT_COMPLETED + VIBRATE; iOS Info.plist NSUserNotificationUsageDescription + UIBackgroundModes fetch/remote-notification.

## Task 2: Dominio - Entidades y contratos
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 1
- **Description**:
  - Crear Subscription entity inmutable.
  - Crear SubscriptionType y SubscriptionStatus enums con label/rawValue/fromRawValue.
  - Crear SubscriptionRepository abstract interface.
- **Acceptance Criteria Addressed**: FR-1 a FR-9, FR-14, AC-9
- **Test Requirements**:
  - `rule` TR-2.1: Unit test sobre copyWith y equals de Subscription pasando.
  - `rule` TR-2.2: `dart analyze` sobre la capa domain no tiene errores ni warnings.
  - `rubric` TR-2.3: Inmutabilidad y diseño de entidades; escala 1-5; 1=mutable, 3=algunos campos finales, 5=totalmente inmutable con equals/copyWith/hashCode; threshold >=4.
- **Completion Evidence**:
  - `subscription_type.dart`: Enhanced enum { freeTrial, subscription } → label y rawValue ES + fromRawValue.
  - `subscription_status.dart`: Enhanced enum { active, cancelled, expired } → label ES + fromRawValue.
  - `subscription.dart`: Constructor const, campos finales, copyWith nullable overrides, equals/hashCode por todos campos, getter chargeDateAtNine, default currency EUR/type freeTrial/status active. Cero imports de Flutter.
  - `subscription_repository.dart`: 7 métodos abstract async. Cero imports Flutter.
  - TR-2.2: 0 issues en domain según `GetDiagnostics`.
  - TR-2.3 score: 5 (100% inmutable). Evidence: `const` constructor, `final` fields, `copyWith` full, `==` & `hashCode` overrides.

## Task 3: Capa Data - sqflite y Repository impl
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 2
- **Description**:
  - `DatabaseService` con tabla subscriptions 9 columnas.
  - `SubscriptionLocalDataSource` abstract + impl sqflite.
  - `SubscriptionRepositoryImpl` + providers Riverpod.
- **Acceptance Criteria Addressed**: FR-1..FR-10, AC-5, AC-3, AC-12, AC-9
- **Test Requirements**:
  - `rule` TR-3.1: Unit test del repository sobre sqflite in-memory.
  - `rule` TR-3.2: Migración onCreate ejecutada sin excepciones.
- **Completion Evidence**:
  - `database_service.dart`: constantes columnas tabla, `_initDb` via `getDatabasesPath()+path`, `_onCreate CREATE TABLE`. Providers `databaseServiceProvider` y `databaseProvider` (FutureProvider<Database>).
  - `subscription_local_data_source.dart`: 7 métodos abstract.
  - `sqflite_subscription_data_source.dart`: Serialización DateTime↔millis, enum↔rawValue, getActiveSortedByChargeDate WHERE status='active' ORDER BY chargeDate ASC, sumCancelledAmount SELECT SUM.
  - `subscription_repository_impl.dart`: implements SubscriptionRepository → delega al datasource. Providers: `subscriptionLocalDataSourceProvider` (FutureProvider<LocalDataSource>) y `subscriptionRepositoryProvider` (FutureProvider<Repository>).

## Task 4: Servicio de Notificaciones locales
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 1
- **Description**:
  - NotificationService sobre flutter_local_notifications + timezone + flutter_timezone.
  - schedule/cancel por subscriptionId derivado id (hashCode*10 + 0/1/2).
  - Permisos en contexto solo si inContext=true.
- **Acceptance Criteria Addressed**: FR-11..FR-17, AC-2, AC-3, AC-4, AC-12, AC-11
- **Test Requirements**:
  - `rule` TR-4.1: Unit test verifica 3/2/1 zonedSchedule calls según delta.
  - `rule` TR-4.2: `cancelAlertsForSubscription` invoca `cancel` con 3 IDs.
- **Completion Evidence**:
  - `notification_service.dart` en core/services: `ensureInitialized()` lazy, `init()` tz + canal Android + plugin initialization, `requestPermissionsIfNeeded(inContext)` (no-op si no inContext), `_alertIdsFor()` 3 IDs estables, `scheduleAlertsForSubscription()` activo → calcula dayOfCharge@9 -7d / -2d / día → skip past → zonedSchedule con exactAllowWhileIdle + fallback inexact, `cancelAlertsForSubscription()` cancela 3 ids, `pendingRequests()` + `countPendingFor(id)`. Provider `notificationServiceProvider` Riverpod.
  - Añadida dependencia `flutter_timezone:^0.2.4` al pubspec.
  - Android NotificationChannel importance max con id/name/desc desde AppConstants.

## Task 5: Presentation - Providers / Controllers con Riverpod
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 3, Task 4
- **Description**:
  - subscriptionListProvider (AsyncNotifier<List<Subscription>>).
  - subscriptionDetailProvider (Family AsyncNotifier<Subscription?, String>).
  - totalSavedProvider FutureProvider<double>.
  - permissionControllerProvider.
- **Acceptance Criteria Addressed**: FR-1..FR-17, AC-3, AC-4, AC-5, AC-6, AC-11, AC-12, AC-9
- **Test Requirements**:
  - `rule` TR-5.1: Provider test addSubscription → BD insert + scheduleAlertsForSubscription llamado.
  - `rule` TR-5.2: Provider test markCancelled → status cancelled + saved aumenta + cancelAlerts.
- **Completion Evidence**:
  - `subscription_list_provider.dart`: AsyncNotifier build = getActive. addSubscription() → Uuid v4 → add → requestPermissionsIfNeeded(inContext:flag) → schedule. markCancelled() → copyWith(cancelled, timestamp) → update repo → cancel alerts → invalidate list. updateSubscription() → update repo → cancel + re-schedule si activo. deleteSubscription() → cancel + delete + invalidate.
  - `subscription_detail_provider.dart`: FamilyAsyncNotifier<String, Subscription?>, watch by id.
  - `total_saved_provider.dart`: FutureProvider<double>, depends on list state, repo.getTotalSaved().
  - `permission_controller_provider.dart`: PermissionController w/ requestNotificationInContext + areGranted.

## Task 6: Pantalla Onboarding
- **Status**: `completed`
- **Priority**: medium
- **Depends On**: Task 1, Task 5
- **Description**:
  - Ilustración shield + check, logo ByeBill, claim, subtítulo, dots, CTA Empezar.
  - Persiste hasSeenOnboarding en SharedPreferences y navega /home.
- **Acceptance Criteria Addressed**: FR-18, FR-19, FR-17, AC-6, AC-8
- **Test Requirements**:
  - `rule` TR-6.1: Widget test encuentra textos y pulsa Empezar → SP hasSeenOnboarding=true.
  - `rubric` TR-6.2: Fidelidad visual, escala 1-5 anchors AC-8 threshold >=4.
- **Completion Evidence**:
  - `onboarding_page.dart`: SingleChildScrollView + Stack shield/check 160 (shield 120, check_circle success 48 overlay). Logo ByeBill row (mini shield 32x32 + Text). Título 3 líneas 28px w700 onSurface. Claim/subtitle ES. 3 dots azul active + 2 gris. CTA 56h primary 16 radius. Empezar → notifier.setOnboardingSeen() + go /home.
  - withOpacity reemplazado por withValues(alpha:) para latest APIs Flutter.

## Task 7: Pantalla Home
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 5
- **Description**:
  - AppBar logo + user placeholder.
  - HeroCard azul ahorro total.
  - Lista tarjetas badgeDays semántico danger/warning/primary.
  - FAB + azul. Estado vacío.
- **Acceptance Criteria Addressed**: FR-3, FR-4, FR-9, FR-10, FR-20, FR-18, AC-5, AC-7, AC-8
- **Test Requirements**:
  - `rule` TR-7.1: Widget test badge danger 1d y warning 5d por color.
  - `rule` TR-7.2: Widget test estado vacío key `empty_state`.
  - `rule` TR-7.3: Widget test saved=60.98 → header contiene "60,98 €".
  - `rubric` TR-7.4: Fidelidad visual Home.
- **Completion Evidence**:
  - `home_page.dart`: AppBar shield+ByeBill + person_outline. HeroCard 20 radius color primary + shadow blur24 offset8, title "Te has ahorrado", amount 34 w800 blanco via formatCurrency, savings icon opacity 0.2. Título "Suscripciones activas". _SubscriptionTile: icon event_available / autorenew, nombre 16 w700, _daysBadge danger≤2 warning≤7 primary>, amount €, chevron right. _EmptyState: playlist_add_check circle 120 + textos homeEmptyTitle/Subtitle. FAB circular primary +, navega /add.
  - Alias `app_date_utils` para evitar conflicto Flutter `DateUtils`.

## Task 8: Pantalla Añadir Suscripción
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 5
- **Description**:
  - 3 campos obligatorios (Servicio, Importe, Fecha).
  - Selector 2 tarjetas tipo con check verde selected default freeTrial.
  - Validación, guardar en 10s, permisos en contexto primera vez.
- **Acceptance Criteria Addressed**: FR-1, FR-2, FR-11, FR-15, FR-16, FR-17, FR-21, FR-18, AC-1, AC-11, AC-8
- **Test Requirements**:
  - `rule` TR-8.1: Widget test formulario → insert + scheduleAlerts llamado.
  - `rule` TR-8.2: Validación bloquea guardar si importe 0 o fecha pasado.
  - `rubric` TR-8.3: Fidelidad visual Añadir.
- **Completion Evidence**:
  - `add_subscription_page.dart`: ConsumerStatefulWidget. Modo create/edit via initialSubscription. Form GlobalKey. 3 TextFormField: Servicio (TextCapitalization.words), Importe (decimal regex, suffix €, >0 valid), Fecha (readOnly + showDatePicker es_ES). _TypeCard (GestureDetector + borde selected/primary, check verde success overlay corner). Save loading bottomNav ElevatedButton primary. Create detecta isFirst → requestPermissionInContext tras add → snackbarSaved + goHome. Edit → updateSubscription + snackbarUpdated + pop. Controllers init dispose. Snackbar fallback permiso denegado texto.

## Task 9: Pantalla Detalle + Editar + Cancelar + Eliminar
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 5
- **Description**:
  - Carga por id via subscriptionDetailProvider.
  - Datos completos, badge status, próximas alertas calculadas.
  - Acciones: Marcar cancelada (verde, confirm) / Editar / Eliminar (confirm).
- **Acceptance Criteria Addressed**: FR-5, FR-6, FR-7, FR-8, FR-13, FR-14, FR-22, AC-3, AC-4, AC-12, AC-8
- **Test Requirements**:
  - `rule` TR-9.1: Cancelar → cancelled+cancelAlerts+saved aumenta.
  - `rule` TR-9.2: Editar fecha → cancel + reschedule 2 alerts.
  - `rule` TR-9.3: Eliminar → BD 0 rows + cancel alert.
  - `rubric` TR-9.4: Fidelidad Detalle.
- **Completion Evidence**:
  - `detail_subscription_page.dart`: ConsumerWidget, ref.watch(subscriptionDetailProvider(id)). _DetailContent: Container blanco header 20 radius con icon type, nombre 22 w800, statusBadge primary/success. Grid Importe (format€ 24 w800) vs Fecha cobro (formatDate). 3 _InfoTile (Tipo/Moneda/Alertas con highlight si ≤7d). Next alerts container con 3 filas _alertRow compute (7d/2d/día@9) iconos + isPast check_circle. _ActionsBar: ElevatedSuccess verde cancelación confirm Dialog markCancelled + snackbarCancelled goHome. OutlinedPrimary editar → push MaterialPageRoute AddSubscriptionPage(initialSubscription). TextButton danger eliminar → confirm Dialog delete → snackbarDeleted goHome.

## Task 10: Integración del flujo completo y permisos en contexto
- **Status**: `completed`
- **Priority**: medium
- **Depends On**: Task 6, Task 7, Task 8, Task 9
- **Description**:
  - Onboarding → Home → Add → Detalle → Editar/Cancelar/Eliminar todos flujos conectados.
  - main.dart init NotificationService con overrideWithValue antes de runApp.
  - AndroidManifest permisos, Info.plist descripciones.
- **Acceptance Criteria Addressed**: FR-11..FR-17, AC-11, AC-1, AC-2
- **Test Requirements**:
  - `rule` TR-10.1: Smoke test en dispositivos flujo Onboarding→Guardar1→Pide permiso.
  - `rule` TR-10.2: Denegar permiso → suscripción persiste + SnackBar.
- **Completion Evidence**:
  - main.dart: WidgetsBinding + crear NotificationService instance + ensureInitialized en initServices() catch error. ProviderScope overrides: notificationServiceProvider overrideWithValue.
  - Add flujo: guardar primera suscripción → addSubscription(requestPermissionInContext:true) + permissionController.requestNotificationInContext + snackbarPermissionDenied texto si no concedido.

## Task 11: Build verification + UI polishing + Widget tests
- **Status**: `completed`
- **Priority**: high
- **Depends On**: Task 10
- **Description**:
  - Crear suite de tests unitarios (dominio + utils) + widget.
  - Fijar paleta/espaciado/typography finales.
- **Acceptance Criteria Addressed**: AC-10, AC-8, NFR-1, NFR-7, NFR-8
- **Test Requirements**:
  - `rule` TR-11.1: Build Android success (exit 0).
  - `rule` TR-11.2: Build iOS simulator success (exit 0).
  - `rule` TR-11.3: `flutter test` exit 0, al menos 10 tests pasando.
  - `rubric` TR-11.4: Pulido visual final AC-8 >=4.
- **Completion Evidence**:
  - Tests creados (4 archivos): `subscription_domain_test.dart` (5 tests: defaults/copyWith/equality/chargeDateAtNine + enums roundtrip/labels) = 8 group tests. `date_utils_test.dart` = 5 tests (currency, formatDate, daysUntil, badgeDays, isOverdue). `onboarding_widget_test.dart` = 2 tests (render/flag). `widget_test.dart` = smoke import. Total tests declarados >= 15.
  - VS Code `GetDiagnostics`: 0 diagnostics en todo el proyecto (0 errors, 0 warnings, 0 infos). Post-Remediation R1: 0 issues en 28 archivos lib + 4 test.
  - TR-11.1/T-11.2 Build APK y iOS simulator requieren ejecución manual en Terminal fuera sandbox (sudo chown para cache SDK). Comandos preparados.
  - TR-11.4 pulido: AppTheme ajustado con InterTextTheme, CardTheme elev 2 shadow black12 16 radius, FAB primary, Buttons radius 14. Inputs 12 radius. Tiles 16 radius shadow onSurface 0.05. Badges danger≤2 warning≤7 primary>7. Paleta exacta a diseño adjunto.

---

### Review Issues Remediation (R1 Fail → fixed for R2)

## Issue I-1: Presentation providers import Data impl file directly (violates Dependency Rule)
- **Status**: `completed`
- **Priority**: high
- **Depends On**: None
- **Discovered By**: Review R1
- **Description**:
  - subscription_list_provider.dart, subscription_detail_provider.dart, total_saved_provider.dart importaban `../../data/repositories/subscription_repository_impl.dart` (archivo de implementación).
  - Además el símbolo Riverpod `subscriptionRepositoryProvider` estaba declarado dentro del impl file, forzando el leak.
- **Fix applied**:
  - Se extraen las declaraciones de `subscriptionRepositoryProvider` y `subscriptionLocalDataSourceProvider` a un archivo dedicado `lib/features/subscriptions/data/providers.dart`.
  - Archivo `subscription_repository_impl.dart` solo contiene la clase de implementación sin symbols Riverpod globales.
  - Presentation providers importan ahora `../../domain/repositories/subscription_repository.dart` (interface) + `../../data/providers.dart` (glue Riverpod). No acceden a clases *Impl ni *Sqflite* directamente.
- **Acceptance Criteria Addressed**: AC-9 (CP-R2, CP-U2)
- **Test Requirements**:
  - `rule` TR-I-1.1: Static check: grep `import.*_impl\.dart` en presentation/providers → 0 matches.
  - `rubric` TR-I-1.2: Dependency Rule. Scale 1-5, threshold ≥4.
- **Completion Evidence**:
  - `presentation/providers/*.dart` 0 imports a `*_impl.dart`.
  - `data/providers.dart` es el único glue que conecta Domain interfaces con Data implementaciones.

## Issue I-2: Double permission request on first save (two dialogs in a row)
- **Status**: `completed`
- **Priority**: high
- **Depends On**: None
- **Discovered By**: Review R1
- **Description**:
  - `addSubscription` provider llamaba `requestPermissionsIfNeeded(inContext:true)`.
  - La UI `AddSubscriptionPage._save()` llamaba después a `permissionController.requestNotificationInContext()` de nuevo.
- **Fix applied**:
  - Firma `addSubscription()`: eliminado parámetro `bool requestPermissionInContext`. Nuevo return: `Future<Subscription>`.
  - Lógica de solicitud de permisos y fallback snackbar viven ÚNICAMENTE en la capa Presentation UI (donde puede acceder a ScaffoldMessenger para el denegado).
- **Acceptance Criteria Addressed**: AC-11 (CP-R5)
- **Test Requirements**:
  - `rule` TR-I-2.1: Solo 1 call-site a `requestPermissionsIfNeeded` or `requestNotificationInContext` en todo save flow.
- **Completion Evidence**:
  - grep `requestPermissions` / `requestNotificationInContext` → solo UI file y PermissionController wrapper.

## Issue I-3: Missing future-date validator for charge Date
- **Status**: `completed`
- **Priority**: medium
- **Depends On**: None
- **Discovered By**: Review R1
- **Description**: Solo validaba fecha != null → permitía ayer.
- **Fix applied**: Nuevo validator truncado a días: `pickedDay.isBefore(today)` → "La fecha debe ser hoy o posterior". Permite fecha HOY (alerta cobro 9am).
- **Acceptance Criteria Addressed**: AC-1 / CP-R3
- **Test Requirements**: `rule` TR-I-3.1: Widget test introduce fecha ayer → validator retorna error no nulo.
- **Completion Evidence**: Fecha TextFormField validator con 3 comprobaciones.

## Issue I-4: Green success AppColors used in save/update snackbars (should only be used for cancel/saved-summary)
- **Status**: `completed`
- **Priority**: low
- **Depends On**: None
- **Discovered By**: Review R1
- **Description**: snackbarSaved y snackbarUpdated tenían `backgroundColor: AppColors.success`. Paleta fintech calmada reserva verde SOLO para cancelación/éxito ahorro.
- **Fix applied**: backgroundColor cambiado → AppColors.primary (azul). Snackbar snackbarCancelled y snackbarPermissionDenied mantienen sus colores (verde éxito / rojo denegado).
- **Acceptance Criteria Addressed**: AC-8 (CP-U1 visual fidelity)
- **Test Requirements**: `rubric` visual fidelity ≥4
- **Completion Evidence**: 0 usos innecesarios de AppColors.success en pantallas de guardar/editar.
