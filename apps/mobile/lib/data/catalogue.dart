import 'dart:convert';
import 'dart:io';
import 'package:flutter/services.dart';

class Product {
  final String id, name, brand, variant, unit, category, color, barcode, pack;
  final num? size;
  Product(Map<String, dynamic> j)
    : id = j['id'],
      name = j['name'],
      brand = j['brand'],
      variant = j['variant'],
      unit = j['unit'],
      category = j['category'],
      color = j['color'],
      barcode = j['barcode'],
      size = j['size'],
      pack = j['pack_label'];
  String get identity => '$name · $pack';
}

class Offer {
  final String id, productId, retailerId, branchId, source;
  final int price;
  final int? memberPrice;
  final DateTime observed;
  Offer(Map<String, dynamic> j)
    : id = j['id'],
      productId = j['product_id'],
      retailerId = j['retailer_id'],
      branchId = j['branch_id'],
      source = j['source'],
      price = j['price_sen'],
      memberPrice = j['member_price_sen'],
      observed = DateTime.parse(j['observed_at']);
  int effective(bool member) => price;
  bool eligible(DateTime now) =>
      !observed.isAfter(now) &&
      now.difference(observed) <= const Duration(days: 7);
}

class PriceCatcherRepository {
  static const apiBase = String.fromEnvironment('API_BASE_URL');
  Future<Catalogue> load() async => Catalogue(
    jsonDecode(await rootBundle.loadString('assets/catalogue.json')),
  );
  Future<Catalogue> refresh() async {
    final base = Uri.parse(apiBase);
    if (base.scheme != 'https' || base.host.isEmpty)
      throw const FormatException(
        'Configure an HTTPS API_BASE_URL when building the app.',
      );
    final client = HttpClient()
      ..connectionTimeout = const Duration(seconds: 15);
    try {
      final req = await client.getUrl(
        Uri.parse('${apiBase.replaceAll(RegExp(r"/$"), "")}/v1/catalogue'),
      );
      final res = await req.close().timeout(const Duration(seconds: 30));
      if (res.statusCode != 200)
        throw HttpException('Price service returned ${res.statusCode}');
      final body = await utf8.decoder
          .bind(res)
          .join()
          .timeout(const Duration(seconds: 30));
      return Catalogue(jsonDecode(body));
    } finally {
      client.close(force: true);
    }
  }
}

class Catalogue {
  final List<Product> products;
  final List<Offer> offers;
  final List<Map<String, dynamic>> retailers, branches;
  final DateTime asOf;
  final Map<String, dynamic> raw;
  Catalogue(Map<String, dynamic> j)
    : raw = j,
      products = (j['products'] as List).map((p) => Product(p)).toList(),
      offers = (j['offers'] as List).map((o) => Offer(o)).toList(),
      retailers = List<Map<String, dynamic>>.from(j['retailers']),
      branches = List<Map<String, dynamic>>.from(j['branches']),
      asOf = DateTime.parse(j['as_of']) {
    if (j['mock'] != false || products.isEmpty || branches.isEmpty)
      throw const FormatException('Invalid PriceCatcher snapshot');
    final ids = products.map((p) => p.id).toSet(),
        stores = branches.map((b) => b['id']).toSet();
    if (offers.any(
      (o) =>
          !ids.contains(o.productId) ||
          !stores.contains(o.branchId) ||
          o.price <= 0,
    ))
      throw const FormatException('Invalid observation');
  }
  String retailer(String id) =>
      retailers.firstWhere((r) => r['id'] == id)['name'];
  Map<String, dynamic> branch(Offer o) =>
      branches.firstWhere((b) => b['id'] == o.branchId);
  List<Offer> latest(String id, {DateTime? now}) {
    final clock = now ?? DateTime.now();
    final byBranch = <String, Offer>{};
    for (final o in offers.where(
      (o) => o.productId == id && !o.observed.isAfter(clock),
    )) {
      final old = byBranch[o.branchId];
      if (old == null || o.observed.isAfter(old.observed))
        byBranch[o.branchId] = o;
    }
    return byBranch.values.toList()..sort((a, b) => a.price.compareTo(b.price));
  }

  List<Offer> ranked(
    String id, {
    bool member = false,
    bool value = false,
    DateTime? now,
  }) => latest(
    id,
    now: now,
  ).where((o) => o.eligible(now ?? DateTime.now())).toList();
}

String money(num sen) => 'RM ${(sen / 100).toStringAsFixed(2)}';
String day(DateTime value) => value
    .toUtc()
    .add(const Duration(hours: 8))
    .toIso8601String()
    .substring(0, 10);
