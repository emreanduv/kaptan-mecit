extends SceneTree
# sezon seyri: 28 ligde sezon boyunca her hafta sira_gecmisi'nin son haftası tablo() ile birebir aynı sırayı vermeli;
# satırlar boş değil; grafik verisi hafta sayısı kadar; sezon bitince de dolu
func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var hata := 0
	for li in veri.ligler.size():
		var L := Lig.new(veri); L.sil(); L.yeni_sezon(li, li % 7)
		if not L.sezon_seyri().is_empty(): hata += 1; print("HATA ilk hafta dolu ", li)
		while not L.bitti():
			L.haftayi_simule()
			var G := L.sira_gecmisi()
			if G.size() != int(L.d.hafta): hata += 1; print("HATA hafta sayısı ", li)
			var T := L.tablo()
			for k in T.size():
				if int(G[-1].s[int(T[k].i)]) != k + 1: hata += 1; print("HATA sıra ", li, " ", k); break
			var gr := L.seyir_grafik()
			if (gr.biz as Array).size() != G.size(): hata += 1
			if L.sezon_seyri().size() < 9: hata += 1; print("HATA satır ", li)
		if li == 0:
			for x in L.sezon_seyri(): print(x)
		L.sil()
	print("seyir_dene hata=", hata)
	quit(hata)
