# Saç modelleri ve yüz: beş oyuncu yan yana, önden yakın çekim (ekran görüntüsü)
extends Node3D
class SahteOy:
	var x := 0.0; var y := 0.0; var vx := 0.0; var vy := 0.0; var dx := 0.0; var dy := 1.0
	var anim := 0.0; var slide := 0.0; var stun := 0.0; var role := "O"; var team := 0; var cd := 0.0; var dive := 0
class SahteTop:
	var x := 100.0; var y := 100.0; var kicker = null
class SahteMac:
	var ball := SahteTop.new()
func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color("#2a4a30")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(.7, .72, .75); env.ambient_light_energy = .7
	we.environment = env; add_child(we)
	var l := DirectionalLight3D.new(); l.rotation_degrees = Vector3(-35, 20, 0); add_child(l)
	var tenler := ["#f1c9a5", "#e0ac7e", "#c68a5a", "#8d5a3b", "#f5d6b8"]; var saclar := ["#2a1a10", "#c8a050", "#1a1a1a", "#4a2e1a", "#7a4a20"]
	for i in 5:
		var f := Futbolcu.new(); add_child(f)
		f.kur({"forma": "#c8102e", "serit": "#ffffff", "sort": "#f3d35a", "tozluk": "#c8102e", "ten": tenler[i], "sac": saclar[i], "stil": i}, 10 + i)
		f.position = Vector3((i - 2) * .75, 0, 0)
		var p := SahteOy.new(); f.poz(p, SahteMac.new(), 0.0, -1)
	var k := Camera3D.new(); add_child(k); k.current = true; k.fov = 30
	k.position = Vector3(0, 1.75, 4.2); k.look_at(Vector3(0, 1.55, 0))
	await RenderingServer.frame_post_draw
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	get_tree().quit()
