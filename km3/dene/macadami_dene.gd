extends SceneTree
# maçın adamı (0.10.14): kullanıcının oynadığı haftalarda haberlerde "Maçın adamı" (en yüksek not; eşitlikte gol+asist),
# simüle haftalarda yok; "Haftanın en farklı skoru" bizim maçımızı tekrar etmez; kayıt d.mo yüklenince aynı; eski kayıt (mo yok) açılır.
func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var hata := 0; var ma_say := 0
	for li in [0, 3, 7]:
		var L := Lig.new(veri); L.sil(); L.yeni_sezon(li, 2)
		var oynanan := {}
		while not L.bitti():
			var w := int(L.d.hafta)
			if w % 2 == 0:
				var gb := w % 5; var gr := (w / 2) % 3
				L.kullanici_sonuc(gb, gr, [], [
					{"n": "Ali Kaya", "not_": 7.4, "a": 0, "g": 1},
					{"n": "Veli Tan", "not_": 7.4, "a": 1, "g": 1},
					{"n": "Can Er", "not_": 6.1, "a": 0, "g": 0}])
				oynanan[w] = 1
			else:
				L.haftayi_simule()
		var b := L.biz()
		for hw in L.haber_haftalari():
			var w: int = int(hw[0]) - 1
			var var_ma := false
			for x in hw[1]:
				var t := str(x[0])
				if t.begins_with("Maçın adamı"):
					var_ma = true; ma_say += 1
					if t != "Maçın adamı: Veli Tan (not 7,4, 1 gol).": hata += 1; print("HATA metin ", t)
				if t.begins_with("Haftanın en farklı skoru") and (t.find(L.takim(b).ad + " ") >= 0 or t.ends_with(" " + L.takim(b).ad + ".")):
					hata += 1; print("HATA en farklı skor bizim maç ", t)
			if var_ma != oynanan.has(w): hata += 1; print("HATA hafta ", w, " oynandı=", oynanan.has(w), " ma=", var_ma)
		# kayıt: yükleyince aynı; EN
		var L2 := Lig.new(veri); L2.yukle()
		if L2.mac_adami(0) != L.mac_adami(0): hata += 1; print("HATA kayıt ", L2.mac_adami(0))
		Dil.en = true
		var en_var := false
		for x in L2.haberler(99):
			if str(x[1]).begins_with("• Player of the match: Veli Tan (rating 7.4, 1 goal)"): en_var = true
			if str(x[1]).find("Maçın") >= 0: hata += 1; print("HATA EN ", x[1])
		Dil.en = false
		if not en_var: hata += 1; print("HATA EN yok")
		# eski kayıt: mo yok
		L2.d.erase("mo")
		for hw in L2.haber_haftalari():
			for x in hw[1]:
				if str(x[0]).begins_with("Maçın adamı"): hata += 1; print("HATA eski kayıt")
		L.sil()
	if ma_say == 0: hata += 1
	print("macadami_dene maçın adamı=", ma_say, " hata=", hata)
	quit(hata)
