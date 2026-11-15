extends SceneTree
# Çizim ara değeri (ana.gd _gorunen): telefon gibi düzensiz kare sürelerinde (45–75 fps) ekrandaki oyuncu hızının
# kareden kareye ortalama sıçraması. Ara değersiz ~1,8 m/s titreme, ara değerli ~0,2 m/s olmalı.
func _init() -> void:
	var v = JSON.parse_string(FileAccess.open("res://veri/takimlar.json", FileAccess.READ).get_as_text())
	var sonuc := []
	for ara in [false, true]:
		seed(7)
		var M = Mac.new(Taktik.kadro_kur(v.ligler[0].takimlar[0], "tr"), Taktik.kadro_kur(v.ligler[0].takimlar[1], "tr"), 4, 1, false)
		for i in 120: M.step(1.0 / 60.0)
		var bir := 0.0; var onceki := []; var o := []; var hs := []; var top := 0.0; var n := 0
		for k in 1500:
			var dt := randf_range(1.0 / 75.0, 1.0 / 45.0)
			bir = minf(bir + dt, 2.0 / 60.0); var a := 0
			while bir >= 1.0 / 60.0 and a < 2:
				bir -= 1.0 / 60.0; a += 1
				onceki = []
				for p in M.P: onceki.append(Vector2(p.x, p.y))
				M.step(1.0 / 60.0)
			var al := clampf(bir * 60.0, 0, 1)
			var c := []
			for i in M.P.size():
				var su := Vector2(M.P[i].x, M.P[i].y)
				c.append(onceki[i].lerp(su, al) if ara and onceki.size() and onceki[i].distance_to(su) < 2 else su)
			if o.size():
				var yeni := []
				for i in M.P.size():
					var h1: float = (c[i] - o[i]).length() / dt
					yeni.append(h1)
					if hs.size() and hs[i] > 1 and hs[i] < 12 and h1 < 12: top += absf(h1 - hs[i]); n += 1
				hs = yeni
			o = c
		sonuc.append(top / maxf(n, 1))
		print("ara=%s ekran hizi ortalama sicrama=%.2f m/s" % [ara, top / maxf(n, 1)])
	print("SONUC: ", "GECTI" if sonuc[1] < sonuc[0] * .3 else "KALDI")
	quit()
