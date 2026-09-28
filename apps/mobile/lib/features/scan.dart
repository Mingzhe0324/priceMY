import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../data/catalogue.dart';
import '../widgets/common.dart';

class ScanScreen extends StatelessWidget {
  final AppState state;
  final ValueChanged<Product> onMatch;
  const ScanScreen({super.key, required this.state, required this.onMatch});
  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        'Barcode matching',
        style: Theme.of(context).textTheme.headlineMedium,
      ),
      gap(24),
      const Panel(
        child: Column(
          children: [
            Icon(Icons.qr_code_scanner, size: 72),
            SizedBox(height: 20),
            Text(
              'PriceCatcher does not provide product barcodes. Search by item name in Compare. Camera scanning and receipt recognition are not connected in this release.',
            ),
          ],
        ),
      ),
    ],
  );
}
