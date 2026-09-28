import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';
import '../widgets/common.dart';

class CompareScreen extends StatelessWidget {
  final AppState state;
  final Product product;
  final String? heroTag;
  const CompareScreen({
    super.key,
    required this.state,
    required this.product,
    this.heroTag,
  });
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: state,
    builder: (context, _) {
      final c = state.catalogue,
          p = product,
          rows = c.ranked(p.id),
          latest = c.latest(p.id);
      return Scaffold(
        appBar: AppBar(title: const Text('Compare prices')),
        body: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Wrap(
              spacing: 8,
              children: [Tag('PRICECATCHER'), Tag('MONITORED ITEM')],
            ),
            gap(24),
            Center(
              child: Hero(
                tag: heroTag ?? p.id,
                child: ProductArt(p, size: 150),
              ),
            ),
            gap(24),
            Text(p.name, style: Theme.of(context).textTheme.headlineMedium),
            Text(p.pack),
            gap(),
            const Text(
              'Matched by official item code, not GTIN. Brand and exact variant equivalence are not guaranteed.',
              style: TextStyle(color: muted),
            ),
            gap(),
            Panel(
              color: ink,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'LOWEST RECENT OBSERVATION',
                    style: TextStyle(color: lime),
                  ),
                  gap(),
                  Text(
                    rows.isEmpty ? 'No recent price' : money(rows.first.price),
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  gap(),
                  const Text(
                    'Records older than 7 days are excluded. Confirm the shelf price before buying. Stock is unknown.',
                    style: TextStyle(color: Colors.white70),
                  ),
                ],
              ),
            ),
            section('${rows.length} premises with recent prices'),
            ...latest.map(
              (o) => Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Panel(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        c.branch(o)['name'],
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 17,
                        ),
                      ),
                      Text(
                        c.branch(o)['address'],
                        style: const TextStyle(color: muted),
                      ),
                      gap(),
                      Text(
                        money(o.price),
                        style: const TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (p.size != null)
                        Text(
                          '${money(o.price * 100 / p.size!)} / 100${p.unit}',
                        ),
                      gap(),
                      Text(
                        'Observed ${day(o.observed)} · ${o.eligible(DateTime.now()) ? "Recent" : "Older · excluded"}',
                      ),
                      const Text(
                        'KPDN / DOSM · no member or stock data',
                        style: TextStyle(fontSize: 11, color: muted),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            section('Price history by premise'),
            ...latest.map(
              (o) => ExpansionTile(
                title: Text(c.branch(o)['name']),
                children:
                    (c.offers
                            .where(
                              (h) =>
                                  h.productId == p.id &&
                                  h.branchId == o.branchId,
                            )
                            .toList()
                          ..sort((a, b) => b.observed.compareTo(a.observed)))
                        .map(
                          (h) => ListTile(
                            title: Text(day(h.observed)),
                            trailing: Text(money(h.price)),
                          ),
                        )
                        .toList(),
              ),
            ),
            gap(),
            FilledButton.icon(
              onPressed: () {
                state.add(p.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Added to your list')),
                );
              },
              icon: const Icon(Icons.add),
              label: const Text('Add to my list'),
            ),
            gap(24),
          ],
        ),
      );
    },
  );
}
