# ByeBill - Independent Review

- [ ] CP-R1: El proyecto compila con 0 diagnostics en análisis estático
  - **Type**: `rule`
  - **Covers**: AC-10, NFR-10, todas las tareas
  - **Evidence**: Pendiente

- [ ] CP-R2: Clean Architecture con 4 capas bien separadas
  - **Type**: `rule`
  - **Covers**: AC-9, NFR-3, NFR-4
  - **Evidence**: Pendiente

- [ ] CP-R3: Registro de suscripción con campos mínimos y validación
  - **Type**: `rule`
  - **Covers**: FR-1, FR-2, FR-21, AC-1, AC-8
  - **Evidence**: Pendiente

- [ ] CP-R4: Alertas graduales 7/2/día 9am programadas con tz local + cancelación por subscriptionId
  - **Type**: `rule`
  - **Covers**: FR-11, FR-12, FR-13, FR-14, AC-2, AC-3, AC-4
  - **Evidence**: Pendiente

- [ ] CP-R5: Permisos de notificación pedidos en contexto (al guardar 1ª suscripción)
  - **Type**: `rule`
  - **Covers**: FR-15, FR-16, FR-17, AC-11
  - **Evidence**: Pendiente

- [ ] CP-R6: Home muestra ahorro total + lista ordenada + badges semánticos
  - **Type**: `rule`
  - **Covers**: FR-3, FR-4, FR-9, FR-10, AC-5, AC-7
  - **Evidence**: Pendiente

- [ ] CP-R7: Detalle permite marcar cancelada (verde), editar, eliminar; con diálogos confirmación
  - **Type**: `rule`
  - **Covers**: FR-5, FR-6, FR-7, FR-8, FR-22, AC-12
  - **Evidence**: Pendiente

- [ ] CP-U1: Fidelidad visual "fintech calmada" a diseño adjunto
  - **Type**: `rubric`
  - **Covers**: AC-8, NFR-7, NFR-8
  - **Scale**: 1-5
  - **Anchors**: 1 = Rotos colores/layout; 3 = Parecido, divergencias claras; 5 = Identidad pixel-perfect (paleta exacta, tipografía Inter, verde solo en éxito, badges semánticos, tarjetas con sombras suaves)
  - **Pass Threshold**: >= 4
  - **Evidence**: Pendiente

- [ ] CP-U2: Arquitectura limpia + Riverpod sin leaks (UI → Presentation → Domain → Data)
  - **Type**: `rubric`
  - **Covers**: AC-9, NFR-3, NFR-4
  - **Scale**: 1-5
  - **Anchors**: 1 = Accesos directos UI ↔ sqflite; 3 = Capas con pequeños leaks; 5 = 100% interfaces explícitas, dependencias hacia adentro, providers en capa presentation únicamente acceden a repository domain.
  - **Pass Threshold**: >= 4
  - **Evidence**: Pendiente

## Review History

### Review R1 (2026-09-30)
- **Result**: `fail`
- **Evidence**: CP-R2 3 leaks import *_repository_impl.dart; CP-R3 falta fecha-futuro validator; CP-R5 doble petición permisos en provider + UI; CP-U1 snackbars saved/updated verde incorrecto. CP-U1 score 4/5 (pasa threshold), CP-U2 3/5 (fallo threshold).
- **Blocked By**: Ninguno
- **Recommended Issues**: I-1 (ALTA) imports presentation→data impl; I-2 (ALTA) doble permisos; I-3 (MEDIA) fecha validator; I-4 (BAJA) snackbar colores.

### Review R2 (2026-09-30) — Post-remediation
- **Result**: `pass`
- **Evidence**: Independiente readonly; 7/7 CP-rule PASS, 2/2 CP-rubric PASS (CP-U1 5/5, CP-U2 5/5). 4 issues I-1..I-4 verificados RESUELTOS por grep y lectura de fuentes. GetDiagnostics=0 en todo el proyecto.
  - CP-R1 (0 diagnostics): `GetDiagnostics` retornó 0 files, 0 diagnostics.
  - CP-R2 (4 capas): `grep flutter/material.dart domain`=0; `find lib | xargs grep sqflite | grep -v data`=0; `grep _repository_impl presentation`=0.
  - CP-R3 (validación): date validator en add_page incluye `pickedDay.isBefore(today)` reject.
  - CP-R4 (alertas): 7/2/día@9 zonedSchedule TZ local; 3 IDs por subscriptionId.
  - CP-R5 (permisos en contexto): `isFirstSubscription` → única llamada en add_subscription_page UI (provider ya no llama).
  - CP-R6 (Home): HeroCard ahorro + lista ordenada ASC chargeDate + 3 badges danger/warning/primary.
  - CP-R7 (Detalle): 3 acciones con confirm Dialogs; Cancelar=verde success.
  - CP-U1 (Visual): Paleta 146EF5/0F1B3D/F5F8FC/26A269 exacta, Inter, verde solo éxito/cancel. 5/5.
  - CP-U2 (Architecture): Domain pure Dart, Presentation solo usa Domain interface + glue data/providers.dart, sin impl. 5/5.
- **Blocked By**: Ninguno
- **Resume When**: N/A (aprobada)
