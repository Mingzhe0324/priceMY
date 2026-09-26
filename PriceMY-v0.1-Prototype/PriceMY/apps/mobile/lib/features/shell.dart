import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';
import '../widgets/common.dart';
import 'compare.dart';
import 'shopping.dart';
import 'scan.dart';

class Shell extends StatefulWidget {
  final AppState state;
  final VoidCallback onLogout;
  const Shell({super.key, required this.state, required this.onLogout});
  @override
  State<Shell> createState() => _ShellState();
}

class _ShellState extends State<Shell> {
  int tab = 0;
  String query = '', category = 'All';
  AppState get s => widget.state;
  void compare(Product p) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => CompareScreen(state: s, product: p),
    ),
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: s,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              child: KeyedSubtree(
                key: ValueKey(tab),
                child: tab == 0
                    ? home()
                    : tab == 1
                    ? catalogue()
                    : tab == 2
                    ? ScanScreen(state: s, onMatch: compare)
                    : tab == 3
                    ? ShoppingScreen(state: s, onProduct: compare)
                    : profile(),
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: tab,
        onDestinationSelected: (i) => setState(() => tab = i),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Home',
          ),
          NavigationDestination(icon: Icon(Icons.search), label: 'Compare'),
          NavigationDestination(
            icon: Icon(Icons.qr_code_scanner),
            label: 'Scan',
          ),
          NavigationDestination(
            icon: Icon(Icons.shopping_bag_outlined),
            label: 'My list',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            label: 'Profile',
          ),
        ],
      ),
    ),
  );
  Widget home() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Row(
        children: [
          const Icon(Icons.location_on_outlined, size: 19),
          const SizedBox(width: 5),
          const Expanded(
            child: Text(
              'Petaling Jaya',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          const Tag('DEMO', color: Color(0xFFE6EBDD)),
        ],
      ),
      gap(5),
      const Text(
        'Sample location · not your live location',
        style: TextStyle(fontSize: 11, color: muted),
      ),
      gap(26),
      Text(
        'Small choices.\nBigger savings.',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      gap(20),
      InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => setState(() => tab = 1),
        child: const Panel(
          padding: EdgeInsets.all(17),
          child: Row(
            children: [
              Icon(Icons.search, color: muted),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'What’s on your shopping list?',
                  style: TextStyle(color: muted),
                ),
              ),
              Icon(Icons.tune, size: 20),
            ],
          ),
        ),
      ),
      gap(22),
      Panel(
        color: ink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Tag('SHOP SMARTER'),
            gap(18),
            const Text(
              'One product.\nEvery perspective.',
              style: TextStyle(
                fontSize: 27,
                fontWeight: FontWeight.w700,
                color: Colors.white,
                height: 1.15,
              ),
            ),
            gap(12),
            const Text(
              'Price, distance and source.\nFind the choice that works for you.',
              style: TextStyle(color: Color(0xFFB8CFC1)),
            ),
            gap(20),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: lime,
                foregroundColor: ink,
              ),
              onPressed: () => compare(s.catalogue.products.first),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Compare an essential'),
                  Icon(Icons.arrow_forward),
                ],
              ),
            ),
          ],
        ),
      ),
      section(
        'Your daily essentials',
        action: TextButton(
          onPressed: () => setState(() => tab = 1),
          child: const Text('See all'),
        ),
      ),
      ...s.catalogue.products.take(3).map(productRow),
      section('Made for your everyday'),
      Row(
        children: [
          Expanded(
            child: Panel(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.shopping_basket_outlined),
                  gap(),
                  Text(
                    '${s.basket.length} items',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'In your saved list',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Panel(
              color: const Color(0xFFE7EDD9),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.notifications_none),
                  gap(),
                  Text(
                    '${s.alerts.length} alerts',
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Saved on this device',
                    style: TextStyle(color: muted, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
      gap(20),
      const Text(
        'All prices, sources and distances are illustrative. No retailer is connected yet.',
        style: TextStyle(color: muted, fontSize: 12),
      ),
    ],
  );
  Widget catalogue() {
    final rows = s.catalogue.products
        .where(
          (p) =>
              (category == 'All' || category == p.category) &&
              '${p.name} ${p.brand} ${p.variant} ${p.barcode}'
                  .toLowerCase()
                  .contains(query.toLowerCase()),
        )
        .toList();
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        Text(
          'Find your best buy.',
          style: Theme.of(context).textTheme.headlineLarge,
        ),
        gap(),
        const Text(
          'Same product. Real clarity.  •  Demo prices',
          style: TextStyle(color: muted),
        ),
        gap(20),
        TextField(
          onChanged: (v) => setState(() => query = v),
          decoration: const InputDecoration(
            hintText: 'Search milk, MILO, brand…',
            prefixIcon: Icon(Icons.search),
          ),
        ),
        gap(),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children:
                ['All', ...s.catalogue.products.map((p) => p.category).toSet()]
                    .map(
                      (c) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(c),
                          selected: c == category,
                          onSelected: (_) => setState(() => category = c),
                        ),
                      ),
                    )
                    .toList(),
          ),
        ),
        section('${rows.length} products'),
        if (rows.isEmpty)
          const Panel(
            child: Text(
              'No exact product found. Try another brand or scan a demo code.',
            ),
          ),
        ...rows.map(productRow),
      ],
    );
  }

  Widget productRow(Product p) {
    final offers = s.catalogue.ranked(p.id, member: s.member);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => compare(p),
        borderRadius: BorderRadius.circular(24),
        child: Panel(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              ProductArt(p, size: 76),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      p.brand,
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                    Text(
                      p.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      '${p.variant} · ${p.pack}',
                      style: const TextStyle(fontSize: 11, color: muted),
                    ),
                    gap(5),
                    Text(
                      'From ${money(offers.first.effective(s.member))}',
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                  ],
                ),
              ),
              const Icon(Icons.chevron_right, color: muted),
            ],
          ),
        ),
      ),
    );
  }

  Widget profile() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text('Your space.', style: Theme.of(context).textTheme.headlineLarge),
      gap(24),
      Panel(
        child: Row(
          children: [
            const CircleAvatar(
              radius: 28,
              backgroundColor: lime,
              child: Icon(Icons.person_outline, color: ink, size: 30),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    s.name,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Text(
                    'Local demo profile',
                    style: TextStyle(color: muted),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      gap(),
      Panel(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'MONTHLY SAVINGS',
              style: TextStyle(fontSize: 11, letterSpacing: 1.4, color: muted),
            ),
            gap(8),
            const Text(
              'No purchases yet',
              style: TextStyle(fontSize: 25, fontWeight: FontWeight.w700),
            ),
            gap(8),
            const Text(
              'Savings will be calculated from verified purchases and a clearly defined comparison price.',
            ),
          ],
        ),
      ),
      section('Your preferences'),
      SwitchListTile(
        contentPadding: EdgeInsets.zero,
        title: const Text('Include demo member prices'),
        subtitle: const Text('Assumes membership at all sample stores.'),
        value: s.member,
        onChanged: s.toggleMember,
      ),
      section('Price alerts'),
      if (s.alerts.isEmpty)
        const Text(
          'Open a product and set a target price.',
          style: TextStyle(color: muted),
        ),
      ...s.alerts.entries.map(
        (e) => ListTile(
          contentPadding: EdgeInsets.zero,
          title: Text(
            s.catalogue.products.firstWhere((p) => p.id == e.key).name,
          ),
          subtitle: Text(
            'Target ${money(e.value)} · local only, no notifications',
          ),
          trailing: IconButton(
            tooltip: 'Remove alert',
            onPressed: () => s.removeAlert(e.key),
            icon: const Icon(Icons.close),
          ),
        ),
      ),
      section('Retailer roadmap'),
      const Text(
        'Config-driven · planned, not connected',
        style: TextStyle(color: muted),
      ),
      gap(),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: s.catalogue.retailers
            .map((r) => Tag(r['name'], color: const Color(0xFFE8EDDF)))
            .toList(),
      ),
      gap(28),
      OutlinedButton(
        onPressed: widget.onLogout,
        child: const Text('Leave demo profile'),
      ),
      gap(),
      const Text(
        'PriceMY 0.1 · Prototype\nEnglish UI · MYR · Malaysia\nReceipt recognition, live camera, AI and real accounts are next-phase integrations.',
        style: TextStyle(color: muted, fontSize: 12),
      ),
    ],
  );
}
