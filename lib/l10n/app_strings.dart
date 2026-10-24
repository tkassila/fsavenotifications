import 'package:flutter/material.dart';

enum AppLanguage {
  fi('Suomi', 'fi', '🇫🇮'),
  sv('Svenska', 'sv', '🇸🇪'),
  de('Deutsch', 'de', '🇩🇪'),
  en('English', 'en', '🇬🇧');

  final String name;
  final String code;
  final String flag;

  const AppLanguage(this.name, this.code, this.flag);

  static AppLanguage fromCode(String code) {
    return AppLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => AppLanguage.en,
    );
  }
}

class LocaleService extends ChangeNotifier {
  static final LocaleService _instance = LocaleService._internal();
  factory LocaleService() => _instance;
  LocaleService._internal();

  AppLanguage _currentLanguage = AppLanguage.en;

  AppLanguage get currentLanguage => _currentLanguage;

  void setLanguage(AppLanguage language) {
    if (_currentLanguage != language) {
      _currentLanguage = language;
      notifyListeners();
    }
  }

  /// Tunnistaa laitteen kielen ja valitsee sopivimman (fi, sv, de).
  /// Jos laitteen kieli ei ole käännettyjen joukossa, oletuskieli on englanti (en).
  void initFromDeviceLocale(Locale locale) {
    final langCode = locale.languageCode.toLowerCase();
    if (langCode == 'fi') {
      _currentLanguage = AppLanguage.fi;
    } else if (langCode == 'sv') {
      _currentLanguage = AppLanguage.sv;
    } else if (langCode == 'de') {
      _currentLanguage = AppLanguage.de;
    } else {
      _currentLanguage = AppLanguage.en;
    }
  }

  AppStrings get strings => AppStrings.of(_currentLanguage);
}

class AppStrings {
  final AppLanguage lang;

  const AppStrings(this.lang);

  static AppStrings of(AppLanguage language) => AppStrings(language);

  // --- Yleiset ja päänäkymä ---
  String get appTitle {
    switch (lang) {
      case AppLanguage.sv:
        return 'Sparade aviseringar';
      case AppLanguage.de:
        return 'Gespeicherte Benachrichtigungen';
      case AppLanguage.en:
        return 'Saved Notifications';
      case AppLanguage.fi:
        return 'Tallennetut ilmoitukset';
    }
  }

  String get appSubtitle {
    switch (lang) {
      case AppLanguage.sv:
        return 'Bevaras över omstart';
      case AppLanguage.de:
        return 'Bleiben nach Neustart erhalten';
      case AppLanguage.en:
        return 'Persist across device reboot';
      case AppLanguage.fi:
        return 'Säilyvät uudelleenkäynnistyksen yli';
    }
  }

  String get tabUnread {
    switch (lang) {
      case AppLanguage.sv:
        return 'Olästa';
      case AppLanguage.de:
        return 'Ungelesen';
      case AppLanguage.en:
        return 'Unread';
      case AppLanguage.fi:
        return 'Lukemattomat';
    }
  }

  String get tabHistory {
    switch (lang) {
      case AppLanguage.sv:
        return 'Historik (Lästa)';
      case AppLanguage.de:
        return 'Verlauf (Gelesen)';
      case AppLanguage.en:
        return 'History (Read)';
      case AppLanguage.fi:
        return 'Historia (Luetut)';
    }
  }

  String get searchHint {
    switch (lang) {
      case AppLanguage.sv:
        return 'Sök i aviseringar...';
      case AppLanguage.de:
        return 'Benachrichtigungen durchsuchen...';
      case AppLanguage.en:
        return 'Search notifications...';
      case AppLanguage.fi:
        return 'Hae ilmoituksista...';
    }
  }

  String get tooltipRefresh {
    switch (lang) {
      case AppLanguage.sv:
        return 'Uppdatera lista';
      case AppLanguage.de:
        return 'Liste aktualisieren';
      case AppLanguage.en:
        return 'Refresh list';
      case AppLanguage.fi:
        return 'Päivitä lista';
    }
  }

  String get tooltipMarkAllRead {
    switch (lang) {
      case AppLanguage.sv:
        return 'Markera alla som lästa';
      case AppLanguage.de:
        return 'Alle als gelesen markieren';
      case AppLanguage.en:
        return 'Mark all as read';
      case AppLanguage.fi:
        return 'Merkitse kaikki luetuiksi';
    }
  }

  String get tooltipClearHistory {
    switch (lang) {
      case AppLanguage.sv:
        return 'Rensa historik';
      case AppLanguage.de:
        return 'Verlauf leeren';
      case AppLanguage.en:
        return 'Clear history';
      case AppLanguage.fi:
        return 'Tyhjennä historia';
    }
  }

  String get tooltipGuide {
    switch (lang) {
      case AppLanguage.sv:
        return 'Instruktioner & batteri';
      case AppLanguage.de:
        return 'Anleitung & Akku';
      case AppLanguage.en:
        return 'Instructions & Battery';
      case AppLanguage.fi:
        return 'Käyttö- ja akkuohjeet';
    }
  }

  String get tooltipLanguage {
    switch (lang) {
      case AppLanguage.sv:
        return 'Välj språk';
      case AppLanguage.de:
        return 'Sprache wählen';
      case AppLanguage.en:
        return 'Select Language';
      case AppLanguage.fi:
        return 'Valitse kieli';
    }
  }

  // --- Lupa- ja varoitusbannerit ---
  String get bannerPermissionText {
    switch (lang) {
      case AppLanguage.sv:
        return 'Bakgrundstjänsten kräver Android-behörigheten "Åtkomst till aviseringar" för att spara inkommande meddelanden.\n\n(Om inställningen är nedtonad i Android 13/14: Appinformation -> trepunktsmenyn -> "Tillåt begränsade inställningar")';
      case AppLanguage.de:
        return 'Der Hintergrunddienst benötigt die Berechtigung "Benachrichtigungszugriff", um eingehende Nachrichten zu speichern.\n\n(Falls unter Android 13/14 ausgegraut: App-Info -> Drei-Punkte-Menü -> "Eingeschränkte Einstellungen zulassen")';
      case AppLanguage.en:
        return 'Background service requires "Notification Access" permission to save incoming messages.\n\n(If grayed out on Android 13/14: App info -> 3-dots menu -> "Allow restricted settings")';
      case AppLanguage.fi:
        return 'Taustapalvelu vaatii Androidin "Ilmoitusten käyttöoikeus" -luvan tallentaakseen saapuvat viestit.\n\n(Jos asetus on Android 13/14:ssä harmaana, avaa "Sovelluksen tiedot" -> kolmen pisteen valikko -> "Salli rajoitetut asetukset")';
    }
  }

  String get bannerBtnGuide {
    switch (lang) {
      case AppLanguage.sv:
        return 'OHJEET';
      case AppLanguage.de:
        return 'ANLEITUNG';
      case AppLanguage.en:
        return 'GUIDE';
      case AppLanguage.fi:
        return 'OHJEET';
    }
  }

  String get bannerBtnAppInfo {
    switch (lang) {
      case AppLanguage.sv:
        return 'APPINFO';
      case AppLanguage.de:
        return 'APP-INFO';
      case AppLanguage.en:
        return 'APP INFO';
      case AppLanguage.fi:
        return 'SOVELLUKSEN TIEDOT';
    }
  }

  String get bannerBtnEnable {
    switch (lang) {
      case AppLanguage.sv:
        return 'AKTIVERA';
      case AppLanguage.de:
        return 'AKTIVIEREN';
      case AppLanguage.en:
        return 'ENABLE';
      case AppLanguage.fi:
        return 'OTA KÄYTTÖÖN';
    }
  }

  String bannerHistoryAlert(int count) {
    switch (lang) {
      case AppLanguage.sv:
        return 'Många historikmeddelanden ($count st), vänligen ta bort dem.';
      case AppLanguage.de:
        return 'Viele Verlaufsnachrichten ($count Stk.), bitte löschen Sie diese.';
      case AppLanguage.en:
        return 'Many history messages ($count pcs), please delete them.';
      case AppLanguage.fi:
        return 'Historiaviestejä paljon ($count kpl), ole hyvä ja poista ne.';
    }
  }

  String get bannerHistoryClearBtn {
    switch (lang) {
      case AppLanguage.sv:
        return 'Rensa historik';
      case AppLanguage.de:
        return 'Verlauf leeren';
      case AppLanguage.en:
        return 'Clear history';
      case AppLanguage.fi:
        return 'Tyhjennä historia';
    }
  }

  // --- Tyhjät tilat ---
  String get emptyUnreadTitle {
    switch (lang) {
      case AppLanguage.sv:
        return 'Inga olästa aviseringar';
      case AppLanguage.de:
        return 'Keine ungelesenen Benachrichtigungen';
      case AppLanguage.en:
        return 'No unread notifications';
      case AppLanguage.fi:
        return 'Ei lukemattomia ilmoituksia';
    }
  }

  String get emptyUnreadDesc {
    switch (lang) {
      case AppLanguage.sv:
        return 'Alla inkommande aviseringar sparas här automatiskt i bakgrunden och bevaras över enhetsomstarter.';
      case AppLanguage.de:
        return 'Alle eingehenden Benachrichtigungen werden hier automatisch im Hintergrund gespeichert und bleiben nach einem Geräteneustart erhalten.';
      case AppLanguage.en:
        return 'All incoming notifications are saved here automatically in the background and persist across device reboots.';
      case AppLanguage.fi:
        return 'Kaikki saapuvat ilmoitukset tallentuvat tänne automaattisesti taustalla ja säilyvät laitteen uudelleenkäynnistyksen yli.';
    }
  }

  String get emptyHistoryTitle {
    switch (lang) {
      case AppLanguage.sv:
        return 'Inga historikmeddelanden';
      case AppLanguage.de:
        return 'Keine Verlaufsnachrichten';
      case AppLanguage.en:
        return 'No history messages';
      case AppLanguage.fi:
        return 'Ei historiaviestejä';
    }
  }

  String get emptyHistoryDesc {
    switch (lang) {
      case AppLanguage.sv:
        return 'Lästa aviseringar visas här. Du kan rensa historiken när som helst.';
      case AppLanguage.de:
        return 'Gelesene Benachrichtigungen erscheinen hier. Sie können den Verlauf jederzeit löschen.';
      case AppLanguage.en:
        return 'Read notifications appear here. You can clear the history at any time.';
      case AppLanguage.fi:
        return 'Luetut ilmoitukset näkyvät täällä. Voit tyhjentää historian milloin vain.';
    }
  }

  String get emptySearchTitle {
    switch (lang) {
      case AppLanguage.sv:
        return 'Inga resultat hittades';
      case AppLanguage.de:
        return 'Keine Ergebnisse gefunden';
      case AppLanguage.en:
        return 'No results found';
      case AppLanguage.fi:
        return 'Ei hakutuloksia';
    }
  }

  // --- Painikkeet ja toiminnot ---
  String get markAsRead {
    switch (lang) {
      case AppLanguage.sv:
        return 'Markera som läst';
      case AppLanguage.de:
        return 'Als gelesen markieren';
      case AppLanguage.en:
        return 'Mark as read';
      case AppLanguage.fi:
        return 'Merkitse luetuksi';
    }
  }

  String get delete {
    switch (lang) {
      case AppLanguage.sv:
        return 'Ta bort';
      case AppLanguage.de:
        return 'Löschen';
      case AppLanguage.en:
        return 'Delete';
      case AppLanguage.fi:
        return 'Poista';
    }
  }

  String get close {
    switch (lang) {
      case AppLanguage.sv:
        return 'Stäng';
      case AppLanguage.de:
        return 'Schließen';
      case AppLanguage.en:
        return 'Close';
      case AppLanguage.fi:
        return 'Sulje';
    }
  }

  String get cancel {
    switch (lang) {
      case AppLanguage.sv:
        return 'Avbryt';
      case AppLanguage.de:
        return 'Abbrechen';
      case AppLanguage.en:
        return 'Cancel';
      case AppLanguage.fi:
        return 'Peruuta';
    }
  }

  String get clear {
    switch (lang) {
      case AppLanguage.sv:
        return 'Rensa';
      case AppLanguage.de:
        return 'Leeren';
      case AppLanguage.en:
        return 'Clear';
      case AppLanguage.fi:
        return 'Tyhjennä';
    }
  }

  String get testNotificationsBtn {
    switch (lang) {
      case AppLanguage.sv:
        return 'Testa aviseringar';
      case AppLanguage.de:
        return 'Benachrichtigungen testen';
      case AppLanguage.en:
        return 'Test notifications';
      case AppLanguage.fi:
        return 'Testaa ilmoituksia';
    }
  }

  // --- Vahvistusdialogit ja viestit ---
  String get confirmClearTitle {
    switch (lang) {
      case AppLanguage.sv:
        return 'Rensa historik?';
      case AppLanguage.de:
        return 'Verlauf leeren?';
      case AppLanguage.en:
        return 'Clear history?';
      case AppLanguage.fi:
        return 'Tyhjennetäänkö historia?';
    }
  }

  String get confirmClearDesc {
    switch (lang) {
      case AppLanguage.sv:
        return 'Är du säker på att du vill ta bort alla lästa aviseringar?';
      case AppLanguage.de:
        return 'Möchten Sie wirklich alle gelesenen Benachrichtigungen löschen?';
      case AppLanguage.en:
        return 'Are you sure you want to delete all read notifications?';
      case AppLanguage.fi:
        return 'Haluatko varmasti poistaa kaikki luetut ilmoitukset?';
    }
  }

  String get historyClearedSnack {
    switch (lang) {
      case AppLanguage.sv:
        return 'Historik över lästa aviseringar rensad.';
      case AppLanguage.de:
        return 'Verlauf der gelesenen Benachrichtigungen gelöscht.';
      case AppLanguage.en:
        return 'Read notifications history cleared.';
      case AppLanguage.fi:
        return 'Luettujen ilmoitusten historia tyhjennetty.';
    }
  }

  String markedAllReadSnack(int count) {
    switch (lang) {
      case AppLanguage.sv:
        return '$count aviseringar markerade som lästa.';
      case AppLanguage.de:
        return '$count Benachrichtigungen als gelesen markiert.';
      case AppLanguage.en:
        return '$count notifications marked as read.';
      case AppLanguage.fi:
        return '$count ilmoitusta merkitty luetuiksi.';
    }
  }

  String markedOneReadSnack(String title) {
    switch (lang) {
      case AppLanguage.sv:
        return 'Avisering "$title" markerad som läst.';
      case AppLanguage.de:
        return 'Benachrichtigung "$title" als gelesen markiert.';
      case AppLanguage.en:
        return 'Notification "$title" marked as read.';
      case AppLanguage.fi:
        return 'Ilmoitus "$title" merkitty luetuksi.';
    }
  }

  // --- Yksityiskohtadialogi ---
  String get detailTitle {
    switch (lang) {
      case AppLanguage.sv:
        return 'Aviseringsdetaljer';
      case AppLanguage.de:
        return 'Benachrichtigungsdetails';
      case AppLanguage.en:
        return 'Notification Details';
      case AppLanguage.fi:
        return 'Ilmoituksen tiedot';
    }
  }

  String get detailAppLabel {
    switch (lang) {
      case AppLanguage.sv:
        return 'App';
      case AppLanguage.de:
        return 'App';
      case AppLanguage.en:
        return 'App';
      case AppLanguage.fi:
        return 'Sovellus';
    }
  }

  String get detailPackageLabel {
    switch (lang) {
      case AppLanguage.sv:
        return 'Paketnamn';
      case AppLanguage.de:
        return 'Paketname';
      case AppLanguage.en:
        return 'Package Name';
      case AppLanguage.fi:
        return 'Pakettinimi';
    }
  }

  String get detailReceivedLabel {
    switch (lang) {
      case AppLanguage.sv:
        return 'Mottagen';
      case AppLanguage.de:
        return 'Empfangen';
      case AppLanguage.en:
        return 'Received';
      case AppLanguage.fi:
        return 'Vastaanotettu';
    }
  }

  String get detailReadAtLabel {
    switch (lang) {
      case AppLanguage.sv:
        return 'Läst vid';
      case AppLanguage.de:
        return 'Gelesen am';
      case AppLanguage.en:
        return 'Read at';
      case AppLanguage.fi:
        return 'Luettu';
    }
  }

  String get detailOngoingLabel {
    switch (lang) {
      case AppLanguage.sv:
        return 'Pågående avisering';
      case AppLanguage.de:
        return 'Dauerhafte Benachrichtigung';
      case AppLanguage.en:
        return 'Ongoing notification';
      case AppLanguage.fi:
        return 'Jatkuva ilmoitus';
    }
  }

  String get yes {
    switch (lang) {
      case AppLanguage.sv:
        return 'Ja';
      case AppLanguage.de:
        return 'Ja';
      case AppLanguage.en:
        return 'Yes';
      case AppLanguage.fi:
        return 'Kyllä';
    }
  }

  String get no {
    switch (lang) {
      case AppLanguage.sv:
        return 'Nej';
      case AppLanguage.de:
        return 'Nein';
      case AppLanguage.en:
        return 'No';
      case AppLanguage.fi:
        return 'Ei';
    }
  }

  // --- Testidialogi ---
  String get testDialogTitle {
    switch (lang) {
      case AppLanguage.sv:
        return 'Aviseringsverktyg & tester';
      case AppLanguage.de:
        return 'Benachrichtigungstools & Tests';
      case AppLanguage.en:
        return 'Notification Tools & Tests';
      case AppLanguage.fi:
        return 'Ilmoitustyökalut ja testit';
    }
  }

  String get testSection1Title {
    switch (lang) {
      case AppLanguage.sv:
        return '1. Skicka enskild testavisering:';
      case AppLanguage.de:
        return '1. Einzelne Testbenachrichtigung senden:';
      case AppLanguage.en:
        return '1. Send single test notification:';
      case AppLanguage.fi:
        return '1. Lähetä yksittäinen testi-ilmoitus:';
    }
  }

  String get testFieldTitleLabel {
    switch (lang) {
      case AppLanguage.sv:
        return 'Rubrik';
      case AppLanguage.de:
        return 'Titel';
      case AppLanguage.en:
        return 'Title';
      case AppLanguage.fi:
        return 'Otsikko';
    }
  }

  String get testFieldMessageLabel {
    switch (lang) {
      case AppLanguage.sv:
        return 'Meddelandetext';
      case AppLanguage.de:
        return 'Nachrichtentext';
      case AppLanguage.en:
        return 'Message text';
      case AppLanguage.fi:
        return 'Viestin teksti';
    }
  }

  String get testSendBtn {
    switch (lang) {
      case AppLanguage.sv:
        return 'Skicka testavisering';
      case AppLanguage.de:
        return 'Testbenachrichtigung senden';
      case AppLanguage.en:
        return 'Send test notification';
      case AppLanguage.fi:
        return 'Lähetä testi-ilmoitus';
    }
  }

  String get testSection2Title {
    switch (lang) {
      case AppLanguage.sv:
        return '2. Larmtest för 500 historikmeddelanden:';
      case AppLanguage.de:
        return '2. Alarmtest für 500 Verlaufsnachrichten:';
      case AppLanguage.en:
        return '2. 500 history messages alert test:';
      case AppLanguage.fi:
        return '2. 500 historiaviestin hälytystestaus:';
    }
  }

  String get testSection2Desc {
    switch (lang) {
      case AppLanguage.sv:
        return 'Testa automatiska aviseringen: "Många historikmeddelanden, vänligen ta bort dem".';
      case AppLanguage.de:
        return 'Testen Sie die automatische Benachrichtigung: "Viele Verlaufsnachrichten, bitte löschen Sie diese".';
      case AppLanguage.en:
        return 'Test automatic alert: "Many history messages, please delete them".';
      case AppLanguage.fi:
        return 'Testaa automaattista ilmoitusta: "Historiaviestejä paljon, ole hyvä ja poista ne".';
    }
  }

  String get testTriggerAlertBtn {
    switch (lang) {
      case AppLanguage.sv:
        return 'Utlös 500-varningsavisering';
      case AppLanguage.de:
        return '500er-Warnbenachrichtigung auslösen';
      case AppLanguage.en:
        return 'Trigger 500 alert notification';
      case AppLanguage.fi:
        return 'Laukaise 500-varoitusilmoitus';
    }
  }

  String get testGenerate500Btn {
    switch (lang) {
      case AppLanguage.sv:
        return 'Skapa 500 historikmeddelanden i databasen';
      case AppLanguage.de:
        return '500 Verlaufsnachrichten in Datenbank generieren';
      case AppLanguage.en:
        return 'Generate 500 history messages in DB';
      case AppLanguage.fi:
        return 'Generoi tietokantaan 500 historiaviestiä';
    }
  }

  String get testSection3Title {
    switch (lang) {
      case AppLanguage.sv:
        return '3. Bakgrundsaktivitet och batterispar:';
      case AppLanguage.de:
        return '3. Hintergrundaktivität & Energiesparen:';
      case AppLanguage.en:
        return '3. Background activity & battery saving:';
      case AppLanguage.fi:
        return '3. Taustatoiminta ja akun säästö:';
    }
  }

  String get testDisableBatteryOptBtn {
    switch (lang) {
      case AppLanguage.sv:
        return 'Inaktivera batterioptimering';
      case AppLanguage.de:
        return 'Akku-Optimierung deaktivieren';
      case AppLanguage.en:
        return 'Disable battery optimization';
      case AppLanguage.fi:
        return 'Poista akun optimointi käytöstä';
    }
  }

  String get testOpenGuideBtn {
    switch (lang) {
      case AppLanguage.sv:
        return 'Läs batteri- och tillverkarinstruktioner';
      case AppLanguage.de:
        return 'Akku- & Herstelleranleitung lesen';
      case AppLanguage.en:
        return 'Read battery & vendor instructions';
      case AppLanguage.fi:
        return 'Lue akku- ja valmistajaohjeet';
    }
  }

  // --- Akku- ja käyttöohje (3 osiota) ---
  String get guideDialogTitle {
    switch (lang) {
      case AppLanguage.sv:
        return 'Användarmanual & bakgrundsanvändning';
      case AppLanguage.de:
        return 'Bedienungsanleitung & Hintergrundnutzung';
      case AppLanguage.en:
        return 'User Guide & Background Settings';
      case AppLanguage.fi:
        return 'Käyttöohje ja tausta-asetukset';
    }
  }

  String get guideSec1Title {
    switch (lang) {
      case AppLanguage.sv:
        return '1. Före användning (Idrifttagning):';
      case AppLanguage.de:
        return '1. Vor der Verwendung (Einrichtung):';
      case AppLanguage.en:
        return '1. Before use (Setup):';
      case AppLanguage.fi:
        return '1. Ennen käyttöä (Käyttöönotto):';
    }
  }

  String get guideSec1Content {
    switch (lang) {
      case AppLanguage.sv:
        return '• Åtkomst till aviseringar:\n'
            'Appen kräver behörigheten "Åtkomst till aviseringar" för att fungera. Utan detta kan bakgrundstjänsten inte upptäcka eller spara aviseringar som kommer till telefonen.\n\n'
            '• Android 13 och 14 (alla märken):\n'
            'Om appen installeras från en APK-fil: Appinformation -> trepunktsmenyn i övre högra hörnet (⋮) -> Tillåt begränsade inställningar, innan åtkomst till aviseringar aktiveras.\n\n'
            '• Inaktivera batterioptimering:\n'
            'Ställ in batterioptimeringen på "Inga begränsningar" så att Android-systemet inte fryser eller stoppar aviseringstjänsten när skärmen är avstängd.';
      case AppLanguage.de:
        return '• Benachrichtigungszugriff:\n'
            'Die App benötigt die Berechtigung "Benachrichtigungszugriff", um zu funktionieren. Ohne diese Berechtigung kann der Hintergrunddienst eingehende Benachrichtigungen nicht erfassen oder speichern.\n\n'
            '• Android 13 und 14 (alle Marken):\n'
            'Wenn die App über eine APK-Datei installiert wird: App-Info -> Drei-Punkte-Menü oben rechts (⋮) -> Eingeschränkte Einstellungen zulassen, bevor der Benachrichtigungszugriff aktiviert wird.\n\n'
            '• Akku-Optimierung deaktivieren:\n'
            'Stellen Sie die Akku-Optimierung auf "Keine Einschränkungen", damit das Android-System den Benachrichtigungsdienst bei ausgeschaltetem Bildschirm nicht einfriert oder beendet.';
      case AppLanguage.en:
        return '• Notification Access:\n'
            'The app requires "Notification Access" permission to function. Without this permission, the background service cannot detect or save incoming notifications.\n\n'
            '• Android 13 and 14 (all brands):\n'
            'If the app is installed from an APK file: App info -> 3-dots menu in top-right corner (⋮) -> Allow restricted settings, before enabling Notification Access.\n\n'
            '• Disable Battery Optimization:\n'
            'Set battery optimization to "Unrestricted" so that Android does not freeze or kill the notification service when the screen is locked.';
      case AppLanguage.fi:
        return '• Ilmoitusten lukuoikeus:\n'
            'Sovellus vaatii toimiakseen Androidin "Ilmoitusten käyttöoikeus" -luvan. Ilman tätä lupaa taustapalvelu ei voi havaita eikä tallentaa puhelimeen saapuvia ilmoituksia.\n\n'
            '• Android 13 ja 14 (kaikki merkit):\n'
            'Jos sovellus asennetaan APK-tiedostosta: Sovelluksen tiedot -> oikeasta yläkulmasta kolme pistettä (⋮) -> Salli rajoitetut asetukset, ennen kuin ilmoitusten käyttöoikeus kytketään päälle.\n\n'
            '• Akun optimoinnin poisto:\n'
            'Ota akun optimointi pois päältä ("Ei rajoituksia"), jotta Android-järjestelmä ei jäädytä tai sammuta ilmoituspalvelua näytön ollessa sammutettuna.';
    }
  }

  String get guideSec2Title {
    switch (lang) {
      case AppLanguage.sv:
        return '2. Under och efter användning:';
      case AppLanguage.de:
        return '2. Während und nach der Nutzung:';
      case AppLanguage.en:
        return '2. During and after use:';
      case AppLanguage.fi:
        return '2. Käytön aikana ja jälkeen:';
    }
  }

  String get guideSec2Content {
    switch (lang) {
      case AppLanguage.sv:
        return '• Bakgrundssparande:\n'
            'Alla inkommande aviseringar sparas i enhetens lokala SQLite-databas i bakgrunden och bevaras även efter att telefonen har startats om.\n\n'
            '• Olästa meddelanden:\n'
            'Olästa meddelanden försvinner från huvudvyn omedelbart när de markeras som lästa eller öppnas.\n\n'
            '• 500 meddelandens rensningsvarning:\n'
            'När 500 eller fler meddelanden ackumuleras i historiken skickar appen en prioriterad avisering: "Många historikmeddelanden, vänligen ta bort dem" och erbjuder en direktlänk till historiken för rensning.';
      case AppLanguage.de:
        return '• Hintergrundspeicherung:\n'
            'Alle eingehenden Benachrichtigungen werden im Hintergrund in der lokalen SQLite-Datenbank des Geräts gespeichert und bleiben auch nach einem Neustart erhalten.\n\n'
            '• Ungelesene Nachrichten:\n'
            'Ungelesene Nachrichten verschwinden sofort aus der Hauptansicht, sobald sie als gelesen markiert oder geöffnet werden.\n\n'
            '• 500-Nachrichten-Bereinigungswarnung:\n'
            'Wenn 500 oder mehr Nachrichten im Verlauf gesammelt wurden, sendet die App eine Benachrichtigung mit hoher Priorität: "Viele Verlaufsnachrichten, bitte löschen Sie diese" und bietet einen direkten Link zum Verlauf.';
      case AppLanguage.en:
        return '• Background Storage:\n'
            'All incoming notifications are saved to the device local SQLite database in the background and persist even after rebooting the phone.\n\n'
            '• Unread Messages:\n'
            'Unread messages are removed from the main view immediately once marked as read or opened.\n\n'
            '• 500 Messages Cleanup Alert:\n'
            'When 500 or more messages accumulate in history, the app sends a high-priority notification: "Many history messages, please delete them" and provides a direct link to clear history.';
      case AppLanguage.fi:
        return '• Taustatallennus:\n'
            'Kaikki saapuvat ilmoitukset tallentuvat laitteen paikalliseen SQLite-tietokantaan taustalla ja säilyvät myös puhelimen uudelleenkäynnistyksen jälkeen.\n\n'
            '• Lukemattomat viestit:\n'
            'Lukemattomat viestit poistuvat päänäkymästä heti, kun ne merkitään luetuiksi tai avataan.\n\n'
            '• 500 viestin siivousvaroitus:\n'
            'Kun historiaan kertyy 500 tai enemmän viestiä, sovellus lähettää korkean prioriteetin ilmoituksen: "Historiaviestejä paljon, ole hyvä ja poista ne" ja tarjoaa suoran linkin historiaan viestien tyhjentämiseksi.';
    }
  }

  String get guideSecImportTitle {
    switch (lang) {
      case AppLanguage.sv:
        return '3. Hämta befintliga aviseringar & uppdateringar:';
      case AppLanguage.de:
        return '3. Vorhandene Benachrichtigungen abrufen & Updates:';
      case AppLanguage.en:
        return '3. Fetching existing notifications & app updates:';
      case AppLanguage.fi:
        return '3. Olemassa olevien ilmoitusten haku ja päivitykset:';
    }
  }

  String get guideSecImportContent {
    switch (lang) {
      case AppLanguage.sv:
        return '• Hämta aviseringar från statusfältet:\n'
            'Du kan när som helst trycka på nedladdningsikonen i övre fältet eller välja "Hämta aktiva aviseringar från enheten" i verktygsdialogen. Appen hämtar alla aviseringar som finns aktiva i telefonens aviseringsfält och lägger till dem som olästa.\n\n'
            '• Automatiskt skydd mot dubbletter:\n'
            'Appen kontrollerar varje avisering mot databasen. Redan sparade meddelanden (olästa eller i historiken) hoppas över automatiskt och dupliceras aldrig.\n\n'
            '• Uppdateringar och omstarter:\n'
            'När appen uppdateras via .apk eller Google Play Store, eller när telefonen startas om, förblir alla behörigheter och meddelanden i SQLite-databasen sparade. Tjänsten återansluter automatiskt när appen öppnas.';
      case AppLanguage.de:
        return '• Benachrichtigungen aus der Statusleiste importieren:\n'
            'Sie können jederzeit auf das Download-Symbol in der oberen Leiste oder im Werkzeugmenü auf "Aktive Gerätebenachrichtigungen abrufen" tippen. Die App liest alle aktuell in der Statusleiste aktiven Benachrichtigungen aus und fügt neue zum Posteingang hinzu.\n\n'
            '• Automatische Duplikatsvermeidung:\n'
            'Die App gleicht jede Benachrichtigung mit der Datenbank ab. Bereits gespeicherte Nachrichten (ungelesen oder im Verlauf) werden automatisch übersprungen und niemals doppelt gespeichert.\n\n'
            '• Updates und Geräteneustarts:\n'
            'Beim Aktualisieren der App (.apk oder Play Store) sowie nach einem Neustart des Smartphones bleiben alle Berechtigungen und Datenbankeinträge vollständig erhalten. Der Hintergrunddienst wird beim Öffnen der App automatisch wieder verbunden.';
      case AppLanguage.en:
        return '• Import notifications from status bar:\n'
            'You can tap the download icon in the top app bar or choose "Import active notifications from device" in the tools menu at any time. The app reads all notifications currently sitting in the device notification shade and imports new ones.\n\n'
            '• Automatic duplicate prevention:\n'
            'The app checks each notification against the local database. Any notification that has already been saved (whether unread or in history) is automatically skipped and never duplicated.\n\n'
            '• Updates and device reboots:\n'
            'When updating the app via .apk or Google Play Store, or after rebooting the phone, all permissions and saved SQLite records are preserved. The background service automatically reconnects as soon as the app is opened.';
      case AppLanguage.fi:
        return '• Ilmoitusten tuonti ilmoituspalkista:\n'
            'Voit milloin vain painaa yläpalkin latauskuvaketta tai työkalujen "Hae laitteen aktiiviset ilmoitukset" -painiketta. Sovellus lukee kaikki puhelimen ilmoitusvalikossa sillä hetkellä odottavat ilmoitukset ja lisää uudet lukemattomiin.\n\n'
            '• Automaattinen duplikaattien esto:\n'
            'Sovellus tarkistaa jokaisen ilmoituksen uniikin avaimen, pakettitunnuksen ja sisällön tietokannasta. Jo aiemmin tallennetut viestit (sekä lukemattomat että luetut historiaviestit) ohitetaan automaattisesti, joten samoja viestejä ei koskaan tallenneta kahta kertaa.\n\n'
            '• Päivitykset ja uudelleenkäynnistys:\n'
            'Kun sovellus päivitetään .apk-tiedostolla tai Play Kaupasta, tai kun puhelin käynnistetään uudelleen, kaikki aiemmin myönnetyt oikeudet ja SQLite-tietokanta säilyvät ennallaan. Taustapalvelu kytkeytyy automaattisesti takaisin päälle sovelluksen käynnistyessä.';
    }
  }

  String get guideSec3Title {
    switch (lang) {
      case AppLanguage.sv:
        return '4. Enhetsspecifika inställningar i telefonen (Viktigt!):';
      case AppLanguage.de:
        return '4. Gerätespezifische Einstellungen auf dem Smartphone (Wichtig!):';
      case AppLanguage.en:
        return '4. Manufacturer-specific device settings (Important!):';
      case AppLanguage.fi:
        return '4. Laitevalmistajakohtaiset asetukset puhelimessa (Tärkeää!):';
    }
  }

  String get guideSec3Content {
    switch (lang) {
      case AppLanguage.sv:
        return 'Olika Android-tillverkare har egna aggressiva batteriövervakare som kan stänga av bakgrundstjänster när telefonen är i viloläge. Kontrollera dessa beroende på telefonmodell:\n\n'
            'Samsung (One UI):\n'
            'Inställningar -> Batteri -> Bakgrundsgränser -> Lägg aldrig i viloläge -> Lägg till fsavenotifications.\n\n'
            'Xiaomi / Redmi / POCO (MIUI / HyperOS):\n'
            'Appinformation -> Autostart -> Slå på.\n'
            'Appinformation -> Batterisparare -> Välj Inga begränsningar.\n\n'
            'OnePlus / Oppo / Realme (OxygenOS / ColorOS):\n'
            'Appinformation -> Batterianvändning -> Tillåt bakgrundsaktivitet.\n\n'
            'Android 13 och 14 (alla märken):\n'
            'Om appen installeras från en APK-fil: Appinformation -> trepunktsmenyn uppe till höger (⋮) -> Tillåt begränsade inställningar, innan åtkomst till aviseringar aktiveras.';
      case AppLanguage.de:
        return 'Verschiedene Android-Hersteller verwenden aggressive Energieverwaltungs-Tools, die Hintergrunddienste beenden können, wenn das Smartphone im Ruhezustand ist. Überprüfen Sie Folgendes je nach Modell:\n\n'
            'Samsung (One UI):\n'
            'Einstellungen -> Akku -> Grenzen der Hintergrundnutzung -> Apps nie im Standby -> fsavenotifications hinzufügen.\n\n'
            'Xiaomi / Redmi / POCO (MIUI / HyperOS):\n'
            'App-Info -> Autostart -> Einschalten.\n'
            'App-Info -> Energiesparen -> Keine Einschränkungen wählen.\n\n'
            'OnePlus / Oppo / Realme (OxygenOS / ColorOS):\n'
            'App-Info -> Akkunutzung -> Hintergrundaktivität zulassen.\n\n'
            'Android 13 und 14 (alle Marken):\n'
            'Wenn die App über eine APK-Datei installiert wird: App-Info -> Drei-Punkte-Menü oben rechts (⋮) -> Eingeschränkte Einstellungen zulassen, bevor der Benachrichtigungszugriff aktiviert wird.';
      case AppLanguage.en:
        return 'Different Android manufacturers have aggressive battery optimization policies that can kill background services when the phone is idle. Check these depending on your phone model:\n\n'
            'Samsung (One UI):\n'
            'Settings -> Battery -> Background usage limits -> Never sleeping apps -> Add fsavenotifications.\n\n'
            'Xiaomi / Redmi / POCO (MIUI / HyperOS):\n'
            'App info -> Autostart -> Turn on.\n'
            'App info -> Battery saver -> Select No restrictions.\n\n'
            'OnePlus / Oppo / Realme (OxygenOS / ColorOS):\n'
            'App info -> Battery usage -> Allow background activity.\n\n'
            'Android 13 and 14 (all brands):\n'
            'If the app is installed from an APK file: App info -> 3-dots menu in top-right corner (⋮) -> Allow restricted settings, before enabling Notification Access.';
      case AppLanguage.fi:
        return 'Eri Android-valmistajilla on omat "tehovalvojat", jotka saattavat sammuttaa taustapalveluita, jos puhelin on pitkään lepotilassa. Tarkista nämä puhelinmallistasi riippuen:\n\n'
            'Samsung (One UI):\n'
            'Asetukset -> Akku -> Taustakäytön rajat -> Älä koskaan aseta lepotilaan -> Lisää fsavenotifications.\n\n'
            'Xiaomi / Redmi / POCO (MIUI / HyperOS):\n'
            'Sovelluksen tiedot -> Automaattikäynnistys (Autostart) -> Laita päälle.\n'
            'Sovelluksen tiedot -> Akunsäästäjä -> Valitse Ei rajoituksia.\n\n'
            'OnePlus / Oppo / Realme (OxygenOS / ColorOS):\n'
            'Sovelluksen tiedot -> Akun käyttö -> Salli taustatoiminta.\n\n'
            'Android 13 ja 14 (kaikki merkit):\n'
            'Jos sovellus asennetaan APK-tiedostosta: Sovelluksen tiedot -> oikeasta yläkulmasta kolme pistettä (⋮) -> Salli rajoitetut asetukset, ennen kuin ilmoitusten käyttöoikeus kytketään päälle.';
    }
  }

  String get guideQuickSettingsTitle {
    switch (lang) {
      case AppLanguage.sv:
        return 'Snabbinställningar:';
      case AppLanguage.de:
        return 'Schnelleinstellungen:';
      case AppLanguage.en:
        return 'Quick settings:';
      case AppLanguage.fi:
        return 'Pika-asetukset:';
    }
  }

  String get guideBtnAppInfo {
    switch (lang) {
      case AppLanguage.sv:
        return 'Öppna appinformation';
      case AppLanguage.de:
        return 'App-Info öffnen';
      case AppLanguage.en:
        return 'Open app info';
      case AppLanguage.fi:
        return 'Avaa sovelluksen tiedot';
    }
  }

  String get guideBtnDisableOpt {
    switch (lang) {
      case AppLanguage.sv:
        return 'Inaktivera batterioptimering';
      case AppLanguage.de:
        return 'Akku-Optimierung deaktivieren';
      case AppLanguage.en:
        return 'Disable battery optimization';
      case AppLanguage.fi:
        return 'Poista akun optimointi käytöstä';
    }
  }

  String get guideBtnNotificationAccess {
    switch (lang) {
      case AppLanguage.sv:
        return 'Öppna aviseringsbehörighet';
      case AppLanguage.de:
        return 'Benachrichtigungszugriff öffnen';
      case AppLanguage.en:
        return 'Open Notification Access settings';
      case AppLanguage.fi:
        return 'Avaa ilmoitusoikeuksien asetukset';
    }
  }

  String get badgeNew {
    switch (lang) {
      case AppLanguage.sv:
        return 'Ny';
      case AppLanguage.de:
        return 'Neu';
      case AppLanguage.en:
        return 'New';
      case AppLanguage.fi:
        return 'Uusi';
    }
  }

  String get badgeRead {
    switch (lang) {
      case AppLanguage.sv:
        return 'Läst';
      case AppLanguage.de:
        return 'Gelesen';
      case AppLanguage.en:
        return 'Read';
      case AppLanguage.fi:
        return 'Luettu';
    }
  }

  String get noTextContent {
    switch (lang) {
      case AppLanguage.sv:
        return '(Inget textinnehåll)';
      case AppLanguage.de:
        return '(Kein Textinhalt)';
      case AppLanguage.en:
        return '(No text content)';
      case AppLanguage.fi:
        return '(Ei tekstisisältöä)';
    }
  }

  String arrivalTime(String time) {
    switch (lang) {
      case AppLanguage.sv:
        return 'Ankomsttid: $time';
      case AppLanguage.de:
        return 'Eingangszeit: $time';
      case AppLanguage.en:
        return 'Received: $time';
      case AppLanguage.fi:
        return 'Saapumisaika: $time';
    }
  }

  String formatYesterday(String time) {
    switch (lang) {
      case AppLanguage.sv:
        return 'Igår $time';
      case AppLanguage.de:
        return 'Gestern $time';
      case AppLanguage.en:
        return 'Yesterday $time';
      case AppLanguage.fi:
        return 'Eilen $time';
    }
  }

  String get testDefaultTitle {
    switch (lang) {
      case AppLanguage.sv:
        return 'Viktigt meddelande';
      case AppLanguage.de:
        return 'Wichtige Nachricht';
      case AppLanguage.en:
        return 'Important message';
      case AppLanguage.fi:
        return 'Tärkeä viesti';
    }
  }

  String get testDefaultMessage {
    switch (lang) {
      case AppLanguage.sv:
        return 'Detta meddelande sparas i bakgrunden och bevaras även efter att telefonen startats om!';
      case AppLanguage.de:
        return 'Diese Nachricht wird im Hintergrund gespeichert und bleibt auch nach einem Neustart erhalten!';
      case AppLanguage.en:
        return 'This message is saved in the background and persists even after rebooting the phone!';
      case AppLanguage.fi:
        return 'Tämä viesti tallentuu taustalla ja säilyy myös puhelimen uudelleenkäynnistyksen jälkeen!';
    }
  }

  String get testAlertSentSnack {
    switch (lang) {
      case AppLanguage.sv:
        return 'Varningsavisering skickad till Androids aviseringsmeny!';
      case AppLanguage.de:
        return 'Warnbenachrichtigung an Android-Benachrichtigungsleiste gesendet!';
      case AppLanguage.en:
        return 'Alert notification sent to Android notification shade!';
      case AppLanguage.fi:
        return 'Varoitusilmoitus lähetetty Androidin ilmoitusvalikkoon!';
    }
  }

  String testBatchAddedSnack(int count) {
    switch (lang) {
      case AppLanguage.sv:
        return 'Lade till $count historikmeddelanden! Varningsavisering utlöst.';
      case AppLanguage.de:
        return '$count Verlaufsnachrichten hinzugefügt! Warnung ausgelöst.';
      case AppLanguage.en:
        return 'Added $count history messages! Alert notification triggered.';
      case AppLanguage.fi:
        return 'Lisätty $count historiaviestiä! Varoitusilmoitus laukaistiin.';
    }
  }

  // --- Aktiivisten ilmoitusten haku ---
  String get tooltipImportActive {
    switch (lang) {
      case AppLanguage.sv:
        return 'Hämta telefonens aktiva aviseringar';
      case AppLanguage.de:
        return 'Aktive Telefonbenachrichtigungen abrufen';
      case AppLanguage.en:
        return 'Import active phone notifications';
      case AppLanguage.fi:
        return 'Hae puhelimen aktiiviset ilmoitukset';
    }
  }

  String get importSectionTitle {
    switch (lang) {
      case AppLanguage.sv:
        return 'Hämta befintliga aviseringar:';
      case AppLanguage.de:
        return 'Bestehende Benachrichtigungen abrufen:';
      case AppLanguage.en:
        return 'Import existing notifications:';
      case AppLanguage.fi:
        return 'Hae laitteen olemassa olevat ilmoitukset:';
    }
  }

  String get importSectionDesc {
    switch (lang) {
      case AppLanguage.sv:
        return 'Hämtar aviseringar som för närvarande finns i statusfältet. Redan sparade meddelanden hoppas över automatiskt.';
      case AppLanguage.de:
        return 'Ruft aktuell in der Statusleiste vorhandene Benachrichtigungen ab. Bereits gespeicherte Nachrichten werden automatisch übersprungen.';
      case AppLanguage.en:
        return 'Fetches notifications currently active in the status bar. Previously saved messages are automatically skipped.';
      case AppLanguage.fi:
        return 'Hakee puhelimen ilmoituspalkissa tällä hetkellä olevat ilmoitukset. Jo aiemmin tallennetut viestit ohitetaan automaattisesti.';
    }
  }

  String get importActiveBtn {
    switch (lang) {
      case AppLanguage.sv:
        return 'Hämta aktiva aviseringar från enheten';
      case AppLanguage.de:
        return 'Aktive Gerätebenachrichtigungen abrufen';
      case AppLanguage.en:
        return 'Import active notifications from device';
      case AppLanguage.fi:
        return 'Hae laitteen aktiiviset ilmoitukset';
    }
  }

  String importResultSuccess(int imported, int skipped) {
    switch (lang) {
      case AppLanguage.sv:
        return 'Hämtade $imported nya aviseringar ($skipped fanns redan sparade).';
      case AppLanguage.de:
        return '$imported neue Benachrichtigung(en) importiert ($skipped bereits gespeichert).';
      case AppLanguage.en:
        return 'Imported $imported new notification(s) ($skipped already saved).';
      case AppLanguage.fi:
        return 'Tuotu $imported uutta ilmoitusta ($skipped oli jo ennestään tallennettu).';
    }
  }

  String importResultAllAlreadySaved(int total) {
    switch (lang) {
      case AppLanguage.sv:
        return 'Inga nya aviseringar att hämta. Alla $total enhetsaviseringar är redan sparade.';
      case AppLanguage.de:
        return 'Keine neuen Benachrichtigungen zum Importieren. Alle $total Benachrichtigungen sind bereits gespeichert.';
      case AppLanguage.en:
        return 'No new notifications to import. All $total notifications are already saved.';
      case AppLanguage.fi:
        return 'Ei uusia ilmoituksia tuotavaksi. Kaikki laitteen $total ilmoitusta on jo ennestään tallennettu.';
    }
  }

  String get importResultNoneFound {
    switch (lang) {
      case AppLanguage.sv:
        return 'Inga aktiva aviseringar hittades i enhetens statusfält.';
      case AppLanguage.de:
        return 'Keine aktiven Benachrichtigungen in der Statusleiste gefunden.';
      case AppLanguage.en:
        return 'No active notifications found in the device status bar.';
      case AppLanguage.fi:
        return 'Laitteen ilmoituspalkissa ei ole yhtään aktiivista ilmoitusta.';
    }
  }

  String get importResultNoPermission {
    switch (lang) {
      case AppLanguage.sv:
        return 'Aviseringsbehörighet krävs för att hämta aviseringar.';
      case AppLanguage.de:
        return 'Benachrichtigungszugriff ist erforderlich, um Benachrichtigungen abzurufen.';
      case AppLanguage.en:
        return 'Notification access permission is required to import notifications.';
      case AppLanguage.fi:
        return 'Ilmoitusten lukuoikeus vaaditaan ilmoitusten hakemiseen.';
    }
  }

  String get importResultServiceConnecting {
    switch (lang) {
      case AppLanguage.sv:
        return 'Kunde inte ansluta till aviseringstjänsten. Klicka på Aktivera för att slå av och på behörigheten i inställningarna.';
      case AppLanguage.de:
        return 'Verbindung zum Benachrichtigungsdienst fehlgeschlagen. Tippen Sie auf Aktivieren, um den Zugriff in den Einstellungen neu zu starten.';
      case AppLanguage.en:
        return 'Could not connect to notification service. Tap Enable to toggle notification access off and on in settings.';
      case AppLanguage.fi:
        return 'Ilmoituspalveluun ei saatu yhteyttä. Paina "Ota käyttöön" ja kytke oikeus kerran pois ja takaisin päälle asetuksista.';
    }
  }

  String get openApp {
    switch (lang) {
      case AppLanguage.sv:
        return 'Öppna app';
      case AppLanguage.de:
        return 'App öffnen';
      case AppLanguage.en:
        return 'Open app';
      case AppLanguage.fi:
        return 'Avaa sovellus';
    }
  }

  String get openNotification {
    switch (lang) {
      case AppLanguage.sv:
        return 'Öppna avisering';
      case AppLanguage.de:
        return 'Benachrichtigung öffnen';
      case AppLanguage.en:
        return 'Open notification';
      case AppLanguage.fi:
        return 'Avaa ilmoitus';
    }
  }

  String get tooltipOpenApp {
    switch (lang) {
      case AppLanguage.sv:
        return 'Öppna i app';
      case AppLanguage.de:
        return 'In App öffnen';
      case AppLanguage.en:
        return 'Open in app';
      case AppLanguage.fi:
        return 'Avaa sovelluksessa';
    }
  }

  String get linksInNotification {
    switch (lang) {
      case AppLanguage.sv:
        return 'Länkar i meddelandet';
      case AppLanguage.de:
        return 'Links in der Nachricht';
      case AppLanguage.en:
        return 'Links in message';
      case AppLanguage.fi:
        return 'Linkit viestissä';
    }
  }

  String get appNotInstalled {
    switch (lang) {
      case AppLanguage.sv:
        return 'Appen är inte tillgänglig på enheten';
      case AppLanguage.de:
        return 'Die App ist auf dem Gerät nicht verfügbar';
      case AppLanguage.en:
        return 'App is not available on this device';
      case AppLanguage.fi:
        return 'Sovellusta ei löydy laitteesta';
    }
  }

  String get openUrlError {
    switch (lang) {
      case AppLanguage.sv:
        return 'Kunde inte öppna länken';
      case AppLanguage.de:
        return 'Link konnte nicht geöffnet werden';
      case AppLanguage.en:
        return 'Failed to open link';
      case AppLanguage.fi:
        return 'Linkin avaaminen epäonnistui';
    }
  }
}

