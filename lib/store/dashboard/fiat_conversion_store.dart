import 'package:cw_core/crypto_currency.dart';
import 'package:mobx/mobx.dart';

part 'fiat_conversion_store.g.dart';

class FiatConversionStore = FiatConversionStoreBase with _$FiatConversionStore;

abstract class FiatConversionStoreBase with Store {
  FiatConversionStoreBase() : prices = ObservableMap<CryptoCurrency, double>() {
    previousPrices = <CryptoCurrency, double>{};
  }

  @observable
  ObservableMap<CryptoCurrency, double> prices;

  /// Precio USD anterior por moneda, para mostrar la dirección
  /// (verde si sube, rojo si baja). No es observable: se consulta junto
  /// con [prices] en el mismo builder de la UI.
  Map<CryptoCurrency, double> previousPrices = <CryptoCurrency, double>{};

  /// 1 si el precio subió, -1 si bajó, 0 si se mantuvo (umbral 0.1%).
  int priceDirection(CryptoCurrency currency) {
    final current = prices[currency];
    final previous = previousPrices[currency];
    if (current == null || current <= 0 || previous == null || previous <= 0) return 0;

    final change = (current - previous) / previous;
    if (change > 0.001) return 1;
    if (change < -0.001) return -1;
    return 0;
  }
}
