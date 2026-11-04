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

def _girtlak(f, n):
    """bağıran insan sesi kaynağı: perde titremeli (jitter) gırtlak darbeleri + sürekli hırıltı (nefes)"""
    f = f * (1 + .03 * R.normal(0, 1, n).cumsum() / np.sqrt(np.arange(1, n + 1)))   # yavaş kayan perde
    faz = np.cumsum(f / HZ) % 1.0
    # Rosenberg benzeri darbe: kısa açılma, keskin kapanma (bağırışta sert)
    d = np.where(faz < .55, .5 * (1 - np.cos(np.pi * faz / .55)), np.maximum(0, 1 - (faz - .55) / .12))
    d = np.diff(d, prepend=0) * 40
    hiril = R.normal(0, 1, n) * .9
    return d + hiril

def kalabalik_sarki(hece, toplam, ses=90, kok=230.0, dagilim=.12):
    """hece: [(başlangıç sn, süre sn, yarım ton, ünlü)]. Her ses kendi perdesinde, kendi zamanlamasıyla bağırır."""
    n = int(toplam * HZ); out = np.zeros(n)
    for v in range(ses):
        det = 2 ** (R.normal(0, 1.4) / 12)            # herkes başka perdede (koro gibi akortlu değil)
        k = kok * det * (0.75 if v % 3 == 0 else 1.0)
        gec = abs(R.normal(0, dagilim))
        guc = R.uniform(.4, 1)
        for (b, s, yt, u) in hece:
            i0 = int((b + gec) * HZ); m = int(s * R.uniform(.8, 1.1) * HZ)
            if i0 >= n: continue
            m = min(m, n - i0); tt = np.arange(m) / HZ
            f = k * 2 ** (yt / 12) * (1.12 - .2 * tt / max(s, .01))   # bağırışta perde düşer
            src = _girtlak(f, m)
            f1, f2, f3 = UNLU[u]
            sc = R.uniform(.9, 1.15)
            x = rezonans(src, f1 * sc, 4) + .7 * rezonans(src, f2 * sc, 6) + .3 * rezonans(src, f3 * sc, 8)
            zarf = np.minimum(1, tt / .03) * np.exp(-tt / (s * .9))
            out[i0:i0 + m] += x * zarf * guc
    return out

def yanki(x, sure=1.6, karisim=.45):
    """stadyum yankısı: üstel sönen, alçak geçirgen gürültü dürtü yanıtı ile evrişim"""
    from scipy.signal import fftconvolve
    m = int(sure * HZ); tt = np.arange(m) / HZ
    ir = R.normal(0, 1, m) * np.exp(-tt * 6.9 / sure)
    b, a = butter(2, 2500 / (HZ / 2)); ir = lfilter(b, a, ir); ir[:int(.03 * HZ)] *= .2
    ir /= np.sqrt((ir ** 2).sum())
    y = fftconvolve(x, ir)[:len(x)]
    return (1 - karisim) * x / (np.std(x) + 1e-9) + karisim * y / (np.std(y) + 1e-9)

def alcak(x, f=6000):
    b, a = butter(2, f / (HZ / 2)); return lfilter(b, a, x)

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
    """kalabalık mırıltısı: yüzlerce kişinin rastgele kısa konuşma/bağırma hecesi, alçak geçirgen"""
    x = np.zeros(n)
    for k in range(int(n / HZ * 120)):
        i0 = R.integers(0, n); s = R.uniform(.08, .35); m = min(n - i0, int(s * HZ))
        if m < 50: continue
        tt = np.arange(m) / HZ
        f = R.uniform(110, 280) * (1 + .1 * np.sin(2 * np.pi * R.uniform(2, 6) * tt))
        u = list(UNLU.values())[R.integers(0, 5)]
        src = _girtlak(f, m)
        y = rezonans(src, u[0], 4) + .6 * rezonans(src, u[1], 6)
        x[i0:i0 + m] += y * np.sin(np.pi * tt / s) * R.uniform(.2, 1)
    return alcak(x, 3000)

# 0) sürekli kalabalık uğultusu (8 sn döngü, uçları birbirine kaynar)
n = 8 * HZ; u = uguldu(n + HZ)
k = HZ
u[:k] = u[:k] * np.linspace(0, 1, k) + u[n:n + k] * np.linspace(1, 0, k); u = u[:n]
kaydet('ugultu', yanki(u, 1.2, .5)[:n], .5)

# 1) "Kap-tan Me-cit" kalıbı: dört kısa bağırış + üç alkış, iki kez (davul altta)
B = .42
h = []; dv = []; al = []
for k in range(2):
    o = k * 8 * B
    h += [(o, B * .7, 0, 'a'), (o + B, B * .7, 0, 'a'), (o + 2 * B, B * .7, 2, 'e'), (o + 3 * B, B * 1.3, -1, 'i')]
    al += [o + 5 * B, o + 6 * B, o + 6.5 * B, o + 7 * B]
    dv += [(o + i * B, 1 if i % 2 == 0 else .6) for i in range(8)]
T = 16 * B + .8
x = yanki(kalabalik_sarki(h, T), 1.6, .4) + .35 * yanki(davul(dv, T), 1.2, .3) + .5 * yanki(alkis(al, T, 120), 1.2, .35)
n = min(len(x), int(T * HZ)); x = x[:n] + .4 * uguldu(n) / 3
kaydet('tezahurat1', alcak(x))

# 2) uzun "Hey! Hey! Hey!" ve yükselen "ooo-HEY"
h = [(0, 1.1, -2, 'o'), (1.25, .35, 3, 'e'), (1.9, .35, 3, 'e'), (2.55, .35, 3, 'e')]
T = 3.6
x = yanki(kalabalik_sarki(h, T, kok=250), 1.6, .4) + .3 * yanki(davul([(1.25, 1), (1.9, 1), (2.55, 1)], T), 1.2, .3)
n = min(len(x), int(T * HZ)); x = x[:n]
kaydet('tezahurat2', alcak(x))

# 3) ritmik alkış + davul (korner, baskı)
vs = []
for k in range(3):
    o = k * 1.2
    vs += [o + .05, o + .35, o + .65, o + .8, o + .95]
T = 3.9
x = yanki(alkis(vs, T, 140), 1.2, .35) + .3 * yanki(davul([(v, .7) for v in vs[::2]], T), 1.2, .3)
kaydet('alkis', alcak(x[:int(T * HZ)]))

# 4) ıslık (yüzlerce parmak ıslığı, kayan perde)
T = 2.6; n = int(T * HZ); x = np.zeros(n)
for k in range(90):
    b = R.uniform(0, .4); s = R.uniform(.5, 2.0)
    i0 = int(b * HZ); m = min(n - i0, int(s * HZ)); tt = np.arange(m) / HZ
    f0 = R.uniform(1700, 3200); f = f0 + R.uniform(-500, 300) * (tt / s) + 40 * np.sin(2 * np.pi * R.uniform(5, 9) * tt)
    z = np.minimum(1, tt / .05) * np.minimum(1, (s - tt) / .15).clip(0)
    x[i0:i0 + m] += np.sin(np.cumsum(2 * np.pi * f / HZ)) * z * R.uniform(.2, 1)
x = yanki(x, 1.4, .45)[:n]
kaydet('islik', x, .55)

# 5) yuhalama: pes, uzun "uuu" bağırışı
x = yanki(kalabalik_sarki([(0, 1.9, -9, 'u')], 2.6, ses=120, kok=200, dagilim=.2), 1.6, .45)
kaydet('yuh', alcak(x[:int(2.6 * HZ)], 4000), .7)

# 6) gol: kalabalığın patlayan "aaaa!" çığlığı + ıslık + alkış (eski gürültü zarfının yerine)
T = 3.4
x = yanki(kalabalik_sarki([(0, 2.6, 4, 'a')], T, ses=150, kok=260, dagilim=.08), 1.8, .45)
n = int(T * HZ); x = x[:n]
isl = np.zeros(n)
for k in range(40):
    b = R.uniform(.3, 1.5); s = R.uniform(.4, 1.2); i0 = int(b * HZ); m = min(n - i0, int(s * HZ)); tt = np.arange(m) / HZ
    isl[i0:i0 + m] += np.sin(np.cumsum(2 * np.pi * (R.uniform(2000, 3200) + 300 * tt) / HZ)) * np.sin(np.pi * tt / s) * R.uniform(.2, .8)
x = x / np.std(x) + .25 * isl / (np.std(isl) + 1e-9) + .4 * alkis(list(R.uniform(.8, 3.0, 25)), T, 60) / 3
kaydet('gol', alcak(x * np.minimum(1, np.arange(n) / (.08 * HZ)), 5000), .9)

# 7) "ooo": kaçan pozisyon, yükselip düşen kısa nida
x = yanki(kalabalik_sarki([(0, .9, 2, 'o')], 1.6, ses=110, kok=240, dagilim=.06), 1.4, .45)
kaydet('ooo', alcak(x[:int(1.6 * HZ)], 4000), .8)
