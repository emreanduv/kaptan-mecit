extends SceneTree
# taç atılamadan hakkın rakibe geçmesi (ping-pong): atıştan sonra kimse topa dokunmadan yeniden taç
func _init() -> void:
	var v = JSON.parse_string(FileAccess.open("res://veri/takimlar.json", FileAccess.READ).get_as_text())
	var lig = v.ligler[0].takimlar
	var n := 0; var kotu := 0
	for mac in 12:
		var t0 = Taktik.kadro_kur(lig[mac % lig.size()], "tr"); var t1 = Taktik.kadro_kur(lig[(mac + 3) % lig.size()], "tr")
		var M = Mac.new(t0, t1, 6, 1, false)
		M.T[0].human = mac % 2 == 1
		var aktif = null; var atici = null; var dokundu := true
		for i in 60*60*7:
			M.step(1.0/60.0)
			if M.state == "over": break
			var sp = M.set_piece
			if sp != null and sp.get("tac", false) and sp != aktif:
				if aktif != null and not dokundu: kotu += 1
				aktif = sp; atici = sp.p; dokundu = false; n += 1
			elif aktif != null and M.ball.owner != null and M.ball.owner != atici: dokundu = true
			elif aktif != null and M.set_piece != null and M.set_piece != aktif and not M.set_piece.get("tac", false): dokundu = true
	print("TAÇ n=", n, " dokunulmadan yine taç=", kotu)
	quit()
