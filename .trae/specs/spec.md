# ByeBill - Product Requirements Document

## Overview
- **Summary**: Aplicación móvil multiplataforma (Android e iOS) para evitar cobros no deseados de suscripciones y pruebas gratuitas olvidadas. El usuario registra un servicio en ~10 segundos, recibe alertas graduales antes del cobro y marca con un check verde cuando lo cancela.
- **Purpose**: Empoderar al usuario para que nunca más pague por algo que quería cancelar, generando un valor medible directo (dinero ahorrado) y alta retención.
- **Target Users**: Personas que activan pruebas gratuitas y suscripciones mensuales/anuales (streaming, apps, gimnasios, almacenamiento en nube) y han sufrido cobros olvidados. Idioma inicial: español. Moneda por defecto: EUR.

## Goals
- G1: Registrar una suscripción/prueba gratuita en menos de 10 segundos con 3 campos obligatorios.
- G2: Entregar >95% de las alertas programadas en el momento correcto (zona horaria local).
- G3: Permitir marcar una suscripción como cancelada y detener inmediatamente sus alertas pendientes.
- G4: Visualizar el ahorro total acumulado como refuerzo del valor de la app.
- G5: Cero fricción de onboarding: sin cuenta de usuario, sin servidor, todos los datos en el dispositivo.

## Non-Goals
- Sincronización en la nube / multi-dispositivo / cuentas de usuario.
- Detección automática de suscripciones por lectura de correo.
- Widgets de pantalla de inicio, Apple Watch / Wear OS.
- Integración de anuncios (AdMob) y compras in-app (fase 2, post-MVP).
- Importación desde extractos bancarios.
- Pantallas de estadísticas avanzadas o perfil de usuario en el MVP.
- Idiomas adicionales al español.

## Background & Context
- Diseño visual decidido el 28-09-2026: estilo "fintech calmada", paleta #146EF5 (azul) / #0F1B3D (texto) / #F5F8FC (fondo) / #FFFFFF (superficie) / #26A269 (verde éxito) / #71809A (gris). Tipografía Inter.
- Diseño de 3 pantallas principales adjunto: Onboarding → Home → Añadir → Detalle.
- El "próximo paso" definido por el usuario es montar el proyecto Flutter con estructura base, modelo, pantallas y servicio de notificaciones listo para conectar.
- Stack tecnológico confirmado: Flutter, Dart, Riverpod (gestión de estado), sqflite (persistencia local), flutter_local_notifications + timezone (alertas locales), Clean Architecture por capas.

## Functional Requirements

### Gestión de Suscripciones
- **FR-1**: Crear suscripción con campos: name (obligatorio), amount (obligatorio), chargeDate (obligatorio), currency (opcional, default "EUR"), type (opcional: free_trial | subscription, default free_trial).
- **FR-2**: Asignar automáticamente id (UUID), status = "active", createdAt = fecha/hora actual al crear.
- **FR-3**: Listar suscripciones activas ordenadas ascendentemente por chargeDate (más próximo primero).
- **FR-4**: Mostrar en cada fila de la lista: nombre, badge con "Faltan X días" y el importe con moneda.
- **FR-5**: Visualizar detalle completo de una suscripción con todos sus campos.
- **FR-6**: Editar una suscripción (name, amount, currency, chargeDate, type).
- **FR-7**: Marcar una suscripción como cancelada: status → "cancelled", cancelledAt = ahora, detener alertas pendientes.
- **FR-8**: Eliminar una suscripción: borrar de la BD y cancelar alertas pendientes.
- **FR-9**: Calcular y mostrar ahorro total: suma de amount de todas las suscripciones con status = "cancelled".
- **FR-10**: Pantalla de estado vacío en Home cuando no hay suscripciones activas.

### Notificaciones y Alertas
- **FR-11**: Al crear/editar una suscripción activa, programar hasta 3 notificaciones locales graduales:
  - Alerta a 7 días antes del cobro (solo si quedan >7 días desde la fecha de programación).
  - Alerta a 2 días antes del cobro (solo si quedan >2 días).
  - Alerta el día del cobro a las 9:00 AM hora local.
- **FR-12**: Todas las alertas usan zona horaria local del dispositivo mediante el paquete `timezone`.
- **FR-13**: Al editar chargeDate: cancelar todas las notificaciones pendientes de esa suscripción y reprogramarlas con la nueva fecha.
- **FR-14**: Al marcar como cancelada o eliminar: cancelar todas las notificaciones pendientes de esa suscripción.
- **FR-15**: Solicitar permiso de notificaciones en contexto (al guardar la primera suscripción), nunca al abrir la app por primera vez.
- **FR-16**: Android 13+: solicitar permiso POST_NOTIFICATIONS. Android 12+: solicitar permiso de alarmas exactas (SCHEDULE_EXACT_ALARM).
- **FR-17**: Onboarding de una sola pantalla que explica el valor antes de la primera solicitud de permiso.

### Navegación y Flujo
- **FR-18**: Flujo de pantallas: Onboarding (solo primer arranque) → Home → Añadir (FAB) → Detalle (tap en fila) → (Editar / Cancelar / Eliminar).
- **FR-19**: Onboarding solo visible en el primer arranque; persistir flag en almacenamiento local.
- **FR-20**: Home: cabecera con ahorro total y debajo lista de suscripciones activas + FAB azul "+".
- **FR-21**: Pantalla Añadir: 3 campos obligatorios (Servicio, Importe, Fecha) + selector de tipo (Prueba gratuita / Suscripción) con default "Prueba gratuita".
- **FR-22**: Pantalla Detalle: botones "Marcar como cancelada" (verde), "Editar", "Eliminar".

## Non-Functional Requirements
- **NFR-1**: Rendimiento: apertura de la app < 1s, scroll de 50 suscripciones a 60fps.
- **NFR-2**: Privacidad: ningún dato abandona el dispositivo; todas las lecturas/escrituras son locales.
- **NFR-3**: Arquitectura: Clean Architecture por capas (UI → Presentation → Domain → Data). Separación UI ↔ Repository ↔ DB / Notification Service.
- **NFR-4**: Gestión de estado: Riverpod con providers por caso de uso.
- **NFR-5**: Persistencia: sqflite con esquema de tabla único `subscriptions` y migraciones versionadas.
- **NFR-6**: Notificaciones: flutter_local_notifications + timezone. IDs de notificación derivados de subscription.id para poder cancelarlos agrupadamente.
- **NFR-7**: Visual: respetar la dirección visual (paleta, tipografía Inter, tarjetas redondeadas, sombras suaves, badges semánticos rojo ≤2d / naranja ≤7d).
- **NFR-8**: Responsive: mobile 100% ancho; escalado progresivo sin rotura en tablet.
- **NFR-9**: Internacionalización: textos hardcodeados en español en esta fase, pero preparados en un archivo de strings localizable.
- **NFR-10**: Manejo de errores: fallback gracefully si permisos de notificación son denegados (no crashear, mostrar aviso explicativo).

## Constraints
- **Technical**: Flutter SDK (canal stable último), Null Safety, Dart 3.x, Riverpod 2.x, sqflite 2.x, flutter_local_notifications 17.x, timezone 0.9.x, go_router (navegación), intl (formato fechas/monedas).
- **Business**: MVP sin monetización. No meter anuncios ni compras in-app. Límite de 4 pantallas máximo para no añadir fricción.
- **Dependencies**: Todo el stack de dependencias debe ser resoluble vía pub.dev sin dependencias Git privadas.
- **Plataforma**: minSdk 23 (Android), iOS 13+ (iPhone).
- **Diseño visual**: Fidelidad al diseño adjunto; colores exactos de la paleta; verde solo para cancelación/éxito/ahorro.

## Assumptions
- El usuario aceptará el permiso de notificaciones cuando se le pida en contexto (tras guardar su primera suscripción). Mitigación: onboarding explicativo previo.
- En Android 12+, si el permiso de alarmas exactas no se concede, la alerta del día del cobro se programa como inexacta y se informa al usuario (degradación controlada).
- SQLite en dispositivo es suficiente para cientos o miles de suscripciones por usuario.
- El usuario tendrá conexión a Internet solo para descargar la app; el funcionamiento core es 100% offline.
- Moneda EUR por defecto; el usuario puede cambiarla por suscripción. No hay conversión automática entre monedas para el ahorro total (se suma importe numérico con símbolo; en MVP se asume EUR mayoritaria).

## Acceptance Criteria

### AC-1: Registro de suscripción en 10 segundos
- **Type**: `rule`
- **Given**: El usuario está en la pantalla Home y pulsa el FAB "+".
- **When**: Introduce nombre = "iCloud+", importe = "2.99", selecciona fecha dentro de 3 días, pulsa "Guardar suscripción" sin cambiar el tipo por defecto.
- **Then**: La suscripción aparece en el top de la lista Home con los datos correctos, status activa, y las alertas de 2 días y día del cobro quedan programadas.
- **Pass Condition**: App ejecutada en emulador/dispositivo real; flujo grabable en video; tiempo medido ≤ 10s desde la pulsación del FAB hasta que aparece la fila en Home.
- **Evidence**: Prueba manual grabada o recorrido automatizado (Widget test) que valide los campos y la inserción.

### AC-2: Alertas graduales se programan correctamente
- **Type**: `rule`
- **Given**: Una suscripción con chargeDate a 15 días vista (15 > 7).
- **When**: Se guarda la suscripción.
- **Then**: Quedan programadas 3 notificaciones: una a 7 días antes, otra a 2 días antes, y otra el día del cobro a las 9:00 hora local.
- **Pass Condition**: Consulta el listado de notificaciones pendientes de flutter_local_notifications y retorna 3 IDs asociados a esa suscripción.
- **Evidence**: Log dump del notification plugin o widget test que invoque `pendingNotificationRequests`.

### AC-3: Cancelación detiene alertas pendientes
- **Type**: `rule`
- **Given**: Suscripción activa con 2 notificaciones pendientes (2 días y día del cobro).
- **When**: El usuario pulsa "Marcar como cancelada" en el detalle.
- **Then**: status pasa a "cancelled", cancelledAt tiene timestamp, el ahorro total aumenta en el amount, y las 2 notificaciones ya no aparecen en la lista de pendientes.
- **Pass Condition**: Query a BD retorna status=cancelled + cancelledAt no nulo; pendingNotificationRequests para esa suscripción retorna 0 elementos.
- **Evidence**: Consulta sqflite + plugin pending dump.

### AC-4: Editar fecha reprograma alertas
- **Type**: `rule`
- **Given**: Suscripción activa con chargeDate original = fecha_ahora + 15 días y 3 alertas programadas.
- **When**: El usuario edita chargeDate a fecha_ahora + 3 días y guarda.
- **Then**: Las 3 alertas originales están canceladas. Se han programado 2 alertas nuevas (2 días antes y día del cobro a las 9:00). La alerta de 7 días NO se programa (7 > 3).
- **Pass Condition**: Count de notificaciones pendientes asociadas = 2; fechas relativas a nueva chargeDate correctas.
- **Evidence**: Dump pendings + inspección de payloads con fecha disparo.

### AC-5: Ahorro total refleja suscripciones canceladas
- **Type**: `rule`
- **Given**: BD con 3 suscripciones: cancelada_1 (amount=12.99), cancelada_2 (amount=47.99), activa_1 (amount=2.99).
- **When**: Se abre Home.
- **Then**: La cabecera muestra un ahorro total de 60,98 € (12.99 + 47.99).
- **Pass Condition**: Widget Text en Home contiene "60,99 €" formateado con coma decimal.
- **Evidence**: Widget test con setup de datos mockeados y matcher sobre el texto del header.

### AC-6: Onboarding solo en primer arranque
- **Type**: `rule`
- **Given**: Instalación limpia (nunca abierta).
- **When**: Abrir la app por primera vez.
- **Then**: Se muestra la pantalla Onboarding con título, subtítulo, ilustración, CTA "Empezar". Después de pulsar Empezar, se navega a Home y no vuelve a aparecer Onboarding en siguientes aperturas.
- **Pass Condition**: Segunda apertura salta directamente a Home; flag `hasSeenOnboarding=true` persistido en SharedPreferences.
- **Evidence**: Inspección de SharedPreferences tras primera y segunda apertura.

### AC-7: Semántica visual de badges
- **Type**: `rule`
- **Given**: Dos suscripciones: A (cobro en 1 día, ≤2d) y B (cobro en 5 días, ≤7d).
- **When**: Se renderiza Home.
- **Then**: Badge A es de color rojo (o semántico urgencia ≤2), Badge B es naranja (o semántico ≤7).
- **Pass Condition**: Colores extraídos del Widget tree coinciden con tokens definidos para esos umbrales.
- **Evidence**: Widget test accediendo al BoxDecoration/BadgeColor.

### AC-8: Fidelidad visual a la dirección acordada
- **Type**: `rubric`
- **Dimension**: Fidelidad del UI al diseño "fintech calmada" en las 3 pantallas principales (Onboarding, Home, Añadir).
- **Scale**: 1-5
- **Anchors**: 1 = Rotos colores, tipografía, layout; 3 = Parecido pero divergencias visibles (redondeados, sombras, espaciados); 5 = Identidad pixel-perfect (azul #146EF5 en CTAs, texto #0F1B3D, fondo #F5F8FC, verde #26A269 solo en éxito, tarjetas blancas con sombra suave, tipografía Inter).
- **Pass Threshold**: >= 4
- **Evidence**: Comparativa side-by-side de capturas reales vs diseño adjunto, evaluada por el usuario.

### AC-9: Clean Architecture + Riverpod respetados
- **Type**: `rubric`
- **Dimension**: Cumplimiento arquitectónico de capas separadas, gestión de estado Riverpod, dependencias apuntando hacia adentro (Dependencia Rule).
- **Scale**: 1-5
- **Anchors**: 1 = Todo en lib/main.dart o widgets acceden a sqflite directamente; 3 = Hay capas pero con leak ocasional (UI llama a DB); 5 = UI → Presentation (controllers/providers) → Domain (entities/usecases) → Data (repositories_impl + datasources) con interfaces explícitas y provider scope único.
- **Pass Threshold**: >= 4
- **Evidence**: Inspección estática de la estructura de carpetas y de imports entre archivos.

### AC-10: Compilación limpia en ambas plataformas
- **Type**: `rule`
- **Given**: Proyecto en estado final, `flutter pub get` ejecutado.
- **When**: Lanzar `flutter build apk --debug` y `flutter build ios --simulator`.
- **Then**: Ambos builds finalizan con exit code 0 y sin warnings críticos de deprecación.
- **Pass Condition**: stdout de ambos comandos retorna "✓ Built ..." y exit 0.
- **Evidence**: Logs de ambos builds guardados.

### AC-11: Permisos de notificación pedidos en contexto
- **Type**: `rule`
- **Given**: App recién instalada, permiso denegado por defecto, primera suscripción lista para guardar.
- **When**: Usuario pulsa "Guardar suscripción".
- **Then**: Se muestra el diálogo del sistema de permiso de notificaciones. Si el usuario lo concede, se programan las alertas; si lo deniega, la suscripción se guarda igual y se muestra un toast/snackbar explicativo de cómo activarlas después.
- **Pass Condition**: Diálogo de permisos aparece solo después del tap en Guardar (nunca antes) y en ambos caminos la suscripción se persiste.
- **Evidence**: Video prueba en iOS y Android 13+.

### AC-12: Eliminar suscripción cancela alertas
- **Type**: `rule`
- **Given**: Suscripción activa con 3 notificaciones pendientes.
- **When**: Usuario pulsa "Eliminar" en la pantalla de Detalle y confirma.
- **Then**: La suscripción no está en BD y pendingNotificationQueries para ella retorna 0.
- **Pass Condition**: Query a tabla subscriptions retorna 0 filas para ese id; plugin dump retorna 0.
- **Evidence**: Consultas post-eliminación.

## Open Questions
- [ ] **Q1**: ¿Confirmamos el uso de go_router para navegación vs Navigator 1.0 simple? (Propuesta: go_router para facilitar Deep Links futuros).
- [ ] **Q2**: ¿El ahorro total distingue monedas distintas o suma valores numéricos sin convertir? (Propuesta MVP: suma numérica y muestra "€" asumiendo EUR; conversión real para fase 2).
- [ ] **Q3**: ¿Incluir SharedPreferences para onboarding/flag o usar sqflite con tabla de settings? (Propuesta: shared_preferences por simplicidad).
- [ ] **Q4**: ¿Pantalla Detalle incluye lista visual de alertas ya programadas (fechas exactas) como se sugiere en punto 5? (Propuesta: sí, mínimo texto con las próximas fechas).
- [ ] **Q5**: ¿Package de UI adicional? (Propuesta: sin package extra; widgets Material 3 personalizados para mantener control total del diseño fintech calmada).
