from typing import Literal
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field, ConfigDict
from .domain import DATA, compare, basket, normalise_gtin

app = FastAPI(title='PriceMY API', version='0.1.0', description='Public mock catalogue API. All prices are fictional. No user data is accepted.')

class BasketItem(BaseModel):
    model_config = ConfigDict(extra='forbid')
    product_id: str = Field(min_length=1, max_length=64)
    quantity: int = Field(ge=1, le=99, strict=True)

class BasketRequest(BaseModel):
    model_config = ConfigDict(extra='forbid')
    items: list[BasketItem] = Field(max_length=50)
    member: bool = False
    max_stores: int = Field(default=3, ge=1, le=5)

@app.get('/health')
def health():
    return {'status': 'ok', 'mode': 'mock', 'database_connected': False}

@app.get('/v1/retailers')
def retailers():
    return {'mock': True, 'items': DATA['retailers']}

@app.get('/v1/catalogue')
def catalogue():
    return DATA

@app.get('/v1/products')
def products(q: str = Query(default='', max_length=120), category: str | None = None):
    return {'mock': True, 'items': [p for p in DATA['products'] if q.casefold() in ' '.join(str(p[k]) for k in ('brand', 'name', 'variant', 'barcode')).casefold() and (category is None or p['category'] == category)]}

@app.get('/v1/barcodes/{code}')
def barcode(code: str):
    if not code.startswith('DEMO-'):
        try:
            normalise_gtin(code)
        except ValueError as exc:
            raise HTTPException(422, str(exc)) from exc
    product = next((p for p in DATA['products'] if p['barcode'] == code), None)
    if product is None:
        raise HTTPException(404, 'Product not found; do not infer an exact match from a similar name.')
    return {'mock': True, 'product': product, 'match_method': 'demo_identifier'}

@app.get('/v1/products/{product_id}/offers')
def offers(product_id: str, member: bool = False, ranking: Literal['cheapest', 'best_value'] = 'cheapest'):
    try:
        return compare(product_id, member, ranking == 'best_value')
    except KeyError as exc:
        raise HTTPException(404, 'Product not found') from exc

@app.get('/v1/products/{product_id}/history')
def history(product_id: str):
    if not any(p['id'] == product_id for p in DATA['products']):
        raise HTTPException(404, 'Product not found')
    return {'mock': True, 'items': [o for o in DATA['offers'] if o['product_id'] == product_id], 'note': 'One observation per branch; not a time-series trend.'}

@app.post('/v1/baskets/compare')
def compare_basket(request: BasketRequest):
    try:
        return basket([item.model_dump() for item in request.items], request.member, request.max_stores)
    except KeyError as exc:
        raise HTTPException(404, 'Unknown product in basket') from exc
