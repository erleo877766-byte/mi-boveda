import "package:cake_wallet/view_model/settings/regular_list_item.dart";
import "package:url_launcher/url_launcher.dart";

class SupportViewModel {
  SupportViewModel();

  String get docsUrl => "https://github.com/erleo877766-byte/mi-boveda";

  String get contactEmail => "erleo877766@gmail.com";

  String fetchUrl() =>
      "mailto:$contactEmail?subject=Soporte%20Mi%20B%C3%B3veda";

  List<dynamic> get items => [
        RegularListItem(
          title: "Soporte por correo",
          handler: (_) async {
            await launchUrl(
              Uri.parse(
                  "mailto:$contactEmail?subject=Soporte%20Mi%20B%C3%B3veda"),
              mode: LaunchMode.externalApplication,
            );
          },
        ),
      ];
}
