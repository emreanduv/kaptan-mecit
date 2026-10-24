# CBM App Store sayfası (CI): düzenlenebilir sürümün açıklama/anahtar kelime/tanıtım/yenilikler metinlerini,
# alt başlığı yazar; ekran görüntülerini (iPhone 6.9" + iPad 13") baştan yükler. İncelemeye GÖNDERMEZ.
import jwt, time, json, os, hashlib, urllib.request, urllib.error
KID=os.environ['ASC_KEY_ID']; ISS=os.environ['ASC_ISSUER_ID']; BUNDLE=os.environ.get('BUNDLE','com.championchess.manager')
EKRAN=os.environ.get('EKRAN','1')=='1'
KEY=open(os.path.expanduser(f'~/private_keys/AuthKey_{KID}.p8')).read()
log=[]; out={'adimlar':[]}
def ok(s): out['adimlar'].append(s); print(s)
def tok(): return jwt.encode({'iss':ISS,'exp':int(time.time())+900,'aud':'appstoreconnect-v1'},KEY,algorithm='ES256',headers={'kid':KID})
def api(m,p,b=None):
    r=urllib.request.Request('https://api.appstoreconnect.apple.com/'+p,method=m,data=json.dumps(b).encode() if b is not None else None,headers={'Authorization':'Bearer '+tok(),'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(r) as f: t=f.read(); return json.loads(t) if t else {}
    except urllib.error.HTTPError as e: log.append(f'{m} {p} -> {e.code} {e.read().decode()[:700]}'); return None
M=json.load(open('store/champion/metin.json'))
def dil(loc): return M['tr'] if loc.startswith('tr') else M['en']
SIRA=['4-mac','8-macsonu','3-taktik','2-genel','6-sd','5-lig','7-posta','1-menu']
AID=api('GET',f'v1/apps?filter[bundleId]={BUNDLE}')['data'][0]['id']
vs=api('GET',f'v1/apps/{AID}/appStoreVersions?filter[platform]=IOS&limit=10')['data']
v=next((x for x in vs if x['attributes']['appStoreState'] in ('PREPARE_FOR_SUBMISSION','DEVELOPER_REJECTED','REJECTED','METADATA_REJECTED')),None)
if not v: raise SystemExit('düzenlenebilir sürüm yok (önce asc-surum)')
VID=v['id']; out['surum']=[v['attributes']['versionString'],v['attributes']['appStoreState']]
api('PATCH',f'v1/appStoreVersions/{VID}',{'data':{'type':'appStoreVersions','id':VID,'attributes':{'copyright':'2026 Mr. Anduv!'}}})
locs=api('GET',f'v1/appStoreVersions/{VID}/appStoreVersionLocalizations')['data']
for l in locs:
    d=dil(l['attributes']['locale'])
    a={k:d[k] for k in ('description','keywords','promotionalText','whatsNew')}
    r=api('PATCH',f'v1/appStoreVersionLocalizations/{l["id"]}',{'data':{'type':'appStoreVersionLocalizations','id':l['id'],'attributes':a}})
    if r is None:   # ilk sürümde whatsNew yazılamaz
        a.pop('whatsNew'); r=api('PATCH',f'v1/appStoreVersionLocalizations/{l["id"]}',{'data':{'type':'appStoreVersionLocalizations','id':l['id'],'attributes':a}})
    if r is not None: ok('metin '+l['attributes']['locale'])
# alt başlık
infos=api('GET',f'v1/apps/{AID}/appInfos')['data']
info=next((i for i in infos if i['attributes'].get('appStoreState') not in ('READY_FOR_SALE',) and i['attributes'].get('state') not in ('READY_FOR_DISTRIBUTION',)),None)
if info:
    for l in api('GET',f'v1/appInfos/{info["id"]}/appInfoLocalizations')['data']:
        out.setdefault('ad',{})[l['attributes']['locale']]=l['attributes'].get('name')
        r=api('PATCH',f'v1/appInfoLocalizations/{l["id"]}',{'data':{'type':'appInfoLocalizations','id':l['id'],'attributes':{'subtitle':dil(l['attributes']['locale'])['subtitle']}}})
        if r is not None: ok('alt başlık '+l['attributes']['locale'])
def yukle(SID,files):
    n=0
    for f in files:
        b=open(f,'rb').read()
        r=api('POST','v1/appScreenshots',{'data':{'type':'appScreenshots','attributes':{'fileName':os.path.basename(f),'fileSize':len(b)},'relationships':{'appScreenshotSet':{'data':{'type':'appScreenshotSets','id':SID}}}}})
        if not r: continue
        sid=r['data']['id']
        for op in r['data']['attributes']['uploadOperations']:
            q=urllib.request.Request(op['url'],method=op['method'],data=b[op['offset']:op['offset']+op['length']],headers={h['name']:h['value'] for h in op['requestHeaders']})
            urllib.request.urlopen(q).read()
        if api('PATCH',f'v1/appScreenshots/{sid}',{'data':{'type':'appScreenshots','id':sid,'attributes':{'uploaded':True,'sourceFileChecksum':hashlib.md5(b).hexdigest()}}}) is not None: n+=1
    return n
if EKRAN:
    HEDEF={'APP_IPHONE_67':'iphone','APP_IPAD_PRO_3GEN_129':'ipad'}
    for l in locs:
        sets=api('GET',f'v1/appStoreVersionLocalizations/{l["id"]}/appScreenshotSets?limit=50')['data']
        for s in sets:   # eski (3.x) görselleri temizle; küçük boyutlar 6.9"/13" görsellerinden ölçeklenir
            for sc in api('GET',f'v1/appScreenshotSets/{s["id"]}/appScreenshots?limit=50')['data']: api('DELETE',f'v1/appScreenshots/{sc["id"]}')
            if s['attributes']['screenshotDisplayType'] not in HEDEF: api('DELETE',f'v1/appScreenshotSets/{s["id"]}')
        var={s['attributes']['screenshotDisplayType']:s['id'] for s in sets}
        for disp,on in HEDEF.items():
            SID=var.get(disp)
            if not SID:
                r=api('POST','v1/appScreenshotSets',{'data':{'type':'appScreenshotSets','attributes':{'screenshotDisplayType':disp},'relationships':{'appStoreVersionLocalization':{'data':{'type':'appStoreVersionLocalizations','id':l['id']}}}}})
                if not r: continue
                SID=r['data']['id']
            n=yukle(SID,[f'store/champion/ekran/{on}-{k}.png' for k in SIRA])
            ok(f'{l["attributes"]["locale"]} {on}: {n} görsel')
        time.sleep(1)
    # işlenme durumu
    time.sleep(20); dur={}
    for l in locs:
        for s in api('GET',f'v1/appStoreVersionLocalizations/{l["id"]}/appScreenshotSets?limit=50')['data']:
            for sc in api('GET',f'v1/appScreenshotSets/{s["id"]}/appScreenshots?limit=50')['data']:
                st=(sc['attributes'].get('assetDeliveryState') or {}).get('state'); dur[st]=dur.get(st,0)+1
    out['gorsel_durum']=dur
out['hatalar']=log
json.dump(out,open('durum.json','w'),ensure_ascii=False,indent=1); print(json.dumps(out,ensure_ascii=False))
