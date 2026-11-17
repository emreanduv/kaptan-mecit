extends SceneTree
# Kupa gol krallığı (0.10.7): her kupada atılan gollerin toplamı = maç skorlarının toplamı (penaltı atışları hariç),
# kullanıcının maçında motorun golcüleri yazılır, kayıt/yüklemede korunur, sıralama ve özet satırı
func _toplam_skor(L: Lig) -> int:
	var t := 0
	for gun in L.kupa.get("gm", []):
		for m in gun:
			if (m.s as Array).size() >= 2: t += int(m.s[0]) + int(m.s[1])
	for tur in L.kupa.esle:
		for m in tur:
			if (m.s as Array).size() >= 2: t += int(m.s[0]) + int(m.s[1])
	return t

func _toplam_gol(L: Lig) -> int:
	var t := 0
	for k in L.kupa.get("goller", {}): t += int(L.kupa.goller[k])
	return t

func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var L := Lig.new(veri)
	var hata := 0; var kupa_say := 0
	for K in Lig.KUPALAR:
		var KK: Array = L.kupa_katilim(K.id)
		for i in [0, KK.size() / 2, KK.size() - 1]:
			L.kupa_basla(K.id, KK[i])
			var n := 0; var ilk := true
			while L.kupa_benim_mac() != null and n < 12:
				if ilk:
					var m = L.kupa_benim_mac()
					var ben_ad: String = L._kupa_golculer(L.kupa.ben)[0][0]
					L.kupa_sonuc(2, 1, [{"n": ben_ad, "team": 0}, {"n": ben_ad, "team": 0}, {"n": "Kendi kalesine (X)", "team": 1}])
					var k := str(L.kupa.ben[0]) + "|" + str(L.kupa.ben[1]) + "|" + ben_ad
					if int(L.kupa.goller.get(k, 0)) < 2: hata += 1; print("HATA kullanıcının golcüsü yazılmadı ", K.id)
					L.kupa_kaydet(); L.kupa_yukle()
					if int(L.kupa.get("goller", {}).get(k, 0)) < 2: hata += 1; print("HATA kayıtta goller yok ", K.id)
					ilk = false
				else: L.kupa_sim_mac()
				n += 1
			if not (L.kupa.bitti or L.kupa.elendi): hata += 1; print("HATA kupa sürüyor ", K.id)
			while not L.kupa.bitti and L.kupa.elendi and n < 40: L.kupa_ilerle(); n += 1
			var fark := _toplam_skor(L) - _toplam_gol(L)
			if fark != 1: hata += 1; print("HATA ", K.id, " skor-gol farkı ", fark, " (beklenen 1: kendi kalesine)")
			var GK := L.kupa_gol_krallari(10)
			if GK.is_empty(): hata += 1; print("HATA gol krallığı boş ", K.id)
			for j in range(1, GK.size()):
				if GK[j][4] > GK[j - 1][4]: hata += 1; print("HATA sıralama ", K.id)
			if L.kupa.bitti and L.kupa_ozet().find("Gol kralı: ") < 0: hata += 1; print("HATA özette gol kralı yok ", K.id)
			kupa_say += 1
		print(K.id, ": ", L.kupa_ozet().replace("\n", " | "))
	L.kupa = {}; L.kupa_kaydet()
	print(kupa_say, " kupa oynandı")
	print("KUPA GOL DENEMESİ: ", "TAMAM" if hata == 0 else "HATA %d" % hata)
	quit()
