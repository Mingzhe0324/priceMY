import 'dart:convert';
import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pricemy/data/catalogue.dart';

void main() {
  late Catalogue c;
  setUp(
    () => c = Catalogue(
      jsonDecode(File('assets/catalogue.json').readAsStringSync()),
    ),
  );
  test('Official data does not invent barcode or distance', () {
    expect(c.raw['mock'], false);
    expect(c.products.every((p) => p.barcode.isEmpty), true);
    expect(c.branches.every((b) => b['distance_km'] == null), true);
  });
  test('Latest observation per premise; expired snapshot has no ranking', () {
    final p = c.products.first;
    final clock = c.asOf.add(const Duration(hours: 12));
    final rows = c.ranked(p.id, now: clock);
    expect(rows.map((o) => o.branchId).toSet().length, rows.length);
    for (final o in rows) {
      final history = c.offers.where(
        (h) =>
            h.productId == p.id &&
            h.branchId == o.branchId &&
            !h.observed.isAfter(clock),
      );
      expect(history.every((h) => !h.observed.isAfter(o.observed)), true);
    }
    expect(c.ranked(p.id, now: c.asOf.add(const Duration(days: 30))), isEmpty);
  });
}
