# Çizimli LED panoları denemesi (Çizim Planı F3): stadyumu kurar, kenar panolarına bakan kameradan görüntü alır.
# xvfb-run godot --path km3 --rendering-driver opengl3 -s dene/pano_dene.gd -- cikti.png [en] [tur=N]
extends SceneTree

func _init() -> void:
	var cikti := "pano.png"; var tur := 0
	for a in OS.get_cmdline_user_args():
		if a.ends_with(".png"): cikti = a
		if a.begins_with("tur="): tur = int(a.substr(4))
	Dil.en = OS.get_cmdline_user_args().has("en")
	var veri = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	root.size = Vector2i(1688, 780)
	var d := Node3D.new(); root.add_child(d)
	var we := WorldEnvironment.new(); var env := Environment.new()
	env.background_mode = Environment.BG_COLOR; env.background_color = Color("#0d1420")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color("#8090a0"); env.ambient_light_energy = .8
	we.environment = env; d.add_child(we)
	var gn := DirectionalLight3D.new(); gn.rotation = Vector3(-0.9, 0.5, 0); d.add_child(gn)
	var s := Stadyum.new(); s.hafif = true; d.add_child(s)
	s.kur({"c1": "#A90432", "c2": "#FDB912"}, {"c1": "#1d3c8a", "c2": "#ffffff"}, veri.panolar, veri.get("afisler", []))
	s._pano_yenile(tur)
	var bos := 0; var afisli := 0
	for p in s.panolar:
		if p.yuz.visible: afisli += 1
		elif p.lab.text == "": bos += 1
	print("PANO ", s.panolar.size(), " afişli ", afisli, " boş ", bos)
	var k := Camera3D.new(); k.fov = 40
	d.add_child(k)
	k.look_at_from_position(Vector3(26, 4, -34), Vector3(Stadyum.HX + 4.5, .5, -22), Vector3.UP)
	k.current = true
	for i in 12: await process_frame
	root.get_texture().get_image().save_png(cikti)
	print(("TAMAM" if bos == 0 and afisli > 0 else "HATA"), " ", cikti)
	quit()
