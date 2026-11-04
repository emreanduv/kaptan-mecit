# Kaptan Mecit 3 — tribün sesleri: tamamen sentezle üretilir (kayıt yok, telif yok).
# Kalabalık şarkısı: 28 ses, her biri biraz detune + gecikmeli testere dalga, ünlü formant süzgeci, nefes gürültüsü; altında davul.
# Çıktı: km3/ses/klip/*.wav (22050 Hz, 16 bit, mono). Çalıştır: python3 araclar/ses/tezahurat.py
import numpy as np, wave, os
from scipy.signal import lfilter, butter
HZ = 22050
R = np.random.default_rng(1923)
OUT = os.path.join(os.path.dirname(__file__), '..', '..', 'km3', 'ses', 'klip')

def kaydet(ad, x, tepe=.85):
    x = x / (np.max(np.abs(x)) + 1e-9) * tepe
    with wave.open(os.path.join(OUT, ad + '.wav'), 'wb') as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(HZ)
        w.writeframes((x * 32000).astype('<i2').tobytes())
    print(ad, round(len(x) / HZ, 2), 's')

def rezonans(x, f, q):
    w0 = 2 * np.pi * f / HZ; al = np.sin(w0) / (2 * q)
    b = [al, 0, -al]; a = [1 + al, -2 * np.cos(w0), 1 - al]
    return lfilter(b, a, x)

UNLU = {'a': (800, 1200, 2500), 'o': (500, 850, 2400), 'e': (480, 1800, 2550), 'i': (330, 2100, 2800), 'u': (380, 800, 2300)}

def kalabalik_sarki(hece, toplam, ses=28, kok=196.0):
    """hece: [(başlangıç sn, süre sn, yarım ton, ünlü)]"""
    n = int(toplam * HZ); t = np.arange(n) / HZ; out = np.zeros(n)
    for v in range(ses):
        oct_ = 0.5 if v % 4 == 0 else 1.0       # bazıları bir oktav pes
        det = 2 ** (R.normal(0, .25) / 12)        # akort kayması
        gec = R.uniform(0, .07)                    # herkes aynı anda başlamaz
        guc = R.uniform(.5, 1)
        sig = np.zeros(n)
        for (b, s, yt, u) in hece:
            i0 = int((b + gec) * HZ); i1 = min(n, int((b + gec + s) * HZ))
            if i1 <= i0: continue
            tt = np.arange(i1 - i0) / HZ
            f = kok * oct_ * det * 2 ** (yt / 12) * (1 + .006 * np.sin(2 * np.pi * R.uniform(4, 6) * tt))
            faz = np.cumsum(2 * np.pi * f / HZ) + R.uniform(0, 6.28)
            saw = 2 * ((faz / (2 * np.pi)) % 1) - 1
            zarf = np.minimum(1, tt / .04) * np.minimum(1, (s - tt) / .08).clip(0)
            sig[i0:i1] += saw * zarf * guc
        out += sig
    # ünlü formantları hece hece
    son = np.zeros(n)
    for (b, s, yt, u) in hece:
        i0 = max(0, int(b * HZ)); i1 = min(n, int((b + s + .12) * HZ))
        parca = out[i0:i1]
        f1, f2, f3 = UNLU[u]
        son[i0:i1] += rezonans(parca, f1, 5) + .6 * rezonans(parca, f2, 7) + .25 * rezonans(parca, f3, 9)
    nefes = rezonans(R.normal(0, 1, n), 1500, .7) * .08 * (np.abs(son) > .01)
    return son + nefes

def davul(vuruslar, toplam):
    n = int(toplam * HZ); x = np.zeros(n)
    for b, g in vuruslar:
        i0 = int(b * HZ); m = min(n - i0, int(.5 * HZ))
        if m <= 0: continue
        tt = np.arange(m) / HZ
        f = 70 + 60 * np.exp(-tt * 30)
        x[i0:i0 + m] += g * np.sin(np.cumsum(2 * np.pi * f / HZ)) * np.exp(-tt * 7) + g * .3 * R.normal(0, 1, m) * np.exp(-tt * 60)
    return x

def alkis(vuruslar, toplam, kisi=60):
    n = int(toplam * HZ); x = np.zeros(n)
    for b in vuruslar:
        for k in range(kisi):
            i0 = int((b + R.normal(0, .018)) * HZ); m = int(.03 * HZ)
            if i0 < 0 or i0 + m >= n: continue
            tt = np.arange(m) / HZ
            x[i0:i0 + m] += rezonans(R.normal(0, 1, m), R.uniform(900, 2200), 2) * np.exp(-tt * 160) * R.uniform(.4, 1)
    return x

def uguldu(n):
    return rezonans(R.normal(0, 1, n), 600, .6) * .15

# 1) "Kap-tan Me-cit" kalıbı: dört hece + üç alkış, iki kez
B = .42
h = []; dv = []; al = []
for k in range(2):
    o = k * 8 * B
    h += [(o, B * .9, 0, 'a'), (o + B, B * .9, 0, 'a'), (o + 2 * B, B * .9, 3, 'e'), (o + 3 * B, B * 1.6, 0, 'i')]
    al += [o + 5 * B, o + 6 * B, o + 6.5 * B, o + 7 * B]
    dv += [(o + i * B, 1 if i % 2 == 0 else .6) for i in range(8)]
T = 16 * B + .6
x = kalabalik_sarki(h, T) + .55 * davul(dv, T) + .7 * alkis(al, T)
x += uguldu(len(x))
kaydet('tezahurat1', x)

# 2) "o-le, o-le, o-le" (ezgili)
h = []; nota = [(0, 'o'), (-2, 'e'), (0, 'o'), (-2, 'e'), (3, 'o'), (2, 'e'), (0, 'o'), (-2, 'e')]
dv = []
for i, (yt, u) in enumerate(nota):
    h.append((i * .38, .34 if i % 2 == 0 else .5, yt + 2, u))
    dv.append((i * .38, .8))
T = len(nota) * .38 + .9
x = kalabalik_sarki(h, T, kok=220) + .45 * davul(dv, T)
x += uguldu(len(x))
kaydet('tezahurat2', x)

# 3) ritmik alkış + davul (korner, baskı)
vs = []
for k in range(3):
    o = k * 1.2
    vs += [o, o + .3, o + .6, o + .75, o + .9]
T = 3.8
x = alkis(vs, T, 90) + .5 * davul([(v, .7) for v in vs[::2]], T) + uguldu(int(T * HZ))
kaydet('alkis', x)

# 4) ıslık (yüzlerce parmak ıslığı, kayan perde)
T = 2.6; n = int(T * HZ); x = np.zeros(n)
for k in range(70):
    b = R.uniform(0, .5); s = R.uniform(.6, 2.0)
    i0 = int(b * HZ); m = min(n - i0, int(s * HZ)); tt = np.arange(m) / HZ
    f0 = R.uniform(1900, 3300); f = f0 + R.uniform(-500, 300) * (tt / s) + 40 * np.sin(2 * np.pi * R.uniform(5, 9) * tt)
    z = np.minimum(1, tt / .05) * np.minimum(1, (s - tt) / .15).clip(0)
    x[i0:i0 + m] += np.sin(np.cumsum(2 * np.pi * f / HZ)) * z * R.uniform(.2, 1)
x += uguldu(n) * 2
kaydet('islik', x, .7)

# 5) yuhalama: pes, uzun "uuu"
h = [(0, 1.9, -7, 'u')]
x = kalabalik_sarki(h, 2.4, ses=36, kok=196)
kaydet('yuh', x + uguldu(len(x)), .75)
