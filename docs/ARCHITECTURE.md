# Data flow

Official PriceCatcher CSVs → Python importer → atomic JSON snapshots → FastAPI → Flutter HTTPS refresh/cache. The same imported snapshot is bundled as a Flutter asset for offline startup. No database has been deployed.

Stable IDs use official item and premise codes. Each observation is unique by date/premise/item. Comparisons retain the latest record per premise; history retains all imported dates. Integer sen avoid floating-point total errors. Unit prices are derived only from unambiguous g/kg/ml/L unit labels. Other units retain the original source label.

Downloaded files have SHA-256 hashes in provenance. Unknown fields remain null. Retailer-chain membership is not guessed from store names. The current retailer-compatible field identifies a premise and carries `identity: premise_not_chain`.

Freshness is seven elapsed days, calculated against the actual clock. This is a product ranking policy, not a source validity period. Latest older observations remain readable. No availability claim is made.

The native shopping list uses an unrestricted cheapest-item split (travel excluded). The API additionally supports exact branch-limited splitting up to three branches, for a maximum of 60 candidate premises. Incomplete baskets have no complete total. Broader national optimisation requires a different solver/region restriction.

For future partner sources, retain source-specific identities and map to canonical GTIN products only when verified. A government monitored item must not be silently promoted to a verified branded SKU.
