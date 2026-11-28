// Champion Battle Manager: kulüpten haberler (G109; çekirdek bildirim-ortak.js)
BildirimOrtak.kur({
  urun: 'cbm',
  dil: () => { try { return localStorage.getItem('cbm.dil') === 'en' ? 'en' : 'tr'; } catch (e) { return 'tr'; } },
  mesajlar: {
    tr: [
      ['Başkan aradı', 'Yönetim kurulu toplandı; bu haftaki maç için beklenti yüksek. Taktik tahtası seni bekliyor.'],
      ['Scout raporu geldi', 'Gözlemcin genç bir yeteneği izlemiş. Transfer listesinde yeni bir isim var.'],
      ['Sakatlık haberi', 'Sağlık ekibi idmandan sonra bir oyuncuyu yakın takibe aldı. Kadroyu gözden geçir.'],
      ['Transfer dönemi kızışıyor', 'Rakip kulüp yıldız oyuncun için teklif hazırlıyor. Masada seni bekliyorlar.'],
      ['Maç haftası', 'Basın toplantısı yarın, kadro bugün belli olmalı. Asistanın listeyi hazırladı.'],
      ['Altyapıdan haber', 'U19 takımı sezonun en iyi maçını çıkardı. A takıma çağırmayı düşünür müsün?'],
      ['Puan tablosu değişti', 'Diğer maçlar oynandı, sıralama karıştı. Lig sana bakıyor.']
    ],
    en: [
      ['The chairman called', 'The board has met and expectations are high for this week’s match. The tactics board is waiting.'],
      ['A scouting report', 'Your scout watched a young talent. There is a new name on the transfer list.'],
      ['Injury news', 'The medical team is monitoring a player after training. Review your squad.'],
      ['The window heats up', 'A rival club is preparing a bid for your star player. They are waiting at the table.'],
      ['Match week', 'Press conference tomorrow; the team must be named today. Your assistant has the list ready.'],
      ['News from the academy', 'The U19s played their best match of the season. Will you call someone up?'],
      ['The table has changed', 'The other matches are played and the standings shifted. The league is watching you.']
    ]
  },
  ayarSatiri: 'button.btn[data-act="paylas"] + button.btn[data-act="bizeYaz"]',
  kayitAnahtari: /^cbm(?!\.tam$)/,
  renk: { zemin: '#10171f', yazi: '#eef2f6', vurgu: '#e8b84a' }
});
