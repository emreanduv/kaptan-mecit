extends SceneTree
# haberler (0.10.12): bütün liglerde sezon boyunca her hafta haber_haftalari() oynanan hafta sayısı kadar,
# her haftada bizim maçımızın haberi var (ilk haber, bizi ilgilendiriyor); sezon sonunda "Sezon bitti" haberi;
# haberler() en yeni hafta en üstte, en çok n hafta; ilk hafta oynanmadan boş; EN metinlerde Türkçe kalıp yok.
func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var hata := 0; var tur := {}
	for li in veri.ligler.size():
		if str(veri.ligler[li].id) == "mt": continue
		var L := Lig.new(veri); L.sil(); L.yeni_sezon(li, li % 7)
		if not L.haberler().is_empty(): hata += 1; print("HATA ilk hafta dolu ", li)
		while not L.bitti():
			L.haftayi_simule()
			var W := L.haber_haftalari()
			if W.size() != int(L.d.hafta): hata += 1; print("HATA hafta ", li)
			var son: Array = W[-1][1]
			if son.is_empty() or not son[0][1] or str(son[0][0]).find(L.takim(L.biz()).ad) < 0: hata += 1; print("HATA bizim maç ", li, " ", son)
			var H := L.haberler(4)
			if H[0][1] != "%d. HAFTA" % int(L.d.hafta): hata += 1; print("HATA başlık ", H[0])
			var bas := H.filter(func(x): return x[0] == "b").size()
			if bas != mini(4, int(L.d.hafta)): hata += 1; print("HATA hafta sınırı ", bas)
			for x in son: tur[str(x[0]).get_slice(":", 0).get_slice(" ", 0)] = 1
		var son: Array = L.haber_haftalari()[-1][1]
		if not son.any(func(x): return str(x[0]).begins_with("Sezon bitti")): hata += 1; print("HATA sezon sonu ", li)
		Dil.en = true
		for x in L.haberler(99):
			for k in ["galibiyet", "beraberlik", "yenilgi", "HAFTA", "Zirve", "Sürpriz", "sıra", "Sezon bitti"]:
				if Dil.cevir(str(x[1])).find(k) >= 0 and not str(x[1]).begins_with("• " + L.baskan()[0]): hata += 1; print("HATA EN ", Dil.cevir(x[1])); break
		if li == 0:
			for x in L.haberler(3): print(Dil.cevir(x[1]))
		Dil.en = false
		if li == 0:
			for x in L.haberler(3): print(x[1])
		L.sil()
	print("haber_dene hata=", hata)
	quit(hata)
