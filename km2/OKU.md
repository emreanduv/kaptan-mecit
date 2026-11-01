# Kaptan Mecit 2 (Godot 4.3)

Kaptan Mecit'in gerçekçi 3B devamı. Bir Mr. Anduv! yapımıdır.

- `motor/mac.gd` — maç motoru: Kaptan Mecit'in (www/index.html) motorunun GDScript'e satır satır taşınmış hali (takım planı, adam paylaşımı, topsuz koşular, topçu kararları, kaleci, top fiziği, duran toplar, devreler, uzatma). Sıradaki: faul/kart/penaltı/VAR/ofsayt/değişiklik/tekrar.
- `sahne/futbolcu.gd` — iskeletli, yordamsal futbolcu (dış model yok) ve hareketleri.
- `sahne/stadyum.gd` — biçilmiş çim, çizgiler, ağlı kaleler, iki katlı kase tribün, ~27 bin seyirci (tek çizim), çatı ışıkları, LED panolar, skor ekranları.
- `ses/ses.gd` — yordamsal ses (tribün, düdük, vuruş, gol).
- `ana.gd` — menü, 60 Hz sabit adım döngüsü, dört yayın kamerası (Yayın, Tele, Dinamik, Saha kenarı), tabela.
- `veri/takimlar.json` — Champion Battle Manager dünyasından 6 lig / 114 kulüp / ilk 11'ler ve diziliş noktaları (`araclar/km2-veri` ile www/index.html'den üretilir).

Çalıştırma: Godot 4.3 ile `km2/` klasörünü aç. Web derlemesi: `godot --headless --path km2 --export-release Web <çıktı>/index.html` (tek iş parçacıklı, GitHub Pages'te çalışır).
Deneme: `godot --headless --path km2 -- --mac --dene` (maçı sonuna kadar oynatır), ekran görüntüsü: `-- --ekran=a.png --ileri=20 --kamera=2`.
