"""Pure comparison logic. Currency is integer sen; no floats for totals."""
from datetime import datetime, timedelta
from decimal import Decimal, ROUND_HALF_UP
from itertools import combinations
from pathlib import Path
import json

DATA = json.loads(Path(__file__).with_name('catalogue.json').read_text())
DEMO_NOW = datetime.fromisoformat(DATA['as_of'].replace('Z', '+00:00'))

def stamp(value):
    return datetime.fromisoformat(value.replace('Z', '+00:00'))

def effective(offer, member=False):
    return offer['member_price_sen'] if member and offer.get('member_price_sen') is not None else offer['price_sen']

def eligible(offer, now):
    age = now - stamp(offer['observed_at'])
    return (offer['available'] and timedelta(0) <= age <= timedelta(days=14)
            and stamp(offer['valid_until']) > now and offer['source'] != 'older_unverified')

def compare(product_id, member=False, best_value=False, data=DATA, now=DEMO_NOW):
    product = next((p for p in data['products'] if p['id'] == product_id), None)
    if product is None:
        raise KeyError(product_id)
    rows, excluded = [], []
    for offer in data['offers']:
        if offer['product_id'] != product_id:
            continue
        branch = next(b for b in data['branches'] if b['id'] == offer['branch_id'])
        retailer = next(r for r in data['retailers'] if r['id'] == offer['retailer_id'])
        price = effective(offer, member)
        travel = int((Decimal(str(branch['distance_km'])) * 100).quantize(Decimal('1'), rounding=ROUND_HALF_UP))
        item = {**offer, 'retailer_name': retailer['name'], 'branch_name': branch['name'],
                'distance_km': branch['distance_km'], 'effective_price_sen': price,
                'estimated_return_trip_sen': travel, 'estimated_total_sen': price + travel,
                'unit_price_sen_per_100': round(price * 100 / product['size'], 2),
                'unit_basis': f"100{product['unit']}"}
        (rows if eligible(offer, now) else excluded).append(item)
    rows.sort(key=lambda o: (o['estimated_total_sen'] if best_value else o['effective_price_sen'], o['id']))
    return {'mock': True, 'as_of': now.isoformat(), 'product': product, 'offers': rows,
            'excluded': excluded, 'ranking': 'best_value' if best_value else 'cheapest',
            'method': 'Item + return distance at RM0.50/km; no tolls, parking or time.' if best_value else 'Lowest eligible item price; stale >14 days excluded.'}

def basket(items, member=False, max_stores=3, data=DATA, now=DEMO_NOW):
    """Exact minimum item subtotal for <= max_stores branches; route cost excluded."""
    quantities = {}
    for item in items:
        quantities[item['product_id']] = quantities.get(item['product_id'], 0) + item['quantity']
    if not quantities:
        return {'mock': True, 'single_store': [], 'split': None, 'unavailable_product_ids': []}
    quotes = {pid: compare(pid, member, data=data, now=now)['offers'] for pid in quantities}
    unavailable = [pid for pid, rows in quotes.items() if not rows]
    if unavailable:
        return {'mock': True, 'single_store': [], 'split': None, 'unavailable_product_ids': unavailable}
    branch_ids = sorted({o['branch_id'] for rows in quotes.values() for o in rows})
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
    return {'mock': True, 'single_store': single, 'split': best, 'unavailable_product_ids': [],
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
