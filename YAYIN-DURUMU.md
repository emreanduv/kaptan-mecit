# Kaptan Mecit — Yayın durumu (18 Ekim 2026)

## 1.1.0 (hazırlanıyor)
- Beş kamera: Klasik, Dinamik, Tele, Stadyum (3D, `www/three.min.js` — Three.js r128, MIT), TV (20 Eki: kenardan dümdüz yayın açısı, gölgeli çizim oyuncular, kontrol edilen oyuncunun adı; 2D tuval, Three.js gerekmez)
- 20 Eki: TV kamerası eklendi; Pardus paketi bu değişikliği içermiyor
- 20 Eki oynanış denetimi (hızlandırılmış simülasyon): topla çizgi dışına/kaleye sürünce oyun durmuyordu → taç/aut/korner/gol; kaleci çerçeve dışı şutları da tutuyordu, şutlar hiç üstten gitmiyordu → maçlarda neredeyse hiç korner/aut yoktu, düzeltildi; pas ve şutta baskı altında sapma; duran topta itilen rakipler saha içinde
- 20 Eki kamera denetimi: Dinamik/Tele'de kameranın arkasına taşan zemin parçaları hiç çizilmiyordu (köşelerde kara boşluk) → yakın düzlem kırpması; Klasik yatay ekranda (bilgisayar/Pardus/Champion) geniş görünüm; TV'de telefonda yakın taç çizgisi tuşların üstünde
- 20 Eki gece: iOS 1.1.0 (5) TestFlight — "Mr. Anduv! Ekibi" + "Mr. Anduv! Testçiler" (Testing; beta incelemesi anında geçti)
- 20 Eki gece: Android 1.1.0 (5) dahili testte yayında (`imza-anahtari/kaptan-mecit-1.1.0-5-imzali.aab`, imza SHA-256 DC:58:9E:56…)
- 20 Eki taktik motoru (Emre'nin ideal 11'inden rol şablonları, oyunda isimler kurgusal): 4-2-3-1 — 1 oyunu kuran/süpürücü kaleci, 2 ve 3 bindiren bekler, 4 sert stoper, 5 oyun kuran stoper, 6 baskıcı dinamo, 8 box-to-box, 7 içe/dışa sağ açık, 10 hatlar arası oyun kurucu, 9 içeri kayan ikinci forvet, 11 hedef santrfor; blok topa ve topa sahipliğe göre yükselir (topa sahipken stoperler orta sahaya), kontra/organize atak, orta + kafa, kalecinin kısa oyun kurması; devre arasında kaleler değişir (Dinamik kamera döner); kaleci kurtarışı güçlendi; Zor bir tık yumuşadı
- 20 Eki gece: taktik motorlu 1.1.0 (6) — iOS TestFlight (iki grup, Testing) + Android dahili test yayında (`imza-anahtari/kaptan-mecit-1.1.0-6-imzali.aab`)
- 20 Eki stadyum mimarisi (kulüp teması yok, yalnız mimari his): sahaya yakın dik iki katlı tribünler + camlı loca kuşağı, kapalı köşeler, çelik makaslı çatı + saçak projektörleri, kuzey kale arkasında tek parça dev tribün; dört çizim motorunda (Klasik piksel, Dinamik/Tele, TV şeritleri, Stadyum 3D + pilonlar); atletizm pisti kaldırıldı
- 20 Eki gece: stadyumlu 1.1.0 (7) — iOS TestFlight (iki grup, Testing) + Android dahili test yayında (`imza-anahtari/kaptan-mecit-1.1.0-7-imzali.aab`)
- Plan aynı: 1.0.0 onayları gelince 1.1.0 (7) mağaza incelemesine (App Store: yeni sürüm 1.1.0 + build 5; Play: kapalı teste terfi / üretim)
- Champion Battle Manager: `champion-battle` dalındaki motor güncel, yeni TestFlight derlemesi alınmadı
- Topsuz oyun yapay zekası (koşular, pas açıları, bindirme, adam adama savunma; zorluğa bağlı)
- Golde seyirciler tek tek coşar; panolarda yalnız kamu yararına çalışan kuruluşlar (TÜBİTAK, Pardus, Kızılay, Yeşilay her maçta)
- Yenilikler metni: `store/magaza-metinleri.md` → "Bu sürümde yenilikler (1.1.0)"
- Pardus: `pardus/kaptan-mecit_1.1.0-1_all.deb` + kaynak paketi (1.0.0 dosyaları git geçmişinde)
- Plan: 1.0.0 incelemeleri sürerken 1.1.0 derlemeleri TestFlight / Play dahili teste; 1.0.0 onaylanınca 1.1.0 incelemeye
- 18 Eki 2026 gece: iOS 1.1.0 (4) TestFlight — "Mr. Anduv! Ekibi" + "Mr. Anduv! Testçiler" (beta incelemesinde)
- 18 Eki 2026 gece: Android 1.1.0 (4) dahili testte yayında (`imza-anahtari/kaptan-mecit-1.1.0-4-imzali.aab`)
- Champion Battle Manager 3.1.0 (14): Kaptan Mecit 1.1.0 maç motoruyla TestFlight'ta, "Mr. Anduv! Testçiler" beta incelemesinde. Derleme: bu depodaki `champion-battle` dalı + `.github/workflows/champion-ios.yml`
- iOS akışları imzasız arşivler, dağıtım imzasını dışa aktarmada alır (Apple geliştirme sertifikası sınırına takılmamak için)


## Hazır olanlar
- Oyun 1.0.0: Hızlı Maç, 6 lig × 20 kulüp lig kariyeri, Kolay/Orta/Zor, 2–8 dk maç
- Paket kimliği: `com.anduv.kaptanmecit` (iOS ve Android) · SKU `kaptan-mecit`
- iOS: dikey ekran, `ITSAppUsesNonExemptEncryption = NO`, ikonlar ve açılış ekranı
- Android: dikey ekran, sürüm kodu/adı derleme akışından, ikonlar ve açılış ekranı
- Ekran görüntüleri: `store/screenshots/` (Android 1080×1920), `store/screenshots-ios/` (iPhone 6.9" 1320×2868, iPad 13" 2064×2752)
- Mağaza metinleri `store/magaza-metinleri.md` · Form cevapları `store/form-cevaplari.md` · Gizlilik politikası `store/gizlilik-politikasi.html` → yayında: https://claude.ai/artifact/9dcY3CsGCnidaUkQRDUhHB (Paylaş menüsünden herkese açık yapılmalı)
- Pardus: `pardus/kaptan-mecit_1.1.0-1_all.deb` + kaynak paketi + `pardus/BASVURU.md`

## Yükleme (imza) anahtarı — KAYBETME
- Bilgisayar: `imza-anahtari/kaptanmecit-upload.jks` (git dışında), alias `kaptanmecit`, şifre `imza-anahtari/SIFRE-OKU.txt`
- SHA-256: DC:58:9E:56:6F:47:D3:90:5F:8B:D3:E5:F2:42:34:93:45:0B:7B:1E:87:34:3F:5B:9A:D8:AD:54:0C:46:AB:C3
- Google Drive'a yedekle

## Mağaza durumu
**App Store Connect** — uygulama kimliği `6824240380`
- Build 2 (1.0.0) yüklendi, sürüme bağlandı; metinler, ekran görüntüleri, yaş derecelendirmesi, fiyat, kategori tamam
- App Privacy: "Data Not Collected" yayımlandı
- TestFlight: "Mr. Anduv! Ekibi" (dahili) + "Mr. Anduv! Testçiler" (harici) — build 2 beta incelemesinde
- 18 Eki 2026: incelemeye gönderildi (20 Eki: hâlâ Waiting for Review)

**Google Play Console** — uygulama kimliği `4974040305096795281`
- Dahili test 1.0.0 (2) yayında ("Kaptan Mecit Testçiler")
- Uygulama içeriği beyanlarının hepsi, mağaza girişi (metin, ikon, özellik grafiği, 5 ekran görüntüsü) tamam
- Kapalı test (Alpha): Türkiye, "Kaptan Mecit Testçiler" listesi, 1.0.0 (2) sürümü hazır
- 18 Eki 2026: kapalı test incelemeye gönderildi → onaylandı, kapalı test (Alpha) yayında
- Üretim için: en az 12 testçi, 14 gün kapalı test → "Üretime başvur"

**Pardus** — beklemede (`pardus/BASVURU.md`)

## Güncelleme çıkarma
1. `www/index.html` değişir → `kaptanmecit.html` (Champion) ve `pardus/` kopyası da güncellenir → GitHub'a gönder.
2. iOS: Actions → "iOS (App Store Connect / TestFlight)" → sürüm adını artır.
3. Android: Actions → "Android (Google Play paketi)" → `builds` dalındaki imzasız `.aab`'yi imzala:
   `jarsigner -sigalg SHA256withRSA -digestalg SHA-256 -keystore imza-anahtari/kaptanmecit-upload.jks paket.aab kaptanmecit`
