"""Future integration boundaries; intentionally no fake live implementation."""
from typing import Protocol
from dataclasses import dataclass
from datetime import datetime

@dataclass(frozen=True)
class ImportedObservation:
    retailer_id: str
    branch_id: str
    retailer_sku: str
    price_sen: int
    observed_at: datetime
    source_url: str | None
    provenance: str

class RetailerAdapter(Protocol):
    """Adapters execute server-side only, with permission, limits and provenance."""
    def fetch(self, since: datetime) -> list[ImportedObservation]: ...

class MatchingProvider(Protocol):
    """Returns candidates, never silently converts fuzzy similarity into exactness."""
    def candidates(self, brand: str, name: str, variant: str, size: int, unit: str) -> list[dict]: ...

class ReceiptProvider(Protocol):
    def extract(self, private_object_key: str) -> list[dict]: ...

class ShoppingAssistant(Protocol):
    """Every recommendation must reference supplied offer IDs and timestamps."""
    def explain(self, question: str, eligible_offers: list[dict]) -> dict: ...
