# Virajda gövde eğimi denemesi: oyuncu saat yönünün tersine çember çiziyor (merkez sahnenin ortası),
# kamera çemberin dışından, oyuncu kameraya doğru gelirken bakar; gövde merkeze (görüntüde sola) yatmalı.
extends Node3D
class SahteOy:
	var x := 0.0; var y := 0.0; var vx := 0.0; var vy := 0.0; var dx := 0.0; var dy := 1.0
	var anim := 0.0; var slide := 0.0; var stun := 0.0; var role := "O"; var team := 0; var cd := 0.0; var dive := 0
class SahteTop:
	var x := 100.0; var y := 100.0; var kicker = null
class SahteMac:
	var ball := SahteTop.new()
var M := SahteMac.new()
func _ready() -> void:
	var we := WorldEnvironment.new(); var env := Environment.new(); env.background_mode = Environment.BG_COLOR; env.background_color = Color("#20303a")
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR; env.ambient_light_color = Color(.6, .65, .7); env.ambient_light_energy = .6
	we.environment = env; add_child(we)
	var l := DirectionalLight3D.new(); l.rotation_degrees = Vector3(-40, 40, 0); add_child(l)
	var f := Futbolcu.new(); add_child(f)
	f.kur({"forma": "#c8102e", "serit": "#ffffff", "sort": "#f3d35a", "tozluk": "#c8102e", "ten": "#e0ac7e", "sac": "#2a1a10"}, 10)
	var p := SahteOy.new()
	var R := 7.0; var v := 7.0; var dt := 1.0 / 60.0; var a := 0.0; var t := 0.0
	var k := Camera3D.new(); add_child(k); k.current = true; k.fov = 35
	# çember: konum (R cos a, R sin a) düzlemde (x, z); a artıyor → saat yönü tersine (yukarıdan)
	while a < 2.0 * PI + PI / 2:
		a += v / R * dt; t += dt
		var px := R * cos(a); var pz := R * sin(a)
		var tx := -sin(a); var tz := cos(a)
		p.vx = tx * v; p.vy = tz * v; p.dx = tx; p.dy = tz; p.anim += v * dt
		f.position = Vector3(px, 0, pz)
		f.poz(p, M, t, -1)
	# oyuncu a = 2.5π noktasında (x=0, z=R) +x yönünde... kamera hareket yönünün önünden bakar
	var px2 := f.position
	var on := Vector3(-sin(a), 0, cos(a))
	k.position = px2 + on * 6.0 + Vector3(0, 1.2, 0); k.look_at(px2 + Vector3(0, .9, 0))
	await RenderingServer.frame_post_draw
	get_viewport().get_texture().get_image().save_png(OS.get_cmdline_user_args()[0])
	print("merkez ekranda: ", "sol" if k.unproject_position(Vector3.ZERO).x < k.unproject_position(px2).x else "sağ")
	get_tree().quit()
