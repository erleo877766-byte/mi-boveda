// ============================================================
// QR Validator — Validacion INTELIGENTE de escaneos QR.
// Clasifica el contenido, valida TODOS los formatos de
// direcciones de criptomonedas, detecta URIs de pago,
// verifica que la direccion pertenezca a la red correcta,
// y bloquea URLs de phishing.
// ============================================================

/// Tipos de contenido que puede contener un QR.
enum QrContentType {
  cryptoAddress,
  paymentUri,
  url,
  text,
  empty,
}

/// Resultado de la validacion de un QR escaneado.
class QrValidationResult {
  final QrContentType type;
  final bool isValid;
  final String message;
  final String? address;
  final String? symbol;
  final double? amount;
  final String? rawContent;
  final bool isDangerous;
  final String? detectedNetwork;

  const QrValidationResult({
    required this.type,
    required this.isValid,
    required this.message,
    this.address,
    this.symbol,
    this.amount,
    this.rawContent,
    this.isDangerous = false,
    this.detectedNetwork,
  });
}

// ---- Regex helpers ----
const _base58 = r'[1-9A-HJ-NP-Za-km-z]';
const _bech32Data = r'[qpzry9x8gf2tvdw0s3jn54khce6mua7l]';
const _zbase32 = r'[13456789abcdefghijkmnopqrstuwxyz]';

RegExp _bech32(String hrp) => RegExp('^$hrp(q$_bech32Data{25,80}|p$_bech32Data{38,90})\$');

final _btcBech32 = _bech32('bc1');
final _btcBech32m = RegExp('^bc1p$_bech32Data{58,62}\$');
final _ltcBech32 = _bech32('ltc1');
final _dgbBech32 = _bech32('dgb1');

// ---- Dominios confiables (exploradores de bloques) ----
const _trustedDomains = {
  'blockstream.info',
  'mempool.space',
  'etherscan.io',
  'bscscan.com',
  'polygonscan.com',
  'arbiscan.io',
  'basescan.org',
  'solscan.io',
  'tronscan.org',
  'moneroblocks.info',
  'xmrchain.net',
  'nanolooker.com',
  'sochain.com',
  'blockchair.com',
  'github.com',
  'miboveda.com',
  'cardanoscan.io',
  'polkadot.subscan.io',
  'nearblocks.io',
  'cosmoscan.io',
  'kas.fyi',
  'tonscan.org',
  'atomscan.com',
};

// ---- Patrones de phishing ----
final _suspiciousUrlPatterns = [
  RegExp(r'bitc0in\.|blockchhin\.|etheruem\.|metamask\.', caseSensitive: false),
  RegExp(r'\.(tk|ml|ga|cf|gq)/', caseSensitive: false),
  RegExp(r'login.*\.(com|net|org)/.*wallet', caseSensitive: false),
  RegExp(r'verify.*seed|enter.*seed|import.*wallet', caseSensitive: false),
];

// ============================================================
// PATRONES DE DIRECCIONES POR MONEDA (ordenados por especificidad)
// ============================================================
final Map<String, List<RegExp>> _addressPatterns = {
  // Bitcoin (Legacy, SegWit, Taproot, Testnet)
  'BTC': [
    RegExp('^bc1p$_bech32Data{58,62}\$'), // Taproot
    RegExp('^bc1[qpe]$_bech32Data{25,89}\$'), // Bech32/Bech32m
    RegExp('^[$_base58]{25,34}\$'), // Legacy P2PKH/P2SH
  ],
  'LTC': [
    RegExp('^ltc1p$_bech32Data{58,62}\$'), // MWEB
    RegExp('^ltc1[qpe]$_bech32Data{25,89}\$'), // Bech32
    RegExp('^[LM3]$_base58{25,33}\$'),
  ],
  'BCH': [
    RegExp('^(bitcoincash:)?[qp][a-z0-9]{41}\$'),
    RegExp('^13$_base58{25,33}\$'),
  ],
  'DASH': [RegExp('^X$_base58{33}\$')],
  'DOGE': [RegExp('^D$_base58{33}\$')],
  'DCR': [RegExp('^D[ks]$_base58{24,33}\$')],
  'DGB': [
    RegExp('^dgb1[_bech32Data]{25,89}\$'),
    RegExp('^[AD]$_base58{25,33}\$'),
  ],
  'RVN': [RegExp('^R$_base58{33}\$')],
  'FIRO': [RegExp('^Z$_base58{33}\$')],
  'PIVX': [RegExp('^D$_base58{33}\$')],
  'KMD': [RegExp('^R$_base58{33}\$')],
  'ZEN': [RegExp('^z[SN]$_base58{33}\$')],

  // Monero family
  'XMR': [
    RegExp('^4$_base58{94}\$'),
    RegExp('^8$_base58{94}\$'),
    RegExp('^$_base58{95}\$'),
  ],
  'WOW': [RegExp('^WOW$_base58{94}\$')],
  'ZANO': [
    RegExp('^$_base58{90,200}\$'),
    RegExp(r'^@[\w.-]+$'),
  ],
  'XHV': [RegExp('^(4|8)$_base58{94}\$')],

  // Zcash
  'ZEC': [
    RegExp('^t1$_base58{33}\$'),
    RegExp('^t3$_base58{33}\$'),
    RegExp(r'^zs[a-z0-9]{76}$'),
    RegExp(r'^u1[a-z0-9]{76,80}$'),
  ],

  // Nano / Banano
  'XNO': [RegExp('^(nano|xrb)_$_zbase32{60}\$')],
  'BAN': [RegExp('^ban_$_zbase32{60}\$')],

  // EVM (ETH + todos los tokens ERC-20/BEP-20)
  'ETH': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'MATIC': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'POL': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'BNB': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'ARB': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'AVAX': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'FTM': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'OP': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'BASE': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'SC': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'DEPS': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'NDEPS': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'DEURO': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'FLIP': [RegExp(r'^0x[a-fA-F0-9]{40}$')],

  // Tokens EVM (ERC-20 / BEP-20 / multi-chain)
  'USDT': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'USDC': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'DAI': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'WBTC': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'WETH': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'SHIB': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'PEPE': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'UNI': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'AAVE': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'COMP': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'MKR': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'LDO': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'GRT': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'STORJ': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'BAT': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'ZRX': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'OXT': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'NEXO': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'CAKE': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'ENS': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'GTC': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'TUSD': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'GUSD': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'FRAX': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'USDE': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'PAXG': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'STETH': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'MANA': [RegExp(r'^0x[a-fA-F0-9]{40}$')],
  'CRO': [RegExp(r'^0x[a-fA-F0-9]{40}$')],

  // Tron (TRC-20)
  'TRX': [RegExp('^T$_base58{33}\$')],
  'BTT': [RegExp('^T$_base58{33}\$')],
  'BTTC': [RegExp('^T$_base58{33}\$')],

  // Solana
  'SOL': [RegExp('^$_base58{32,44}\$')],

  // XRP
  'XRP': [
    RegExp('^r$_base58{24,34}\$'),
    RegExp('^X$_base58{34}\$'),
  ],

  // Stellar
  'XLM': [
    RegExp(r'^G[A-Z0-9]{55}$'),
    RegExp(r'^G[A-Z0-9]{55}:[A-Z0-9]{1,12}$'),
  ],

  // Cardano
  'ADA': [
    RegExp(r'^addr1[a-z0-9]{50,110}$'),
    RegExp('^$_base58{59}\$'),
  ],

  // Polkadot
  'DOT': [RegExp('^1$_base58{46,47}\$')],

  // NEAR
  'NEAR': [
    RegExp(r'^[0-9a-f]{64}$'),
    RegExp(r'^[a-z0-9._-]{2,64}\.near$'),
    RegExp(r'^(near|@)[\w.-]+$'),
  ],

  // EOS
  'EOS': [RegExp(r'^[1-5a-z]{1,12}$')],

  // TON
  'TON': [
    RegExp(r'^[A-Za-z0-9_-]{48}$'),
    RegExp(r'^EQ[A-Za-z0-9_-]{44,46}$'),
  ],

  // Hedera
  'HBAR': [RegExp(r'^[0-9]+\.[0-9]+\.[0-9]+$')],

  // Kaspa
  'KAS': [
    RegExp(r'^kaspa:[a-z0-9]{61,64}$'),
    RegExp(r'^[a-z0-9]{61,64}$'),
  ],

  // Cosmos
  'ATOM': [RegExp(r'^cosmos1[0-9a-z]{38}$')],

  // Secret Network
  'SCRT': [RegExp(r'^secret1[0-9a-z]{38}$')],

  // THORChain
  'RUNE': [
    RegExp(r'^thor1[0-9a-z]{38}$'),
    RegExp(r'^[a-z0-9]{2,20}$'),
  ],

  // dYdX
  'DYDX': [RegExp(r'^dydx1[0-9a-z]{38}$')],

  // Verge
  'XVG': [RegExp('^D$_base58{33}\$')],

  // Stacks
  'STX': [RegExp('^SP$_base58{33,34}\$')],
};

// ============================================================
// MAPEO MONEDA -> RED (para deteccion de red equivocada)
// ============================================================
const _symbolToNetwork = {
  'BTC': 'bitcoin',
  'LTC': 'bitcoin',
  'BCH': 'bitcoin',
  'DASH': 'bitcoin',
  'DOGE': 'bitcoin',
  'DCR': 'bitcoin',
  'DGB': 'bitcoin',
  'RVN': 'bitcoin',
  'FIRO': 'bitcoin',
  'PIVX': 'bitcoin',
  'KMD': 'bitcoin',
  'ZEN': 'bitcoin',
  'XMR': 'monero',
  'WOW': 'monero',
  'ZANO': 'monero',
  'XHV': 'monero',
  'ZEC': 'zcash',
  'XNO': 'nano',
  'BAN': 'nano',
  'ETH': 'ethereum',
  'MATIC': 'polygon',
  'POL': 'polygon',
  'BNB': 'bsc',
  'ARB': 'arbitrum',
  'AVAX': 'avalanche',
  'FTM': 'fantom',
  'OP': 'optimism',
  'BASE': 'base',
  'TRX': 'tron',
  'BTT': 'tron',
  'BTTC': 'tron',
  'SOL': 'solana',
  'XRP': 'xrp',
  'XLM': 'stellar',
  'ADA': 'cardano',
  'DOT': 'polkadot',
  'NEAR': 'near',
  'EOS': 'eos',
  'TON': 'ton',
  'HBAR': 'hedera',
  'KAS': 'kaspa',
  'ATOM': 'cosmos',
  'SCRT': 'secret',
  'RUNE': 'thorchain',
  'DYDX': 'dydx',
  'XVG': 'verge',
  'STX': 'stacks',
};

// Redes EVM: todas aceptan formato 0x
const _evmNetworks = {
  'ethereum',
  'erc20',
  'bep20',
  'base',
  'arbitrum',
  'polygon',
};

// ============================================================
// DETECCION DE RED POR FORMATO DE DIRECCION
// ============================================================
String? _detectNetworkByFormat(String address) {
  final a = address.trim();
  if (RegExp(r'^0x[a-fA-F0-9]{40}$').hasMatch(a)) return 'evm';
  if (RegExp('^bc1').hasMatch(a.toLowerCase())) return 'bitcoin';
  if (RegExp('^[13]').hasMatch(a)) return 'bitcoin';
  if (RegExp('^[mn]').hasMatch(a)) return 'bitcoin';
  if (RegExp('^T').hasMatch(a) && RegExp('^T$_base58{33}\$').hasMatch(a)) return 'tron';
  if (RegExp('^(nano|xrb)_').hasMatch(a)) return 'nano';
  if (RegExp('^ban_').hasMatch(a)) return 'nano';
  if (RegExp('^[LM3]$_base58{25,33}\$').hasMatch(a)) return 'bitcoin'; // LTC similar
  if (RegExp('^addr1').hasMatch(a)) return 'cardano';
  if (RegExp('^cosmos1').hasMatch(a)) return 'cosmos';
  if (RegExp('^kaspa:').hasMatch(a)) return 'kaspa';
  if (RegExp('^thor1').hasMatch(a)) return 'thorchain';
  if (RegExp('^[1-9A-HJ-NP-Za-km-z]{32,44}\$').hasMatch(a) && !RegExp('^[13mnT]').hasMatch(a))
    return 'solana';
  return null;
}

// ============================================================
// URI DE PAGO
// ============================================================
final _paymentUriPattern = RegExp(
  r'^(bitcoin|litecoin|ethereum|monero|bitcoincash|dogecoin|tron|solana|ripple|nano|cardano|polkadot|cosmos|ton|near):',
  caseSensitive: false,
);

// ============================================================
// URL GENERICA
// ============================================================
final _urlPattern = RegExp(r'^https?://', caseSensitive: false);

// ============================================================
// FUNCION PRINCIPAL
// ============================================================
QrValidationResult validateQrContent(String? content, {String? currentSymbol}) {
  final text = (content ?? '').trim();

  if (text.isEmpty) {
    return const QrValidationResult(
      type: QrContentType.empty,
      isValid: false,
      message: 'El codigo QR esta vacio',
    );
  }

  // 1) URI de pago
  if (_paymentUriPattern.hasMatch(text)) {
    return _validatePaymentUri(text);
  }

  // 2) URL
  if (_urlPattern.hasMatch(text)) {
    return _validateUrl(text);
  }

  // 3) Direccion directa
  final addrResult = _validateAsAddress(text, currentSymbol);
  if (addrResult != null) return addrResult;

  // 4) Texto plano no reconocido
  return QrValidationResult(
    type: QrContentType.text,
    isValid: false,
    message: 'Formato no reconocido como direccion de criptomoneda',
    rawContent: text,
  );
}

QrValidationResult _validatePaymentUri(String uri) {
  try {
    final colonIdx = uri.indexOf(':');
    final symbol = uri.substring(0, colonIdx).toUpperCase();

    final questionIdx = uri.indexOf('?');
    final addressPart =
        questionIdx > 0 ? uri.substring(colonIdx + 1, questionIdx) : uri.substring(colonIdx + 1);

    final address = Uri.decodeComponent(addressPart).trim();

    if (address.isEmpty) {
      return QrValidationResult(
        type: QrContentType.paymentUri,
        isValid: false,
        message: 'URI de pago sin direccion de destino',
        symbol: symbol,
      );
    }

    double? amount;
    if (questionIdx > 0) {
      final params = Uri.splitQueryString(uri.substring(questionIdx + 1));
      if (params.containsKey('amount')) {
        amount = double.tryParse(params['amount']!);
      }
    }

    final addrValid = _isValidAddressForSymbol(symbol, address);
    if (!addrValid) {
      return QrValidationResult(
        type: QrContentType.paymentUri,
        isValid: false,
        message: 'Direccion invalida en el URI de $symbol',
        address: address,
        symbol: symbol,
        amount: amount,
      );
    }

    String msg = 'Pago detectado: $symbol';
    if (amount != null) msg += ' $amount';
    msg += ' -> ${_truncateAddress(address)}';

    return QrValidationResult(
      type: QrContentType.paymentUri,
      isValid: true,
      message: msg,
      address: address,
      symbol: symbol,
      amount: amount,
    );
  } catch (e) {
    return QrValidationResult(
      type: QrContentType.paymentUri,
      isValid: false,
      message: 'URI de pago malformado',
      rawContent: uri,
    );
  }
}

QrValidationResult _validateUrl(String url) {
  try {
    final uri = Uri.parse(url);
    final host = uri.host.toLowerCase();

    for (final pattern in _suspiciousUrlPatterns) {
      if (pattern.hasMatch(url)) {
        return QrValidationResult(
          type: QrContentType.url,
          isValid: false,
          message: 'URL sospechosa detectada: posible intento de phishing',
          rawContent: url,
          isDangerous: true,
        );
      }
    }

    final isTrusted = _trustedDomains.any((d) => host == d || host.endsWith('.$d'));
    if (isTrusted) {
      return QrValidationResult(
        type: QrContentType.url,
        isValid: true,
        message: 'Enlace de explorador de bloques: $host',
        rawContent: url,
      );
    }

    return QrValidationResult(
      type: QrContentType.url,
      isValid: false,
      message: 'Codigo contiene un enlace web. No se aceptan URLs como direcciones de envio.',
      rawContent: url,
      isDangerous: true,
    );
  } catch (e) {
    return QrValidationResult(
      type: QrContentType.url,
      isValid: false,
      message: 'URL malformada',
      rawContent: url,
      isDangerous: true,
    );
  }
}

QrValidationResult? _validateAsAddress(String text, String? currentSymbol) {
  // Intentar con la moneda actual primero
  if (currentSymbol != null && _isValidAddressForSymbol(currentSymbol, text)) {
    // Verificar si la direccion escaneada pertenece a la red correcta
    final detectedNet = _detectNetworkByFormat(text);
    final expectedNet = _symbolToNetwork[currentSymbol.toUpperCase()];
    final networkWarning = _checkNetworkMismatch(currentSymbol, detectedNet, expectedNet);

    if (networkWarning != null) {
      return QrValidationResult(
        type: QrContentType.cryptoAddress,
        isValid: false,
        message: networkWarning,
        address: text,
        symbol: currentSymbol,
        detectedNetwork: detectedNet,
      );
    }

    return QrValidationResult(
      type: QrContentType.cryptoAddress,
      isValid: true,
      message: 'Direccion de $currentSymbol valida: ${_truncateAddress(text)}',
      address: text,
      symbol: currentSymbol,
    );
  }

  // Intentar con todas las monedas conocidas
  for (final entry in _addressPatterns.entries) {
    if (entry.key == currentSymbol) continue;
    for (final pattern in entry.value) {
      if (pattern.hasMatch(text)) {
        final detectedNet = _symbolToNetwork[entry.key] ?? 'unknown';
        return QrValidationResult(
          type: QrContentType.cryptoAddress,
          isValid: true,
          message: 'Direccion de ${entry.key} detectada: ${_truncateAddress(text)}',
          address: text,
          symbol: entry.key,
          detectedNetwork: detectedNet,
        );
      }
    }
  }

  // Sin match
  if (text.length >= 26 && text.length <= 120) {
    return QrValidationResult(
      type: QrContentType.cryptoAddress,
      isValid: false,
      message: 'No se reconoce como direccion de criptomoneda conocida. Verifica que sea correcta.',
      address: text,
      rawContent: text,
    );
  }

  return null;
}

/// Verifica si la direccion escaneada es de la red equivocada.
String? _checkNetworkMismatch(String currentSymbol, String? detectedNet, String? expectedNet) {
  if (detectedNet == null || expectedNet == null) return null;
  if (detectedNet == expectedNet) return null;

  // EVM es compatible entre sí (ETH, BSC, Polygon, Arbitrum, Base)
  if (detectedNet == 'evm' && _evmNetworks.contains(expectedNet)) return null;

  // Bitcoin family es compatible
  if (detectedNet == 'bitcoin' && expectedNet == 'bitcoin') return null;

  // Tron family
  if (detectedNet == 'tron' && expectedNet == 'tron') return null;

  // Nano family
  if (detectedNet == 'nano' && expectedNet == 'nano') return null;

  return 'Esta direccion parece ser de $detectedNet pero $currentSymbol '
      'esta en la red $expectedNet. '
      'Usa una direccion correcta de $expectedNet para evitar perder fondos.';
}

bool _isValidAddressForSymbol(String symbol, String address) {
  final patterns = _addressPatterns[symbol.toUpperCase()];
  if (patterns == null) return address.length >= 4;
  return patterns.any((p) => p.hasMatch(address));
}

String _truncateAddress(String addr) {
  if (addr.length <= 16) return addr;
  return '${addr.substring(0, 8)}...${addr.substring(addr.length - 6)}';
}

/// Detecta automaticamente que moneda es una direccion.
/// Util para cuando el usuario escanea sin haber seleccionado moneda.
String? detectSymbolByAddress(String address) {
  for (final entry in _addressPatterns.entries) {
    for (final pattern in entry.value) {
      if (pattern.hasMatch(address)) return entry.key;
    }
  }
  return null;
}

/// Detecta la red de una direccion (para monedas multi-chain).
String? detectNetworkByAddress(String address) => _detectNetworkByFormat(address);
