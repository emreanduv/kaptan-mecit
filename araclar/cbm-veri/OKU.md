# CBM kadrolarını Kaptan Mecit'e aktarma

`kmveri.mjs`, Champion Battle Manager'ın kaynağıyla (Mac: `~/Documents/Champion-Battle-Manager/src`) çalışır:
CBM'nin `dunyaUret` + `uyum` fonksiyonlarıyla türetilmiş dünyayı (emreanduv.github.io `veri/cbm/v1/dunya.json`) üretir,
her kulübün en iyi 11'ini Kaptan Mecit yerlerine dizer, yedekleri ekler ve `www/index.html` içindeki `LEAGUES` ile `KADRO`yu besleyen JSON'u yazar.

    node kmveri.mjs dunya.json eski-LEAGUES.json kmveri.json   # (betik CBM src klasörünün yanında çalışır)
