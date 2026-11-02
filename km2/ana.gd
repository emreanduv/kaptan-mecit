# Kaptan Mecit 2 — ana sahne: menü, maç döngüsü (60 Hz sabit adım), görüntü eşlemesi, yayın kameraları, skor tabelası, ses.
extends Node3D

const PW := 68.0
const PL := 105.0
const ADIM := 1.0 / 60.0
const KAMERALAR := ["Yayın", "Tele", "Dinamik", "Saha kenarı"]
const SURELER := [2, 4, 6, 8]
const ZORLUK := ["Kolay", "Orta", "Zor"]

var veri: Dictionary
var M: Mac = null
var stad: Stadyum = null
var oyuncular: Array = []
var top: MeshInstance3D
var isaret: MeshInstance3D
var kam: Camera3D
var kam_mod := 0
var _kam_hedef := Vector3.ZERO
var _birikim := 0.0
var ses: Ses
var sec := {"lig": 0, "ev": 0, "dep": 1, "sure": 1, "zor": 1}
var menu_acik := true
var dunya: Node3D
var gunes: DirectionalLight3D
var vr: VR = null
var vr_koltuk := 2
var hafif := OS.has_feature("android")

# arayüz
var ui: CanvasLayer
var tabela: Label
var dakika: Label
var afis: PanelContainer
var afis_ust: Label
var afis_alt: Label
var _afis_t := 0.0
var bilgi: Label
var menu: PanelContainer
var sec_lig: Secici
var sec_ev: Secici
var sec_dep: Secici
var sec_sure: Secici
var sec_zor: Secici
var sec_kam: Secici

# test / ekran görüntüsü (komut satırı)
var _arg := {}

func _ready() -> void:
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_arg[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if _arg.has("hafif"): hafif = true
	veri = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	_ortam()
	dunya = Node3D.new(); add_child(dunya)
	kam = Camera3D.new(); kam.current = true; kam.near = .3; kam.far = 900
	add_child(kam)
	top = MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = .12; sm.height = .24; sm.radial_segments = 24; sm.rings = 12
	top.mesh = sm
	var tm := ShaderMaterial.new(); var sh := Shader.new(); sh.code = TOP_SHADER; tm.shader = sh
	top.material_override = tm
	dunya.add_child(top)
	isaret = MeshInstance3D.new()
	var tor := TorusMesh.new(); tor.inner_radius = .62; tor.outer_radius = .78; tor.rings = 32
	isaret.mesh = tor; isaret.scale = Vector3(1, .05, 1)
	var im := StandardMaterial3D.new(); im.albedo_color = Color("#f3d35a"); im.emission_enabled = true; im.emission = Color("#f3d35a"); im.emission_energy_multiplier = 1.5
	im.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	isaret.material_override = im; isaret.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dunya.add_child(isaret)
	ses = Ses.new(); add_child(ses)
	_arayuz()
	kam_mod = int(_arg.get("kamera", "0"))
	sec_kam.select(kam_mod)
	# açılışta arkada gösterim maçı döner (Kaptan Mecit'teki gibi)
	_mac_kur(_takim(0, 0), _takim(0, 1), 4, 1, true)
	vr = VR.baslat(self, _arg.has("vrsahte"))
	if vr:
		kam.current = false
		ses.baslat()
	if _arg.has("mac"):
		menu_goster(false); _mac_kur(_takim(0, 0), _takim(0, 1), 4, 1, _arg.has("gosterim"))
	if _arg.has("ileri"):
		var n := int(float(_arg.ileri) * 60)
		for i in n: _adim()
	if _arg.has("dene"):
		# başsız deneme: maçı sonuna kadar oynat, skor ve olay sayısını yaz
		var t0 := Time.get_ticks_msec()
		var n := 0
		while M.state != "over" and n < 60 * 60 * 20:
			if n % 90 == 0: M.giris.x = randf_range(-1, 1); M.giris.y = randf_range(-1, 1); M.giris.pasE = randf() < .3; M.giris.sutE = randf() < .2
			M.step(ADIM); M.olaylar.clear(); n += 1
		print("TEST bitti: ", M.T[0].t.kisa, " ", M.T[0].score, "-", M.T[1].score, " ", M.T[1].t.kisa, " adım=", n, " dk=", M.min_label(), " goller=", M.events, " süre(ms)=", Time.get_ticks_msec() - t0)
		get_tree().quit(); return
	if _arg.has("ekran"):
		menu_goster(_arg.has("menu"))
		await get_tree().create_timer(float(_arg.get("bekle", "1.5"))).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_arg.ekran)
		print("ekran kaydedildi: ", _arg.ekran, " seyirci=", stad.seyirci_sayisi(), " fps=", Engine.get_frames_per_second(),
			" çizim=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			" üçgen=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		get_tree().quit()

func _takim(lig: int, i: int) -> Dictionary: return veri.ligler[lig].takimlar[i]

# ---------- ortam: gece maçı ----------
func _ortam() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var ps := ProceduralSkyMaterial.new()
	ps.sky_top_color = Color("#070b18"); ps.sky_horizon_color = Color("#1c2638")
	ps.ground_bottom_color = Color("#0b0d10"); ps.ground_horizon_color = Color("#1c2638")
	ps.sun_angle_max = 0.0
	sky.sky_material = ps
	env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8ea4c4"); env.ambient_light_energy = .55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.05
	env.glow_enabled = true; env.glow_intensity = .55; env.glow_bloom = .05; env.glow_hdr_threshold = 1.2
	env.adjustment_enabled = true; env.adjustment_contrast = 1.06; env.adjustment_saturation = 1.08
	we.environment = env
	add_child(we)
	# projektörlerin birleşik ışığı: hafif sıcak beyaz, gölgeli
	var gl := DirectionalLight3D.new()
	gl.rotation_degrees = Vector3(-58, 28, 0)
	gl.light_color = Color("#fff4e2"); gl.light_energy = 1.35
	gl.shadow_enabled = true; gl.shadow_bias = .03; gl.shadow_normal_bias = 1.2
	gl.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	gl.directional_shadow_max_distance = 140.0
	add_child(gl); gunes = gl
	# karşı projektör: gölgesiz dolgu
	var dl := DirectionalLight3D.new()
	dl.rotation_degrees = Vector3(-50, 208, 0); dl.light_color = Color("#e8eeff"); dl.light_energy = .55
	add_child(dl)

# ---------- maç kurulumu ----------
func _mac_kur(ev: Dictionary, dep: Dictionary, sure: int, zor: int, gosterim: bool) -> void:
	M = Mac.new(ev, dep, sure, zor, gosterim)
	if stad: stad.queue_free()
	stad = Stadyum.new(); stad.hafif = hafif; dunya.add_child(stad)
	stad.kur(M.T[0].kit, M.T[1].kit, veri.panolar)
	Futbolcu.hafif = hafif
	for f in oyuncular: f.queue_free()
	oyuncular.clear()
	var trim := func(c1: String, c2: String) -> String: return c2 if Mac.renk_farki(c1, c2) > 128 else "#ffffff"
	for p in M.P:
		var kit: Dictionary = M.T[p.team].kit
		var gk: bool = p.role == "G"
		var renk := {"forma": ("#f3d35a" if p.team == 0 else "#3ec46d") if gk else kit.c1,
			"serit": "#1d1d1d" if gk else trim.call(kit.c1, kit.c2), "sort": "#1d1d1d" if gk else kit.c2,
			"tozluk": "#1d1d1d" if gk else kit.c1, "ten": p.ten, "sac": p.sac, "eldiven": "#f4f4f4" if gk else null}
		var f := Futbolcu.new()
		dunya.add_child(f)
		f.kur(renk, p.no, .96 + float((p.no * 37) % 9) / 100.0)
		oyuncular.append(f)
	_birikim = 0.0
	_tabela()

# ---------- döngü ----------
func _process(dt: float) -> void:
	_girdi()
	_birikim = minf(_birikim + dt, .25)
	while _birikim >= ADIM:
		_birikim -= ADIM
		_adim()
	_ciz(dt)
	if _afis_t > 0:
		_afis_t -= dt
		if _afis_t <= 0: afis.visible = false

func _adim() -> void:
	if M == null: return
	if not menu_acik or M.demo: M.step(ADIM)
	for o in M.olaylar: _olay(o)
	M.olaylar.clear()
	if M.state == "over" and M.demo:
		# gösterim maçı biter bitmez yenisi başlar
		var L: Array = veri.ligler[randi() % veri.ligler.size()].takimlar
		var a := randi() % L.size(); var b := (a + 1 + randi() % (L.size() - 1)) % L.size()
		_mac_kur(L[a], L[b], 4, 1, true)

func _olay(o: Array) -> void:
	match o[0]:
		"banner": afis_goster(o[1], o[2], 2.2)
		"flash": afis_goster(o[1], "", 1.0)
		"duduk": ses.duduk(int(o[1]))
		"vurus": ses.vurus(float(o[1]))
		"ooo": ses.ooo()
		"gol":
			ses.gol()
			_tabela()
		"tik": ses.tik()

func _girdi() -> void:
	if M == null or M.demo or menu_acik: return
	if vr: vr.girdi(M); return
	var v := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if Input.is_key_pressed(KEY_A): v.x -= 1
	if Input.is_key_pressed(KEY_D): v.x += 1
	if Input.is_key_pressed(KEY_W): v.y -= 1
	if Input.is_key_pressed(KEY_S): v.y += 1
	var joy := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if joy.length() > .2: v = joy
	if v.length() > 1: v = v.normalized()
	# ekran yönünü sahaya çevir: kameranın sağı ve ileri yönü (yere izdüşüm)
	var sag := kam.global_basis.x; sag.y = 0; sag = sag.normalized()
	var ileri := -kam.global_basis.z; ileri.y = 0; ileri = ileri.normalized()
	var w := sag * v.x - ileri * v.y
	M.giris.x = w.x; M.giris.y = w.z

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_X, KEY_K: if M: M.giris.pasE = true
			KEY_Z, KEY_SPACE, KEY_L: if M: M.giris.sutE = true
			KEY_C: _kamera((kam_mod + 1) % KAMERALAR.size())
			KEY_ESCAPE, KEY_M: if M and not M.demo: menu_goster(not menu_acik)
	elif e is InputEventJoypadButton and e.pressed:
		match e.button_index:
			JOY_BUTTON_A: if M: M.giris.pasE = true
			JOY_BUTTON_B, JOY_BUTTON_X: if M: M.giris.sutE = true
			JOY_BUTTON_Y: _kamera((kam_mod + 1) % KAMERALAR.size())
			JOY_BUTTON_START: if M and not M.demo: menu_goster(not menu_acik)

static func W(x: float, y: float, z := 0.0) -> Vector3: return Vector3(x - PW / 2, z, y - PL / 2)

func _ciz(dt: float) -> void:
	if M == null: return
	var now := Time.get_ticks_msec() / 1000.0
	var gol := M.son_gol_takimi()
	for i in M.P.size():
		var p = M.P[i]
		var f: Futbolcu = oyuncular[i]
		f.position = W(p.x, p.y)
		f.poz(p, M, now, gol)
	var b = M.ball
	top.position = W(b.x, b.y, b.z + .12)
	top.rotate(Vector3(b.vy, 0, -b.vx).normalized() if (b.vx != 0 or b.vy != 0) else Vector3.UP, Vector2(b.vx, b.vy).length() * dt / .12)
	isaret.visible = M.ctrl != null and not M.demo
	if isaret.visible: isaret.position = W(M.ctrl.x, M.ctrl.y, .02)
	# tribün heyecanı: gol, top kaleye yaklaştıkça
	var yakin := 1.0 - clampf(minf(b.y, PL - b.y) / 30.0, 0, 1)
	stad.heyecan(1.0 if gol >= 0 else yakin * .25)
	ses.heyecan(1.0 if gol >= 0 else yakin)
	dakika.text = M.min_label() + "'"
	_kamera_guncelle(dt)

func _kamera_guncelle(dt: float) -> void:
	if vr: return
	var b = M.ball
	var bw := W(b.x, b.y, b.z)
	var ileri_y := 1.0 if M.goal_y_of(0) == 0.0 else -1.0     # ev sahibinin hücum yönü (dünya Z'de ters)
	var poz: Vector3; var bak: Vector3; var fov: float
	match kam_mod:
		0:  # yayın: yan tribün üstü, topu yatayda izler
			poz = Vector3(53, 20, clampf(bw.z * .8, -32, 32)); bak = Vector3(bw.x * .6, 0, bw.z); fov = 30
		1:  # tele: köşe, yüksek
			poz = Vector3(46, 24, 66); bak = Vector3(bw.x * .7, 0, bw.z * .85); fov = 34
		2:  # dinamik: ev sahibinin arkasından, hücum yönüne bakar
			poz = Vector3(bw.x * .55, 15, clampf(bw.z + ileri_y * 26, -PL / 2 - 14, PL / 2 + 14)); bak = Vector3(bw.x * .8, 0, bw.z - ileri_y * 8); fov = 48
		_:  # saha kenarı: göz hizası
			poz = Vector3(PW / 2 + 5, 1.75, clampf(bw.z, -40, 40) * .7); bak = Vector3(bw.x, .9, bw.z); fov = 52
	if _arg.has("yakin"):
		if b.owner != null: bw = W(b.owner.x, b.owner.y)
		kam.position = bw + Vector3(4.0, 1.9, 3.0); kam.fov = 42; kam.look_at(bw + Vector3(0, .9, 0)); return
	var k := 1.0 - exp(-dt * 3.2)
	kam.position = kam.position.lerp(poz, k) if kam.position != Vector3.ZERO else poz
	_kam_hedef = _kam_hedef.lerp(bak, 1.0 - exp(-dt * 4.5)) if _kam_hedef != Vector3.ZERO else bak
	kam.fov = lerpf(kam.fov, fov, k)
	kam.look_at(_kam_hedef)

func _kamera(i: int) -> void:
	kam_mod = i
	sec_kam.select(i)
	afis_goster("KAMERA", KAMERALAR[i], .9)

# ---------- arayüz ----------
func _arayuz() -> void:
	ui = CanvasLayer.new(); add_child(ui)
	var tema := Theme.new()
	tema.default_font_size = 18
	# tabela (sol üst)
	var tp := PanelContainer.new()
	tp.add_theme_stylebox_override("panel", _kutu(Color(0.04, 0.07, 0.09, .82), 10))
	tp.position = Vector2(18, 16)
	var th := HBoxContainer.new(); th.add_theme_constant_override("separation", 14)
	tp.add_child(th)
	tabela = Label.new(); tabela.add_theme_font_size_override("font_size", 24)
	dakika = Label.new(); dakika.add_theme_font_size_override("font_size", 24); dakika.add_theme_color_override("font_color", Color("#f3d35a"))
	th.add_child(tabela); th.add_child(dakika)
	ui.add_child(tp)
	# afiş (orta)
	afis = PanelContainer.new()
	afis.add_theme_stylebox_override("panel", _kutu(Color(0.04, 0.07, 0.09, .86), 14))
	afis.custom_minimum_size = Vector2(520, 0)
	var av := VBoxContainer.new(); av.alignment = BoxContainer.ALIGNMENT_CENTER
	afis_ust = Label.new(); afis_ust.add_theme_font_size_override("font_size", 40); afis_ust.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	afis_ust.add_theme_color_override("font_color", Color("#f3d35a"))
	afis_alt = Label.new(); afis_alt.add_theme_font_size_override("font_size", 20); afis_alt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av.add_child(afis_ust); av.add_child(afis_alt); afis.add_child(av)
	afis.visible = false
	var ak := CenterContainer.new(); ak.set_anchors_preset(Control.PRESET_TOP_WIDE); ak.offset_top = 110; ak.offset_bottom = 260
	ak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ak.add_child(afis); ui.add_child(ak)
	# kısayollar (sol alt)
	bilgi = Label.new()
	bilgi.text = "WASD / oklar: koş · X: pas / oyuncu seç · Z / boşluk: şut · kay · C: kamera · M: menü   ·   Kol: sol çubuk koş · A pas · B şut · Y kamera"
	bilgi.add_theme_font_size_override("font_size", 14); bilgi.add_theme_color_override("font_color", Color(1, 1, 1, .75))
	bilgi.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); bilgi.position = Vector2(18, -34)
	ui.add_child(bilgi)
	var imza := Label.new(); imza.text = "Bir Mr. Anduv! yapımıdır."
	imza.add_theme_stylebox_override("normal", _kutu(Color(0.04, 0.07, 0.09, .7), 8))
	imza.add_theme_font_size_override("font_size", 15); imza.add_theme_color_override("font_color", Color(1, 1, 1, .8))
	imza.set_anchors_preset(Control.PRESET_TOP_RIGHT); imza.position = Vector2(-250, 16)
	ui.add_child(imza)
	# menü
	menu = PanelContainer.new()
	menu.add_theme_stylebox_override("panel", _kutu(Color("#f5ecd8"), 16))
	menu.custom_minimum_size = Vector2(800, 0)
	var mv := VBoxContainer.new(); mv.add_theme_constant_override("separation", 10)
	var bas := PanelContainer.new(); bas.add_theme_stylebox_override("panel", _kutu(Color("#1f3b3c"), 12))
	var bv := VBoxContainer.new()
	var bl := Label.new(); bl.text = "Kaptan Mecit 2"; bl.add_theme_font_size_override("font_size", 34); bl.add_theme_color_override("font_color", Color.WHITE)
	var bl2 := Label.new(); bl2.text = "Bir Mr. Anduv! yapımıdır."; bl2.add_theme_font_size_override("font_size", 15); bl2.add_theme_color_override("font_color", Color("#cfe3d6"))
	bv.add_child(bl); bv.add_child(bl2); bas.add_child(bv); mv.add_child(bas)
	sec_lig = _secici(mv, "Lig"); sec_ev = _secici(mv, "Senin takımın"); sec_dep = _secici(mv, "Rakip")
	var sat := HBoxContainer.new(); sat.add_theme_constant_override("separation", 10)
	sec_sure = _secici(sat, "Süre"); sec_zor = _secici(sat, "Zorluk"); sec_kam = _secici(sat, "Kamera")
	mv.add_child(sat)
	for l in veri.ligler: sec_lig.add_item(l.ad + " · " + l.ulke)
	for s in SURELER: sec_sure.add_item(str(s) + " dk")
	for z in ZORLUK: sec_zor.add_item(z)
	for k in KAMERALAR: sec_kam.add_item(k)
	sec_sure.select(1); sec_zor.select(1)
	sec_lig.item_selected.connect(func(_i): _takimlari_doldur())
	sec_kam.item_selected.connect(func(i): kam_mod = i)
	_takimlari_doldur()
	var dug := Button.new(); dug.text = "Maça başla"; dug.add_theme_font_size_override("font_size", 24)
	dug.add_theme_stylebox_override("normal", _kutu(Color("#e5722f"), 12)); dug.add_theme_stylebox_override("hover", _kutu(Color("#f08442"), 12))
	dug.add_theme_stylebox_override("pressed", _kutu(Color("#c95f22"), 12)); dug.add_theme_color_override("font_color", Color.WHITE)
	dug.custom_minimum_size = Vector2(0, 58)
	dug.pressed.connect(basla)
	mv.add_child(dug)
	menu.add_child(mv)
	var mk := CenterContainer.new(); mk.set_anchors_preset(Control.PRESET_FULL_RECT); mk.mouse_filter = Control.MOUSE_FILTER_IGNORE
	mk.add_child(menu); ui.add_child(mk)

func _secici(kap: Container, ad: String) -> Secici:
	var v := VBoxContainer.new(); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := Label.new(); l.text = ad; l.add_theme_font_size_override("font_size", 14); l.add_theme_color_override("font_color", Color("#5b6466"))
	var o := Secici.new()
	v.add_child(l); v.add_child(o); kap.add_child(v)
	return o

func _takimlari_doldur() -> void:
	var L: Array = veri.ligler[sec_lig.selected].takimlar
	for o in [sec_ev, sec_dep]:
		o.clear()
		for t in L: o.add_item("%s   ·   güç %d" % [t.ad, int(t.str)])
	sec_ev.select(0); sec_dep.select(1)

func basla() -> void:
	var L: Array = veri.ligler[sec_lig.selected].takimlar
	var a := sec_ev.selected; var b := sec_dep.selected
	if a == b: b = (b + 1) % L.size()
	menu_goster(false)
	_mac_kur(L[a], L[b], SURELER[sec_sure.selected], sec_zor.selected, false)
	kam_mod = sec_kam.selected
	ses.baslat()

func menu_goster(v: bool) -> void:
	menu_acik = v
	menu.visible = v

func _tabela() -> void:
	tabela.text = "%s  %d - %d  %s" % [M.T[0].t.kisa, M.T[0].score, M.T[1].score, M.T[1].t.kisa]
	stad.skor("%s %d-%d %s" % [M.T[0].t.kisa, M.T[0].score, M.T[1].score, M.T[1].t.kisa])

func afis_gorunur() -> bool: return afis.visible

func afis_goster(ust: String, alt, sure: float) -> void:
	afis_ust.text = ust; afis_alt.text = str(alt) if alt != null else ""
	afis_alt.visible = afis_alt.text != ""
	afis.visible = true; _afis_t = sure

static func _kutu(c: Color, r: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = c
	s.set_corner_radius_all(r); s.set_content_margin_all(12)
	return s

const TOP_SHADER := """
shader_type spatial;
varying vec3 n;
void vertex(){ n = normalize(VERTEX); }
void fragment(){
	// klasik top: 12 siyah beşgen (ikosahedron köşeleri)
	float t = 1.618034;
	vec3 v[12] = vec3[](vec3(-1,t,0),vec3(1,t,0),vec3(-1,-t,0),vec3(1,-t,0),vec3(0,-1,t),vec3(0,1,t),vec3(0,-1,-t),vec3(0,1,-t),vec3(t,0,-1),vec3(t,0,1),vec3(-t,0,-1),vec3(-t,0,1));
	float m = 0.0;
	for (int i = 0; i < 12; i++) m = max(m, dot(n, normalize(v[i])));
	vec3 c = m > 0.93 ? vec3(0.02) : vec3(0.9);
	if (m > 0.915 && m < 0.93) c = vec3(0.5);
	ALBEDO = c; ROUGHNESS = 0.45;
}
"""
