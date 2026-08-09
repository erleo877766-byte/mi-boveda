import 'package:cake_wallet/core/cerebro_service.dart';
import 'package:cake_wallet/di.dart';
import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/view_model/exchange/exchange_view_model.dart';
import 'package:cw_core/crypto_amount_format.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

class SwapLimitPopup extends StatelessWidget {
  const SwapLimitPopup({super.key, required this.exchangeViewModel});

  final ExchangeViewModel exchangeViewModel;

  static const outlineColor = Color(0xFFFFB84E);
  static const backgroundColor = Color(0xFF8E5800);

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: Duration(milliseconds: 200),
      curve: Curves.easeInOutCubic,
      child: Container(
        width: double.infinity,
        child: Observer(builder: (_) {
          final amount = exchangeViewModel.hasDepositAmount
              ? double.tryParse(exchangeViewModel.depositAmountCanonical)
              : null;
          final max = exchangeViewModel.limits.max ?? double.infinity;
          final min = exchangeViewModel.limits.min ?? 0;
          final tooLarge = amount != null && max != 0 && amount > max;
          final tooSmall = amount != null && min != 0 && amount < min;
          final show = amount != null && (tooLarge || tooSmall);

          // Intercambio propio (Erleo): aunque el monto esté por debajo del
          // mínimo de ChangeNOW, el Cerebro puede procesarlo. No bloqueamos.
          final erleoApplies =
              tooSmall && exchangeViewModel.canAttemptErleoForBelowMin;

          final askText =
              tooLarge ? S.of(context).enter_less_than : S.of(context).enter_greater_than;
          final neededAmount = (tooLarge ? max : min).toString().withMaxDecimals(8);
          final currency = exchangeViewModel.depositCurrency.title;

          // Mensaje claro con el mínimo real de ChangeNOW:
          // "Mín.: 18.0545715 XNO" (o el máximo si es demasiado grande).
          final message = tooLarge
              ? "$askText $neededAmount $currency"
              : erleoApplies
                  ? "${S.of(context).min_amount(neededAmount)} $currency · se enviará a tu Cerebro"
                  : "${S.of(context).min_amount(neededAmount)} $currency";

          // Cuando Erleo aplica, mostrar cuánto recibirá el usuario tras la comisión %.
          Widget? erleoNetWidget;
          if (erleoApplies) {
            final cerebro = getIt.get<CerebroService>();
            final pct = cerebro.commissionPercent;
            final estReceive = double.tryParse(exchangeViewModel.receiveAmountCanonical);
            final neto = estReceive != null ? cerebro.erleoNetEstimate(estReceive) : null;
            erleoNetWidget = Padding(
              padding: const EdgeInsets.only(top: 8),
              child: Text(
                [
                  if (pct > 0) 'Comisión del servicio: ${pct.toStringAsFixed(2)}% del intercambio',
                  if (neto != null && neto > 0)
                    'Recibirás aprox. ${neto.toStringAsFixed(8)} ${exchangeViewModel.receiveCurrency.title}',
                  'Tu cerebro procesará el intercambio tras la aprobación.',
                ].join('\n'),
                textAlign: TextAlign.center,
                style: TextStyle(
                    color: outlineColor, fontWeight: FontWeight.w400, fontSize: 11, height: 1.4),
              ),
            );
          }

          return Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: AnimatedOpacity(
              duration: Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              opacity: show ? 1 : 0,
              child: Container(
                height: show ? null : 0,
                decoration: BoxDecoration(
                    color: backgroundColor, borderRadius: BorderRadius.circular(99999)),
                width: double.infinity,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0, horizontal: 16),
                  child: Column(
                    children: [
                      Text(
                        message,
                        textAlign: TextAlign.center,
                        style: TextStyle(
                            color: outlineColor, fontWeight: FontWeight.w500, fontSize: 12),
                      ),
                      if (erleoNetWidget != null) erleoNetWidget,
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
      ),
    );
  }
}
