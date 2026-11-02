# Hareket denemesi: dört oyuncu yan yana (yürü, koş, depar, vuruş), yandan kamera; kareleri tek görüntüde birleştirir.
extends Node3D

class SahteOy:
	var x := 0.0; var y := 0.0; var vx := 0.0; var vy := 0.0; var dx := 0.0; var dy := 1.0
	var anim := 0.0; var slide := 0.0; var stun := 0.0; var role := "O"; var team := 0; var cd := 0.0; var dive := 0
class SahteTop:
	var x := 100.0; var y := 100.0; var kicker = null
class SahteMac:
	var ball := SahteTop.new()

var F: Array = []
var P: Array = []
var M := SahteMac.new()
var hizlar := [1.3, 3.3, 6.5, 0.0]

func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color("#20303a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(.6, .65, .7); env.ambient_light_energy = .6
	we.environment = env; add_child(we)
	var l := DirectionalLight3D.new(); l.rotation_degrees = Vector3(-40, 40, 0); add_child(l)
	var zemin := MeshInstance3D.new(); var pm := PlaneMesh.new(); pm.size = Vector2(40, 40); zemin.mesh = pm
	var zm := StandardMaterial3D.new(); zm.albedo_color = Color("#2c6a2a"); zemin.material_override = zm; add_child(zemin)
	for i in 4:
		var f := Futbolcu.new(); add_child(f)
		f.kur({"forma": "#c8102e", "serit": "#ffffff", "sort": "#f3d35a", "tozluk": "#c8102e", "ten": "#e0ac7e", "sac": "#2a1a10"}, 10 + i)
		f.position = Vector3(i * 1.6 - 2.4, 0, 0); f.yaw = PI / 2
		var p := SahteOy.new(); p.dx = 1; p.dy = 0
		F.append(f); P.append(p)
	var k := Camera3D.new(); k.position = Vector3(0, 1.0, 6.2); k.fov = 40; add_child(k); k.look_at(Vector3(0, .9, 0)); k.current = true
	var kareler: Array = []
	for t in 8:
		for s in 6:
			_adim(1.0 / 60.0, t * 6 + s)
		await RenderingServer.frame_post_draw
		kareler.append(get_viewport().get_texture().get_image())
	# 8 kareyi 4x2 ızgara yap
	var ilk: Image = kareler[0]; var w := ilk.get_width() / 2; var h := ilk.get_height() / 2
	var son := Image.create(w * 4, h * 2, false, Image.FORMAT_RGBA8)
	for i in 8:
		var im: Image = kareler[i]; im.convert(Image.FORMAT_RGBA8); im.resize(w, h)
		son.blit_rect(im, Rect2i(0, 0, w, h), Vector2i((i % 4) * w, (i / 4) * h))
	son.save_png(OS.get_cmdline_user_args()[0])
	get_tree().quit()

func _adim(dt: float, n: int) -> void:
	for i in 4:
		var p: SahteOy = P[i]
		if i < 3:
			p.vx = hizlar[i]; p.anim += hizlar[i] * dt
		else:
			# vuruş: her 0.45 sn'de bir
			p.vx = 0.0
			var ev := fmod(n * dt, .45)
			M.ball.kicker = p; p.cd = .35 - ev * (.35 / .45) + .1
		F[i].poz(p, M, n * dt, -1)
