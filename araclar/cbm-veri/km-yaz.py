"""km28.mjs çıktısını Kaptan Mecit Klasik'e (www/klasik/index.html: LEAGUES, HAVUZ, LG_ORDER, GERCEK_FX) ve
Modern'e (km3/veri/fikstur.json) yazar. Kulüp kimlikleri tsdb anahtarıyla eski sürümdekiyle aynı tutulur (kariyer kayıtları bozulmasın).
Kullanım: python3 km-yaz.py km28.json dunya.json eski-dunya.json gercek-dunya-klasörü kaptan-mecit-klasörü [kulüp sırası alınacak eski index.html]"""
import json, sys, collections, re
km, dunya, eski_dunya, gd, kok = sys.argv[1:6]
K = json.load(open(km)); D = json.load(open(dunya)); E = json.load(open(eski_dunya))
F = f'{kok}/www/klasik/index.html'; S = open(F, encoding='utf-8').read()
satir = lambda ad: re.search(r'^const ' + ad + r'=(.*);$', S, re.M)
eskiL = json.loads(satir('LEAGUES').group(1))
# kulüp sırası korunur (Modern'in lig kaydı takımı sırasıyla tutar): eski ligde olan kulüpler eski sırada, yeniler sona
if len(sys.argv) > 6:
    _e = re.search(r'^const LEAGUES=(.*);$', open(sys.argv[6], encoding='utf-8').read(), re.M)
    eskiSira = {lg: [t[0] for t in l['t']] for lg, l in json.loads(_e.group(1)).items()}
else: eskiSira = {lg: [t[0] for t in l['t']] for lg, l in eskiL.items()}

# 1) kimlik eşleme: (lig, yeni id) -> eski id (aynı tsdb)
eski_ts = {(lg, c['tsdb']): c['id'] for lg, l in E['ligler'].items() for c in l['kulupler'] if c.get('tsdb')}
esle = {}
for lg, l in D['ligler'].items():
    kullan = set(); yeni = {}
    for c in l['kulupler']:
        e = eski_ts.get((lg, c.get('tsdb')))
        if e and e not in kullan: yeni[c['id']] = e; kullan.add(e)
    for c in l['kulupler']:
        if c['id'] in yeni: continue
        i = c['id']
        if i in kullan:
            n = 1
            while f'y{n:02d}' in kullan: n += 1
            i = f'y{n:02d}'
        yeni[c['id']] = i; kullan.add(i)
    esle[lg] = yeni

# 2) Klasik verisi
LG_ORDER = ['tr', 'en', 'es', 'it', 'de', 'fr']
KITA_SIRA = ['Avrupa', 'Amerika', 'Asya', 'Afrika']
digerleri = sorted([k for k in K['LG'] if k not in LG_ORDER], key=lambda k: (KITA_SIRA.index(K['LG'][k]['kita']), -K['LG'][k]['itibar']))
LG_ORDER += digerleri
LEAGUES, HAVUZ = {}, {}
for lg in LG_ORDER:
    L = K['LG'][lg]; m = esle[lg]
    if lg in eskiL: fn, ln = eskiL[lg]['fn'], eskiL[lg]['ln']
    else:
        a = collections.Counter(); s = collections.Counter()
        for c in D['ligler'][lg]['kulupler']:
            for o in c['oyuncular']:
                if o.get('ad'): a[o['ad'].split()[0]] += 1
                if o.get('soyad'): s[o['soyad'].split()[-1]] += 1
        fn = [x for x, _ in a.most_common(36)]; ln = [x for x, _ in s.most_common(36)]
    t = []
    satirlar = L['t'][:-1] if len(L['t']) % 2 else L['t']   # tek sayıda kulüp: fikstürde bay olmasın diye en zayıf kulüp çıkar
    for r in satirlar:
        r = list(r); r[0] = m.get(r[0], r[0]); t.append(r)
        HAVUZ[f'{lg}:{r[0]}'] = K['HAVUZ'][f"{lg}:{satirlar[len(t)-1][0]}"]
    if lg in eskiSira:
        o = eskiSira[lg]; t.sort(key=lambda r: o.index(r[0]) if r[0] in o else len(o))
    LEAGUES[lg] = {'kurgu': L['kurgu'], 'ad': L['ad'], 'kita': L['kita'], 'it': L['itibar'], 'fn': fn, 'ln': ln, 't': t}

# 3) gerçek fikstür (verisi olan ligler): tsdb -> kulüp kimliği
ts_id = {(lg, c['tsdb']): esle[lg][c['id']] for lg, l in D['ligler'].items() for c in l['kulupler'] if c.get('tsdb')}
GFX = {}
import os
for lg in LG_ORDER:
    p = f'{gd}/maclar-{lg}.json'
    if not os.path.exists(p): continue
    ms = json.load(open(p))['maclar'].values()
    H = collections.defaultdict(list); ok = True
    for x in ms:
        a, b = ts_id.get((lg, x['evk'])), ts_id.get((lg, x['depk']))
        if not a or not b: ok = False; break
        H[x['hafta']].append([a, b])
    n = len(LEAGUES[lg]['t'])
    if ok and len(H) == 2 * (n - 1) and all(len(H[h]) == n // 2 for h in H):
        GFX[lg] = [H[h] for h in sorted(H)]
    else: print('fikstür atlandı', lg)

def yaz(ad, deger):
    global S
    S = re.sub(r'^const ' + ad + r'=.*;$', lambda _: f'const {ad}=' + json.dumps(deger, ensure_ascii=False, separators=(',', ':')) + ';', S, count=1, flags=re.M)
yaz('LEAGUES', LEAGUES); yaz('HAVUZ', HAVUZ); yaz('GERCEK_FX', GFX)
S, n = re.subn(r"^const LG_ORDER=\[[^\]]*\];", lambda _: "const LG_ORDER=" + json.dumps(LG_ORDER) + ";", S, count=1, flags=re.M)
assert n == 1, 'LG_ORDER bulunamadı'
S = re.sub(r"(Champion Battle Manager'in türetilmiş dünyasından \(Lukaku → Lakaka usulü\) kadro havuzları · sezon )\S+ · kaynak \S+", lambda mm: mm.group(1) + f"{K['sezon']} · kaynak {K['kaynak']}", S)
open(F, 'w', encoding='utf-8').write(S)

# 3b) kariyer geçmişi (ayrı dosya, gerekince yüklenir): anahtar lig:kulüp:forma no; kulüp adları KLUP tablosunda
KAR = {}
for k, v in K.get('KARIYER', {}).items():
    lg, i, no = k.split(':')
    yi = esle.get(lg, {}).get(i, i)
    if f'{lg}:{yi}' in HAVUZ: KAR[f'{lg}:{yi}:{no}'] = v
kar = {'KLUP': K.get('KLUP', []), 'K': KAR}
open(f'{kok}/www/klasik/kariyer.js', 'w', encoding='utf-8').write('/* Kaptan Mecit · oyuncu kariyer geçmişi (Champion Battle Manager verisinden; kulüpler oyunun türetilmiş adlarıyla). Otomatik üretilir: araclar/cbm-veri/km-yaz.py */\nwindow.KARIYER=' + json.dumps(kar, ensure_ascii=False, separators=(',', ':')) + ';\n')
json.dump(kar, open(f'{kok}/km3/veri/kariyer.json', 'w'), ensure_ascii=False, separators=(',', ':'))

# 3c) Modern'in kadro havuzu (taktik.json 'havuz'; asistan buradan dizilişe göre 11 + yedek kurar)
tp = f'{kok}/km3/veri/taktik.json'
TK = json.load(open(tp)); TK['havuz'] = HAVUZ
json.dump(TK, open(tp, 'w'), ensure_ascii=False, separators=(',', ':'))

# 4) Modern fikstür
fp = f'{kok}/km3/veri/fikstur.json'
FX = json.load(open(fp)); FX['ligler'] = GFX; FX['sezon'] = K['sezon']
json.dump(FX, open(fp, 'w'), ensure_ascii=False, separators=(',', ':'))
print('ligler', len(LEAGUES), 'kulüp', sum(len(l['t']) for l in LEAGUES.values()), 'gerçek fikstür', list(GFX), 'kimliği korunan',
      sum(1 for lg in esle for a, b in esle[lg].items() if (lg, b) in {(l, c['id']) for l, ll in E['ligler'].items() for c in ll['kulupler']}))
