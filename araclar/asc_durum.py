# App Store durumu (CI). KIP=durum: sürümleri, durumlarını ve bağlı derlemeyi yazar (hiçbir şeyi değiştirmez).
# KIP=iptal: incelemedeki gönderimi geri çeker. KIP=gonder: hazırlanmış (PREPARE_FOR_SUBMISSION, derlemesi bağlı) iOS sürümünü incelemeye gönderir.
import jwt, time, json, os, urllib.request, urllib.error
KID=os.environ['ASC_KEY_ID']; ISS=os.environ['ASC_ISSUER_ID']; BUNDLE=os.environ['BUNDLE']; KIP=os.environ.get('KIP','durum'); VER=os.environ.get('VERSION','')
KEY=open(os.path.expanduser(f'~/private_keys/AuthKey_{KID}.p8')).read(); log=[]
def tok(): return jwt.encode({'iss':ISS,'exp':int(time.time())+900,'aud':'appstoreconnect-v1'},KEY,algorithm='ES256',headers={'kid':KID})
def api(m,p,b=None):
    r=urllib.request.Request('https://api.appstoreconnect.apple.com/'+p,method=m,data=json.dumps(b).encode() if b is not None else None,headers={'Authorization':'Bearer '+tok(),'Content-Type':'application/json'})
    try:
        with urllib.request.urlopen(r) as f: t=f.read(); return json.loads(t) if t else {}
    except urllib.error.HTTPError as e: log.append(f'{m} {p} -> {e.code} {e.read().decode()[:600]}'); return None
app=api('GET',f'v1/apps?filter[bundleId]={BUNDLE}')['data'][0]; AID=app['id']
out={'app':app['attributes']['name'],'kip':KIP,'surumler':[]}
vs=api('GET',f'v1/apps/{AID}/appStoreVersions?limit=8&include=build')
bld={x['id']:x['attributes'].get('version') for x in vs.get('included',[]) if x['type']=='builds'}
for v in vs['data']:
    b=(v.get('relationships',{}).get('build',{}).get('data') or {}).get('id')
    out['surumler'].append([v['attributes']['versionString'],v['attributes']['appStoreState'],v['attributes'].get('platform'),bld.get(b)])
if KIP=='gonder':
    v=next((x for x in vs['data'] if x['attributes']['platform']=='IOS' and x['attributes']['appStoreState']=='PREPARE_FOR_SUBMISSION' and (not VER or x['attributes']['versionString']==VER)),None)
    if not v: log.append('gönderilecek hazır sürüm yok')
    else:
        rs=api('POST','v1/reviewSubmissions',{'data':{'type':'reviewSubmissions','attributes':{'platform':'IOS'},'relationships':{'app':{'data':{'type':'apps','id':AID}}}}})
        if not rs:
            ex=api('GET',f'v1/reviewSubmissions?filter[app]={AID}&filter[state]=READY_FOR_REVIEW&limit=1'); rs={'data':ex['data'][0]} if ex and ex['data'] else None
        if rs:
            RID=rs['data']['id']
            api('POST','v1/reviewSubmissionItems',{'data':{'type':'reviewSubmissionItems','relationships':{'reviewSubmission':{'data':{'type':'reviewSubmissions','id':RID}},'appStoreVersion':{'data':{'type':'appStoreVersions','id':v['id']}}}}})
            r=api('PATCH',f'v1/reviewSubmissions/{RID}',{'data':{'type':'reviewSubmissions','id':RID,'attributes':{'submitted':True}}})
            out['gonderildi']=bool(r) and v['attributes']['versionString']
if KIP=='iptal':                                               # incelemedeki gönderimi geri çek (derleme değiştirmek için)
    ex=api('GET',f'v1/reviewSubmissions?filter[app]={AID}&filter[state]=WAITING_FOR_REVIEW,IN_REVIEW,UNRESOLVED_ISSUES&limit=5') or {'data':[]}
    out['iptal']=[]
    for rs in ex['data']:
        r=api('PATCH',f"v1/reviewSubmissions/{rs['id']}",{'data':{'type':'reviewSubmissions','id':rs['id'],'attributes':{'canceled':True}}})
        out['iptal'].append([rs['id'], rs['attributes'].get('state'), bool(r)])
out['hatalar']=log
json.dump(out,open('durum.json','w'),ensure_ascii=False,indent=1); print(json.dumps(out,ensure_ascii=False))
