import 'package:cake_wallet/generated/i18n.dart';
import 'package:cake_wallet/new-ui/widgets/coins_page/assets_history/asset_details_modal.dart';
import 'package:cake_wallet/view_model/dashboard/dashboard_view_model.dart';
import 'package:cw_core/crypto_currency.dart';
import 'package:flutter/material.dart';
import 'package:flutter_mobx/flutter_mobx.dart';

import 'asset_tile.dart';

class AssetsSection extends StatelessWidget {
  const AssetsSection({super.key, required this.dashboardViewModel});

  final DashboardViewModel dashboardViewModel;

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(bottom: 64.0),
        child: Observer(builder: (context) {
          final hasMweb = dashboardViewModel.hasMweb && dashboardViewModel.mwebEnabled;
          return Column(
            children: [
              if (dashboardViewModel.balanceViewModel.shouldShowTotalFiatBalance)
                _TotalBalanceHeader(
                    total:
                        dashboardViewModel.balanceViewModel.totalFiatBalance),
              ListView.separated(
            shrinkWrap: true,
            padding: EdgeInsets.symmetric(vertical: 18),
            physics: NeverScrollableScrollPhysics(),
            itemCount:
                dashboardViewModel.balanceViewModel.formattedBalances.length + (hasMweb ? 1 : 0),
            separatorBuilder: (context, index) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 18.0),
              child: Container(
                color: Theme.of(context).colorScheme.surfaceContainer,
                height: 1,
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  child: Container(
                    color: Theme.of(context).colorScheme.surfaceContainerHigh,
                  ),
                ),
              ),
            ),
            itemBuilder: (context, index) {
              return Observer(builder: (context) {
                if (hasMweb) {
                  return AssetTile(
                    showSwap: dashboardViewModel.isEnabledSwapAction,
                    balance: dashboardViewModel.balanceViewModel.formattedBalances.first,
                    showSecondary: index > 0 ? true : false,
                    wallet: dashboardViewModel.wallet,
                    chainIconPath:
                        index > 0 ? dashboardViewModel.wallet.currency.chainIconPath! : "",
                    trailingText: index > 0 ? "MWEB" : null,
                    modalMode: index > 0
                        ? AssetDetailsModalModes.ltcPrivate
                        : AssetDetailsModalModes.ltcTransparent,
                    isFirst: index == 0,
                    isLast: index != 0,
                    title: index > 0 ? "Litecoin Private" : null,
                  );
                }

                final balance =
                    dashboardViewModel.balanceViewModel.formattedBalances.elementAt(index);
                return AssetTile(
                  showSwap: dashboardViewModel.isEnabledSwapAction,
                  showBridgeButton: dashboardViewModel.showBridge(balance.asset),
                  balance: balance,
                  wallet: dashboardViewModel.wallet,
                  isFirst: index == 0,
                  isLast: index == dashboardViewModel.balanceViewModel.formattedBalances.length - 1,
                  chainIconPath: _getChainIconPath(),
                );
              });
            },
          ),
              ],
          );
        }),
      ),
    );
  }

  // TODO refactor chainIconPath to get rid of this ugly thing. it's needed because arbitrum's wallet currency isn't arb
  String _getChainIconPath() {
    try {
      return CryptoCurrency.fromString(
              dashboardViewModel.wallet.currency.tag ?? dashboardViewModel.wallet.currency.title)
          .chainIconPath!;
    } catch (e) {
      return dashboardViewModel.wallet.currency.chainIconPath ?? "";
    }
  }
}

class _TotalBalanceHeader extends StatelessWidget {
  const _TotalBalanceHeader({required this.total});

  final String total;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 18.0, left: 18.0, right: 18.0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 18.0, vertical: 16.0),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primaryContainer,
              Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
            ],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              S.of(context).total,
              style: TextStyle(
                fontSize: 13,
                color: Theme.of(context).colorScheme.onPrimaryContainer.withAlpha(180),
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              total,
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onPrimaryContainer,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
