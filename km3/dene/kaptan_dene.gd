extends SceneTree
# kaptan (0.10.18): asistan ilk 11'den kaptan + yardımcı seçer; "Kaptan" satırı yalnız Kadro görünümünde; ‹ › ilk 11'de gezer,
# yeni kaptan yardımcıysa eski kaptan yardımcı olur; kayıtta d.kap aynı; haberlerde sezon başı ve değişiklik (gezinip geri dönünce haber yok);
# yeni sezonda bant kalır; kadro satırında (K)/(Y), EN (C)/(VC); eski kayıt (kap yok) açılır; Verilerimi sil/ligi bırak siler.
func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var hata := 0
	for li in [0, 3, 7]:
		var L := Lig.new(veri); L.sil(); L.yeni_sezon(li, 1)
		var I: Array = L.kadro_satirlari().filter(func(x): return x[5]).map(func(x): return str(x[2]))
		var k := L.kaptan()
		if k.size() != 2 or not I.has(k[0]) or not I.has(k[1]) or k[0] == k[1]: hata += 1; print("HATA ilk seçim ", k)
		if L.satirlar().has("Kaptan"): hata += 1; print("HATA tablo görünümünde Kaptan satırı")
		L.gorunum = "kadro"
		var S := L.satirlar()
		var ki := S.find("Kaptan")
		if ki != S.find("Kadro") + 1: hata += 1; print("HATA satır yeri ", S)
		if L.satir_metni(ki, true) != "‹  Kaptan:  %s  ›" % k[0]: hata += 1; print("HATA satır metni ", L.satir_metni(ki, true))
		# yardımcıya ver: eski kaptan yardımcı olur
		var hedef: String = k[1]
		var adim := 0
		while L.kaptan()[0] != hedef and adim < 12: L.kay(ki, 1); adim += 1
		var k2 := L.kaptan()
		if k2[0] != hedef: hata += 1; print("HATA gezinti ", k2)
		# gezinirken yardımcıya rastlanmadan önce başka kaptanlar da geçti: yardımcı ya eski kaptan ya da baştaki yardımcı değil
		if k2[1] == k2[0] or not I.has(k2[1]): hata += 1; print("HATA yardımcı ", k2)
		if adim == 1 and k2[1] != k[0]: hata += 1; print("HATA yardımcı↔kaptan ", k2)
		# kayıt
		var L2 := Lig.new(veri)
		if L2.kaptan() != k2: hata += 1; print("HATA kayıt ", L2.kaptan(), k2)
		# haftalar: 3. haftadan sonra bant değişir; geri-ileri gezinme haber yazmaz
		for i in 3: L2.haftayi_simule()
		L2.gorunum = "kadro"
		var ki2 := L2.satirlar().find("Kaptan")
		L2.kay(ki2, 1); L2.kay(ki2, -1)
		var g_once: int = (L2.d.get("kapg", []) as Array).size()
		L2.kay(ki2, 1)
		var yeni: String = L2.kaptan()[0]
		for i in 2: L2.haftayi_simule()
		var bas := 0; var deg := 0
		for hw in L2.haber_haftalari():
			for x in hw[1]:
				var t := str(x[0])
				if t.begins_with("Sezonun kaptanı"):
					bas += 1
					if int(hw[0]) != 1: hata += 1; print("HATA sezon başı haftası ", hw[0])
				if t.begins_with("Kaptanlık bandı değişti"):
					deg += 1
					if int(hw[0]) != 3 or not t.ends_with(yeni + "."): hata += 1; print("HATA değişiklik ", hw[0], " ", t)
		if bas != 1 or deg != 1: hata += 1; print("HATA haber sayısı bas=", bas, " deg=", deg, " kapg=", L2.d.get("kapg"), " önce=", g_once)
		# kadro işareti
		if L2.kaptan_isareti(yeni) != "  (K)" or L2.kaptan_isareti(L2.kaptan()[1]) != "  (Y)" or L2.kaptan_isareti("Yok Böyle") != "": hata += 1; print("HATA işaret")
		Dil.en = true
		if L2.kaptan_isareti(yeni) != "  (C)" or not L2.kaptan_metni().begins_with("Captain: "): hata += 1; print("HATA EN ", L2.kaptan_metni())
		if Dil.cevir("Kaptan Mecit") != "Kaptan Mecit": hata += 1; print("HATA oyunun adı çevrildi")
		Dil.en = false
		# yeni sezonda bant kalır, sezon başı haberi yeni kaptanla
		while not L2.bitti(): L2.haftayi_simule()
		L2.sonraki_sezon()
		if L2.kaptan()[0] != yeni: hata += 1; print("HATA yeni sezon kaptan ", L2.kaptan())
		L2.haftayi_simule()
		var hb := ""
		for x in L2.haber_haftalari()[0][1]:
			if str(x[0]).begins_with("Sezonun kaptanı"): hb = str(x[0])
		if hb != "Sezonun kaptanı: %s." % yeni: hata += 1; print("HATA yeni sezon haberi ", hb)
		# eski kayıt: kap yok → asistan seçer
		L2.d.erase("kap"); L2.d.erase("kapg")
		if L2.kaptan().size() != 2: hata += 1; print("HATA eski kayıt")
		for hw in L2.haber_haftalari():
			for x in hw[1]:
				if str(x[0]).begins_with("Kaptanlık bandı değişti"): hata += 1; print("HATA eski kayıtta değişti haberi")
		# silme
		L2.sil()
		var L3 := Lig.new(veri)
		if L3.var_mi() or not L3.kaptan().is_empty(): hata += 1; print("HATA silme")
	print("kaptan_dene hata=", hata)
	quit(hata)
