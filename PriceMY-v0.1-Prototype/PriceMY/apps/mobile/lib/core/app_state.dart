import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../data/catalogue.dart';

class AppState extends ChangeNotifier {
  final Catalogue catalogue;
  final SharedPreferences prefs;
  final Map<String, int> basket = {};
  final Map<String, int> alerts = {};
  bool member = false, onboarded = false;
  String name = 'Guest';
  AppState(this.catalogue, this.prefs) {
    onboarded = prefs.getBool('onboarded') ?? false;
    member = prefs.getBool('member') ?? false;
    for (final pair in [('basket', basket), ('alerts', alerts)]) {
      try {
        final data =
            jsonDecode(prefs.getString(pair.$1) ?? '{}')
                as Map<String, dynamic>;
        for (final e in data.entries) {
          if (catalogue.products.any((p) => p.id == e.key) &&
              e.value is int &&
              e.value > 0)
            pair.$2[e.key] = e.value;
        }
      } catch (_) {
        /* Invalid local demo state is safely reset. */
      }
    }
  }
  void add(String id, [int delta = 1]) {
    basket[id] = (basket[id] ?? 0) + delta;
    if (basket[id]! <= 0) basket.remove(id);
    save();
  }

  void alert(String id, int price) {
    alerts[id] = price;
    save();
  }

  void removeAlert(String id) {
    alerts.remove(id);
    save();
  }

  void toggleMember(bool value) {
    member = value;
    save();
  }

  void finishOnboarding() {
    onboarded = true;
    save();
  }

  Future<void> save() async {
    notifyListeners();
    await prefs.setString('basket', jsonEncode(basket));
    await prefs.setString('alerts', jsonEncode(alerts));
    await prefs.setBool('member', member);
    await prefs.setBool('onboarded', onboarded);
  }

  int get splitTotal => basket.entries.fold(
    0,
    (sum, e) =>
        sum +
        catalogue.ranked(e.key, member: member).first.effective(member) *
            e.value,
  );
  List<Map<String, dynamic>> get storeTotals {
    final result = <Map<String, dynamic>>[];
    for (final branch in catalogue.branches) {
      var total = 0;
      var covered = 0;
      for (final e in basket.entries) {
        final rows = catalogue
            .ranked(e.key, member: member)
            .where((o) => o.branchId == branch['id']);
        if (rows.isNotEmpty) {
          covered++;
          total += rows.first.effective(member) * e.value;
        }
      }
      if (covered == basket.length && covered > 0)
        result.add({'branch': branch, 'total': total});
    }
    result.sort((a, b) => (a['total'] as int).compareTo(b['total'] as int));
    return result;
  }
}
