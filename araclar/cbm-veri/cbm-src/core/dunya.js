/* Kurmaca dünya üretici: 6 lig, 120 kulüp, kulüp başına 25 oyuncu.
   Aynı tohum her zaman aynı dünyayı üretir. Hiçbir gerçek kişi, kulüp ya da veri kullanılmaz. */
import { rng, hash, clamp } from './rng.js';
import { LIGLER, LIG_SIRASI } from '../data/ligler.js';
import { DIL, UYRUK, LIG_UYRUK, YASAKLI } from '../data/names/havuz.js';
import { OZELLIK, TUM, KALECI_OZ, AGIRLIK, KADRO_DUZENI, YAKIN, KISILIK, MEVKI } from '../data/ozellikler.js';
import { baslangicMuafiyeti } from './kural.js';

export const SEZON = 2026;
export const LIG_ITIBAR = { en: 1.0, es: .97, it: .95, de: .93, fr: .88, tr: .8 };
export const ligItibar = lk => LIG_ITIBAR[lk] ?? (LIG_ITIBAR[lk.slice(0, 2)] ?? .8) * .78;   // 2. ligler üst ligin ~%78'i
export const LIG_DEGER = { en: 1.25, es: 1.0, it: 1.0, de: 1.0, fr: .9, tr: .9 };

/* ---------- Yetenek (CA, 1–200) ↔ özellik düzeyi ---------- */
const anaDuzey = ca => 3 + ca * 0.085;                     // önemli özelliklerin beklenen değeri
export function yetenekHesapla(oz, mevki) {                // özelliklerden mevki için yetenek
  const w = AGIRLIK[mevki]; let s = 0, t = 0;
  for (const k of TUM) { const a = w[k] ?? (KALECI_OZ.includes(k) ? 0 : (mevki === 'KL' ? 0.15 : 0.4)); if (!a) continue; s += oz[k] * a; t += a; }
  return clamp(Math.round(((s / t) - 3) / 0.085 * 1.04), 1, 200);
}

function ozellikUret(r, mevki, ca, yas) {
  const w = AGIRLIK[mevki], ana = anaDuzey(ca), oz = {};
  for (const k of TUM) {
    let m;
    if (KALECI_OZ.includes(k)) m = mevki === 'KL' ? ana * (0.55 + 0.45 * Math.min(w[k] ?? 1, 3) / 3) : r.int(1, 3);
    else {
      const a = w[k] ?? 0.4;
      const tavan = mevki === 'KL' && ['bit', 'uzs', 'srm', 'ort', 'kaf', 'mrk', 'kap', 'tsz', 'tek'].includes(k) ? 0.38 : 1;
      m = ana * (0.5 + 0.5 * Math.min(a, 3) / 3) * tavan;
    }
    if (!(KALECI_OZ.includes(k) && mevki !== 'KL')) m = r.norm(m, 1.5);
    oz[k] = m;
  }
  // yaşa göre fizik ve zihin
  const fiz = ['hiz', 'hzl', 'day', 'cev'];
  if (yas >= 31) { const d = (yas - 30) * 0.7; for (const k of fiz) oz[k] -= d * (0.6 + r() * 0.6); for (const k of ['krr', 'poz', 'lid', 'sgk', 'ons']) oz[k] += 0.4 + r() * 1.4; }
  if (yas <= 20) { for (const k of ['krr', 'poz', 'lid', 'sgk']) oz[k] -= 1 + r(); for (const k of ['hiz', 'hzl']) oz[k] += r() * 1.2; }
  // oyuncunun kendine has birkaç güçlü / zayıf yanı
  const ozellikler = mevki === 'KL' ? [...KALECI_OZ, 'krr', 'poz', 'cev'] : TUM.filter(k => !KALECI_OZ.includes(k));
  for (let i = 0; i < 2; i++) oz[r.pick(ozellikler)] += 1.5 + r() * 2;
  oz[r.pick(ozellikler)] -= 1.5 + r() * 1.5;
  for (const k of TUM) oz[k] = clamp(Math.round(oz[k]), 1, 20);
  return oz;
}

/* ---------- Veri seti ----------
   'turetilmis': gerçek oyunculardan türeyen benzer adlar (mobil). 'kurgu': aynı oyuncu, tamamen kurmaca ad (Steam).
   Kurgu adı oyuncunun kaynak anahtarından üretilir: her sezonda ve her veri güncellemesinde aynı kalır; yetenekler değişmez. */
export const VERI = { kurgu: false };
export function veriSetiAyarla(kip) { VERI.kurgu = kip === 'kurgu'; }
const KURGU_AD = new Map(), KURGU_KUL = new Set();
/* havuzda olmayan uyruklar için en yakın ad havuzu */
const YAKIN_HAVUZ = { SC: 'EN', IE: 'EN', WL: 'EN', NI: 'EN', CA: 'US', AU: 'EN', NZ: 'EN', JM: 'US', CD: 'CM', GN: 'SN', GM: 'SN', GW: 'SN', MR: 'SN', CV: 'PT', AO: 'PT', MZ: 'PT', BF: 'CI', GA: 'CM', CG: 'CM', CF: 'CM', BJ: 'CI', TG: 'CI', NE: 'ML', GQ: 'CM', KM: 'MA', EG: 'MA', SA: 'MA', JO: 'MA', SY: 'MA', AE: 'MA',
  GR: 'AL', RO: 'HR', HU: 'CZ', SK: 'CZ', SI: 'HR', BG: 'RS', UA: 'PL', RU: 'PL', ME: 'RS', MK: 'RS', XK: 'AL', EE: 'SE', LT: 'PL', IS: 'NO', FI: 'SE', LU: 'FR', AM: 'GE', UZ: 'AZ', IL: 'US',
  EC: 'CO', CL: 'AR', MX: 'CO', VE: 'CO', PY: 'UY', PE: 'CO', CR: 'CO', PA: 'CO', HN: 'CO', DO: 'CO', SR: 'NL', CW: 'NL', HT: 'FR', GP: 'FR', MQ: 'FR', ID: 'JP', TH: 'JP', PH: 'US', CN: 'JP', ZM: 'NG', TZ: 'NG', KE: 'NG', SL: 'NG', LR: 'NG', BI: 'CM', MG: 'FR' };
export function kurguAd(k, uyruk) {
  const a = `${k}|${uyruk}`; if (KURGU_AD.has(a)) return KURGU_AD.get(a);
  const u = UYRUK[uyruk] ? uyruk : YAKIN_HAVUZ[uyruk] || 'BR';
  const x = isimUret(rng((hash('kurgu:' + k) ^ 0x5bd1e995) >>> 0), UYRUK[u] ? u : Object.keys(UYRUK)[0], KURGU_KUL);
  KURGU_AD.set(a, x); return x;
}
export const kaynakAdi = (k, o) => { if (VERI.kurgu && k != null) { const x = kurguAd(k, o?.uyruk || 'GB'); return `${x.ad} ${x.soyad}`; } return `${o?.ad || ''} ${o?.soyad || ''}`.trim(); };

/* ---------- İsim ---------- */
export function isimUret(r, uyruk, kullanilan) {
  const diller = UYRUK[uyruk].dil;
  for (let i = 0; i < 60; i++) {
    const d = DIL[r.pick(diller)];
    const ad = r.pick(d.ad), soyad = r.pick(d.soyad), tam = `${ad} ${soyad}`;
    if (YASAKLI.has(tam) || kullanilan.has(tam)) continue;
    kullanilan.add(tam);
    return { ad, soyad };
  }
  const d = DIL[diller[0]];
  const ad = r.pick(d.ad), soyad = r.pick(d.soyad) + ' ' + r.pick(d.soyad);
  kullanilan.add(`${ad} ${soyad}`);
  return { ad, soyad };
}

/* ---------- Para ---------- */
export const yuvarla = v => { if (v >= 1e7) return Math.round(v / 5e5) * 5e5; if (v >= 1e6) return Math.round(v / 1e5) * 1e5; if (v >= 1e5) return Math.round(v / 2.5e4) * 2.5e4; return Math.round(v / 5e3) * 5e3; };
export function degerHesapla(o, lig) {
  let v = 80e6 * Math.exp(-0.045 * (170 - o.ca));
  const y = o.yas;
  v *= y <= 21 ? 1 + Math.max(0, o.pa - o.ca) / 55 : y <= 27 ? 1 : y <= 30 ? .75 : y <= 32 ? .45 : .2;
  v *= LIG_DEGER[lig] ?? (lig ? (LIG_DEGER[lig.slice(0, 2)] ?? 1) * .6 : 1);
  if (o.mevki === 'KL') v *= .7;
  return Math.max(25000, yuvarla(v));
}

/* ---------- Yaş dağılımı ---------- */
function yasSec(r, mevki) {
  const b = r.weighted({ g: 12, y: 28, z: 40, d: 16, e: mevki === 'KL' ? 8 : 4 });
  return b === 'g' ? r.int(17, 19) : b === 'y' ? r.int(20, 23) : b === 'z' ? r.int(24, 29) : b === 'd' ? r.int(30, 33) : r.int(34, mevki === 'KL' ? 39 : 36);
}

/* ---------- Oyuncu ---------- */
export function oyuncuUret(r, { id, kulup, lig, mevki, hedefCA, kullanilan, numara, sabit = null, yasZorla = null, sezon = SEZON }) {
  const yas = sabit?.yas ?? yasZorla ?? yasSec(r, mevki);
  const ly = LIG_UYRUK[lig] || LIG_UYRUK[lig.slice(0, 2)] || { yerli: 'NL', oran: 0.5, yabanci: { BR: 4, PT: 2, NL: 2, BE: 2, HR: 2, RS: 2, SN: 2, NG: 2, AR: 2, DK: 1, SE: 1, CI: 1, GH: 1 } };   // yabancı kulüpler
  const uyruk = sabit?.uyruk || (r() < ly.oran ? ly.yerli : r.weighted(ly.yabanci));
  // yaşa göre yetenek ve potansiyel
  let ca = hedefCA;
  if (yas <= 19) ca *= 0.62 + r() * 0.18; else if (yas <= 21) ca *= 0.78 + r() * 0.16; else if (yas >= 34) ca *= 0.85 + r() * 0.1;
  ca = clamp(Math.round(r.norm(ca, sabit ? 4 : 9)), 35, 195);
  const oz = ozellikUret(r, mevki, ca, yas);
  const caGercek = yetenekHesapla(oz, mevki);
  let pa;
  if (yas <= 21) pa = caGercek + Math.round(15 + r() * 45 + (r() < 0.03 ? 35 : 0));
  else if (yas <= 24) pa = caGercek + Math.round(r() * 28);
  else if (yas <= 28) pa = caGercek + Math.round(r() * 10);
  else pa = caGercek;
  pa = clamp(pa, caGercek, 200);
  const isim = sabit ? (VERI.kurgu && sabit.k != null ? kurguAd(sabit.k, UYRUK[uyruk] ? uyruk : YAKIN_HAVUZ[uyruk] || ly.yerli) : { ad: sabit.ad, soyad: sabit.soyad }) : isimUret(r, UYRUK[uyruk] ? uyruk : ly.yerli, kullanilan);
  const boy = sabit?.boy || Math.round(mevki === 'KL' ? r.norm(190, 4) : mevki === 'STP' ? r.norm(188, 4) : mevki === 'SF' ? r.norm(183, 6) : ['SĞK', 'SLK', 'OOS'].includes(mevki) ? r.norm(176, 5) : r.norm(180, 5));
  const sol = mevki.startsWith('SL') ? .6 : mevki.startsWith('SĞ') ? .08 : .2;
  const ayakR = r();
  const ayak = ayakR < sol ? 'Sol' : ayakR < sol + .06 ? 'İki ayak' : 'Sağ';
  const dogum = sabit?.dogum ? (sabit.dogum.length === 4 ? new Date(Date.UTC(+sabit.dogum, r.int(0, 11), r.int(1, 28), 12)) : new Date(sabit.dogum + 'T12:00:00Z')) : new Date(Date.UTC(sezon - yas - (r() < .5 ? 1 : 0), r.int(0, 11), r.int(1, 28)));
  const rastgeleIkinci = YAKIN[mevki].filter(() => r() < .35);    // (rastgele sayı akışı değişmesin diye gerçek oyuncuda da çekilir)
  const ikinci = sabit ? (sabit.ikinci || []).filter(m => m !== mevki) : rastgeleIkinci;   // gerçek oyuncu: yalnız kaynaktaki yan mevkiler
  const kisilik = Object.fromEntries(KISILIK.map(([k]) => [k, clamp(Math.round(r.norm(11, 3.5)), 1, 20)]));
  const o = {
    id, ad: isim.ad, soyad: isim.soyad, uyruk, dogum: dogum.toISOString().slice(0, 10), yas, kulup, mevki, ikinci, ayak,
    boy: clamp(boy, 160, 202), kilo: clamp(Math.round(r.norm(boy - 105, 5)), 55, 100), no: numara,
    oz, ca: caGercek, pa, kisilik, moral: 13, kondisyon: 100, form: [], zirve: caGercek,
  };
  if (sabit?.k) o.anahtar = sabit.k;
  o.deger = degerHesapla(o, lig);
  o.sozlesme = { bitis: sezon + clamp(Math.round(r.norm(yas <= 23 ? 3.6 : yas <= 29 ? 2.8 : 1.6, 1.1)), 1, 5), maas: 0 };
  return o;
}

/* ---------- Türetilmiş kaynak (gerçekten türeyen kulüp ve kadrolar) ---------- */
const RENK_HEX = { 'Kırmızı': '#C8102E', 'Beyaz': '#F2F2F2', 'Mavi': '#1F5FB4', 'Siyah': '#141414', 'Sarı': '#F5C400', 'Yeşil': '#0B7A3B', 'Lacivert': '#0B2A6B', 'Gök Mavi': '#6CADDF', 'Bordo': '#7A1F3D', 'Turuncu': '#E35205', 'Mor': '#5B2A86', 'Altın': '#C9A227', 'Gri': '#8A8D91', 'Kehribar': '#F2A900' };
/* kaynaktaki yan mevkiler (Vikipedi bilgi kutusu): genel kodlar açılır; genel asıl mevki (bek/kanat) diğer tarafı da kapsar */
const YAN_AC = { B: ['SĞB', 'SLB'], K: ['SĞK', 'SLK'], D: ['STP'] };
export function kaynakIkinci(o, m) {
  const out = [];
  for (const k of [...(['B', 'K'].includes(o.mevki) ? [o.mevki] : []), ...(o.yan || [])]) for (const x of YAN_AC[k] || [k]) if (x !== m && x !== 'KL' && !out.includes(x)) out.push(x);
  return out.slice(0, 3);
}
const GENEL_MEVKI = { D: ['STP', 'SĞB', 'SLB'], B: ['SĞB', 'SLB'], K: ['SĞK', 'SLK'], MOS: ['MOS', 'DOS', 'OOS', 'SĞO', 'SLO'], SF: ['SF', 'SĞK', 'SLK', 'OOS'] };
export const yasHesapla = (d, sezon = SEZON) => { if (!d) return null; const [y, m] = d.split('-').map(Number); return sezon - y - (m > 7 ? 1 : 0); };
function kaynakKulupleri(L, lk, r) {
  // ünlülükten kulüp gücü: en ünlü 14 oyuncunun ortalaması, lig içi sıraya göre 4–9
  const puan = L.kulupler.map(c => { const u = c.oyuncular.map(o => o.un || 0).sort((a, b) => b - a).slice(0, 14); return u.reduce((s, x) => s + x, 0) / Math.max(1, u.length); });
  const sirali = [...puan].sort((a, b) => b - a), n = L.kulupler.length;
  const adlar = new Set(LIGLER[lk].kulupler.map(k => k.ad)), kisalar = new Set(LIGLER[lk].kulupler.map(k => k.kisa));
  return L.kulupler.map((c, i) => {
    const sira = sirali.indexOf(puan[i]);
    const w = clamp((c.oyuncular.length - 10) / 12, 0, 1);            // kadro verisi azsa puan tablosuna güven
    const unSira = sira / Math.max(1, n - 1), tabloSira = (c.sira - 1) / Math.max(1, n - 1);
    const guc = clamp(Math.round(9 - 5 * (unSira * (0.85 * w) + tabloSira * (1 - 0.85 * w))), 4, 9);
    const km = c.km && LIGLER[lk].kulupler.find(k => k.id === c.id);
    if (km) return { ...km, guc, kaynak: c };
    let ad = `${c.sehir} ${c.renkAd?.length ? c.renkAd.join('-') : 'Yıldızları'}`;
    if (adlar.has(ad)) ad = `${c.sehir} ${c.renkAd?.[0] || ''} Şimşekleri`.replace('  ', ' ');
    adlar.add(ad);
    let kisa = (c.sehir.slice(0, 1) + (c.renkAd?.[0] || 'Y').slice(0, 1) + (c.renkAd?.[1] || c.sehir.slice(1, 2)).slice(0, 1)).toLocaleUpperCase('tr');
    while (kisalar.has(kisa)) kisa = kisa.slice(0, 2) + 'ABCDEFGHKLMNPRSTUVYZ'[r.int(0, 19)];
    kisalar.add(kisa);
    const renk1 = RENK_HEX[c.renkAd?.[0]] || c.renk?.[0] || '#2A4F8A', renk2 = RENK_HEX[c.renkAd?.[1]] || c.renk?.[1] || '#F2F2F2';
    return { id: c.id, ad, kisa, renk1, renk2, guc, sehir: c.sehir, kaynak: c };
  });
}
function kaynakKadro(r, c, lk, K, hedef, kullanilan, yeniId, D) {
  const need = Object.fromEntries(KADRO_DUZENI.map(([m, n]) => [m, n]));
  const sahip = [...c.kaynak.oyuncular].sort((a, b) => (b.un || 0) - (a.un || 0));
  const atanan = [];
  const ata = (o, m) => { atanan.push([o, m]); need[m] = (need[m] ?? 0) - 1; };
  const genel = o => GENEL_MEVKI[o.mevki] && !(o.kesin && (o.mevki === 'MOS' || o.mevki === 'SF'));   // bilgi kutusundan gelen MOS/SF kesindir
  for (const o of sahip) if (o.mevki && !genel(o) && need[o.mevki] !== undefined) ata(o, o.mevki);
  for (const o of sahip) {
    if (o.mevki && !genel(o) && need[o.mevki] !== undefined) continue;
    let secenek = GENEL_MEVKI[o.mevki] || ['MOS', 'STP', 'SF', 'SĞB', 'SLB', 'SĞK', 'SLK', 'DOS', 'OOS'];
    if (o.mevki === 'D' && o.boy) secenek = o.boy >= 185 ? ['STP', 'SĞB', 'SLB'] : o.boy <= 180 ? ['SĞB', 'SLB', 'STP'] : secenek;   // boy: uzunlar stoper, kısalar bek
    if (o.mevki === 'D' && o.boy >= 185 && (need.STP ?? 0) > -1) { ata(o, 'STP'); continue; }
    ata(o, secenek.reduce((a, b) => (need[b] ?? 0) > (need[a] ?? 0) ? b : a));
  }
  const n = atanan.length, unOrt = atanan.reduce((s, [o]) => s + (o.un || 0), 0) / Math.max(1, n);
  const kullNo = new Set(); const noVer = (o, m) => { if (o?.no && !kullNo.has(o.no)) { kullNo.add(o.no); return o.no; } let x = m === 'KL' ? 1 : 2; while (kullNo.has(x) || (m !== 'KL' && (x === 1 || x === 12))) x++; kullNo.add(x); return x; };
  atanan.forEach(([o, m], i) => {
    const rk = n > 1 ? i / (n - 1) : 0;
    const ca = hedef * (1.12 - 0.36 * rk) + ((o.un || 0) - unOrt) * 34;
    const yas = yasHesapla(o.dogum);
    const p = oyuncuUret(r, { id: yeniId(), kulup: K.id, lig: lk, mevki: m, hedefCA: ca, kullanilan, numara: noVer(o, m),
      sabit: { k: o.k, ad: o.ad, soyad: o.soyad, ikinci: kaynakIkinci(o, m), uyruk: o.uyruk || LIG_UYRUK[lk].yerli, yas: yas ?? undefined, boy: o.boy && o.boy > 150 && o.boy < 210 ? o.boy : undefined, dogum: o.dogum || undefined } });
    D.oyuncular[p.id] = p; K.oyuncular.push(p.id);
  });
  // eksik mevkiler: altyapıdan kurmaca gençler
  for (const [m] of KADRO_DUZENI) while ((need[m] ?? 0) > 0 && K.oyuncular.length < 26) {
    const p = oyuncuUret(r, { id: yeniId(), kulup: K.id, lig: lk, mevki: m, hedefCA: hedef * (K.oyuncular.length < 16 ? 0.9 : 0.72), kullanilan, numara: noVer(null, m), sabit: null });
    D.oyuncular[p.id] = p; K.oyuncular.push(p.id); need[m]--;
  }
}

/* eski kayıtlar: gerçek oyuncuların mevkilerini güncel kaynağa göre düzelt (rastgele yan mevkiler silinir).
   Yetenek ve özellikler aynı kalır; yalnız asıl/yan mevki değişir. Dönen: düzeltilen oyuncu sayısı */
export function mevkiDuzelt(D, kaynak) {
  const K = new Map();
  for (const l of Object.values(kaynak?.ligler || {})) for (const c of l.kulupler) for (const o of c.oyuncular) if (o.k != null) K.set(o.k, o);
  let n = 0;
  for (const o of Object.values(D.oyuncular)) {
    if (o.anahtar == null) continue;
    const k = K.get(o.anahtar); if (!k || !k.mevki) continue;
    if ((k.mevki === 'KL') !== (o.mevki === 'KL')) continue;
    let m = o.mevki;
    const ac = k.mevki === 'D' ? GENEL_MEVKI.D : YAN_AC[k.mevki] || GENEL_MEVKI[k.mevki];
    if (k.kesin && MEVKI[k.mevki]) m = k.mevki;
    else if (!GENEL_MEVKI[k.mevki] && MEVKI[k.mevki]) m = k.mevki;
    else if (ac && !ac.includes(m)) m = ac[0];
    const ik = kaynakIkinci(k, m);
    if (m !== o.mevki || ik.join() !== (o.ikinci || []).join()) { o.mevki = m; o.ikinci = ik; n++; }
  }
  return n;
}

/* ---------- Dünya ---------- */
export function dunyaUret(tohum = Date.now() >>> 0, kaynak = null) {
  const r = rng(tohum >>> 0);
  const D = { surum: 1, tohum: tohum >>> 0, sezon: SEZON, ligler: {}, kulupler: {}, oyuncular: {}, turetilmis: !!kaynak, veriSeti: VERI.kurgu ? 'kurgu' : 'turetilmis' };
  const kullanilan = new Set();
  let oid = 1;
  for (const lk of LIG_SIRASI) {
    const L = LIGLER[lk], it = LIG_ITIBAR[lk];
    D.ligler[lk] = { kod: lk, ad: L.ad, ulke: L.ulke, itibar: Math.round(it * 100), kulupler: [] };
    const kaynakL = kaynak?.ligler?.[lk];
    for (const c of kaynakL ? kaynakKulupleri(kaynakL, lk, r) : L.kulupler) {
      const id = `${lk}-${c.id}`;
      const hedef = (60 + c.guc * 12) * it;                          // ilk 11'in ortalama yeteneği
      const butce = yuvarla(Math.exp(0.62 * c.guc) * 9e4 * it * it);   // transfer bütçesi
      const K = {
        id, lig: lk, ad: c.ad, kisa: c.kisa, renk1: c.renk1, renk2: c.renk2, sehir: c.sehir, guc: c.guc, tsdb: c.kaynak?.tsdb,
        itibar: Math.round(c.guc * 10 * it), butce, maasButcesi: 0,
        stad: { ad: `${c.sehir} ${r.pick(['Şehir', 'Belediye', 'Halk', 'Cumhuriyet', 'Gençlik', 'Spor Kompleksi'])} Stadı`, kapasite: Math.round((8000 + c.guc * c.guc * 900 * it + r() * 6000) / 500) * 500 },
        oyuncular: [],
        ekip: ekipUret(rng((hash(id) ^ tohum) >>> 0), c.guc * 10 * it),   // ayrı tohum: eski kayıtların dünyası değişmesin
      };
      if (c.kaynak) {
        if (c.kaynak.kapasite > 3000) K.stad.kapasite = Math.round(c.kaynak.kapasite / 500) * 500;
        kaynakKadro(r, c, lk, K, hedef, kullanilan, () => `o${oid++}`, D);
      } else kadroUret(r, D, K, hedef, kullanilan, () => `o${oid++}`);
      // maaşlar: kulübün gücüne göre ölçekli, toplam maaş bütçesi
      let top = 0;
      for (const pid of K.oyuncular) { const o = D.oyuncular[pid]; o.sozlesme.maas = maasHesapla(o, K); top += o.sozlesme.maas; }
      K.maasButcesi = yuvarla(top * 1.08);
      D.kulupler[id] = K; D.ligler[lk].kulupler.push(id);
    }
  }
  D.sonId = oid;
  if (kaynak) baslangicMuafiyeti(D);
  D.anahtar = {};
  for (const o of Object.values(D.oyuncular)) if (o.anahtar) D.anahtar[o.anahtar] = o.id;
  return D;
}

/* kurmaca kadro: önce ilk 11 düzeyinde çekirdek, sonra yedekler ve gençler */
export function kadroUret(r, D, K, hedef, kullanilan, yeniId, sezon = SEZON) {
  const roller = [];
  for (const [m, n] of KADRO_DUZENI) for (let i = 0; i < n; i++) roller.push({ m, sira: i });
  const numaralar = r.shuffle([...Array(38).keys()].map(i => i + 2).filter(n => n !== 12));
  const KLno = [1, 12, r.pick([23, 25, 30, 31, 33, 40, 41, 99])];
  let kl = 0, ni = 0;
  for (const { m, sira } of roller) {
    const rol = sira === 0 ? 1 : m === 'STP' && sira === 1 ? 0.98 : sira === 1 ? 0.88 : 0.8;   // ilk tercihler, rotasyon, derinlik
    const no = m === 'KL' ? KLno[kl++] : numaralar[ni++];
    const o = oyuncuUret(r, { id: yeniId(), kulup: K.id, lig: K.lig, mevki: m, hedefCA: hedef * rol, kullanilan, numara: no, sezon });
    o.sozlesme.maas = maasHesapla(o, K);
    D.oyuncular[o.id] = o; K.oyuncular.push(o.id);
  }
}
export const maasHesapla = (o, K) => Math.max(1500, yuvarla(o.deger * 0.0011 * (0.75 + (K?.guc ?? 4) * 0.06)));
/* teknik ekip (1–20): scout ağı, antrenörler, sportif direktör — kulüp itibarıyla gelir */
export function ekipUret(r, itibar) {
  const t = 4 + itibar / 7;
  const f = () => clamp(Math.round(r.norm(t, 2.2)), 1, 20);
  return { scout: f(), antrenor: f(), sd: f(), saglik: f() };
}

/* ---------- Yardımcılar ---------- */
export const oyuncuAdi = o => `${o.ad} ${o.soyad}`;
export const yildiz = (ca, ref = 150) => clamp(Math.round((ca / ref) * 10) / 2, 0.5, 5);   // 0,5 – 5 yıldız
export function kulupGucu(D, kid, musait = false) {        // en iyi 11'in ortalama yeteneği (musait: sakatlar hariç)
  const K = D.kulupler[kid];
  if (K.hafif || K.oyuncular.length < 11) return K.seviye ?? 80;
  if (musait) { const ca = K.oyuncular.map(id => D.oyuncular[id]).filter(o => !o.sakat && !o.kadroDisi && !(o.ceza > 0) && !o.milliTurnuva).map(o => o.ca).sort((a, b) => b - a).slice(0, 11); if (ca.length >= 11) return Math.round(ca.reduce((s, x) => s + x, 0) / 11); }
  const ca = K.oyuncular.map(id => D.oyuncular[id].ca).sort((a, b) => b - a).slice(0, 11);
  return Math.round(ca.reduce((s, x) => s + x, 0) / ca.length);
}
