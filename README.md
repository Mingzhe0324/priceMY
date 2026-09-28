# PriceMY 0.2 — PriceCatcher integration

Flutter Android/iOS application plus FastAPI. Real official price observations replace the fictional catalogue. **This is source code, not an IPA or a deployed service.**

## Included coverage

Initial offline snapshot: Selangor / Petaling, 269 monitored items, 41 premises, 10,075 observations. Newest observation in this downloaded region: **2026-09-24**. Dates in the dataset, rather than portal publication dates, determine freshness.

- Browse/search monitored items, compare latest observations by premise, inspect dated history.
- Save quantities in a device-local shopping list; compare complete single-store baskets and item-price splits.
- Reject prices older than seven days from current ranking using the actual device/server clock; still display older records.
- Optional HTTPS backend refresh, cached locally. Refresh failure retains the last snapshot.
- Screen fade/slide transitions honour reduced motion; product Hero transitions retained.
- No mock login. No fabricated GTIN, membership prices, stock, distances or promotion validity. Barcode and receipt features explicitly unavailable.

PriceCatcher item codes do **not** establish exact brand/variant/GTIN equivalence. The catalogue is for monitored-item comparisons, not a complete barcode catalogue. Premise records are not inferred retailer chains. The `retailers` field currently has explicit `premise_not_chain` identities, preserving independently addressable premises without guessing brand affiliation.

## Run the API

```bash
cd backend
python -m pip install -r requirements.txt
python -m uvicorn app.main:app --host 0.0.0.0 --port 8000
```

Open `/docs`. `GET /v1/catalogue` provides the snapshot, `/v1/products?q=AYAM` searches, `/v1/products/pc-1/offers` compares, `/history` retains dated observations, and `POST /v1/baskets/compare` compares baskets. There is no user-data write endpoint. The application reads atomically replaced snapshots without needing a restart.

## Refresh official data

From the project root:

```bash
python scripts/import_pricecatcher.py --state Selangor --district Petaling
```

The importer downloads official item/premise CSVs and current/previous month records, keeps the latest seven observation dates in the selected region and atomically replaces backend/mobile snapshots. It records URLs, hashes and attribution. For another district, change both parameters; pass empty strings for broader coverage. Do not run simultaneous import jobs. Downloads remain in `backend/downloads` and are not included in the deliverable.

Example daily server cron (paths and Python executable must match deployment):

```cron
30 5 * * * cd /srv/PriceMY && /usr/bin/python3 scripts/import_pricecatcher.py --state Selangor --district Petaling >> /var/log/pricemy-import.log 2>&1
```

This example assumes the server uses UTC (13:30 Malaysia). Monitor job failures and actual observation dates. The schedule is an example; no server or scheduled task has been deployed by this package.

## Android / iPhone

Install Flutter, then run `scripts/bootstrap.ps1` (Windows) or `bash scripts/bootstrap.sh`. Only Android/iOS are supported by this version; networking uses dart:io.

```bash
cd apps/mobile
flutter run --dart-define=API_BASE_URL=https://YOUR-DEPLOYED-API
```

Without API_BASE_URL the official bundled snapshot works offline. With a deployed HTTPS endpoint, Profile → Refresh loads the server snapshot. API_BASE_URL is public configuration, not a secret. No automatic background fetching is claimed.

See `START-HERE-IPHONE.md` for GitHub's macOS build → unsigned IPA → AltStore Classic. Optional GitHub repository variable `API_BASE_URL` is passed into the iOS build. No Apple credentials are needed in GitHub. This environment has not executed the Flutter/macOS build.

## Not yet connected

GPS and geocoded premise coordinates, national deployment, Supabase authentication/storage, barcode mapping, receipt OCR, push alerts, membership offers and travel-based Best Value. Supabase migration 001 is a future schema scaffold, not the active PriceCatcher store. No retailer partnerships are implied.

## Attribution

KPDN / DOSM, [PriceCatcher](https://data.gov.my/data-catalogue/pricecatcher), [CC BY 4.0](https://creativecommons.org/licenses/by/4.0/). Source CSV data is transformed by region/date filtering, item/premise joins and RM-to-sen conversion. Price observations do not guarantee current shelf prices or availability.
