# Arma ve kupa çizicisi denemesi: godot --path km3 -s dene/arma_dene.gd -- cikti.png [ani]
# Ayrıca arma.js ile karşılaştırma için birkaç kulübün özelliklerini yazar.
extends SceneTree

func _init() -> void:
	var cikti := "arma.png"
	for a in OS.get_cmdline_user_args(): if a.ends_with(".png"): cikti = a
	var veri = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var T: Array = []
	for l in veri.ligler.slice(0, 3): T += l.takimlar.slice(0, 8)
	for t in T.slice(0, 6):
		var o := Arma.ozellik(Arma.kulup(t))
		print("AR ", t.id, " ", o.simge, " ", o.bicim, " ", o.desen, " ", o.yildiz, " ", o.cerceve, " ", o.kisa)
	root.size = Vector2i(1200, 820)
	var bg := ColorRect.new(); bg.color = Color("#1c2026"); bg.size = Vector2(1200, 820); root.add_child(bg)
	if OS.get_cmdline_user_args().has("kupa"):   # kupa kazanılınca lig ekranı (yan panelde kupa + arma) ve kupa anı
		var L := Lig.new(veri)
		var kazandi := false
		for tk in L.kupa_katilim("avr"):
			L.kupa_basla("avr", tk)
			var g := 0
			while L.kupa_benim_mac() != null and g < 12: L.kupa_sim_mac(); g += 1
			if L.kupa_kazandi(): kazandi = true; break
		print("kupa kazanıldı: ", kazandi)
		L.kip = "kupa"
		var E := LigEkran.new(L); root.add_child(E); E.size = Vector2(1200, 820); E.visible = true; E.yenile()
		for i in 90: await process_frame
		if OS.get_cmdline_user_args().has("panel") and root.has_node("KupaAni"): root.get_node("KupaAni").queue_free(); await process_frame
		L.sil()
	elif OS.get_cmdline_user_args().has("ani"):
		Arma.kupa_ani(self, {"ad": "Süper Lig", "tur": "lig", "takim": T[0]})
		for i in 90: await process_frame
	else:
		for i in 24:
			var a := Arma.yeni(T[i], Vector2(96, 96)); a.position = Vector2(10 + (i % 12) * 98, 10 + (i / 12) * 100); a.size = Vector2(96, 96); root.add_child(a)
		for i in 24:
			var a := Arma.yeni(T[i], Vector2(28, 28)); a.position = Vector2(10 + i * 34, 215); a.size = Vector2(28, 28); root.add_child(a)
		var kup := [{"tur": "lig"}, {"kod": "avr"}, {"kod": "kit"}, {"kod": "mil"}, {"kod": "ipe"}, {"kod": "kon"}, {"kod": "kuz"}, {"kod": "sav"}, {"kod": "yerel"}, {"kod": "uecl"}]
		for i in kup.size():
			var o: Dictionary = kup[i]; o.k1 = "#a90432"; o.k2 = "#fdb912"
			var k := Arma.kupa_yeni(o, Vector2(110, 135)); k.position = Vector2(10 + i * 118, 260); k.size = Vector2(110, 135); root.add_child(k)
			var k2 := Arma.kupa_yeni(o, Vector2(40, 50)); k2.position = Vector2(10 + i * 50, 420); k2.size = Vector2(40, 50); root.add_child(k2)
		var b := Arma.yeni(T[0], Vector2(300, 300)); b.position = Vector2(10, 490); b.size = Vector2(300, 300); root.add_child(b)
		var b2 := Arma.yeni(T[3], Vector2(300, 300)); b2.position = Vector2(320, 490); b2.size = Vector2(300, 300); root.add_child(b2)
		var kb := Arma.kupa_yeni({"kod": "avr", "k1": "#002f6c", "k2": "#ffffff"}, Vector2(250, 310)); kb.position = Vector2(640, 490); kb.size = Vector2(250, 310); root.add_child(kb)
		for i in 4: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(cikti)
	print("kaydedildi ", cikti)
	quit()
