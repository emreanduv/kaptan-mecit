# Uygulama içi ürünü (Tam Sürüm, Non-Consumable) App Store Connect'te kurar (CI). Tekrar çalıştırılabilir: var olanı atlar.
# Ürün + TR/EN adlar + fiyat (ABD 1,99 $ taban, diğer ülkeler Apple eşdeğeri) + bütün ülkeler + inceleme ekran görüntüsü.
import jwt, time, json, os, hashlib, urllib.request, urllib.error
KID = os.environ['ASC_KEY_ID']; ISS = os.environ['ASC_ISSUER_ID']; BUNDLE = os.environ['BUNDLE']
URUN = os.environ['URUN']; FIYAT = os.environ.get('FIYAT', '1.99'); FOTO = os.environ.get('FOTO', '')
KEY = open(os.path.expanduser(f'~/private_keys/AuthKey_{KID}.p8')).read()
log = []
def tok(): return jwt.encode({'iss': ISS, 'exp': int(time.time()) + 900, 'aud': 'appstoreconnect-v1'}, KEY, algorithm='ES256', headers={'kid': KID})
def api(m, p, b=None, ham=None, basliklar=None):
    url = p if p.startswith('http') else 'https://api.appstoreconnect.apple.com/' + p
    h = basliklar or {'Authorization': 'Bearer ' + tok(), 'Content-Type': 'application/json'}
    r = urllib.request.Request(url, method=m, data=ham if ham is not None else (json.dumps(b).encode() if b is not None else None), headers=h)
    try:
        with urllib.request.urlopen(r) as f: t = f.read(); return json.loads(t) if t and not ham else {}
    except urllib.error.HTTPError as e: log.append(f'{m} {p[:90]} -> {e.code} {e.read().decode()[:700]}'); return None

AID = api('GET', f'v1/apps?filter[bundleId]={BUNDLE}')['data'][0]['id']
out = {'app': AID}
var = api('GET', f'v1/apps/{AID}/inAppPurchasesV2?filter[productId]={URUN}&limit=5')
iap = var and var['data'] and var['data'][0]
if not iap:
    r = api('POST', 'v2/inAppPurchases', {'data': {'type': 'inAppPurchases', 'attributes': {
        'name': 'Tam Sürüm', 'productId': URUN, 'inAppPurchaseType': 'NON_CONSUMABLE', 'familySharable': False,
        'reviewNote': 'One-time Full Version unlock. The first half of the first season is free; the Full Version unlocks the rest of the season, later seasons and Challenge Mode. To find it: Main menu > "Full Version" button, or Settings > Full Version > Buy. "Restore purchase" is in the same window and in Settings.'},
        'relationships': {'app': {'data': {'type': 'apps', 'id': AID}}}}})
    iap = r and r['data']
out['urun'] = iap and [iap['id'], iap['attributes'].get('state')]
if iap:
    IID = iap['id']
    # adlar ve açıklamalar (açıklama en fazla 55 karakter)
    var = {l['attributes']['locale'] for l in (api('GET', f'v2/inAppPurchases/{IID}/inAppPurchaseLocalizations') or {'data': []})['data']}
    for loc, ad, ac in [('tr', 'Tam Sürüm', 'Bütün sezonlar ve Challenge Modu, tek seferlik ödeme'), ('en-US', 'Full Version', 'Every season and Challenge Mode, one-time payment'), ('en-GB', 'Full Version', 'Every season and Challenge Mode, one-time payment')]:
        if loc not in var:
            api('POST', 'v1/inAppPurchaseLocalizations', {'data': {'type': 'inAppPurchaseLocalizations', 'attributes': {'locale': loc, 'name': ad, 'description': ac},
                'relationships': {'inAppPurchaseV2': {'data': {'type': 'inAppPurchases', 'id': IID}}}}})
    # fiyat: ABD taban 1,99 $
    sch = api('GET', f'v2/inAppPurchases/{IID}/iapPriceSchedule')
    if not (sch and sch.get('data')):
        pp, url = None, f'v2/inAppPurchases/{IID}/pricePoints?filter[territory]=USA&limit=200'
        while url and not pp:
            r = api('GET', url) or {}
            pp = next((x for x in r.get('data', []) if x['attributes'].get('customerPrice') == FIYAT), None)
            url = (r.get('links') or {}).get('next')
        out['fiyatNoktasi'] = pp and pp['id']
        if pp:
            api('POST', 'v1/inAppPurchasePriceSchedules', {'data': {'type': 'inAppPurchasePriceSchedules', 'relationships': {
                'inAppPurchase': {'data': {'type': 'inAppPurchases', 'id': IID}}, 'baseTerritory': {'data': {'type': 'territories', 'id': 'USA'}},
                'manualPrices': {'data': [{'type': 'inAppPurchasePrices', 'id': '${f0}'}]}}},
                'included': [{'type': 'inAppPurchasePrices', 'id': '${f0}', 'attributes': {'startDate': None},
                    'relationships': {'inAppPurchasePricePoint': {'data': {'type': 'inAppPurchasePricePoints', 'id': pp['id']}}}}]})
    # bütün ülkeler
    av = api('GET', f'v2/inAppPurchases/{IID}/inAppPurchaseAvailability')
    if not (av and av.get('data')):
        ter, url = [], 'v1/territories?limit=200'
        while url:
            r = api('GET', url) or {}; ter += [{'type': 'territories', 'id': t['id']} for t in r.get('data', [])]; url = (r.get('links') or {}).get('next')
        api('POST', 'v1/inAppPurchaseAvailabilities', {'data': {'type': 'inAppPurchaseAvailabilities', 'attributes': {'availableInNewTerritories': True},
            'relationships': {'inAppPurchase': {'data': {'type': 'inAppPurchases', 'id': IID}}, 'availableTerritories': {'data': ter}}}})
        out['ulke'] = len(ter)
    # inceleme ekran görüntüsü
    ss = api('GET', f'v2/inAppPurchases/{IID}/appStoreReviewScreenshot')
    if FOTO and not (ss and ss.get('data')):
        veri = open(FOTO, 'rb').read()
        r = api('POST', 'v1/inAppPurchaseAppStoreReviewScreenshots', {'data': {'type': 'inAppPurchaseAppStoreReviewScreenshots',
            'attributes': {'fileName': os.path.basename(FOTO), 'fileSize': len(veri)}, 'relationships': {'inAppPurchaseV2': {'data': {'type': 'inAppPurchases', 'id': IID}}}}})
        if r:
            sid = r['data']['id']
            for op in r['data']['attributes']['uploadOperations']:
                parca = veri[op['offset']:op['offset'] + op['length']]
                api(op['method'], op['url'], ham=parca, basliklar={h['name']: h['value'] for h in op['requestHeaders']})
            api('PATCH', f'v1/inAppPurchaseAppStoreReviewScreenshots/{sid}', {'data': {'type': 'inAppPurchaseAppStoreReviewScreenshots', 'id': sid,
                'attributes': {'uploaded': True, 'sourceFileChecksum': hashlib.md5(veri).hexdigest()}}})
            out['foto'] = 'yüklendi'
    son = api('GET', f'v2/inAppPurchases/{IID}')
    out['durum'] = son and son['data']['attributes'].get('state')
out['log'] = log
json.dump(out, open('iap.json', 'w'), ensure_ascii=False, indent=1)
print(json.dumps(out, ensure_ascii=False, indent=1))
