extends SceneTree
func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var hata := 0
	for li in veri.ligler.size():
		var L := Lig.new(veri); L.sil(); L.yeni_sezon(li, li % 5)
		if not L.istatistik().is_empty(): hata += 1
		for w in 3: L.haftayi_simule()
		var R := L.istatistik()
		if R.size() != 19: hata += 1; print("HATA boyut ", R.size())
		while not L.bitti(): L.haftayi_simule()
		R = L.istatistik()
		# iç saha + deplasman = toplam
		var t: Dictionary = L.tablo().filter(func(x): return int(x.i) == L.biz())[0]
		if li == 0:
			for x in R: print(x)
		var ev: String = R[13][2]; var dp: String = R[14][2]
		var pe := int(ev.split("·")[1]); var pd := int(dp.split("·")[1])
		if pe + pd != int(t.P): hata += 1; print("HATA puan ", pe, "+", pd, "!=", t.P)
		L.sil()
	print("ist_dene hata=", hata)
	quit(hata)
