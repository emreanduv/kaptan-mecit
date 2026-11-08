/* Champion Battle Manager'ın türetilmiş dünyasından (veri/cbm/v1/dunya.json, 28 lig) Kaptan Mecit verisi.
   CBM'nin kendi kodunu (src/core/dunya.js dunyaUret + taktik.js uyum) kullanır; CBM kaynağında henüz olmayan ligleri
   (ad/ülke dunya.json'dan) ve lig itibarlarını burada ekler. Çıktı: Klasik için LG/KADRO/HAVUZ, Modern için takimlar.json.
   Kullanım: node km28.mjs <cbm-src-klasörü> <dunya.json> <cikti-klasik.json> <cikti-km3.json> */
import fs from 'fs'; import path from 'path'; import { pathToFileURL } from 'url';
const [SRC, DUNYA, CIKTI_K, CIKTI_M] = process.argv.slice(2);
const kaynak = JSON.parse(fs.readFileSync(DUNYA, 'utf8'));

/* Lig itibarı (CBM'deki en:1 … tr:.8 ölçeği). CBM kaynağı yeni ligleri tanımlayınca oradaki değerler geçerli olur. */
export const ITIBAR = { en: 1, es: .97, it: .95, de: .93, fr: .88, pt: .86, nl: .85, br: .84, tr: .8, be: .8, ar: .8, sa: .74, mx: .74,
  at: .74, us: .72, sc: .72, gr: .72, co: .7, jp: .7, kr: .66, ma: .64, eg: .62, qa: .62, au: .62, cn: .6, tn: .58, dz: .58, za: .58 };
const KITA = { en: 'Avrupa', es: 'Avrupa', it: 'Avrupa', de: 'Avrupa', fr: 'Avrupa', pt: 'Avrupa', nl: 'Avrupa', tr: 'Avrupa', be: 'Avrupa', at: 'Avrupa', sc: 'Avrupa', gr: 'Avrupa',
  br: 'Amerika', ar: 'Amerika', mx: 'Amerika', us: 'Amerika', co: 'Amerika', sa: 'Asya', jp: 'Asya', kr: 'Asya', qa: 'Asya', cn: 'Asya', au: 'Asya',
  ma: 'Afrika', eg: 'Afrika', tn: 'Afrika', dz: 'Afrika', za: 'Afrika' };

/* CBM kaynağını geçici bir kopyada genişlet: yeni ligler, itibar, uyruk */
const TMP = fs.mkdtempSync('/tmp/km28-'); fs.cpSync(SRC, TMP + '/src', { recursive: true });
const sira = Object.keys(kaynak.ligler).sort((a, b) => (ITIBAR[b] ?? .6) - (ITIBAR[a] ?? .6));
let lig = fs.readFileSync(TMP + '/src/data/ligler.js', 'utf8');
const ek = Object.fromEntries(Object.entries(kaynak.ligler).map(([k, l]) => [k, { kod: k, ad: l.ad, ulke: l.ulke, kulupler: [] }]));
lig = lig.replace(/export const LIG_SIRASI = .*;/, `export const LIG_SIRASI = ${JSON.stringify(sira)};\nfor (const [k, v] of Object.entries(${JSON.stringify(ek)})) if (!LIGLER[k]) LIGLER[k] = v;`);
fs.writeFileSync(TMP + '/src/data/ligler.js', lig);
let du = fs.readFileSync(TMP + '/src/core/dunya.js', 'utf8');
du = du.replace(/export const LIG_ITIBAR = \{[^}]*\};/, `export const LIG_ITIBAR = ${JSON.stringify(ITIBAR)};`);
fs.writeFileSync(TMP + '/src/core/dunya.js', du);
let hv = fs.readFileSync(TMP + '/src/data/names/havuz.js', 'utf8');
const yerli = Object.fromEntries(Object.entries(kaynak.ligler).map(([k, l]) => { const c = {}; for (const cl of l.kulupler) for (const o of cl.oyuncular) if (o.uyruk) c[o.uyruk] = (c[o.uyruk] || 0) + 1; return [k, Object.entries(c).sort((a, b) => b[1] - a[1])[0]?.[0] || 'EN']; }));
hv += `\nfor (const [k, y] of Object.entries(${JSON.stringify(yerli)})) if (!LIG_UYRUK[k]) LIG_UYRUK[k] = { yerli: y, oran: .65, yabanci: { BR: 3, AR: 2, FR: 2, ES: 1, PT: 1, NG: 1, SN: 1 } };
for (const u of ${JSON.stringify([...new Set(Object.values(yerli))])}) if (!UYRUK[u]) UYRUK[u] = { ad: u, b: '', dil: ['en'] };\n`;
fs.writeFileSync(TMP + '/src/data/names/havuz.js', hv);

const { dunyaUret, veriSetiAyarla } = await import(pathToFileURL(TMP + '/src/core/dunya.js'));
const { uyum } = await import(pathToFileURL(TMP + '/src/core/taktik.js'));
veriSetiAyarla('turetilmis'); const D = dunyaUret(20261023, kaynak);

const KM_YER = ['KL', 'SLB', 'STP', 'STP', 'SĞB', 'SLK', 'DOS', 'MOS', 'SĞK', 'OOS', 'SF'];
const HARF = { KL: 'K', SĞB: 'D', STP: 'D', SLB: 'D', DOS: 'O', MOS: 'O', SĞO: 'O', SLO: 'O', OOS: 'O', SĞK: 'F', SLK: 'F', SF: 'F' };
const ad = o => `${o.ad ? o.ad[0] + '. ' : ''}${o.soyad}`.trim();
function enIyi11(liste) {
  const kal = liste.filter(o => o.mevki === 'KL').sort((a, b) => b.ca - a.ca), saha = liste.filter(o => o.mevki !== 'KL').sort((a, b) => b.ca - a.ca);
  const aday = [kal[0], ...saha.slice(0, 14)].filter(Boolean), out = Array(11), kalan = [...aday];
  for (const j of [0, 10, 2, 3, 1, 4, 6, 9, 7, 5, 8]) { let en = 0, es = -1; kalan.forEach((o, k) => { const s = uyum(o, KM_YER[j]) * 1000 + o.ca; if (s > es) { es = s; en = k; } }); out[j] = kalan.splice(en, 1)[0]; }
  return out;
}
/* KM gücü (3–9): CBM kulüp gücü × lig itibarı, ligler arası karşılaştırılabilir */
const kmGuc = (K, lk) => Math.max(3, Math.min(9, Math.round(K.guc * (0.55 + 0.45 * (ITIBAR[lk] ?? .6) / 1))));
const LG = {}, KADRO = {}, HAVUZ = {}, KARIYER = {}, KLUP = [], KLUP_I = new Map();
/* kariyer geçmişi (Champion 4.5.0'daki gibi): dunya.json oyuncu 'g' = [[başlangıç, bitiş(0=sürüyor), kulüp, maç, gol, kiralık?]], 'mi' = [A milli maç, gol] */
const KAY = new Map();
for (const l of Object.values(kaynak.ligler)) for (const c of l.kulupler) for (const o of c.oyuncular) if (o.k != null && (o.g || o.mi)) KAY.set(o.k, o);
const klupAd = ref => { if (typeof ref === 'string') { const K = D.kulupler[ref]; return K ? K.ad : null; } const n = (kaynak.disKulup || [])[ref]; return n ? `${n.sehir} ${n.renkAd?.length ? n.renkAd.join('-') : 'Spor'}` : null; };
const klupNo = ad => { if (!KLUP_I.has(ad)) { KLUP_I.set(ad, KLUP.length); KLUP.push(ad); } return KLUP_I.get(ad); };
for (const lk of sira) {
  const L = D.ligler[lk];
  const ks = L.kulupler.map(id => D.kulupler[id]).sort((a, b) => b.guc - a.guc || a.ad.localeCompare(b.ad, 'tr'));
  LG[lk] = { kurgu: L.ad, ad: L.ulke, kita: KITA[lk] || 'Dünya', itibar: ITIBAR[lk] ?? .6, t: [] };
  for (const K of ks) {
    const id = K.id.replace(/^[a-z]+-/, '');
    LG[lk].t.push([id, K.ad, K.kisa, K.renk1, K.renk2, kmGuc(K, lk), K.sehir]);
    const os = K.oyuncular.map(p => D.oyuncular[p]), xi = enIyi11(os), xiS = new Set(xi);
    const yedek = os.filter(o => !xiS.has(o)).sort((a, b) => b.ca - a.ca);
    const kl = yedek.find(o => o.mevki === 'KL'), yd = [kl, ...yedek.filter(o => o.mevki !== 'KL')].filter(Boolean).slice(0, 9);
    KADRO[lk + ':' + id] = { k: xi.map(o => [o.no, ad(o)]), y: yd.map(o => [o.no, ad(o), HARF[o.mevki] || 'O']) };
    const kls = os.filter(o => o.mevki === 'KL').sort((a, b) => b.ca - a.ca).slice(0, 2), saha = os.filter(o => o.mevki !== 'KL').sort((a, b) => b.ca - a.ca).slice(0, 20);
    HAVUZ[lk + ':' + id] = [...kls, ...saha].map(o => [o.no, ad(o), o.mevki, (o.ikinci || []).join(','), o.ca]);
    for (const o of [...kls, ...saha]) { const k = KAY.get(o.anahtar); if (!k) continue;
      const g = (k.g || []).map(x => { const a = klupAd(x[2]); return a ? [x[0], x[1], klupNo(a), x[3] || 0, x[4] || 0, x[5] ? 1 : 0] : null; }).filter(Boolean);
      if (g.length || k.mi) KARIYER[lk + ':' + id + ':' + o.no] = k.mi ? [g, k.mi] : [g]; }
  }
}
fs.writeFileSync(CIKTI_K, JSON.stringify({ LG, KADRO, HAVUZ, KARIYER, KLUP, sira, kaynak: kaynak.guncel, sezon: kaynak.sezon }));
fs.rmSync(TMP, { recursive: true, force: true });
console.log(sira.map(k => k + ':' + LG[k].t.length).join(' '), '| kulüp', Object.keys(KADRO).length, '| boyut', fs.statSync(CIKTI_K).size);
