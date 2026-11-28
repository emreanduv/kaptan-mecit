# Takım morali denemesi (0.10.19): godot --headless --path km3 -s dene/moral_dene.gd
# Moral 5–99 arası; galibiyet serisi morali yükseltir, yenilgi serisi düşürür; kulüp ve rakip raporunda satır var;
# haberlerde moral değişimi yazılır; moral simüle maçta gücü oynatır.
extends SceneTree
func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var L := Lig.new(veri); L.sil(); L.yeni_sezon(0, 0)
	var hata := 0
	if L.moral() != 60: hata += 1; print("başlangıç morali 60 değil: ", L.moral())
	for i in 5: L.kullanici_sonuc(3, 0)
	var yuksek := L.moral()
	print("5 galibiyet (3-0) sonra moral: ", yuksek, " · ", Lig.moral_adi(yuksek), " · etki ", Lig.moral_etki(yuksek))
	if yuksek < 80: hata += 1; print("HATA: galibiyet serisinde moral yükselmedi")
	for i in 5: L.kullanici_sonuc(0, 3)
	var dusuk := L.moral()
	print("5 yenilgi (0-3) sonra moral: ", dusuk, " · ", Lig.moral_adi(dusuk), " · etki ", Lig.moral_etki(dusuk))
	if dusuk > 20: hata += 1; print("HATA: yenilgi serisinde moral düşmedi")
	var mc := L.sonraki_mac()
	var o1 := L.olasiliklar(int(mc[0]), int(mc[1])); var o2 := L.olasiliklar(int(mc[0]), int(mc[1]), true)
	var ev := int(mc[0]) == L.biz()
	var p1: float = o1[0] if ev else o1[2]; var p2: float = o2[0] if ev else o2[2]
	print("kazanma olasılığı moralsiz %.3f · moralli %.3f" % [p1, p2])
	if p2 >= p1: hata += 1; print("HATA: düşük moral olasılığı düşürmedi")
	var var_k := false; var var_r := false
	for x in L.kulup_raporu(): if x[1] == "Takım morali": var_k = true; print("  kulüp raporu: ", x[2])
	for x in L.rakip_raporu(): if x[1] == "Takım morali": var_r = true
	if not var_k or not var_r: hata += 1; print("HATA: raporda moral satırı yok")
	var hb := 0
	for hw in L.haber_haftalari():
		for h in hw[1]:
			if "oral" in str(h[0]): hb += 1; print("  hafta ", hw[0], ": ", h[0])
	if hb < 2: hata += 1; print("HATA: haberlerde moral değişimi yok")
	for i in 60: if not L.bitti(): L.haftayi_simule()
	for w in L.hafta_sayisi() + 1:
		var m := L.moral(w)
		if m < 5 or m > 99: hata += 1
	print("sezon sonu moral: ", L.moral(), " · şampiyon ", L.takim(int(L.d.sampiyon)).ad)
	L.sil()
	print("moral " + ("tamam" if hata == 0 else "HATA"))
	quit(hata)
