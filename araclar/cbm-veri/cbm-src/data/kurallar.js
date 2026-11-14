/* Lig kuralları: yabancı / yerli yetişmiş oyuncu sınırları (2026-27).
   Türkiye: TFF'nin 21 Mayıs 2026'da açıkladığı "10+4" kuralı (A takım listesinde en fazla 14 yabancı; 14'ün hepsi kullanılırsa
   en az 4'ü 01.01.2003 ve sonrası doğumlu). Diğer ligler bilinen kuralların sadeleştirilmiş hâli: oyunda "yerli yetişmiş"
   kulübün altyapısından gelenler ve ülkenin kendi oyuncularıyla yaklaşık olarak sayılır. */
export const AB = new Set(['ES', 'IT', 'DE', 'FR', 'PT', 'NL', 'BE', 'AT', 'HR', 'PL', 'CZ', 'DK', 'SE', 'IE', 'GR', 'HU', 'RO', 'BG', 'SK', 'SI', 'FI', 'EE', 'LV', 'LT', 'LU', 'MT', 'CY', 'NO', 'IS', 'LI', 'CH']);
export const KURAL = {
  tr: { tip: 'yabanci', yerli: ['TR'], max: 14, serbest: 10, genc: '2003-01-01', ad: 'Yabancı sınırı', aciklama: 'A takım listesinde en fazla 14 yabancı. 14\'ün hepsi kullanılırsa en az 4\'ü 2003 ve sonrası doğumlu olmalı.' },
  es: { tip: 'abDisi', max: 3, ad: 'AB dışı sınırı', aciklama: 'Kadroda en fazla 3 Avrupa Birliği dışından oyuncu.' },
  fr: { tip: 'abDisi', max: 4, ad: 'AB dışı sınırı', aciklama: 'Kadroda en fazla 4 Avrupa Birliği dışından oyuncu.' },
  en: { tip: 'yerliYetismis', yerli: ['EN', 'WL', 'SC', 'NI'], max: 17, muafYas: 21, ad: 'Yerli yetişmiş kuralı', aciklama: '25 kişilik listede en fazla 17 yerli yetişmemiş oyuncu (en az 8 yerli yetişmiş); 21 yaş altı muaf.' },
  it: { tip: 'yerliYetismis', yerli: ['IT'], max: 17, muafYas: 22, ad: 'Yerli yetişmiş kuralı', aciklama: '25 kişilik listede en fazla 17 yerli yetişmemiş oyuncu; 22 yaş altı muaf.' },
  de: { tip: 'yerliSayi', yerli: ['DE'], min: 12, ad: 'Alman oyuncu kuralı', aciklama: 'Profesyonel kadroda en az 12 Alman oyuncu bulunmalı.' },
};
