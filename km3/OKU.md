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

## 0.4.0
- Tribün sesleri: her tribün kendi takımı için (ev: güney kale arkası + ana tribün, misafir: kuzey kale arkası), sesler tribünün yerinden gelir (AudioStreamPlayer3D). Klipler `araclar/ses/tezahurat.py` ile sentezlenir (28 sesli kalabalık şarkısı + davul + alkış, ıslık, yuh): `python3 araclar/ses/tezahurat.py`.
  - Gol: atan takımın tribünü tezahürata başlar, diğeri susar. Faul: faul yiyenin taraftarı ıslıklar; kart: kart görenin taraftarı ıslıklar / yuhalar; ofsayt: ofsayta düşenin taraftarı ıslıklar; korner ve penaltı: alkış; VAR iptali: yuh. Arada hücum eden / önde olan tribün kendiliğinden tezahürat yapar.
- Mola (yedek kulübesi): maç içinde menü = mola. Çıkan (sakat ve en yorgun önce, kondisyon %), Giren (aynı mevki önce), Değişikliği yap (5 hak / 3 ara), Asistan değişiklikleri Açık/Kapalı (kapalıyken sakatlıkta yine girer), Nasıl oynanır, Maçı bırak. `arayuz/mola.gd`; ekranda ve VR'da aynı satırlar.
- Rehber: ilk maçlarda yeri gelince bir kez ipucu (koş, pas/şut, top kap, koltuk/kamera, mola); "Rehberi baştan göster". Nasıl oynanır: ana menüde ve molada, görüş için e-posta.
- Deneme: `--mac --ileri=200 --menu --ekran=x.png` (mola), `--menu --yardim` (Nasıl oynanır), `--vrsahte` ile VR paneli.

## 0.5.0
- Dokunmatik kontrol (`arayuz/dokunmatik.gd`): ekranın solunda parmağın altında beliren çubuk, sağ altta PAS / ŞUT, üstte II mola. Dokunmatik ekran varsa kendiliğinden açılır; `--dokun` ile masaüstünde denenir. Rehber ve Nasıl oynanır dokunmatiğe göre yazar.
- Kaleci uçuşu: kurtarış denemesinde kaleci topun kale çizgisine geleceği yere yana uçar (yük al → uç, kollar topa → yere düş → kalk); yakın ve alçak topta göğüste tutar. Motor konumu iniş yerine geçer, görüntü oraya süzülür. Deneme: `dene/kaleci_dene.tscn -- cikti.png [tur=0|1] [yan=±1] [z=yükseklik]`.
- Molaya Kamera (VR'da Koltuk) satırı.

## 0.6.0 — Lig modu
- Ana menüde **Lig** (VR menüsünde **LİG MODU**): `veri/takimlar.json`'daki 6 ligden birini ve kulübünü seç, sezona başla. Çift devreli tam fikstür (18 takımda 34, 20 takımda 38 hafta; ev/deplasman dengeli, art arda en çok 2-3 iç saha/deplasman).
- Her hafta kendi maçını oynarsın (süre, zorluk, diziliş ve kamera ana menüden), ligin diğer maçları `Taktik` kadrolarının güç değeriyle (asistanın kurduğu ilk 11'in mevkiye uyumlu ortalama yeteneği) hızlı simüle edilir (Poisson, ev avantajı). "Maçı simüle et" ile kendi maçını da simüle edebilirsin. Maç yarıda bırakılırsa hafta oynanmamış sayılır.
- Puan durumu: O G B M A Y Av P + son beş maç formu; sıra şeridi (şampiyonluk altın, ilk dört yeşil, son üç kırmızı). Sağda sonraki maç, haftanın sonuçları ve eylemler. Sezon sonunda şampiyon, "Yeni sezon".
- Kayıt `user://km3-lig.json`; "Verilerimi sil" bunu da siler. "Ligi bırak" iki kez basınca sezonu siler.
- Kod: `motor/lig.gd` (fikstür, tablo, simülasyon, kayıt, menü satırları), `arayuz/lig_ekran.gd` (düz ekran), `vr/vr.gd` (3B lig paneli).
- Deneme: `godot --headless --path km3 -s dene/lig_dene.gd` (6 ligin hepsinde tam sezon, fikstür/kayıt/silme denetimi); `--ligsezon=12 [--liglig=1 --ligtakim=3] --lig --ekran=x.png` (lig ekranı), `--ligsezon=3 --ligmac --dene` (lig maçını oynat, sonucu işle), `--vrsahte` ile VR paneli.

## 0.7.5 — Deplasmanda gerçek ev sahibi
- Lig maçında kullanıcı deplasmandaysa (`Mac.kul_dep`): tabela, stadyum skor ekranları, başlama/maç sonu afişleri ve mola başlığı ev sahibini önce yazar ("EV 1-0 DEP"); ev sahibi kendi formasını giyer (forma çakışmasında misafir değişir); tribünler ev sahibinin renginde, kuzey kale arkası misafir (kullanıcının) taraftarı; taraftar sesleri ve tribün coşkusu doğru tarafa (`ana._y()`). Motorda kullanıcı yine T[0]; sonuç Lig'e doğru ev/deplasman sırasıyla yazılır.

## 0.7.7 — Lig fikstürü
- Lig ekranında **Fikstür** satırı (VR'da da): sol panel puan durumu ile kulübün sezon fikstürü arasında geçer. Menajer oyunlarındaki gibi iki devre yan yana (dik ekranda alt alta): hafta · İ/D · rakip (şu anki sırası) · skor · sonuç (G/B/M renkli); sıradaki maç vurgulu, başlıkta sezonun G/B/M dökümü. VR panelinde sıradaki maçın devresi gösterilir.
- Kod: `Lig.gorunum`, `Lig.fikstur_biz()`, `Lig.sonuc_harf()`; `LigEkran._fikstur_panel()`; `vr._lig_ciz()`.
- Deneme: `--ligsezon=12 --lig --ligfik --ekran=x.png` (`--vrsahte` ile VR paneli).

## 0.7.9 — Gol krallığı
- Lig ekranında **Gol krallığı** satırı (VR'da da): sol panel ligin en golcü 20 oyuncusunu gösterir (# · oyuncu · kulüp · gol; eşit golde aynı sıra, kendi oyuncuların vurgulu). Sezon sonunda şampiyonun yanında gol kralı da yazılır.
- Kendi maçındaki goller maç motorunun gol olaylarından gelir (kendi kalesine gol sayılmaz, VAR iptali düşer); simüle edilen maçların golleri kulübün ilk 11'ine mevkiye göre paylaştırılır (forvet 5, orta saha 1,8, defans 0,55, kaleci 0).
- Kayıtta `golcu` (kulüp başına [ad, pay]) ve `goller` ("kulüp|ad" → gol). Eski kayıtlar açılınca `golcu` kurulur, krallık o haftadan itibaren sayılır.
- Kod: `Lig.gol_krallari()`, `Lig.gol_krali_metni()`, `LigEkran._goller_panel()`, `vr._lig_ciz()`. Deneme: `dene/lig_dene.gd` (dağıtılan gol = atılan gol, kayıt aynı liste), `--ligsezon=14 --lig --liggol --ekran=x.png` (`--vrsahte` ile VR).
- Seçili satır işareti `▶` web fontunda kutu görünüyordu → lig ve mola satırlarında `»` (VR ana menüsü değişmedi).

## 0.9.1 — Lig tarihçesi
- Lig ekranında **Tarihçe** satırı (VR'da da): kulübün sezon sezon karnesi, menajer oyunlarındaki kulüp geçmişi gibi — sezon · sıra · O G B M Av P · şampiyon · gol kralı; süren sezon en üstte vurgulu, şampiyon olunan sezon altın. Başlıkta özet: "n sezon · k şampiyonluk · en iyi sıra x."
- Biten sezon `d.tarih`'e yazılır (aynı sezon iki kez yazılmaz); "YENİ SEZON" (`Lig.sonraki_sezon()`) tarihçeyi taşır; "Ligi bırak" ve "Verilerimi sil" siler. Eski kayıtlar açılınca boş tarihçeyle sürer.
- VR lig menüsünde satırlar çoğalınca (Tarihçe, Kupalar, Maç raporu) satır aralığı ve yazı küçülür; alttaki ipucu yazısının üstüne taşmaz.
- Kod: `Lig.tarih_satirlari()`, `Lig.tarih_ozet()`, `LigEkran._tarih_panel()`, `vr._lig_ciz()`. Deneme: `dene/lig_dene.gd` (28 ligde tarihçe + kayıt), `--ligsezon=90 --lig --ligtarih --ekran=x.png` (hafta sayısı sezonu aşınca yeni sezona geçer; `--vrsahte` ile VR).

## 0.9.2 — Yönetim beklentisi
- Menajer oyunlarındaki yönetim kurulu gibi: sezon başında kulübün güç sırasına göre **hedef** konur (1. → Şampiyonluk, 2–3 → İlk üç, 4–6 → İlk altı, n−5'e kadar → Orta sıra (ilk %60), altı → Ligde kalmak (son üçe düşmemek)).
- **Yönetim güveni** (%5–99): 60'tan başlar; oynanan her maçta alınan puan ile güce göre beklenen puan (sim_mac'in Poisson modeliyle 3×G + B olasılığı) farkının 3 katı eklenir; sezonun ikinci yarısında hedefin gerisindeki her sıra −2, önündeki +1. Durum: Çok memnun / Memnun / Kararsız / Huzursuz / Çok huzursuz.
- Lig ekranı sağda **YÖNETİM** paneli (hedef, şu anki sıra, güven çubuğu, açıklama); sezon sonunda "Yönetim: Hedef tuttu / Beklentinin üstü / Hedefin altında". Tarihçede **Yönetim** sütunu (süren sezonda hedef, biten sezonda sonuç). VR panelinde sonraki maçın altında güven, sezon sonunda sonuç; VR'da sezon sonu mesajı alt satırdan taşmıyor, uzun başlık küçülür.
- Kayıtta `d.hedef` ({k, s}), tarihçede `hd`/`hs`. Eski kayıtlar açılınca hedef kurulur; eski tarihçe satırlarında Yönetim boş kalır. "Ligi bırak" / "Verilerimi sil" hepsini siler (aynı dosya).
- Kod: `Lig._hedef_kur()`, `hedef_adi/sira/aciklama()`, `hedef_sonuc()`, `beklenen_puan()`, `guven()`, `guven_adi()`, `yuzde()` (TR %72, EN 72%), `LigEkran._yonetim_panel()`, `vr._lig_ciz()`. Deneme: `dene/lig_dene.gd` (28 ligde hedef/güven/kayıt/eski kayıt), `--ligsezon=22 --ligtakim=8 --lig --ekran=x.png` (`--vrsahte`, `--dil=en`).

## 0.9.11 — Lig istatistikleri
- Lig ekranında **İstatistik** satırı (VR'da da), menajer oyunlarının istatistik sayfası gibi. **Lig rekorları:** en golcü takım, en sağlam savunma, iç sahanın ve deplasmanın en iyisi, formda takım (son 5 maç), en uzun galibiyet ve yenilmezlik serisi, en farklı skor, en gollü maç, maç başına gol, ev sahibi / beraberlik / deplasman yüzdesi. **Kulübün karnesi:** iç saha ve deplasman G-B-M · puan, en farklı galibiyetimiz, en ağır yenilgimiz, süren seri, yenilmezlik serisi (en uzun · şu an). Bizim kulübü ilgilendiren satırlar mavi.
- Her şey fikstürdeki oynanmış maçlardan hesaplanır; ayrı kayıt yok (aynı `user://km3-lig.json`; "Verilerimi sil" / "Ligi bırak" siler).
- Kod: `Lig.istatistik()`, `LigEkran._ist_panel()`, `vr._lig_ciz()`. Deneme: `godot --headless --path km3 -s dene/ist_dene.gd` (28 ligde satır sayısı, iç saha + deplasman puanı = tablo puanı), `--ligsezon=24 --lig --ligist --ekran=x.png` (`--vrsahte`, `--dil=en`).

## 0.9.9 — Sezon ödülleri
- Lig ekranında **Ödüller** satırı (VR'da da), menajer oyunlarının sezon sonu ödülleri gibi: **yılın oyuncusu** yarışı (ilk 10: # · oyuncu · mevki · kulüp · gol · puan), **sezonun 11'i** (4-3-3: 1 kaleci, 4 defans, 3 orta saha, 3 forvet) ve **yılın teknik direktörü** (güç sırasına göre beklenenin en çok üstüne çıkan kulüp; "güç sırası 11 → ligde 3."). Sezon sürerken "Ödül yarışı", bitince "Sezon ödülleri" (birinci ★).
- Puan: yetenek/2 + kulübün maç başı puanı ×8 + lig sırası (0–10) + lig golü (sezon temposuna göre; forvet 2, orta saha 2,6, defans 3,2 ağırlık) + kaleci/defansa yenilen gol ortalaması + orta sahaya oyun kurucu payı (+4). 56 sezonluk denemede yılın oyuncusu: 35 forvet, 17 orta saha, 4 defans.
- Sezon sonu mesajına ve VR sezon sonu yazısına "Yılın oyuncusu" eklendi; tarihçeye `yo` (yılın oyuncusu) ve `td` (yılın teknik direktörü sen miydin) yazılır, tarihçe özeti "n kez yılın teknik direktörü" der. Ayrı kayıt yok (aynı `user://km3-lig.json`; "Verilerimi sil" / "Ligi bırak" siler).
- Kod: `Lig.odul_puanlari()`, `yilin_oyuncusu_adaylari()`, `yilin_oyuncusu_metni()`, `sezonun_11i()`, `yilin_td()`, `yilin_td_metni()`; `LigEkran._odul_panel()`; `vr._lig_ciz()` (uzun TD yazısında yazı küçülür). Deneme: `dene/lig_dene.gd` (28 ligde 10 aday, 11'in mevki kotası, TD, sıralama, kayıt, tarihçe), `--ligsezon=20 --lig --ligodul --ekran=x.png` (`--vrsahte`, `--dil=en`).

## 0.9.8 — Kadro
- Lig ekranında **Kadro** satırı (VR'da da), menajer oyunlarının kadro ekranı gibi: no · mevki · oyuncu · yetenek (renkli çubuk + 0-100 puan) · bu sezonki lig golü. Üstte asistanın kurduğu ilk 11 (mevki sırasıyla), altta yedekler; başlıkta diziliş ve ilk 11 ortalaması. Kadro ana menüde seçilen dizilişe göre kurulur (maçtaki kadroyla aynı; Otomatik'te asistanın seçtiği).
- Mevkiler Türkçe (KL, SĞB, STP, SLB, DOS, MOS, SĞO, SLO, OOS, SĞK, SLK, SF), İngilizcede GK, RB, CB, LB, DM, CM, RM, LM, AM, RW, LW, ST. Yetenek: Champion'ın yetenek puanı / 1,7.
- Oyuncu adları İngilizce çeviriden geçmez (kadro ve gol krallığı; "D. Gol" → "D. Goals" oluyordu).
- Kod: `Taktik.kadro_kur` oyunculara `mk` (mevki) ve `ca` ekler; `Lig.kadro_satirlari()`, `kadro_ozet()`, `mevki_adi()`, `yetenek()`, `Lig.diz` (ana menüdeki diziliş); `LigEkran._kadro_panel()`; `vr._lig_ciz()`. Deneme: `dene/lig_dene.gd` (28 ligde ilk 11, yetenek aralığı, gol toplamı), `--ligsezon=12 --lig --ligkadro --ekran=x.png` (`--vrsahte`, `--dil=en`).

## 0.9.7 — Taç döngüsü düzeltildi
- Emre (11 Kas 2026): taçta top içeri girmiyor, taç hakkı bir bize bir rakibe geçiyordu. Sebep: taçı kullanacak oyuncu koşarak geliyor, yerine varınca hızı sıfırlanmadığı için çizginin dışına kayıyor (−0,7 m) ve sahaya sırtını dönüyordu; atışta top da çizginin dışından bırakılıyor, ilk adımda yeniden auta çıkıp taç rakibe geçiyordu (eski motorla tam maçlarda 15 taçtan 8'i).
- Düzeltme (`motor/mac.gd`): yerine varınca hız sıfır; `set_piece.nokta` ile oyuncu duran top boyunca yerinde durur (`mesafe_kurali`); duran toptan bırakılan top sahanın içinden (≥0,2 m) oyuna girer (`release`). Klasik'e de aynı güvence (`www/klasik/index.html`).
- Deneme: `dene/tac_kos.gd` (taç, koşarak gelen oyuncu, iki kenar, 7 nokta, insan/yapay zekâ: 56 taç, 0 döngü, top çizginin dışında 0 m), `dene/tac_pingpong.gd` (tam maçlar: dokunulmadan yeniden taç 0).

## 0.9.6 — Klasik kumanda kaldırıldı
- Emre'nin kararı (11 Kas 2026): futbolda dokunmatik daha iyi. `ana.klasik` her zaman false, molada Kontrol satırı gizli (`Mola.SIRA`, satır 9 işlem yapmaz), VR molası 9 satır. `dokunmatik.gd` içindeki klasik çizim kodu duruyor ama kullanılmıyor.

## 0.9.5 — Klasik kumanda büyüdü
- `dokunmatik._k()`: yh = P*.41, düğme r = P*.235; ok uçları haçla orantılı. Klasik kumandada üstteki imza gizli (`ana._yerlesim`), panelde yazılı. `Mola.IPUCU` 5. sütun: klasik kumanda ipuçları. Deneme: `--klasik`.

## 0.9.4 — Mola ekranı düzeltmesi
- Mola düğmelerinin yazısı odak/basılı durumda da koyu (`ana.gd`, bütün font_*_color); satır aralığı 5; ekran sırası `Mola.SIRA` (Kontrol, Kamera'nın altında; MAÇI BIRAK en sonda), klavye yukarı/aşağı da bu sırayla gezer. `dil.gd`: Kontrol / Klasik kumanda / Dokunmatik çubuk / oyun kolu.

## 0.9.3 — Klasik kumanda
- Molada yeni satır **Kontrol**: Dokunmatik çubuk / Klasik kumanda (`user://km3-ayar.cfg` → `kontrol/klasik`). Klasik kumandada iki yanda panel: solda sabit yön haçı (8 yön, çaprazlar dahil) ve MENÜ, sağda A (ŞUT) / B (PAS) — basılı tutunca güç halkası dolar. Tabela ve imza panellerin içine kaçmaz (`ana._yerlesim`). Kod: `arayuz/dokunmatik.gd` (`klasik`, `_k`, `_input_klasik`, `_ciz_klasik`).
- Oyun kolu zaten vardı (sol çubuk koş, A pas, B/X şut, Y kamera, Start mola); her modda çalışır.
- Deneme: `km3-ayar.cfg`'ye `[kontrol] klasik=true` yaz, `--mac --ileri=60 --dokun --ekran=x.png`.

## CBM Modern — Champion Battle Manager maçını izleme
- Web derlemesi `?cbm=1` ile açılınca menü ve arayüz gizlenir, ses kapanır; maçı Champion Battle Manager'ın motoru oynatır, burası yalnız çizer (oyuncular gerçek hareketlerle, stadyum, kameralar).
- Köprü: CBM iframe penceresine yazar → `window.__cbmKurulum` (takımlar, formalar, oyuncular), her karede `window.__cbmKare` (konumlar, top, skor, dakika, yön), `window.__cbmOlay` (vuruş, kaleci uçuşu, değişiklik, kırmızı kart, gol, düdük), `window.__cbmKamera` (0–4). Hazır olunca `window.__cbmHazir = true`.
- Kod: `motor/dis_mac.gd` (Mac'in çizim için gereken yüzü: T, P, ball, goal_y_of…), `ana.gd` → `_dis_*`. `M` artık türsüz (Mac ya da DisMac).
- Deneme: `--cbmdene=<önek>` → `<önek>.kurulum.json` + `<önek>.kareler.json` (30 Hz kayıt; üretici: cbm4 tarafında motoru Node'da çalıştıran kayıt betiği). Örnek: `xvfb-run godot --path km3 --rendering-driver opengl3 -- --cbmdene=/tmp/cbm --ekran=x.png --bekle=5 --kamera=4`.
