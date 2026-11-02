# Kaptan Mecit 3 (Godot 4.3)

Kaptan Mecit 2'nin üstüne kurulur. Bir Mr. Anduv! yapımıdır.

Yeni: **gerçek hareketler.** Yürüme, koşu, depar ve vuruş, Carnegie Mellon Üniversitesi Hareket Yakalama Veritabanı'ndan
(mocap.cs.cmu.edu; B. Hahne'nin BVH dönüşümü — "araştırma ve ticari kullanım için ücretsiz") bizim iskelete aktarıldı:
`araclar/mocap/donustur.py` → `veri/hareket.json`. Hıza göre iki komşu döngü harmanlanır, adım evresi oyuncunun katettiği
yola bağlıdır (ayak kaymaz). Kayma, düşme, kaleci duruşu/uçuşu ve dururken nefes el yapımı kalır.

Yeni kamera: **Yakın** (topu yandan, alçaktan ve yakından izler).
Hareket denemesi: `godot --path km3 dene/hareket_dene.tscn -- cikti.png` (yürü / koş / depar / vuruş yan yana).
