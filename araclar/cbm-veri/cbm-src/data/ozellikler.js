/* Oyuncu özellikleri (1–20) ve mevkiler. Ağırlıklar, bir mevkide hangi özelliklerin önemli olduğunu söyler. */

export const OZELLIK = {
  teknik: [
    ['bit', 'Bitiricilik'], ['uzs', 'Uzaktan şut'], ['pas', 'Pas'], ['ort', 'Orta'], ['srm', 'Top sürme'], ['ilk', 'İlk dokunuş'],
    ['tek', 'Teknik'], ['kaf', 'Kafa vuruşu'], ['mrk', 'Markaj'], ['kap', 'Top kapma'], ['dur', 'Duran top'],
  ],
  zihinsel: [
    ['krr', 'Karar alma'], ['ons', 'Önsezi'], ['poz', 'Pozisyon alma'], ['tsz', 'Topsuz oyun'], ['viz', 'Vizyon'], ['sgk', 'Soğukkanlılık'],
    ['cls', 'Çalışkanlık'], ['tko', 'Takım oyunu'], ['lid', 'Liderlik'], ['agr', 'Agresiflik'],
  ],
  fiziksel: [
    ['hiz', 'Hız'], ['hzl', 'Hızlanma'], ['day', 'Dayanıklılık'], ['guc', 'Güç'], ['cev', 'Çeviklik'], ['den', 'Denge'], ['zip', 'Zıplama'],
  ],
  kaleci: [
    ['ref', 'Refleks'], ['elk', 'Elle kontrol'], ['bir', 'Birebir'], ['hav', 'Hava hâkimiyeti'], ['cik', 'Kaleden çıkış'], ['ayk', 'Ayakla oyun'],
  ],
};
export const TUM = Object.values(OZELLIK).flat().map(x => x[0]);
export const OZ_AD = Object.fromEntries(Object.values(OZELLIK).flat());
export const KALECI_OZ = OZELLIK.kaleci.map(x => x[0]);

/* Mevkiler: kod, ad, saha üzerindeki yeri (x: 0 sol – 1 sağ, y: 0 kendi kalesi – 1 rakip kale). */
export const MEVKI = {
  KL:  { ad: 'Kaleci', kisa: 'KL', x: .5, y: .03, grup: 'K' },
  SĞB: { ad: 'Sağ bek', kisa: 'SĞB', x: .88, y: .25, grup: 'D' },
  STP: { ad: 'Stoper', kisa: 'STP', x: .5, y: .18, grup: 'D' },
  SLB: { ad: 'Sol bek', kisa: 'SLB', x: .12, y: .25, grup: 'D' },
  DOS: { ad: 'Defansif orta saha', kisa: 'DOS', x: .5, y: .38, grup: 'O' },
  MOS: { ad: 'Merkez orta saha', kisa: 'MOS', x: .5, y: .5, grup: 'O' },
  SĞO: { ad: 'Sağ orta saha', kisa: 'SĞO', x: .88, y: .52, grup: 'O' },
  SLO: { ad: 'Sol orta saha', kisa: 'SLO', x: .12, y: .52, grup: 'O' },
  OOS: { ad: 'Ofansif orta saha', kisa: 'OOS', x: .5, y: .68, grup: 'O' },
  SĞK: { ad: 'Sağ kanat', kisa: 'SĞK', x: .85, y: .74, grup: 'F' },
  SLK: { ad: 'Sol kanat', kisa: 'SLK', x: .15, y: .74, grup: 'F' },
  SF:  { ad: 'Santrfor', kisa: 'SF', x: .5, y: .86, grup: 'F' },
};
export const MEVKI_SIRA = Object.keys(MEVKI);

/* Mevki ağırlıkları (önemli özellikler 3, destek 2, az önemli 1; yazılmayanlar 0.4). */
const A = (o) => o;
export const AGIRLIK = {
  KL:  A({ ref: 3, elk: 3, bir: 3, hav: 2.5, cik: 2, ayk: 1.5, krr: 2, poz: 2.5, sgk: 2, ons: 1.5, cev: 2, zip: 1.5, lid: 1, tko: 1 }),
  STP: A({ mrk: 3, kap: 3, kaf: 3, poz: 3, guc: 2.5, zip: 2.5, krr: 2, ons: 2, sgk: 1.5, hiz: 1.5, cls: 1.5, tko: 1.5, lid: 1, pas: 1, agr: 1.5, den: 1 }),
  SĞB: A({ kap: 2.5, mrk: 2.5, poz: 2, hiz: 3, hzl: 2.5, day: 3, ort: 2.5, cls: 2.5, tko: 2, pas: 1.5, srm: 1.5, krr: 1.5, ons: 1.5, cev: 1 }),
  SLB: null,
  DOS: A({ kap: 3, mrk: 2.5, poz: 3, pas: 2.5, krr: 2.5, ons: 2.5, cls: 2.5, tko: 2.5, day: 2.5, guc: 2, sgk: 1.5, ilk: 1.5, agr: 1.5, den: 1.5, viz: 1 }),
  MOS: A({ pas: 3, krr: 3, viz: 2.5, ilk: 2.5, tek: 2, tko: 2.5, cls: 2.5, day: 2.5, ons: 2, poz: 1.5, tsz: 1.5, kap: 1.5, uzs: 1.5, sgk: 1.5, srm: 1 }),
  SĞO: A({ ort: 3, srm: 2.5, hiz: 2.5, hzl: 2.5, day: 2.5, pas: 2, tek: 2, cls: 2.5, tko: 2, ilk: 2, tsz: 1.5, krr: 1.5, viz: 1.5, cev: 1.5 }),
  SLO: null,
  OOS: A({ pas: 2.5, viz: 3, tek: 3, ilk: 3, srm: 2.5, krr: 2.5, tsz: 2.5, uzs: 2, bit: 2, sgk: 2, ons: 1.5, cev: 2, hzl: 1.5, dur: 1 }),
  SĞK: A({ srm: 3, hiz: 3, hzl: 3, tek: 2.5, ilk: 2.5, ort: 2.5, bit: 2, tsz: 2.5, cev: 2.5, krr: 1.5, uzs: 1.5, pas: 1.5, sgk: 1.5, den: 1.5 }),
  SLK: null,
  SF:  A({ bit: 3, tsz: 3, sgk: 2.5, ilk: 2.5, kaf: 2.5, hzl: 2.5, hiz: 2, guc: 2, tek: 2, ons: 2, krr: 1.5, srm: 1.5, zip: 1.5, den: 1.5, cev: 1.5, uzs: 1 }),
};
AGIRLIK.SLB = AGIRLIK.SĞB; AGIRLIK.SLO = AGIRLIK.SĞO; AGIRLIK.SLK = AGIRLIK.SĞK;

/* Bir kadroda olması gereken mevki dağılımı (25 kişi). */
export const KADRO_DUZENI = [
  ['KL', 3], ['SĞB', 2], ['STP', 4], ['SLB', 2], ['DOS', 2], ['MOS', 3], ['SĞO', 1], ['SLO', 1], ['OOS', 2], ['SĞK', 1], ['SLK', 1], ['SF', 3],
];

/* İkinci mevkiler (oyuncunun oynayabildiği yakın yerler). */
export const YAKIN = {
  KL: [], SĞB: ['SĞO', 'STP'], SLB: ['SLO', 'STP'], STP: ['DOS', 'SĞB', 'SLB'], DOS: ['MOS', 'STP'], MOS: ['DOS', 'OOS'],
  SĞO: ['SĞK', 'SĞB'], SLO: ['SLK', 'SLB'], OOS: ['MOS', 'SF', 'SĞK', 'SLK'], SĞK: ['SĞO', 'SLK', 'SF'], SLK: ['SLO', 'SĞK', 'SF'], SF: ['OOS', 'SĞK', 'SLK'],
};

/* Gizli kişilik özellikleri (1–20) — oyuncu kartında yorum olarak görünür. */
export const KISILIK = [['pro', 'Profesyonellik'], ['hir', 'Hırs'], ['sad', 'Sadakat'], ['bsk', 'Baskıya dayanıklılık'], ['ozg', 'Özgüven']];
