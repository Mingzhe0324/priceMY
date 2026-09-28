import importlib.util
from pathlib import Path
from datetime import date,timedelta,datetime,timezone
import csv
spec=importlib.util.spec_from_file_location('importer',Path(__file__).resolve().parents[2]/'scripts/import_pricecatcher.py')
mod=importlib.util.module_from_spec(spec);spec.loader.exec_module(mod)
def write(path,header,rows):
    with path.open('w',newline='') as f:
        w=csv.writer(f);w.writerow(header);w.writerows(rows)
def source(tmp_path):
    write(tmp_path/'lookup_item.csv',['item_code','item','unit','item_category'],[['1','MILK','1L','MILK'],['2','EGG','10 biji','EGGS']])
    write(tmp_path/'lookup_premise.csv',['premise_code','premise','address','state','district'],[['1','Shop A','Address','Selangor','Petaling'],['2','Shop B','Elsewhere','Johor','Segamat']])
    today=datetime.now(timezone(timedelta(hours=8))).date();month=today.strftime('%Y-%m')
    write(tmp_path/f'pricecatcher_{month}.csv',['date','premise_code','item_code','price'],[[today,'1','1','7.29'],[today,'1','2','5.00'],[today,'2','1','1.00'],[today+timedelta(days=1),'1','1','1.00']])
    return month

def test_region_decimal_units_and_provenance(tmp_path):
    month=source(tmp_path);d=mod.build(tmp_path,month,'Selangor','Petaling')
    assert len(d['branches'])==1 and len(d['offers'])==2
    assert next(o for o in d['offers'] if o['product_id']=='pc-1')['price_sen']==729
    p={p['id']:p for p in d['products']}
    assert p['pc-1']['size']==1000 and p['pc-1']['unit']=='ml'
    assert p['pc-2']['size'] is None and p['pc-2']['pack_label']=='10 biji'
    assert all(len(f['sha256'])==64 for f in d['provenance']['files'])

def test_empty_region_fails_without_fabricated_fallback(tmp_path):
    import pytest
    month=source(tmp_path)
    with pytest.raises(ValueError,match='No observations'):mod.build(tmp_path,month,'Unknown','Unknown')

def test_month_rollover_keeps_previous_month(tmp_path):
    month=source(tmp_path)
    start=date.fromisoformat(month+'-01');previous=start-timedelta(days=1)
    write(tmp_path/f'pricecatcher_{month}.csv',['date','premise_code','item_code','price'],[[start,'1','1','8.00']])
    write(tmp_path/f'pricecatcher_{previous:%Y-%m}.csv',['date','premise_code','item_code','price'],[[previous,'1','1','7.00']])
    assert len(mod.build(tmp_path,month,'Selangor','Petaling')['offers'])==2
