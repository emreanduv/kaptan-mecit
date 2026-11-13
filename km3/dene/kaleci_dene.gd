extends SceneTree
# kaleci atlayışı: şutların kaçında kaleci top gelmeden atlamaya başlamış ve top geldiğinde uçuş ne kadar ilerlemiş
func _init() -> void:
	var v = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var t0 = Taktik.kadro_kur(v.ligler[0].takimlar[0], "tr"); var t1 = Taktik.kadro_kur(v.ligler[0].takimlar[1], "tr")
	var say := 0; var erken := 0; var e_top := 0.0; var gol := 0
	for m in 4:
		var M = Mac.new(t0, t1, 4, 1, false)
		M.T[0].human = false
		var onceki := {}
		for i in 60 * 60 * 8:
			for g in M.P:
				if g.role == "G": onceki[g] = g.ucus
			var tried = M.ball.gk_tried
			M.step(1.0 / 60.0)
			if M.ball.gk_tried != tried and M.ball.gk_tried != null:
				var g = M.ball.gk_tried
				if g.ucus > 0:
					say += 1
					var e: float = 1.5 - g.ucus if g.ucus_tur == 1 else .7 - g.ucus
					if float(onceki.get(g, 0.0)) > 0: erken += 1; e_top += e
			if M.state == "over": break
		gol += M.T[0].score + M.T[1].score
	print("KALECI temas=", say, " erken_atlayis=", erken, " ort_ucus_ilerleme_sn=", snappedf(e_top / maxf(1, erken), .01), " gol=", gol)
	quit()
