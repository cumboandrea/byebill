# ByeBill · Subir la app a Apple (iOS): guía de tareas

Este documento resume **todo lo que hay que hacer** para publicar ByeBill en el **App Store (iOS)**, aprovechando todo lo que ya está implementado en la app. Es la versión iOS de `PASOS_ADMOB.md`.

> Estado: **documento de planificación** — lo ponemos en práctica en una fase posterior.

---

## 0. Lo que ya está hecho (no habrá que tocarlo)

La app es **multiplataforma** y ya contiene el 90 % de lo que iOS necesita:

| Pieza | Estado actual | Detalle |
|---|---|---|
| Carpeta `ios/` | ✅ Generada | Plantilla Runner de Flutter con `AppDelegate.swift`, `SceneDelegate.swift`, `Runner.xcodeproj`. |
| Iconos iOS | ✅ Generados | `Runner/Assets.xcassets/AppIcon.appiconset` con todos los tamaños + 1024 px de App Store. |
| Permisos en `Info.plist` | ✅ Puestos | Notificaciones (`NSUserNotificationUsageDescription`), Calendario (`NSCalendarsFullAccessUsageDescription`, legacy `NSCalendarsUsageDescription`), Contactos (`NSContactsUsageDescription`). |
| Compras in-app | ✅ Código multiplataforma | `billing_service.dart` usa `in_app_purchase` → en iOS funciona con **StoreKit** automáticamente. |
| Notificaciones | ✅ Código multiplataforma | `flutter_local_notifications` v18 → `zonedSchedule` funciona igual en iOS. |
| Calendario | ✅ Código multiplataforma | `device_calendar` 4.3.3 → en iOS usa **EventKit** con el mismo código. |
| Tiempo/zona horaria | ✅ | `flutter_timezone` + `timezone`. |
| Legal (privacidad y términos) | ✅ | En `legal/` (URL pública una vez subida al hosting actual). |
| AdMob | ✅ Paquete instalado | `google_mobile_ads` 9.1.0 es multiplataforma; falta solo la config iOS (abajo). |

---

## 1. Requisitos previos (solo de Apple)

1. **Cuenta de desarrollador de Apple** (Apple Developer Program): **99 €/año**.
   - Registro en https://developer.apple.com/programs/ (te pedirá Apple ID + DNI/datos fiscales).
   - La cuenta puede ser **individual** (tu nombre) o **empresa** (para "Develca" como entidad legal). Para subir como *desarrollador personal* no hace falta empresa.
2. **Mac con Xcode** (ya lo tienes: macOS Sequoia + tu Mac).
   - Instalar **Xcode** desde la App Store (gratis).
   - Primera vez: `sudo xcodebuild -license accept` y abrir Xcode una vez para que acepte los términos.
3. **CocoaPods** (gestor de dependencias iOS de Flutter):
   ```bash
   sudo gem install cocoapods
   # o bien: brew install cocoapods
   ```
4. **iPhone físico** (recomendado) para probar notificaciones/calendario/compras. El simulador de Xcode vale para la mayoría de pruebas.
5. **Apple ID de pruebas** ("Apple ID sandbox") para probar compras con dinero ficticio — se crea desde App Store Connect, no hace falta tarjeta.

---

## 2. Cambios de código necesarios (los hago yo cuando toque)

Solo hay **2 cambios de código reales**; el resto es configuración web de Apple.

### 2.1 WorkManager: solo Android (IMPORTANTE)
`lib/main.dart` llama a `Workmanager()` al arrancar (`main()` línea ~30). **WorkManager NO existe en iOS** (es la API de tareas en segundo plano de Android): en iOS lanzaría `MissingPluginException` / no haría nada.

> En iOS las notificaciones locales **las entrega el propio sistema**, así que el watchdog de reprogramación no es necesario (a diferencia de Xiaomi).

Cuando toque, envuelvo esa parte con `if (Platform.isAndroid)`:
```dart
import 'dart:io' show Platform;

if (Platform.isAndroid) {
  Workmanager().initialize(callbackDispatcher, isInDebugMode: false);
  Workmanager().registerPeriodicTask("byebill_periodic_task_1", "check_subscriptions_task", ...);
}
```

### 2.2 AdMob para iOS
AdMob necesita un **App ID específico de iOS** (distinto al de Android) y, opcionalmente, la petición ATT:

1. En el panel de AdMob, **añadir la plataforma iOS** a la app ByeBill (o crear una segunda entrada "ByeBill iOS").
2. Obtener el **App ID iOS** (`ca-app-pub-XXXX~YYYY`) y añadirlo a `ios/Runner/Info.plist`:
   ```xml
   <key>GADApplicationIdentifier</key>
   <string>ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYY</string>
   ```
3. Las **unidades de anuncio** (banner / nativo / intersticial) se generan por plataforma: habrá que crear unidades **iOS** nuevas y separarlas en el código (`ad_service.dart` — hoy hay un único `AdUnitIds`). Al ser multiplataforma, se tendrían dos conjuntos de IDs (uno por plataforma).
4. **ATT (Transparencia de seguimiento)**: si queremos que AdMob pueda personalizar/medir anuncios, en iOS hay que pedir permiso con el diálogo autorizado por Apple:
   - Añadir a `Info.plist`:
     ```xml
     <key>NSUserTrackingUsageDescription</key>
     <string>Tu permiso permite que ByeBill muestre anuncios más relevantes.</string>
     ```
   - El consentimiento **UMP** ya está integrado en la app; hay que habilitar el flujo de ATT junto a UMP en iOS (el SDK de AdMob lo guía).
   - **Alternativa sin ATT**: desactivar la medición/uso de identificador en AdMob (menos ingresos, pero sin diálogo extra). Perfectamente válida para lanzar simple.

### 2.3 Notificaciones: verificar pre-condiciones iOS
- En iOS, `flutter_local_notifications` v18 configura solo el delegate; con las versiones recientes **no hace falta tocar `AppDelegate.swift`** (en las más antiguas había que añadir `UNUserNotificationCenter.current().delegate`). Lo comprobaremos al compilar.
- El permiso se pide igual que en Android (`requestPermissionsIfNeeded`, que ya existe).
- iOS **no tiene** la limitación "alarmas exactas" de Android: las alertas programadas se entregan a la hora establecida. El problema de la notificación tarde queda resuelto por diseño en iOS.

### 2.4 Compras (StoreKit): sin cambios de código
`billing_service.dart` ya es multiplataforma. En iOS:
- La compra de "por vida" (`buyNonConsumable`) se traduce como **non-consumable** de StoreKit. ✅
- Las suscripciones (mensual/anual) se traducen como suscripciones **auto-renovables de StoreKit**. ✅
- Función "restaurar compras" (`restore`) ya existe y funciona con StoreKit. ✅
- 💡 **Ojo con las fechas**: en App Store el servidor de Apple devuelve el tiempo de suscripción real; hoy la app estima la expiración con `purchase.transactionDate + 30/365 días` (mismo código que Android). Funciona, pero la fuente oficial del estado de la suscripción es el **restringed/notification de StoreKit** — se puede refinar luego (documentarlo, no es bloqueante).

---

## 3. Configuración web: Apple Developer + App Store Connect

_(Pasos manuales, clic a clic; no requiere código.)_

### 3.1 Apple Developer
1. Entrar en https://developer.apple.com → **Account** → **Certificates, IDs & Profiles**.
2. **Identifiers → App IDs → `+`**:
   - Type: `App`
   - Bundle ID: **`com.byebill.byebill`** (debe coincidir con el bundle de la app; verificar en Xcode → Runner → Signing & Capabilities).
   - Activar los capabilities que usa la app: **Push Notifications** (opcional), nada más obligatorio. (Calendario/contactos no requieren capability.)
3. **Devices → `+`**: registrar tu iPhone físico (UDID) para instalar la app en desarrollo.
4. **Keys → `+`**: crear una **App Store Connect API Key** (opcional, solo si queremos automatizar subidas vía `transporter`/CI). No necesaria para el primer lanzamiento.

### 3.2 App Store Connect (https://appstoreconnect.apple.com)
1. **Mis apps → `+` → Nueva app**:
   - Plataforma: **iOS**.
   - Nombre: **ByeBill** (mismo nombre que Play; si está cogido, añadir sufijo, ej. "ByeBill – Subscriptions Reminder").
   - Idioma principal: Español (o Inglés).
   - Bundle ID: `com.byebill.byebill`.
   - SKU: texto libre, ej. `byebill-ios-1`.
2. **Productos in-app (IAP)** — **mismos IDs que el código** (imprescindible):
   | Código (`PremiumProductIds`) | Tipo en App Store Connect | Nota |
   |---|---|---|
   | `premium_mensual` | **Suscripción auto-renovable** | Precio mensual (€). |
   | `premium_anual` | **Suscripción auto-renovable** | Precio anual (€). Mismo "grupo de suscripción" que la mensual. |
   | `premium_vitalicio` | **Compra integrada no consumible** | Precio único. |
   - Las suscripciones van dentro de un **Subscription Group** (crear uno: "ByeBill Premium"); dentro del grupo se permite la actualización entre planes.
   - Opcional por país: precios automáticos (Apple sugiere）.
3. **Pestaña General de la app**:
   - **Política de privacidad**: URL pública (la que ya tenemos: `legal/privacidad.html` subida a un hosting; la URL de Play ya la tienes, se puede reutilizar).
   - **Clasificación por edad** y **categoría** (Utilidades / Finanzas).
   - **Datos de privacidad** (App Privacy "labelling"): declarar correctamente lo que recoge la app:
     * **Compras** (identificadores de compra) → Sí.
     * **Publicidad** (si activamos AdMob): identificador de anuncios, medición → declarar.
     * **Contactos/Calendario**: solo se lee con permiso del usuario (declarar como "Uso no vinculado a identidad").
     * **Género/edad**: no se recoge. No usar cripto ni otros.
   - **Contacto de soporte**: tu email (hola@byebill.eu).
4. **TestFlight** (beta):
   - Subir el build (sección 4) y añadir testers con su Apple ID.
   - Límite: **máx. 100 testers** en plan gratuito; suficiente para nuestro caso.
5. **Lanzamiento**:
   - **App Store → Versión de lanzamiento**: capturas de pantalla de iPhone (6.7"/6.5"/5.5" — al menos las 6 que ya tenemos en `store-assets/`, pero **regrabadas en dispositivo/simulador iOS**), descripción, palabras clave, valoración por edad, nota para revisión (si usamos IAP o AdMob, indicarlo), y precio.
   - **Precio**: App Store permite "Gratis + IAP" (mismo modelo que Google).

---

## 4. Compilar, probar y subir (comandos)

```bash
# 1) Desde la raíz del proyecto (terminal):
flutter clean
flutter pub get
flutter build ios --release --no-codesign   # comprueba que compila (sin firmar)

# o directamente el paquete firmado (requiere sesión de Apple en Xcode):
flutter build ipa --release
```
- El primer `flutter build ipa` instalará pods automáticamente y creará **`build/ios/ipa/*.ipa`**.
- **Alternativa gráfica**: abrir `ios/Runner.xcworkspace` en Xcode → seleccionar "Any iOS Device" → **Product → Archive** → con el Organizer pulsar **Distribute App → App Store Connect**. (= equivalente a `flutter build ipa`.)

### Pruebas en el iPhone antes de subir
```bash
flutter run -d <iPhone físico>        # debug directo
flutter build ios --simulator         # solo simulador
```
Verificar en el dispositivo iOS:
- [ ] Notificaciones (7 días / 2 días / día del cobro).
- [ ] Eventos de calendario (crear/editar/eliminar suscripción → el evento se crea/actualiza/borra).
- [ ] Compras: con cuenta **sandbox** (Ajustes del iPhone → App Store → Sandbox) se compra sin pagar.
- [ ] AdMob: con `GADApplicationIdentifier` real se ven anuncios; con el de prueba salen los banners "Test Ad".

---

## 5. Checklist final antes de enviar a revisión

- [ ] Código: WorkManager protegido con `Platform.isAndroid`.
- [ ] `Info.plist`: `GADApplicationIdentifier` + `NSUserTrackingUsageDescription` (si AdMob con ATT).
- [ ] Bundle ID `com.byebill.byebill` registrado en Apple Developer.
- [ ] Icono sin canal alfa (App Store lo rechaza): el que ya generamos cumple; si no, regenerar.
- [ ] Capturas de pantalla iOS (6.7"/6.5"/5.5") hechas con dispositivo iOS.
- [ ] IAP creados con los 3 IDs idénticos al código.
- [ ] Prueba completa en dispositivo físico (notificaciones, calendario, compra sandbox).
- [ ] TestFlight con build subido aprobado.
- [ ] Política de privacidad URL accesible.
- [ ] Declaración de privacidad (App Privacy) coherente con lo implementado.
- [ ] `flutter analyze` sin errores.
- [ ] Versión y build: `pubspec.yaml` → `1.0.1+2` (iOS usa el `+2` como CFBundleVersion; la primera subida puede ser `2`; sube el mismo valor a iOS y Android para mantener la correspondencia).

---

## 6. Diferencias clave que conviene recordar (Android vs Apple)

| Concepto | Google Play | Apple App Store |
|---|---|---|
| Coste de cuenta | 25 $ (un solo pago) | **99 €/año** |
| Pruebas beta | Play = "Prueba interna" con hasta 100 testers | **TestFlight** (100 testers) |
| Revisión | Automática (horas) | Manual por Apple (1–3 días, a veces más) |
| Suscripciones | Play Billing | **StoreKit** (mismo código vía `in_app_purchase`) |
| Tareas en segundo plano | WorkManager (watchdog) | **No hace falta**: iOS entrega las notificaciones él mismo |
| Alarmas exactas | Requiere permiso (fallback inexact) | **Siempre precisas** (sin diálogos extra) |
| Anuncios | AdMob App ID Android | **AdMob App ID iOS** distinto + ATT opcional |
| Backups/restauración | Automático de Google si da permiso | StoreKit `restore()` (ya implementado) |
| Deploy | AAB | **IPA** (Archive en Xcode) |

---

## 7. Qué necesito de ti cuando lo empecemos (checklist)

- [ ] **Apple ID** para crear la cuenta de desarrollador (99 €/año) — o confirmar que ya existe.
- [ ] **Xcode instalado** en tu Mac (App Store) y `sudo gem install cocoapods`.
- [ ] Datos de **facturación/fiscales** para el registro de desarrollador (nombre, NIF/DNI, dirección).
- [ ] Decisión: lanzamos **AdMob en iOS desde el día 1** o lo dejamos desactivado y lo añadimos después.
- [ ] Si AdMob iOS sí: registrar la app iOS en AdMob y traer el **App ID iOS** (`ca-app-pub-…~…`) + decidir ATT (sí/no).
- [ ] **Precios €** de los IAP en App Store (¿iguales a Play? mensual 4,99 € / anual 39,99 € / vitalicio 79,99 € — confirmar).
- [ ] Un **iPhone físico** para pruebas (si lo tienes a mano).

---

> **Resumen ejecutivo:** el único trabajo de código pendiente es el ajuste de WorkManager (2.1) y la configuración de AdMob iOS (2.2). El grueso del esfuerzo es web: cuenta de Apple (99 €/año), crear la app en App Store Connect, crear los 3 IAP con **exactamente** los mismos IDs que el código, hacer capturas iOS, subir el primer IPA vía Archive/Xcode y pasar la revisión de Apple.