import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'core/theme.dart';
import 'core/app_state.dart';
import 'data/catalogue.dart';
import 'features/entry.dart';

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
    final data = await MockCatalogueRepository().load();
    return AppState(data, await SharedPreferences.getInstance());
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
                  const Text('Could not load the demo.'),
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
        return Entry(state: snapshot.data!);
      },
    ),
  );
}
