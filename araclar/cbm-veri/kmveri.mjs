/* CBM'nin türetilmiş dünyasından (Lukaku → Lakaka usulü) Kaptan Mecit verisi: ligler, kulüpler, en iyi 11 (KM yerlerine dizili) ve yedekler */
import { dunyaUret, veriSetiAyarla } from './src/core/dunya.js';
import { uyum } from './src/core/taktik.js';
import fs from 'fs';
const kaynak = JSON.parse(fs.readFileSync(process.argv[2], 'utf8')), eski = JSON.parse(process.argv[3] ? fs.readFileSync(process.argv[3], 'utf8') : '{}');
veriSetiAyarla('turetilmis'); const D = dunyaUret(20261023, kaynak);
const KM_YER = ['KL', 'SLB', 'STP', 'STP', 'SĞB', 'SLK', 'DOS', 'MOS', 'SĞK', 'OOS', 'SF'];
const HARF = { KL: 'K', SĞB: 'D', STP: 'D', SLB: 'D', DOS: 'O', MOS: 'O', SĞO: 'O', SLO: 'O', OOS: 'O', SĞK: 'F', SLK: 'F', SF: 'F' };
const ad = o => `${o.ad ? o.ad[0] + '. ' : ''}${o.soyad}`.trim();
function enIyi11(liste) {   /* önce kaleci + yeteneğe göre aday havuzu, sonra CBM'nin Kaptan Mecit yerleştirmesi (zor yerler önce) */
  const kal = liste.filter(o => o.mevki === 'KL').sort((a, b) => b.ca - a.ca), saha = liste.filter(o => o.mevki !== 'KL').sort((a, b) => b.ca - a.ca);
  const aday = [kal[0], ...saha.slice(0, 14)].filter(Boolean), out = Array(11), kalan = [...aday];
  for (const j of [0, 10, 2, 3, 1, 4, 6, 9, 7, 5, 8]) { let en = 0, es = -1; kalan.forEach((o, k) => { const s = uyum(o, KM_YER[j]) * 1000 + o.ca; if (s > es) { es = s; en = k; } }); out[j] = kalan.splice(en, 1)[0]; }
  return out;
}
const LG = {}, KADRO = {};
for (const lk of ['tr', 'en', 'es', 'it', 'de', 'fr']) {
  const L = D.ligler[lk], E = eski[lk] || {};
  const ks = L.kulupler.map(id => D.kulupler[id]).sort((a, b) => b.guc - a.guc || a.ad.localeCompare(b.ad, 'tr'));
  LG[lk] = { kurgu: L.ad, ad: L.ulke || E.ad, fn: E.fn || [], ln: E.ln || [], t: [] };
  for (const K of ks) {
    const id = K.id.replace(/^[a-z]+-/, '');
    LG[lk].t.push([id, K.ad, K.kisa, K.renk1, K.renk2, Math.max(3, Math.min(9, Math.round(K.guc))), K.sehir]);
    const os = K.oyuncular.map(p => D.oyuncular[p]), xi = enIyi11(os), xiS = new Set(xi);
    const yedek = os.filter(o => !xiS.has(o)).sort((a, b) => b.ca - a.ca);
    const kl = yedek.find(o => o.mevki === 'KL'), yd = [kl, ...yedek.filter(o => o.mevki !== 'KL')].filter(Boolean).slice(0, 9);
    KADRO[lk + ':' + id] = { k: xi.map(o => [o.no, ad(o)]), y: yd.map(o => [o.no, ad(o), HARF[o.mevki] || 'O']) };
  }
}
fs.writeFileSync(process.argv[4], JSON.stringify({ LG, KADRO, kaynak: kaynak.guncel, sezon: kaynak.sezon }));
console.log(Object.entries(LG).map(([k, v]) => k + ':' + v.t.length).join(' '), Object.keys(KADRO).length, JSON.stringify(KADRO['tr:' + LG.tr.t[0][0]]).slice(0, 400));
