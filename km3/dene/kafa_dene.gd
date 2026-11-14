extends SceneTree
# Kafa vuruşu: yüksek ortalar kafayla karşılanıyor mu, kaç kafa golü, maç başına gol değişmedi mi
func _init() -> void:
	var v = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var kafa := 0; var kgol := 0; var gol := 0; var orta := 0
	for m in 6:
		var t0 = Taktik.kadro_kur(v.ligler[0].takimlar[m], "tr"); var t1 = Taktik.kadro_kur(v.ligler[0].takimlar[m + 6], "tr")
		var M = Mac.new(t0, t1, 4, 1, true)
		var onceki := {}; var son_kafa := -10.0; var son_cross := false
		while M.state != "over":
			M.step(1.0 / 60.0)
			if M.ball.cross and not son_cross: orta += 1
			son_cross = M.ball.cross
			for p in M.P:
				if p.kafa > .49 and not onceki.get(p, false): kafa += 1; son_kafa = M.clock
				onceki[p] = p.kafa > 0
			for o in M.olaylar if "olaylar" in M else []: pass
		gol += M.T[0].score + M.T[1].score
	print("KAFA orta=%d kafa=%d gol=%d (6 maç)" % [orta, kafa, gol])
	quit()
