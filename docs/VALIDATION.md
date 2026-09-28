# Validation — PriceCatcher 0.2

- 12 backend/importer tests passed: real-data contract, latest-record selection, clock-based expiry, future-date exclusion, unit conversion, unknown units, complete baskets, missing prices, branch limits, barcode rejection, region filtering, provenance and month rollover.
- Downloaded official CSVs and imported Petaling / Selangor: 269 items, 41 premises, 10,075 dated observations. Latest date is 2026-09-24. Not all Malaysia coverage.
- Dart files formatted with the Dart WASM formatter and syntax-parsed. Workflow YAML parsed. This is NOT `flutter analyze`, Flutter tests or a native build.
- Native Flutter tests and Android/iOS builds remain unexecuted here because Flutter SDK and macOS/Xcode are unavailable. CI workflows perform analysis, tests and builds when run on GitHub.
- No UI screenshot or device verification is claimed for this revision. Old prototype screenshots/HTML were removed because they showed fictional prices.
- API has not been deployed, no recurring importer job has been started, and no IPA has been created. The bundled official snapshot is usable by the app after a successful build. Online refresh additionally needs deployment and API_BASE_URL.
- Supabase, GPS, receipt recognition, barcode-product mappings, push alerts and membership integrations remain unconnected.
