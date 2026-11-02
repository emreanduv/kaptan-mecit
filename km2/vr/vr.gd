# Kaptan Mecit 2 — VR (Meta Quest, OpenXR): mide bulandırmayan düzen.
# Kamera hiçbir zaman kendiliğinden hareket etmez: oyuncu sabit koltuklardan birinde oturur, başını çevirerek izler.
# Koltuk değişimi kısa bir kararmayla olur (yapay yürüme/dönme yok). Maket koltuğunda stadyum masanın üstünde küçülür.
extends Node3D
class_name VR

const KOLTUKLAR := ["Maket", "Saha kenarı", "TV", "Dinamik", "Tele", "Stadyum"]
const MAKET_OLCEK := 1.0 / 70.0

var ana: Node3D
var arayuz: Node            # ana'nın CanvasLayer'ı (menü + tabela) burada bir panele çizilir
var xr: XRInterface
var koken: XROrigin3D
var kafa: XRCamera3D
var sol: XRController3D
var sag: XRController3D
var panel: MeshInstance3D
var panel_vp: SubViewport
var isin: MeshInstance3D
var karart: MeshInstance3D
var _karart_mat: StandardMaterial3D
var masa: Node3D
var koltuk := 2
var _dinamik_yon := 0.0
var _gecis := false
var _cubuk_bekle := 0.0
var _imlec := Vector2(-1, -1)
var _tetik_onceki := false
var _afis_t := 0.0

static func baslat(ana_dugum: Node3D) -> VR:
	var x := XRServer.find_interface("OpenXR")
	if x == null or not x.is_initialized(): return null
	var v := VR.new()
	v.ana = ana_dugum
	v.xr = x
	ana_dugum.add_child(v)
	v._kur()
	return v

func _kur() -> void:
	var vp := get_viewport()
	vp.use_xr = true
	vp.msaa_3d = Viewport.MSAA_2X
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	if xr is OpenXRInterface:
		var ox := xr as OpenXRInterface
		ox.foveation_level = 3
		ox.foveation_dynamic = true
		var hz := ox.get_available_display_refresh_rates()
		if hz.has(72.0): ox.display_refresh_rate = 72.0
	koken = XROrigin3D.new(); add_child(koken)
	kafa = XRCamera3D.new(); kafa.near = .05; kafa.far = 900; koken.add_child(kafa)
	kafa.current = true
	sol = XRController3D.new(); sol.tracker = "left_hand"; koken.add_child(sol)
	sag = XRController3D.new(); sag.tracker = "right_hand"; koken.add_child(sag)
	for c in [sol, sag]:
		var el := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(.04, .03, .12)
		el.mesh = bm; el.material_override = _duz(Color("#1f3b3c")); c.add_child(el)
	sag.button_pressed.connect(_sag_bas)
	sol.button_pressed.connect(_sol_bas)
	# kararma perdesi (kafaya bağlı)
	karart = MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(2, 2); karart.mesh = q
	_karart_mat = StandardMaterial3D.new(); _karart_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_karart_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; _karart_mat.albedo_color = Color(0, 0, 0, 0)
	_karart_mat.no_depth_test = true; _karart_mat.render_priority = 100
	karart.material_override = _karart_mat; karart.position = Vector3(0, 0, -.1); karart.visible = false
	kafa.add_child(karart)
	# menü / tabela paneli: ana arayüz bir SubViewport'a taşınır
	panel_vp = SubViewport.new(); panel_vp.size = Vector2i(1280, 720); panel_vp.transparent_bg = true
	panel_vp.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	panel_vp.gui_embed_subwindows = true
	add_child(panel_vp)
	arayuz = ana.ui
	arayuz.get_parent().remove_child(arayuz)
	panel_vp.add_child(arayuz)
	panel = MeshInstance3D.new(); var pq := QuadMesh.new(); pq.size = Vector2(1.6, .9); panel.mesh = pq
	var pm := StandardMaterial3D.new(); pm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; pm.albedo_texture = panel_vp.get_texture()
	pm.no_depth_test = true; pm.render_priority = 50
	panel.material_override = pm
	add_child(panel)
	# lazer işaretçi
	isin = MeshInstance3D.new(); var cm := CylinderMesh.new(); cm.top_radius = .003; cm.bottom_radius = .003; cm.height = 1
	isin.mesh = cm; isin.material_override = _duz(Color("#f3d35a")); isin.rotation.x = -PI / 2; isin.position = Vector3(0, 0, -.5)
	sag.add_child(isin)
	# maket masası
	masa = Node3D.new(); add_child(masa)
	var tm := MeshInstance3D.new(); var cy := CylinderMesh.new(); cy.top_radius = 1.45; cy.bottom_radius = 1.45; cy.height = .06
	tm.mesh = cy; tm.material_override = _std(Color("#3a2a1e"), .6); tm.position = Vector3(0, .74, -1.55); masa.add_child(tm)
	var ay := MeshInstance3D.new(); var ac := CylinderMesh.new(); ac.top_radius = .12; ac.bottom_radius = .3; ac.height = .72
	ay.mesh = ac; ay.material_override = _std(Color("#2a1e16"), .7); ay.position = Vector3(0, .36, -1.55); masa.add_child(ay)
	ana.bilgi.text = "Sol çubuk: koş (baktığın yöne) · Sağ tetik / A: pas · B / sağ kavrama: şut · kay · Sağ çubuk sola/sağa ya da sol X: koltuk · Sol menü / Y: menü"
	ana.sec_kam.clear()
	for k in KOLTUKLAR: ana.sec_kam.add_item(k)
	ana.sec_kam.item_selected.connect(func(i): koltuga_gec(i))
	koltuga_gec(ana.vr_koltuk, true)
	ana.sec_kam.select(koltuk)
	panel_goster(true)

static func _duz(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED; m.albedo_color = c
	return m
static func _std(c: Color, r: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = r
	return m

# ---------- koltuklar ----------
func _koltuk_yeri(i: int) -> Array:
	# [konum (gerçek boy dünya), bakılacak nokta]
	var M = ana.M
	var yon := 1.0 if (M == null or M.goal_y_of(0) == 0.0) else -1.0   # ev sahibi -Z'ye (y=0) hücum ediyorsa +1
	match i:
		1: return [Vector3(36.0, 0, 0), Vector3(0, 0, 0)]
		2: return [Vector3(53.0, 18.0, 0), Vector3(0, 0, 0)]
		3: return [Vector3(0, 13.0, yon * 68.0), Vector3(0, 0, -yon * 10.0)]
		4: return [Vector3(46.0, 21.0, 66.0), Vector3(0, 0, 8.0)]
		5: return [Vector3(62.5, 13.6, -14.0), Vector3(0, 0, -6.0)]
	return [Vector3.ZERO, Vector3(0, 0, -1)]

func koltuga_gec(i: int, hemen := false) -> void:
	if _gecis and not hemen: return
	i = posmod(i, KOLTUKLAR.size())
	if hemen:
		_uygula(i); return
	_gecis = true
	karart.visible = true
	var tw := create_tween()
	tw.tween_property(_karart_mat, "albedo_color:a", 1.0, .22)
	tw.tween_callback(_uygula.bind(i))
	tw.tween_interval(.08)
	tw.tween_property(_karart_mat, "albedo_color:a", 0.0, .28)
	tw.tween_callback(func(): karart.visible = false; _gecis = false)

func _uygula(i: int) -> void:
	koltuk = i
	ana.set("vr_koltuk", i)
	var dunya: Node3D = ana.dunya
	var isik: DirectionalLight3D = ana.gunes
	if i == 0:
		dunya.scale = Vector3.ONE * MAKET_OLCEK
		dunya.position = Vector3(0, .78, -1.55)
		masa.visible = true
		koken.global_transform = Transform3D.IDENTITY
		isik.directional_shadow_max_distance = 5.0
	else:
		dunya.scale = Vector3.ONE; dunya.position = Vector3.ZERO
		masa.visible = false
		var k := _koltuk_yeri(i)
		var poz: Vector3 = k[0]; var bak: Vector3 = k[1]
		var ileri := Vector3(bak.x - poz.x, 0, bak.z - poz.z).normalized()
		koken.global_transform = Transform3D(Basis.looking_at(ileri, Vector3.UP), poz)
		isik.directional_shadow_max_distance = 70.0
		ana.stad.koltuk_bosalt(poz, 1.4)
	if ana.M: _dinamik_yon = ana.M.goal_y_of(0)
	ana.afis_goster("KOLTUK", KOLTUKLAR[i], 1.0)

# ---------- panel ----------
func panel_goster(v: bool) -> void:
	panel.visible = v
	if not v: return
	# panel kafanın baktığı yöne, göz hizasının biraz altına, 1.7 m öteye kurulur (sonra yerinde kalır)
	var t := kafa.global_transform
	var ileri := -t.basis.z; ileri.y = 0; ileri = ileri.normalized()
	var p := t.origin + ileri * 1.7 + Vector3(0, -.15, 0)
	panel.global_transform = Transform3D(Basis.looking_at(-ileri, Vector3.UP), p)

# ---------- girdi ----------
func girdi(M) -> void:
	# sol çubuk: baktığın yöne göre koş
	var v := sol.get_vector2("primary")
	if v.length() < .15: v = Vector2.ZERO
	var b := kafa.global_basis
	var sag_y := b.x; sag_y.y = 0; sag_y = sag_y.normalized()
	var ileri := -b.z; ileri.y = 0; ileri = ileri.normalized()
	var w := sag_y * v.x + ileri * v.y
	if w.length() > 1: w = w.normalized()
	M.giris.x = w.x; M.giris.y = w.z

func _sag_bas(ad: String) -> void:
	var M = ana.M
	if ana.menu_acik: return
	match ad:
		"trigger_click", "ax_button": if M: M.giris.pasE = true
		"by_button", "grip_click": if M: M.giris.sutE = true

func _sol_bas(ad: String) -> void:
	match ad:
		"menu_button", "by_button":
			if ana.M and not ana.M.demo: ana.menu_goster(not ana.menu_acik)
		"ax_button": koltuga_gec(koltuk + 1)

func _process(dt: float) -> void:
	# sağ çubuk sola/sağa: koltuk değiştir
	_cubuk_bekle -= dt
	var rs := sag.get_vector2("primary")
	if absf(rs.x) > .7 and _cubuk_bekle <= 0 and not ana.menu_acik:
		koltuga_gec(koltuk + (1 if rs.x > 0 else -1)); _cubuk_bekle = .6
	# devre arası: Dinamik koltuk takımın yeni hücum yönüne geçer
	if koltuk == 3 and ana.M and ana.M.goal_y_of(0) != _dinamik_yon: koltuga_gec(3)
	# panel: menü açıkken ya da afiş varken görünür
	var gerek: bool = ana.menu_acik or ana.afis_gorunur()
	if gerek and not panel.visible: panel_goster(true)
	elif not gerek and panel.visible: panel.visible = false
	isin.visible = ana.menu_acik and panel.visible
	if isin.visible: _isaretci()

func _isaretci() -> void:
	var o := sag.global_position
	var d := -sag.global_basis.z
	var pt := panel.global_transform
	var n := pt.basis.z
	var den := n.dot(d)
	if absf(den) < 1e-4: return
	var t := n.dot(pt.origin - o) / den
	if t <= 0 or t > 6: return
	var hit := o + d * t
	var yerel := pt.affine_inverse() * hit
	var uv := Vector2(yerel.x / 1.6 + .5, .5 - yerel.y / .9)
	var basil := sag.is_button_pressed("trigger_click")
	if uv.x < 0 or uv.x > 1 or uv.y < 0 or uv.y > 1:
		_tetik_onceki = basil; return
	var px := uv * Vector2(panel_vp.size)
	var mm := InputEventMouseMotion.new(); mm.position = px; mm.global_position = px
	panel_vp.push_input(mm)
	if basil != _tetik_onceki:
		var mb := InputEventMouseButton.new(); mb.button_index = MOUSE_BUTTON_LEFT; mb.pressed = basil
		mb.position = px; mb.global_position = px
		panel_vp.push_input(mb)
	_tetik_onceki = basil
	isin.scale = Vector3(1, t, 1); isin.position = Vector3(0, 0, -t / 2)
