import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';
import '../widgets/common.dart';

class ShoppingScreen extends StatelessWidget {
  final AppState state;
  final ValueChanged<Product> onProduct;
  const ShoppingScreen({
    super.key,
    required this.state,
    required this.onProduct,
  });
  @override
  Widget build(BuildContext context) {
    final s = state, c = s.catalogue, totals = s.storeTotals;
    final splitStores = s.basket.keys
        .map((id) => c.ranked(id, member: s.member).first.branchId)
        .toSet();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Your everyday list.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        gap(),
        Text(
          '${s.basket.values.fold<int>(0, (a, b) => a + b)} items · saved on this device',
          style: const TextStyle(color: muted),
        ),
        gap(24),
        if (s.basket.isEmpty)
          Panel(
            child: Column(
              children: [
                const Icon(Icons.shopping_bag_outlined, size: 55),
                gap(),
                const Text('Good savings start with a list.'),
                gap(),
                const Text(
                  'Search or scan a product, then tap “Add to my list”.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: muted),
                ),
              ],
            ),
          ),
        ...s.basket.entries.map((e) {
          final p = c.products.firstWhere((p) => p.id == e.key);
          return Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Panel(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  InkWell(
                    onTap: () => onProduct(p),
                    child: Row(
                      children: [
                        ProductArt(p, size: 64),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${p.brand} ${p.name}',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              Text(
                                '${p.variant} · ${p.pack}',
                                style: const TextStyle(
                                  color: muted,
                                  fontSize: 12,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      IconButton(
                        tooltip: 'Remove one',
                        onPressed: () => s.add(p.id, -1),
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('${e.value}'),
                      IconButton(
                        tooltip: 'Add one',
                        onPressed: () => s.add(p.id),
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
        if (s.basket.isNotEmpty) ...[
          section('One store. One stop.'),
          ...totals.map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: Panel(
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            c.retailer(r['branch']['retailer_id']),
                            style: const TextStyle(fontWeight: FontWeight.w700),
                          ),
                          Text(
                            '${r['branch']['name']} · all items covered',
                            style: const TextStyle(fontSize: 11, color: muted),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      money(r['total']),
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (totals.isEmpty) const Text('No single store covers this basket.'),
          section('Smart Split'),
          Panel(
            color: ink,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Tag('LOWEST ITEM TOTAL'),
                gap(),
                Text(
                  money(s.splitTotal),
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  '${splitStores.length} stores · before travel costs',
                  style: const TextStyle(color: Colors.white),
                ),
                gap(),
                ...s.basket.entries.map((e) {
                  final o = c.ranked(e.key, member: s.member).first;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Text(
                      '${e.value} × ${c.products.firstWhere((p) => p.id == e.key).name} → ${c.retailer(o.retailerId)}',
                      style: const TextStyle(
                        color: Color(0xFFC6D8CD),
                        fontSize: 12,
                      ),
                    ),
                  );
                }),
                gap(),
                Text(
                  totals.isEmpty
                      ? 'No complete single-store basket available.'
                      : 'Potential item saving: ${money((totals.first['total'] as int) - s.splitTotal)} versus the cheapest complete single-store basket.',
                  style: const TextStyle(color: lime),
                ),
                gap(),
                const Text(
                  'This is an item-price split, not route optimisation. Extra journeys can cost more than you save.',
                  style: TextStyle(color: Color(0xFFC6D8CD), fontSize: 12),
                ),
              ],
            ),
          ),
          gap(24),
        ],
      ],
    );
  }
}
