# Kaptan Mecit — Yayın durumu (6 Kasım 2026)

## 1.5.0 — Klasik + Modern (5–6 Kas)
- Uygulama açılınca önce dil (Türkçe / English), sonra oyun: **Klasik** (önceki Kaptan Mecit, `www/klasik/`) ya da **Modern** (Kaptan Mecit 3'ün en güncel web derlemesi, `www/modern/`). Seçilen dil hatırlanır; oyunlardan "Oyun seçimi" ile açılışa dönülür.
- `www/modern/` depoya girmez: `ios.yml` / `android.yml` derlerken `araclar/modern-al.sh` ile emreanduv.github.io'daki `kaptan-mecit-3/` alınır. Yani KM3 web'e her gönderimde bir sonraki mağaza derlemesi otomatik güncel Modern'i taşır.
- Klasik İngilizcesi: `www/klasik/en.js` (çalışma anında çeviri: DOM, tuval, paylaşım; kulüp adları renk/şehir çevirisiyle). Modern İngilizcesi: `km3/arayuz/dil.gd`.
- Modern bu cihazda açılamazsa (WebGL 2 yok ya da kayboldu) seçim ekranına "Modern bu cihazda açılamadı" uyarısıyla döner. iOS simülatöründe (Intel ve Apple Silicon) Godot web WebGL bağlamını kaybediyor — Safari'de de aynı; gerçek iPhone'da denenmeli.
- 6 Kas gece: **1.5.0 (16)** Android imzalı (`imza-anahtari/kaptan-mecit-1.5.0-16-imzali.aab`) → Play dahili test yayında. **iOS 1.5.0 (15)** TestFlight'a yüklendi, dış gruba (Mr. Anduv! Testçiler) eklendi, beta incelemesi bekliyor.
- 6 Kas gece: Emre iPhone'da Modern'i açtı (çalışıyor) ama yazılar okunmuyordu ve zorlanıyordu → **1.5.1**: Modern yatay kilitli (`@capacitor/screen-orientation`), KM3 0.7.1 telefonda büyük arayüz + safe-area + hafif çizim. Android 1.5.1 (17) Play dahili test yayında; iOS 1.5.1 (16) TestFlight dış grup, beta incelemesi bekliyor.
- 6 Kas gece: **1.5.2** — Modern'de gol tekrarı (KM3 0.7.2, `km3/arayuz/tekrar.gd`); Emre'nin Facebook hesabı yok → `FACEBOOK / MR. ANDUV!` panosu her yerden kaldırıldı (Klasik, KM2, KM3, Pardus, champion-4, champion-battle, Kaptan Mecit VR web, KM2 web). Quest APK'larında bir sonraki derlemede gider. Android 1.5.2 (18) Play dahili test yayında; iOS 1.5.2 (17) TestFlight beta incelemesi bekliyor.
- 6 Kas gece: **1.5.3** — Modern lig ekranında telefonda takılma (düğmeler ekran dışında, kaydırma yok) düzeltildi (KM3 0.7.3). Android 1.5.3 (19) Play dahili test; iOS 1.5.3 (18) TestFlight beta incelemesinde.
- 7 Kas: **1.5.4** — hızlı maç bitince oyun donup kalıyordu (menü gelmiyordu) → menüye dönüş + uzatmaya kesin sınır (KM3 0.7.5). Android 1.5.4 (21) Play dahili test; iOS 1.5.4 (20) TestFlight beta incelemesinde.
- 7 Kas: **Meta KM3**: 0.7.4 başvurusu iptal edildi; aynı hata VR'da da vardı (VRC.Quest.Functional.1'in muhtemel sebebi). 0.7.5 (kod 8) yüklendi, yaş grubu 13+ Emre'nin onayıyla onaylandı, v1 yeniden değerlendirmeye gönderildi (Emre tam yetki verdi).
- 7 Kas: **1.5.5** — lig ekranında kulüp seçimi: ‹ › düğmeleri + listeden dokunarak seçim (KM3 0.7.6; Quest'e bir sonraki sürümde). Android (22) Play dahili test; iOS (21) TestFlight beta incelemesinde.
- 7 Kas (günlük görev): **KM3 0.7.7** — lig ekranında Fikstür görünümü (ekran + VR), web güncellendi. Meta v1 (0.7.5) hâlâ "Gönderildi". Apple: Kurt Yolu 1.1.0 hâlâ WAITING_FOR_REVIEW.
- 11 Kas: **1.6.2 / KM3 0.9.3** — Modern'de de klasik kumanda (molada Kontrol satırı): iki yanda panel, solda yön haçı + MENÜ, sağda A şut / B pas. Web derlemesi bu oturumda yerelde Godot 4.3 ile alınıp emreanduv.github.io/kaptan-mecit-3'e gönderildi.
- 10 Kas: **1.6.1** — Klasik'te **Klasik kumanda** (Ayarlar → KONTROL): maç ekranı üstte, yön haçı (8 yön) + A şut / B pas (basılı tut = güç) + MENÜ altta (Tamga Yolu düzeni, Legend Heads'in `kumanda.js`'inden kopya: `www/klasik/kumanda.js`). Bluetooth oyun kolu (sol çubuk analog, ✕ pas, ○ şut, Start mola) ve klavyeyle menü gezintisi her modda. Modern (KM3/Godot) ve CBM'ye karşılığı sonra.
- 9 Kas: **1.6.0 / KM3 0.9.0** — Champion'dan: maç raporu (istatistik, oyuncu notları, maçın yıldızı, asistler), takım konuşması (maç önü + devre arası), oyuncu kariyeri (Klasik: rapordaki oyuncuya dokun; Modern: yıldızın kariyeri raporda), kupalar (Şampiyonlar Ligi, Kondor, Kuzey Yıldızı, İpek Yolu, Savana, Kıtalar Arası; Klasik ana menü, Modern lig ekranı + VR); Modern'de Puan ver/Arkadaşına öner/Bize yaz; Modern kadro havuzu 28 lig (0.8.1'de yeni liglerde yedek yoktu); arka plandan dönünce ses. Android (27) Play dahili test; iOS (26) TestFlight. Quest: Meta incelemesi bitince (kod 9).
- 9 Kas (gece kontrolü): yayın öncesi kontrol (`araclar/yayin-kontrol.sh`, iOS/Android iş akışlarının başında) + `store/SON-SURUM` (1.5.9) eklendi; Klasik'te arka plandan dönünce ses geri gelir (sonraki sürümde). Meta KM3 v1 (0.7.5) hâlâ Gönderildi.
- 9 Kas: **1.5.9 / KM3 0.8.1** — Champion'ın 28 ligi, 496 kulüp (dört kıta; Klasik'te kıta → lig seçimi). Aktarım aracı `araclar/cbm-veri/` (km28.mjs + km-yaz.py + km3-takim.js, OKU.md). Kulüp kimliği/sırası korunur, kayıtlar bozulmaz. Gerçek fikstür büyük 6 ligde (tsdb ile birebir). Aztek Ligi 17 kulüp → en zayıfı çıktı (16). Android (26) Play dahili test; iOS (25) TestFlight.
- 8 Kas (gece): **1.5.8 / KM3 0.8.0** — basılı tutunca güçlenen şut (tuş çevresinde halka; fazla güç auta gidebilir), PAS basılı tut-bırak = ara pas, geri pasta kaleci ayakla oynar (top kapılabilir), serbest vuruşta baraj, taç/autta ofsayt yok, taçtan doğrudan gol yok, taçta ŞUT = uzun atış. Android (25) Play dahili test; iOS (24) TestFlight beta incelemesinde. Not: KM3 0.7.9'u paralel oturum kullandı (lig/mola » işareti).
- 8 Kas: **1.5.7 / KM3 0.7.8** — duran top kuralı: topçu topa dokunmadan rakip 9,15 m uzakta, top kapma/kayma yok; santrada rakip kendi yarısında. Android (24) Play dahili test; iOS (23) TestFlight beta incelemesinde. Quest'e Meta incelemesi bitince (sürüm kodu 9).
- 8 Kas (günlük görev): **KM3 0.7.9** — lig gol krallığı (ekran + VR; sezon sonunda gol kralı). Web güncellendi; mağaza derlemesi yok (bir sonraki 1.5.x derlemesi Modern'i otomatik alır). Meta v1 (0.7.5) hâlâ "Gönderildi". Apple: Kurt Yolu 1.1.0 hâlâ WAITING_FOR_REVIEW; CBM 4.5.1 de 8 Kas 05:42Z'den beri WAITING_FOR_REVIEW (başka oturum/Emre); Yaşam Rehberi 1.1.0 READY_FOR_SALE.
- 8 Kas: **1.5.6** — lig/kariyer gerçek 2026-27 fikstürüyle başlar (Klasik + Modern; `km3/veri/fikstur.json`, CBM tsdb eşlemesi). Android (23) Play dahili test; iOS (22) TestFlight beta incelemesinde.
- 9 Kas (günlük görev): **KM3 0.9.1** — lig tarihçesi (kulübün sezon sezon karnesi: sıra, O G B M Av P, şampiyon, gol kralı; ekran + VR), VR lig menüsünde satırlar taşmıyor. Web güncellendi; mağaza derlemesi yok. Meta v1 (0.7.5) hâlâ "Gönderildi". Apple: Kurt Yolu 1.1.0 hâlâ WAITING_FOR_REVIEW (Yaşam Rehberi 1.2.0 da WAITING_FOR_REVIEW).
- 10 Kas (günlük görev): **Meta KM3 v1 (0.7.5, kod 8) ONAYLANDI** (değerlendirme 9 Kas; durum "Pending release" — yayın tarihini Emre seçecek). **KM3 0.9.2** — yönetim beklentisi (sezon hedefi, yönetim güveni, sezon sonu değerlendirmesi; ekran + VR + tarihçe). Web güncellendi; mağaza derlemesi yok. Apple: Kurt Yolu 1.1.0 hâlâ WAITING_FOR_REVIEW.
- Steam/Champion kopyası artık `www/klasik/index.html` (+ `*.js`).

## 1.4.0 (hazırlanıyor, 4 Kas)
- Test önerileri paketi (Malazgirt 1.6 / CBM 4.4 ile aynı): Rehber ipucu kartları (ana menü, Hızlı Maç, lig, ilk maç, mola, değişiklik, maç sonu, Ayarlar; eski oyunculara temel ipuçları gösterilmez), Nasıl Oynanır (ana menü, mola menüsü, Ayarlar), ★ Puan ver (`@capacitor-community/in-app-review` 8.0.0; 3. ve 10. galibiyette ya da ligi ilk üçte bitirince, en çok 2 kez), paylaş (`@capacitor/share` 8.0.3), Bize yaz, Verilerimi sil
- Mağaza metinleri + gizlilik politikası güncel (`store/`); App Store numarası çıkınca `www/index.html` → `KM_IOS_ID`
- Derleme: `ios.yml` / `android.yml` (version_name 1.4.0); derleme numarası iş akışının çalıştırma sayısından gelir

## Champion Battle Manager 3.4.0 (24 Eki)
- 2 Kas gece: **1.3.0 (12)** — CBM'nin 34 dizilişi + asistanı (maç öncesi ◀ ▶ seçim ve şema, Otomatik; rakip yaygınlık payıyla seçer), kadrolar `HAVUZ`dan dizilişe göre kurulur. iOS TestFlight + Android dahili test yayında (`imza-anahtari/kaptan-mecit-1.3.0-12-imzali.aab`); VR menüsüne de diziliş geldi.
- 2 Kas: **1.3.0 (11)** — kadrolar Champion Battle Manager'ın türetilmiş dünyasından (`araclar`: CBM `src` + gh-io `veri/cbm/v1/dunya.json` → LEAGUES + KADRO; 6 lig, 114 kulüp, Lukaku → Lakaka). iOS TestFlight (dış grup beta incelemesi bekliyor) + Android dahili test yayında (`imza-anahtari/kaptan-mecit-1.3.0-11-imzali.aab`). Kaptan Mecit VR de aynı motorla güncellendi (web üzerinden, APK değişmeden). Mağaza incelemesi Emre'de.
- 2 Kas: **Kaptan Mecit VR** (Meta Quest, ayrı uygulama, ücretsiz) — https://emreanduv.github.io/kaptan-mecit-vr/ · paket com.anduv.kaptanmecit.vr · Horizon uygulama no 1486658967858040 · 1.0.0 (1) Alpha kanalına yüklendi (taslak). İmza: `imza-anahtari/kaptanmecit-vr-quest.jks` + `KMVR-QUEST-ANAHTAR-OKU.txt` (depoya girmez). Kalan (Emre): yaş grubu öz-sertifikası, Alpha'ya davet onayı, derlemeyi yayınla.
- Malazgirt modu 1.4 (1071 bölüm, 22 sefer; `champion-battle` dalı `araclar/malazgirt-birlestir.py` ile tek dosya), güncel Kaptan Mecit motoru
- iOS 3.4.0 (18) TestFlight + App Store sürümü hazırlandı (derleme bağlı, Yenilikler yazıldı) → "İncelemeye gönder" elle
- Android 3.4.0 (20) imzalı: bilgisayarda `ChampionChess-main/fm2010/magaza/champion-battle-3.4.0-20-imzali.aab` → Play kapalı test (Alpha) yeni sürüm taslağı açık

## 1.2.0 (hazırlanıyor)
- 23 Eki gece: iOS 1.2.0 (10) TestFlight'a yüklendi, dış test grubuna dağıtıldı (`testflight.yml`)
- 23 Eki gece: Android 1.2.0 (10) imzalandı (`imza-anahtari/kaptan-mecit-1.2.0-10-imzali.aab`); Play dahili test sürüm taslağı açık, paket yüklenecek
- 23 Eki gece: Champion Battle Manager 3.3.0 (17) — güncel Kaptan Mecit motoruyla TestFlight'a yüklendi ve dış gruba dağıtıldı
- Oyuncu değişikliği (yedek kulübesi, 5 hak / 3 ara, asistan), kondisyon ve sakatlık, uzatma süresi ve akış kesilince maç sonu düdüğü, sosyal medya/müzik panoları
- Pardus: `pardus/kaptan-mecit_1.2.0-1_all.deb` + kaynak paketi (Three.js çıkarıldı, `ses-kurtarici.js` eklendi)
- Mağaza metinleri: `store/magaza-metinleri.md` → "Bu sürümde yenilikler (1.2.0)"

## 1.1.0 (hazırlanıyor)
- 23 Eki: oyuncu değişikliği — 7 kişilik yedek kulübesi (kurmaca), 90 dakikada 5 hak / en fazla 3 ara (devre arası sayılmaz), uzatmada +1 hak ve +1 ara; isteğe bağlı 🤖 asistan değişikliği (Ayarlar + II menüsü: yorgunluk, sakatlık, skor); oyuncu kondisyonu (yoruldukça yavaşlar) ve maç içi sakatlık; Champion Battle'dan gelen eleme maçlarında uzatma ve seri penaltılar. Mağaza derlemesi alınmadı (TestFlight/Play için yeni derleme gerekir)
- Beş kamera: Klasik, Dinamik, Tele, Stadyum (20 Eki gece: 3D motor kaldırıldı, tüm kameralar TV yayın motorunun çatalı), TV (20 Eki: kenardan dümdüz yayın açısı, gölgeli çizim oyuncular, kontrol edilen oyuncunun adı; 2D tuval, Three.js gerekmez)
- 20 Eki: TV kamerası eklendi; Pardus paketi bu değişikliği içermiyor
- 20 Eki oynanış denetimi (hızlandırılmış simülasyon): topla çizgi dışına/kaleye sürünce oyun durmuyordu → taç/aut/korner/gol; kaleci çerçeve dışı şutları da tutuyordu, şutlar hiç üstten gitmiyordu → maçlarda neredeyse hiç korner/aut yoktu, düzeltildi; pas ve şutta baskı altında sapma; duran topta itilen rakipler saha içinde
- 20 Eki kamera denetimi: Dinamik/Tele'de kameranın arkasına taşan zemin parçaları hiç çizilmiyordu (köşelerde kara boşluk) → yakın düzlem kırpması; Klasik yatay ekranda (bilgisayar/Pardus/Champion) geniş görünüm; TV'de telefonda yakın taç çizgisi tuşların üstünde
- 20 Eki gece: iOS 1.1.0 (5) TestFlight — "Mr. Anduv! Ekibi" + "Mr. Anduv! Testçiler" (Testing; beta incelemesi anında geçti)
- 20 Eki gece: Android 1.1.0 (5) dahili testte yayında (`imza-anahtari/kaptan-mecit-1.1.0-5-imzali.aab`, imza SHA-256 DC:58:9E:56…)
- 20 Eki taktik motoru (Emre'nin ideal 11'inden rol şablonları, oyunda isimler kurgusal): 4-2-3-1 — 1 oyunu kuran/süpürücü kaleci, 2 ve 3 bindiren bekler, 4 sert stoper, 5 oyun kuran stoper, 6 baskıcı dinamo, 8 box-to-box, 7 içe/dışa sağ açık, 10 hatlar arası oyun kurucu, 9 içeri kayan ikinci forvet, 11 hedef santrfor; blok topa ve topa sahipliğe göre yükselir (topa sahipken stoperler orta sahaya), kontra/organize atak, orta + kafa, kalecinin kısa oyun kurması; devre arasında kaleler değişir (Dinamik kamera döner); kaleci kurtarışı güçlendi; Zor bir tık yumuşadı
- 20 Eki gece: taktik motorlu 1.1.0 (6) — iOS TestFlight (iki grup, Testing) + Android dahili test yayında (`imza-anahtari/kaptan-mecit-1.1.0-6-imzali.aab`)
- 20 Eki stadyum mimarisi (kulüp teması yok, yalnız mimari his): sahaya yakın dik iki katlı tribünler + camlı loca kuşağı, kapalı köşeler, çelik makaslı çatı + saçak projektörleri, kuzey kale arkasında tek parça dev tribün; dört çizim motorunda (Klasik piksel, Dinamik/Tele, TV şeritleri, Stadyum 3D + pilonlar); atletizm pisti kaldırıldı
- 20 Eki gece: tek yayın motorlu 1.1.0 (9) — Dinamik/Tele/Stadyum TV motorunun çatalı, Three.js kaldırıldı; iOS TestFlight dış grup (beta onaylı) + Android dahili test yayında (`imza-anahtari/kaptan-mecit-1.1.0-9-imzali.aab`)
- 20 Eki: LED panolu 1.1.0 (8) — iOS TestFlight dış grup (beta onaylı, API ile: `testflight.yml`) + Android dahili test yayında (`imza-anahtari/kaptan-mecit-1.1.0-8-imzali.aab`)
- 20 Eki gece: stadyumlu 1.1.0 (7) — iOS TestFlight (iki grup, Testing) + Android dahili test yayında (`imza-anahtari/kaptan-mecit-1.1.0-7-imzali.aab`)
- Plan aynı: 1.0.0 onayları gelince 1.1.0 (9) mağaza incelemesine (App Store: yeni sürüm 1.1.0 + build 9; Play: kapalı teste terfi / üretim)
- Champion Battle Manager: `champion-battle` dalındaki motor güncel, yeni TestFlight derlemesi alınmadı
- Topsuz oyun yapay zekası (koşular, pas açıları, bindirme, adam adama savunma; zorluğa bağlı)
- Golde seyirciler tek tek coşar; panolarda yalnız Mr. Anduv! markası, oyunları, uygulamaları ve sosyal medya hesapları
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
- Pardus: `pardus/kaptan-mecit_1.2.0-1_all.deb` + kaynak paketi + `pardus/BASVURU.md`

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

## VR · Gerçekçi görünüm (2026-11-02)
- emreanduv.github.io/kaptan-mecit-vr: iskeletli 3B futbolcular (gercekci.js), gölgeler, biçilmiş çim, desenli top. Menü > Görünüm: Gerçekçi / Retro. Quest uygulaması TWA olduğu için kendiliğinden güncellenir.

## Kaptan Mecit 2 · Meta Quest (2026-11-02)
- Horizon uygulaması: Kaptan Mecit 2 (id 1488570437666893), paket com.anduv.kaptanmecit2, Alpha kanalına 1.0.0 (1) yüklendi.
- İmza anahtarı: Belgeler/Kaptan-Mecit/imza-anahtari/kaptanmecit2-quest.jks (+ KM2-QUEST-ANAHTAR-OKU.txt). Depoya girmez.
- Derleme: Actions > Kaptan Mecit 2 (Meta Quest APK) → imzasız APK; Mac'te apksigner ile imzalanır.
- Emre bekleyen: yaş grubu öz sertifikası; Alpha davetinde "Kabul ediyorum" + "Davet Gönder".

## Kaptan Mecit 3 · Meta Quest (2026-11-03)
- Horizon uygulaması: Kaptan Mecit 3 (id 1488865890970681), paket com.anduv.kaptanmecit3, Alpha kanalına 0.2.0 (1) yüklendi.
- İmza anahtarı: Belgeler/Kaptan-Mecit/imza-anahtari/kaptanmecit3-quest.jks (+ KM3-QUEST-ANAHTAR-OKU.txt), şifre Mac'te üretildi. Depoya girmez.
- Derleme: Actions > Kaptan Mecit 3 (Meta Quest APK). Web: emreanduv.github.io/kaptan-mecit-3/
- 4 Kas: Alpha'da 0.4.0 (3) yayında: tribün tezahüratları, mola / yedek kulübesi, rehber, Nasıl oynanır. Alpha daveti (emreanduv@hotmail.com) gönderildi, yaş sertifikası tamam. Aynı gün 0.4.1 (4: yeni tribün sesleri) ve 0.5.0 (5: kaleci uçuşu, dokunmatik kontrol).
- 4 Kas 14:10: ✅ Horizon Store'a İNCELEMEYE GÖNDERİLDİ (başvuru v1, derleme 0.5.1 (6) Production kanalında). Metinler EN, Oyun > Spor > Takım sporları, Early Access, tek oyunculu, Touch, oturarak/ayakta, Konforlu, internet gerekmez, ücretsiz, dil Türkçe; yaş grubu 13+, IARC: PEGI 3; görseller store/km3-meta; gizlilik https://emreanduv.github.io/kaptan-mecit-3/gizlilik.html. Onay gelince yayın tarihi Emre'de.
- Karar (4 Kas, Emre): telefonda şimdilik KM1 1.4.0 (lig modu) kalır; KM3 önce Horizon Store'a çıkar, lig modu gelince telefonda Kaptan Mecit 2.0 olarak KM1'in yerine geçer. Play'in 16 KB sayfa şartı için KM3'ün telefon derlemesi Godot 4.5+ ister (4.3 kütüphaneleri 4 KB hizalı).
- 5 Kas (günlük görev): Horizon incelemesi hâlâ "Gönderildi" (değerlendirme tarihi yok). **0.6.0 lig modu** main'de (`km3/OKU.md` → 0.6.0) ve web'de; web derlemesi 0.4–0.5.1'de açılışta derlenmiyordu (OpenXRInterface türü web'de yok) → düzeltildi. Quest Alpha'ya 0.6.0 henüz yüklenmedi (VR'da lig maçı uçtan uca bir tur daha denenecek).
- 5 Kas App Store: Kurt Yolu 1.1.0 WAITING_FOR_REVIEW (inceleme 25 Eki'den beri bekliyor); CBM 4.4.0 zaten READY_FOR_SALE.
- Önceki Karar (4 Kas, Emre): mağazalarda TEK uygulama "Kaptan Mecit" olacak, KM3 motoruyla (App Store'da reddedilen KM 1.0.0'ın yerine aynı uygulamanın yeni sürümü; ayrı "Kaptan Mecit 3" açılmaz). Sıra: Meta Horizon Store → Google Play kapalı test → App Store (Kurt Yolu ve CBM sonuçlandıktan sonra) → Steam (Valve doğrulaması bitince).

## Kaptan Mecit 1.4.1 (4 Kas): açılışta boş ekran düzeltmesi
- Sorun: 1.4.0 (13) iPhone'da açılınca yalnız çim çizgileri; ana menü çizilmiyordu. Neden: 1.0–1.2'den kalan kariyer kaydında artık olmayan kurmaca kulüpler fikstürde duruyordu; eski denetim yalnız kullanıcının kendi takımına bakıyordu → puan tablosu (table) çöküyor, render hiç bitmiyordu.
- Düzeltme: kmKariyerGecerli: fikstürdeki bütün takımlar denetlenir, biri bile yoksa kariyer sıfırlanır. render() artık korumalı: hata olursa kariyeri sıfırlayıp ana menüyü yine çizer (bilgi notu çıkar).
- Dağıtım: iOS 1.4.1 (14) TestFlight 'Mr. Anduv! Testçiler' grubuna eklendi (beta incelemesi bekliyor); Android 1.4.1 (14) imzalandı (imza-anahtari/kaptan-mecit-1.4.1-14-imzali.aab; Mac VM'de Temurin 17 jarsigner) ve dahili teste yayınlandı.
- Deneme: araclar/dene/ (WebKit), .github/workflows/ios-sim-dene.yml (iOS simülatörü; macos-15-intel kuyruğu daha hızlı).
