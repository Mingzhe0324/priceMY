from copy import deepcopy
from datetime import datetime, timezone, timedelta
from fastapi.testclient import TestClient
from app.main import app
from app.domain import DATA, compare, basket, normalise_gtin
client=TestClient(app)
NOW=datetime(2026,9,25,tzinfo=timezone.utc)

def fixture():
    return {'products':[{'id':'a','size':1000,'unit':'g'},{'id':'b','size':None,'unit':''}],
      'branches':[{'id':b,'name':b,'address':'test'} for b in ['s1','s2']],
      'offers':[{'id':f'{p}-{b}-{day}','product_id':p,'branch_id':b,'retailer_id':b,'price_sen':price,'observed_at':f'2026-09-{day}T00:00:00Z'} for p,b,day,price in [('a','s1','24',500),('a','s1','23',100),('a','s2','24',600),('b','s2','24',200)]]}

def test_official_snapshot_and_no_invented_fields():
    assert DATA['mock'] is False
    assert DATA['provenance']['license']=='CC BY 4.0'
    assert all(not p['barcode'] for p in DATA['products'])
    assert all(o['member_price_sen'] is None and o['available'] is None and o['valid_until'] is None for o in DATA['offers'])
    assert all(b['distance_km'] is None for b in DATA['branches'])

def test_latest_per_premise_not_historical_minimum():
    r=compare('a',data=fixture(),now=NOW)
    assert [o['price_sen'] for o in r['offers']]==[500,600]

def test_clock_expiry_and_future_exclusion():
    d=fixture()
    assert compare('a',data=d,now=NOW+timedelta(days=10))['offers']==[]
    assert compare('a',data=d,now=NOW-timedelta(days=20))['offers']==[]

def test_unknown_unit_has_no_fake_unit_price():
    assert compare('b',data=fixture(),now=NOW)['offers'][0]['unit_price_sen_per_100'] is None

def test_complete_basket_only_and_split():
    r=basket([{'product_id':'a','quantity':2},{'product_id':'b','quantity':1}],data=fixture(),now=NOW)
    assert len(r['single_store'])==1
    assert r['single_store'][0]['total_sen']==1400
    assert r['split']['total_sen']==1200

def test_missing_prices_never_zero_total():
    r=basket([{'product_id':'a','quantity':1}],data=fixture(),now=NOW+timedelta(days=10))
    assert r['split'] is None and r['unavailable_product_ids']==['a']

def test_store_limit_and_duplicate_quantity():
    r=basket([{'product_id':'a','quantity':1},{'product_id':'a','quantity':1},{'product_id':'b','quantity':1}],max_stores=1,data=fixture(),now=NOW)
    assert r['split']['total_sen']==1400

def test_real_api_and_unknown_barcode():
    assert client.get('/v1/catalogue').json()['mock'] is False
    assert client.get('/v1/barcodes/4006381333931').status_code==404
    assert client.get('/v1/barcodes/DEMO-0001').status_code==422
    assert client.get('/v1/products/missing/offers').status_code==404
    assert client.get('/v1/products/pc-1/offers?ranking=best_value').status_code==422
    assert client.post('/v1/baskets/compare',json={'items':[{'product_id':'a','quantity':0}]}).status_code==422

def test_gtin_checksum():
    import pytest
    assert normalise_gtin('4006381333931')=='04006381333931'
    with pytest.raises(ValueError):normalise_gtin('4006381333932')
