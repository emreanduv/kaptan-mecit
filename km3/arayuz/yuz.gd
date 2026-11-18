# Mr. Anduv! ortak yüz çizicisi (F1) — Kaptan Mecit 3 (Godot) portu.
# Champion Battle Manager'daki www/yuz.js ile birebir aynı: tohum String.hash() (djb2), mulberry32 sırası,
# yüz biçimi, saç modeli (KM3 _sac_stili: 0 kısa, 1 kazınmış, 2 dolgun, 3 kıvırcık, 4 arkadan uzun), ten/saç rengi
# (Taktik._renk ile aynı). Aynı ad = iki oyunda da aynı yüz.
# Kalem dili ortak kalemle aynı: kontur #1e130b, ışık soldan-yukarıdan, hacim gölgesi, kenar ışığı, hale.
# Kullanım: Yuz.yeni({"ad": "U. Çakel", "rol": "oyuncu", "k1": "#a90432", "k2": "#fdb912"}, Vector2(30, 36))
#   rol: oyuncu (forma), td (takım elbise + kravat), asistan (eşofman), gazeteci, yonetim, hakem.
# Çizim 100 × 120 mantıksal tuvalde komut listesine çevrilir (ad başına bir kez, bellekte tutulur),
# her çizimde kutunun gerçek pikseline ölçeklenir (dolgular üçgen dizisi, konturlar yumuşatılmış çizgi).
extends Control
class_name Yuz

const KONTUR := Color("#1e130b")
const TENLER := ["#f1c9a5", "#e0ac7e", "#c68a5a", "#8d5a3b", "#f5d6b8"]
const SACLAR := ["#2a1a10", "#4a2e1a", "#1a1a1a", "#7a4a20", "#c8a050"]

var veri: Dictionary = {}
static var _bellek := {}

static func yeni(o: Dictionary, boy: Vector2) -> Yuz:
	var y := Yuz.new()
	y.veri = o; y.custom_minimum_size = boy
	y.mouse_filter = Control.MOUSE_FILTER_IGNORE
	y.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return y

static func komutlar(o: Dictionary) -> Array:
	var anahtar := JSON.stringify(o)
	if _bellek.has(anahtar): return _bellek[anahtar]
	if _bellek.size() > 600: _bellek.clear()
	var c := Kalem.new()
	ciz(c, o)
	c.bitir()
	_bellek[anahtar] = c.K
	return c.K

# Bir yüzün komutları masaüstünde ≈30 ms sürer; kadro ekranında 20 yüz bir kerede kurulursa ekran takılır.
# Bu yüzden henüz hazır olmayan yüzler sıraya girer, her karede ≈12 ms'lik dilimle kurulur (o arada kulüp renginde yer tutucu).
static var _kuyruk: Array = []
static var _bagli := false
static func _isle() -> void:
	var t0 := Time.get_ticks_msec()
	while not _kuyruk.is_empty() and Time.get_ticks_msec() - t0 < 12:
		var y = _kuyruk.pop_front()
		if not is_instance_valid(y): continue
		komutlar(y.veri); y.queue_redraw()

# kulüp kadrosundaki oyuncunun yüz verisi: ad, forma renkleri (kaleci sarı), maçtaki ten / saç (veride varsa)
static func oyuncu(takim: Dictionary, ad: String, mk := "") -> Dictionary:
	var o := {"ad": ad, "k1": str(takim.get("c1", "#2e9e44")), "k2": str(takim.get("c2", "#ffffff"))}
	for grup in ["oy", "yedek"]:
		for x in takim.get(grup, []):
			if str(x.get("n", "")) == ad:
				if x.has("ten"): o.ten = str(x.ten)
				if x.has("sac"): o.sac = str(x.sac)
				if mk == "": mk = str(x.get("mk", x.get("rol", "")))
				break
	if mk in ["GK", "G", "KL"]: o.k1 = "#f3d35a"; o.k2 = "#1d1d1d"
	return o

func _draw() -> void:
	if veri.is_empty(): return
	var anahtar := JSON.stringify(veri)
	if not _bellek.has(anahtar):
		# yer tutucu: kulüp renginde koyu kart
		draw_rect(Rect2(Vector2.ZERO, size), Yuz.ton(renk(veri.get("k1", "#2e9e44")), -0.45))
		if not _kuyruk.has(self): _kuyruk.append(self)
		if not _bagli and is_inside_tree():
			_bagli = true; get_tree().process_frame.connect(func() -> void: Yuz._isle())
		return
	var K: Array = _bellek[anahtar]
	var s := minf(size.x / 100.0, size.y / 120.0)
	var xf := Transform2D(0.0, Vector2(s, s), 0.0, Vector2((size.x - 100.0 * s) / 2.0, (size.y - 120.0 * s) / 2.0))
	var ci := get_canvas_item()
	for k in K:
		if k[0] == 0:
			RenderingServer.canvas_item_add_triangle_array(ci, k[3], xf * (k[1] as PackedVector2Array), k[2])
		else:
			var w: float = maxf(0.6, k[3] * s)
			draw_polyline(xf * (k[1] as PackedVector2Array), k[2], w, true)

# ---------------- renk yardımcıları (yuz.js ile aynı) ----------------
static func renk(h) -> Color:
	if h is Color: return h
	return Color(str(h))
static func karis(a, b, t: float) -> Color:
	var x := renk(a); var y := renk(b)
	var r := x.lerp(y, t); r.a = 1.0
	return Color(round(r.r * 255.0) / 255.0, round(r.g * 255.0) / 255.0, round(r.b * 255.0) / 255.0)
static func ton(c, f: float) -> Color:
	return karis(c, "#fff6e8", f) if f >= 0 else karis(c, "#140c08", -f)
static func isik(c) -> float:
	var r := renk(c)
	return (r.r8 * 299 + r.g8 * 587 + r.b8 * 114) / 1000.0
static func rgba(c, a: float) -> Color:
	var r := renk(c); r.a = a; return r

# ---------------- tohum ----------------
class Rast:
	var t: int
	func _init(s: int) -> void: t = s & 0xFFFFFFFF
	static func imul(a: int, b: int) -> int:
		a &= 0xFFFFFFFF; b &= 0xFFFFFFFF
		return ((a * (b & 0xFFFF)) + (((a * (b >> 16)) & 0xFFFF) << 16)) & 0xFFFFFFFF
	func f() -> float:   # mulberry32
		t = (t + 0x6D2B79F5) & 0xFFFFFFFF
		var r := imul(t ^ (t >> 15), 1 | t)
		r = (r ^ ((r + imul(r ^ (r >> 7), 61 | r)) & 0xFFFFFFFF)) & 0xFFFFFFFF
		return float((r ^ (r >> 14)) & 0xFFFFFFFF) / 4294967296.0

static func hash_ad(s: String) -> int:
	return s.hash() & 0xFFFFFFFF

static func kisa_ad(ad: String, soyad: String) -> String:
	ad = ad.strip_edges(); soyad = soyad.strip_edges()
	if soyad == "": return ad
	return (ad.substr(0, 1) + ". " + soyad) if ad != "" else soyad

static func ozellik(o: Dictionary) -> Dictionary:
	var ad := str(o.get("ad", "?"))
	if ad == "": ad = "?"
	var h := hash_ad(ad)
	var R := Rast.new(hash_ad(ad + "#yuz"))
	var rol: String = str(o.get("rol", "oyuncu"))
	var yas: int = int(o.get("yas", 0))
	if yas == 0: yas = (18 + h % 16) if rol == "oyuncu" else (34 + h % 30)
	var stil: int
	if o.has("stil") and o.stil != null: stil = int(o.stil)
	else:
		var k := h % 100
		stil = 0 if k < 45 else (1 if k < 60 else (2 if k < 80 else (3 if k < 90 else 4)))
	var ten = o.get("ten", null); if ten == null or str(ten) == "": ten = TENLER[h % 5]
	var sac = o.get("sac", null); if sac == null or str(sac) == "": sac = SACLAR[(h >> 5) % 5]
	var koyu_ten := isik(ten) < 150
	var g := {"ad": ad, "rol": rol, "yas": yas, "stil": stil, "ten": renk(ten), "sac": renk(sac), "kadin": bool(o.get("kadin", false))}
	g.genis = 0.9 + R.f() * 0.16
	g.cene = R.f()
	g.uzun = 0.94 + R.f() * 0.12
	g.gozAra = 0.92 + R.f() * 0.16
	g.gozBoy = 0.85 + R.f() * 0.3
	if koyu_ten: g.gozRenk = renk("#3a2214" if R.f() < 0.85 else "#5a3a1e")
	else: g.gozRenk = renk(["#4a2e1a", "#5a3a1e", "#6b5a2a", "#3f6f8f", "#4f7a4a", "#2f2418"][int(floor(R.f() * 6))])
	g.kas = 0.8 + R.f() * 0.5; g.kasAci = (R.f() - 0.4) * 0.25
	g.burun = int(floor(R.f() * 3)); g.burunBoy = 0.9 + R.f() * 0.25
	g.agiz = int(floor(R.f() * 3)); g.gulus = (R.f() - 0.35) * 1.0
	g.kulak = 0.9 + R.f() * 0.2
	g.sakal = 0
	g.sacCizgi = R.f(); g.ayrik = -1 if R.f() < 0.5 else 1; g.kabarik = R.f()
	g.ben = null
	if R.f() < 0.18:
		var bx := (R.f() - 0.5) * 22; var by := 4 + R.f() * 10
		g.ben = Vector2(bx, by)
	g.kirli = R.f()
	g.R = R
	var s := R.f()
	if not g.kadin and yas >= 18:
		if rol == "oyuncu": g.sakal = 0 if s < 0.42 else (1 if s < 0.66 else (2 if s < 0.72 else (3 if s < 0.80 else (4 if s < 0.93 else 5))))
		else: g.sakal = 0 if s < 0.35 else (1 if s < 0.5 else (2 if s < 0.68 else (3 if s < 0.78 else (4 if s < 0.92 else 5))))
	g.kir = maxf(0.0, minf(0.85, (yas - 36 - R.f() * 8) / 26.0))
	if rol == "oyuncu":
		g.kel = 0.4 if (yas > 30 and R.f() < 0.15) else 0.0
	else:
		if yas > 45 and R.f() < 0.35: g.kel = 1.0 if R.f() < 0.4 else 0.6
		elif yas > 38 and R.f() < 0.3: g.kel = 0.35
		else: g.kel = 0.0
	if g.kel >= 1: g.stil = 1
	g.sacRenk = karis(g.sac, "#d9d6cf", g.kir)
	g.sakalRenk = karis(g.sac, "#e2dfd8", minf(1.0, g.kir * 1.2))
	return g

# ---------------- küçük tuval: yol, dolgu (düz / doğrusal / dairesel degrade), kontur, kırpma ----------------
class Kalem:
	var K: Array = []
	var T := Transform2D.IDENTITY
	var clipp: PackedVector2Array = PackedVector2Array([Vector2(-1e4, -1e4), Vector2(1e4, -1e4), Vector2(1e4, 1e4), Vector2(-1e4, 1e4)])
	var yigin: Array = []
	var yol: Array = []        # [PackedVector2Array, kapalı]
	var cur := PackedVector2Array()
	var bas := Vector2()       # alt yolun başı (yerel)
	var son := Vector2()       # son nokta (yerel)
	var alfa := 1.0
	var _tp := PackedVector2Array(); var _tc := PackedColorArray(); var _ti := PackedInt32Array()

	func save() -> void: yigin.append([T, clipp, alfa])
	func restore() -> void:
		var x: Array = yigin.pop_back(); T = x[0]; clipp = x[1]; alfa = x[2]
	func tasi(x: float, y: float) -> void: T = T * Transform2D(0.0, Vector2(x, y))
	func sc(s: float) -> void: T = T * Transform2D(0.0, Vector2(s, s), 0.0, Vector2.ZERO)
	func ro(a: float) -> void: T = T * Transform2D(a, Vector2.ZERO)
	func _olcek() -> float: return T.get_scale().x

	func _kapat_alt(kapali: bool) -> void:
		if cur.size() > 0: yol.append([cur, kapali])
		cur = PackedVector2Array()
	func bp() -> void: yol = []; cur = PackedVector2Array()
	func mt(x: float, y: float) -> void:
		_kapat_alt(false); bas = Vector2(x, y); son = bas; cur.append(T * bas)
	func lt(x: float, y: float) -> void:
		if cur.is_empty(): mt(x, y); return
		son = Vector2(x, y); cur.append(T * son)
	func qt(cx: float, cy: float, x: float, y: float) -> void:
		if cur.is_empty(): mt(cx, cy)
		var p0 := son; var p1 := Vector2(cx, cy); var p2 := Vector2(x, y)
		var n := 10
		for i in range(1, n + 1):
			var t := float(i) / n
			cur.append(T * (p0 * (1 - t) * (1 - t) + p1 * 2 * (1 - t) * t + p2 * t * t))
		son = p2
	func bt(ax: float, ay: float, bx: float, by: float, x: float, y: float) -> void:
		if cur.is_empty(): mt(ax, ay)
		var p0 := son; var p1 := Vector2(ax, ay); var p2 := Vector2(bx, by); var p3 := Vector2(x, y)
		var n := 14
		for i in range(1, n + 1):
			var t := float(i) / n; var u := 1 - t
			cur.append(T * (p0 * u * u * u + p1 * 3 * u * u * t + p2 * 3 * u * t * t + p3 * t * t * t))
		son = p3
	func cp() -> void:
		if cur.is_empty(): return
		_kapat_alt(true); son = bas
	func el(x: float, y: float, rx: float, ry: float, a := 0.0) -> void:
		bp(); _kapat_alt(false)
		var n := 28
		var ca := cos(a); var sa := sin(a)
		for i in n:
			var t := TAU * i / n
			var px := cos(t) * rx; var py := sin(t) * ry
			cur.append(T * Vector2(x + px * ca - py * sa, y + px * sa + py * ca))
		_kapat_alt(true)
	func rc(x: float, y: float, w: float, h: float) -> void:
		_kapat_alt(false)
		for p in [Vector2(x, y), Vector2(x + w, y), Vector2(x + w, y + h), Vector2(x, y + h)]: cur.append(T * p)
		_kapat_alt(true)
	func ar(x: float, y: float, r: float, a0: float, a1: float) -> void:
		var n := 10
		for i in range(n + 1):
			var t := a0 + (a1 - a0) * i / n
			var p := Vector2(x + cos(t) * r, y + sin(t) * r)
			if i == 0 and cur.is_empty(): mt(p.x, p.y)
			else: lt(p.x, p.y)

	# boya: Color | {"l": [a, b], "s": [[t, Color]…]} | {"r": [c0, r0, c1, r1], "s": […]}
	func dog(ax: float, ay: float, bx: float, by: float, s: Array) -> Dictionary:
		return {"l": [T * Vector2(ax, ay), T * Vector2(bx, by)], "s": s}
	func dai(x0: float, y0: float, r0: float, x1: float, y1: float, r1: float, s: Array) -> Dictionary:
		var k := _olcek()
		return {"r": [T * Vector2(x0, y0), r0 * k, T * Vector2(x1, y1), r1 * k], "s": s}
	static func _durak(s: Array, t: float) -> Color:
		t = clampf(t, 0.0, 1.0)
		if t <= s[0][0]: return s[0][1]
		for i in range(1, s.size()):
			if t <= s[i][0]:
				var a: Array = s[i - 1]; var b: Array = s[i]
				var u: float = (t - float(a[0])) / maxf(1e-6, float(b[0]) - float(a[0]))
				return (a[1] as Color).lerp(b[1], u)
		return s[s.size() - 1][1]
	static func _renk_at(b, p: Vector2) -> Color:
		if b is Color: return b
		if b.has("l"):
			var a: Vector2 = b.l[0]; var d: Vector2 = b.l[1] - a
			return _durak(b.s, (p - a).dot(d) / maxf(1e-6, d.length_squared()))
		var c0: Vector2 = b.r[0]; var r0: float = b.r[1]; var c1: Vector2 = b.r[2]; var r1: float = b.r[3]
		var cd := c1 - c0; var pd := p - c0; var dr := r1 - r0
		var A := cd.dot(cd) - dr * dr; var B := pd.dot(cd) + r0 * dr; var C := pd.dot(pd) - r0 * r0
		var t: float
		if absf(A) < 1e-6: t = C / (2.0 * B) if absf(B) > 1e-9 else 0.0
		else:
			var D := B * B - A * C
			if D < 0: return Color(0, 0, 0, 0)
			t = (B + sqrt(D)) / A
			if r0 + t * dr < 0: t = (B - sqrt(D)) / A
		return _durak(b.s, t)

	func _ucgen(a: Vector2, b: Vector2, c: Vector2, ca: Color, cb: Color, cc: Color) -> void:
		var n := _tp.size()
		_tp.append(a); _tp.append(b); _tp.append(c)
		_tc.append(ca); _tc.append(cb); _tc.append(cc)
		_ti.append(n); _ti.append(n + 1); _ti.append(n + 2)
	func _bosalt() -> void:
		if _tp.is_empty(): return
		K.append([0, _tp, _tc, _ti])
		_tp = PackedVector2Array(); _tc = PackedColorArray(); _ti = PackedInt32Array()
	func bitir() -> void: _bosalt()

	func _cokgen(p: PackedVector2Array, boya) -> void:
		var ix := Geometry2D.triangulate_polygon(p)
		if ix.is_empty(): return
		var duz: bool = boya is Color
		for i in range(0, ix.size(), 3):
			var a := p[ix[i]]; var b := p[ix[i + 1]]; var c := p[ix[i + 2]]
			if duz:
				var cl: Color = boya; cl.a *= alfa
				_ucgen(a, b, c, cl, cl, cl)
			else: _bol(a, b, c, boya, 0)
	func _bol(a: Vector2, b: Vector2, c: Vector2, boya, d: int) -> void:
		var ab := a.distance_squared_to(b); var bc := b.distance_squared_to(c); var ca := c.distance_squared_to(a)
		var m := maxf(ab, maxf(bc, ca))
		var r1 := _renk_at(boya, a); var r2 := _renk_at(boya, b); var r3 := _renk_at(boya, c)
		var bol := m > 16.0 and d < 9
		if bol and m < 400.0:   # renk üçgen içinde düz değişiyorsa bölme (ağırlık merkezi ve en uzun kenarın ortası denetlenir)
			var o := _renk_at(boya, (a + b + c) / 3.0); var e := (r1 + r2 + r3) / 3.0
			var hata := maxf(maxf(absf(o.r - e.r), absf(o.g - e.g)), maxf(absf(o.b - e.b), absf(o.a - e.a)))
			var orta: Vector2 = (a + b) / 2 if m == ab else ((b + c) / 2 if m == bc else (c + a) / 2)
			var eo: Color = (r1 + r2) / 2 if m == ab else ((r2 + r3) / 2 if m == bc else (r3 + r1) / 2)
			var oo := _renk_at(boya, orta)
			hata = maxf(hata, maxf(maxf(absf(oo.r - eo.r), absf(oo.g - eo.g)), maxf(absf(oo.b - eo.b), absf(oo.a - eo.a))))
			bol = hata > 0.008
		if bol:
			if m == ab: var x := (a + b) / 2; _bol(a, x, c, boya, d + 1); _bol(x, b, c, boya, d + 1)
			elif m == bc: var x := (b + c) / 2; _bol(a, b, x, boya, d + 1); _bol(a, x, c, boya, d + 1)
			else: var x := (c + a) / 2; _bol(a, b, x, boya, d + 1); _bol(x, b, c, boya, d + 1)
			return
		r1.a *= alfa; r2.a *= alfa; r3.a *= alfa
		_ucgen(a, b, c, r1, r2, r3)

	func fill(boya) -> void:
		_kapat_alt(false)
		for sp in yol:
			var p: PackedVector2Array = sp[0]
			if p.size() < 3: continue
			for q in Geometry2D.intersect_polygons(p, clipp):
				if q.size() >= 3: _cokgen(q, boya)
	func frect(x: float, y: float, w: float, h: float, boya) -> void:
		if w < 1.6 and h < 1.6:   # küçük benek: kırpma yalnız merkezle
			if not Geometry2D.is_point_in_polygon(T * Vector2(x + w / 2, y + h / 2), clipp): return
			var cl: Color = boya; cl.a *= alfa
			var a := T * Vector2(x, y); var b := T * Vector2(x + w, y); var c := T * Vector2(x + w, y + h); var d := T * Vector2(x, y + h)
			_ucgen(a, b, c, cl, cl, cl); _ucgen(a, c, d, cl, cl, cl); return
		var p := PackedVector2Array([T * Vector2(x, y), T * Vector2(x + w, y), T * Vector2(x + w, y + h), T * Vector2(x, y + h)])
		for q in Geometry2D.intersect_polygons(p, clipp):
			if q.size() >= 3: _cokgen(q, boya)
	func stroke(cl: Color, w: float) -> void:
		_kapat_alt(false)
		cl.a *= alfa
		var ww := w * _olcek()
		for sp in yol:
			var p: PackedVector2Array = (sp[0] as PackedVector2Array).duplicate()
			if p.size() < 2: continue
			if sp[1]: p.append(p[0])
			_bosalt()
			for q in Geometry2D.intersect_polyline_with_polygon(p, clipp):
				if q.size() >= 2: K.append([1, q, cl, ww])
	func clip() -> void:
		_kapat_alt(false)
		var en := PackedVector2Array(); var ea := -1.0
		for sp in yol:
			var p: PackedVector2Array = sp[0]
			if p.size() < 3: continue
			for q in Geometry2D.intersect_polygons(p, clipp):
				var a := absf(_alan(q))
				if a > ea: ea = a; en = q
		clipp = en if en.size() >= 3 else PackedVector2Array([Vector2.ZERO, Vector2.ZERO, Vector2.ZERO])
	static func _alan(p: PackedVector2Array) -> float:
		var s := 0.0
		for i in p.size(): s += p[i].cross(p[(i + 1) % p.size()])
		return s / 2.0

# ---------------- çizim (yuz.js ile satır satır aynı) ----------------
static func _kont(c: Kalem, w := 1.4) -> void: c.stroke(KONTUR, w)

static func _bas_yolu(c: Kalem, g: Dictionary) -> Dictionary:
	var W: float = 21 * g.genis; var U: float = g.uzun; var cn: float = g.cene
	var ust := 26 - 2 * U; var sakak := 44.0; var cene := 70 + 6 * U; var ceneG := 7 + 6 * cn
	c.bp()
	c.mt(50, ust)
	c.bt(50 + W * 0.75, ust, 50 + W, ust + 8, 50 + W, sakak)
	c.bt(50 + W, sakak + 10, 50 + W * (0.9 - 0.05 * cn), cene - 12, 50 + ceneG + 4, cene - 2)
	c.qt(50 + ceneG * 0.6, cene + 1, 50, cene + 1.5)
	c.qt(50 - ceneG * 0.6, cene + 1, 50 - ceneG - 4, cene - 2)
	c.bt(50 - W * (0.9 - 0.05 * cn), cene - 12, 50 - W, sakak + 10, 50 - W, sakak)
	c.bt(50 - W, ust + 8, 50 - W * 0.75, ust, 50, ust)
	c.cp()
	return {"W": W, "ust": ust, "cene": cene, "ceneG": ceneG, "sakak": sakak}

static func _govde(c: Kalem, g: Dictionary, o: Dictionary, B: Dictionary) -> void:
	var k1 := renk(o.get("k1", "#c8102e")); var k2 := renk(o.get("k2", "#ffffff"))
	var R: Rast = g.R
	if g.rol == "hakem": k1 = renk("#1b1b1b"); k2 = renk("#f3d35a")
	var omuz: float = 44 + g.genis * 2
	var bW: float = 9 + g.genis * 2 + (-2 if g.kadin else 0)
	var cene: float = B.cene
	c.bp(); c.mt(50 - bW, cene - 10); c.lt(50 - bW - 1, 92); c.lt(50 + bW + 1, 92); c.lt(50 + bW, cene - 10); c.cp()
	c.fill(c.dog(50 - bW, 0, 50 + bW, 0, [[0.0, ton(g.ten, -0.12)], [0.55, ton(g.ten, -0.05)], [1.0, ton(g.ten, -0.3)]])); _kont(c, 1.2)
	c.save(); c.clip(); c.el(50, cene + 1, bW + 3, 7); c.fill(rgba("#3a1c0c", 0.32)); c.restore()
	var govde_yolu := func() -> void:
		c.bp(); c.mt(50 - omuz - 6, 122); c.lt(50 - omuz - 4, 104)
		c.bt(50 - omuz - 2, 94, 50 - omuz + 8, 89, 50 - bW - 4, 86)
		c.lt(50 + bW + 4, 86)
		c.bt(50 + omuz - 8, 89, 50 + omuz + 2, 94, 50 + omuz + 4, 104)
		c.lt(50 + omuz + 6, 122); c.cp()
	var ana := k1; var kenar := k2
	if g.rol == "td" or g.rol == "yonetim": ana = renk("#232836" if R.f() < 0.5 else "#2d2a28")
	elif g.rol == "gazeteci": ana = renk(["#5d7a96", "#7c8a6a", "#8a6a5a", "#4a5568"][int(floor(R.f() * 4))])
	elif g.rol == "asistan":
		ana = k2 if isik(k1) > 200 else k1; kenar = k1 if isik(k1) > 200 else k2
	govde_yolu.call()
	c.fill(c.dog(0, 86, 0, 122, [[0.0, ton(ana, 0.12)], [1.0, ton(ana, -0.25)]]))
	c.save(); c.clip()
	c.frect(0, 80, 100, 50, c.dog(50 - omuz, 0, 50 + omuz, 0, [[0.0, rgba("#ffffff", 0.18)], [0.45, rgba("#ffffff", 0)], [0.7, rgba("#000000", 0)], [1.0, rgba("#000000", 0.3)]]))
	if g.rol == "oyuncu" or g.rol == "hakem":
		c.bp(); c.mt(50 - omuz - 8, 101); c.bt(50 - omuz, 91, 50 - omuz + 10, 88, 50 - bW - 4, 86.5); c.lt(50 - bW - 4, 89.5); c.bt(50 - omuz + 11, 92, 50 - omuz + 2, 95, 50 - omuz - 5, 104); c.cp(); c.fill(kenar)
		c.bp(); c.mt(50 + omuz + 8, 101); c.bt(50 + omuz, 91, 50 + omuz - 10, 88, 50 + bW + 4, 86.5); c.lt(50 + bW + 4, 89.5); c.bt(50 + omuz - 11, 92, 50 + omuz - 2, 95, 50 + omuz + 5, 104); c.cp(); c.fill(kenar)
		c.bp(); c.mt(50 - bW - 4, 86); c.lt(50, 97); c.lt(50 + bW + 4, 86); c.lt(50 + bW + 1, 86); c.lt(50, 93.5); c.lt(50 - bW - 1, 86); c.cp()
		c.fill(kenar); _kont(c, 0.8)
		c.bp(); c.mt(62.5, 99); c.lt(69.5, 99); c.lt(69.5, 103); c.qt(69, 106.5, 66, 108); c.qt(63, 106.5, 62.5, 103); c.cp(); c.fill(kenar); _kont(c, 0.7)
		c.el(66, 103, 1.4, 1.6); c.fill(ana)
		c.alfa = 0.07
		for i in 26: c.frect(8 + i * 3.4, 88, 1.1, 40, Color.BLACK)
		c.alfa = 1.0
	elif g.rol == "td" or g.rol == "yonetim":
		c.bp(); c.mt(50 - bW - 3, 86); c.lt(50, 112); c.lt(50 + bW + 3, 86); c.cp(); c.fill(renk("#f4f1ea"))
		var kravat: Color = k1 if g.rol == "yonetim" else (k1 if R.f() < 0.5 else renk("#3a3f52"))
		c.bp(); c.mt(47.5, 89.5); c.lt(52.5, 89.5); c.lt(51.6, 93); c.lt(54, 118); c.lt(50, 122); c.lt(46, 118); c.lt(48.4, 93); c.cp(); c.fill(kravat); _kont(c, 0.8)
		c.frect(48.6, 95, 1.2, 20, rgba("#ffffff", 0.15))
		c.bp(); c.mt(50 - bW - 3, 85.5); c.lt(47.5, 90.5); c.lt(50 - bW + 1, 93); c.cp(); c.fill(Color.WHITE); _kont(c, 0.7)
		c.bp(); c.mt(50 + bW + 3, 85.5); c.lt(52.5, 90.5); c.lt(50 + bW - 1, 93); c.cp(); c.fill(Color.WHITE); _kont(c, 0.7)
		var kl := ton(ana, 0.1)
		c.bp(); c.mt(50 - bW - 5, 86); c.lt(44, 116); c.lt(39, 104); c.lt(42, 98); c.lt(37, 94); c.cp(); c.fill(kl); _kont(c, 0.8)
		c.bp(); c.mt(50 + bW + 5, 86); c.lt(56, 116); c.lt(61, 104); c.lt(58, 98); c.lt(63, 94); c.cp(); c.fill(kl); _kont(c, 0.8)
		c.bp(); c.mt(66, 104); c.lt(72, 104); c.lt(70, 101); c.lt(68, 102.5); c.cp(); c.fill(k2 if isik(k2) > 60 else renk("#f3d35a"))
	elif g.rol == "asistan":
		c.frect(50 - omuz - 6, 96, 6, 30, kenar); c.frect(50 + omuz, 96, 6, 30, kenar)
		c.bp(); c.mt(50 - bW - 5, 83); c.lt(50 + bW + 5, 83); c.lt(50 + bW + 5, 91); c.qt(50, 94, 50 - bW - 5, 91); c.cp(); c.fill(ton(ana, -0.1)); _kont(c, 0.8)
		c.bp(); c.mt(50, 92.5); c.lt(50, 125); c.stroke(ton(kenar, -0.1), 1.2)
		c.frect(48.8, 92, 2.4, 4, renk("#c9c9c9"))
		c.el(36, 102, 3, 3.5); c.fill(kenar); _kont(c, 0.7)
	elif g.rol == "gazeteci":
		var ya := ton(ana, 0.18)
		c.bp(); c.mt(50 - bW - 4, 85.5); c.lt(46, 96); c.lt(50 - bW - 6, 93); c.cp(); c.fill(ya); _kont(c, 0.7)
		c.bp(); c.mt(50 + bW + 4, 85.5); c.lt(54, 96); c.lt(50 + bW + 6, 93); c.cp(); c.fill(ya); _kont(c, 0.7)
		c.bp(); c.mt(50 - bW - 1, 86); c.lt(50, 96); c.lt(50 + bW + 1, 86); c.cp(); c.fill(ton(g.ten, -0.08))
		c.bp(); c.mt(50 - bW - 2, 87); c.qt(44, 96, 47, 102); c.mt(50 + bW + 2, 87); c.qt(56, 96, 53, 102); c.stroke(renk("#c8102e"), 2)
		c.bp(); c.rc(42, 100, 16, 12); c.fill(renk("#f7f4ec")); _kont(c, 0.8)
		c.frect(42.6, 100.6, 14.8, 3, renk("#c8102e"))
		c.frect(44, 105.5, 7, 1.3, renk("#8a8a8a")); c.frect(44, 108, 10, 1.3, renk("#8a8a8a"))
		c.frect(52.5, 105, 4, 5, renk("#b8b2a6"))
	c.restore()
	govde_yolu.call(); _kont(c, 1.5)

static func _sac_arka(c: Kalem, g: Dictionary, B: Dictionary) -> void:
	var W: float = B.W; var sakak: float = B.sakak
	if g.stil == 4 or (g.kadin and g.stil != 1):
		var uz := 34.0 if g.kadin else 18.0
		c.bp(); c.mt(50 - W - 3, sakak - 6)
		c.bt(50 - W - 7, sakak + 10, 50 - W - 6, sakak + uz, 50 - W + 3, sakak + uz + 6)
		c.lt(50 + W - 3, sakak + uz + 6)
		c.bt(50 + W + 6, sakak + uz, 50 + W + 7, sakak + 10, 50 + W + 3, sakak - 6)
		c.cp()
		c.fill(ton(g.sacRenk, -0.25)); _kont(c, 1.4)
		c.save(); c.clip()
		for i in range(-3, 4):
			c.bp(); c.mt(50 + i * W / 3.5, sakak - 4); c.qt(50 + i * W / 3 + 2, sakak + uz / 2, 50 + i * W / 3.2, sakak + uz + 6); c.stroke(rgba("#000000", 0.25), 0.7)
		c.restore()
	if g.stil == 3:
		var R2 := Rast.new(hash_ad(g.ad + "#kivir2"))
		for j in 22:
			var a := PI * (1.0 + j / 21.0); var r := W + 4 + R2.f() * 2
			c.el(50 + cos(a) * r, sakak - 4 + sin(a) * (r + 2), 5, 5); c.fill(ton(g.sacRenk, -0.3)); _kont(c, 0.9)

static func _sac_on(c: Kalem, g: Dictionary, B: Dictionary) -> void:
	var W: float = B.W; var ust: float = B.ust; var sakak: float = B.sakak
	var rk: Color = g.sacRenk; var R := Rast.new(hash_ad(g.ad + "#sac"))
	var cizgi: float = ust + 9 + g.sacCizgi * 3 + g.kel * 9
	var dolgu := func(yol: Callable, isikli: bool) -> void:
		yol.call()
		c.fill(c.dog(50 - W, ust - 8, 50 + W, cizgi + 4, [[0.0, ton(rk, 0.25)], [0.5, rk], [1.0, ton(rk, -0.35)]]))
		if isikli:
			c.save(); c.clip()
			for i in 7:
				var x := 50 - W * 0.6 + i * W * 0.17
				c.bp(); c.mt(x, ust - 2); c.qt(x - 3, ust + 4, x - 5 + R.f() * 2, cizgi - 2); c.stroke(rgba(ton(rk, 0.6), 0.55), 0.9)
			c.el(50 - W * 0.35, ust + 2, W * 0.35, 3.5, -0.3); c.fill(rgba("#fff8e0", 0.18)); c.restore()
		yol.call(); _kont(c, 1.4)
	if g.stil == 1:
		if g.kel >= 1: return
		c.save(); _bas_yolu(c, g); c.clip()
		c.bp(); c.mt(50 - W - 2, sakak - 1); c.bt(50 - W, ust - 2, 50 + W, ust - 2, 50 + W + 2, sakak - 1)
		c.lt(50 + W - 3, sakak - 2); c.qt(50 + W * 0.6, cizgi - 1, 50, cizgi); c.qt(50 - W * 0.6, cizgi - 1, 50 - W + 3, sakak - 2); c.cp()
		c.fill(rgba(rk, 0.55))
		var nk := rgba(ton(rk, -0.3), 0.5)
		for i in 160:
			var x := 50 + (R.f() - 0.5) * W * 2; var y := ust + R.f() * (cizgi - ust + 2)
			c.frect(x, y, 0.55, 0.55, nk)
		c.restore(); return
	if g.kel >= 1: return
	if g.stil == 0:
		dolgu.call(func() -> void:
			c.bp(); c.mt(50 - W - 1.5, sakak + 1)
			c.bt(50 - W - 2.5, ust - 2, 50 - 6, ust - 5, 50 + 2, ust - 4.5)
			c.bt(50 + W, ust - 4, 50 + W + 2.5, ust + 6, 50 + W + 1.5, sakak + 1)
			c.lt(50 + W - 1.5, sakak - 3)
			c.qt(50 + W * 0.7, cizgi - 1, 50 + W * 0.3, cizgi + 0.5)
			for i in 6:
				var x := 50 + W * 0.3 - (i + 1) * W * 0.6 / 6
				c.lt(x + W * 0.05, cizgi + (2.4 if i % 2 else -0.3))
			c.qt(50 - W * 0.8, cizgi - 1, 50 - W + 1.5, sakak - 3)
			c.cp(), true)
	elif g.stil == 2:
		var k: float = 5 + g.kabarik * 4
		dolgu.call(func() -> void:
			c.bp(); c.mt(50 - W - 2, sakak + 1)
			c.bt(50 - W - 5, ust - 6, 50 - W * 0.5, ust - k - 4, 50 + 2, ust - k - 3)
			c.bt(50 + W * 0.7, ust - k - 3, 50 + W + 5, ust - 4, 50 + W + 2, sakak + 1)
			c.lt(50 + W - 1.5, sakak - 3)
			c.bt(50 + W * 0.8, cizgi - 4, 50 + W * 0.3, cizgi - 4, 50 + W * 0.1 * g.ayrik, cizgi - 1)
			c.bt(50 - W * 0.3, cizgi + 2, 50 - W * 0.8, cizgi - 1, 50 - W + 1.5, sakak - 3)
			c.cp(), true)
		for i in 5:
			var x := 50 - W * 0.6 + i * W * 0.3
			c.bp(); c.mt(x, ust - k); c.qt(x + 4, ust - 2, x + 2, cizgi - 3); c.stroke(rgba(ton(rk, -0.5), 0.6), 0.8)
	elif g.stil == 3:
		var R2 := Rast.new(hash_ad(g.ad + "#kivir"))
		var pts: Array = []
		for i in 26:
			var a := PI * (1.02 + 0.96 * i / 25.0); var r := W + 1 + R2.f() * 2.5
			pts.append(Vector2(50 + cos(a) * r, ust + 13 + sin(a) * (r * 0.85)))
		for j in 14:
			var px := 50 + (R2.f() - 0.5) * W * 1.6; var py := ust - 3 + R2.f() * 9
			pts.append(Vector2(px, py))
		for m in 9:
			pts.append(Vector2(50 - W * 0.8 + m * W * 0.2, cizgi - 1 + R2.f() * 1.5))
		for p in pts:
			var rr := 3.6 + R2.f() * 1.6
			c.el(p.x, p.y, rr, rr)
			c.fill(c.dai(p.x - 1.2, p.y - 1.2, 0.3, p.x, p.y, rr, [[0.0, ton(rk, 0.35)], [1.0, ton(rk, -0.3)]])); _kont(c, 0.75)
			c.bp(); c.ar(p.x, p.y, rr * 0.5, PI, PI * 1.7); c.stroke(rgba(ton(rk, 0.5), 0.5), 0.6)
	elif g.stil == 4:
		var ay: float = 50 + g.ayrik * W * 0.25
		dolgu.call(func() -> void:
			c.bp(); c.mt(50 - W - 3, sakak + 10)
			c.bt(50 - W - 5, ust - 5, ay - 6, ust - 7, ay, ust - 5)
			c.bt(ay + 6, ust - 7, 50 + W + 5, ust - 5, 50 + W + 3, sakak + 10)
			c.lt(50 + W - 1, sakak + 6)
			c.bt(50 + W - 2, cizgi + 2, ay + 8, cizgi - 3, ay, cizgi - 4)
			c.bt(ay - 8, cizgi - 3, 50 - W + 2, cizgi + 2, 50 - W + 1, sakak + 6)
			c.cp(), true)
		c.bp(); c.mt(ay, ust - 4); c.lt(ay, cizgi - 4); c.stroke(rgba(ton(rk, -0.5), 0.55), 0.8)
	if g.stil != 3 and not g.kadin:
		var ek := 4.0 if g.sakal >= 4 else 0.0
		for y in [-1, 1]:
			c.bp(); c.mt(50 + y * (W - 0.3), sakak - 3); c.lt(50 + y * (W - 3.2), sakak - 3); c.lt(50 + y * (W - 2.6), sakak + 4.5 + ek); c.lt(50 + y * (W - 0.4), sakak + 4.5 + ek); c.cp(); c.fill(ton(rk, -0.1))
	if g.kir > 0.15:
		var kr := rgba("#efece6", minf(0.7, g.kir))
		for q in 10:
			var x0 := 50 + (R.f() - 0.5) * W * 1.8
			c.bp(); c.mt(x0, ust + 1); c.lt(x0 - 2, ust + 6); c.stroke(kr, 0.7)

static func _goz(c: Kalem, g: Dictionary, x: float, y: float, yon: int) -> void:
	var b: float = g.gozBoy; var gw := 4.4; var gh := 2.5 * b
	c.el(x, y - 0.6, gw + 1.6, gh + 1.6); c.fill(rgba("#5a2a14", 0.12))
	c.bp(); c.mt(x - gw, y); c.qt(x - gw * 0.2, y - gh * 1.5, x + gw, y - 0.2 * yon); c.qt(x, y + gh * 1.1, x - gw, y); c.cp()
	c.fill(renk("#f8f4ec"))
	c.save(); c.clip()
	var ir := 2.15; var gr: Color = g.gozRenk
	c.el(x + 0.2, y - 0.1, ir, ir); c.fill(c.dai(x + 0.2, y - 0.2, 0.2, x + 0.2, y - 0.1, ir, [[0.0, ton(gr, 0.35)], [0.7, gr], [1.0, ton(gr, -0.5)]]))
	c.el(x + 0.2, y - 0.1, 1.0, 1.0); c.fill(renk("#0c0805"))
	c.frect(x - gw, y - gh * 2, gw * 2, gh * 0.9, rgba("#3a1c0c", 0.25))
	c.restore()
	c.el(x - 0.6, y - 0.9, 0.65, 0.65); c.fill(Color.WHITE)
	c.bp(); c.mt(x - gw - 0.4, y + 0.2); c.qt(x - gw * 0.2, y - gh * 1.55, x + gw + 0.3, y - 0.3 * yon); c.stroke(KONTUR, 1.25)
	c.bp(); c.mt(x - gw * 0.6, y + gh * 0.55); c.qt(x, y + gh * 0.95, x + gw * 0.7, y + gh * 0.4); c.stroke(rgba("#3a1c0c", 0.45), 0.6)
	c.bp(); c.mt(x - gw * 0.8, y - gh * 1.15); c.qt(x, y - gh * 2.0, x + gw * 0.9, y - gh * 1.0); c.stroke(rgba("#3a1c0c", 0.3), 0.6)

static func _kas(c: Kalem, g: Dictionary, x: float, y: float, yon: int) -> void:
	var rk := karis(g.sacRenk, "#000000", 0.1)
	var k: float = g.kas; var a: float = g.kasAci * yon
	c.save(); c.tasi(x, y); c.ro(a)
	c.bp(); c.mt(-5.2 * yon, 1.1); c.qt(-1 * yon, -1.6 - k * 0.6, 5.4 * yon, -0.2)
	c.qt(0, -0.4 - k * 0.2 + 1.6 * k, -5.2 * yon, 1.1 + 0.4)
	c.cp(); c.fill(rk)
	c.stroke(rgba(rk, 0.8), 0.9 * k)
	c.restore()

static func _yuz_ayrinti(c: Kalem, g: Dictionary, B: Dictionary) -> void:
	var W: float = B.W; var ust: float = B.ust; var cene: float = B.cene; var ceneG: float = B.ceneG
	var gy := 46.0; var ga: float = 9.2 * g.gozAra * minf(1.05, g.genis)
	c.save(); _bas_yolu(c, g); c.clip()
	c.frect(0, 0, 100, 100, c.dog(50 - W, 0, 50 + W, 0, [[0.0, rgba("#fff4e0", 0.22)], [0.35, rgba("#fff4e0", 0)], [0.62, rgba("#3a1608", 0)], [1.0, rgba("#3a1608", 0.38)]]))
	c.frect(0, 0, 100, 100, c.dai(44, ust + 10, 1, 44, ust + 10, 16, [[0.0, rgba("#fff8ec", 0.28)], [1.0, rgba("#fff8ec", 0)]]))
	c.el(50 - ga - 2, 57, 6, 3.5); c.fill(rgba("#d0503c", 0.10)); c.el(50 + ga + 2, 57, 6, 3.5); c.fill(rgba("#d0503c", 0.10))
	c.el(50 + W - 2, gy + 6, 4, 10); c.fill(rgba("#3a1608", 0.12))
	if g.sakal == 1 or g.sakal >= 4:
		var yo := 0.85 if g.sakal == 5 else (0.65 if g.sakal == 4 else 0.22)
		c.bp(); c.mt(50 - W, gy + 6); c.qt(50 - W + 3, 60, 50 - 10, 60); c.qt(50, 57.5, 50 + 10, 60)
		c.qt(50 + W - 3, 60, 50 + W, gy + 6); c.lt(50 + W, 100); c.lt(50 - W, 100); c.cp(); c.fill(rgba(g.sakalRenk, yo * 0.55))
		var R3 := Rast.new(hash_ad(g.ad + "#sakal")); var sk := rgba(ton(g.sakalRenk, -0.3), yo * 0.6)
		var i := 0
		while i < 260 * yo:
			var x := 50 + (R3.f() - 0.5) * W * 2; var y := 54 + R3.f() * (cene - 52)
			c.frect(x, y, 0.5, 0.5, sk); i += 1
	if g.yas >= 30:
		var cr := rgba("#5a2a14", minf(0.35, (g.yas - 28) / 60.0))
		for l in (3 if g.yas >= 45 else 2):
			c.bp(); c.mt(50 - 8 + l, ust + 10 + l * 2.3); c.qt(50, ust + 9 + l * 2.3, 50 + 8 - l, ust + 10 + l * 2.3); c.stroke(cr, 0.55)
	c.restore()

	_kas(c, g, 50 - ga, gy - 6.2, -1); _kas(c, g, 50 + ga, gy - 6.2, 1)
	_goz(c, g, 50 - ga, gy, -1); _goz(c, g, 50 + ga, gy, 1)
	if g.yas >= 40:
		for s in [-1, 1]:
			var x: float = 50 + s * (ga + 5.5)
			for i in range(-1, 2):
				c.bp(); c.mt(x, gy + i * 1.4); c.lt(x + s * 2.2, gy + i * 2.1); c.stroke(rgba("#5a2a14", 0.3), 0.5)
	var nb: float = g.burunBoy; var ny := 55 + 2 * nb
	c.bp(); c.mt(50 + 2, gy + 1); c.qt(50 + 3.6, ny - 5, 50 + 3.4 + g.burun * 0.6, ny - 1); c.stroke(rgba("#5a2a14", 0.45), 0.9)
	c.bp(); c.mt(50 + 1.2, gy + 3); c.qt(50 + 4, ny - 4, 50 + 4.2, ny); c.lt(50 + 1.5, ny - 1); c.cp(); c.fill(rgba("#5a2a14", 0.18))
	var kanat: float = 3.6 + g.burun * 0.7
	c.el(50 - 0.8, ny - 2.2, 1.4, 1.1); c.fill(rgba("#fff4e0", 0.35))
	c.bp(); c.mt(50 - kanat, ny - 1.4); c.qt(50 - kanat - 1, ny + 0.8, 50 - 1.6, ny + 0.6)
	c.mt(50 + kanat, ny - 1.4); c.qt(50 + kanat + 1, ny + 0.8, 50 + 1.6, ny + 0.6); c.stroke(KONTUR, 0.95)
	c.el(50 - 1.9, ny + 0.2, 1.0, 0.55); c.fill(rgba("#2a0e04", 0.6)); c.el(50 + 1.9, ny + 0.2, 1.0, 0.55); c.fill(rgba("#2a0e04", 0.6))
	var ay: float = ny + 6.2 + (cene - 72) * 0.25; var aw: float = 5.5 + g.agiz * 0.8; var gl: float = g.gulus
	var dudak := karis(g.ten, "#b0483c", 0.35)
	c.bp(); c.mt(50 - aw, ay - gl * 0.6); c.qt(50, ay + 3.2 + gl * 0.6, 50 + aw, ay - gl * 0.6); c.qt(50, ay + 0.6, 50 - aw, ay - gl * 0.6); c.fill(dudak)
	c.bp(); c.mt(50 - aw + 0.5, ay - gl * 0.6); c.qt(50 - 2, ay - 1.8, 50, ay - 1.0); c.qt(50 + 2, ay - 1.8, 50 + aw - 0.5, ay - gl * 0.6); c.qt(50, ay + 0.4, 50 - aw + 0.5, ay - gl * 0.6); c.fill(ton(dudak, -0.15))
	c.bp(); c.mt(50 - aw, ay - gl * 0.6); c.qt(50, ay + 0.9 + gl * 0.8, 50 + aw, ay - gl * 0.6); c.stroke(KONTUR, 1.0)
	if gl > 0.25:
		c.bp(); c.ar(50 - aw - 0.6, ay - gl * 0.6 - 0.8, 1.2, 0.3, 1.6); c.stroke(rgba("#5a2a14", 0.5), 0.6)
		c.bp(); c.ar(50 + aw + 0.6, ay - gl * 0.6 - 0.8, 1.2, 1.5, 2.8); c.stroke(rgba("#5a2a14", 0.5), 0.6)
	c.el(50 - 1, ay + 2.2, 2.2, 0.7); c.fill(rgba("#fff4e0", 0.3))
	if g.yas >= 38:
		c.bp(); c.mt(50 - kanat - 1, ny); c.qt(50 - aw - 3, ay - 2, 50 - aw - 2, ay + 3); c.mt(50 + kanat + 1, ny); c.qt(50 + aw + 3, ay - 2, 50 + aw + 2, ay + 3); c.stroke(rgba("#5a2a14", 0.28), 0.6)
	var sr: Color = g.sakalRenk
	if g.sakal == 2 or g.sakal >= 3:
		c.bp(); c.mt(50 - aw - 1.6, ay + 0.4); c.qt(50 - aw, ny + 1.4, 50, ny + 2.4); c.qt(50 + aw, ny + 1.4, 50 + aw + 1.6, ay + 0.4)
		c.qt(50 + aw - 1, ay - 2.2, 50, ay - 1.6); c.qt(50 - aw + 1, ay - 2.2, 50 - aw - 1.6, ay + 0.4); c.fill(sr); _kont(c, 0.6)
	if g.sakal == 3:
		c.bp(); c.mt(50 - 4, ay + 3); c.qt(50, ay + 2, 50 + 4, ay + 3); c.lt(50 + 3, cene + 1); c.qt(50, cene + 3, 50 - 3, cene + 1); c.cp(); c.fill(sr); _kont(c, 0.6)
	if g.sakal >= 4:
		var gur := 3.5 if g.sakal == 5 else 1.2
		c.bp(); c.mt(50 - W + 0.5, gy + 7)
		c.bt(50 - W + 1, cene - 4, 50 - ceneG - 4, cene + gur, 50, cene + 1.5 + gur)
		c.bt(50 + ceneG + 4, cene + gur, 50 + W - 1, cene - 4, 50 + W - 0.5, gy + 7)
		c.lt(50 + W - 2.5, gy + 9); c.qt(50 + aw + 4, ay + 6, 50, ay + 4.2); c.qt(50 - aw - 4, ay + 6, 50 - W + 2.5, gy + 9); c.cp()
		c.fill(sr); _kont(c, 0.9)
		c.save(); c.clip()
		for i in 12:
			var x := 50 - W + 3 + i * W / 6
			c.bp(); c.mt(x, ay + 4); c.lt(x + 0.6, cene + gur); c.stroke(rgba(ton(sr, 0.4), 0.4), 0.5)
		c.restore()
	if g.ben != null:
		c.el(50 + g.ben.x, gy + g.ben.y, 0.7, 0.7); c.fill(rgba("#3a1608", 0.65))

static func _kulak(c: Kalem, g: Dictionary, B: Dictionary, yon: int) -> void:
	var x: float = 50 + yon * (B.W - 0.5); var y := 49.0; var k: float = g.kulak
	c.bp(); c.mt(x, y - 6 * k); c.bt(x + yon * 5.5 * k, y - 8 * k, x + yon * 6 * k, y + 3, x + yon * 1, y + 6 * k); c.cp()
	c.fill(ton(g.ten, -0.02) if yon < 0 else ton(g.ten, -0.22)); _kont(c, 1.2)
	c.bp(); c.mt(x + yon * 1.2, y - 3.5 * k); c.qt(x + yon * 4 * k, y - 4 * k, x + yon * 2.2, y + 2.5 * k); c.stroke(rgba("#5a2a14", 0.45), 0.7)

static func _zemin(c: Kalem, o: Dictionary) -> void:
	var k1 := renk(o.get("k1", "#2e9e44"))
	c.frect(0, 0, 100, 120, c.dai(46, 40, 4, 50, 56, 66, [[0.0, ton(k1, 0.55)], [0.55, ton(k1, 0.1)], [1.0, ton(k1, -0.45)]]))
	c.frect(0, 0, 100, 120, c.dai(50, 50, 10, 50, 50, 46, [[0.0, rgba("#fff8e6", 0.55)], [1.0, rgba("#fff8e6", 0)]]))
	c.alfa = 0.08
	for i in 5:
		c.bp(); c.mt(10 + i * 18, 0); c.lt(18 + i * 18, 0); c.lt(i * 18 - 6, 120); c.lt(i * 18 - 14, 120); c.cp(); c.fill(Color.WHITE)
	c.alfa = 1.0

# ana çizici: mantıksal tuval 100 × 120
static func ciz(c: Kalem, o: Dictionary) -> Dictionary:
	var g := ozellik(o)
	var zemin: bool = o.get("zemin", true) != false
	c.save()
	c.bp(); c.rc(0, 0, 100, 120); c.clip()
	if zemin: _zemin(c, o)
	var z: float = float(o.get("yakin", 1.14))
	c.tasi(50, 58); c.sc(z); c.tasi(-50, -54)
	c.save(); c.bp(); c.rc(-10, -10, 120, 130); c.clip()
	var B := _bas_yolu(c, g); c.bp()
	_sac_arka(c, g, B)
	_govde(c, g, o, B)
	_kulak(c, g, B, -1); _kulak(c, g, B, 1)
	_bas_yolu(c, g)
	c.fill(c.dog(50 - B.W, B.ust, 50 + B.W * 0.6, B.cene, [[0.0, ton(g.ten, 0.1)], [0.6, g.ten], [1.0, ton(g.ten, -0.12)]]))
	_yuz_ayrinti(c, g, B)
	_bas_yolu(c, g); _kont(c, 1.6)
	c.save(); _bas_yolu(c, g); c.clip()
	c.bp(); c.mt(50 - B.W + 1.2, B.sakak - 8); c.qt(50 - B.W + 0.6, B.sakak + 6, 50 - B.W + 3, B.sakak + 14); c.stroke(rgba("#fffbe8", 0.5), 1.4)
	c.restore()
	_sac_on(c, g, B)
	c.restore()
	c.restore()
	if zemin:
		c.save(); c.bp(); c.rc(0, 0, 100, 120); c.clip()
		c.frect(0, 0, 100, 120, c.dai(50, 56, 40, 50, 60, 78, [[0.0, Color(0, 0, 0, 0)], [1.0, Color(0, 0, 0, 0.35)]]))
		c.restore()
	return g
