# Kaptan Mecit 3 (Godot 4.3)

Kaptan Mecit 2'nin üstüne kurulur. Bir Mr. Anduv! yapımıdır.

Yeni: **gerçek hareketler.** Yürüme, koşu, depar ve vuruş, Carnegie Mellon Üniversitesi Hareket Yakalama Veritabanı'ndan
(mocap.cs.cmu.edu; B. Hahne'nin BVH dönüşümü — "araştırma ve ticari kullanım için ücretsiz") bizim iskelete aktarıldı:
`araclar/mocap/donustur.py` → `veri/hareket.json`. Hıza göre iki komşu döngü harmanlanır, adım evresi oyuncunun katettiği
yola bağlıdır (ayak kaymaz). Kayma, düşme, kaleci duruşu/uçuşu ve dururken nefes el yapımı kalır.

Yeni kamera: **Yakın** (topu yandan, alçaktan ve yakından izler).
Hareket denemesi: `godot --path km3 dene/hareket_dene.tscn -- cikti.png` (yürü / koş / depar / vuruş yan yana).

Kurallar (Kaptan Mecit motorundan taşındı): faul (kayarak müdahale arkadan / topa değmeden, omuz-çekme), avantaj, sarı / ikinci sarı / kırmızı
(net gol fırsatı dahil), kırmızıda oyuncu sahadan çıkar (kaleci atılırsa bir saha oyuncusu eldiven giyer), serbest vuruş (kaleye yakınsa doğrudan şut),
penaltı (ceza sahasında faul), ofsayt (pas anında sondan ikinci rakip çizgisi; yapay zekâ ofsayttaki arkadaşına pas atmaktan kaçınır).

Taktik: Champion Battle Manager'ın 34 dizilişi ve teknik direktör asistanı (`motor/taktik.gd`, veri: `veri/taktik.json`,
üretici: `araclar/km2-veri/taktik-uret.js`). Menüde Diziliş: Otomatik ya da 34'ten biri; asistan havuzdan en uygun 11'i ve 9 yedeği kurar.
