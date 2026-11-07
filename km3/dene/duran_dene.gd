extends SceneTree
# duran top kuralı: santra ve taçta kullanan vurmadan rakip 9,15 m'ye giremez ve topu alamaz
func _init() -> void:
	var v = JSON.parse_string(FileAccess.open("res://veri/takimlar.json", FileAccess.READ).get_as_text())
	var t0 = Taktik.kadro_kur(v.ligler[0].takimlar[0], "tr"); var t1 = Taktik.kadro_kur(v.ligler[0].takimlar[1], "tr")
	var hata := 0; var ornek := 0
	for deneme in 30:
		var M = Mac.new(t0, t1, 4, 1, false)
		M.T[0].human = true
		if deneme % 2 == 1: M.throw_in(1, 0.0, 40.0)
		for i in 600:
			M.step(1.0 / 60.0)
			if M.duran_top_bekliyor():
				ornek += 1
				for q in M.P:
					if q.team != M.set_piece.p.team and Vector2(q.x - M.ball.x, q.y - M.ball.y).length() < 9.0: hata += 1
			elif M.state == "play" and M.set_piece == null and M.ball.owner != null and i > 30:
				break
	print("DURAN ornek=", ornek, " ihlal=", hata)
	quit()
