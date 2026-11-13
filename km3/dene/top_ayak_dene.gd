extends SceneTree
# dripling: oyuncu ileri koşarken geri döner; top tek karede ne kadar sıçrıyor, oyuncudan ne kadar uzaklaşıyor
func _init() -> void:
	var v = JSON.parse_string(FileAccess.open("res://veri/takimlar.json", FileAccess.READ).get_as_text())
	var t0 = Taktik.kadro_kur(v.ligler[0].takimlar[0], "tr"); var t1 = Taktik.kadro_kur(v.ligler[0].takimlar[1], "tr")
	var M = Mac.new(t0, t1, 4, 1, false)
	M.T[0].human = true
	for i in 30: M.step(1.0 / 60.0)
	M.state = "play"; M.set_piece = null
	var c = null
	for q in M.P:
		if q.team == 0 and q.role == "O": c = q; break
	for q in M.P:
		if q.team == 1: q.x = 1.0; q.y = 1.0; q.stun = 50.0
	M.ctrl = c; c.x = M.PW / 2; c.y = M.PL / 2; M.ball.owner = c
	var maxs := 0.0; var maxd := 0.0; var bx: float = M.ball.x; var by: float = M.ball.y
	var donus := -1.0; var t := 0.0
	for i in 240:
		var f: float = M.fwd_of(0)
		M.giris.x = 0.0; M.giris.y = f if i < 90 else -f
		M.step(1.0 / 60.0); t += 1.0 / 60.0
		if M.ball.owner != c: print("TOP KAYBI ", i); break
		var s := Vector2(M.ball.x - bx, M.ball.y - by).length() - Vector2(c.vx, c.vy).length() / 60.0
		maxs = maxf(maxs, s); bx = M.ball.x; by = M.ball.y
		maxd = maxf(maxd, Vector2(M.ball.x - c.x, M.ball.y - c.y).length())
		if i >= 90 and donus < 0 and c.dy * -f > .9: donus = (i - 90) / 60.0
	print("TOPAYAK kare_sicrama=%.2f m  en_uzak=%.2f m  donus_sn=%.2f" % [maxs, maxd, donus])
	quit()
