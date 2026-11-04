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
