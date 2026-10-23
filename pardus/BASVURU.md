# Kaptan Mecit — Pardus resmi deposu başvurusu

## Nereye gönderilecek
1. **Hata/Talep Bildirimi:** https://talep.pardus.org.tr → yeni talep → "Yeni paket / uygulama isteği" türünde (varsa) ya da genel talep.
2. Aynı metni **Pardus Forumu**'nda (https://forum.pardus.org.tr) "Uygulama önerileri" benzeri bir bölümde paylaş; topluluğun desteği talebi hızlandırır.
3. Ek olarak: Pardus .deb paketi, kaynak paketi (`.dsc`, `.orig.tar.gz`, `.debian.tar.xz`) ve ekran görüntüsü bu klasörde. Kaynak kod için herkese açık GitHub deposunun linki eklenmeli.

## Gönderilecek metin

**Konu:** Pardus depolarına yeni oyun önerisi: Kaptan Mecit (özgür yazılım, GPL-3.0)

Merhaba Pardus ekibi,

Ben Emre Anduv. "Mr. Anduv!" adıyla küçük, çevrimdışı oyunlar geliştiriyorum. Son oyunum **Kaptan Mecit**'i Pardus depolarına ve Pardus Yazılım Merkezi'ne eklenmesi için öneriyorum. Pardus projesine katkı vermek benim için önemli; oyunun ilk masaüstü sürümünü özellikle Pardus için hazırladım.

**Oyun hakkında**
- Nostaljik bir futbol oyunu; beş kamera: tepeden piksel görünüm (Klasik), Dinamik, Tele, Stadyum ve TV; 5 oyuncu değişikliği, asistan, kondisyon ve sakatlık. Bilgisayara karşı 11'e 11 maç ve 6 ligde 38 haftalık lig kariyeri.
- Tamamen çevrimdışı çalışır; reklam, hesap, veri toplama veya ağ bağlantısı yoktur.
- Arayüz Türkçe. Klavye ile oynanır (ok tuşları, X, Z), dokunmatik ekranda da çalışır.
- Tüm kulüp ve oyuncu adları kurmacadır. Stat panolarında yalnızca Mr. Anduv! markası, oyunları, uygulamaları ve sosyal medya hesapları yer alır; başka marka ya da kurum adı yoktur.

**Paket bilgileri**
- Paket adı: `kaptan-mecit` · Sürüm: 1.2.0-1 · Mimari: all · Bölüm: games
- Bağımlılıklar: python3, python3-gi, gir1.2-gtk-3.0, gir1.2-webkit2-4.1 | gir1.2-webkit2-4.0
- Kurulan dosyalar: `/usr/games/kaptan-mecit` (Python + WebKitGTK başlatıcı), `/usr/share/kaptan-mecit/www/index.html` (oyun) ve `ses-kurtarici.js`, `.desktop` dosyası, AppStream metainfo (`com.anduv.kaptanmecit`), hicolor ikonları, man sayfası
- Oyuncu verisi: `~/.local/share/kaptan-mecit`
- Lisans: oyun kodu GPL-3.0-or-later; gömülü "Press Start 2P" yazı tipi SIL OFL 1.1
- Kaynak paketi debhelper-compat 13 ile hazırlandı; `appstreamcli validate` ve `desktop-file-validate` hatasız geçiyor.
- Kaynak kod: https://github.com/emreanduv/kaptan-mecit (herkese açık)

Paketi Debian 12 tabanlı bir sistemde derleyip WebKitGTK 4.1 ile test ettim. İsterseniz paketlemeyi sizin depo kurallarınıza göre (dağıtım adı, bakımcı alanı, imza vb.) düzenlerim. Bakımını ve güncellemelerini ben üstlenirim.

Değerlendirmeniz için teşekkür ederim.

Emre Anduv (Mr. Anduv!)
emreanduvart@gmail.com
