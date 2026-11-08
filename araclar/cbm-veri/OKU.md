# Champion Battle Manager verisini Kaptan Mecit'e aktarma (28 lig)

Kaptan Mecit (Klasik ve Modern) ligleri, kulüpleri ve kadroları Champion Battle Manager'ın türetilmiş dünyasından gelir
(emreanduv.github.io `veri/cbm/v1/dunya.json`, her pazartesi `cbm-kadro.yml` ile yenilenir). Aktarım üç adım:

1. `km28.mjs` — CBM'nin kendi kodunu (Mac: `~/Documents/Champion-Battle-Manager/src`, `core/dunya.js` + `core/taktik.js`) geçici bir kopyada
   çalıştırır; CBM kaynağında henüz olmayan ligleri (ad/ülke dunya.json'dan) ve lig itibarlarını (`ITIBAR`) ekler. Çıktı: km28.json.

       node km28.mjs <cbm-src> <dunya.json> km28.json -

2. `km-yaz.py` — km28.json'u Klasik'e (`www/klasik/index.html`: LEAGUES, HAVUZ, LG_ORDER, GERCEK_FX) ve Modern'in fikstürüne
   (`km3/veri/fikstur.json`) yazar. Kulüp kimlikleri tsdb anahtarıyla eski dünyadakiyle eşlenir, kulüp sırası korunur
   (Klasik kariyer kaydı kimlikle, Modern lig kaydı sırayla tutulur; ikisi de bozulmaz). Tek sayıda kulübü olan ligde en zayıf kulüp çıkar
   (fikstürde bay olmasın). Gerçek fikstür yalnız `veri/gercek-dunya/v1/maclar-<lig>.json` olan liglerde (şimdilik büyük 6).

       python3 km-yaz.py km28.json dunya.json eski-dunya.json <gercek-dunya/v1> <kaptan-mecit> [eski index.html]

   `eski-dunya.json`: kimliklerin geldiği önceki dunya.json (Pages geçmişinden, ör. `git show c4594b8:veri/cbm/v1/dunya.json`).

3. `km3-takim.js` — Modern'in `km3/veri/takimlar.json`'unu Klasik'in verisinden (dizilişe göre kadro) üretir, panoları korur.

       node km3-takim.js <kaptan-mecit>

Sonra: Klasik Playwright denemeleri, `km3/dene/lig_dene.gd` (bütün liglerde sezon), sürüm yükselt, KM3 web dışa aktar → Pages, derlemeler.

Eski betik `kmveri.mjs` (yalnız 6 lig) yerine `km28.mjs` kullanılır.
