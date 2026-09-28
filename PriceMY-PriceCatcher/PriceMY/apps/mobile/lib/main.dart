import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'core/app_state.dart';
import 'data/catalogue.dart';
import 'features/shell.dart';
import 'dart:convert';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const PriceMY());
}

class PriceMY extends StatefulWidget {
  const PriceMY({super.key});
  @override
  State<PriceMY> createState() => _PriceMYState();
}

class _PriceMYState extends State<PriceMY> {
  late Future<AppState> boot;
  Future<AppState> load() async {
    var data = await PriceCatcherRepository().load();
    final prefs = await SharedPreferences.getInstance();
    try {
      final saved = prefs.getString('pricecatcher_cache');
      if (saved != null) {
        final cached = Catalogue(jsonDecode(saved));
        if (!cached.asOf.isBefore(data.asOf)) data = cached;
      }
    } catch (_) {
      /* Keep bundled official snapshot if cache is invalid. */
    }
    return AppState(data, prefs);
  }

  @override
  void initState() {
    super.initState();
    boot = load();
  }

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'PriceMY',
    debugShowCheckedModeBanner: false,
    theme: appTheme(),
    home: FutureBuilder<AppState>(
      future: boot,
      builder: (context, snapshot) {
        if (snapshot.hasError)
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load price records.'),
                  TextButton(
                    onPressed: () => setState(() => boot = load()),
                    child: const Text('Try again'),
                  ),
                ],
              ),
            ),
          );
        if (!snapshot.hasData)
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        return Shell(state: snapshot.data!, onLogout: () {});
      },
    ),
  );
}
