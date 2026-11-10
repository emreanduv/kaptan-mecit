extends SceneTree
# taçı kullanacak oyuncu koşarak gelir; yerine vardığında kayıp topu çizginin dışında tutmamalı, atış sahaya girmeli
func _init() -> void:
	var v = JSON.parse_string(FileAccess.open("res://veri/takimlar.json", FileAccess.READ).get_as_text())
	var t0 = Taktik.kadro_kur(v.ligler[0].takimlar[0], "tr"); var t1 = Taktik.kadro_kur(v.ligler[0].takimlar[1], "tr")
	var n := 0; var kotu := 0; var disari := 0.0
	for kenar in [0.0, 1.0]:
		for yy in [8.0, 20.0, 35.0, 52.0, 70.0, 85.0, 97.0]:
			for ti in 2:
				for insan in [false, true]:
					var M = Mac.new(t0, t1, 4, 1, false)
					M.T[0].human = insan
					for i in 30: M.step(1.0/60.0)
					var x: float = 0.0 if kenar == 0.0 else M.PW
					M.throw_in(ti, x, yy)
					var sp0 = M.set_piece; var atici = sp0.p
					var atildi := false; var t := 0.0
					for i in 900:
						M.step(1.0/60.0)
						if M.set_piece == sp0 and M.state == "play": disari = maxf(disari, absf(M.ball.x - clampf(M.ball.x, 0, M.PW)))
						if not atildi and M.set_piece != sp0 and M.state == "play": atildi = true; n += 1
						elif atildi:
							t += 1.0/60.0
							if M.ball.owner != null and M.ball.owner != atici: break
							if M.state != "play":
								if M.set_piece != null and M.set_piece.get("tac", false): kotu += 1
								break
	print("TAÇ n=", n, " dokunulmadan yine taç=", kotu, " top en çok çizgi dışında=", snappedf(disari, .01), " m")
	quit()
