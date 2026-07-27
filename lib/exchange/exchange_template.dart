import 'package:hive/hive.dart';

class ExchangeTemplate extends HiveObject {
  static const exchangeTemplateTypeId = 0;

  static const boxName = 'ExchangeTemplates';
  static const boxKey = 0;

  String from;
  String to;
  String provider;
  double amount;

  ExchangeTemplate({
    this.from = '',
    this.to = '',
    this.provider = '',
    this.amount = 0,
  });
}
