# Kaleci uçuşu denemesi: önden (sahadan kaleye bakan) kamera, uçuşun 8 anı tek görüntüde. Kullanım:
# godot --path . dene/kaleci_dene.tscn -- cikti.png [tur=1] [yan=1] [z=.8]
extends Node3D

class SahteOy:
	var x := 34.0; var y := 1.0; var vx := 0.0; var vy := 0.0; var dx := 0.0; var dy := 1.0
	var anim := 0.0; var slide := 0.0; var stun := 0.0; var role := "G"; var team := 0; var cd := 0.0; var dive := 0
	var ucus := 0.0; var ucus_tur := 1; var ucus_yan := 1.0; var ucus_z := .8; var ucus_ofs := Vector2(-2.0, 0)
class SahteTop:
	var x := 36.0; var y := 12.0; var kicker = null
class SahteMac:
	var ball := SahteTop.new()
	func fwd_of(_t: int) -> float: return 1.0

func _ready() -> void:
	var a := OS.get_cmdline_user_args()
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color("#20303a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(.6, .65, .7); env.ambient_light_energy = .6
	we.environment = env; add_child(we)
	var l := DirectionalLight3D.new(); l.rotation_degrees = Vector3(-40, 20, 0); add_child(l)
	var zemin := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(40, 40); zemin.mesh = pm
	var zm := StandardMaterial3D.new(); zm.albedo_color = Color("#2c6a2a"); zemin.material_override = zm; add_child(zemin)
	var f := Futbolcu.new(); add_child(f)
	f.kur({"forma": "#f3d35a", "serit": "#1d1d1d", "sort": "#1d1d1d", "tozluk": "#1d1d1d", "ten": "#e0ac7e", "sac": "#2a1a10", "eldiven": "#f4f4f4"}, 1)
	var p := SahteOy.new(); var M := SahteMac.new()
	for x in a:
		if x.begins_with("tur="): p.ucus_tur = int(x.substr(4))
		if x.begins_with("yan="): p.ucus_yan = float(x.substr(4)); p.ucus_ofs = Vector2(-2.0 * p.ucus_yan, 0)
		if x.begins_with("z="): p.ucus_z = float(x.substr(2))
	var T := 1.5 if p.ucus_tur == 1 else .7
	# kale çizgisi (görsel ölçek için)
	var kale := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(7.32, .08, .08); kale.mesh = bm; kale.position = Vector3(0, 2.44, -.6); add_child(kale)
	var k := Camera3D.new(); k.position = Vector3(0, 1.2, 7.5); k.fov = 45; add_child(k); k.look_at(Vector3(0, .8, 0)); k.current = true
	var kareler: Array = []
	for i in 8:
		p.ucus = T - T * i / 7.0 * .999
		f.position = Vector3.ZERO
		f.poz(p, M, 0.0, -1)
		await RenderingServer.frame_post_draw
		await RenderingServer.frame_post_draw
		kareler.append(get_viewport().get_texture().get_image())
	var ilk: Image = kareler[0]; var w := ilk.get_width() / 2; var h := ilk.get_height() / 2
	var son := Image.create(w * 4, h * 2, false, Image.FORMAT_RGBA8)
	for i in 8:
		var im: Image = kareler[i]; im.convert(Image.FORMAT_RGBA8); im.resize(w, h)
		son.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % 4) * w, (i / 4) * h))
	son.save_png(a[0])
	get_tree().quit()
