extends SceneTree
# maç raporu: tam bir maç oynatılır, rapor metni basılır
func _init() -> void:
	var v = JSON.parse_string(FileAccess.open("res://veri/takimlar.json", FileAccess.READ).get_as_text())
	var t0 = Taktik.kadro_kur(v.ligler[0].takimlar[0], "tr"); var t1 = Taktik.kadro_kur(v.ligler[0].takimlar[1], "tr")
	var M = Mac.new(t0, t1, 4, 1, false)
	M.T[0].human = false   # iki takım da yapay zekâ
	for i in 60 * 60 * 8:
		M.step(1.0 / 60.0)
		if M.state == "over": break
	print(M.rapor_metni(0))
	var R: Dictionary = M.rapor()
	print("RAPOR oyuncu=", R.oy.size(), " yildiz=", R.yildiz.n if R.yildiz != null else "-", " state=", M.state)
	quit()
