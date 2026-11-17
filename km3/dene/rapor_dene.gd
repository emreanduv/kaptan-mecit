# Kulüp raporu denemesi: godot --headless --path km3 -s dene/rapor_dene.gd
extends SceneTree
func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var L := Lig.new(veri); L.sil(); L.yeni_sezon(0, 0)
	for i in 10: L.haftayi_simule()
	var R := L.kulup_raporu()
	var hata := 0
	if R.size() < 10: hata += 1
	for x in R: print("  ", x[0], " | ", x[1], " | ", x[2])
	L.sil()
	print("kulüp raporu " + ("tamam" if hata == 0 else "HATA"))
	quit(hata)
