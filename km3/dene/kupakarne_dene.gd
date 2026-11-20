extends SceneTree
# kupa karnesi (0.10.11): kullanıcının kupa maçlarında rapordaki oyuncular kupa.oyn'a yazılır (maç, asist, not);
# gol kupa gol krallığından gelir; kayıtla korunur; kupa silinince gider; kupanın oyuncusu özete yazılır.
func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var hata := 0
	for id in ["avr", "mil"]:
		var L := Lig.new(veri); L.kupa = {}
		var ben: Array = L.kupa_katilim(id)[0]
		L.kupa_basla(id, ben)
		var t := Taktik.kadro_kur(L.kupa_takim(ben), str(ben[0]))
		var a: String = t.oy[10].n; var b: String = t.oy[9].n
		var oyn := 0
		while L.kupa_benim_mac() != null and oyn < 10:
			oyn += 1
			L.kupa_sonuc(3, 0, [{"team": 0, "n": a}], [{"n": a, "not_": 8.0, "a": 0}, {"n": b, "not_": 6.0, "a": 1}])
		var K := L.kupa_karne()
		if K.is_empty() or K[0][0] != a or K[0][1] != oyn or K[0][2] != oyn or absf(K[0][4] - 8.0) > .01: hata += 1; print("HATA a ", id, " ", K, " ", oyn)
		if K.size() < 2 or K[1][0] != b or K[1][3] != oyn: hata += 1; print("HATA b ", id, " ", K)
		if L.kupa_karne_en_iyi().is_empty() or L.kupa_karne_en_iyi()[0] != a: hata += 1; print("HATA en iyi")
		if not L.kupa.bitti: hata += 1; print("HATA kupa bitmedi ", id)
		if L.kupa_ozet().find("Kupanın oyuncusu: " + a) < 0: hata += 1; print("HATA özet ", L.kupa_ozet())
		L.kupa_kaydet(); var L2 := Lig.new(veri); L2.kupa_yukle()
		if L2.kupa_karne() != K: hata += 1; print("HATA kayıt")
		L2.kupa.erase("oyn")
		if not L2.kupa_karne().is_empty() or not L2.kupa_karne_en_iyi().is_empty(): hata += 1; print("HATA eski kayıt")
		L2.kupa_ozet()
		print(id, " maç=", oyn, " ", K.slice(0, 2))
	var L3 := Lig.new(veri); L3.sil(); L3.kupa_yukle()
	if L3.kupa_var() and L3.kupa.has("oyn"): hata += 1; print("HATA sil")
	print("kupakarne_dene hata=", hata)
	quit(hata)
