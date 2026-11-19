extends SceneTree
# oyuncu karnesi (0.10.10): kullanıcı maçında rapordaki oyuncular maç/asist/not ortalamasına yazılır, kayıtla korunur,
# yeni sezonda sıfırlanır; eski kayıt (oyn yok) açılır. Milli takım kısaltmaları İngilizcede FIFA kodu.
func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var hata := 0
	for li in veri.ligler.size():
		if str(veri.ligler[li].id) == "mt": continue
		var L := Lig.new(veri); L.sil(); L.yeni_sezon(li, li % 5)
		var K := L.kadro_satirlari()
		if K.is_empty() or (K[0] as Array).size() != 9: hata += 1; print("HATA satır ", li); continue
		var a: String = K[0][2]; var b: String = K[1][2]
		var oyn := 0
		while not L.bitti():
			if L.sonraki_mac().is_empty(): L.haftayi_simule(); continue
			oyn += 1
			L.kullanici_sonuc(1, 0, [], [{"n": a, "not_": 7.0, "a": 1}, {"n": b, "not_": 6.0 + (oyn % 2), "a": 0}])
		var ka := L.karne(a); var kb := L.karne(b)
		if ka[0] != oyn or ka[1] != oyn or absf(ka[2] - 7.0) > .01: hata += 1; print("HATA a ", li, " ", ka, " ", oyn)
		if kb[0] != oyn or absf(kb[2] - (6.0 + float(oyn / 2) / oyn)) > .06: hata += 1; print("HATA b ", li, " ", kb, " ", oyn)
		if L.karne_en_iyi().is_empty() or L.karne_en_iyi()[0] != a: hata += 1; print("HATA en iyi ", L.karne_en_iyi())
		L.kaydet(); var L2 := Lig.new(veri); L2.yukle()
		if L2.karne(a) != ka: hata += 1; print("HATA kayıt ", L2.karne(a), ka)
		L2.d.erase("oyn"); L2.kaydet(); var L3 := Lig.new(veri); L3.yukle()
		if not L3.var_mi() or L3.karne(a)[0] != 0: hata += 1; print("HATA eski kayıt")
		L2.sonraki_sezon()
		if L2.karne(a)[0] != 0: hata += 1; print("HATA yeni sezon")
		L2.sil()
	Dil.ayarla(true, false)
	if Dil.kisa("FAS") != "MAR" or Dil.kisa("İSK", "tr") != "İSK" or Dil.kisa("XYZ") != "XYZ": hata += 1; print("HATA kısa EN")
	Dil.ayarla(false, false)
	if Dil.kisa("FAS") != "FAS": hata += 1; print("HATA kısa TR")
	print("karne_dene hata=", hata)
	quit(hata)
