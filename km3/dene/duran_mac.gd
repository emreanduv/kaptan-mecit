extends SceneTree
func _init() -> void:
	var v = JSON.parse_string(FileAccess.open("res://veri/takimlar.json", FileAccess.READ).get_as_text())
	var t0 = Taktik.kadro_kur(v.ligler[0].takimlar[0], "tr"); var t1 = Taktik.kadro_kur(v.ligler[0].takimlar[1], "tr")
	for k in 3:
		var M = Mac.new(t0, t1, 4, 1, false)
		var uzun := 0.0; var en := 0.0; var n := 0
		while M.state != "over" and n < 60 * 600:
			M.step(1.0 / 60.0); n += 1
			if M.duran_top_bekliyor(): uzun += 1.0 / 60.0; en = maxf(en, M.set_piece.t)
			else: uzun = 0
		print("MAC ", M.T[0].score, "-", M.T[1].score, " durum=", M.state, " en uzun bekleme=", snappedf(en, .1), " sn")
	quit()
