# Yeni build'i TestFlight dış test grubuna ekler, "Neyi test etmeli" metnini yazar, beta incelemesine gönderir (CI'da).
# Mağaza incelemesine GÖNDERMEZ.
import jwt, time, json, os, urllib.request, urllib.error
KID=os.environ['ASC_KEY_ID']; ISS=os.environ['ASC_ISSUER_ID']; BUNDLE='com.anduv.kaptanmecit'
KEY=open(os.path.expanduser(f'~/private_keys/AuthKey_{KID}.p8')).read()
BNO=os.environ['BUILD_NO']; NOT=os.environ['NEYI_TEST']
def tok(): return jwt.encode({'iss':ISS,'exp':int(time.time())+900,'aud':'appstoreconnect-v1'},KEY,algorithm='ES256',headers={'kid':KID})
def api(m,p,b=None):
    r=urllib.request.Request('https://api.appstoreconnect.apple.com/'+p,method=m,data=json.dumps(b).encode() if b is not None else None,headers={'Authorization':'Bearer '+tok(),'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(r) as f: t=f.read(); return json.loads(t) if t else {}
    except urllib.error.HTTPError as e: print(f'::warning::{m} {p} -> {e.code} {e.read().decode()[:800]}'); return None
AID=api('GET',f'v1/apps?filter[bundleId]={BUNDLE}')['data'][0]['id']
b=None
for i in range(60):
    r=api('GET',f'v1/builds?filter[app]={AID}&filter[version]={BNO}&limit=1')
    if r and r['data'] and r['data'][0]['attributes']['processingState']=='VALID': b=r['data'][0]; break
    print('build bekleniyor', (r or {}).get('data') and r['data'][0]['attributes']['processingState']); time.sleep(30)
assert b, 'build hazır değil'
bid=b['id']
api('PATCH',f'v1/builds/{bid}',{'data':{'type':'builds','id':bid,'attributes':{'usesNonExemptEncryption':False}}})
bbl=api('GET',f'v1/builds/{bid}/betaBuildLocalizations')
loc=[x for x in (bbl or {}).get('data',[]) if x['attributes']['locale'].startswith('tr')]
if loc: api('PATCH',f'v1/betaBuildLocalizations/{loc[0]["id"]}',{'data':{'type':'betaBuildLocalizations','id':loc[0]['id'],'attributes':{'whatsNew':NOT}}})
else: api('POST','v1/betaBuildLocalizations',{'data':{'type':'betaBuildLocalizations','attributes':{'locale':'tr','whatsNew':NOT},'relationships':{'build':{'data':{'type':'builds','id':bid}}}}})
for g in api('GET',f'v1/apps/{AID}/betaGroups')['data']:
    if not g['attributes'].get('isInternalGroup'):
        r=api('POST',f'v1/betaGroups/{g["id"]}/relationships/builds',{'data':[{'type':'builds','id':bid}]}); print('gruba eklendi',g['attributes']['name'],r is not None)
st=api('GET',f'v1/builds/{bid}/betaAppReviewSubmission')
if st is not None and not st.get('data'):
    r=api('POST','v1/betaAppReviewSubmissions',{'data':{'type':'betaAppReviewSubmissions','relationships':{'build':{'data':{'type':'builds','id':bid}}}}}); print('beta incelemesine gönderildi',r is not None)
time.sleep(20)
st=api('GET',f'v1/builds/{bid}/betaAppReviewSubmission'); print('::notice::beta durum',st and st.get('data') and st['data']['attributes'].get('betaReviewState'))
