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
/* CBM 4.8 "oyuncu gücü gerçek kariyerden" (CBM 4.8.0, 14 Kas 2026; CBM paketindeki ld/md'nin aynısı): kulüp içindeki sıra artık
   yalnız ün (un) değil, ün + A milli maç + son 5 yılda oynadığı liglerin düzeyi + forvet/orta sahada maç başına gol karışımı (v).
   Hedef yetenek: kulüp tabanı × (1.12 − 0.36 × sıra) + (v − ortalama v) × 40. */
const KM_LD = `
const KM_YD = {TR:"tr",GB:"en",EN:"en",DE:"de",ES:"es",IT:"it",FR:"fr",NL:"nl",PT:"pt",BE:"be",AT:"at",GR:"gr",AR:"ar",BR:"br",MX:"mx",US:"us",JP:"jp",KR:"kr",SA:"sa",QA:"qa",CN:"cn",AU:"au",EG:"eg",MA:"ma",ZA:"za",DZ:"dz",TN:"tn"};
let KM_DIS = [];
function kmRd(c) { if (typeof c === 'string') return ligItibar(c.split('-')[0]); const u = KM_YD[KM_DIS[c]?.ulke]; return u && LIG_ITIBAR[u] != null ? LIG_ITIBAR[u] * .9 : .45; }
const KM_GOLCU = ['SF', 'SĞK', 'SLK'], KM_ORTA = ['OOS', 'SĞO', 'SLO', 'MOS'];
function kmLd(o, mevki, sezon = SEZON) {
  const mi = o.mi?.[0] > 0 ? o.mi[0] : 0, a = Math.min(1, Math.log1p(mi) / Math.log1p(80));
  const k = (o.g || []).filter(S => (S[1] || sezon) >= sezon - 4 && S[3] > 0 && !S[5]), mac = k.reduce((s, c) => s + c[3], 0);
  const y = mac ? clamp((k.reduce((s, c) => s + c[3] * kmRd(c[2]), 0) / mac - .45) / .55, 0, 1) * Math.min(1, mac / 60) : null;
  const gol = k.reduce((s, c) => s + Math.max(0, c[4]), 0), gm = mac >= 10 ? gol / mac : 0;
  const r = KM_GOLCU.includes(mevki) ? Math.min(1, gm / .55) : KM_ORTA.includes(mevki) ? Math.min(1, gm / .25) : 0, un = o.un || 0;
  return y == null ? .7 * un + .3 * a : .45 * un + .25 * a + .22 * y + .08 * r;
}`;
du += KM_LD;
du = du.replace("const sahip = [...c.kaynak.oyuncular].sort((a, b) => (b.un || 0) - (a.un || 0));",
  "const kmv = new Map(c.kaynak.oyuncular.map(o => [o, kmLd(o, o.mevki)])); const sahip = [...c.kaynak.oyuncular].sort((a, b) => kmv.get(b) - kmv.get(a));");
du = du.replace("unOrt = atanan.reduce((s, [o]) => s + (o.un || 0), 0) / Math.max(1, n);", "unOrt = atanan.reduce((s, [o]) => s + kmv.get(o), 0) / Math.max(1, n);");
du = du.replace("const ca = hedef * (1.12 - 0.36 * rk) + ((o.un || 0) - unOrt) * 34;", "const ca = hedef * (1.12 - 0.36 * rk) + (kmv.get(o) - unOrt) * 40;");
du = du.replace("export function dunyaUret(tohum = Date.now() >>> 0, kaynak = null) {", "export function dunyaUret(tohum = Date.now() >>> 0, kaynak = null) {\n  KM_DIS = kaynak?.disKulup || [];");
for (const z of ['kmv.get(b) - kmv.get(a)', 'kmv.get(o), 0)', '(kmv.get(o) - unOrt) * 40', 'KM_DIS = kaynak']) if (!du.includes(z)) throw new Error('CBM 4.8 güç yaması tutmadı: ' + z);
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
/* Milli takımlar (CBM 4.11 milli takım menajerliğinin KM karşılığı, Gelişim Defteri G47): dünyanın bütün oyuncuları uyruklarına göre;
   en güçlü 32 ülke 'mt' ligi olur (Kaptan Mecit'te hazırlık maçı, lig ve turnuva). Kadro: en iyi 2 kaleci + 20 saha oyuncusu, forma no 1–23. */
const { uyrukBilgi } = await import(pathToFileURL(TMP + '/src/data/names/havuz.js'));
const FORMA = { TR: ['#e30a17', '#ffffff'], EN: ['#ffffff', '#1d2d5c'], DE: ['#ffffff', '#111111'], FR: ['#1f3b8c', '#ffffff'], ES: ['#c60b1e', '#1d2d5c'], IT: ['#1f5fbf', '#ffffff'],
  PT: ['#a5001e', '#0b6b3a'], NL: ['#f36c21', '#ffffff'], BE: ['#c8102e', '#111111'], BR: ['#ffdf00', '#1f5fbf'], AR: ['#75aadb', '#ffffff'], UY: ['#5ba3dc', '#111111'],
  HR: ['#e8e8e8', '#d0021b'], JP: ['#1c2c6b', '#ffffff'], KR: ['#d0021b', '#111111'], US: ['#ffffff', '#1d2d5c'], MX: ['#0b6b3a', '#ffffff'], MA: ['#c1272d', '#0b6b3a'],
  SN: ['#ffffff', '#0b8a3e'], NG: ['#0b8a3e', '#ffffff'], CO: ['#fcd116', '#1d2d5c'], SC: ['#1d2d5c', '#ffffff'], WL: ['#d0021b', '#ffffff'], CH: ['#d52b1e', '#ffffff'],
  AT: ['#ed2939', '#ffffff'], DK: ['#c8102e', '#ffffff'], SE: ['#fecc00', '#1f5fbf'], NO: ['#ba0c2f', '#ffffff'], PL: ['#ffffff', '#dc143c'], RS: ['#c6363c', '#1d2d5c'],
  GR: ['#0d5eaf', '#ffffff'], CI: ['#f77f00', '#ffffff'], DZ: ['#ffffff', '#006233'], EG: ['#ce1126', '#ffffff'], SA: ['#006c35', '#ffffff'], AU: ['#ffcd00', '#0b6b3a'],
  CM: ['#007a5e', '#ce1126'], GH: ['#ffffff', '#111111'], TN: ['#e70013', '#ffffff'], UA: ['#ffd500', '#005bbb'], CZ: ['#d7141a', '#ffffff'], IE: ['#169b62', '#ffffff'] };
const forma = uy => { if (FORMA[uy]) return FORMA[uy]; let h = 0; for (const c of 'forma' + uy) h = (h * 31 + c.charCodeAt(0)) >>> 0;
  const P = ['#c0392b', '#1f5fbf', '#0b6b3a', '#f1c40f', '#ffffff', '#111111', '#8e44ad', '#e67e22', '#16a085', '#2c3e50'], a = P[h % P.length]; let b = P[(h >> 4) % P.length]; if (b === a) b = a === '#ffffff' ? '#111111' : '#ffffff'; return [a, b]; };
const ULKE_TR = { GR: 'Yunanistan', EC: 'Ekvador', HU: 'Macaristan', PY: 'Paraguay', CA: 'Kanada', ML: 'Mali', CD: 'Kongo DC', GE: 'Gürcistan', BA: 'Bosna-Hersek', SK: 'Slovakya',
  IS: 'İzlanda', RO: 'Romanya', AL: 'Arnavutluk', CL: 'Şili', VE: 'Venezuela', BF: 'Burkina Faso', GN: 'Gine', ID: 'Endonezya', IL: 'İsrail', UA: 'Ukrayna', CZ: 'Çekya', IE: 'İrlanda',
  CM: 'Kamerun', GH: 'Gana', TN: 'Tunus', EG: 'Mısır', SA: 'Suudi Arabistan', AU: 'Avustralya', NG: 'Nijerya', SN: 'Senegal', CI: 'Fildişi Sahili', DZ: 'Cezayir', RS: 'Sırbistan',
  DK: 'Danimarka', CH: 'İsviçre', PL: 'Polonya', NO: 'Norveç', SE: 'İsveç', AT: 'Avusturya', HR: 'Hırvatistan', UY: 'Uruguay', CO: 'Kolombiya', KR: 'Güney Kore', JP: 'Japonya', MA: 'Fas', MX: 'Meksika', US: 'ABD' };
const KISA = { TR: 'TÜR', EN: 'ING', DE: 'ALM', FR: 'FRA', ES: 'İSP', IT: 'İTA', PT: 'POR', NL: 'HOL', BE: 'BEL', BR: 'BRE', AR: 'ARJ', UY: 'URU', HR: 'HIR', JP: 'JAP', KR: 'KOR',
  US: 'ABD', MX: 'MEK', MA: 'FAS', SN: 'SEN', NG: 'NİJ', CO: 'KOL', SC: 'İSK', WL: 'GAL', CH: 'İSV', AT: 'AVU', DK: 'DAN', SE: 'İSÇ', NO: 'NOR', PL: 'POL', RS: 'SIR',
  GR: 'YUN', CI: 'FİL', DZ: 'CEZ', EG: 'MIS', SA: 'SUU', AU: 'AVS', CM: 'KAM', GH: 'GAN', TN: 'TUN', UA: 'UKR', CZ: 'ÇEK', IE: 'İRL', EC: 'EKV', HU: 'MAC', PY: 'PAR', CA: 'KAN', ML: 'MAL', CD: 'KON', GE: 'GÜR', BA: 'BOS', SK: 'SLK', IS: 'İZL', RO: 'ROM', AL: 'ARN', CL: 'ŞİL', VE: 'VEN', BF: 'BUR', GN: 'GİN', ID: 'END', IL: 'İSR' };
{
  const U = {};
  for (const o of Object.values(D.oyuncular)) if (o.uyruk && o.kulup) (U[o.uyruk] ||= []).push(o);
  const ulke = Object.entries(U).filter(([, L]) => L.length >= 16 && L.filter(o => o.mevki === 'KL').length >= 2)
    .map(([k, L]) => { L.sort((a, b) => b.ca - a.ca); return [k, L, L.slice(0, 11).reduce((s, o) => s + o.ca, 0) / 11]; })
    .sort((a, b) => b[2] - a[2]).slice(0, 32);
  const gMax = ulke[0][2], gMin = ulke[ulke.length - 1][2];
  LG.mt = { kurgu: 'Milli Takımlar', ad: 'Dünya', kita: 'Milli', itibar: 1, t: [] };
  for (const [uy, L] of ulke) {
    const id = uy.toLowerCase(), ad0 = uyrukBilgi(uy).ad, ad_ = ad0 && ad0 !== uy ? ad0 : (ULKE_TR[uy] || uy), [c1, c2] = forma(uy);
    const guc = Math.max(4, Math.min(9, Math.round(4 + 5 * (ulke.find(x => x[0] === uy)[2] - gMin) / Math.max(1, gMax - gMin))));
    LG.mt.t.push([id, ad_, KISA[uy] || ad_.toLocaleUpperCase('tr').slice(0, 3), c1, c2, guc, '']);
    const kls = L.filter(o => o.mevki === 'KL').slice(0, 2), saha = L.filter(o => o.mevki !== 'KL').slice(0, 20);
    const NO = [1, 12, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 13, 14, 15, 16, 17, 18, 19, 20, 21, 22], yeni = new Map([...kls, ...saha].map((o, i) => [o, { ...o, no: NO[i] }]));
    const os = [...yeni.values()], xi = enIyi11(os), xiS = new Set(xi);
    const yedek = os.filter(o => !xiS.has(o)).sort((a, b) => b.ca - a.ca);
    const kl = yedek.find(o => o.mevki === 'KL'), yd = [kl, ...yedek.filter(o => o.mevki !== 'KL')].filter(Boolean).slice(0, 9);
    KADRO['mt:' + id] = { k: xi.map(o => [o.no, ad(o)]), y: yd.map(o => [o.no, ad(o), HARF[o.mevki] || 'O']) };
    HAVUZ['mt:' + id] = os.map(o => [o.no, ad(o), o.mevki, (o.ikinci || []).join(','), o.ca]);
    for (const o of os) { const k = KAY.get(o.anahtar); if (!k) continue;
      const g = (k.g || []).map(x => { const a = klupAd(x[2]); return a ? [x[0], x[1], klupNo(a), x[3] || 0, x[4] || 0, x[5] ? 1 : 0] : null; }).filter(Boolean);
      if (g.length || k.mi) KARIYER['mt:' + id + ':' + o.no] = k.mi ? [g, k.mi] : [g]; }
  }
  sira.push('mt');
}
fs.writeFileSync(CIKTI_K, JSON.stringify({ LG, KADRO, HAVUZ, KARIYER, KLUP, sira, kaynak: kaynak.guncel, sezon: kaynak.sezon }));
fs.rmSync(TMP, { recursive: true, force: true });
console.log(sira.map(k => k + ':' + LG[k].t.length).join(' '), '| kulüp', Object.keys(KADRO).length, '| boyut', fs.statSync(CIKTI_K).size);
