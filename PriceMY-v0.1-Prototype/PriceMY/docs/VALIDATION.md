# Validation · 26 September 2026

## Passed here

- FastAPI: `python -m pytest -q` — **8 passed**. Tests cover exact-product isolation, stale/expired/future/unavailable exclusion, member opt-in, estimated-value ordering, GTIN check digit, missing/invalid products, basket quantity aggregation, full-store coverage and maximum split-store count.
- Browser companion: headless Chromium, 1280×1050 and 375×812. Onboarding → guest → Home → Compare → Best Value → add to list → set RM7.20 alert → shopping basket → empty search → invalid barcode → simulated scan → Profile → reload and persistence. **Passed, no JavaScript page errors.** No document horizontal overflow at 375px.
- JavaScript syntax: `node --check preview/app.js` passed.
- 11 Dart files parsed without syntax errors using tree-sitter-dart; formatted with WASM dart_style. This is not Dart analyzer or Flutter compilation.
- Fixture is shared byte-for-byte between mobile asset and backend; browser embeds the same object.
- Preview screenshots captured from the actual HTML companion, not native Flutter.

## Not run here

- `flutter pub get`, `flutter analyze`, Flutter tests, native/web Flutter builds: Flutter SDK unavailable; SDK download unavailable in this environment.
- Android device and iOS simulator QA, camera permissions, native accessibility.
- Supabase migration execution and live RLS tests: no project configured.
- Real retailer integration, real account creation, OCR, AI, live notifications: not implemented in this phase.

The included bootstrap and GitHub Actions workflow are a way to run the remaining Flutter gates; their inclusion does not mean those gates have already passed.

Backend tested with Python 3.12, FastAPI 0.141.1, Pydantic 2.13.5, Uvicorn 0.54.0, HTTPX 0.28.1, pytest 9.1.1. One upstream Starlette deprecation warning appeared for the HTTPX test client; tests passed.
