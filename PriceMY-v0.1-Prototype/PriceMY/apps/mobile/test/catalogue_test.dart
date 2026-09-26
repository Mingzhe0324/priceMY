import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pricemy/data/catalogue.dart';
import 'package:pricemy/core/app_state.dart';

void main() {
  late Catalogue catalogue;
  setUp(() {
    catalogue = Catalogue(
      jsonDecode(File('assets/catalogue.json').readAsStringSync()),
    );
  });
  test('Exact product comparisons do not combine variants or pack sizes', () {
    final rows = catalogue.ranked('p1');
    expect(rows.every((o) => o.productId == 'p1'), true);
    expect(rows.length, 4);
    expect(rows.first.retailerId, 'r4');
    expect(rows.every((o) => o.source != 'older_unverified'), true);
  });
  test('Membership prices are opt-in', () {
    final aeon = catalogue.ranked('p1').firstWhere((o) => o.retailerId == 'r2');
    expect(aeon.effective(false), aeon.price);
    expect(aeon.effective(true), aeon.memberPrice);
  });
  test('Local quantities and targets survive state recreation', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = await SharedPreferences.getInstance();
    final state = AppState(catalogue, prefs);
    state.add('p1', 2);
    state.alert('p1', 720);
    await state.save();
    final restored = AppState(catalogue, prefs);
    expect(restored.basket['p1'], 2);
    expect(restored.alerts['p1'], 720);
    expect(restored.splitTotal, 1500);
    expect(restored.storeTotals.length, 4);
    restored.add('p1', -2);
    expect(restored.basket, isEmpty);
  });
}
