# PriceMY architecture & next steps

## Phase 1 runtime

Flutter view → AppState → CatalogueRepository → bundled mock JSON.
FastAPI → pure comparison domain → the same JSON fixture.
HTML preview → same fixture → independent presentation implementation.

The browser companion proves the interaction design, not native Flutter rendering. No web wrapper replaces the requested mobile app. Native shells are generated with the installed Flutter toolchain. UI language is English in this version; localization to Bahasa Melayu and Chinese is planned.

## Production target

Flutter → Supabase Auth (session/refresh) → JWT-authenticated FastAPI → Supabase PostgreSQL.
Receipt uploads → private Storage object under user UUID → queued OCR → user review → moderation → approved price observation.
Retailer adapters → ingestion queue → schema validation → identity matching → price observations.
AI receives eligible offer IDs and returns explanations/candidates. Domain code still determines prices and totals.

No service-role keys or AI keys in Flutter. FastAPI production routes must validate JWT signature, issuer, audience and expiry; never accept user_id from the request as authorization. This demo API exposes public fixtures only and has no private mutation endpoints. No production auth bypass is provided.

## Product identity

Product = brand + name + variant + normalized amount + measurement dimension + pack count.
Barcode table stores canonical GTIN-14 (validate check digit before padding). A 1 L full-cream milk and 1 L low-fat milk are different canonical products; so are 1 L and 2 L packs. Unit price enables an explicit alternative-size comparison later, never conflates products in exact matches.

Match order: validated GTIN → confirmed exact attributes → manual review. AI may propose ranked candidates; fuzzy confidence alone cannot approve an exact match. Importer must check GTIN attributes against existing product identity and quarantine conflicts, multipacks, promotional bundles and ambiguous receipt descriptions. Demo identifiers are intentionally `DEMO-0001`, not purported real GTINs.

## Price semantics

All totals use integer Malaysian sen. Unit-price display can use fractional sen. Offer scope is a branch; absent data is unknown, not proof a retailer does not stock an item. Prices include source kind, observed_at, validity, promotion conditions, membership conditions and availability.

Demo uses a fixed `as_of` (26 Sep 2026) so it does not decay between demonstrations. Production must use server UTC now, retailer validity windows, an explicit freshness SLA per source, and Asia/Kuala_Lumpur date presentation. No source label on a mock offer asserts a real retailer partnership.

Source kinds: Official / Partner; Retailer catalogue; Receipt Verified; Community submitted; Older / unverified. All categories retain provenance. Receipt Verified requires evidence plus review; OCR success alone is not verification.

Cheapest: minimum eligible exact-product price. Demo excludes >14-day-old, expired, unavailable, future-dated and older_unverified observations. Membership is opt-in; demo switch assumes all sample memberships. Production must model memberships per retailer. Complex multi-buy, coupons, delivery charges, deposit and loyalty-points value must have separate eligibility and effective-cost rules before they enter rankings.

Best Value v0: item + estimated return distance × RM0.50/km. Distance is one-way, hence distance_km × 100 sen. Clearly disclosed, no parking/tolls/time. Not an AI score. Production should allow walk/drive mode, travel-cost preferences and rank explanations; geography and stock must be current.

Basket: compare only branches covering every requested product. Duplicate line items aggregate quantities. Never silently drop missing products. Flutter and HTML use unconstrained per-item cheapest selection; API additionally supports max_stores 1–5 with exact subset enumeration for the small fixture. This is NOT scalable to arbitrary thousands of branches: production requires a bounded nearby-store candidate set and a suitable optimizer. Split savings compare to cheapest complete single-store item subtotal and exclude transport; no claim of actual earned savings.

## Supabase and privacy

Migration is designed for a new Supabase project, not a migration into an unknown existing database. It enables RLS on every app table, isolates personal records, keeps receipt Storage private and denies public mapping writes. Users cannot mark receipts or submissions verified. Trusted workers set moderation state and approved flags. Public prices may not expose receipt contents; use signed private reads only after owner authorization.

SQL has not run against a Supabase instance. Before production, exercise policies with two real test accounts: A must not read/write B's list, alert, receipt or Storage object; anon must not mutate prices; authenticated clients must not self-approve. Add upload content inspection, PII redaction, retention and deletion worker, moderation rate limits, audit trail and migration rollback/forward practice. Auth user deletion must also delete private Storage objects.

## Roadmap

1. Native verification: generate platforms, run analyzer/tests, Android emulator + iOS simulator, accessibility and large-text checks. Replace placeholder product art with licensed imagery.
2. Connect Supabase Auth and private list/alert sync; add offline conflict resolution and account-scoped cache clearing on logout.
3. HTTP catalogue repository + real backend persistence + pagination/error/retry states. Apply Supabase schema in a staging project; validate RLS.
4. Camera barcode scanning with explicit permission flow; GTIN identity pipeline; unknown-product reporting.
5. One authorized retailer feed at a time. Written permission/partner feed or legitimately licensed catalogue; respect provider rate limits and update rights. Do not claim all retailers connected or bypass access controls.
6. Receipt recognition and human confirmation; searchable dated history; price-monitor worker and notification delivery.
7. Basket route cost, live nearby branch geography, promotion eligibility, source-grounded AI assistant and transparent savings ledger.

## Not yet configured

No hosted database, Supabase URL, publishable key, signing certificates, store accounts or production API are included. No APK/IPA build, TestFlight upload or app-store release is represented by this package.
