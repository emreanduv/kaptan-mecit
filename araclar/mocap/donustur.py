#!/usr/bin/env python3
"""Kaptan Mecit 3 — CMU hareket yakalama (BVH) → bizim 16 kemikli iskelet.

Kaynak: Carnegie Mellon Üniversitesi Hareket Yakalama Veritabanı (mocap.cs.cmu.edu), Bruce Hahne'nin BVH dönüşümü.
"Bu veri araştırma ve ticari kullanım için ücretsizdir" (READMEFIRST); veri tek başına yeniden satılamaz.

Yöntem (yön hizalamalı aktarım): her karede mocap eklemlerinin dünya konumları hesaplanır; bizim her kemiğimiz,
dinlenme yönünü mocap'taki karşılık gelen uzvun yönüne en kısa dönüşle hizalayacak şekilde, ebeveyninin üstüne döndürülür
(leğen ve göğüs tam çerçeve: yukarı + yan yön, böylece gövde burulması da gelir). Bu yöntem iki iskeletin dinlenme
duruşları ve uzuv boyları farklı olsa da çalışır.

Çıktı: kemik başına yerel dönüş dördeyleri (x,y,z,w), kök yükseklik oynaması, döngü adım boyu (metre).
Kullanım: python3 donustur.py <cmu-mocap klasörü> <çıktı.json>
"""
import json, math, sys
import numpy as np

KEMIK = ['kok', 'kalca', 'bel', 'gogus', 'boyun', 'bas', 'omuzL', 'dirsekL', 'omuzR', 'dirsekR',
         'bacakL', 'dizL', 'bilekL', 'bacakR', 'dizR', 'bilekR']
EBEVEYN = {'kalca': 'kok', 'bel': 'kalca', 'gogus': 'bel', 'boyun': 'gogus', 'bas': 'boyun', 'omuzL': 'gogus',
           'dirsekL': 'omuzL', 'omuzR': 'gogus', 'dirsekR': 'omuzR', 'bacakL': 'kalca', 'dizL': 'bacakL',
           'bilekL': 'dizL', 'bacakR': 'kalca', 'dizR': 'bacakR', 'bilekR': 'dizR'}
# bizim dinlenme yönlerimiz (model +Z'ye bakar; "L" kemikleri -X tarafında)
def n(v): v = np.asarray(v, float); return v / np.linalg.norm(v)
DIN = {'bel': n([0, 1, 0]), 'boyun': n([0, 1, 0]), 'bas': n([0, 1, 0]),
       'omuzL': n([-.03, -.29, 0]), 'dirsekL': n([-.015, -.25, .02]), 'omuzR': n([.03, -.29, 0]), 'dirsekR': n([.015, -.25, .02]),
       'bacakL': n([-.005, -.43, .01]), 'dizL': n([0, -.415, -.01]), 'bilekL': n([0, -.27, 1]),
       'bacakR': n([.005, -.43, .01]), 'dizR': n([0, -.415, -.01]), 'bilekR': n([0, -.27, 1])}

def rot(ax, deg):
    a = math.radians(deg); c, s = math.cos(a), math.sin(a)
    if ax == 'X': return np.array([[1, 0, 0], [0, c, -s], [0, s, c]])
    if ax == 'Y': return np.array([[c, 0, s], [0, 1, 0], [-s, 0, c]])
    return np.array([[c, -s, 0], [s, c, 0], [0, 0, 1]])

def bvh_oku(yol):
    satir = open(yol).read().split('\n')
    eklem, ebeveyn, ofset, kanal, yigin = [], [], [], [], []
    i = 0; son = None
    while not satir[i].strip().startswith('MOTION'):
        t = satir[i].split()
        if t and t[0] in ('ROOT', 'JOINT'):
            eklem.append(t[1]); ebeveyn.append(yigin[-1] if yigin else -1); kanal.append([]); ofset.append(None); son = len(eklem) - 1
        elif t and t[0] == 'End':
            eklem.append(eklem[yigin[-1]] + '_uc'); ebeveyn.append(yigin[-1]); kanal.append([]); ofset.append(None); son = len(eklem) - 1
        elif t and t[0] == '{': yigin.append(son)
        elif t and t[0] == '}': yigin.pop()
        elif t and t[0] == 'OFFSET': ofset[son] = np.array(list(map(float, t[1:4])))
        elif t and t[0] == 'CHANNELS': kanal[son] = t[2:]
        i += 1
    kare = int(satir[i + 1].split()[1]); dt = float(satir[i + 2].split()[2])
    veri = np.array([list(map(float, s.split())) for s in satir[i + 3:i + 3 + kare] if s.strip()])
    return eklem, ebeveyn, ofset, kanal, veri, dt

def ileri_kinematik(eklem, ebeveyn, ofset, kanal, veri):
    F = len(veri); J = len(eklem)
    P = np.zeros((F, J, 3))
    for f in range(F):
        R = [None] * J; k = 0
        for j in range(J):
            yer = np.zeros(3); L = np.eye(3)
            for c in kanal[j]:
                v = veri[f, k]; k += 1
                if c.endswith('position'): yer['XYZ'.index(c[0])] = v
                else: L = L @ rot(c[0], v)
            p = ebeveyn[j]
            if p < 0: P[f, j] = yer + ofset[j]; R[j] = L
            else: P[f, j] = P[f, p] + R[p] @ ofset[j]; R[j] = R[p] @ L
    return P

def yay(a, b):
    """a birim vektörünü b'ye götüren en kısa dönüş (3x3)."""
    v = np.cross(a, b); c = float(np.dot(a, b))
    if c < -0.9999:
        e = np.cross(a, [1, 0, 0]);
        if np.linalg.norm(e) < 1e-3: e = np.cross(a, [0, 1, 0])
        e = n(e); return 2 * np.outer(e, e) - np.eye(3)
    vx = np.array([[0, -v[2], v[1]], [v[2], 0, -v[0]], [-v[1], v[0], 0]])
    return np.eye(3) + vx + vx @ vx / (1 + c)

def cerceve(yukari, yan):
    y = n(yukari); x = n(yan - np.dot(yan, y) * y); z = np.cross(x, y)
    return np.stack([x, y, z], axis=1)

def dordey(M):
    t = np.trace(M)
    if t > 0:
        s = math.sqrt(t + 1) * 2; w = .25 * s; x = (M[2, 1] - M[1, 2]) / s; y = (M[0, 2] - M[2, 0]) / s; z = (M[1, 0] - M[0, 1]) / s
    elif M[0, 0] > M[1, 1] and M[0, 0] > M[2, 2]:
        s = math.sqrt(1 + M[0, 0] - M[1, 1] - M[2, 2]) * 2; w = (M[2, 1] - M[1, 2]) / s; x = .25 * s; y = (M[0, 1] + M[1, 0]) / s; z = (M[0, 2] + M[2, 0]) / s
    elif M[1, 1] > M[2, 2]:
        s = math.sqrt(1 + M[1, 1] - M[0, 0] - M[2, 2]) * 2; w = (M[0, 2] - M[2, 0]) / s; x = (M[0, 1] + M[1, 0]) / s; y = .25 * s; z = (M[1, 2] + M[2, 1]) / s
    else:
        s = math.sqrt(1 + M[2, 2] - M[0, 0] - M[1, 1]) * 2; w = (M[1, 0] - M[0, 1]) / s; x = (M[0, 2] + M[2, 0]) / s; y = (M[1, 2] + M[2, 1]) / s; z = .25 * s
    q = np.array([x, y, z, w]); return q / np.linalg.norm(q)

def aktar(eklem, P, idx):
    """P: (kare, eklem, 3) zaten yönü +Z'ye hizalı. Dönüş: kare başına 16 dördey + kök yüksekliği."""
    j = {a: eklem.index(a) for a in eklem}
    out = []
    for f in range(len(P)):
        p = lambda a: P[f, j[a]]
        G = {'kok': np.eye(3)}
        # leğen: yukarı = kalça→sırt, yan = mocap sol bacak - sağ bacak (+X, karakterin solu)
        G['kalca'] = cerceve(p('Spine') - p('Hips'), p('LeftUpLeg') - p('RightUpLeg'))
        def kol(ad, ebe, hedef):
            G[ad] = yay(n(G[ebe] @ DIN[ad]), n(hedef)) @ G[ebe]
        kol('bel', 'kalca', p('Spine1') - p('Spine'))
        G['gogus'] = cerceve(p('Neck1') - p('Spine1'), p('LeftArm') - p('RightArm'))
        kol('boyun', 'gogus', p('Head') - p('Neck1'))
        kol('bas', 'boyun', p('Head_uc') - p('Head'))
        # bizim "L" kemiklerimiz -X tarafında = mocap'ın sağ tarafı (karakter +Z'ye bakarken sağı -X)
        kol('omuzL', 'gogus', p('RightForeArm') - p('RightArm')); kol('dirsekL', 'omuzL', p('RightHand') - p('RightForeArm'))
        kol('omuzR', 'gogus', p('LeftForeArm') - p('LeftArm')); kol('dirsekR', 'omuzR', p('LeftHand') - p('LeftForeArm'))
        kol('bacakL', 'kalca', p('RightLeg') - p('RightUpLeg')); kol('dizL', 'bacakL', p('RightFoot') - p('RightLeg'))
        kol('bilekL', 'dizL', p('RightToeBase') - p('RightFoot'))
        kol('bacakR', 'kalca', p('LeftLeg') - p('LeftUpLeg')); kol('dizR', 'bacakR', p('LeftFoot') - p('LeftLeg'))
        kol('bilekR', 'dizR', p('LeftToeBase') - p('LeftFoot'))
        yerel = []
        for k in KEMIK:
            e = EBEVEYN.get(k)
            L = G[k] if e is None else G[e].T @ G[k]
            yerel.append([round(float(x), 4) for x in dordey(L)])
        out.append(yerel)
    return out

def hizala(eklem, P, a, b):
    """[a,b) aralığındaki ortalama yürüyüş yönünü +Z'ye çevir, ortalama ilerlemeyi çıkar."""
    j = eklem.index
    yan = P[a:b, j('LeftUpLeg')] - P[a:b, j('RightUpLeg')]
    ileri = np.cross(yan.mean(0), [0, 1, 0]); ileri[1] = 0; ileri = n(ileri)
    aci = math.atan2(ileri[0], ileri[2])
    R = rot('Y', -math.degrees(aci))
    Q = P[a:b] @ R.T
    return Q

def dongu(eklem, P, dt, ad, kare_sayisi=32, kac_dongu=1):
    """Yürüyüş/koşu: mocap 'sol' (bizim R) ayağın yere bastığı iki an arası = 1 adım çifti."""
    j = eklem.index
    # döngü süresi: sol ayak yüksekliğinin öz ilintisinin 0.4 sn sonrasındaki ilk tepesi
    ay = P[:, j('LeftToeBase'), 1]; ay = ay - ay.mean()
    ac = np.correlate(ay, ay, 'full')[len(ay) - 1:]
    l0 = int(.4 / dt); T = l0 + int(np.argmax(ac[l0:int(1.6 / dt)]))
    # başlangıç: ortadaki bir ayak basışı (yüksekliğin dibi)
    orta = len(ay) // 2 - T // 2
    a = max(0, orta - T // 2) + int(np.argmin(ay[max(0, orta - T // 2):orta + T // 2]))
    if a + T >= len(ay): a = max(0, len(ay) - T - 1)
    b = a + T
    Q = hizala(eklem, P, a, b + 1)
    olcek = .86 / np.mean(np.linalg.norm(P[:, j('LeftUpLeg')] - P[:, j('LeftFoot')], axis=1))
    adim = float(np.linalg.norm((P[b, j('Hips')] - P[a, j('Hips')])[[0, 2]]) * olcek)
    sure = (b - a) * dt
    # sabit sayıda kareye yeniden örnekle (doğrusal; aktarım sonrası dördeyler yeniden normalize)
    t = np.linspace(0, len(Q) - 1, kare_sayisi, endpoint=False)
    Qr = np.array([Q[int(x)] * (1 - (x - int(x))) + Q[min(int(x) + 1, len(Q) - 1)] * (x - int(x)) for x in t])
    kok = (Qr[:, j('Hips'), 1] - Qr[:, j('Hips'), 1].mean()) * olcek
    return {'ad': ad, 'kare': aktar(eklem, Qr, j), 'kok_y': [round(float(v), 4) for v in kok],
            'adim_boyu': round(adim, 3), 'sure': round(sure, 3), 'hiz': round(adim / sure, 2)}

def vurus(eklem, P, dt, ad, once=.45, sonra=.4, kare_sayisi=26):
    j = eklem.index
    hiz = {}
    for t in ('LeftToeBase', 'RightToeBase'):
        v = np.linalg.norm(np.diff(P[:, j(t)], axis=0), axis=1) / dt; v[:6] = 0; hiz[t] = v   # ilk kareler: T duruşundan sıçrama
    ayak = max(hiz, key=lambda t: hiz[t].max()); c = int(np.argmax(hiz[ayak]))
    a = max(0, c - int(once / dt)); b = min(len(P) - 1, c + int(sonra / dt))
    Q = hizala(eklem, P, a, b + 1)
    # vuran ayak bizim sağımız (R) olsun: mocap "Left" = bizim R. Değilse aynala (X'i çevir, sol-sağ adlarını değiştir).
    if ayak == 'RightToeBase':
        Q = Q * np.array([-1, 1, 1])
        ad_degis = {}
        for i, e in enumerate(eklem):
            if e.startswith('Left'): ad_degis[i] = eklem.index('Right' + e[4:]) if ('Right' + e[4:]) in eklem else i
            elif e.startswith('Right'): ad_degis[i] = eklem.index('Left' + e[5:]) if ('Left' + e[5:]) in eklem else i
        Q = Q[:, [ad_degis.get(i, i) for i in range(len(eklem))]]
    olcek = .86 / np.mean(np.linalg.norm(P[:, j('LeftUpLeg')] - P[:, j('LeftFoot')], axis=1))
    t = np.linspace(0, len(Q) - 1, kare_sayisi)
    Qr = np.array([Q[int(x)] * (1 - (x - int(x))) + Q[min(int(x) + 1, len(Q) - 1)] * (x - int(x)) for x in t])
    kok = (Qr[:, j('Hips'), 1] - Qr[0, j('Hips'), 1]) * olcek
    return {'ad': ad, 'kare': aktar(eklem, Qr, j), 'kok_y': [round(float(v), 4) for v in kok],
            'temas': round(once / (once + sonra), 3), 'sure': round(once + sonra, 3)}

def main():
    kok, cikti = sys.argv[1], sys.argv[2]
    def yukle(dosya):
        e, eb, of, ka, ve, dt = bvh_oku(f'{kok}/data/{dosya}')
        return e, ileri_kinematik(e, eb, of, ka, ve), dt
    klipler = {}
    for ad, dosya in [('yuru', '016/16_15.bvh'), ('kos', '016/16_35.bvh'), ('depar', '009/09_01.bvh')]:
        e, P, dt = yukle(dosya); klipler[ad] = dongu(e, P, dt, ad)
        print(ad, 'adım', klipler[ad]['adim_boyu'], 'm', 'süre', klipler[ad]['sure'], 's', 'hız', klipler[ad]['hiz'], 'm/s')
    e, P, dt = yukle('010/10_01.bvh'); klipler['vurus'] = vurus(e, P, dt, 'vurus')
    print('vuruş', klipler['vurus']['sure'], 's')
    json.dump({'kaynak': 'CMU Graphics Lab Motion Capture Database (mocap.cs.cmu.edu), BVH: B. Hahne / cgspeed',
               'kemikler': KEMIK, 'klipler': klipler}, open(cikti, 'w'), separators=(',', ':'))

if __name__ == '__main__':
    main()
