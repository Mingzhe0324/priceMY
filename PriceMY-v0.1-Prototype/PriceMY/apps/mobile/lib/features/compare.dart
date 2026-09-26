import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';
import '../widgets/common.dart';

class CompareScreen extends StatefulWidget {
  final AppState state;
  final Product product;
  const CompareScreen({super.key, required this.state, required this.product});
  @override
  State<CompareScreen> createState() => _CompareScreenState();
}

class _CompareScreenState extends State<CompareScreen> {
  bool value = false;
  Future<void> setAlert() async {
    final controller = TextEditingController();
    final key = GlobalKey<FormState>();
    final result = await showDialog<int>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Set a price target'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: controller,
            autofocus: true,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              prefixText: 'RM ',
              hintText: '7.00',
            ),
            validator: (v) {
              final n = double.tryParse(v ?? '');
              return n == null || !n.isFinite || n <= 0 || n > 100000
                  ? 'Enter a positive price'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              if (key.currentState!.validate())
                Navigator.pop(
                  ctx,
                  (double.parse(controller.text) * 100).round(),
                );
            },
            child: const Text('Save target'),
          ),
        ],
      ),
    );
    // Dialog route finishes its exit animation before controller disposal.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    controller.dispose();
    if (result != null && mounted)
      widget.state.alert(widget.product.id, result);
  }

  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: widget.state,
    builder: (context, _) {
      final s = widget.state, p = widget.product, c = s.catalogue;
      final rows = c.ranked(p.id, member: s.member, value: value);
      final best = rows.first;
      final old = c.offers.where(
        (o) => o.productId == p.id && !o.eligible(c.asOf),
      );
      return Scaffold(
        appBar: AppBar(
          title: const Text('Compare'),
          actions: [
            IconButton(
              tooltip: 'Set price alert',
              onPressed: setAlert,
              icon: Icon(
                s.alerts.containsKey(p.id)
                    ? Icons.notifications_active
                    : Icons.notifications_none,
              ),
            ),
          ],
        ),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: ListView(
              padding: const EdgeInsets.all(24),
              children: [
                const Row(
                  children: [
                    Tag('EXACT PRODUCT'),
                    SizedBox(width: 8),
                    Tag('MOCK DATA', color: Color(0xFFE6EBDD)),
                  ],
                ),
                gap(24),
                Center(
                  child: Hero(tag: p.id, child: ProductArt(p, size: 170)),
                ),
                gap(24),
                Text(
                  '${p.brand} ${p.name}',
                  style: Theme.of(context).textTheme.headlineMedium,
                ),
                Text(
                  '${p.variant} · ${p.pack}',
                  style: const TextStyle(fontSize: 16, color: muted),
                ),
                gap(),
                Text(
                  'Matched by demo product identity • ${p.barcode}\nBrand, variant and size are identical across these offers.',
                  style: const TextStyle(fontSize: 12, color: muted),
                ),
                gap(20),
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(
                      value: false,
                      label: Text('Cheapest'),
                      icon: Icon(Icons.sell_outlined),
                    ),
                    ButtonSegment(
                      value: true,
                      label: Text('Best value'),
                      icon: Icon(Icons.auto_awesome_outlined),
                    ),
                  ],
                  selected: {value},
                  onSelectionChanged: (v) => setState(() => value = v.first),
                ),
                gap(),
                Panel(
                  color: ink,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        value
                            ? 'BEST VALUE · DEMO ESTIMATE'
                            : 'LOWEST ELIGIBLE PRICE',
                        style: const TextStyle(
                          color: lime,
                          fontSize: 11,
                          letterSpacing: 1.1,
                        ),
                      ),
                      gap(8),
                      Text(
                        money(best.effective(s.member)),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 40,
                          fontWeight: FontWeight.w700,
                          letterSpacing: -1.5,
                        ),
                      ),
                      Text(
                        '${c.retailer(best.retailerId)} · ${c.distance(best)} km away',
                        style: const TextStyle(color: Colors.white),
                      ),
                      gap(12),
                      Text(
                        value
                            ? 'Estimated total ${money(c.score(best, s.member, true))}: item + return trip at RM 0.50/km. No tolls or parking.'
                            : 'Excludes old prices. Member conditions apply only when enabled.',
                        style: const TextStyle(
                          color: Color(0xFFB8CFC1),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: const Text('Include member prices'),
                  subtitle: const Text(
                    'Demo: assumes you hold each membership',
                  ),
                  value: s.member,
                  onChanged: s.toggleMember,
                ),
                section('${rows.length} comparable stores'),
                ...rows.asMap().entries.map((e) {
                  final o = e.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: Panel(
                      color: e.key == 0
                          ? const Color(0xFFE7EEDC)
                          : Colors.white,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  c.retailer(o.retailerId),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                    fontSize: 18,
                                  ),
                                ),
                              ),
                              Text(
                                money(o.effective(s.member)),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 20,
                                ),
                              ),
                            ],
                          ),
                          Text(
                            '${c.branch(o)['name']} · ${c.distance(o)} km',
                            style: const TextStyle(color: muted, fontSize: 12),
                          ),
                          gap(10),
                          Text(
                            '${money(o.effective(s.member) * 100 / p.size)} / 100${p.unit}${o.memberPrice != null ? ' · Member ${money(o.memberPrice!)}' : ''}',
                            style: const TextStyle(fontSize: 12),
                          ),
                          gap(10),
                          Tag(
                            'Demo · ${sourceLabels[o.source]}',
                            color: Colors.white,
                          ),
                          gap(8),
                          const Text(
                            'Observed 26 Sep 2026 · valid to 3 Oct 2026',
                            style: TextStyle(fontSize: 10, color: muted),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                section('Older / unverified'),
                ...old.map(
                  (o) => ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(c.retailer(o.retailerId)),
                    subtitle: const Text(
                      'Observed 1 Aug 2026 · excluded from ranking',
                    ),
                    trailing: Text(
                      money(o.price),
                      style: const TextStyle(color: muted),
                    ),
                  ),
                ),
                section('Price history'),
                const Panel(
                  child: Text(
                    'Only one current demo observation per store. Historical trends will appear when dated observations are available.',
                  ),
                ),
                gap(24),
                FilledButton.icon(
                  onPressed: () {
                    s.add(p.id);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Added to your shopping list'),
                        duration: Duration(seconds: 1),
                      ),
                    );
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Add to my list'),
                ),
                gap(12),
                OutlinedButton.icon(
                  onPressed: setAlert,
                  icon: const Icon(Icons.notifications_none),
                  label: Text(
                    s.alerts.containsKey(p.id)
                        ? 'Target saved · ${money(s.alerts[p.id]!)}'
                        : 'Set a price alert',
                  ),
                ),
                gap(24),
              ],
            ),
          ),
        ),
      );
    },
  );
}
