# App Store Connect meta verilerini API ile doldurur (CI'da çalışır).
import jwt, time, json, os, sys, hashlib, urllib.request, urllib.error, glob

KID=os.environ['ASC_KEY_ID']; ISS=os.environ['ASC_ISSUER_ID']; BUNDLE='com.anduv.kaptanmecit'
KEY=open(os.path.expanduser(f'~/private_keys/AuthKey_{KID}.p8')).read()
GIZLILIK=os.environ.get('GIZLILIK_URL','')
def tok(): return jwt.encode({'iss':ISS,'exp':int(time.time())+900,'aud':'appstoreconnect-v1'},KEY,algorithm='ES256',headers={'kid':KID})
def api(method,path,body=None):
    url=path if path.startswith('http') else 'https://api.appstoreconnect.apple.com/'+path
    r=urllib.request.Request(url,method=method,data=json.dumps(body).encode() if body is not None else None,
        headers={'Authorization':'Bearer '+tok(),'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(r) as f:
            t=f.read(); return json.loads(t) if t else {}
    except urllib.error.HTTPError as e:
        msg=e.read().decode()[:3000]
        msg=msg if len(msg)<600 else msg
        print(f'::warning::{method} {path.split("?")[0]} -> {e.code} {msg}'); RAPOR.write(f'HATA {method} {path} -> {e.code} {msg}\n'); RAPOR.flush(); return None
RAPOR=open('/tmp/rapor.txt','w')
def ok(s): print('::notice::'+s); RAPOR.write('OK '+s+'\n'); RAPOR.flush()

meta=json.load(open('store/asc-metadata.json'))
app=api('GET',f'v1/apps?filter[bundleId]={BUNDLE}')['data'][0]; AID=app['id']; ok('app '+AID)

# İçerik hakları
api('PATCH',f'v1/apps/{AID}',{'data':{'type':'apps','id':AID,'attributes':{'contentRightsDeclaration':'DOES_NOT_USE_THIRD_PARTY_CONTENT'}}})

# App info: kategori + yerelleştirmeler
infos=api('GET',f'v1/apps/{AID}/appInfos')['data']
info=[i for i in infos if i['attributes'].get('appStoreState') not in ('READY_FOR_SALE',)][0]; IID=info['id']
r=api('PATCH',f'v1/appInfos/{IID}',{'data':{'type':'appInfos','id':IID,'relationships':{
    'primaryCategory':{'data':{'type':'appCategories','id':'GAMES'}},
    'primarySubcategoryOne':{'data':{'type':'appCategories','id':'GAMES_SPORTS'}},
    'primarySubcategoryTwo':{'data':{'type':'appCategories','id':'GAMES_ARCADE'}}}}})
if r is not None: ok('kategori: Oyun / Spor, Arcade')
locs={l['attributes']['locale']:l['id'] for l in api('GET',f'v1/appInfos/{IID}/appInfoLocalizations')['data']}
for loc,m in meta.items():
    attrs={'name':'Kaptan Mecit','subtitle':m['subtitle']}
    if GIZLILIK: attrs['privacyPolicyUrl']=GIZLILIK
    if loc in locs: r=api('PATCH',f'v1/appInfoLocalizations/{locs[loc]}',{'data':{'type':'appInfoLocalizations','id':locs[loc],'attributes':attrs}})
    else: r=api('POST','v1/appInfoLocalizations',{'data':{'type':'appInfoLocalizations','attributes':{'locale':loc,**attrs},'relationships':{'appInfo':{'data':{'type':'appInfos','id':IID}}}}})
    if r is not None: ok(f'app bilgisi {loc}')

# Yaş derecelendirmesi
ar=api('GET',f'v1/appInfos/{IID}/ageRatingDeclaration')
if ar:
    ARID=ar['data']['id']; cur=ar['data']['attributes']; new={}
    BOOL={'advertising','gambling','lootBox','messagingAndChat','parentalControls','ageAssurance','healthOrWellnessTopics','unrestrictedWebAccess','userGeneratedContent','socialMedia','socialMediaAgeRestricted'}
    ATLA={'ageRatingOverride','ageRatingOverrideV2','koreaAgeRatingOverride','kidsAgeBand','developerAgeRatingInfoUrl','gracRatingClassificationNumber'}
    for k in cur:
        if k in ATLA: continue
        new[k]=False if k in BOOL else 'NONE'
    RAPOR.write('yaş alanları: '+json.dumps(cur)+'\n')
    r=api('PATCH',f'v1/ageRatingDeclarations/{ARID}',{'data':{'type':'ageRatingDeclarations','id':ARID,'attributes':new}})
    if r is not None: ok('yaş derecelendirmesi: hepsi yok (4+)')

# Sürüm
vers=api('GET',f'v1/apps/{AID}/appStoreVersions?filter[platform]=IOS')['data']
v=[x for x in vers if x['attributes']['appStoreState'] in ('PREPARE_FOR_SUBMISSION','DEVELOPER_REJECTED','REJECTED','METADATA_REJECTED')][0]; VID=v['id']
api('PATCH',f'v1/appStoreVersions/{VID}',{'data':{'type':'appStoreVersions','id':VID,'attributes':{'versionString':'1.0.0','copyright':'2026 Mr. Anduv!'}}})
vlocs={l['attributes']['locale']:l['id'] for l in api('GET',f'v1/appStoreVersions/{VID}/appStoreVersionLocalizations')['data']}
DESTEK=os.environ.get('DESTEK_URL') or GIZLILIK
for loc,m in meta.items():
    attrs={'description':m['description'],'keywords':m['keywords']}
    if DESTEK: attrs['supportUrl']=DESTEK
    if loc in vlocs: r=api('PATCH',f'v1/appStoreVersionLocalizations/{vlocs[loc]}',{'data':{'type':'appStoreVersionLocalizations','id':vlocs[loc],'attributes':attrs}})
    else:
        r=api('POST','v1/appStoreVersionLocalizations',{'data':{'type':'appStoreVersionLocalizations','attributes':{'locale':loc,**attrs},'relationships':{'appStoreVersion':{'data':{'type':'appStoreVersions','id':VID}}}}})
        if r: vlocs[loc]=r['data']['id']
    if r is not None: ok(f'sürüm metni {loc}')

# Ekran görüntüleri (her iki dil için)
def yukle(locid,disp,files):
    sets=api('GET',f'v1/appStoreVersionLocalizations/{locid}/appScreenshotSets')['data']
    s=[x for x in sets if x['attributes']['screenshotDisplayType']==disp]
    if s:
        SID=s[0]['id']
        if api('GET',f'v1/appScreenshotSets/{SID}/appScreenshots')['data']: return 'zaten var'
    else:
        r=api('POST','v1/appScreenshotSets',{'data':{'type':'appScreenshotSets','attributes':{'screenshotDisplayType':disp},'relationships':{'appStoreVersionLocalization':{'data':{'type':'appStoreVersionLocalizations','id':locid}}}}})
        if not r: return 'set hatası'
        SID=r['data']['id']
    n=0
    for f in files:
        b=open(f,'rb').read()
        r=api('POST','v1/appScreenshots',{'data':{'type':'appScreenshots','attributes':{'fileName':os.path.basename(f),'fileSize':len(b)},'relationships':{'appScreenshotSet':{'data':{'type':'appScreenshotSets','id':SID}}}}})
        if not r: continue
        sid=r['data']['id']
        for op in r['data']['attributes']['uploadOperations']:
            part=b[op['offset']:op['offset']+op['length']]
            q=urllib.request.Request(op['url'],method=op['method'],data=part,headers={h['name']:h['value'] for h in op['requestHeaders']})
            urllib.request.urlopen(q).read()
        api('PATCH',f'v1/appScreenshots/{sid}',{'data':{'type':'appScreenshots','id':sid,'attributes':{'uploaded':True,'sourceFileChecksum':hashlib.md5(b).hexdigest()}}})
        n+=1
    return f'{n} görsel'
for loc,lid in vlocs.items():
    if loc not in meta: continue
    ok(f'{loc} iPhone: '+yukle(lid,'APP_IPHONE_67',sorted(glob.glob('store/screenshots-ios/iphone-*.png'))))
    ok(f'{loc} iPad: '+yukle(lid,'APP_IPAD_PRO_3GEN_129',sorted(glob.glob('store/screenshots-ios/ipad-*.png'))))

# Fiyat: ücretsiz
pp=api('GET',f'v1/apps/{AID}/appPricePoints?filter[territory]=USA&limit=200')
if pp:
    free=[p for p in pp['data'] if float(p['attributes']['customerPrice'])==0]
    if free:
        r=api('POST','v1/appPriceSchedules',{'data':{'type':'appPriceSchedules','relationships':{
            'app':{'data':{'type':'apps','id':AID}},'baseTerritory':{'data':{'type':'territories','id':'USA'}},
            'manualPrices':{'data':[{'type':'appPrices','id':'${p0}'}]}}},
            'included':[{'type':'appPrices','id':'${p0}','attributes':{'startDate':None},'relationships':{'appPricePoint':{'data':{'type':'appPricePoints','id':free[0]['id']}}}}]})
        if r is not None: ok('fiyat: ücretsiz')

# Erişilebilirlik: mevcut durumu raporla
av=api('GET',f'v1/apps/{AID}/appAvailabilityV2')
if av:
    AVID=av['data']['id']
    t=api('GET',f'v2/appAvailabilities/{AVID}/territoryAvailabilities?limit=200')
    if t: ok('satışta ülke: %d / %d'%(sum(1 for x in t['data'] if x['attributes'].get('available')),len(t['data'])))
print('bitti')

# --- İnceleme bilgisi, build, TestFlight ---
ESKI='6822718671'  # Malazgirt Akıncıları: iletişim bilgisi kaynağı
ev=api('GET',f'v1/apps/{ESKI}/appStoreVersions?limit=5')
src=None
for x in (ev or {}).get('data',[]):
    d=api('GET',f'v1/appStoreVersions/{x["id"]}/appStoreReviewDetail')
    if d and d.get('data'): src=d['data']['attributes']; break
if src:
    attrs={k:src.get(k) for k in ('contactFirstName','contactLastName','contactPhone','contactEmail')}
    attrs.update({'demoAccountRequired':False,'notes':'Kaptan Mecit is a fully offline top-down football game. Drag on the left half of the screen to run; use the PASS and SHOOT buttons (they become SELECT and SLIDE when the opponent has the ball). No login, no ads, no in-app purchases, no data collection. Stadium boards only show names of public-benefit institutions as decoration.'})
    d=api('GET',f'v1/appStoreVersions/{VID}/appStoreReviewDetail')
    if d and d.get('data'):
        r=api('PATCH',f'v1/appStoreReviewDetails/{d["data"]["id"]}',{'data':{'type':'appStoreReviewDetails','id':d['data']['id'],'attributes':attrs}})
    else:
        r=api('POST','v1/appStoreReviewDetails',{'data':{'type':'appStoreReviewDetails','attributes':attrs,'relationships':{'appStoreVersion':{'data':{'type':'appStoreVersions','id':VID}}}}})
    if r is not None: ok('inceleme iletişim bilgisi (Malazgirt ile aynı)')
builds=api('GET',f'v1/builds?filter[app]={AID}&sort=-uploadedDate&limit=5')
if builds and builds['data']:
    b=builds['data'][0]; ok('son build %s durum %s'%(b['attributes']['version'],b['attributes']['processingState']))
    if b['attributes']['processingState']=='VALID':
        r=api('PATCH',f'v1/appStoreVersions/{VID}/relationships/build',{'data':{'type':'builds','id':b['id']}})
        if r is not None: ok('build sürüme bağlandı')
        api('PATCH',f'v1/builds/{b["id"]}',{'data':{'type':'builds','id':b['id'],'attributes':{'usesNonExemptEncryption':False}}})
# Malazgirt'in test gruplarını raporla
g=api('GET',f'v1/apps/{ESKI}/betaGroups')
for x in (g or {}).get('data',[]):
    a=x['attributes']; t=api('GET',f'v1/betaGroups/{x["id"]}/betaTesters?limit=50')
    ok('Malazgirt grubu %s internal=%s publicLink=%s testçi=%s'%(a['name'],a.get('isInternalGroup'),a.get('publicLinkEnabled'),[y['attributes'].get('email') for y in (t or {}).get('data',[])]))
g=api('GET',f'v1/apps/{AID}/betaGroups')
ok('Kaptan Mecit grupları: %s'%[x['attributes']['name'] for x in (g or {}).get('data',[])])

# TestFlight grupları
TESTCI=['emreanduv@hotmail.com','zeynepbayramcavus@icloud.com','mbayramcavus@icloud.com','mebayramcavus@icloud.com']
mevcut={x['attributes']['name']:x['id'] for x in (g or {}).get('data',[])}
def grup(ad,internal):
    if ad in mevcut: return mevcut[ad]
    at={'name':ad,'isInternalGroup':internal}
    if internal: at['hasAccessToAllBuilds']=True
    r=api('POST','v1/betaGroups',{'data':{'type':'betaGroups','attributes':at,'relationships':{'app':{'data':{'type':'apps','id':AID}}}}})
    return r['data']['id'] if r else None
def testci_ekle(gid,emails):
    var={y['attributes'].get('email') for y in (api('GET',f'v1/betaGroups/{gid}/betaTesters?limit=50') or {}).get('data',[])}
    for e in emails:
        if e in var: continue
        r=api('POST','v1/betaTesters',{'data':{'type':'betaTesters','attributes':{'email':e},'relationships':{'betaGroups':{'data':[{'type':'betaGroups','id':gid}]}}}})
        if r is not None: ok('testçi eklendi '+e)
ig=grup('Mr. Anduv! Ekibi',True)
if ig: testci_ekle(ig,['emreanduv@hotmail.com'])
eg=grup('Mr. Anduv! Testçiler',False)
# beta bilgileri
bl=api('GET',f'v1/apps/{AID}/betaAppLocalizations')
if bl is not None and not bl['data']:
    api('POST','v1/betaAppLocalizations',{'data':{'type':'betaAppLocalizations','attributes':{'locale':'tr','feedbackEmail':'emreanduvart@gmail.com','description':'Üstten görünümlü nostaljik futbol. Hızlı Maç ve 6 ligde 38 haftalık lig kariyeri.'},'relationships':{'app':{'data':{'type':'apps','id':AID}}}}})
bd=api('GET',f'v1/apps/{AID}/betaAppReviewDetail')
if bd and src:
    api('PATCH',f'v1/betaAppReviewDetails/{bd["data"]["id"]}',{'data':{'type':'betaAppReviewDetails','id':bd['data']['id'],'attributes':{
        'contactFirstName':src.get('contactFirstName'),'contactLastName':src.get('contactLastName'),'contactPhone':src.get('contactPhone'),'contactEmail':src.get('contactEmail'),'demoAccountRequired':False}}})
if eg and builds and builds['data'] and builds['data'][0]['attributes']['processingState']=='VALID':
    bid=builds['data'][0]['id']
    api('POST',f'v1/betaGroups/{eg}/relationships/builds',{'data':[{'type':'builds','id':bid}]})
    bbl=api('GET',f'v1/builds/{bid}/betaBuildLocalizations')
    if bbl is not None and not bbl['data']:
        api('POST','v1/betaBuildLocalizations',{'data':{'type':'betaBuildLocalizations','attributes':{'locale':'tr','whatsNew':'İlk sürüm: Hızlı Maç, 6 lig ve 120 kulüple lig kariyeri, Kolay/Orta/Zor.'},'relationships':{'build':{'data':{'type':'builds','id':bid}}}}})
    st=api('GET',f'v1/builds/{bid}/betaAppReviewSubmission')
    if st is not None and not st.get('data'):
        r=api('POST','v1/betaAppReviewSubmissions',{'data':{'type':'betaAppReviewSubmissions','relationships':{'build':{'data':{'type':'builds','id':bid}}}}})
        if r is not None: ok('TestFlight dış test incelemesine gönderildi')
    elif st: ok('TestFlight inceleme durumu: %s'%st['data']['attributes'].get('betaReviewState'))
    testci_ekle(eg,TESTCI)
print('bitti 3')
