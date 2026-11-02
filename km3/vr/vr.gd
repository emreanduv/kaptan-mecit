# Kaptan Mecit 3 — VR (Meta Quest, OpenXR): mide bulandırmayan düzen.
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
var _takip_t := 1.0

static func baslat(ana_dugum: Node3D, sahte := false) -> VR:
	var x := XRServer.find_interface("OpenXR")
	if not sahte and (x == null or not x.is_initialized()): return null
	var v := VR.new()
	v.ana = ana_dugum
	v.xr = x
	ana_dugum.add_child(v)
	v._kur()
	return v

func _kur() -> void:
	var vp := get_viewport()
	vp.use_xr = xr != null and xr.is_initialized()
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
	if not vp.use_xr: kafa.position = Vector3(0, 1.2, 0)   # masaüstü denemesi: oturan göz yüksekliği
	sol = XRController3D.new(); sol.tracker = "left_hand"; koken.add_child(sol)
	sag = XRController3D.new(); sag.tracker = "right_hand"; sag.pose = "aim"; koken.add_child(sag)
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
	# menü ve afiş: doğrudan 3B yazı (Label3D) — panel dokusuna, lazere ya da açılır pencereye bağlı değil
	_menu3d_kur()
	ana.ui.visible = false   # 2B arayüz gözlükte çizilmez; menü ve afiş 3B
	# maket masası
	masa = Node3D.new(); add_child(masa)
	var tm := MeshInstance3D.new(); var cy := CylinderMesh.new(); cy.top_radius = 1.45; cy.bottom_radius = 1.45; cy.height = .06
	tm.mesh = cy; tm.material_override = _std(Color("#3a2a1e"), .6); tm.position = Vector3(0, .74, -1.55); masa.add_child(tm)
	var ay := MeshInstance3D.new(); var ac := CylinderMesh.new(); ac.top_radius = .12; ac.bottom_radius = .3; ac.height = .72
	ay.mesh = ac; ay.material_override = _std(Color("#2a1e16"), .7); ay.position = Vector3(0, .36, -1.55); masa.add_child(ay)
	ana.bilgi.text = "Menü: lazerle seç, tetikle bas · A: maça başla   ·   Maçta: sol çubuk koş (baktığın yöne) · Sağ tetik / A: pas · B / sağ kavrama: şut · kay · Sağ çubuk sola/sağa ya da sol X: koltuk · Sol menü / Y: menü"
	ana.sec_kam.clear()
	for k in KOLTUKLAR: ana.sec_kam.add_item(k)
	ana.sec_kam.item_selected.connect(func(i): koltuga_gec(i))
	koltuga_gec(ana.vr_koltuk, true)
	ana.sec_kam.select(koltuk)
	menu3d_yerlestir()

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
	if ana.menu_acik:
		if ad == "ax_button" or ad == "trigger_click": ana.basla()     # menüde A / tetik: seçili takımlarla maça başla
		return
	match ad:
		"trigger_click", "ax_button": if M: M.giris.pasE = true
		"by_button", "grip_click": if M: M.giris.sutE = true

func _sol_bas(ad: String) -> void:
	match ad:
		"menu_button", "by_button":
			if ana.M and not ana.M.demo:
				ana.menu_goster(not ana.menu_acik)
				if ana.menu_acik: menu3d_yerlestir()
		"ax_button": koltuga_gec(koltuk + 1)

func _process(dt: float) -> void:
	_cubuk_bekle -= dt
	var rs := sag.get_vector2("primary")
	var ls := sol.get_vector2("primary")
	if ana.menu_acik:
		# menü: herhangi bir çubukla yukarı/aşağı satır, sola/sağa değer
		var v := rs if rs.length() > ls.length() else ls
		if _cubuk_bekle <= 0 and v.length() > .7:
			if absf(v.y) > absf(v.x): _satir = posmod(_satir + (-1 if v.y > 0 else 1), SATIRLAR.size())
			else: _deger(1 if v.x > 0 else -1)
			_cubuk_bekle = .28
		elif v.length() < .3: _cubuk_bekle = minf(_cubuk_bekle, 0.0)
		_takip_t -= dt
		if _takip_t <= 0: _takip_t = .5; _menu_takip()
	elif absf(rs.x) > .7 and _cubuk_bekle <= 0:
		koltuga_gec(koltuk + (1 if rs.x > 0 else -1)); _cubuk_bekle = .6
	# devre arası: Dinamik koltuk takımın yeni hücum yönüne geçer
	if koltuk == 3 and ana.M and ana.M.goal_y_of(0) != _dinamik_yon: koltuga_gec(3)
	menu3d.visible = ana.menu_acik
	if menu3d.visible: _menu_ciz()
	afis3d.visible = ana.afis_gorunur() and not ana.menu_acik
	if afis3d.visible:
		afis3d.text = ana.afis_ust.text + ("\n" + ana.afis_alt.text if ana.afis_alt.text != "" else "")

# ---------- 3B menü ----------
const SATIRLAR := ["Lig", "Senin takımın", "Rakip", "Diziliş", "Süre", "Zorluk", "Koltuk", "MAÇA BAŞLA"]
const SURUM := "0.1.0"
var menu3d: Node3D
var _menu_satirlar: Array = []
var _satir := 7
var afis3d: Label3D

func _yazi(boy: int, renk: Color) -> Label3D:
	var l := Label3D.new(); l.font_size = boy; l.pixel_size = .0011; l.modulate = renk
	l.outline_size = 0; l.shaded = false; l.double_sided = true; l.no_depth_test = true; l.render_priority = 60
	l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	return l

func _menu3d_kur() -> void:
	menu3d = Node3D.new(); koken.add_child(menu3d)
	var zemin := MeshInstance3D.new(); var q := QuadMesh.new(); q.size = Vector2(1.5, 1.12); zemin.mesh = q
	var zm := StandardMaterial3D.new(); zm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	zm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA; zm.albedo_color = Color(0.05, 0.1, 0.11, .95)
	zm.no_depth_test = true; zm.render_priority = 55; zm.cull_mode = BaseMaterial3D.CULL_DISABLED
	zemin.material_override = zm; menu3d.add_child(zemin)
	var bas := _yazi(96, Color.WHITE); bas.text = "Kaptan Mecit 3"; bas.position = Vector3(0, .44, .001); menu3d.add_child(bas)
	var imza := _yazi(36, Color("#cfe3d6")); imza.text = "Bir Mr. Anduv! yapımıdır.  ·  sürüm " + SURUM; imza.position = Vector3(0, .36, .001); menu3d.add_child(imza)
	for i in SATIRLAR.size():
		var l := _yazi(52, Color.WHITE); l.position = Vector3(0, .25 - i * .085, .001); menu3d.add_child(l)
		_menu_satirlar.append(l)
	var ipucu := _yazi(32, Color(1, 1, 1, .75))
	ipucu.text = "Çubuk yukarı/aşağı: satır  ·  sola/sağa: değiştir  ·  A ya da tetik: MAÇA BAŞLA"
	ipucu.position = Vector3(0, -.45, .001); menu3d.add_child(ipucu)
	afis3d = _yazi(72, Color("#f3d35a")); afis3d.visible = false
	koken.add_child(afis3d)

func _secici(i: int) -> Secici:
	return [ana.sec_lig, ana.sec_ev, ana.sec_dep, ana.sec_dz, ana.sec_sure, ana.sec_zor, ana.sec_kam][i] if i < 7 else null

func _deger(d: int) -> void:
	var s := _secici(_satir)
	if s: s.kay(d)

func _menu_ciz() -> void:
	for i in SATIRLAR.size():
		var l: Label3D = _menu_satirlar[i]
		var s := _secici(i)
		var sec := i == _satir
		if s: l.text = ("‹  " if sec else "") + SATIRLAR[i] + ":  " + s.metin() + ("  ›" if sec else "")
		else: l.text = ("▶  " if sec else "") + SATIRLAR[i]
		l.modulate = Color("#f3d35a") if sec else (Color("#e5722f") if s == null else Color.WHITE)

func menu3d_yerlestir() -> void:
	var t := kafa.transform
	var ileri := -t.basis.z; ileri.y = 0
	ileri = ileri.normalized() if ileri.length() > .1 else Vector3.FORWARD
	var goz := t.origin if t.origin.y > .3 else Vector3(0, 1.2, 0)
	menu3d.transform = Transform3D(Basis.looking_at(ileri, Vector3.UP), goz + ileri * 1.5 + Vector3(0, -.08, 0))
	afis3d.transform = Transform3D(Basis.looking_at(ileri, Vector3.UP), goz + ileri * 2.4 + Vector3(0, .25, 0))

func _menu_takip() -> void:
	var ileri := -kafa.transform.basis.z; ileri.y = 0
	if ileri.length() < .1: return
	var yon := menu3d.transform.origin - kafa.transform.origin; yon.y = 0
	if yon.length() < .1 or ileri.normalized().angle_to(yon.normalized()) > deg_to_rad(50) or yon.length() > 3.0:
		menu3d_yerlestir()
