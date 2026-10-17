# ByeBill — Resumen de funcionalidades

> App de gestión de suscripciones (Flutter): registra tus servicios (Netflix, Spotify, iCloud, etc.), te avisa antes de cada cobro y te ayuda a cancelar lo que ya no usas.

---

## 1. Funcionalidades generales (ambos planes)

### Gestión de suscripciones
- **Añadir / editar suscripción** con los campos:
  - Nombre del servicio (con **servicios populares predefinidos**: Netflix, Spotify, Disney+, Amazon Prime, Apple TV+, YouTube Premium, ChatGPT, Midjourney, etc., con su logo y enlace de cancelación).
  - Logo del servicio (SVG/PNG desde `assets/logos/`).
  - Importe y moneda (**€ / $**), con separador decimal correcto por moneda (coma para €, punto para $).
  - Ciclo de facturación: **mensual / anual**.
  - Tipo: **Prueba gratuita** o **Suscripción de pago**.
  - **Fecha de cobro** y **fecha de inicio** (para el cálculo real del historial de gasto).
  - **Enlace oficial de cancelación** ("Abrir enlace oficial…").
- **Detalle de suscripción**: logo, datos, acciones de editar, cancelar (mover a histórico) y eliminar (borrado definitivo con confirmación).
- **Pruebas gratuitas**: se marcan como "termina el…" / "terminada…" según estado; al vencer se pueden convertir en suscripción de pago con un solo toque.

### Avisos y notificaciones
- **Notificaciones programadas** locales (sin servidor): "X días para el cobro de…" y "Hoy es el cobro de…".
- **Logo del servicio en la notificación** (ficha con el logo del proveedor).
- **Sincronización con el calendario** (agenda del teléfono o Google Calendar):
  - Evento de **día completo** el día del cobro.
  - Recordatorios dentro del evento según el plan.
  - Elección de agenda por cuenta (muestra el email de la cuenta).
  - Diagnóstico DEBUG y botón "Recrear eventos".
- **Centro de Alertas Inteligente**: campana con punto rojo cuando hay avisos (pruebas a punto de caducar, próximos cobros, ahorro registrado, promoción Premium). Acceso mediante panel deslizable (Bottom Sheet). Los avisos se calculan en tiempo real, sin persistencia.
- **Watchdog de fondo** (WorkManager): tras reinicios o cierres forzados reprograma las alarmas que falten (sin duplicar notificaciones).

### Ahorro y gamificación
- **Gasto mensual activo** (tarjeta destacada en rojo con total de suscripciones activas).
- KPIs de ahorro: **este mes**, **este año** y **total ahorrado**.
- Gráficos (fl_chart):
  - Barras: evolución del gasto (últimos 6 meses).
  - Línea escalonada: evolución del ahorro acumulado.
- **Top servicios ahorrados** (pódium oro/plata/bronce).
- **Equivalencias de ahorro** con experiencias reales: cafés, cine, cena fuera, vuelo de fin de semana, gadget tecnológico.

### Historial
- Suscripciones **canceladas y pruebas agotadas** en lista aparte.
- **Filtros** por tipo y **búsqueda** por nombre.
- Badges visuales de estado (prueba/cancelada).

### Ajustes
- **Idioma**: Español / English / Italiano.
- **Moneda**: € o $.
- **Hora de aviso** (bloqueada en FREE; ver diferencias).
- Sincronización de **calendario** (activar/desactivar, elegir agenda).
- Estado de permisos de **notificación**.
- **Plan actual** (Premium/Free) y acceso a la página de planes.
- **Restablecer datos** (doble confirmación; borra suscripciones, eventos y avisos, conserva ajustes).
- Versión de la app, términos y privacidad.
- Sección **DEBUG** (solo desarrollo): interruptor Premium y diagnóstico de calendario.

### Otros
- **Onboarding** de bienvenida y Splash con el logo.
- Navegación inferior con 4 pestañas (INICIO, HISTORIAL, AHORRO, AJUSTES).
- Localización completa de textos (es/en/it) en tiempo real.
- Notificaciones y recordatorios de calendario sincronizados con el plan.

---

## 2. Diferencias FREE vs PREMIUM

| Funcionalidad | FREE | PREMIUM |
|---|---|---|
| **Suscripciones activas** | Máximo **3** | **Ilimitadas** |
| **Notificaciones** | **2 avisos**: 2 días antes y día del cobro | **3 avisos**: 7 días antes, 2 días antes y día del cobro |
| **Recordatorios de calendario** | 2 (2 días antes y día del cobro) | 3 (7 días antes, 2 días antes y día del cobro) |
| **Hora de aviso** | Fija a las **09:00** | **Personalizable** |
| **Publicidad** | Con publicidad (planificado; aún sin implementar) | **Sin publicidad** |
| **Promoción Premium** | Alertas de "hazte Premium" visibles | Ocultas |

### Comportamientos asociados al plan

- **Límite de 3**: en FREE, al llegar a 3 suscripciones activas el botón de añadir dirige a la página Premium y aparece un banner de upsell ("Límite alcanzado").
- **Cambio de plan**: al pasar de PREMIUM a FREE, la aplicación **restaura automáticamente la hora de aviso a las 09:00** y reprograma las alertas y eventos de calendario al plan FREE (se elimina el aviso de 7 días). Una vez en FREE, el selector de hora queda bloqueado y dirige a la página Premium.
- Las suscripciones de pago se autorenuevan sumando su ciclo; las gratuitas (free trial) se marcan como "Expiradas" al vencer.

---

## 3. Planes Premium disponibles

| Plan | Precio (€) | Precio ($) |
|---|---|---|
| **Mensual** | 2,99 €/mes | 2.99 $/mese |
| **Anual** | 19,99 €/año | 19.99 $/anno |
| **De por vida** (Más popular) | 34,99 € (único) | 34.99 $ (una tantum) |

**Beneficios destacados**: avisos anticipados de 7 días, sin publicidad, suscripciones ilimitadas.

> **Nota de estado**: la compra/restauración de planes está pendiente de integrar con la pasarela de pagos (Google Play / App Store). Actualmente el plan se activa vía interruptor de desarrollo (DEBUG). La publicidad es un beneficio Premium declarado pero todavía no implementada en la app.

---

## 4. Stack técnico

| Área | Tecnología |
|---|---|
| App | Flutter (Riverpod, Arquitectura Limpia por capas) |
| Base de datos | sqflite (SQLite) |
| Notificaciones | flutter_local_notifications + timezone |
| Calendario | device_calendar |
| Fondo | flutter_workmanager (watchdog) |
| Navegación | go_router |
| Gráficos | fl_chart |
| SVG / logos | flutter_svg |
| Permisos | permission_handler |
| Preferencias | shared_preferences |