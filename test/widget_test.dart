import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:fsavenotifications/l10n/app_strings.dart';

void main() {
  test('Default language is English if phone locale is not in translated list', () {
    final service = LocaleService();

    // Ranska -> Englanti
    service.initFromDeviceLocale(const Locale('fr', 'FR'));
    expect(service.currentLanguage, AppLanguage.en);

    // Espanja -> Englanti
    service.initFromDeviceLocale(const Locale('es', 'ES'));
    expect(service.currentLanguage, AppLanguage.en);

    // Japani -> Englanti
    service.initFromDeviceLocale(const Locale('ja', 'JP'));
    expect(service.currentLanguage, AppLanguage.en);

    // Käännetyt kielet
    service.initFromDeviceLocale(const Locale('fi', 'FI'));
    expect(service.currentLanguage, AppLanguage.fi);

    service.initFromDeviceLocale(const Locale('sv', 'SE'));
    expect(service.currentLanguage, AppLanguage.sv);

    service.initFromDeviceLocale(const Locale('de', 'DE'));
    expect(service.currentLanguage, AppLanguage.de);

    service.initFromDeviceLocale(const Locale('en', 'US'));
    expect(service.currentLanguage, AppLanguage.en);

    // Tuntematon koodi fallback
    expect(AppLanguage.fromCode('unknown_code'), AppLanguage.en);
  });
}

