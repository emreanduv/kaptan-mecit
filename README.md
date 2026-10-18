# Kaptan Mecit · Bir Mr. Anduv! yapımıdır.

Nostaljik, üstten görünümlü, internetsiz futbol oyunu. iOS, Android (Capacitor) ve Pardus (.deb).

## Klasörler
- `www/index.html` — oyunun tamamı (tek dosya). Tarayıcıda denemek için `start.command`'a çift tıkla.
- `www/three.min.js` — Stadyum kamerası için 3D motor (Three.js r128, MIT). Yoksa oyun Stadyum'u Tele'ye düşürür.
- `android/`, `ios/` — Capacitor yerel projeleri (`npx cap sync` ile `www` kopyalanır)
- `assets/` — ikon, açılış ekranı, Play öne çıkan görsel (`npm run ikonlar` ile tüm boyutlar üretilir)
- `store/` — mağaza metinleri, form cevapları, gizlilik politikası, ekran görüntüleri
- `pardus/` — Debian/Pardus kaynak paketi, derlenmiş `.deb` ve başvuru metni (`BASVURU.md`)
- `imza-anahtari/` — Android yükleme anahtarı (git dışında, KAYBETME)
- `.github/workflows/` — iOS (TestFlight) ve Android (.aab) derleme akışları

## Kontroller
Telefonda sol taraf sürükle = koş · PAS/ŞUT (top rakipteyken SEÇ/KAY).
Klavye: ok tuşları/WASD · X pas · Z/Boşluk şut · P duraklat · (Pardus'ta F11 tam ekran)

## Kameralar (1.1.0)
Klasik (tepeden piksel) · Dinamik (kale arkası) · Tele (yandan yayın, sağdaki kaleye hücum) · Stadyum (3D yayın).
Ayarlar'dan, maç başı ekranından ya da maç içinde duraklat menüsünden seçilir; varsayılan Klasik.

## Champion Battle Manager
Aynı dosya `ChampionChess-main/fm2010/www/kaptanmecit.html` olarak "Kaptan Mecit modu" maç motorudur (`?mac=1`).
Oyunda değişiklik yapınca bu dosyayı da güncelle.
