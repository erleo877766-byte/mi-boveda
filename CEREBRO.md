# Mapa del sistema Cerebro / Erleo

El sistema "Cerebro" tiene **dos mitades**:

1. **El servidor** (Node/Express + SQLite/Turso) que recibe órdenes de intercambio pequeño, las almacena, calcula comisiones y tiene un panel web para administrarlas.
2. **La billetera Mi Bóveda** (Flutter/Dart) que se conecta al servidor, lee su configuración (`/api/v1/config`) y le envía órdenes cuando el monto está por debajo del mínimo de ChangeNOW ("intercambio propio" / **Erleo**).

> Antes de buscar en el `.exe` (código de la billetera) o en el panel web: decide primero **qué mitad** estás buscando. La tabla de abajo te lleva directo al archivo.

---

## 1. Servidor (Cerebro) — `server/`

Todo vive dentro de `cake_wallet-6.3.2/server/`.

| Qué es | Dónde |
|---|---|
| Punto de entrada / arranque, puerto, login rate-limit | `server/src/index.js` |
| **Todas las rutas HTTP** (config, órdenes, toggle Erleo, reservas, comisiones, reportes) | `server/src/routes/api.js` |
| Creación/consulta/aprobación de órdenes Erleo | `server/src/services/orders.js` |
| Cálculo de comisiones (por velocidad y especiales) | `server/src/services/commission.js` |
| Reportes y contabilidad | `server/src/services/reports.js` |
| Precios para calcular comisión en USD | `server/src/services/prices.js` |
| Autenticación (API key de la app + sesión del panel) | `server/src/middleware/auth.js` |
| **Base de datos** (SQLite local o Turso remoto): tablas `settings`, `reserves`, `orders`, `commission_events`, `order_events`, `small_order_commission` | `server/src/db/index.js` |
| **Panel web del admin** (HTML/CSS/JS) | `server/public/` |
| Dependencias (no tocar) | `server/node_modules/` |

### Endpoints del servidor

| Endpoint | Uso | Quién lo llama |
|---|---|---|
| `POST /api/v1/admin/login` | Login del panel (password en `ADMIN_PASSWORD`) | Panel web |
| `GET /api/v1/config` | Config global: `globalEnabled`, comisiones, `coins` (reservas), `erleoExchangeEnabled` | **La app** (`cerebro_service.dart`) |
| `POST /api/v1/orders` | La app envía una orden pequeña | **La app** (`submitErleoOrder`) |
| `GET /api/v1/orders/:id` | La app consulta estado (pending/approved/rejected/completed) | **La app** (`fetchErleoOrder`) |
| `GET /api/v1/orders` | Listado | Panel |
| `POST /api/v1/orders/:id/approve` / `reject` / `complete` | Admin procesa | Panel |
| `GET/POST /api/v1/settings/erleo-enabled` | Leer/cambiar el toggle "Intercambios Erleo" | Panel |
| `GET/POST /api/v1/settings/api-key*` | Ver/regenerar la API key de la app | Panel |
| `GET/POST /api/v1/reserves`, `DELETE /api/v1/reserves/:symbol` | Direcciones de reserva por moneda | Panel |
| `GET/POST /api/v1/small-commissions` | Comisión especial por moneda | Panel |
| `GET /api/v1/report/*` | Reportes y export CSV | Panel |

### Config del servidor (variables de entorno)

| Variable | Efecto |
|---|---|
| `PORT` | Puerto HTTP (default `8787`) |
| `ADMIN_PASSWORD` | Contraseña del panel (si no está, se genera una y se muestra en consola) |
| `CEREBRO_API_KEY` / auto-generada | Clave que usa la app; se persiste en la tabla `settings` |
| `TURSO_DATABASE_URL` + `TURSO_AUTH_TOKEN` | Si están, usa la DB remota de Turso (persistente en Render); si no, SQLite local `server/data/cerebro.db` |

---

## 2. La billetera (Flutter/Dart) — `lib/`

### Servicios núcleo

| Qué es | Dónde |
|---|---|
| **`CerebroService`**: conexión, `poll()`, config cacheada, toggle `erleoExchangeEnabled`, envío de órdenes `submitErleoOrder`, consulta de estado `fetchErleoOrder`, comisiones, `killSwitch`, `refreshNow()` | `lib/core/cerebro_service.dart` |
| **`CerebroAdminService`**: cliente del panel (login, toggle Erleo, órdenes, reservas, comisiones, reportes, API key) | `lib/core/cerebro_admin_service.dart` |
| **`cerebro_node_sync`**: sincronización de nodos built-in desde el Cerebro + tipos (`CerebroNode`) | `lib/core/cerebro_node_sync.dart` |
| Registro en el contenedor de dependencias (`getIt`) | `lib/di.dart:1578-1581` |
| Arranque del `CerebroService` al iniciar la app | `lib/reactions/bootstrap.dart:58` |

### Páginas / UI

| Qué es | Dónde |
|---|---|
| **Panel admin del Cerebro** (dentro de la app): toggle Erleo, órdenes pendientes/aprobadas/historial, reservas, comisiones, reporte | `lib/new-ui/pages/cerebro_panel_page.dart` |
| **Config del Cerebro** (URL + API key + botón conectar) — entrada en Ajustes → "Intercambios Erleo" | `lib/new-ui/pages/cerebro_config_page.dart` |
| Indicador de conexión (verde/rojo/amarillo) en la página de swap | `lib/new-ui/widgets/swap_page/cerebro_connection_status.dart` |
| Avisos emergentes de Erleo (procesando/aprobado/completado/rechazado) | `lib/new-ui/pages/swap_page.dart` (`_showErleo*`) |
| Aviso de límite en swap ("se enviará a tu Cerebro") | `lib/new-ui/widgets/swap_page/swap_limit_popup.dart` |
| Ruta para entrar al panel (Ajustes → Intercambios Erleo) | `lib/new-ui/pages/settings_page.dart:106-117` |

### Lógica de la app (ViewModel)

| Qué es | Dónde |
|---|---|
| Estados de trade de Erleo (`TradeIsErleoPending/Approved/Completed/Rejected/Error`) | `lib/exchange/exchange_trade_state.dart:23-56` |
| Lógica del intercambio: `canUseErleoForBelowMin`, `canAttemptErleoForBelowMin`, `submitToErleo`, `_startErleoPolling`, `cancelErleoWait`, `erleoSpeed` | `lib/view_model/exchange/exchange_view_model.dart` (líneas 577-610, 1429-1519) |
| Botón de swap habilitado/deshabilitado según Cerebro | `lib/new-ui/pages/swap_page.dart` (`_swapButtonDisabled`, ~línea 839) |
| Comisión del Cerebro en la pantalla de enviar | `lib/view_model/send/send_view_model.dart` (`cerebroCommission`, ~líneas 1245-1330) |
| Kill switch del Cerebro (bloquea envíos) | `lib/view_model/send/send_view_model.dart:677` |
| Tipo de wallet nuevo afectado por nodos del Cerebro | `lib/src/screens/new_wallet/new_wallet_type_page.dart:108` |

### Almacenamiento en la billetera (claves de preferencias)

Definidas en `lib/entities/preferences_key.dart:148-154`, leídas/escritas en `lib/store/settings_store.dart` y `lib/core/cerebro_service.dart`:

| Clave | Qué guarda |
|---|---|
| `cerebro_server_url` | URL del servidor Cerebro |
| `cerebro_api_key` | API key de la app |
| `cerebro_last_config` | Última config descargada (caché offline) |
| `cerebro_last_sync` | Marca de tiempo de la última sincronización |
| `cerebro_admin_password` / `cerebro_admin_token` | Credenciales del panel (login de admin) |
| `cerebro_api_key_shown` | Si la API key ya se mostró una vez en el panel |

### Textos / idiomas (i18n)

Las cadenas `erleo_*` se editan en los archivos fuente `res/values/strings_*.arb` (en español: `strings_es.arb`). Después se regenera `lib/generated/i18n.dart` (que es lo que usa el código) con el generador de localizaciones del proyecto.

### Constantes importantes

- URL y API key por defecto del Cerebro: `lib/core/cerebro_service.dart:74-75` (`kCerebroServerUrl`, `kCerebroApiKey`).
- Email de soporte del proyecto: `erleo877766@gmail.com` (aparece en `lib/utils/exception_handler.dart:93` y popups).

---

## 3. Flujo de una orden Erleo (de punta a punta)

```
Usuario mete monto < mínimo de ChangeNOW
  → swap_page.dart detecta (SwapLimitPopup muestra "se enviará a tu Cerebro")
  → exchange_view_model.createTrade():
        - si no hay proveedor cotizado y canAttemptErleoForBelowMin → submitToErleo()
  → submitToErleo() hace cerebro.refreshNow() (despierta Render, actualiza erleoExchangeEnabled)
  → cerebro.submitErleoOrder(...) → POST /api/v1/orders  (servidor guarda en tabla orders)
  → exchange_view_model._startErleoPolling(orderId) cada 5s:
        GET /api/v1/orders/:id → pending | approved | rejected | completed
  → Admin ve la orden en el panel (cerebro_panel_page.dart o web) y la aprueba/completa
  → swap_page.dart muestra el popup del estado final
```

---

## 4. Cómo levantar / probar

**Servidor (local):**
```bash
cd server
npm install
npm start            # http://localhost:8787  (panel: /   API: /api/v1)
```

**Servidor (producción en Render):** repo del servidor + variables `ADMIN_PASSWORD`, `TURSO_DATABASE_URL`, `TURSO_AUTH_TOKEN`. La URL pública (hoy `https://miboveda-cerebro.onrender.com`) va en `cerebro_service.dart:74` o en la pantalla de Config del Cerebro dentro de la app.

**Billetera (compilar el exe):**
```bash
flutter build windows --release
# → build/windows/x64/runner/Release/MiBoveda.exe
```

---

## 5. Preguntas rápidas → archivo

| Pregunta | Abrir |
|---|---|
| "¿El toggle Erleo está activo?" | `server/src/routes/api.js` (`erleo-enabled`) o Panel → Intercambios Erleo |
| "¿Cómo decide la app si puede enviar por debajo del mínimo?" | `exchange_view_model.dart` → `canUseErleoForBelowMin` |
| "¿A qué servidor apunta la app?" | `cerebro_service.dart:74` y/o Ajustes → Intercambios Erleo |
| "¿Dónde veo las órdenes que llegan?" | Panel web del Cerebro o `cerebro_panel_page.dart` |
| "¿Dónde están las comisiones?" | Servidor: `commission.js` + `reports.js`; App: `send_view_model.dart` (`cerebroCommission`) |
| "¿Dónde cambio las direcciones de reserva?" | Panel → reservas (`POST /api/v1/reserves`) |
| "¿Dónde está la DB?" | Local: `server/data/cerebro.db`; prod: Turso (`TURSO_DATABASE_URL`) |
