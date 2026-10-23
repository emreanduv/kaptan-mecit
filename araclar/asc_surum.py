# App Store sürümünü hazırlar (CI): sürüm yoksa açar, "Yenilikler" metnini yazar, derlemeyi bağlar.
# İncelemeye GÖNDERMEZ ("Add for Review / Submit" App Store Connect'te elle). Durum özetini durum.json'a yazar.
import jwt, time, json, os, urllib.request, urllib.error
KID=os.environ['ASC_KEY_ID']; ISS=os.environ['ASC_ISSUER_ID']; BUNDLE=os.environ['BUNDLE']
VER=os.environ['VERSION']; BNO=os.environ.get('BUILD_NO',''); NOT_TR=os.environ.get('NOT_TR',''); NOT_EN=os.environ.get('NOT_EN','')
KEY=open(os.path.expanduser(f'~/private_keys/AuthKey_{KID}.p8')).read()
log=[]
def tok(): return jwt.encode({'iss':ISS,'exp':int(time.time())+900,'aud':'appstoreconnect-v1'},KEY,algorithm='ES256',headers={'kid':KID})
def api(m,p,b=None):
    r=urllib.request.Request('https://api.appstoreconnect.apple.com/'+p,method=m,data=json.dumps(b).encode() if b is not None else None,headers={'Authorization':'Bearer '+tok(),'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(r) as f: t=f.read(); return json.loads(t) if t else {}
    except urllib.error.HTTPError as e: log.append(f'{m} {p} -> {e.code} {e.read().decode()[:600]}'); return None
app=api('GET',f'v1/apps?filter[bundleId]={BUNDLE}')['data'][0]; AID=app['id']
out={'app':app['attributes']['name'],'surumler':[]}
vs=api('GET',f'v1/apps/{AID}/appStoreVersions?limit=10')['data']
for v in vs: out['surumler'].append([v['attributes']['versionString'],v['attributes']['appStoreState'],v['attributes'].get('platform')])
duzenlenebilir={'PREPARE_FOR_SUBMISSION','DEVELOPER_REJECTED','REJECTED','METADATA_REJECTED','INVALID_BINARY','WAITING_FOR_REVIEW'}
v=next((x for x in vs if x['attributes']['platform']=='IOS' and x['attributes']['appStoreState'] in duzenlenebilir),None)
if v and v['attributes']['versionString']!=VER:
    api('PATCH',f'v1/appStoreVersions/{v["id"]}',{'data':{'type':'appStoreVersions','id':v['id'],'attributes':{'versionString':VER}}})
if not v:
    r=api('POST','v1/appStoreVersions',{'data':{'type':'appStoreVersions','attributes':{'platform':'IOS','versionString':VER},'relationships':{'app':{'data':{'type':'apps','id':AID}}}}})
    v=r and r['data']
out['hazirlanan']=v and [v['attributes']['versionString'],v['attributes']['appStoreState']]
if v:
    locs=api('GET',f'v1/appStoreVersions/{v["id"]}/appStoreVersionLocalizations')['data']
    out['diller']=[l['attributes']['locale'] for l in locs]
    first = all(s[1]!='READY_FOR_SALE' for s in out['surumler'])
    for l in locs:
        metin = NOT_TR if l['attributes']['locale'].startswith('tr') else NOT_EN
        if metin and not first:
            api('PATCH',f'v1/appStoreVersionLocalizations/{l["id"]}',{'data':{'type':'appStoreVersionLocalizations','id':l['id'],'attributes':{'whatsNew':metin}}})
    if BNO:
        b=None
        for i in range(40):
            r=api('GET',f'v1/builds?filter[app]={AID}&filter[version]={BNO}&limit=1')
            if r and r['data'] and r['data'][0]['attributes']['processingState']=='VALID': b=r['data'][0]; break
            time.sleep(30)
        if b:
            api('PATCH',f'v1/builds/{b["id"]}',{'data':{'type':'builds','id':b['id'],'attributes':{'usesNonExemptEncryption':False}}})
            api('PATCH',f'v1/appStoreVersions/{v["id"]}/relationships/build',{'data':{'type':'builds','id':b['id']}})
            out['derleme']=BNO
        else: out['derleme']='hazır değil'
out['hatalar']=log
json.dump(out,open('durum.json','w'),ensure_ascii=False,indent=1); print(json.dumps(out,ensure_ascii=False))
