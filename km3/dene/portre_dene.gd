# Yüz çizicisi denemesi: godot --path km3 -s dene/portre_dene.gd -- cikti.png
# Ayrıca CBM yuz.js ile karşılaştırma için birkaç adın özelliklerini yazar.
extends SceneTree

func _init() -> void:
	var cikti := "yuz.png"
	for a in OS.get_cmdline_user_args(): if a.ends_with(".png"): cikti = a
	for ad in ["U. Çakel", "R. Sarrae", "D. Sánkhaz", "I. Gümdoğon", "Y. Ozimhan"]:
		var g := Yuz.ozellik({"ad": ad})
		print("OZ ", ad, " ", g.stil, " ", g.ten.to_html(false), " ", g.sac.to_html(false), " ", "%.6f %.6f %.6f" % [g.genis, g.cene, g.kirli], " ", g.sakal, " ", g.yas, " ", g.kel)
	root.size = Vector2i(1200, 820)
	var bg := ColorRect.new(); bg.color = Color("#1c2026"); bg.size = Vector2(1200, 820); root.add_child(bg)
	var roller := ["oyuncu", "oyuncu", "oyuncu", "oyuncu", "oyuncu", "oyuncu", "td", "asistan", "gazeteci", "yonetim", "hakem", "oyuncu"]
	var adlar := ["U. Çakel", "R. Sarrae", "D. Sánkhaz", "A. Bordokcı", "I. Jacabs", "L. Tolleiro", "O. Bukeç", "M. Yılmuz", "Z. Arkan", "H. Sagün", "C. Çakor", "Y. Ozimhan",
		"K. Ayhem", "W. Sinku", "C. Betsheabu", "E. Elmorı", "G. Güvamç", "S. Tapan", "F. Terum", "N. Dalgıç", "B. Uslı", "T. Köse", "P. Rossa", "J. Okafar"]
	var renkler := [["#a90432", "#fdb912"], ["#002f6c", "#ffffff"], ["#00843d", "#ffffff"], ["#1b1b1b", "#ffffff"]]
	for i in adlar.size():
		var r: Array = renkler[i % 4]
		var y := Yuz.yeni({"ad": adlar[i], "rol": roller[i % roller.size()] if i < 12 else "oyuncu", "k1": r[0], "k2": r[1], "yas": 0 if i < 12 else 0}, Vector2(140, 168))
		y.position = Vector2(10 + (i % 8) * 148, 10 + (i / 8) * 176); y.size = Vector2(140, 168)
		root.add_child(y)
	if OS.get_cmdline_user_args().has("buyuk"):
		for ch in root.get_children(): if ch is Yuz: ch.queue_free()
		for j in 3:
			var yb := Yuz.yeni({"ad": adlar[j * 4], "rol": roller[j * 4], "k1": "#a90432", "k2": "#fdb912"}, Vector2(400, 480)); yb.position = Vector2(j * 400, 0); yb.size = Vector2(400, 480); root.add_child(yb)
	var kucuk := Yuz.yeni({"ad": "U. Çakel", "k1": "#a90432", "k2": "#fdb912"}, Vector2(30, 36)); kucuk.position = Vector2(10, 548); kucuk.size = Vector2(30, 36); root.add_child(kucuk)
	var t0 := Time.get_ticks_msec()
	for ad in adlar: Yuz.komutlar({"ad": ad + "x", "rol": "oyuncu"})
	print("24 yüz komut süresi ms: ", Time.get_ticks_msec() - t0)
	await process_frame; await process_frame; await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(cikti)
	print("kaydedildi ", cikti)
	quit()
