extends SceneTree
func _init():
	var veri = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var lig = veri.ligler[0]
	var t0 := Time.get_ticks_msec()
	var a := Taktik.kadro_kur(lig.takimlar[0], lig.id, "")
	print("otomatik: ", a.dzAd, " (", Time.get_ticks_msec() - t0, " ms)  hazır veri: ", lig.takimlar[0].dzAd)
	for o in a.oy: print("  ", o.no, " ", o.n, " ", o.rol, " ", o.yer, " fx=", o.fx, " fy=", o.fy)
	t0 = Time.get_ticks_msec()
	var b := Taktik.kadro_kur(lig.takimlar[0], lig.id, "3-5-2")
	print("3-5-2 (", Time.get_ticks_msec() - t0, " ms): ", b.oy.map(func(o): return o.yer + ":" + o.n))
	print("yedek: ", b.yedek.map(func(o): return o.mevki + ":" + o.n))
	quit()
