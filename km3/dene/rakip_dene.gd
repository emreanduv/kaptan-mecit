extends SceneTree
# rakip raporu: 28 ligde sezon boyunca her hafta rapor kurulur; olasılıklar toplamı 1, sezon sonunda boş
func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var hata := 0
	for li in veri.ligler.size():
		var L := Lig.new(veri); L.sil(); L.yeni_sezon(li, li % 5)
		var w := 0
		while not L.bitti():
			var R := L.rakip_raporu()
			if R.size() != 16: hata += 1; print("HATA boyut ", li, " ", R.size())
			var mc := L.sonraki_mac()
			var ol := L.olasiliklar(int(mc[0]), int(mc[1]))
			if absf(ol[0] + ol[1] + ol[2] - 1.0) > .01: hata += 1; print("HATA olasılık ", ol)
			if li == 0 and w == 20:
				for x in R: print(x)
			L.haftayi_simule(); w += 1
		if not L.rakip_raporu().is_empty(): hata += 1
		L.sil()
	print("rakip_dene hata=", hata)
	quit(hata)
