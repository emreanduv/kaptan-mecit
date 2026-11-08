extends SceneTree
# kurallar: serbest vuruşta baraj 9,15 m'de; taçtan doğrudan gol olmaz; taçta ofsayt yok
func _init() -> void:
	var v = JSON.parse_string(FileAccess.open("res://veri/takimlar.json", FileAccess.READ).get_as_text())
	var t0 = Taktik.kadro_kur(v.ligler[0].takimlar[0], "tr"); var t1 = Taktik.kadro_kur(v.ligler[0].takimlar[1], "tr")
	var baraj := 0; var bkisi := 0; var bihlal := 0
	for k in 12:
		var M = Mac.new(t0, t1, 4, 1, false)
		for i in 60: M.step(1.0 / 60.0)
		var gy: float = M.goal_y_of(0)
		var y: float = 20.0 + k if gy == 0 else M.PL - 20.0 - k
		M.restart(0, M.PW / 2 + (k % 5 - 2) * 3, y); M.set_piece.fk = true; M.baraj(0)
		if M.set_piece.has("baraj"):
			baraj += 1; bkisi += M.set_piece.baraj.size()
		for i in 120:
			M.step(1.0 / 60.0)
			if M.set_piece != null and M.set_piece.has("baraj") and M.duran_top_bekliyor():
				for e in M.set_piece.baraj:
					if Vector2(e[0].x - M.ball.x, e[0].y - M.ball.y).length() < 9.1: bihlal += 1
	# taçtan doğrudan kaleye: gol sayılmamalı
	var M2 = Mac.new(t0, t1, 4, 1, false)
	for i in 30: M2.step(1.0 / 60.0)
	M2.state = "play"
	var p = M2.P[5]; var gy2: float = M2.goal_y_of(p.team)
	M2.set_piece = {"p": p, "t": 0.0, "tac": true}; M2.ball.owner = p
	p.x = M2.PW / 2; p.y = gy2 + (3.0 if gy2 == 0 else -3.0); p.dx = 0; p.dy = -1.0 if gy2 == 0 else 1.0
	M2.release(p, 0, 15 * p.dy, .3)
	var skor0: int = M2.T[0].score + M2.T[1].score
	for i in 60: M2.step(1.0 / 60.0)
	var skor1: int = M2.T[0].score + M2.T[1].score
	print("KURAL baraj=", baraj, " kisi=", bkisi, " ihlal=", bihlal, " tac_gol=", skor1 - skor0, " sonra=", M2.state, " aut=", M2.set_piece != null and M2.set_piece.get("aut", false), " korner=", M2.korner)
	quit()
