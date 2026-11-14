/* Yabancı / yerli kuralları: kim listeye girer (oynayabilir), kim kadro dışı kalır. Sonuç oyuncuda o.kadroDisi olarak durur. */
import { KURAL, AB } from '../data/kurallar.js';

export const kuralOf = K => KURAL[(K?.lig || '').slice(0, 2)] || null;
const yerliMi = (o, k, K) => o.muaf || k.yerli?.includes(o.uyruk) || (o.altyapi && o.kulup === K.id) || o.yerliYetisme === K.id;
const yabanciMi = (o, k) => !o.muaf && !k.yerli.includes(o.uyruk);
const abDisi = o => !o.muaf && !AB.has(o.uyruk);

/* kurala göre listeye girmeyenleri bul */
export function kadroDisilari(D, K) {
  const k = kuralOf(K); const O = K.oyuncular.map(id => D.oyuncular[id]).filter(Boolean);
  const disarida = new Set();
  if (!k) return disarida;
  const ca = (a, b) => b.ca - a.ca;
  if (k.tip === 'yabanci') {                                     // 10 serbest + 4 genç (2003 ve sonrası) = en fazla 14
    const Y = O.filter(o => yabanciMi(o, k)).sort(ca);
    let n = 0, yasli = 0;
    for (const o of Y) {
      const genc = (o.dogum || '') >= k.genc;
      if (n < k.max && (genc || yasli < k.serbest)) { n++; if (!genc) yasli++; } else disarida.add(o.id);
    }
  } else if (k.tip === 'abDisi') {
    const Y = O.filter(abDisi).sort(ca);
    for (const o of Y.slice(k.max)) disarida.add(o.id);
  } else if (k.tip === 'yerliYetismis') {
    const Y = O.filter(o => !yerliMi(o, k, K) && o.yas >= k.muafYas).sort(ca);
    for (const o of Y.slice(k.max)) disarida.add(o.id);
  }
  return disarida;
}
export function kurallariUygula(D, K) {
  if (!K || K.hafif) return;
  const d = kadroDisilari(D, K);
  for (const id of K.oyuncular) { const o = D.oyuncular[id]; if (!o) continue; if (d.has(id)) o.kadroDisi = true; else delete o.kadroDisi; }
}
export function tumKurallar(D) { for (const K of Object.values(D.kulupler)) if (!K.hafif) kurallariUygula(D, K); }
/* kulübün kural durumu (ekranda) */
export function kuralDurumu(D, K) {
  const k = kuralOf(K); if (!k) return null;
  const O = K.oyuncular.map(id => D.oyuncular[id]).filter(Boolean);
  if (k.tip === 'yabanci') { const Y = O.filter(o => yabanciMi(o, k)); return { k, sayi: Y.length, sinir: k.max, genc: Y.filter(o => (o.dogum || '') >= k.genc).length, disarida: O.filter(o => o.kadroDisi).length }; }
  if (k.tip === 'abDisi') return { k, sayi: O.filter(abDisi).length, sinir: k.max, disarida: O.filter(o => o.kadroDisi).length };
  if (k.tip === 'yerliYetismis') return { k, sayi: O.filter(o => !yerliMi(o, k, K) && o.yas >= k.muafYas).length, sinir: k.max, disarida: O.filter(o => o.kadroDisi).length };
  if (k.tip === 'yerliSayi') return { k, sayi: O.filter(o => k.yerli.includes(o.uyruk)).length, sinir: k.min, alt: true, disarida: 0 };
  return null;
}
/* SD için: aday kurala takılır mı? (kontenjan dolu ve aday mevcut listedekilerin en zayıfından iyi değilse) */
export function adayKurali(D, K, o) {
  const k = kuralOf(K); if (!k) return { ok: true };
  const O = K.oyuncular.map(id => D.oyuncular[id]).filter(Boolean);
  const kapsamda = k.tip === 'yabanci' ? (x => yabanciMi(x, k)) : k.tip === 'abDisi' ? abDisi : k.tip === 'yerliYetismis' ? (x => !yerliMi(x, k, K) && x.yas >= k.muafYas) : null;
  if (k.tip === 'yerliSayi') { const n = O.filter(x => k.yerli.includes(x.uyruk)).length; return { ok: true, bonus: n < k.min && k.yerli.includes(o.uyruk) ? 8 : 0, neden: n < k.min ? `kadroda ${n} Alman var, en az ${k.min} gerekli` : null }; }
  if (!kapsamda(o)) return { ok: true, bonus: 0 };
  const L = O.filter(x => kapsamda(x) && !x.kadroDisi).sort((a, b) => b.ca - a.ca);
  if (L.length < k.max) return { ok: true, bonus: 0 };
  const zayif = L[L.length - 1];
  return o.ca > zayif.ca + 4 ? { ok: true, bonus: -3, neden: `${k.ad} dolu; gelirse ${zayif.soyad} listeden çıkar` } : { ok: false, neden: `${k.ad} dolu (${L.length}/${k.max})` };
}

/* gerçekten türeyen başlangıç kadroları gerçekte kurala uygundur: fazlalık çifte vatandaşlık, Cotonou anlaşması
   ya da yerli yetişme gibi verimizde görünmeyen durumlardan gelir. Bu oyuncular muaf sayılır; kural yeni gelenlere işler. */
export function baslangicMuafiyeti(D) {
  if (D.kuralSurum >= 1) return;
  for (const K of Object.values(D.kulupler)) {
    if (K.hafif) continue;
    for (const id of kadroDisilari(D, K)) D.oyuncular[id].muaf = true;
  }
  D.kuralSurum = 1;
  tumKurallar(D);
}
