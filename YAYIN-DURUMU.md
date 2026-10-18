# Kaptan Mecit — Yayın durumu (18 Ekim 2026)

## Hazır olanlar
- Oyun 1.0.0: Hızlı Maç, 6 lig × 20 kulüp lig kariyeri, Kolay/Orta/Zor, 2–8 dk maç
- Paket kimliği: `com.anduv.kaptanmecit` (iOS ve Android) · SKU `kaptan-mecit`
- iOS: dikey ekran, `ITSAppUsesNonExemptEncryption = NO`, ikonlar ve açılış ekranı
- Android: dikey ekran, sürüm kodu/adı derleme akışından, ikonlar ve açılış ekranı
- Ekran görüntüleri: `store/screenshots/` (Android 1080×1920), `store/screenshots-ios/` (iPhone 6.9" 1320×2868, iPad 13" 2064×2752)
- Mağaza metinleri `store/magaza-metinleri.md` · Form cevapları `store/form-cevaplari.md` · Gizlilik politikası `store/gizlilik-politikasi.html` → yayında: https://claude.ai/artifact/9dcY3CsGCnidaUkQRDUhHB (Paylaş menüsünden herkese açık yapılmalı)
- Pardus: `pardus/kaptan-mecit_1.0.0-1_all.deb` + kaynak paketi + `pardus/BASVURU.md`

## Yükleme (imza) anahtarı — KAYBETME
- Bilgisayar: `imza-anahtari/kaptanmecit-upload.jks` (git dışında), alias `kaptanmecit`, şifre `imza-anahtari/SIFRE-OKU.txt`
- SHA-256: DC:58:9E:56:6F:47:D3:90:5F:8B:D3:E5:F2:42:34:93:45:0B:7B:1E:87:34:3F:5B:9A:D8:AD:54:0C:46:AB:C3
- Google Drive'a yedekle

## Mağaza durumu
**App Store Connect** — uygulama kimliği `6824240380`
- Build 2 (1.0.0) yüklendi, sürüme bağlandı; metinler, ekran görüntüleri, yaş derecelendirmesi, fiyat, kategori tamam
- App Privacy: "Data Not Collected" yayımlandı
- TestFlight: "Mr. Anduv! Ekibi" (dahili) + "Mr. Anduv! Testçiler" (harici) — build 2 beta incelemesinde
- KALAN (Emre): sürüm sayfasında **Add for Review → Submit**

**Google Play Console** — uygulama kimliği `4974040305096795281`
- Dahili test 1.0.0 (2) yayında ("Kaptan Mecit Testçiler")
- Uygulama içeriği beyanlarının hepsi, mağaza girişi (metin, ikon, özellik grafiği, 5 ekran görüntüsü) tamam
- Kapalı test (Alpha): Türkiye, "Kaptan Mecit Testçiler" listesi, 1.0.0 (2) sürümü hazır
- KALAN (Emre): Yayın özeti → **15 değişikliği incelemeye gönder**
- Üretim için: en az 12 testçi, 14 gün kapalı test → "Üretime başvur"

**Pardus** — beklemede (`pardus/BASVURU.md`)

## Güncelleme çıkarma
1. `www/index.html` değişir → `kaptanmecit.html` (Champion) ve `pardus/` kopyası da güncellenir → GitHub'a gönder.
2. iOS: Actions → "iOS (App Store Connect / TestFlight)" → sürüm adını artır.
3. Android: Actions → "Android (Google Play paketi)" → `builds` dalındaki imzasız `.aab`'yi imzala:
   `jarsigner -sigalg SHA256withRSA -digestalg SHA-256 -keystore imza-anahtari/kaptanmecit-upload.jks paket.aab kaptanmecit`
