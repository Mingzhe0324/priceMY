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
  String query = '';
  bool busy = false;
  AppState get s => widget.state;
  void compare(Product p) => Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) =>
          CompareScreen(state: s, product: p, heroTag: '$tab-${p.id}'),
    ),
  );
  Future<void> refresh() async {
    setState(() => busy = true);
    try {
      await s.refresh();
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Latest server snapshot loaded')),
        );
    } catch (e) {
      if (mounted)
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Could not refresh. Saved records retained. $e'),
          ),
        );
    } finally {
      if (mounted) setState(() => busy = false);
    }
  }

  Widget productRow(Product p) {
    final rows = s.catalogue.ranked(p.id);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Panel(
        padding: const EdgeInsets.all(8),
        child: ListTile(
          onTap: () => compare(p),
          leading: Hero(tag: '$tab-${p.id}', child: ProductArt(p, size: 54)),
          title: Text(p.name, maxLines: 2, overflow: TextOverflow.ellipsis),
          subtitle: Text(p.pack),
          trailing: Text(rows.isEmpty ? 'Older only' : money(rows.first.price)),
        ),
      ),
    );
  }

  Widget home() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      const Tag('KPDN / DOSM · PRICECATCHER'),
      gap(24),
      Text(
        'Know the price.\nChoose with care.',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      gap(),
      Text(
        '${s.catalogue.raw['region']['district']}, ${s.catalogue.raw['region']['state']} · manually configured coverage',
        style: const TextStyle(color: muted),
      ),
      gap(24),
      Panel(
        color: ink,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${s.catalogue.products.length} monitored items',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 25,
                fontWeight: FontWeight.bold,
              ),
            ),
            gap(),
            Text(
              '${s.catalogue.branches.length} premises · newest record ${day(s.catalogue.asOf)}',
              style: const TextStyle(color: lime),
            ),
            gap(),
            const Text(
              'Official observed prices. Not a live shelf-price or stock feed.',
              style: TextStyle(color: Colors.white70),
            ),
            gap(),
            FilledButton(
              onPressed: () => setState(() => tab = 1),
              child: const Text('Explore prices'),
            ),
          ],
        ),
      ),
      section('Browse essentials'),
      ...s.catalogue.products.take(8).map(productRow),
      const Text(
        'Source: data.gov.my / PriceCatcher · CC BY 4.0',
        style: TextStyle(color: muted, fontSize: 12),
      ),
    ],
  );
  Widget catalogue() {
    final products = s.catalogue.products
        .where(
          (p) => '${p.name} ${p.category} ${p.pack}'.toLowerCase().contains(
            query.toLowerCase(),
          ),
        )
        .toList();
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(20),
          child: TextField(
            decoration: const InputDecoration(
              prefixIcon: Icon(Icons.search),
              hintText: 'Search item name · e.g. AYAM',
            ),
            onChanged: (v) => setState(() => query = v),
          ),
        ),
        Expanded(
          child: products.isEmpty
              ? const Center(child: Text('No monitored item found'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: products.length,
                  itemBuilder: (_, i) => productRow(products[i]),
                ),
        ),
      ],
    );
  }

  Widget profile() => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        'Your price notebook',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      gap(),
      const Text(
        'Guest · shopping list saved on this device. Cloud accounts are not connected.',
      ),
      section('Data updates'),
      Text('Newest observation: ${day(s.catalogue.asOf)}'),
      gap(),
      FilledButton.icon(
        onPressed: busy ? null : refresh,
        icon: const Icon(Icons.refresh),
        label: Text(busy ? 'Refreshing…' : 'Refresh from server'),
      ),
      gap(),
      Text(
        PriceCatcherRepository.apiBase.isEmpty
            ? 'This build includes an official offline snapshot. Online refresh becomes available when a price server is connected.'
            : 'Refresh downloads the backend snapshot. The backend importer must run regularly.',
      ),
      section('Coverage & limitations'),
      const Text(
        'Prices are grouped by official monitored item code. No GTIN, live inventory, membership prices, GPS distances or travel ranking are inferred. Records older than 7 days stay visible outside current rankings.',
      ),
      section('Attribution'),
      const Text(
        'KPDN / DOSM · data.gov.my\nCreative Commons Attribution 4.0\nhttps://data.gov.my/data-catalogue/pricecatcher',
      ),
      section('Release'),
      const Text('PriceMY 0.2 · PriceCatcher integration'),
    ],
  );
  @override
  Widget build(BuildContext context) => ListenableBuilder(
    listenable: s,
    builder: (context, _) => Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 680),
            child: AnimatedSwitcher(
              duration: MediaQuery.of(context).disableAnimations
                  ? Duration.zero
                  : const Duration(milliseconds: 350),
              switchInCurve: Curves.easeOutCubic,
              transitionBuilder: (child, animation) => FadeTransition(
                opacity: animation,
                child: SlideTransition(
                  position: Tween<Offset>(
                    begin: const Offset(0, .025),
                    end: Offset.zero,
                  ).animate(animation),
                  child: child,
                ),
              ),
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
          NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
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
}
