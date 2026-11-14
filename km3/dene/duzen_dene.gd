extends SceneTree
# Düzenleme modu: kulüp/oyuncu düzenlemesi kaydedilir, yeni yüklemede uygulanır, paket dışa/içe aktarılır, sıfırlanır.
func _veri() -> Dictionary: return JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
func _init() -> void:
	var hata := 0
	var yedek := FileAccess.get_file_as_string(Duzen.KAYIT) if FileAccess.file_exists(Duzen.KAYIT) else ""
	Duzen.hepsini_sifirla(); Duzen._orijinal = {}
	var v := _veri(); Duzen.uygula(v)
	var t: Dictionary = v.ligler[0].takimlar[0]
	var oz_ad: String = t.ad; var oz_oy: String = t.oy[3].n
	var oy := []
	for o in t.oy: oy.append({"n": o.n, "no": o.no})
	oy[3].n = "Mecit Kaptan"; oy[3].no = 23
	Duzen.takim_yaz(t, "Benim Kulübüm", "BKM", "#0A2D6E", "#FDB912", oy)
	Duzen.lig_yaz(v.ligler[0], "Benim Ligim")
	Duzen.kaydet(); Duzen.uygula(v)
	if t.ad != "Benim Kulübüm" or t.oy[3].n != "Mecit Kaptan" or int(t.oy[3].no) != 23 or v.ligler[0].ad != "Benim Ligim": hata += 1; print("HATA uygulanmadı")
	# yeni açılış: kayıttan
	Duzen._orijinal = {}; Duzen.yukle(); var v2 := _veri(); Duzen.uygula(v2)
	if v2.ligler[0].takimlar[0].ad != "Benim Kulübüm" or v2.ligler[0].takimlar[0].kisa != "BKM": hata += 1; print("HATA kayıttan yüklenmedi")
	# oyuncu sırası değişse de düzenleme oyuncuya gider (ada bağlı)
	Duzen._orijinal = {}; var v3 := _veri(); var oyl: Array = v3.ligler[0].takimlar[0].oy; var x = oyl[3]; oyl.remove_at(3); oyl.push_back(x)
	Duzen.uygula(v3)
	if oyl[oyl.size() - 1].n != "Mecit Kaptan": hata += 1; print("HATA sıra değişince kayboldu")
	# paket
	var p := Duzen.paket_metni()
	Duzen.hepsini_sifirla(); Duzen._orijinal = {}; var v4 := _veri(); Duzen.uygula(v4)
	if v4.ligler[0].takimlar[0].ad != oz_ad: hata += 1; print("HATA sıfırlanmadı")
	if Duzen.paket_al("merhaba") != -1: hata += 1; print("HATA geçersiz paket kabul edildi")
	var n := Duzen.paket_al("Arkadaşımın paketi: " + p)
	Duzen.uygula(v4)
	if n != 2 or v4.ligler[0].takimlar[0].ad != "Benim Kulübüm" or v4.ligler[0].takimlar[0].oy[3].n != "Mecit Kaptan": hata += 1; print("HATA paket ", n)
	# kötü veri süzülür
	Duzen.paket_al(Duzen.PAKET_BAS + JSON.stringify({"t": {str(t.id): {"ad": "X", "c1": "zehir", "kisa": "UZUNKISA", "str": 99}}}))
	var e: Dictionary = Duzen.d.t[str(t.id)]
	if e.has("str") or e.has("c1") or str(e.kisa).length() > 4: hata += 1; print("HATA süzülmedi ", e)
	# kulübü sıfırla → özgün
	Duzen.takim_sifirla(t); Duzen.lig_yaz(v4.ligler[0], ""); Duzen.uygula(v4)
	if v4.ligler[0].takimlar[0].ad != oz_ad or v4.ligler[0].takimlar[0].oy[3].n != oz_oy: hata += 1; print("HATA kulüp sıfırlanmadı")
	if yedek != "": var f := FileAccess.open(Duzen.KAYIT, FileAccess.WRITE); f.store_string(yedek)
	else: DirAccess.remove_absolute(Duzen.KAYIT)
	print("DÜZEN DENEMESİ: ", "TAMAM" if hata == 0 else str(hata) + " HATA")
	quit()
