from typing import Literal
from fastapi import FastAPI, HTTPException, Query
from pydantic import BaseModel, Field, ConfigDict
from .domain import load_data, compare, basket, normalise_gtin

app = FastAPI(title='PriceMY API', version='0.2.0', description='Official PriceCatcher observations; not live shelf prices. No user data accepted.')

class BasketItem(BaseModel):
    model_config = ConfigDict(extra='forbid')
    product_id: str = Field(min_length=1, max_length=64)
    quantity: int = Field(ge=1, le=99, strict=True)

class BasketRequest(BaseModel):
    model_config = ConfigDict(extra='forbid')
    items: list[BasketItem] = Field(max_length=50)
    member: bool = False
    max_stores: int = Field(default=3, ge=1, le=3)

@app.get('/health')
def health():
    return {'status': 'ok', 'mode': 'pricecatcher_snapshot', 'database_connected': False}

@app.get('/v1/retailers')
def retailers():
    return {'mock': False, 'items': load_data()['retailers']}

@app.get('/v1/catalogue')
def catalogue():
    return load_data()

@app.get('/v1/products')
def products(q: str = Query(default='', max_length=120), category: str | None = None):
    return {'mock': False, 'items': [p for p in load_data()['products'] if q.casefold() in ' '.join(str(p[k]) for k in ('brand', 'name', 'variant', 'barcode')).casefold() and (category is None or p['category'] == category)]}

@app.get('/v1/barcodes/{code}')
def barcode(code: str):
    try:
        normalise_gtin(code)
    except ValueError as exc:
        raise HTTPException(422, str(exc)) from exc
    raise HTTPException(404, 'PriceCatcher has no GTIN mapping. Search the monitored item by name.')

@app.get('/v1/products/{product_id}/offers')
def offers(product_id: str, member: bool = False, ranking: Literal['cheapest', 'best_value'] = 'cheapest'):
    if ranking == 'best_value':
        raise HTTPException(422, 'Travel data unavailable; use cheapest ranking')
    try:
        return compare(product_id, member)
    except KeyError as exc:
        raise HTTPException(404, 'Product not found') from exc

@app.get('/v1/products/{product_id}/history')
def history(product_id: str):
    if not any(p['id'] == product_id for p in load_data()['products']):
        raise HTTPException(404, 'Product not found')
    return {'mock': False, 'items': [o for o in load_data()['offers'] if o['product_id'] == product_id], 'note': 'Dated monitored observations. Compare history within one premise only.'}

@app.post('/v1/baskets/compare')
def compare_basket(request: BasketRequest):
    try:
        return basket([item.model_dump() for item in request.items], request.member, request.max_stores)
    except KeyError as exc:
        raise HTTPException(404, 'Unknown product in basket') from exc
    except ValueError as exc:
        raise HTTPException(422, str(exc)) from exc
