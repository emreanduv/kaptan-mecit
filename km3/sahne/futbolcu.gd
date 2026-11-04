# Kaptan Mecit 3 — iskeletli futbolcu (tamamen kendi üretimimiz; dış model / lisans yok).
# Gövde, uzuvlar ve baş yordamsal üretilir; köşelere renk bölgesi işlenir (forma, şerit, şort, tozluk, krampon, ten, saç, eldiven).
# Hareketler motorun oyuncu durumundan üretilir: koşu/depar, nefes, kaleci hazır duruşu ve uçuşu, şut, kayma, düşme, gol sevinci.
extends Node3D
class_name Futbolcu

const KEMIK := ["kok", "kalca", "bel", "gogus", "boyun", "bas", "omuzL", "dirsekL", "omuzR", "dirsekR", "bacakL", "dizL", "bilekL", "bacakR", "dizR", "bilekR"]
const BAG := {
	"kok": Vector3(0, 0, 0), "kalca": Vector3(0, .95, 0), "bel": Vector3(0, 1.08, 0), "gogus": Vector3(0, 1.28, 0), "boyun": Vector3(0, 1.5, 0), "bas": Vector3(0, 1.6, 0),
	"omuzL": Vector3(-.2, 1.44, 0), "dirsekL": Vector3(-.23, 1.15, 0), "omuzR": Vector3(.2, 1.44, 0), "dirsekR": Vector3(.23, 1.15, 0),
	"bacakL": Vector3(-.095, .93, 0), "dizL": Vector3(-.1, .5, .01), "bilekL": Vector3(-.1, .085, 0),
	"bacakR": Vector3(.095, .93, 0), "dizR": Vector3(.1, .5, .01), "bilekR": Vector3(.1, .085, 0)}
const EBEVEYN := {"kalca": "kok", "bel": "kalca", "gogus": "bel", "boyun": "gogus", "bas": "boyun", "omuzL": "gogus", "dirsekL": "omuzL",
	"omuzR": "gogus", "dirsekR": "omuzR", "bacakL": "kalca", "dizL": "bacakL", "bilekL": "dizL", "bacakR": "kalca", "dizR": "bacakR", "bilekR": "dizR"}

# ---------- taban geometri (bir kez üretilir, tüm futbolcular paylaşır) ----------
static var _taban: Dictionary = {}
static var hafif := false   # Quest / telefon: daha az üçgen

static func _k(ad: String) -> int: return KEMIK.find(ad)

class Yapici:
	var pos := PackedVector3Array()
	var nor := PackedVector3Array()
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	var bolge := PackedByteArray()
	var idx := PackedInt32Array()
	# kemik: String ya da Callable(v) -> [[ad, ağırlık], ...]; bolge: int ya da Callable(v) -> int
	func ekle(v: PackedVector3Array, n: PackedVector3Array, ix: PackedInt32Array, kemik, bolge_f) -> void:
		var taban := pos.size()
		for i in v.size():
			var p := v[i]
			pos.append(p); nor.append(n[i])
			var kb: Array = kemik.call(p) if kemik is Callable else [[kemik, 1.0]]
			var t := 0.0
			for j in 4:
				if j < kb.size(): t += kb[j][1]
			if t == 0: t = 1
			for j in 4:
				if j < kb.size():
					bones.append(Futbolcu._k(kb[j][0])); weights.append(kb[j][1] / t)
				else:
					bones.append(0); weights.append(0.0)
			bolge.append(bolge_f.call(p) if bolge_f is Callable else bolge_f)
		for k in ix: idx.append(taban + k)

# küre (enlem-boylam), ölçek ve öteleme ile
static func _kure(r: float, seg: int, hs: int, olcek := Vector3.ONE, oteleme := Vector3.ZERO) -> Array:
	var v := PackedVector3Array(); var n := PackedVector3Array(); var ix := PackedInt32Array()
	for y in hs + 1:
		var th := PI * y / hs
		for x in seg + 1:
			var ph := TAU * x / seg
			var d := Vector3(-cos(ph) * sin(th), cos(th), sin(ph) * sin(th))
			v.append(d * r * olcek + oteleme); n.append((d / olcek).normalized())
	for y in hs:
		for x in seg:
			var a := y * (seg + 1) + x; var b := a + seg + 1
			ix.append_array([a, a + 1, b, b, a + 1, b + 1])
	return [v, n, ix]

# a'dan b'ye konik silindir (uçları ayrı küreler kapatır)
static func _silindir(a: Vector3, b: Vector3, r0: float, r1: float, seg: int, hs := 0) -> Array:
	if hs <= 0: hs = 6 if hafif else 14
	if hafif: seg = maxi(6, seg - 2)
	var v := PackedVector3Array(); var n := PackedVector3Array(); var ix := PackedInt32Array()
	var yon := (b - a).normalized()
	var ref := Vector3.FORWARD if absf(yon.y) > .9 else Vector3.UP
	var u := yon.cross(ref).normalized(); var w := yon.cross(u).normalized()
	var egim := (r0 - r1) / maxf(.001, a.distance_to(b))
	for y in hs + 1:
		var t := float(y) / hs
		var c := a.lerp(b, t); var r := lerpf(r0, r1, t)
		for x in seg + 1:
			var ph := TAU * x / seg
			var rad := u * cos(ph) + w * sin(ph)
			v.append(c + rad * r); n.append((rad + yon * egim).normalized())
	for y in hs:
		for x in seg:
			var i0 := y * (seg + 1) + x; var i1 := i0 + seg + 1
			ix.append_array([i0, i1, i0 + 1, i0 + 1, i1, i1 + 1])
	return [v, n, ix]

static func _kapsul(Y: Yapici, a: Vector3, b: Vector3, r0: float, r1: float, kemik, bolge, seg := 10) -> void:
	var s := _silindir(a, b, r0, r1, seg)
	Y.ekle(s[0], s[1], s[2], kemik, bolge)
	var k0 := _kure(r0, seg, 6, Vector3.ONE, a); Y.ekle(k0[0], k0[1], k0[2], kemik, bolge)
	var k1 := _kure(r1, seg, 6, Vector3.ONE, b); Y.ekle(k1[0], k1[1], k1[2], kemik, bolge)

static func _kutu(boyut: Vector3, merkez: Vector3) -> Array:
	var v := PackedVector3Array(); var n := PackedVector3Array(); var ix := PackedInt32Array()
	var h := boyut / 2
	for ax in 3:
		for sg in [-1.0, 1.0]:
			var nn := Vector3.ZERO; nn[ax] = sg
			var u := Vector3.ZERO; u[(ax + 1) % 3] = 1
			var w := Vector3.ZERO; w[(ax + 2) % 3] = 1
			var c := merkez + nn * h[ax]
			var b0 := v.size()
			for q in [[-1, -1], [1, -1], [1, 1], [-1, 1]]:
				v.append(c + u * h[(ax + 1) % 3] * q[0] + w * h[(ax + 2) % 3] * q[1]); n.append(nn)
			if sg > 0: ix.append_array([b0, b0 + 1, b0 + 2, b0, b0 + 2, b0 + 3])
			else: ix.append_array([b0, b0 + 2, b0 + 1, b0, b0 + 3, b0 + 2])
	return [v, n, ix]

static func _taban_uret() -> void:
	var Y := Yapici.new()
	# gövde: profil boyunca eliptik kesit
	var prof := [[.86, .15], [.95, .165], [.965, .163], [.975, .161], [1.05, .15], [1.18, .165], [1.3, .195], [1.4, .205], [1.46, .19], [1.5, .1]]
	var v := PackedVector3Array(); var n := PackedVector3Array(); var ix := PackedInt32Array()
	var seg := 14
	for i in prof.size():
		var yy: float = prof[i][0]; var r: float = prof[i][1]
		var dr := 0.0
		if i > 0 and i < prof.size() - 1: dr = (prof[i + 1][1] - prof[i - 1][1]) / (prof[i + 1][0] - prof[i - 1][0])
		for x in seg + 1:
			var ph := TAU * x / seg
			var d := Vector3(sin(ph), 0, cos(ph))
			v.append(Vector3(d.x * r, yy, d.z * r * .66)); n.append(Vector3(d.x, -dr * .6, d.z / .66).normalized())
	for i in prof.size() - 1:
		for x in seg:
			var a := i * (seg + 1) + x; var b := a + seg + 1
			ix.append_array([a, b, a + 1, a + 1, b, b + 1])
	var govde_kemik := func(p: Vector3) -> Array:
		var yy := p.y
		if yy < 1.0: return [["kalca", 1.0]]
		if yy < 1.12: return [["kalca", (1.12 - yy) / .12], ["bel", (yy - 1.0) / .12]]
		if yy < 1.26: return [["bel", (1.26 - yy) / .14], ["gogus", (yy - 1.12) / .14]]
		return [["gogus", 1.0]]
	var govde_bolge := func(p: Vector3) -> int:
		if p.y < .97: return 2
		if p.y > 1.45 and absf(p.x) < .06 and p.z > 0: return 1
		return 0
	Y.ekle(v, n, ix, govde_kemik, govde_bolge)
	_kapsul(Y, Vector3(0, 1.48, 0), Vector3(0, 1.6, 0), .055, .05, "boyun", 5, 8)
	var bas := _kure(.11, 14, 10, Vector3(.9, 1.08, 1), Vector3(0, 1.7, .005))
	Y.ekle(bas[0], bas[1], bas[2], "bas", func(p: Vector3) -> int: return 6 if (p.y > 1.735 or (p.z < -.03 and p.y > 1.62)) else 5)
	for sx in [-1.0, 1.0]:
		var kul := _kure(.025, 6, 4, Vector3.ONE, Vector3(.1 * sx, 1.69, 0)); Y.ekle(kul[0], kul[1], kul[2], "bas", 5)
	for t in [[-1.0, "omuzL", "dirsekL"], [1.0, "omuzR", "dirsekR"]]:
		var s: float = t[0]
		_kapsul(Y, Vector3(s * .2, 1.44, 0), Vector3(s * .23, 1.15, 0), .062, .05, t[1], func(p: Vector3) -> int: return 0 if p.y > 1.3 else 7, 8)
		_kapsul(Y, Vector3(s * .23, 1.15, 0), Vector3(s * .245, .9, .02), .046, .035, t[2], 7, 8)
		var el := _kure(.045, 8, 6, Vector3(.8, 1.2, .6), Vector3(s * .25, .85, .025)); Y.ekle(el[0], el[1], el[2], t[2], 7)
	for t in [[-1.0, "bacakL", "dizL", "bilekL"], [1.0, "bacakR", "dizR", "bilekR"]]:
		var s: float = t[0]
		_kapsul(Y, Vector3(s * .095, .93, 0), Vector3(s * .1, .5, .01), .088, .058, t[1], func(p: Vector3) -> int: return 2 if p.y > .7 else 5, 10)
		_kapsul(Y, Vector3(s * .1, .5, .01), Vector3(s * .1, .1, 0), .056, .038, t[2], func(p: Vector3) -> int: return 5 if p.y > .44 else 3, 10)
		var ay := _kutu(Vector3(.1, .075, .26), Vector3(s * .1, .04, .055)); Y.ekle(ay[0], ay[1], ay[2], t[3], 4)
	_taban = {"Y": Y}

# ---------- örnek ----------
var iskelet: Skeleton3D
var govde: MeshInstance3D
var yaw := 0.0
var faz := randf() * 6.0
var _e: Array = []   # kemik başına Euler (XYZ)
var _kok_y := 0.0

static func _malzeme() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.vertex_color_use_as_albedo = true
	m.roughness = .78
	return m

static var _mat: StandardMaterial3D = null

func kur(renk: Dictionary, no: int, boy := 1.0) -> Futbolcu:
	if _taban.is_empty(): _taban_uret()
	if _mat == null: _mat = _malzeme()
	var Y: Yapici = _taban.Y
	var R := [renk.forma, renk.serit, renk.sort, renk.tozluk, "#151515", renk.ten, renk.sac, renk.get("eldiven", renk.ten)]
	var C: Array = []
	for c in R: C.append(Color(c if c != null else renk.ten))
	var col := PackedColorArray(); col.resize(Y.bolge.size())
	for i in Y.bolge.size(): col[i] = C[Y.bolge[i]]
	var a := []; a.resize(Mesh.ARRAY_MAX)
	a[Mesh.ARRAY_VERTEX] = Y.pos; a[Mesh.ARRAY_NORMAL] = Y.nor; a[Mesh.ARRAY_COLOR] = col
	a[Mesh.ARRAY_BONES] = Y.bones; a[Mesh.ARRAY_WEIGHTS] = Y.weights; a[Mesh.ARRAY_INDEX] = Y.idx
	var mesh := ArrayMesh.new()
	mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, a)
	mesh.surface_set_material(0, _mat)
	iskelet = Skeleton3D.new()
	add_child(iskelet)
	for k in KEMIK: iskelet.add_bone(k)
	for k in KEMIK:
		var i := _k(k)
		if EBEVEYN.has(k):
			iskelet.set_bone_parent(i, _k(EBEVEYN[k]))
			iskelet.set_bone_rest(i, Transform3D(Basis(), BAG[k] - BAG[EBEVEYN[k]]))
		else:
			iskelet.set_bone_rest(i, Transform3D(Basis(), BAG[k]))
	iskelet.reset_bone_poses()
	govde = MeshInstance3D.new()
	govde.mesh = mesh
	iskelet.add_child(govde)
	govde.skeleton = NodePath("..")
	govde.skin = iskelet.create_skin_from_rest_transforms()
	govde.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
	govde.extra_cull_margin = 2.0
	# sırt numarası
	var ba := BoneAttachment3D.new()
	ba.bone_name = "gogus"
	iskelet.add_child(ba)
	var lab := Label3D.new()
	lab.text = str(no)
	lab.font_size = 64
	lab.pixel_size = .0026
	lab.outline_size = 0
	var fc := Color(renk.forma)
	lab.modulate = Color("#141414") if fc.get_luminance() > .6 else Color("#f4f4f4")
	lab.position = Vector3(0, .1, -.138)
	lab.rotation = Vector3(0, PI, 0)
	lab.double_sided = false
	lab.shaded = true
	ba.add_child(lab)
	scale = Vector3.ONE * boy
	_e.resize(KEMIK.size())
	return self

func _sifirla() -> void:
	for i in _e.size(): _e[i] = Vector3.ZERO
	_kok_y = 0.0

func _r(ad: String) -> Vector3: return _e[_k(ad)]
func _s(ad: String, v: Vector3) -> void: _e[_k(ad)] = v
func _x(ad: String, v: float) -> void: var e: Vector3 = _e[_k(ad)]; e.x = v; _e[_k(ad)] = e
func _y(ad: String, v: float) -> void: var e: Vector3 = _e[_k(ad)]; e.y = v; _e[_k(ad)] = e
func _z(ad: String, v: float) -> void: var e: Vector3 = _e[_k(ad)]; e.z = v; _e[_k(ad)] = e

func _uygula() -> void:
	_y("kok", yaw)
	for i in KEMIK.size():
		iskelet.set_bone_pose_rotation(i, Basis.from_euler(_e[i], EULER_ORDER_XYZ).get_rotation_quaternion())
	iskelet.set_bone_pose_position(0, Vector3(0, _kok_y, 0))

# motor oyuncusundan duruş: p = Mac.Oy, M = Mac
func _poz_yordamsal(p, M, now: float, gol_takim: int) -> void:
	var dx: float = p.dx; var dy: float = p.dy
	if dx != 0 or dy != 0:
		var t := atan2(dx, dy)
		var d := wrapf(t - yaw, -PI, PI)
		yaw += d * .3
	_sifirla()
	_z("omuzL", -.12); _z("omuzR", .12)
	var spd := sqrt(p.vx * p.vx + p.vy * p.vy)
	var a := clampf(spd / 7.5, 0, 1)
	var fz: float = p.anim * 3.9
	var sL := sin(fz); var sR := -sL
	if p.slide > 0 or p.stun > .3:
		var kay: bool = p.slide > 0
		_kok_y = .16 if kay else .12
		_x("kalca", -1.25 if kay else -1.5)
		_x("bacakR", -.25 if kay else .1); _x("dizR", .08 if kay else .4); _x("bacakL", .35 if kay else .2); _x("dizL", 1.1 if kay else .5)
		_s("omuzL", Vector3(-.6, 0, -1.0)); _s("omuzR", Vector3(-.2, 0, 1.1)); _x("dirsekL", -.5); _x("bas", .6 if kay else .3)
		_uygula(); return
	var kaleci: bool = p.role == "G"
	if kaleci and p.ucus > 0:
		_kaleci_ucus(p, M); return
	var top = M.ball
	var top_yakin := sqrt((top.x - p.x) ** 2 + (top.y - p.y) ** 2)
	var adim := .12 + .78 * a
	_x("bacakL", -sL * adim); _x("bacakR", -sR * adim)
	_x("dizL", .06 + a * (.25 + 1.25 * maxf(0, sin(fz - 1.2))))
	_x("dizR", .06 + a * (.25 + 1.25 * maxf(0, sin(fz + PI - 1.2))))
	_x("bilekL", -.25 * a * maxf(0, -sL)); _x("bilekR", -.25 * a * maxf(0, -sR))
	_y("kalca", sL * .12 * a); _y("gogus", -sL * .18 * a); _x("bel", .06 + .22 * a); _x("bas", -.18 * a)
	_x("omuzL", sL * (.18 + .75 * a)); _x("omuzR", sR * (.18 + .75 * a))
	_x("dirsekL", -(.25 + 1.2 * a)); _x("dirsekR", -(.25 + 1.2 * a))
	_kok_y = absf(cos(fz)) * .055 * a - .02 * a
	if spd < .5:
		var n := sin(now / .9 + faz)
		_x("gogus", .02 * n); _z("kalca", .02 * sin(now / 1.6 + faz))
		_x("dirsekL", -.15); _x("dirsekR", -.15)
	if kaleci and p.dive == 1 and spd > 2:
		# plonjon: hareket yönüne yana uzanır
		var yan := signf(p.vx * cos(yaw) - p.vy * sin(yaw))
		_z("kok", -yan * .9); _kok_y = .25
		_s("omuzL", Vector3(-.2, 0, -2.6)); _s("omuzR", Vector3(-.2, 0, 2.6))
	elif kaleci and top_yakin < 22 and spd < 3:
		_kok_y = -.1; _x("bacakL", -.45); _x("bacakR", -.45); _x("dizL", .8); _x("dizR", .8); _x("bel", .35)
		_z("bacakL", -.12); _z("bacakR", .12); _s("omuzL", Vector3(-.9, 0, -.45)); _s("omuzR", Vector3(-.9, 0, .45)); _x("dirsekL", -.6); _x("dirsekR", -.6)
	if top.kicker == p and p.cd > .1:
		var k := clampf((p.cd - .1) / .25, 0, 1)
		var sav := sin(k * PI)
		_x("bacakR", -1.35 * sav + .5 * (1 - k)); _x("dizR", .2 + .9 * (1 - k) * k * 2); _x("bacakL", .15); _x("dizL", .25)
		_s("omuzL", Vector3(-.3, 0, -.9)); _s("omuzR", Vector3(.4, 0, .3)); _x("bel", -.05); _y("gogus", .25 * sav)
	if gol_takim == p.team:
		_s("omuzL", Vector3(-2.8, 0, -.35)); _s("omuzR", Vector3(-2.8, 0, .35)); _x("dirsekL", -.2); _x("dirsekR", -.2); _x("bas", -.3)
	elif gol_takim >= 0:
		_x("bel", .45); _x("bas", .35); _x("omuzL", .1); _x("omuzR", .1)
	_uygula()

# kaleci kurtarışı: yükle → yana uç (kollar topa uzanır) → yere düş → kalk. Motor konumu iniş yerinde; görüntü oraya süzülür.
const UCUS_T := 1.5
func _kaleci_ucus(p, M) -> void:
	var fwd: float = M.fwd_of(p.team)
	yaw = 0.0 if fwd > 0 else PI
	if p.ucus_tur == 0:
		# göğüste tutma: çömel, kollar öne, top gövdeye
		var e: float = .7 - p.ucus
		var c := sin(clampf(e / .7, 0, 1) * PI)
		_kok_y = -.18 * c
		_x("bacakL", -.55 * c); _x("bacakR", -.55 * c); _x("dizL", 1.0 * c); _x("dizR", 1.0 * c); _x("bel", .45 * c); _x("bas", .2 * c)
		_s("omuzL", Vector3(-1.25, 0, -.25)); _s("omuzR", Vector3(-1.25, 0, .25)); _x("dirsekL", -1.3); _x("dirsekR", -1.3)
		_uygula(); return
	var e: float = UCUS_T - p.ucus
	var yuk := clampf(e / .12, 0, 1) * (1.0 - clampf((e - .12) / .08, 0, 1))      # kısa çömelme (yük alma)
	var k := smoothstep(.1, .5, e)                                                 # uçuş ilerleyişi
	var kalk := smoothstep(1.05, 1.5, e)                                           # kalkış
	var yuksek: float = clampf(p.ucus_z / 2.0, 0, 1)
	var aci := (1.5 - .45 * yuksek * (1.0 - smoothstep(.55, .75, e))) * k * (1.0 - kalk)   # yüksek topta havada dikçe, inişte yatay
	var s_: float = p.ucus_yan * (1.0 if fwd > 0 else -1.0)
	_z("kok", -s_ * aci)
	var kemer := sin(clampf((e - .1) / .5, 0, 1) * PI) * (.35 + .55 * yuksek)    # havadaki yay
	_kok_y = -.14 * yuk + (.16 * k + kemer) * (1.0 - kalk)        # kök ayak hizasında: yan yatınca gövde yerden ~16 cm
	# kollar başın üstünden topa uzanır, alttaki kol hafif bükük
	var kol := maxf(k, yuk * .4) * (1.0 - kalk)
	_s("omuzL", Vector3(-.25 * kol, 0, -2.75 * kol - .12)); _s("omuzR", Vector3(-.25 * kol, 0, 2.75 * kol + .12))
	_x("dirsekL", -.15); _x("dirsekR", -.15)
	_x("bas", -.15 * k)
	# bacaklar: üstteki bacak dizden bükük, alttaki uzanık
	_x("bacakL", -.2 * k - .5 * yuk); _x("bacakR", -.2 * k - .5 * yuk); _x("dizL", .2 + .7 * yuk + .5 * k * (1 if s_ < 0 else 0)); _x("dizR", .2 + .7 * yuk + .5 * k * (1 if s_ > 0 else 0))
	_z("bacakL", -.2 * k); _z("bacakR", .2 * k)
	if kalk > 0:
		_x("bel", .5 * sin(kalk * PI)); _x("dizL", .9 * sin(kalk * PI)); _x("dizR", .9 * sin(kalk * PI))
	# görüntü eski yerden iniş yerine süzülür
	var o: Vector2 = p.ucus_ofs * (1.0 - smoothstep(.1, .55, e))
	position += Vector3(o.x, 0, o.y)
	_uygula()

# =================== Kaptan Mecit 3: gerçek hareket (CMU hareket yakalama) ===================
# Yürüme / koşu / depar döngüleri ve vuruş, gerçek insan kayıtlarından bizim iskelete aktarıldı (araclar/mocap/donustur.py).
# Hıza göre iki komşu döngü harmanlanır; adım evresi oyuncunun gerçekten katettiği yola bağlıdır (ayak kaymaz).
static var _hareket: Dictionary = {}
var _evre := 0.0
var _son_yol := -1.0
var _q: Array = []

static func _hareket_yukle() -> void:
	if not _hareket.is_empty(): return
	var j = JSON.parse_string(FileAccess.get_file_as_string("res://veri/hareket.json"))
	if j == null: _hareket = {"yok": true}; return
	for ad in j.klipler:
		var k: Dictionary = j.klipler[ad]
		var kareler: Array = []
		for f in k.kare:
			var qs: Array = []
			for q in f: qs.append(Quaternion(q[0], q[1], q[2], q[3]))
			kareler.append(qs)
		k["Q"] = kareler
		_hareket[ad] = k

static func _ornek(k: Dictionary, evre: float, dongu := true) -> Array:
	var Q: Array = k.Q
	var n := Q.size()
	var x := evre * (n if dongu else n - 1)
	var i0 := int(floor(x)); var t := x - i0
	var a: Array = Q[posmod(i0, n) if dongu else clampi(i0, 0, n - 1)]
	var b: Array = Q[posmod(i0 + 1, n) if dongu else clampi(i0 + 1, 0, n - 1)]
	var r: Array = []
	for i in a.size(): r.append((a[i] as Quaternion).slerp(b[i], t))
	return r

static func _klip_kok(k: Dictionary, evre: float, dongu := true) -> float:
	var Y: Array = k.kok_y
	var n := Y.size()
	var x := evre * (n if dongu else n - 1)
	var i0 := int(floor(x)); var t := x - i0
	var a: float = Y[posmod(i0, n) if dongu else clampi(i0, 0, n - 1)]
	var b: float = Y[posmod(i0 + 1, n) if dongu else clampi(i0 + 1, 0, n - 1)]
	return lerpf(a, b, t)

func poz(p, M, now: float, gol_takim: int) -> void:
	_hareket_yukle()
	var spd := sqrt(p.vx * p.vx + p.vy * p.vy)
	var kaleci_hazir: bool = p.role == "G" and spd < 3 and sqrt((M.ball.x - p.x) ** 2 + (M.ball.y - p.y) ** 2) < 22
	var vuruyor: bool = M.ball.kicker == p and p.cd > .1
	# yere düşme, kayma, kaleci duruşu/uçuşu, gol sevinci ve duran oyuncu: el yapımı hareketler
	if _hareket.has("yok") or p.slide > 0 or p.stun > .3 or kaleci_hazir or (p.role == "G" and (p.dive == 1 or p.ucus > 0)) or spd < .45 and not vuruyor:
		_son_yol = p.anim
		_poz_yordamsal(p, M, now, gol_takim); return
	var dx: float = p.dx; var dy: float = p.dy
	if dx != 0 or dy != 0:
		yaw += wrapf(atan2(dx, dy) - yaw, -PI, PI) * .3
	var Y: Dictionary = _hareket.yuru; var K: Dictionary = _hareket.kos; var D: Dictionary = _hareket.depar
	var poz_q: Array; var ky := 0.0
	if vuruyor:
		var V: Dictionary = _hareket.vurus
		var k := 1.0 - clampf((p.cd - .1) / .25, 0, 1)                 # 0 → 1
		# motor topu temas anında bırakır: kısa bir kurulma + vuruş + takip gösterilir
		var ev: float = lerpf(float(V.temas) - .22, minf(1.0, float(V.temas) + .38), k)
		poz_q = _ornek(V, ev, false); ky = _klip_kok(V, ev, false)
	else:
		# hıza göre iki komşu döngü ve harman ağırlığı
		var a: Dictionary; var b: Dictionary; var w: float
		if spd < float(K.hiz): a = Y; b = K; w = clampf((spd - float(Y.hiz)) / (float(K.hiz) - float(Y.hiz)), 0, 1)
		else: a = K; b = D; w = clampf((spd - float(K.hiz)) / (float(D.hiz) - float(K.hiz)), 0, 1)
		var adim: float = lerpf(float(a.adim_boyu), float(b.adim_boyu), w)
		if spd > float(D.hiz): adim *= lerpf(1.0, 1.25, clampf((spd - float(D.hiz)) / 3.0, 0, 1))   # depar: daha uzun adım
		if _son_yol < 0: _son_yol = p.anim
		_evre = fposmod(_evre + maxf(0, p.anim - _son_yol) / adim, 1.0)
		var qa := _ornek(a, _evre); var qb := _ornek(b, _evre)
		poz_q = []
		for i in qa.size(): poz_q.append((qa[i] as Quaternion).slerp(qb[i], w))
		ky = lerpf(_klip_kok(a, _evre), _klip_kok(b, _evre), w)
	_son_yol = p.anim
	# kök: oyunun verdiği yön; diğer kemikler kayıttan
	iskelet.set_bone_pose_rotation(0, Quaternion(Vector3.UP, yaw))
	for i in range(1, KEMIK.size()): iskelet.set_bone_pose_rotation(i, poz_q[i])
	iskelet.set_bone_pose_position(0, Vector3(0, ky, 0))
	# gol sevinci koşarken: kollar havada
	if gol_takim == p.team:
		iskelet.set_bone_pose_rotation(_k("omuzL"), Basis.from_euler(Vector3(-2.8, 0, -.35), EULER_ORDER_XYZ).get_rotation_quaternion())
		iskelet.set_bone_pose_rotation(_k("omuzR"), Basis.from_euler(Vector3(-2.8, 0, .35), EULER_ORDER_XYZ).get_rotation_quaternion())
		iskelet.set_bone_pose_rotation(_k("dirsekL"), Quaternion(Vector3.RIGHT, -.2))
		iskelet.set_bone_pose_rotation(_k("dirsekR"), Quaternion(Vector3.RIGHT, -.2))
