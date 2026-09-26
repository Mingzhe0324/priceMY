import 'dart:convert';
import 'package:flutter/services.dart';

class Product {
  final String id, name, brand, variant, unit, category, color, barcode;
  final int size;
  Product(Map<String, dynamic> j)
    : id = j['id'],
      name = j['name'],
      brand = j['brand'],
      variant = j['variant'],
      unit = j['unit'],
      category = j['category'],
      color = j['color'],
      barcode = j['barcode'],
      size = j['size'];
  String get pack =>
      '${size >= 1000 ? size / 1000 : size}${size >= 1000 ? (unit == 'ml' ? 'L' : 'kg') : unit}';
  String get identity => '$brand · $variant · $pack';
}

class Offer {
  final String id, productId, retailerId, branchId, source;
  final int price;
  final int? memberPrice;
  final DateTime observed, validUntil;
  final bool available;
  Offer(Map<String, dynamic> j)
    : id = j['id'],
      productId = j['product_id'],
      retailerId = j['retailer_id'],
      branchId = j['branch_id'],
      source = j['source'],
      price = j['price_sen'],
      memberPrice = j['member_price_sen'],
      observed = DateTime.parse(j['observed_at']),
      validUntil = DateTime.parse(j['valid_until']),
      available = j['available'];
  int effective(bool member) => member ? memberPrice ?? price : price;
  bool eligible(DateTime now) =>
      available &&
      validUntil.isAfter(now) &&
      !observed.isAfter(now) &&
      now.difference(observed) <= const Duration(days: 14) &&
      source != 'older_unverified';
}

abstract class CatalogueRepository {
  Future<Catalogue> load();
}

class MockCatalogueRepository implements CatalogueRepository {
  @override
  Future<Catalogue> load() async => Catalogue(
    jsonDecode(await rootBundle.loadString('assets/catalogue.json')),
  );
}

class Catalogue {
  final List<Product> products;
  final List<Offer> offers;
  final List<Map<String, dynamic>> retailers, branches;
  final DateTime asOf;
  Catalogue(Map<String, dynamic> j)
    : products = (j['products'] as List).map((p) => Product(p)).toList(),
      offers = (j['offers'] as List).map((o) => Offer(o)).toList(),
      retailers = List<Map<String, dynamic>>.from(j['retailers']),
      branches = List<Map<String, dynamic>>.from(j['branches']),
      asOf = DateTime.parse(j['as_of']);
  String retailer(String id) =>
      retailers.firstWhere((r) => r['id'] == id)['name'];
  Map<String, dynamic> branch(Offer o) =>
      branches.firstWhere((b) => b['id'] == o.branchId);
  double distance(Offer o) => (branch(o)['distance_km'] as num).toDouble();
  List<Offer> ranked(String id, {bool member = false, bool value = false}) {
    final rows = offers
        .where((o) => o.productId == id && o.eligible(asOf))
        .toList();
    rows.sort(
      (a, b) => score(a, member, value).compareTo(score(b, member, value)),
    );
    return rows;
  }

  // Estimated return trip at RM0.50/km; a transparent demo heuristic, not AI.
  int score(Offer o, bool member, bool value) =>
      o.effective(member) + (value ? (distance(o) * 100).round() : 0);
}

String money(num sen) => 'RM ${(sen / 100).toStringAsFixed(2)}';
const sourceLabels = {
  'official_partner': 'Official / Partner',
  'catalogue': 'Retailer catalogue',
  'receipt_verified': 'Receipt Verified',
  'community': 'Community submitted',
  'older_unverified': 'Older / unverified',
};
