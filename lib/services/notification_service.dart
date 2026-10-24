import 'dart:async';
import 'package:flutter/services.dart';
import '../models/saved_notification.dart';

class NotificationService {
  static const MethodChannel _channel =
      MethodChannel('com.metait.fsavenotifications/channel');

  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;

  final StreamController<void> _newNotificationStreamController =
      StreamController<void>.broadcast();

  final StreamController<String> _openTabStreamController =
      StreamController<String>.broadcast();

  Stream<void> get onNewNotification =>
      _newNotificationStreamController.stream;

  Stream<String> get onOpenTab => _openTabStreamController.stream;

  NotificationService._internal() {
    _channel.setMethodCallHandler(_handleMethodCall);
  }

  Future<dynamic> _handleMethodCall(MethodCall call) async {
    if (call.method == 'onNewNotification') {
      _newNotificationStreamController.add(null);
    } else if (call.method == 'openTab') {
      final tab = (call.arguments as Map?)?['tab'] as String?;
      if (tab != null) {
        _openTabStreamController.add(tab);
      }
    }
  }

  /// Hakee käynnistysintentistä mahdollisen avattavan välilehden (esim. 'history')
  Future<String?> getInitialTab() async {
    try {
      final String? tab = await _channel.invokeMethod('getInitialTab');
      return tab;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe haettaessa käynnistysvälilehteä: ${e.message}');
      return null;
    }
  }

  /// Hakee kaikki lukemattomat ilmoitukset SQLite-tietokannasta
  Future<List<SavedNotification>> getUnreadNotifications() async {
    try {
      final List<dynamic>? rawList =
          await _channel.invokeMethod('getUnreadNotifications');
      if (rawList == null) return [];
      return rawList
          .map((item) => SavedNotification.fromMap(item as Map))
          .toList();
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe haettaessa lukemattomia ilmoituksia: ${e.message}');
      return [];
    }
  }

  /// Hakee kaikki ilmoitukset (sekä lukemattomat että luetut historia)
  Future<List<SavedNotification>> getAllNotifications() async {
    try {
      final List<dynamic>? rawList =
          await _channel.invokeMethod('getAllNotifications');
      if (rawList == null) return [];
      return rawList
          .map((item) => SavedNotification.fromMap(item as Map))
          .toList();
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe haettaessa kaikkia ilmoituksia: ${e.message}');
      return [];
    }
  }

  /// Merkitsee yksittäisen ilmoituksen luetuksi, jolloin se poistuu heti lukemattomien listalta
  Future<bool> markAsRead(int id) async {
    try {
      final bool? success =
          await _channel.invokeMethod('markAsRead', {'id': id});
      return success ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe merkittäessä luetuksi: ${e.message}');
      return false;
    }
  }

  /// Merkitsee kaikki ilmoitukset kerralla luetuiksi
  Future<int> markAllAsRead() async {
    try {
      final int? count = await _channel.invokeMethod('markAllAsRead');
      return count ?? 0;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe merkittäessä kaikkia luetuiksi: ${e.message}');
      return 0;
    }
  }

  /// Poistaa ilmoituksen pysyvästi tietokannasta
  Future<bool> deleteNotification(int id) async {
    try {
      final bool? success =
          await _channel.invokeMethod('deleteNotification', {'id': id});
      return success ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe poistettaessa ilmoitusta: ${e.message}');
      return false;
    }
  }

  /// Tyhjentää koko tietokannan
  Future<int> clearAll() async {
    try {
      final int? count = await _channel.invokeMethod('clearAll');
      return count ?? 0;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe tyhjennettäessä ilmoituksia: ${e.message}');
      return 0;
    }
  }

  /// Tyhjentää vain luetut ilmoitukset historiasta
  Future<int> clearRead() async {
    try {
      final int? count = await _channel.invokeMethod('clearRead');
      return count ?? 0;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe tyhjennettäessä luettuja ilmoituksia: ${e.message}');
      return 0;
    }
  }

  /// Tarkistaa, onko käyttäjä sallinut ilmoitusten kuuntelun Android-asetuksissa
  Future<bool> isNotificationAccessGranted() async {
    try {
      final bool? granted =
          await _channel.invokeMethod('isNotificationAccessGranted');
      return granted ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe käyttöoikeuden tarkistuksessa: ${e.message}');
      return false;
    }
  }

  /// Avaa Androidin "Ilmoitusten käyttöoikeus" -asetussivun
  Future<void> openNotificationAccessSettings() async {
    try {
      await _channel.invokeMethod('openNotificationAccessSettings');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe avattaessa asetuksia: ${e.message}');
    }
  }

  /// Avaa sovelluksen omat tiedot -sivun (Android 13+ rajoitettujen asetusten sallimiseen)
  Future<void> openAppSettings() async {
    try {
      await _channel.invokeMethod('openAppSettings');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe avattaessa sovellusasetuksia: ${e.message}');
    }
  }

  /// Tarkistaa, onko sovellukselta poistettu akun optimointi (saa toimia vapaasti taustalla)
  Future<bool> isIgnoringBatteryOptimizations() async {
    try {
      final bool? result =
          await _channel.invokeMethod('isIgnoringBatteryOptimizations');
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe akkuoptimoinnin tarkistuksessa: ${e.message}');
      return false;
    }
  }

  /// Avaa suoran järjestelmädialogin akun optimoinnin poistamiseksi
  Future<bool> requestIgnoreBatteryOptimizations() async {
    try {
      final bool? result =
          await _channel.invokeMethod('requestIgnoreBatteryOptimizations');
      return result ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe pyydettäessä akkuoptimoinnin poistoa: ${e.message}');
      return false;
    }
  }

  /// Pyytää ilmoitusluvan (POST_NOTIFICATIONS) Android 13+ -laitteissa
  Future<void> requestNotificationPermission() async {
    try {
      await _channel.invokeMethod('requestNotificationPermission');
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe pyydettäessä ilmoituslupaa: ${e.message}');
    }
  }

  /// Lähettää testi-ilmoituksen, jonka taustapalvelu nappaa ja tallettaa
  Future<bool> sendTestNotification({
    String title = 'Testiviesti',
    String message = 'Tämä viesti tallentuu automaattisesti taustalla.',
  }) async {
    try {
      final bool? success = await _channel.invokeMethod('sendTestNotification', {
        'title': title,
        'message': message,
      });
      return success ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe lähetettäessä testi-ilmoitusta: ${e.message}');
      return false;
    }
  }

  /// Laukaisee manuaalisesti 500+ historiaviestin varoitusilmoituksen
  Future<bool> triggerHistoryAlert() async {
    try {
      final bool? success = await _channel.invokeMethod('triggerHistoryAlert');
      return success ?? false;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe historiavaroituksen laukaisussa: ${e.message}');
      return false;
    }
  }

  /// Lisää testisovelluksen historiaviestejä (kynnystestaus 500 viestiä varten)
  Future<int> insertBatchTestMessages({
    int count = 500,
    bool markAsRead = true,
  }) async {
    try {
      final int? inserted = await _channel.invokeMethod('insertBatchTestMessages', {
        'count': count,
        'markAsRead': markAsRead,
      });
      return inserted ?? 0;
    } on PlatformException catch (e) {
      // ignore: avoid_print
      print('Virhe lisättäessä testimassoja: ${e.message}');
      return 0;
    }
  }
}
