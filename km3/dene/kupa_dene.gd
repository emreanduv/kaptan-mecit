extends SceneTree
# kupalar: her kupada katılımcı sayısı, simülasyonla baştan sona; kullanıcı maçı sonucu ve penaltılar
func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var L := Lig.new(veri)
	var hata := 0
	for K in Lig.KUPALAR:
		var t := L.kupa_katilim(K.id)
		if t.size() != int(K.n): hata += 1; print("HATA katılım ", K.id, " ", t.size())
		L.kupa_basla(K.id, t[0])
		var g := 0
		while L.kupa_benim_mac() != null and g < 6:
			if g == 0: print("  ", K.id, " ilk maç sonucu: '", L.kupa_sonuc(1, 1), "'")
			else: L.kupa_sim_mac()
			g += 1
		if not L.kupa.bitti: hata += 1; print("HATA bitmedi ", K.id)
		print(K.ad, ": ", t.size(), " kulüp · ", L.kupa_ozet(), " · tur ", (L.kupa.esle as Array).size())
	L.kip = "kupa"; L.kupa = {}
	print("satırlar: ", L.satirlar(), " · ", L.satir_metni(0, true), " · ", L.satir_metni(1, false))
	L.sil()
	print("KUPA DENEMESİ: ", "TAMAM" if hata == 0 else "HATA %d" % hata)
	quit()
