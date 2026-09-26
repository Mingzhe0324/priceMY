import 'package:flutter/material.dart';
import '../core/app_state.dart';
import '../core/theme.dart';
import '../data/catalogue.dart';
import '../widgets/common.dart';

class ScanScreen extends StatefulWidget {
  final AppState state;
  final ValueChanged<Product> onMatch;
  const ScanScreen({super.key, required this.state, required this.onMatch});
  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {
  final code = TextEditingController();
  String? error;
  bool receipt = false;
  @override
  void dispose() {
    code.dispose();
    super.dispose();
  }

  void lookup(String v) {
    final matches = widget.state.catalogue.products.where(
      (p) => p.barcode == v.trim().toUpperCase(),
    );
    if (matches.isEmpty) {
      setState(() => error = 'No matching demo code. Try DEMO-0001.');
    } else {
      setState(() => error = null);
      widget.onMatch(matches.first);
    }
  }

  @override
  Widget build(BuildContext context) => ListView(
    padding: const EdgeInsets.all(24),
    children: [
      Text(
        'Scan. Compare.\nShop smarter.',
        style: Theme.of(context).textTheme.headlineLarge,
      ),
      gap(),
      const Text(
        'Demo scanner · camera is not enabled',
        style: TextStyle(color: muted),
      ),
      gap(24),
      SegmentedButton<bool>(
        segments: const [
          ButtonSegment(value: false, label: Text('Barcode')),
          ButtonSegment(value: true, label: Text('Receipt')),
        ],
        selected: {receipt},
        onSelectionChanged: (v) => setState(() => receipt = v.first),
      ),
      gap(24),
      Panel(
        color: ink,
        child: SizedBox(
          height: 240,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                receipt ? Icons.receipt_long_outlined : Icons.qr_code_scanner,
                size: 100,
                color: lime,
              ),
              gap(20),
              Text(
                receipt
                    ? 'Receipt recognition preview'
                    : 'Place a barcode inside the frame',
                style: const TextStyle(color: Colors.white),
              ),
              gap(),
              const Text(
                'SIMULATION · NO CAMERA ACCESS',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.3,
                  color: Color(0xFFB8CFC1),
                ),
              ),
            ],
          ),
        ),
      ),
      gap(24),
      if (!receipt) ...[
        TextField(
          controller: code,
          decoration: InputDecoration(
            labelText: 'Enter demo barcode',
            hintText: 'DEMO-0001',
            errorText: error,
          ),
          onSubmitted: lookup,
        ),
        gap(),
        FilledButton(
          onPressed: () => lookup(code.text),
          child: const Text('Find this product'),
        ),
        gap(),
        OutlinedButton(
          onPressed: () => lookup('DEMO-0001'),
          child: const Text('Simulate a successful scan'),
        ),
        gap(),
        const Text(
          'Production matching will validate GTIN checksums. Demo codes are intentionally not real retail barcodes.',
          style: TextStyle(color: muted, fontSize: 12),
        ),
      ] else
        const Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Tag('NEXT PHASE'),
              SizedBox(height: 14),
              Text(
                'Turn receipts into useful prices.',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 19),
              ),
              SizedBox(height: 10),
              Text(
                'Future flow: capture → hide personal details → extract items → confirm exact matches → submit for verification.\n\nOCR and receipt uploads are not connected in this prototype.',
              ),
            ],
          ),
        ),
      gap(24),
    ],
  );
}
