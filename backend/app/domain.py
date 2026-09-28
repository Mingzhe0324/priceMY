"""Pure comparison logic. Currency is integer sen; no floats for totals."""
from datetime import datetime, timedelta, timezone
from decimal import Decimal, ROUND_HALF_UP
from itertools import combinations
from pathlib import Path
import json

CATALOGUE_PATH = Path(__file__).with_name('catalogue.json')
_snapshot = None
_snapshot_mtime = None

def load_data():
    global _snapshot, _snapshot_mtime
    mtime = CATALOGUE_PATH.stat().st_mtime_ns
    if _snapshot is None or mtime != _snapshot_mtime:
        candidate = json.loads(CATALOGUE_PATH.read_text())
        if candidate.get('mock') is not False: raise ValueError('Expected official snapshot')
        _snapshot, _snapshot_mtime = candidate, mtime
    return _snapshot

DATA = load_data()


def stamp(value):
    return datetime.fromisoformat(value.replace('Z', '+00:00'))

def effective(offer, member=False):
    return offer['member_price_sen'] if member and offer.get('member_price_sen') is not None else offer['price_sen']

def eligible(offer, now):
    age = now - stamp(offer['observed_at'])
    return timedelta(0) <= age <= timedelta(days=7)

def compare(product_id, member=False, best_value=False, data=None, now=None):
    data = load_data() if data is None else data
    now = now or datetime.now(timezone.utc)
    product = next((p for p in data['products'] if p['id'] == product_id), None)
    if product is None: raise KeyError(product_id)
    branches = {b['id']: b for b in data['branches']}
    newest = {}
    for o in data['offers']:
        if o['product_id'] == product_id and stamp(o['observed_at']) <= now:
            if o['branch_id'] not in newest or stamp(o['observed_at']) > stamp(newest[o['branch_id']]['observed_at']):
                newest[o['branch_id']] = o
    rows, excluded = [], []
    for o in newest.values():
        b = branches[o['branch_id']]
        row = {**o, 'retailer_name': b['name'], 'branch_name': b['name'], 'address': b['address'],
               'effective_price_sen': o['price_sen'], 'distance_km': None,
               'unit_price_sen_per_100': round(o['price_sen']*100/product['size'],2) if product['size'] else None,
               'unit_basis': '100'+product['unit'] if product['size'] else None}
        (rows if eligible(o,now) else excluded).append(row)
    rows.sort(key=lambda o:(o['price_sen'],o['id']))
    return {'mock':False,'as_of':now.isoformat(),'product':product,'offers':rows,'excluded':excluded,
            'ranking':'cheapest','best_value_available':False,
            'method':'Latest observation per premise; older than 7 days excluded. Stock and current shelf price are unknown.'}

def basket(items, member=False, max_stores=3, data=None, now=None):
    """Exact minimum item subtotal for <= max_stores branches; route cost excluded."""
    data = load_data() if data is None else data
    now = now or datetime.now(timezone.utc)
    quantities = {}
    for item in items:
        quantities[item['product_id']] = quantities.get(item['product_id'], 0) + item['quantity']
    if not quantities:
        return {'mock': False, 'single_store': [], 'split': None, 'unavailable_product_ids': []}
    quotes = {pid: compare(pid, member, data=data, now=now)['offers'] for pid in quantities}
    unavailable = [pid for pid, rows in quotes.items() if not rows]
    if unavailable:
        return {'mock': False, 'single_store': [], 'split': None, 'unavailable_product_ids': unavailable}
    branch_ids = sorted({o['branch_id'] for rows in quotes.values() for o in rows})
    if len(branch_ids) > 60: raise ValueError('Select a smaller region (maximum 60 premises for basket optimisation)')
    def plan(branches):
        lines = []
        for pid, qty in quantities.items():
            rows = [o for o in quotes[pid] if o['branch_id'] in branches]
            if not rows:
                return None
            offer = min(rows, key=lambda o: (o['effective_price_sen'], o['id']))
            lines.append({'product_id': pid, 'quantity': qty, 'offer_id': offer['id'],
                          'branch_id': offer['branch_id'], 'retailer_name': offer['retailer_name'],
                          'subtotal_sen': offer['effective_price_sen'] * qty})
        return {'total_sen': sum(line['subtotal_sen'] for line in lines), 'lines': lines,
                'branch_ids': sorted({line['branch_id'] for line in lines})}
    single = [p for b in branch_ids if (p := plan([b])) is not None]
    single.sort(key=lambda p: p['total_sen'])
    candidates = [p for n in range(1, min(max_stores, len(branch_ids)) + 1)
                  for bs in combinations(branch_ids, n) if (p := plan(bs)) is not None]
    best = min(candidates, key=lambda p: (p['total_sen'], len(p['branch_ids']))) if candidates else None
    return {'mock': False, 'single_store': single, 'split': best, 'unavailable_product_ids': [],
            'max_stores': max_stores, 'travel_included': False,
            'potential_item_saving_sen': single[0]['total_sen'] - best['total_sen'] if single and best else None}

def normalise_gtin(code):
    if not code.isascii() or not code.isdigit() or len(code) not in (8, 12, 13, 14):
        raise ValueError('Expected GTIN-8, UPC-12, EAN-13 or GTIN-14 digits')
    body = code[:-1]
    check = (10 - sum(int(d) * (3 if i % 2 == 0 else 1) for i, d in enumerate(reversed(body))) % 10) % 10
    if check != int(code[-1]):
        raise ValueError('Invalid GTIN checksum')
    return code.zfill(14)
