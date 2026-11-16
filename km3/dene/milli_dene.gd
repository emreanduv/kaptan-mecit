extends SceneTree
# Milletler Kupası: 32 milli takım, 8 grup kura (torbalar), 3 maç günü, Son 16 (1A-2B…), kayıt/yükleme, elenme ve şampiyonluk yolları
func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var L := Lig.new(veri)
	var hata := 0
	var K: Array = L.kupa_katilim("mil")
	if K.size() != 32: hata += 1; print("HATA katılım ", K.size())
	var sam := 0; var cikti := 0
	for i in K.size():
		L.kupa_basla("mil", K[i])
		# kura: 8 grup × 4, her takım bir kez, her grupta her torbadan bir takım
		var gor := {}
		for g in L.kupa.gruplar:
			if (g as Array).size() != 4: hata += 1
			for x in g: gor[str(x[1])] = true
		if gor.size() != 32: hata += 1; print("HATA kura ", gor.size())
		var kip := i % 3     # 0: hep kazan, 1: hep kaybet, 2: simüle
		var n := 0
		while L.kupa_benim_mac() != null and n < 12:
			if kip == 0: L.kupa_sonuc(3, 0)
			elif kip == 1: L.kupa_sonuc(0, 2)
			else: L.kupa_sim_mac()
			n += 1
			if n == 2:
				L.kupa_yukle()   # ara kayıttan dönüş
				if not L.kupa.has("gruplar"): hata += 1; print("HATA kayıt")
		if not L.kupa.bitti: hata += 1; print("HATA bitmedi ", i)
		for g in 8:
			for r in L.grup_tablosu(g):
				if int(r.O) != 3: hata += 1; print("HATA grup maç sayısı ", g)
		var ilk: Array = L.kupa.esle[0]
		if ilk.size() != 8: hata += 1
		var T0 := L.grup_tablosu(0); var T1 := L.grup_tablosu(1)
		if not (Lig._ayni(ilk[0].a, T0[0].t) and Lig._ayni(ilk[0].b, T1[1].t) and Lig._ayni(ilk[4].a, T1[0].t) and Lig._ayni(ilk[4].b, T0[1].t)): hata += 1; print("HATA son 16 eşleşme")
		if kip == 0 and not L.kupa_kazandi(): hata += 1; print("HATA hep kazanan şampiyon olmadı")
		if kip == 1 and not L.kupa.elendi: hata += 1; print("HATA hep kaybeden elenmedi")
		if kip == 1 and n != 3: hata += 1; print("HATA hep kaybeden ", n, " maç oynadı")
		if L.kupa_kazandi(): sam += 1
		if not L.kupa.elendi or (L.kupa.esle as Array).size() > 0 and kip == 0: cikti += 1
	L.kupa_basla("mil", K[21])
	print("grup başı özet: ", L.kupa_ozet(), " · ", L.kupa_tur_adi(0))
	print("satır: ", L.kupa_satir_metni("MAÇA ÇIK", true))
	print("bizim maçlar: ", L.grup_maclarim())
	L.kupa_sim_mac(); print("1. gün sonra: ", L.kupa_ozet(), " · gün ", L.kupa.gtur)
	L.kupa = {}; L.kupa_kaydet()
	print("şampiyonluk ", sam, "/32")
	print("MİLLİ DENEMESİ: ", "TAMAM" if hata == 0 else "HATA %d" % hata)
	quit()
