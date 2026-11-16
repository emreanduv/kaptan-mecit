/* Kaptan Mecit lig modu için camia verisi (Champion Battle Manager ile aynı): her kulübün başkanı (ad, tarz), dört büyük / en büyükler
   (derbi kuralı) ve şehri. Başkan adı ve tarzı CBM'de kulüp kimliğinden türediği için iki oyunda da aynıdır.
   Kullanım: node km-camia.mjs <cbm-src> <kaptan-mecit>   → km3/veri/camia.json  { "tr-gs": [başkan, tarz, büyük(0/1), şehir], ... } */
import fs from 'node:fs';
import { pathToFileURL } from 'node:url';
globalThis.localStorage ||= { getItem: () => null, setItem: () => {}, removeItem: () => {} };
const [SRC, KOK] = process.argv.slice(2);
const im = p => import(pathToFileURL(`${SRC}/${p}`));
const { dunyaUret } = await im('core/dunya.js'), { camiaHazirla } = await im('core/camia.js'), { buyukler, ulkeKod } = await im('core/derbi.js');
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
