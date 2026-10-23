# ByeBill · Alta en AdMob: guía y tareas para Andrea

Este archivo resume **qué necesito de ti** y **los pasos exactos** para darte de alta en AdMob y generar las credenciales reales que sustituirán a los IDs de prueba actuales de la app.

---

## 1. Resumen: lo que necesito de ti (checklist)

Cuando completes el registro, necesitaré **4 valores** (aparecen como `ca-app-pub-…`). Puedes pegármelos aquí en el chat o guardarlos en este archivo.

| # | Valor | Ejemplo de formato | Dónde se usa |
|---|-------|--------------------|--------------|
| 1 | **App ID** de AdMob | `ca-app-pub-1234567890123456~1234567890` | `android/app/build.gradle.kts` (placeholder `admobAppId`) |
| 2 | **Ad Unit ID · Banner adaptativo** | `ca-app-pub-1234567890123456/1111111111` | `lib/core/services/ad_service.dart` → `AdUnitIds.banner` |
| 3 | **Ad Unit ID · Nativo avanzado** | `ca-app-pub-1234567890123456/2222222222` | `lib/core/services/ad_service.dart` → `AdUnitIds.native` |
| 4 | **Ad Unit ID · Intersticial** | `ca-app-pub-1234567890123456/3333333333` | `lib/core/services/ad_service.dart` → `AdUnitIds.interstitial` |

**Datos clave de la app** (ya los tengo, solo confírmame):
- Nombre en AdMob: **ByeBill**
- Plataforma: **Android**
- Paquete (applicationId): **`com.byebill.byebill`**

> ⚠️ Los ID de prueba actuales (`…3940256099942544…`) solo funcionan en desarrollo. Con los reales desaparecerá la etiqueta "Test Ad" y el validador "Native Ad Validator".

---

## 2. Requisitos previos

1. **Cuenta de Google** personal (la que uses normalmente).
2. **La app publicada en Google Play** (recomendado pero no imprescindible para *crear* las unidades). AdMob puede generar el App ID y las unidades sin que la app esté publicada, **pero el tráfico real de anuncios exige** que la app esté listada en una store (Google Play / App Store) y cumplas sus políticas. Si aún no subimos el APK de prueba, podemos hacer el alta y dejar los IDs configurados; el llenado real vendrá cuando esté publicada.
3. **Datos de pago** (vinculación con AdSense) — solo cuando quieras *cobrar*; para configurarlo todo al principio no hace falta.

---

## 3. Pasos paso a paso en el panel de AdMob

### Paso 1 — Crear la cuenta
1. Entra en **https://admob.google.com** e inicia sesión con tu cuenta de Google.
2. Acepta los términos y rellena: **país**, **divisa** y **datos personales/empresa**.
3. Pulsa **"Crear cuenta"** / "Empezar". (Si te pide acuerdos de AdSense, acéptalos con calma, son los de pago.)

### Paso 2 — Añadir la app
1. En el panel, ve a **Apps → Añadir aplicación** ("Add app").
2. **Plataforma**: `Android`.
3. **Nombre de la app**: `ByeBill`.
4. Te preguntará si la app aparece en una store:
   - Si ya está en Google Play → búscala y enlázala.
   - Si no → elige **"No, añadir manualmente"** o similar y escribe el paquete a mano.
5. **Paquete**: `com.byebill.byebill`.
6. Guarda. Ahora tienes el **App ID** en la ficha de la app (panel de Apps → tu app → página de inicio). Es el valor `ca-app-pub-…~…` que va en la casilla **1** del checklist.

### Paso 3 — Crear las 3 unidades de anuncio
En la ficha de tu app, ve a **"Anunciar" → "Unidades de anuncio" → "Añadir unidad"**. Crea una por cada formato (puedes nombrarlas como quieras, p. ej. `byebill_banner`, `byebill_nativo`, `byebill_interstitial`):

1. **Banner adaptativo**
   - Formato: **Banner**
   - Tipo de banner: **Adaptativo** → tamaño **"Anclado" (anchored)**.
   - Genera el **Ad Unit ID** → casilla **2**.
2. **Nativo avanzado**
   - Formato: **Nativo** → **"Nativo avanzado" (native advanced)** — nuestro formato estándar/medium.
   - Genera el **Ad Unit ID** → casilla **3**.
3. **Intersticial**
   - Formato: **Intersticial**.
   - Genera el **Ad Unit ID** → casilla **4**.

> Cada unidad te da un ID distinto (`…/111…`, `…/222…`, `…/333…`). No los confundas entre sí.

### Paso 4 — Configurar el tratamiento de datos (GDPR / UE)
Como la app se usará en la UE, es obligatorio:
1. En **Privacidad y mensajes** → **"Tratamiento de datos" ("Data protection settings")**, revisa y guarda.
2. Marca las opciones de consentimiento adecuadas (ya tenemos el **UMP** integrado en la app: pedirá el consentimiento automáticamente a los usuarios de la UE una vez tengas los IDs reales).

### Paso 5 — Verificación de la app y políticas
1. **Verifica que eres el propietario** de la app cuando te lo pida (normalmente añadiendo un enlace a la ficha de la store o verificando la propiedad del paquete).
2. Revisa la **Política de AdMob** y la **Política de datos de usuario** desde el panel; deja todo en "Aceptado/Verificado" antes del tráfico real.

### Paso 6 (cuando toque cobrar) — Vincular pago
1. En **Pago → Ajustes de pago**, vincula o crea una cuenta **AdSense/Google Pay** con los mismos datos.
2. Rellena datos fiscales y preferencias de pago.

---

## 4. Dónde se pega cada valor en el código

Cuando me pases los 4 IDs, los cambio yo en dos sitios:

**A. App ID (build de Android)** — [android/app/build.gradle.kts](android/app/build.gradle.kts):
```kotlin
manifestPlaceholders["admobAppId"] = "ca-app-pub-XXXXXXXXXXXXXXXX~YYYYYYYY"
```

**B. Unidades de anuncio** — [lib/core/services/ad_service.dart](lib/core/services/ad_service.dart):
```dart
class AdUnitIds {
  static const String banner = 'ca-app-pub-XXXXXXXXXXXXXXXX/1111111111';
  static const String native = 'ca-app-pub-XXXXXXXXXXXXXXXX/2222222222';
  static const String interstitial = 'ca-app-pub-XXXXXXXXXXXXXXXX/3333333333';
}
```

---

## 5. Antes de publicar (recordatorios)

- [ ] Sustituir ids de prueba por los reales (checklist §1).
- [ ] Registrar el teléfono de pruebas como **"dispositivo de prueba"** en el panel de AdMob (Ajustes → Dispositivos de prueba) para poder ver anuncios reales sin inflar el balance ni arriesgar el cierre de la cuenta.
- [ ] La app debe estar **publicada en Google Play** y con las **políticas verificadas** para que los anuncios se sirvan de verdad.
- [ ] Prueba el ciclo completo: banner en todas las pestañas, nativo en Inicio, intersticial al cancelar (máx. 1/15 min) y consentimiento UMP.

---

## 6. Dudas que puedes tener antes de empezar

- **¿Necesito AdSense por separado?** No para configurar; sí para cobrar cuando haya ingresos.
- **¿Cuánto tarda la revisión?** La política suele aprobarse en horas/días. Los anuncios empiezan a servirse cuando la app está publicada y verificada.
- **¿Y si no quiero subir a Google Play aún?** Podemos dejar todos los IDs reales configurados y que empiece a facturar cuando se publique; mientras tanto, para probar usamos el ID de "test" o tu dispositivo de prueba.