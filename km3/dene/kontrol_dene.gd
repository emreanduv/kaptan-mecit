extends SceneTree
# basılı tutma: kısa/uzun şut gücü, kısa pas / ara pas, savunmada anında tepki, geri pasta kaleci ayakla
func _init() -> void:
	var v = JSON.parse_string(FileAccess.open("res://veri/takimlar.json", FileAccess.READ).get_as_text())
	var t0 = Taktik.kadro_kur(v.ligler[0].takimlar[0], "tr"); var t1 = Taktik.kadro_kur(v.ligler[0].takimlar[1], "tr")
	var sonuc := []
	for d in [["sutKisa", "sut", 3], ["sutUzun", "sut", 50], ["pasKisa", "pas", 3], ["araPas", "pas", 30]]:
		var M = Mac.new(t0, t1, 4, 1, false)
		M.T[0].human = true
		for i in 30: M.step(1.0 / 60.0)
		M.state = "play"; M.set_piece = null
		var c = null
		for q in M.P:
			if q.team == 0 and q.role == "O": c = q; break
		M.ctrl = c; c.x = M.PW / 2 if d[1] == "sut" else 14.0; c.y = (22.0 if M.goal_y_of(0) == 0 else M.PL - 22.0) if d[1] == "sut" else M.PL / 2; c.dx = 0; c.dy = M.fwd_of(0); M.ball.owner = c
		for q in M.P:
			if q.team == 1 and q.role != "G": q.x = 1.0; q.stun = 5.0
		M.tus_bas(d[1])
		for i in d[2]:
			M.step(1.0 / 60.0)
		M.tus_birak(d[1]); M.step(1.0 / 60.0)
		var b = M.ball; var f: float = M.fwd_of(0)
		sonuc.append("%s hiz=%.1f ileri=%.1f hedef=%s sahip=%s ctrl_sahip=%s dolum=%.2f" % [d[0], Vector2(b.vx, b.vy).length(), b.vy * f, b.intended.n if b.intended != null else "-", b.owner.n if b.owner != null else "-", b.owner == c, M.dolum[d[1]]])
	var M2 = Mac.new(t0, t1, 4, 1, false)
	M2.T[0].human = true
	for i in 30: M2.step(1.0 / 60.0)
	M2.state = "play"
	for q in M2.P:
		if q.team == 1 and q.role == "O": M2.ball.owner = q; break
	M2.tus_bas("sut")
	sonuc.append("savunmaAnlik=%s" % M2.giris.sutE)
	print("KONTROL ", " | ".join(sonuc))
	quit()
