extends SceneTree
# xG ayarı: yapay zekâ maçlarında toplam xG ile gol karşılaştırılır (XG_K buna göre seçilir)
func _init() -> void:
	var v = JSON.parse_string(FileAccess.open("res://veri/takimlar.json", FileAccess.READ).get_as_text())
	var xg := 0.0; var gol := 0; var sut := 0
	for m in 10:
		var L: Array = v.ligler[m % v.ligler.size()].takimlar
		var t0 = Taktik.kadro_kur(L[m % L.size()], "tr"); var t1 = Taktik.kadro_kur(L[(m + 3) % L.size()], "tr")
		var M = Mac.new(t0, t1, 4, 1, false)
		M.T[0].human = false
		for i in 60 * 60 * 8:
			M.step(1.0 / 60.0)
			if M.state == "over": break
		xg += M.ist.xg[0] + M.ist.xg[1]; gol += int(M.T[0].score) + int(M.T[1].score); sut += M.ist.sut[0] + M.ist.sut[1]
	print("XG10 xg=", snappedf(xg, .01), " gol=", gol, " sut=", sut)
	quit()
