# Mi Bóveda

Billetera de criptomonedas descentralizada para Android y Windows. Tus claves, tus fondos, tu control.

Fork de [Cake Wallet](https://github.com/cake-tech/cake_wallet) — Copyright (c) 2018-2025 Cake Labs LLC. Licencia MIT.

---

## Descargas

Descarga la ultima version desde la release automatica:

| Plataforma | Archivo | Tamano | Descarga |
|---|---|---|---|
| Android (arm64) | MiBoveda.apk | ~265 MB | [Descargar APK](https://github.com/erleo877766-byte/mi-boveda/releases/latest/download/MiBoveda.apk) |
| Windows (instalador) | MiBovedaSetup.exe | ~70 MB | [Descargar EXE](https://github.com/erleo877766-byte/mi-boveda/releases/latest/download/MiBovedaSetup.exe) |

### Instalacion en Android

1. Descarga el APK desde el boton de arriba.
2. Abrilo y toca **Instalar**.
3. Si aparece Google Play Protect: toca **Mas detalles** > **Instalar de todos modos**.
4. La app se conecta automaticamente al servidor Cerebro para nodos, precios e intercambios.

### Instalacion en Windows

1. Descarga `MiBovedaSetup.exe` desde el boton de arriba.
2. Ejecutalo y segui los pasos del instalador.
3. Se crean accesos directos en el Escritorio y Menu Inicio.
4. La app se conecta automaticamente al servidor Cerebro.

### Intercambios Erleo

La wallet incluye el sistema de intercambios Erleo integrado. Podes intercambiar entre monedas directamente desde la app sin crear cuenta. El servidor Cerebro calcula comisiones, tiempos de confirmacion y ejecuta los intercambios de forma segura.

---

## Criptomonedas soportadas

Mas de 60 criptomonedas incluyendo:

| Red | Simbolo | Redes |
|---|---|---|
| Monero | XMR | Mainnet |
| Bitcoin | BTC | Mainnet, Lightning |
| Ethereum | ETH | Mainnet, Base, Arbitrum |
| Litecoin | LTC | Mainnet |
| Bitcoin Cash | BCH | Mainnet |
| Solana | SOL | Mainnet |
| Tron | TRX | Mainnet |
| Nano | XNO | Mainnet |
| Polygon | POL | Mainnet |
| BNB Chain | BNB | Mainnet |
| Dogecoin | DOGE | Mainnet |
| Dash | DASH | Mainnet |
| Zcash | ZEC | Mainnet |
| Decred | DCR | Mainnet |
| Avalanche | AVAX | Mainnet |
| Ripple | XRP | Mainnet |
| Cardano | ADA | Mainnet |
| USDT | USDT | ERC-20, TRC-20, BSC, Polygon, Solana, Arbitrum |
| USDC | USDC | ERC-20, TRC-20, Polygon, Solana, Arbitrum |

Y muchos tokens ERC-20/BEP-20 adicionales: AAVE, COMP, DAI, ENOS, GRT, LDO, MKR, PEPE, SHIB, UNI, WBTC, WETH, y mas.

---

## Caracteristicas

- Multiples monederos con claves privadas locales
- Precios en tiempo real via Binance/CoinGecko
- Envio y recepcion de criptomonedas
- Libreta de direcciones
- Codigos QR
- Notas de transacciones locales
- Control de tarifas de red
- Conexiones Tor para privacidad
- Autenticacion de dos factores (2FA)
- Intercambios Erleo integrados (sin registro, sin cuenta)
- 60+ criptomonedas soportadas
- Nodos sincronizados automaticamente desde el servidor
- Notificaciones en tiempo real desde el servidor

### Monero (XMR)

- Clave de vista retenida en el dispositivo
- Subdirecciones y cuentas
- Altura de restauracion configurable
- Envio a multiples destinatarios

### Bitcoin (BTC)

- Control de monedas (coin control)
- Generacion automatica de direcciones
- Envio a multiples destinatarios

### Ethereum (ETH)

- Almacenar ETH y tokens ERC-20
- Tokens personalizados por direccion de contrato

---

## Compilacion

Instrucciones en `scripts/` y `.github/workflows/`.

## Contribuir

Las traducciones estan en `res/values/strings_XX.arb`.

---

## Licencia

Este proyecto esta licenciado bajo la Licencia MIT.

Basado en el codigo fuente de [Cake Wallet](https://github.com/cake-tech/cake_wallet) por Cake Labs LLC.

Copyright (c) 2018-2025 Cake Labs LLC. Todos los derechos reservados.

Las condiciones completas de la licencia se encuentran en [LICENSE.md](LICENSE.md).

Modificaciones realizadas por Leonardo Noel Salazar Mendoza, 2026.
