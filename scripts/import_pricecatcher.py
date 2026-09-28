"""Official bulk importer. Atomic snapshots; never infer GTIN, stock or validity."""
import argparse, csv, hashlib, json, re, urllib.request
from datetime import date, datetime, timedelta, timezone
from decimal import Decimal, ROUND_HALF_UP
from pathlib import Path
BASE = 'https://storage.data.gov.my/pricecatcher/'
ROOT = Path(__file__).resolve().parents[1]

def rows(path):
    with path.open(encoding='utf-8-sig', newline='') as f:
        yield from csv.DictReader(f)

def build(folder, month, state, district, days=7):
    premises = {r['premise_code']: r for r in rows(folder/'lookup_premise.csv')
                if (not state or r['state'].casefold()==state.casefold())
                and (not district or r['district'].casefold()==district.casefold())}
    items = {r['item_code']: r for r in rows(folder/'lookup_item.csv')}
    # Include previous month so a rolling window works across month boundaries.
    previous=(date.fromisoformat(month+'-01')-timedelta(days=1)).strftime('%Y-%m')
    paths = [folder/f'pricecatcher_{m}.csv' for m in [previous,month] if (folder/f'pricecatcher_{m}.csv').exists()]
    records = {}
    for path in paths:
        for r in rows(path):
            if r['premise_code'] not in premises or r['item_code'] not in items: continue
            if date.fromisoformat(r['date']) > datetime.now(timezone(timedelta(hours=8))).date(): continue
            price = Decimal(r['price'])
            if not price.is_finite() or price <= 0: continue
            key = (r['date'],r['premise_code'],r['item_code'])
            records[key] = int((price*100).quantize(Decimal('1'),rounding=ROUND_HALF_UP))
    if not records: raise ValueError('No observations for the requested region; existing snapshot retained')
    latest = max(k[0] for k in records)
    cutoff = (date.fromisoformat(latest)-timedelta(days=days-1)).isoformat()
    records = {k:v for k,v in records.items() if k[0]>=cutoff}
    used_items = sorted({k[2] for k in records},key=int)
    used_stores = sorted({k[1] for k in records},key=int)
    products=[]
    for code in used_items:
        r=items[code]; unit=r['unit']; m=re.fullmatch(r'\s*(\d+(?:\.\d+)?)\s*(kg|g|ml|l)\s*',unit,re.I)
        size, basis = (float(m[1])*(1000 if m[2].lower() in ('kg','l') else 1), 'g' if m[2].lower() in ('kg','g') else 'ml') if m else (None,None)
        products.append(dict(id='pc-'+code,name=r['item'],brand='',variant='',barcode='',size=size,unit=basis or '',pack_label=unit,category=r['item_category'],color='E7EEDC',match_method='monitored_item',item_code=code))
    branches=[dict(id='pc-store-'+c,retailer_id='pc-premise-'+c,name=premises[c]['premise'],address=premises[c]['address'],state=premises[c]['state'],district=premises[c]['district'],distance_km=None) for c in used_stores]
    offers=[dict(id='pc-'+'-'.join(k),product_id='pc-'+k[2],branch_id='pc-store-'+k[1],retailer_id='pc-premise-'+k[1],price_sen=v,member_price_sen=None,observed_at=k[0]+'T00:00:00+08:00',source='government_price_monitoring',available=None,valid_until=None) for k,v in sorted(records.items())]
    return dict(mock=False,as_of=latest+'T00:00:00+08:00',imported_at=datetime.now(timezone.utc).isoformat(),region={'state':state,'district':district},provenance={'publisher':'KPDN / DOSM · data.gov.my','license':'CC BY 4.0','url':'https://data.gov.my/data-catalogue/pricecatcher','files':[{'url':BASE+p.name,'sha256':hashlib.sha256(p.read_bytes()).hexdigest()} for p in paths+[folder/'lookup_item.csv',folder/'lookup_premise.csv']]},products=products,branches=branches,retailers=[{'id':b['retailer_id'],'name':b['name'],'identity':'premise_not_chain'} for b in branches],offers=offers)

def main():
    p=argparse.ArgumentParser();p.add_argument('--month',default=datetime.now(timezone(timedelta(hours=8))).strftime('%Y-%m'));p.add_argument('--state',default='Selangor');p.add_argument('--district',default='Petaling');p.add_argument('--files',type=Path);a=p.parse_args()
    folder=a.files or ROOT/'backend/downloads';folder.mkdir(parents=True,exist_ok=True)
    start=date.fromisoformat(a.month+'-01'); previous=(start-timedelta(days=1)).strftime('%Y-%m')
    if not a.files:
        for name in ['lookup_item.csv','lookup_premise.csv',f'pricecatcher_{previous}.csv',f'pricecatcher_{a.month}.csv']:
            temp=folder/(name+'.tmp');print('Downloading',name,flush=True)
            with urllib.request.urlopen(BASE+name,timeout=120) as src,temp.open('wb') as dst:
                import shutil;shutil.copyfileobj(src,dst)
            temp.replace(folder/name)
    data=build(folder,a.month,a.state,a.district)
    encoded=json.dumps(data,ensure_ascii=False,separators=(',',':'))
    for target in [ROOT/'backend/app/catalogue.json',ROOT/'apps/mobile/assets/catalogue.json']:
        tmp=target.with_suffix('.tmp');tmp.write_text(encoded,encoding='utf-8');tmp.replace(target)
    print(json.dumps({'products':len(data['products']),'branches':len(data['branches']),'observations':len(data['offers']),'latest':data['as_of']}))
if __name__=='__main__':main()
