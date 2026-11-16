/* Kaptan Mecit lig modu için camia verisi (Champion Battle Manager ile aynı): her kulübün başkanı (ad, tarz), dört büyük / en büyükler
   (derbi kuralı) ve şehri. Başkan adı ve tarzı CBM'de kulüp kimliğinden türediği için iki oyunda da aynıdır.
   Kullanım: node km-camia.mjs <cbm-src> <kaptan-mecit>   → km3/veri/camia.json  { "tr-gs": [başkan, tarz, büyük(0/1), şehir], ... } */
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
globalThis.localStorage ||= { getItem: () => null, setItem: () => {}, removeItem: () => {} };
const [SRC, KOK] = process.argv.slice(2);
const im = p => import(pathToFileURL(`${SRC}/${p}`));
const { dunyaUret, isimUret } = await im('core/dunya.js'), { rng, hash } = await im('core/rng.js');
/* CBM core/camia.js baskanUret ve core/derbi.js buyukler ile birebir aynı hesap (cbm-src'de yalnız dunya/rng olduğu için burada) */
const UY = { tr: 'TR', en: 'EN', es: 'ES', it: 'IT', de: 'DE', fr: 'FR', br: 'BR', ar: 'AR', mx: 'MX', us: 'US', co: 'CO', jp: 'JP', kr: 'KR', sa: 'SA', qa: 'QA', cn: 'CN', eg: 'EG', ma: 'MA', za: 'ZA', dz: 'DZ', tn: 'TN', nl: 'NL', pt: 'PT', be: 'BE', sc: 'SC', at: 'AT', gr: 'GR', au: 'AU' };
const TARZ_SIRA = ['sabirsiz', 'mali', 'populist', 'altyapici', 'vizyoner'], BUYUK_SAYI = { tr: 4, es: 2, de: 2, fr: 2, nl: 3, pt: 3, it: 3 };
const ulkeKod = K => (K?.lig || '').replace(/\d+$/, '').slice(0, 2);
const camiaHazirla = (D, K) => { const r = rng(hash(K.id + 'baskan' + 0) >>> 0); let ad; try { const i = isimUret(r, UY[(K.lig || 'tr').slice(0, 2)] || 'TR', new Set()); ad = `${i.ad} ${i.soyad}`; } catch { ad = ''; } r.int(44, 72); return { baskan: { ad, tarz: TARZ_SIRA[r.int(0, TARZ_SIRA.length - 1)] } }; };
const BK = {}; const buyukler = (D, u) => (BK[u] ||= BUYUK_SAYI[u] ? Object.values(D.kulupler).filter(K => ulkeKod(K) === u).sort((a, b) => (b.itibar ?? 0) - (a.itibar ?? 0)).slice(0, BUYUK_SAYI[u]).map(K => K.id) : []);
const D = dunyaUret(1, (await im('data/turetilmis.js')).default);
const TK = JSON.parse(fs.readFileSync(`${KOK}/km3/veri/takimlar.json`, 'utf8')), out = {};
let var_ = 0, yok = 0;
for (const L of TK.ligler) for (const t of L.takimlar) {
  const K = D.kulupler[`${L.id}-${t.id}`];
  if (!K) { yok++; continue; }
  const B = camiaHazirla(D, K).baskan;
  out[K.id] = [B.ad, B.tarz, buyukler(D, ulkeKod(K)).includes(K.id) ? 1 : 0, K.sehir || ''];
  var_++;
}
fs.writeFileSync(`${KOK}/km3/veri/camia.json`, JSON.stringify(out));
console.log('camia', var_, 'kulüp · eşleşmeyen', yok);
