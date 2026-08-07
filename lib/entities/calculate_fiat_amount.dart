import 'package:cw_core/amount/amount_sanitizer.dart';

String calculateFiatAmount({double? price, String? cryptoAmount, bool raw = false}) {
  if (price == null || cryptoAmount == null) {
    return '0.00';
  }

  cryptoAmount = cryptoAmount.sanitized();

  final _amount = double.tryParse(cryptoAmount);
  if (_amount == null || _amount.isNaN) return '0.00';
  final _result = price * _amount;
  final result = _result < 0 ? _result * -1 : _result;

  if (result == 0.0) {
    return '0.00';
  }

  if (raw) {
    return result.toStringAsFixed(3);
  }

  // Mostrar hasta 3 decimales y nunca "0.00" para montos muy chicos:
  // se ve el valor exacto (p.ej. 0.007) en vez de "< 0.01".
  var formatted = '';
  final parts = result.toString().split('.');

  if (parts.length >= 2) {
    if (parts[1].length > 3) {
      formatted = formatWithCommas(parts[0] + '.' + parts[1].substring(0, 3));
    } else {
      formatted = formatWithCommas(parts[0] + '.' + parts[1]);
    }
  } else {
    formatted = formatWithCommas(parts[0]);
  }

  return formatted;
}

String formatWithCommas(String? number) {
  if (number?.isEmpty ?? true) return '';

  final parts = number!.split('.');
  final integerPart = parts[0];
  var decimalPart = parts.length > 1 ? parts[1] : '';

  final formattedInteger = integerPart.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (Match match) => ',',
  );

  if (decimalPart.length == 1) {
    decimalPart = "${decimalPart}0";
  }

  return decimalPart.isNotEmpty ? '$formattedInteger.$decimalPart' : formattedInteger;
}
