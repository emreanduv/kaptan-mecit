// Kaptan Mecit: soyunma odasından haberler (G109; çekirdek bildirim-ortak.js)
BildirimOrtak.kur({
  urun: 'kaptanmecit',
  dil: () => window.KM_DIL === 'en' ? 'en' : 'tr',
  mesajlar: {
    tr: [
      ['Hoca kadroyu açıkladı', 'Hafta sonu maçının ilk on biri belli oldu. Kaptan bandı yine sende.'],
      ['Antrenman sahası hazır', 'Çim biçildi, toplar şişirildi. Takım ısınmaya çıktı, kaptanı bekliyor.'],
      ['Derbi haftası', 'Şehirde bu hafta başka konu yok. Tribünler şimdiden dolmaya başladı.'],
      ['Maç günü sabahı', 'Formalar dolaba asıldı. Taraftar statta, düdük çalmak üzere.'],
      ['Fikstür güncellendi', 'Ligin bu haftası zorlu. Puan tablosunda her maç önemli.'],
      ['Gençlerden haber', 'Altyapıdan bir oyuncu antrenmanda göz doldurdu. Hoca ona şans vermeyi düşünüyor.'],
      ['Kupa kurası çekildi', 'Kupada rakibin belli oldu. Deplasmanda zorlu bir gece seni bekliyor.']
    ],
    en: [
      ['The coach named the team', 'The starting eleven for the weekend is set. You wear the captain’s armband again.'],
      ['The training pitch is ready', 'Grass cut, balls pumped. The team is warming up and waiting for its captain.'],
      ['Derby week', 'The whole city talks of nothing else. The stands are already filling up.'],
      ['Matchday morning', 'Kits hang in the lockers. The fans are in, the whistle is about to blow.'],
      ['Fixtures updated', 'A tough round in the league. Every match counts in the table.'],
      ['News from the academy', 'A youngster impressed in training. The coach is thinking of giving him a chance.'],
      ['The cup draw is out', 'Your cup opponent is set. A tough night away from home awaits.']
    ]
  },
  yazi: { tr: { satir: '🔔 BİLDİRİMLER', ac: 'AÇIK', kap: 'KAPALI' }, en: { satir: '🔔 NOTIFICATIONS', ac: 'ON', kap: 'OFF' } },
  ayarSatiri: '[data-act="howtoS"]',
  kayitAnahtari: /^km\.|^retrolig\./,
  renk: { zemin: '#0f1a13', yazi: '#f3ead6', vurgu: '#ffcf4a' }
});
