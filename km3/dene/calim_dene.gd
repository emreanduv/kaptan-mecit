extends SceneTree
# Çalım: topla rakibe giden oyuncu sert yön değiştirince çalım başlar; çalım varken top daha zor kaptırılır.
func _init() -> void:
	var v = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var t0 = Taktik.kadro_kur(v.ligler[0].takimlar[0], "tr"); var t1 = Taktik.kadro_kur(v.ligler[0].takimlar[1], "tr")
	var basla := 0; var kayip_calim := 0; var kayip_duz := 0
	for deneme in 2:
		for tekrar in 60:
			var M = Mac.new(t0, t1, 4, 1, false)
			M.T[0].human = true
			for i in 30: M.step(1.0 / 60.0)
			M.state = "play"; M.set_piece = null
			var c = null; var r = null
			for q in M.P:
				if q.team == 0 and q.role == "O" and c == null: c = q
				if q.team == 1 and q.role == "D" and r == null: r = q
			for q in M.P:
				if q != c and q != r: q.x = 1.0; q.y = 1.0; q.stun = 50.0
			var f: float = M.fwd_of(0)
			M.ctrl = c; c.x = M.PW / 2; c.y = M.PL / 2; c.dx = 0; c.dy = f; M.ball.owner = c; c.hold = 1.0
			r.x = c.x; r.y = c.y + f * 2.2; r.stun = 0
			var kayip := false
			for i in 90:
				M.giris.x = (1.0 if deneme == 0 and i >= 10 else 0.0); M.giris.y = f if i < 10 or deneme == 1 else 0.0
				M.step(1.0 / 60.0)
				if c.calim > 0 and i < 20: basla += 1 if c.calim > .38 else 0
				if M.ball.owner != c: kayip = true; break
			if deneme == 0 and kayip: kayip_calim += 1
			if deneme == 1 and kayip: kayip_duz += 1
	print("CALIM basladi=%d/60  top_kaybi: calimla=%d/60 duz=%d/60" % [basla, kayip_calim, kayip_duz])
	quit()
