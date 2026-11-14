/* Dizilişler, asistanın ilk 11 seçimi ve takım görevleri.
   Yer koordinatları göreli: rx kendi kalesinden uzaklık (0–105), ry 0 sağ kanat – 68 sol kanat. */
import { MEVKI } from '../data/ozellikler.js';

export const DIZILIS = {
  '4-4-2': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['SĞO', 32, 12], ['MOS', 30, 29], ['MOS', 30, 39], ['SLO', 32, 56], ['SF', 45, 31], ['SF', 46, 39]],
  '4-4-2 Elmas': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['DOS', 26, 34], ['MOS', 32, 22], ['MOS', 32, 46], ['OOS', 39, 34], ['SF', 46, 30], ['SF', 46, 38]],
  '4-4-2 Savunma': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['SĞO', 31, 12], ['DOS', 27, 29], ['DOS', 27, 39], ['SLO', 31, 56], ['SF', 45, 31], ['SF', 46, 39]],
  '4-4-1-1': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['SĞO', 32, 12], ['MOS', 30, 29], ['MOS', 30, 39], ['SLO', 32, 56], ['OOS', 40, 34], ['SF', 47, 34]],
  '4-4-2 Dar': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['MOS', 31, 22], ['DOS', 27, 34], ['MOS', 31, 46], ['OOS', 38, 34], ['SF', 46, 30], ['SF', 46, 38]],
  '4-3-3': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['DOS', 27, 34], ['MOS', 33, 25], ['MOS', 33, 43], ['SĞK', 44, 11], ['SLK', 44, 57], ['SF', 47, 34]],
  '4-3-3 Hücum': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['MOS', 30, 25], ['MOS', 30, 43], ['OOS', 37, 34], ['SĞK', 44, 11], ['SLK', 44, 57], ['SF', 47, 34]],
  '4-3-3 Savunma': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['DOS', 27, 27], ['DOS', 27, 41], ['MOS', 32, 34], ['SĞK', 43, 11], ['SLK', 43, 57], ['SF', 47, 34]],
  '4-2-3-1': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['DOS', 27, 29], ['DOS', 27, 39], ['SĞK', 40, 11], ['OOS', 39, 34], ['SLK', 40, 57], ['SF', 47, 34]],
  '4-2-3-1 Geniş': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['DOS', 27, 29], ['MOS', 29, 39], ['SĞO', 36, 8], ['OOS', 39, 34], ['SLO', 36, 60], ['SF', 47, 34]],
  '4-1-4-1': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['DOS', 25, 34], ['SĞO', 34, 11], ['MOS', 34, 28], ['MOS', 34, 40], ['SLO', 34, 57], ['SF', 46, 34]],
  '4-5-1': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['SĞO', 32, 11], ['MOS', 31, 24], ['DOS', 28, 34], ['MOS', 31, 44], ['SLO', 32, 57], ['SF', 46, 34]],
  '4-3-2-1': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['DOS', 27, 34], ['MOS', 31, 23], ['MOS', 31, 45], ['OOS', 39, 26], ['OOS', 39, 42], ['SF', 47, 34]],
  '4-3-1-2': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['DOS', 27, 34], ['MOS', 31, 23], ['MOS', 31, 45], ['OOS', 38, 34], ['SF', 46, 29], ['SF', 46, 39]],
  '4-2-2-2': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['DOS', 27, 28], ['DOS', 27, 40], ['OOS', 37, 15], ['OOS', 37, 53], ['SF', 46, 29], ['SF', 46, 39]],
  '4-1-3-2': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['DOS', 26, 34], ['SĞO', 33, 12], ['MOS', 32, 34], ['SLO', 33, 56], ['SF', 46, 29], ['SF', 46, 39]],
  '4-2-4': [['KL', 4, 34], ['SĞB', 17, 10], ['STP', 15, 26], ['STP', 15, 42], ['SLB', 17, 58], ['MOS', 29, 28], ['MOS', 29, 40], ['SĞK', 43, 10], ['SF', 46, 28], ['SF', 46, 40], ['SLK', 43, 58]],
  '3-5-2': [['KL', 4, 34], ['STP', 15, 22], ['STP', 14, 34], ['STP', 15, 46], ['SĞO', 31, 7], ['DOS', 27, 34], ['MOS', 33, 26], ['MOS', 33, 42], ['SLO', 31, 61], ['SF', 45, 30], ['SF', 46, 38]],
  '3-4-3': [['KL', 4, 34], ['STP', 15, 22], ['STP', 14, 34], ['STP', 15, 46], ['SĞO', 32, 8], ['MOS', 30, 28], ['MOS', 30, 40], ['SLO', 32, 60], ['SĞK', 44, 14], ['SF', 47, 34], ['SLK', 44, 54]],
  '3-4-3 Elmas': [['KL', 4, 34], ['STP', 15, 22], ['STP', 14, 34], ['STP', 15, 46], ['DOS', 26, 34], ['SĞO', 32, 10], ['SLO', 32, 58], ['OOS', 38, 34], ['SĞK', 44, 14], ['SF', 47, 34], ['SLK', 44, 54]],
  '3-4-1-2': [['KL', 4, 34], ['STP', 15, 22], ['STP', 14, 34], ['STP', 15, 46], ['SĞO', 31, 8], ['MOS', 29, 28], ['MOS', 29, 40], ['SLO', 31, 60], ['OOS', 39, 34], ['SF', 46, 29], ['SF', 46, 39]],
  '3-4-2-1': [['KL', 4, 34], ['STP', 15, 22], ['STP', 14, 34], ['STP', 15, 46], ['SĞO', 31, 8], ['MOS', 29, 28], ['MOS', 29, 40], ['SLO', 31, 60], ['OOS', 39, 24], ['OOS', 39, 44], ['SF', 47, 34]],
  '3-5-1-1': [['KL', 4, 34], ['STP', 15, 22], ['STP', 14, 34], ['STP', 15, 46], ['SĞO', 31, 7], ['DOS', 27, 34], ['MOS', 32, 25], ['MOS', 32, 43], ['SLO', 31, 61], ['OOS', 40, 34], ['SF', 47, 34]],
  '3-1-4-2': [['KL', 4, 34], ['STP', 15, 22], ['STP', 14, 34], ['STP', 15, 46], ['DOS', 25, 34], ['SĞO', 32, 8], ['MOS', 32, 27], ['MOS', 32, 41], ['SLO', 32, 60], ['SF', 46, 29], ['SF', 46, 39]],
  '3-6-1': [['KL', 4, 34], ['STP', 15, 22], ['STP', 14, 34], ['STP', 15, 46], ['SĞO', 31, 7], ['DOS', 27, 27], ['DOS', 27, 41], ['SLO', 31, 61], ['OOS', 37, 24], ['OOS', 37, 44], ['SF', 47, 34]],
  '3-3-4': [['KL', 4, 34], ['STP', 15, 22], ['STP', 14, 34], ['STP', 15, 46], ['DOS', 27, 34], ['MOS', 31, 22], ['MOS', 31, 46], ['SĞK', 43, 10], ['SF', 46, 28], ['SF', 46, 40], ['SLK', 43, 58]],
  '5-3-2': [['KL', 4, 34], ['SĞB', 20, 7], ['STP', 14, 22], ['STP', 13, 34], ['STP', 14, 46], ['SLB', 20, 61], ['MOS', 30, 25], ['DOS', 28, 34], ['MOS', 30, 43], ['SF', 44, 30], ['SF', 45, 38]],
  '5-4-1': [['KL', 4, 34], ['SĞB', 20, 7], ['STP', 14, 22], ['STP', 13, 34], ['STP', 14, 46], ['SLB', 20, 61], ['SĞO', 31, 12], ['MOS', 29, 28], ['MOS', 29, 40], ['SLO', 31, 56], ['SF', 45, 34]],
  '5-4-1 Elmas': [['KL', 4, 34], ['SĞB', 20, 7], ['STP', 14, 22], ['STP', 13, 34], ['STP', 14, 46], ['SLB', 20, 61], ['DOS', 26, 34], ['SĞO', 31, 14], ['SLO', 31, 54], ['OOS', 37, 34], ['SF', 46, 34]],
  '5-2-3': [['KL', 4, 34], ['SĞB', 20, 7], ['STP', 14, 22], ['STP', 13, 34], ['STP', 14, 46], ['SLB', 20, 61], ['MOS', 30, 28], ['MOS', 30, 40], ['SĞK', 43, 14], ['SF', 46, 34], ['SLK', 43, 54]],
  '5-2-1-2': [['KL', 4, 34], ['SĞB', 20, 7], ['STP', 14, 22], ['STP', 13, 34], ['STP', 14, 46], ['SLB', 20, 61], ['DOS', 27, 28], ['DOS', 27, 40], ['OOS', 37, 34], ['SF', 46, 29], ['SF', 46, 39]],
  '5-3-1-1': [['KL', 4, 34], ['SĞB', 20, 7], ['STP', 14, 22], ['STP', 13, 34], ['STP', 14, 46], ['SLB', 20, 61], ['MOS', 30, 24], ['DOS', 27, 34], ['MOS', 30, 44], ['OOS', 39, 34], ['SF', 47, 34]],
  '5-2-2-1': [['KL', 4, 34], ['SĞB', 20, 7], ['STP', 14, 22], ['STP', 13, 34], ['STP', 14, 46], ['SLB', 20, 61], ['DOS', 27, 28], ['DOS', 27, 40], ['OOS', 38, 21], ['OOS', 38, 47], ['SF', 47, 34]],
  '5-3-2 Kanat': [['KL', 4, 34], ['SĞB', 23, 6], ['STP', 14, 22], ['STP', 13, 34], ['STP', 14, 46], ['SLB', 23, 62], ['MOS', 31, 26], ['DOS', 27, 34], ['MOS', 31, 42], ['SF', 45, 30], ['SF', 46, 38]],
};
export const DIZILIS_SIRA = Object.keys(DIZILIS);
/* ekranda üç grup: üçlü, dörtlü, beşli savunma */
export const DIZILIS_GRUP = [['3', 'Üçlü savunma'], ['4', 'Dörtlü savunma'], ['5', 'Beşli savunma']].map(([g, ad]) => [ad, Object.keys(DIZILIS).filter(k => k[0] === g)]);
/* yapay zekâ kulüplerin diziliş seçiminde gerçek futboldaki yaygınlık payı (kadroya en uygun olan kazanır; eşitlikte yaygın olan) */
const YAYGIN = { '4-2-3-1': 1.035, '4-3-3': 1.035, '4-4-2': 1.03, '4-1-4-1': 1.02, '3-5-2': 1.015, '3-4-3': 1.015, '5-3-2': 1.01, '4-3-3 Hücum': 1.01, '3-4-2-1': 1.01, '4-4-1-1': 1.01, '5-4-1': 1.0, '4-2-3-1 Geniş': 1.0,
  '4-2-4': 0.95, '3-3-4': 0.95, '4-2-2-2': 0.96, '3-6-1': 0.96, '5-2-2-1': 0.96, '4-4-2 Dar': 0.96, '5-3-2 Kanat': 0.97, '4-3-2-1': 0.97, '4-4-2 Elmas': 0.975, '5-3-1-1': 0.97 };
export const yayginlik = dz => YAYGIN[dz] ?? 0.985;
export const arkaSayisi = dz => (DIZILIS[dz] || []).filter(y => ['SĞB', 'SLB', 'STP'].includes(y[0])).length;


export const ZIHNIYET = [['savunma', '🛡️ Savunma'], ['dengeli', '⚖️ Dengeli'], ['hucum', '⚔️ Hücum']];
export const PRES = [['dusuk', 'Düşük'], ['orta', 'Orta'], ['yuksek', 'Yüksek']];

/* yer uyumu: aynı mevki tam, yakın mevki iyi, aynı bölge orta */
const YAKIN_YER = {
  MOS: ['DOS', 'OOS'], DOS: ['MOS', 'STP'], OOS: ['MOS', 'SF', 'SĞK', 'SLK'], SĞO: ['SĞK', 'SĞB'], SLO: ['SLK', 'SLB'],
  SĞK: ['SĞO', 'SF', 'OOS'], SLK: ['SLO', 'SF', 'OOS'], SF: ['OOS', 'SĞK', 'SLK'], SĞB: ['SĞO', 'STP'], SLB: ['SLO', 'STP'], STP: ['DOS', 'SĞB', 'SLB'],
};
export function uyum(o, yer) {                               // 0–1
  if (o.mevki === yer) return 1;
  if (o.ikinci?.includes(yer)) return 0.92;
  const yi = (YAKIN_YER[yer] || []).indexOf(o.mevki);
  if (yi >= 0) return yi === 0 ? 0.87 : 0.82;                // en yakın mevki (ör. MOS → DOS) bir tık önde
  if (yer === 'KL' || o.mevki === 'KL') return 0.05;
  return MEVKI[o.mevki].grup === MEVKI[yer].grup ? 0.7 : 0.45;
}
export const etkinlik = (o, yer) => Math.round(o.ca * uyum(o, yer) * (0.7 + 0.3 * (o.kondisyon ?? 100) / 100));

/* asistan: diziliş için en iyi 11 (zor yerlerden başlayarak), sonra 9 yedek (önce kaleci) */
/* maç günü seçimi: son maç notları (form), kondisyon ve moral. Yorgun ya da formsuz oyuncu yerini formdaki yedeğe bırakır. */
const clamp01 = x => Math.max(0.35, Math.min(1.2, x));
export const formOrt = o => { const f = (o.form || []).slice(-4); return f.length ? f.reduce((a, b) => a + b, 0) / f.length : null; };
export function gunlukCarpan(o) {
  const k = o.kondisyon ?? 100, f = formOrt(o);
  const kc = k >= 92 ? 1 : k >= 86 ? 0.95 : k >= 80 ? 0.86 : k >= 72 ? 0.74 : 0.55;        // yorgun oyuncu dinlendirilir (sakatlık riski)
  const fc = f == null ? 1 : 1 + Math.max(-0.14, Math.min(0.1, (f - 6.8) * 0.1));
  const mc = 1 + Math.max(-0.03, Math.min(0.03, ((o.moral ?? 13) - 13) * 0.006));
  return kc * fc * mc;
}
export function asistanKur(oyuncular, dizilis = '4-4-2', musait = o => !o.sakat && !o.kadroDisi && !(o.ceza > 0) && !o.milliTurnuva, sec = {}) {
  const D = DIZILIS[dizilis], havuz = oyuncular.filter(musait), secilen = new Set(), ilk11 = Array(11).fill(null);
  const yw = clamp01((sec.yardimci ?? 12) / 14);           // yardımcı antrenörün kalitesi: zayıf yardımcı form ve yorgunluğu yarım tartar
  const gc = sec.gunluk ? o => 1 + (gunlukCarpan(o) - 1) * yw : () => 1;
  const sira = D.map((d, i) => [i, havuz.filter(o => uyum(o, d[0]) >= 0.82).length]).sort((a, b) => a[1] - b[1]).map(x => x[0]);
  for (const i of sira) {
    let en = null, es = -1;
    for (const o of havuz) { if (secilen.has(o.id)) continue; const u = uyum(o, D[i][0]); const s = etkinlik(o, D[i][0]) * u * u * gc(o); if (s > es) { es = s; en = o; } }   // asistan doğal mevkiyi kollar
    if (en) { secilen.add(en.id); ilk11[i] = en.id; }
  }
  /* iyileştirme: iki yerin oyuncularını takas et ya da dışarıdakini al; toplam uyum artıyorsa uygula
     (açgözlü seçim bir stoperi sol beke koyup gerçek sol beki dışarıda bırakmasın) */
  const byId = Object.fromEntries(havuz.map(o => [o.id, o]));
  const puan = (o, i) => o ? etkinlik(o, D[i][0]) * uyum(o, D[i][0]) ** 2 * gc(o) : 0;   // asistan oyuncuyu doğal mevkiinde oynatmayı belirgin biçimde yeğler
  for (let tur = 0, degisti = true; degisti && tur < 8; tur++) {
    degisti = false;
    for (let i = 0; i < 11; i++) for (let j = i + 1; j < 11; j++) {
      const a = byId[ilk11[i]], b = byId[ilk11[j]];
      if (puan(b, i) + puan(a, j) > puan(a, i) + puan(b, j) + 0.5) { [ilk11[i], ilk11[j]] = [ilk11[j], ilk11[i]]; degisti = true; }
    }
    for (let i = 0; i < 11; i++) for (const o of havuz) {
      if (secilen.has(o.id)) continue;
      if (puan(o, i) > puan(byId[ilk11[i]], i) + 0.5) { if (ilk11[i]) secilen.delete(ilk11[i]); secilen.add(o.id); ilk11[i] = o.id; degisti = true; }
    }
  }
  const kalan = havuz.filter(o => !secilen.has(o.id));
  const yedek = [];
  const yg = o => o.ca * gc(o);
  const kl = kalan.filter(o => o.mevki === 'KL').sort((a, b) => yg(b) - yg(a))[0]; if (kl) yedek.push(kl.id);
  for (const g of ['D', 'O', 'F', 'D', 'O', 'F', 'O', 'D']) {
    const o = kalan.filter(x => !yedek.includes(x.id) && x.mevki !== 'KL' && MEVKI[x.mevki].grup === g).sort((a, b) => yg(b) - yg(a))[0];
    if (o) yedek.push(o.id);
  }
  for (const o of kalan.filter(x => !yedek.includes(x.id) && x.mevki !== 'KL').sort((a, b) => b.ca - a.ca)) { if (yedek.length >= 9) break; yedek.push(o.id); }
  return { dizilis, ilk11, yedek: yedek.slice(0, 9) };
}

/* görevler: kaptan liderlik, penaltı bitiricilik+soğukkanlılık, korner/serbest vuruş orta+duran top */
export function gorevSec(ilk11Oyuncular) {
  const en = f => ilk11Oyuncular.filter(Boolean).sort((a, b) => f(b) - f(a))[0]?.id ?? null;
  return {
    kaptan: en(o => o.oz.lid * 2 + o.yas * 0.3 + o.ca * 0.02),
    penalti: en(o => o.mevki === 'KL' ? -99 : o.oz.bit + o.oz.sgk + o.oz.dur * 0.5),
    korner: en(o => o.mevki === 'KL' ? -99 : o.oz.ort + o.oz.dur),
    serbest: en(o => o.mevki === 'KL' ? -99 : o.oz.dur * 1.5 + o.oz.uzs + o.oz.tek * 0.5),
  };
}

/* kayıtlı taktiği kadroya göre doğrula: ayrılan/sakat oyuncu varsa asistan boşluğu doldurur */
export function taktikHazirla(D, kid, eski) {
  const O = D.kulupler[kid].oyuncular.map(id => D.oyuncular[id]);
  const dz = DIZILIS[eski?.dizilis] ? eski.dizilis : '4-4-2';
  const var_ = new Set(O.filter(o => !o.sakat && !o.kadroDisi && !(o.ceza > 0) && !o.milliTurnuva).map(o => o.id));
  if (!eski || eski.ilk11?.length !== 11) {
    const t = asistanKur(O, dz);
    return { ...t, ...gorevSec(t.ilk11.map(id => D.oyuncular[id])), zihniyet: 'dengeli', pres: 'orta' };
  }
  const ilk11 = eski.ilk11.map(id => var_.has(id) ? id : null);
  const kullan = new Set(ilk11.filter(Boolean));
  const yedek = (eski.yedek || []).filter(id => var_.has(id) && !kullan.has(id));
  ilk11.forEach((id, i) => {
    if (id) return;
    const yer = DIZILIS[dz][i][0];
    const aday = O.filter(o => var_.has(o.id) && !kullan.has(o.id)).sort((a, b) => etkinlik(b, yer) - etkinlik(a, yer))[0];
    if (aday) { ilk11[i] = aday.id; kullan.add(aday.id); const yi = yedek.indexOf(aday.id); if (yi >= 0) yedek.splice(yi, 1); }
  });
  for (const o of O.filter(o => var_.has(o.id) && !kullan.has(o.id) && !yedek.includes(o.id)).sort((a, b) => b.ca - a.ca)) { if (yedek.length >= 9) break; yedek.push(o.id); }
  const t = { ...eski, dizilis: dz, ilk11, yedek: yedek.slice(0, 9) };
  const g = gorevSec(ilk11.map(id => D.oyuncular[id]));
  for (const k of ['kaptan', 'penalti', 'korner', 'serbest']) if (!ilk11.includes(t[k])) t[k] = g[k];
  t.zihniyet ??= 'dengeli'; t.pres ??= 'orta';
  return t;
}

/* yapay zekâ rakip: dizilişi kadrosuna göre seçer */
export function rakipTaktik(D, kid) {
  const O = D.kulupler[kid].oyuncular.map(id => D.oyuncular[id]);
  let en = null, es = -1;
  for (const dz of DIZILIS_SIRA) {
    const t = asistanKur(O, dz);
    const s = t.ilk11.reduce((a, id, i) => a + (id ? etkinlik(D.oyuncular[id], DIZILIS[dz][i][0]) : 0), 0) * yayginlik(dz);
    if (s > es) { es = s; en = t; }
  }
  return { ...en, ...gorevSec(en.ilk11.map(id => D.oyuncular[id])), zihniyet: 'dengeli', pres: 'orta' };
}
