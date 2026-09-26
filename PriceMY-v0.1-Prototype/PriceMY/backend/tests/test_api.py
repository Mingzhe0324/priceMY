from copy import deepcopy
from fastapi.testclient import TestClient
from app.main import app
from app.domain import DATA, DEMO_NOW, compare, basket, normalise_gtin
client = TestClient(app)

def test_mock_contract_and_dynamic_retailers():
    assert client.get('/health').json()['database_connected'] is False
    assert len(client.get('/v1/retailers').json()['items']) == 22

def test_same_pack_and_variant_only():
    result = compare('p1')
    assert all(o['product_id'] == 'p1' for o in result['offers'])
    assert result['product']['variant'] == 'Full Cream'
    assert result['product']['size'] == 1000
    assert len(result['excluded']) == 1

def test_member_and_value_ranking():
    assert compare('p1')['offers'][0]['retailer_id'] == 'r4'
    aeon = next(o for o in compare('p1', True)['offers'] if o['retailer_id'] == 'r2')
    assert aeon['effective_price_sen'] == aeon['price_sen'] - 60
    rows = compare('p2', best_value=True)['offers']
    assert rows == sorted(rows, key=lambda o: o['estimated_total_sen'])

def test_stale_expired_future_and_unavailable_prices_excluded():
    data = deepcopy(DATA)
    for o in data['offers']:
        if o['product_id'] == 'p1':
            o['available'] = False
    assert compare('p1', data=data)['offers'] == []
    o = data['offers'][0]
    o['available'] = True
    o['valid_until'] = '2026-09-01T00:00:00Z'
    assert compare('p1', data=data)['offers'] == []
    o['valid_until'] = '2027-01-01T00:00:00Z'
    o['observed_at'] = '2027-01-01T00:00:00Z'
    assert compare('p1', data=data)['offers'] == []

def test_basket_counts_duplicates_quantities_and_store_limit():
    result = basket([{'product_id':'p1','quantity':2}, {'product_id':'p1','quantity':1},{'product_id':'p2','quantity':2}], max_stores=1)
    assert result['split']['total_sen'] == result['single_store'][0]['total_sen']
    assert sum(l['quantity'] for l in result['split']['lines']) == 5
    split = basket([{'product_id':p['id'],'quantity':1} for p in DATA['products']])
    assert split['split']['total_sen'] <= split['single_store'][0]['total_sen']
    assert len(split['split']['branch_ids']) <= 3

def test_partial_baskets_not_ranked_as_complete():
    data=deepcopy(DATA)
    data['offers']=[o for o in data['offers'] if not (o['product_id']=='p2' and o['branch_id']=='b1')]
    result=basket([{'product_id':'p1','quantity':1},{'product_id':'p2','quantity':1}],data=data)
    assert not any(p['branch_ids']==['b1'] for p in result['single_store'])

def test_validation_and_not_found():
    assert client.get('/v1/barcodes/DEMO-0001').status_code == 200
    assert client.get('/v1/barcodes/bad').status_code == 422
    assert client.get('/v1/products/missing/offers').status_code == 404
    assert client.post('/v1/baskets/compare',json={'items':[{'product_id':'p1','quantity':0}]}).status_code == 422
    assert client.post('/v1/baskets/compare',json={'items':[{'product_id':'missing','quantity':1}]}).status_code == 404
    assert client.post('/v1/baskets/compare',json={'items':[]}).json()['split'] is None

def test_gtin_check_digit_and_canonical_form():
    assert normalise_gtin('4006381333931') == '04006381333931'
    import pytest
    with pytest.raises(ValueError): normalise_gtin('4006381333932')
