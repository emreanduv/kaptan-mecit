# Mr. Anduv! ortak arma ve kupa çizicisi (F2) — Kaptan Mecit 3 (Godot) portu.
# Champion Battle Manager / KM Klasik'teki www/klasik/arma.js ile birebir: tohum kulübün kimliğinden (id, yoksa ad),
# String.hash() (djb2, yuz.js ile aynı) + mulberry32 sırası; kalkan biçimi (6), bölüm deseni (7), şehre göre simge,
# kısaltma şeridi, şampiyonluk yıldızları; kupa biçimleri (lig, ulusal kupa, kulaklı, vazo, ince, küre, milli).
# Gerçek kulüp armaları kopyalanmaz; yalnız kulübün iki rengi (ve varsa şehri) kullanılır.
# Çizim, Yuz'un küçük tuvali (Yuz.Kalem: yol, degrade, kırpma, kontur) ile komut listesine çevrilir, bellekte tutulur.
# Kullanım:
#   Arma.yeni(takim, Vector2(28, 28))                 → kulüp arması (takım sözlüğü: id, ad, kisa, c1, c2[, sehir])
#   Arma.kupa_yeni({"kod": "avr" | "tur": "lig", "k1": .., "k2": ..}, Vector2(40, 50))
#   Arma.kupa_ani(agac, {"ad": kupa adı, "kod": .., "tur": "lig", "takim": takim, "en": false})   → tam ekran kupa kaldırma anı
extends Control
class_name Arma

const KONTUR := Color("#1e130b")
const BICIM := ["kalkan", "sivri", "yuvarlak", "madalyon", "kose", "kalkan"]
const DESEN := ["capraz", "dikey", "yari", "kusak", "serit", "kama", "duz"]
const SIMGE_KIYI := ["capa", "kadirga", "dalga", "fener"]
const SIMGE_ORTA := ["kule", "yildiz", "cinar", "mesale", "gunes", "lale", "kurt", "top", "kule", "yildiz"]
const KIYI := "istanbul|izmir|trabzon|antalya|alanya|samsun|rize|giresun|mersin|bodrum|ordu|sinop|zonguldak|kocaeli|bursa|tekirdağ|çanakkale|balıkesir|aydın|muğla|hatay|iskenderun|lizbon|porto|barselona|barcelona|marsilya|napoli|cenova|genova|liverpool|amsterdam|rotterdam|hamburg|bremen|kopenhag|glasgow|aberdeen|valensiya|valencia|sevilla|bilbao|lisbon|atina|selanik|pire|odessa|bakü|baku|cádiz|vigo|malaga|málaga|palermo|bari|venedik|southampton|brighton|newcastle|sunderland|nantes|bordo|nice|lorient|brest|le havre|santos|rio|buenos"
const DAGLI := "erzurum|kars|van|sivas|kayseri|ağrı|bayburt|gümüşhane|erzincan|bolu|denizli|isparta|torino|grenoble|innsbruck|salzburg|bern|zürih|zurich|cenevre|la paz|quito|bogota|tiflis|yerevan|bişkek|almatı|almaty|taşkent"

var veri: Dictionary = {}
var kupa := false
static var _bellek := {}
static var _yazi: Font

static func yeni(takim: Dictionary, boy: Vector2) -> Arma:
	var a := Arma.new()
	a.veri = kulup(takim); a.custom_minimum_size = boy
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return a

static func kupa_yeni(o: Dictionary, boy: Vector2) -> Arma:
	var a := Arma.new()
	a.veri = o; a.kupa = true; a.custom_minimum_size = boy
	a.mouse_filter = Control.MOUSE_FILTER_IGNORE
	a.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	return a

# KM3 takım sözlüğü → arma.js kulüp nesnesi (Klasik: {id, ad: name, kisa: short, renk1: c1, renk2: c2, sehir: city})
static func kulup(t: Dictionary) -> Dictionary:
	if t.has("renk1"): return t
	return {"id": str(t.get("id", "")), "ad": str(t.get("ad", "?")), "kisa": str(t.get("kisa", "")),
		"renk1": str(t.get("c1", "#3e6a8a")), "renk2": str(t.get("c2", "#f2f2f2")), "sehir": str(t.get("sehir", ""))}

# KM3 kupa kimliği → arma.js kupa kodu (aynı biçim iki oyunda)
static func kupa_kodu(id: String) -> String:
	return {"avr": "ucl", "kit": "kik", "ipe": "ipek", "kon": "lib", "kuz": "cnc", "sav": "savana"}.get(id, id)

static func yazi() -> Font:
	if _yazi == null:
		var f := FontVariation.new(); f.base_font = ThemeDB.fallback_font; f.variation_embolden = 1.1
		_yazi = f
	return _yazi

# ---------------- renk ----------------
static func fark(a, b) -> float:
	var x := Yuz.renk(a); var y := Yuz.renk(b)
	return absf(x.r8 - y.r8) + absf(x.g8 - y.g8) + absf(x.b8 - y.b8)
static func yazi_renk(c) -> Color:
	return Color("#1a1410") if Yuz.isik(c) > 150 else Color("#fffaf0")

static func _eslesir(desen: String, s: String) -> bool:
	if s == "": return false
	var r := RegEx.new(); r.compile("(?i)" + desen)
	return r.search(s) != null

static func ozellik(k: Dictionary) -> Dictionary:
	var anahtar := str(k.get("id", ""))
	if anahtar == "": anahtar = str(k.get("ad", ""))
	if anahtar == "": anahtar = str(k.get("kisa", "?"))
	var R := Yuz.Rast.new(Yuz.hash_ad(anahtar + "#arma"))
	var r1 = str(k.get("renk1", "#3e6a8a")); var r2 = str(k.get("renk2", "#f2f2f2"))
	if fark(r1, r2) < 90: r2 = (Yuz.ton(r1, -0.55) if Yuz.isik(r1) > 128 else Yuz.ton(r1, 0.7)).to_html(false)
	var sehir := str(k.get("sehir", ""))
	var liste: Array = SIMGE_KIYI if _eslesir(KIYI, sehir) else (["dag", "dag", "kule", "kurt"] if _eslesir(DAGLI, sehir) else SIMGE_ORTA)
	var simge: String = liste[int(floor(R.f() * liste.size()))]
	var bicim: String = BICIM[int(floor(R.f() * BICIM.size()))]
	var desen: String = DESEN[int(floor(R.f() * DESEN.size()))]
	var yildiz := 0
	if R.f() < 0.3: yildiz = 1 + int(floor(R.f() * 3))
	var ks := str(k.get("kisa", ""))
	if ks == "": ks = str(k.get("ad", "?")).substr(0, 3)
	return {"r1": Yuz.renk(r1), "r2": Yuz.renk(r2), "simge": simge, "bicim": bicim, "desen": desen, "yildiz": yildiz,
		"kisa": ks.to_upper(), "cerceve": "altin" if R.f() < 0.5 else "krem"}

# ---------------- yol yardımcıları (Kalem'in el()'i yolu sıfırladığı için birleşik yollarda bunlar) ----------------
static func _daire(c, x: float, y: float, r: float) -> void:
	_elips(c, x, y, r, r)
static func _elips(c, x: float, y: float, rx: float, ry: float, a0 := 0.0, a1 := TAU, kapali := true) -> void:
	var n := 28
	for i in n + 1:
		if kapali and i == n: break
		var t := a0 + (a1 - a0) * i / n
		var p := Vector2(x + cos(t) * rx, y + sin(t) * ry)
		if i == 0: c.mt(p.x, p.y)
		else: c.lt(p.x, p.y)
	if kapali: c.cp()

static func _yildiz_yol(c, x: float, y: float, R: float, r: float, n := 5) -> void:
	c.mt(x, y - R)
	for i in range(1, n * 2):
		var a := -PI / 2 + i * PI / n; var q := r if i % 2 else R
		c.lt(x + cos(a) * q, y + sin(a) * q)
	c.cp()

static func _bicim_yolu(c, b: String) -> void:
	c.bp()
	if b == "kalkan":
		c.mt(-0.86, -0.86); c.qt(0, -1.0, 0.86, -0.86)
		c.lt(0.86, -0.05); c.bt(0.86, 0.5, 0.42, 0.82, 0, 1.0)
		c.bt(-0.42, 0.82, -0.86, 0.5, -0.86, -0.05); c.cp()
	elif b == "sivri":
		c.mt(0, -1.0); c.qt(0.4, -0.78, 0.86, -0.8)
		c.lt(0.86, 0.0); c.bt(0.86, 0.52, 0.4, 0.8, 0, 1.0)
		c.bt(-0.4, 0.8, -0.86, 0.52, -0.86, 0.0); c.lt(-0.86, -0.8)
		c.qt(-0.4, -0.78, 0, -1.0); c.cp()
	elif b == "yuvarlak":
		_daire(c, 0, 0, 0.94)
	elif b == "madalyon":
		_elips(c, 0, 0, 0.8, 0.97)
	else:   # kose: köşeleri içe oyulmuş kare kalkan
		var r := 0.2
		c.mt(-0.86 + r, -0.9); c.lt(0.86 - r, -0.9); c.ar(0.86, -0.9, r, PI, PI / 2)
		c.lt(0.86, 0.25); c.qt(0.86, 0.72, 0, 0.98); c.qt(-0.86, 0.72, -0.86, 0.25)
		c.lt(-0.86, -0.9 + r); c.ar(-0.86, -0.9, r, PI / 2, 0); c.cp()

static func _desen_ciz(c, o: Dictionary) -> void:
	c.frect(-1.2, -1.2, 2.4, 2.4, o.r1)
	c.bp()
	match o.desen:
		"capraz": c.mt(-1.2, 1.2); c.lt(1.2, -1.2); c.lt(1.2, 1.2); c.cp()
		"dikey":
			for i in [-2, 0, 2]: c.rc(i * 0.19 - 0.095 + 0.19, -1.2, 0.19, 2.4)
		"yari": c.rc(0, -1.2, 1.2, 2.4)
		"kusak": c.rc(-1.2, -0.18, 2.4, 0.36)
		"serit": c.mt(-1.2, -0.55); c.lt(-0.75, -1.2); c.lt(1.2, 0.75); c.lt(1.2, 1.2); c.lt(0.75, 1.2); c.lt(-1.2, -0.75); c.cp()
		"kama": c.mt(-1.2, 1.2); c.lt(0, 0.05); c.lt(1.2, 1.2); c.cp()
		_: _daire(c, 0, -0.05, 0.62)
	c.fill(o.r2)

# ---------------- simgeler (birim kutu ~ -0.5..0.5) ----------------
static func _simge_yol(c, s: String) -> void:
	match s:
		"capa":
			c.mt(-0.04, -0.34); c.lt(0.04, -0.34); c.lt(0.04, 0.32); c.lt(-0.04, 0.32); c.cp()
			c.mt(-0.2, -0.24); c.lt(0.2, -0.24); c.lt(0.2, -0.17); c.lt(-0.2, -0.17); c.cp()
			_daire(c, 0, -0.42, 0.075)
			c.mt(-0.36, 0.06); c.qt(-0.32, 0.4, 0, 0.44); c.qt(0.32, 0.4, 0.36, 0.06)
			c.lt(0.42, 0.16); c.lt(0.3, 0.12); c.qt(0.26, 0.32, 0, 0.35)
			c.qt(-0.26, 0.32, -0.3, 0.12); c.lt(-0.42, 0.16); c.cp()
		"kadirga":
			c.mt(-0.44, 0.12); c.lt(0.44, 0.12); c.qt(0.34, 0.34, 0.2, 0.36); c.lt(-0.24, 0.36); c.qt(-0.38, 0.3, -0.44, 0.12); c.cp()
			c.mt(-0.025, 0.12); c.lt(-0.025, -0.44); c.lt(0.025, -0.44); c.lt(0.025, 0.12); c.cp()
			c.mt(0.05, -0.38); c.qt(0.34, -0.16, 0.32, 0.06); c.lt(0.05, 0.06); c.cp()
			c.mt(-0.05, -0.32); c.qt(-0.3, -0.12, -0.28, 0.06); c.lt(-0.05, 0.06); c.cp()
			c.mt(0.03, -0.44); c.lt(0.18, -0.4); c.lt(0.03, -0.36); c.cp()
		"dalga":
			for j in 3:
				var y := -0.26 + j * 0.24
				c.mt(-0.44, y + 0.05)
				c.bt(-0.3, y - 0.12, -0.16, y - 0.12, -0.02, y + 0.02)
				c.bt(0.12, y - 0.12, 0.28, y - 0.12, 0.44, y + 0.03)
				c.lt(0.44, y + 0.12); c.bt(0.28, y - 0.02, 0.12, y - 0.02, -0.02, y + 0.11)
				c.bt(-0.16, y - 0.02, -0.3, y - 0.02, -0.44, y + 0.14); c.cp()
		"fener":
			c.mt(-0.12, 0.38); c.lt(-0.08, -0.16); c.lt(0.08, -0.16); c.lt(0.12, 0.38); c.cp()
			c.mt(-0.13, -0.18); c.lt(0.13, -0.18); c.lt(0.13, -0.24); c.lt(-0.13, -0.24); c.cp()
			c.mt(-0.09, -0.26); c.lt(0.09, -0.26); c.lt(0.09, -0.36); c.lt(-0.09, -0.36); c.cp()
			c.mt(-0.11, -0.37); c.lt(0, -0.46); c.lt(0.11, -0.37); c.cp()
			c.mt(-0.2, 0.38); c.lt(0.2, 0.38); c.lt(0.24, 0.44); c.lt(-0.24, 0.44); c.cp()
			c.mt(0.12, -0.33); c.lt(0.44, -0.42); c.lt(0.44, -0.2); c.cp()
			c.mt(-0.12, -0.33); c.lt(-0.44, -0.42); c.lt(-0.44, -0.2); c.cp()
		"dag":
			c.mt(-0.46, 0.3); c.lt(-0.16, -0.16); c.lt(-0.06, -0.04); c.lt(0.12, -0.36); c.lt(0.46, 0.3); c.cp()
		"kule":
			c.mt(-0.24, 0.42); c.lt(-0.2, -0.18); c.lt(0.2, -0.18); c.lt(0.24, 0.42); c.cp()
			c.mt(-0.3, -0.18); c.lt(-0.3, -0.38); c.lt(-0.19, -0.38); c.lt(-0.19, -0.3); c.lt(-0.06, -0.3); c.lt(-0.06, -0.38)
			c.lt(0.06, -0.38); c.lt(0.06, -0.3); c.lt(0.19, -0.3); c.lt(0.19, -0.38); c.lt(0.3, -0.38); c.lt(0.3, -0.18); c.cp()
		"yildiz":
			_yildiz_yol(c, 0, 0.02, 0.46, 0.19, 5)
		"cinar":   # beş loplu çınar yaprağı
			c.mt(0, 0.24)
			for p in [[-0.12, 0.2], [-0.42, 0.18], [-0.3, 0.06], [-0.46, -0.1], [-0.26, -0.12], [-0.3, -0.36], [-0.1, -0.2], [0, -0.46],
					[0.1, -0.2], [0.3, -0.36], [0.26, -0.12], [0.46, -0.1], [0.3, 0.06], [0.42, 0.18], [0.12, 0.2]]:
				c.lt(p[0], p[1])
			c.cp()
			c.mt(-0.025, 0.2); c.lt(0.025, 0.2); c.lt(0.04, 0.46); c.lt(-0.01, 0.46); c.cp()
		"mesale":
			c.mt(-0.1, -0.06); c.lt(0.1, -0.06); c.lt(0.04, 0.46); c.lt(-0.04, 0.46); c.cp()
			c.mt(-0.15, -0.06); c.lt(0.15, -0.06); c.lt(0.13, -0.13); c.lt(-0.13, -0.13); c.cp()
			c.mt(0, -0.48); c.bt(0.24, -0.34, 0.2, -0.2, 0.12, -0.15); c.bt(0.14, -0.24, 0.06, -0.28, 0.04, -0.3)
			c.bt(0.04, -0.2, -0.04, -0.2, -0.04, -0.15); c.lt(-0.12, -0.15); c.bt(-0.22, -0.24, -0.12, -0.38, 0, -0.48); c.cp()
		"gunes":
			_daire(c, 0, 0, 0.2)
			for i in 12:
				var a := i * PI / 6; var a1 := a - 0.11; var a2 := a + 0.11; var R := 0.4 if i % 2 else 0.47
				c.mt(cos(a1) * 0.25, sin(a1) * 0.25); c.lt(cos(a) * R, sin(a) * R); c.lt(cos(a2) * 0.25, sin(a2) * 0.25); c.cp()
		"lale":
			c.mt(0, -0.08); c.bt(-0.08, -0.22, -0.06, -0.38, 0, -0.46); c.bt(0.06, -0.38, 0.08, -0.22, 0, -0.08); c.cp()
			c.mt(-0.02, -0.08); c.bt(-0.24, -0.12, -0.28, -0.3, -0.24, -0.42); c.bt(-0.14, -0.3, -0.06, -0.24, -0.02, -0.18); c.cp()
			c.mt(0.02, -0.08); c.bt(0.24, -0.12, 0.28, -0.3, 0.24, -0.42); c.bt(0.14, -0.3, 0.06, -0.24, 0.02, -0.18); c.cp()
			c.mt(-0.022, -0.08); c.lt(0.022, -0.08); c.qt(0.04, 0.2, 0.02, 0.46); c.lt(-0.02, 0.46); c.qt(0, 0.2, -0.022, -0.08); c.cp()
			c.mt(0, 0.3); c.bt(-0.16, 0.24, -0.3, 0.1, -0.3, -0.02); c.bt(-0.14, 0.04, -0.04, 0.16, 0, 0.24); c.cp()
		"kurt":   # yandan bozkurt başı (Tamga/Kurt Yolu Bozbörü silueti, sola bakar)
			c.mt(0.36, 0.44)
			for p in [[0.28, 0.06], [0.3, -0.2], [0.22, -0.46], [0.08, -0.26], [-0.02, -0.3], [-0.06, -0.46], [-0.16, -0.22], [-0.3, -0.12],
					[-0.46, -0.02], [-0.44, 0.06], [-0.3, 0.08], [-0.2, 0.14], [-0.1, 0.28], [0.02, 0.44]]:
				c.lt(p[0], p[1])
			c.cp()
		_:   # top
			_daire(c, 0, 0, 0.4)

static func _simge_ciz(c, o: Dictionary, s: float, renk: Color, golge: Color) -> void:
	var ad: String = o.simge
	c.save(); c.sc(s)
	c.save(); c.tasi(0.025, 0.035); c.bp(); _simge_yol(c, ad); c.fill(Color(10 / 255.0, 6 / 255.0, 4 / 255.0, 0.35)); c.restore()
	c.bp(); _simge_yol(c, ad)
	c.stroke(golge, 0.06)
	c.fill(c.dog(-0.4, -0.45, 0.35, 0.45, [[0.0, Yuz.ton(renk, 0.35)], [0.55, renk], [1.0, Yuz.ton(renk, -0.22)]]))
	if ad == "top":   # beşgen yamalar
		c.bp(); _yildiz_yol(c, 0, 0, 0.13, 0.13 * 0.81, 5); c.fill(golge)
		c.save(); c.bp(); _daire(c, 0, 0, 0.4); c.clip()
		for i in 5:
			var a := -PI / 2 + i * TAU / 5
			c.bp(); _daire(c, cos(a) * 0.4, sin(a) * 0.4, 0.11); c.fill(golge)
		c.restore()
	if ad == "dag":   # kar başlığı
		c.save(); c.bp(); _simge_yol(c, ad); c.clip()
		c.bp(); c.mt(0.12, -0.4); c.lt(0.27, -0.08); c.lt(0.17, -0.14); c.lt(0.1, -0.06); c.lt(0.02, -0.16); c.lt(-0.06, -0.06); c.cp(); c.fill(Color("#fbf8f0"))
		c.bp(); c.mt(-0.16, -0.2); c.lt(-0.06, -0.05); c.lt(-0.13, -0.08); c.lt(-0.2, -0.02); c.lt(-0.26, -0.06); c.cp(); c.fill(Color("#fbf8f0"))
		c.restore()
	if ad == "kurt": c.bp(); _daire(c, -0.12, -0.08, 0.035); c.fill(Color("#ffd25a"))
	if ad == "mesale": c.bp(); _daire(c, 0, -0.28, 0.1); c.fill(Color(1, 214 / 255.0, 90 / 255.0, 0.55))
	c.restore()

# metin komutu: [2, merkez, boy, renk, kontur rengi | null, kontur kalınlığı, en geniş] (Kalem'in mantıksal pikselinde)
static func _metin(c, t: String, x: float, y: float, boy: float, renk: Color, kontur, kk: float, genis: float) -> void:
	c._bosalt()
	var k: float = c._olcek()
	c.K.append([2, c.T * Vector2(x, y), boy * k, renk, kontur, kk * k, genis * k, t])

# ana çizici: mantıksal tuval 100 × 100; px = ekrandaki yaklaşık boy (ince çizgiler bir piksel kalsın, küçükte simge yok)
static func ciz(c, kulup_: Dictionary, px: float) -> void:
	var o := ozellik(kulup_)
	var buyuk := px >= 44
	var s := px / 2.0
	c.save(); c.bp(); c.rc(0, 0, 100, 100); c.clip()
	c.tasi(50, 50); c.sc(50)
	if o.yildiz and buyuk: c.sc(0.88); c.tasi(0, 0.08); s *= 0.88
	var lw := 1.0 / s
	# yer gölgesi
	c.save(); c.tasi(0.03, 0.07); c.sc(0.97); _bicim_yolu(c, o.bicim); c.fill(Color(20 / 255.0, 12 / 255.0, 6 / 255.0, 0.38)); c.restore()
	# dış çerçeve (metal)
	var altin: bool = o.cerceve == "altin"
	c.save(); c.sc(0.97); _bicim_yolu(c, o.bicim)
	c.fill(c.dog(-1, -1, 1, 1, [[0.0, Color("#f7dc84" if altin else "#fbf6ea")], [0.5, Color("#d9ae4c" if altin else "#efe7d6")], [1.0, Color("#b3832a" if altin else "#cfc5b0")]]))
	c.stroke(KONTUR, maxf(0.045, 1.2 * lw)); c.restore()
	# iç alan
	var ic := 0.83 if buyuk else 0.8
	c.save(); c.sc(ic); _bicim_yolu(c, o.bicim); c.clip()
	_desen_ciz(c, o)
	if buyuk:
		var sr: Color = Yuz.ton(o.r2, 0) if Yuz.isik(o.r1) > 150 else Color("#fbf3df")
		if fark(sr, o.r1) < 120 and fark(sr, o.r2) < 120: sr = Color("#f3cf5a")
		c.save(); c.tasi(0, -0.2); _simge_ciz(c, o, 1.12, Color("#fbf8f0") if o.simge == "top" else sr, KONTUR); c.restore()
	# hacim: üst sol ışık, alt sağ gölge
	c.frect(-1.2, -1.2, 2.4, 2.4, c.dai(-0.45, -0.6, 0.05, -0.2, -0.3, 1.5, [[0.0, Color(1, 250 / 255.0, 235 / 255.0, 0.42)], [0.45, Color(1, 250 / 255.0, 235 / 255.0, 0.05)], [1.0, Color(10 / 255.0, 6 / 255.0, 4 / 255.0, 0.32)]]))
	# cam parıltısı
	c.bp(); c.mt(-1.1, -1.1); c.lt(0.4, -1.1); c.qt(-0.1, -0.35, -1.1, -0.05); c.cp(); c.fill(Color(1, 1, 1, 0.16))
	c.restore()
	# iç kontur ve ince çift halka
	c.save(); c.sc(ic); _bicim_yolu(c, o.bicim); c.stroke(KONTUR, maxf(0.03, lw) / ic); c.restore()
	if buyuk: c.save(); c.sc(ic - 0.06); _bicim_yolu(c, o.bicim); c.stroke(Color(1, 248 / 255.0, 225 / 255.0, 0.55), 0.012 / ic); c.restore()
	var ks: String = o.kisa
	if buyuk:
		var sy := 0.4; var sh := 0.3
		c.bp(); c.mt(-0.98, sy - sh / 2 + 0.04); c.lt(0.98, sy - sh / 2 + 0.04); c.lt(0.88, sy + 0.02); c.lt(0.98, sy + sh / 2 + 0.04)
		c.lt(-0.98, sy + sh / 2 + 0.04); c.lt(-0.88, sy + 0.02); c.cp(); c.fill(Color(20 / 255.0, 12 / 255.0, 6 / 255.0, 0.35))
		var serit := func() -> void:
			c.bp(); c.mt(-0.96, sy - sh / 2); c.lt(0.96, sy - sh / 2); c.lt(0.86, sy); c.lt(0.96, sy + sh / 2)
			c.lt(-0.96, sy + sh / 2); c.lt(-0.86, sy); c.cp()
		var bant: Color = Yuz.ton(o.r2, -0.25) if Yuz.isik(o.r1) > 170 else Yuz.ton(o.r1, -0.35)
		serit.call(); c.fill(c.dog(0, sy - sh / 2, 0, sy + sh / 2, [[0.0, Yuz.ton(bant, 0.22)], [1.0, Yuz.ton(bant, -0.2)]]))
		serit.call(); c.stroke(KONTUR, maxf(0.03, lw))
		c.bp(); c.mt(-0.8, sy - sh / 2 + 0.05); c.lt(0.8, sy - sh / 2 + 0.05); c.stroke(Color(1, 240 / 255.0, 200 / 255.0, 0.35), 0.02)
		_metin(c, ks, 0, sy + 0.012, 0.21 if ks.length() > 3 else 0.25, yazi_renk(bant), null, 0, 1.5)
		for i in o.yildiz:
			var yx: float = (i - (o.yildiz - 1) / 2.0) * 0.22
			c.bp(); _yildiz_yol(c, yx, -1.07, 0.1, 0.042, 5); c.fill(Color("#f6cf55")); c.stroke(KONTUR, 0.022)
	else:
		var ty := -0.06 if o.bicim in ["kalkan", "sivri", "kose"] else 0.0
		var zemin: Color = o.r1 if o.desen in ["duz", "kusak"] else Yuz.karis(o.r1, o.r2, 0.5)
		var acik := Yuz.isik(zemin) > 140
		var yr := Color("#1a1410") if acik else Color("#fffaf0")
		var kr := Color(1, 250 / 255.0, 238 / 255.0, 0.9) if acik else Color(20 / 255.0, 12 / 255.0, 6 / 255.0, 0.85)
		_metin(c, ks, 0, ty, 0.46 if ks.length() > 3 else 0.56, yr, kr, 0.13, 1.45)
	c.restore()

static func komutlar(o: Dictionary, k: bool, px: float) -> Array:
	var anahtar := JSON.stringify(o) + ("K" if k else "A") + str(snappedf(px, 4.0))
	if _bellek.has(anahtar): return _bellek[anahtar]
	if _bellek.size() > 400: _bellek.clear()
	var c := Yuz.Kalem.new()
	if k: kupa_ciz(c, o, px)
	else: ciz(c, o, px)
	c.bitir()
	_bellek[anahtar] = c.K
	return c.K

func _draw() -> void:
	if veri.is_empty(): return
	var px := minf(size.x, size.y) if not kupa else size.x
	var K := komutlar(veri, kupa, px)
	var lw := 100.0; var lh := 123.0 if kupa else 100.0
	var s := minf(size.x / lw, size.y / lh)
	ciz_komut(self, K, Transform2D(0.0, Vector2(s, s), 0.0, Vector2((size.x - lw * s) / 2.0, (size.y - lh * s) / 2.0)), s)

# komut listesini bir CanvasItem'a çiz (kupa anı da kullanır)
static func ciz_komut(ci: CanvasItem, K: Array, xf: Transform2D, s: float, alfa := 1.0) -> void:
	var rid := ci.get_canvas_item()
	for k in K:
		if k[0] == 0:
			var cl: PackedColorArray = k[2]
			if alfa < 1.0:
				cl = cl.duplicate()
				for i in cl.size(): cl[i].a *= alfa
			RenderingServer.canvas_item_add_triangle_array(rid, k[3], xf * (k[1] as PackedVector2Array), cl)
		elif k[0] == 1:
			var c1: Color = k[2]; c1.a *= alfa
			ci.draw_polyline(xf * (k[1] as PackedVector2Array), c1, maxf(0.6, k[3] * s), true)
		else:
			var f := yazi()
			var t: String = k[7]
			var boy := maxi(5, int(round(k[2] * s)))
			var w := f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, boy).x
			var en: float = k[6] * s
			if w > en and w > 0:
				boy = maxi(5, int(floor(boy * en / w))); w = f.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, boy).x
			var p: Vector2 = xf * (k[1] as Vector2)
			var tp := Vector2(p.x - w / 2.0, p.y + (f.get_ascent(boy) - f.get_descent(boy)) / 2.0)
			var renk: Color = k[3]; renk.a *= alfa
			if k[4] is Color:
				var kr: Color = k[4]; kr.a *= alfa
				ci.draw_string_outline(f, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, boy, maxi(1, int(round(k[5] * s))), kr)
			ci.draw_string(f, tp, t, HORIZONTAL_ALIGNMENT_LEFT, -1, boy, renk)

# ---------------- kupa ----------------
static func kupa_tur(o: Dictionary) -> String:
	var k := str(o.get("kod", o.get("tur", "")))
	if str(o.get("tur", "")) == "lig" or o.get("lig", false): return "lig"
	if o.get("milli", false) or str(o.get("tur", "")) == "milli" or k == "mil": return "milli"
	k = kupa_kodu(k)
	if k == "ucl": return "kulakli"
	if k == "uel": return "vazo"
	if k == "uecl": return "ince"
	if k == "kik": return "kure"
	if k.contains("ipek") or k.contains("cnc") or k.contains("lib") or k.contains("savana"):
		return ["vazo", "kure", "kulakli", "ince"][Yuz.hash_ad(k) % 4]
	return "kupa"

const PROFIL := {   # kâse yarı genişliği (üst, orta, alt), kâse yüksekliği, kulp biçimi, ayak yüksekliği, kapak
	"lig": {"ust": 0.36, "orta": 0.34, "alt": 0.12, "kh": 0.46, "kulp": "yuvarlak", "ayak": 0.16, "kapak": 1, "kaide": 0.2},
	"kupa": {"ust": 0.34, "orta": 0.24, "alt": 0.08, "kh": 0.42, "kulp": "kivrik", "ayak": 0.2, "kapak": 0, "kaide": 0.18},
	"kulakli": {"ust": 0.26, "orta": 0.3, "alt": 0.1, "kh": 0.5, "kulp": "kulak", "ayak": 0.16, "kapak": 0, "kaide": 0.18},
	"vazo": {"ust": 0.2, "orta": 0.3, "alt": 0.12, "kh": 0.56, "kulp": "ince", "ayak": 0.12, "kapak": 0, "kaide": 0.2},
	"ince": {"ust": 0.24, "orta": 0.18, "alt": 0.07, "kh": 0.48, "kulp": "yok", "ayak": 0.24, "kapak": 0, "kaide": 0.16},
	"kure": {"ust": 0.0, "orta": 0.0, "alt": 0.0, "kh": 0.0, "kulp": "yok", "ayak": 0.36, "kapak": 0, "kaide": 0.2, "kure": 1},
	"milli": {"ust": 0.0, "orta": 0.0, "alt": 0.0, "kh": 0.0, "kulp": "yok", "ayak": 0.42, "kapak": 0, "kaide": 0.18, "kure": 1, "sarmal": 1}}

static func _metal(c, x0: float, y0: float, x1: float, y1: float, gumus: bool) -> Dictionary:
	var s: Array = ["#5d646b", "#c9d0d6", "#ffffff", "#aab3bb", "#6d757c", "#dfe5ea"] if gumus else ["#7a4e12", "#d9a43a", "#fff1b0", "#e7b84a", "#8a5a16", "#f3cf6a"]
	return c.dog(x0, y0, x1, y1, [[0.0, Color(s[0])], [0.18, Color(s[1])], [0.32, Color(s[2])], [0.5, Color(s[3])], [0.78, Color(s[4])], [1.0, Color(s[5])]])

# mantıksal tuval 100 × 123 (arma.js kupaCiz ile aynı oran ve yerleşim)
static func kupa_ciz(c, o: Dictionary, px: float) -> void:
	var tur := kupa_tur(o); var p: Dictionary = PROFIL[tur]
	var gumus: bool = tur == "ince" and not o.get("altin", false)
	var k1 := Yuz.renk(o.get("k1", "#c0392b")); var k2 := Yuz.renk(o.get("k2", "#f2f2f2"))
	var W := 100.0; var H := 123.0
	var s := minf(W / (1.6 if tur == "kulakli" else 1.45), H / 1.32)
	var ps := px / 100.0   # gerçek piksel / mantıksal
	c.save(); c.tasi(W / 2, H / 2 - s * 0.14); c.sc(s)
	var lw := 1.0 / (s * ps)
	var KL := maxf(0.012, 1.1 * lw)
	var MO := Color("#d9a43a") if not gumus else Color("#c9d0d6")   # çizgi (kulp) metali
	var tabanY := 0.72; var kaideU: float = tabanY - p.kaide
	# yer gölgesi
	c.bp(); _elips(c, 0, tabanY + 0.02, 0.5, 0.07)
	c.fill(c.dai(0, tabanY + 0.02, 0.02, 0, tabanY + 0.02, 0.5, [[0.0, Color(10 / 255.0, 6 / 255.0, 4 / 255.0, 0.45)], [1.0, Color(10 / 255.0, 6 / 255.0, 4 / 255.0, 0)]]))
	# kaide (koyu ağaç, iki kademe)
	c.bp(); c.mt(-0.34, tabanY); c.lt(0.34, tabanY); c.lt(0.3, kaideU + 0.06); c.lt(-0.3, kaideU + 0.06); c.cp()
	c.fill(c.dog(-0.34, 0, 0.34, 0, [[0.0, Color("#2a1a12")], [0.35, Color("#5a3a26")], [0.6, Color("#3e2718")], [1.0, Color("#1e130b")]])); c.stroke(KONTUR, KL)
	# plaket
	c.bp(); c.rc(-0.16, kaideU + 0.1, 0.32, maxf(0.05, p.kaide - 0.14)); c.fill(_metal(c, -0.16, 0, 0.16, 0.1, gumus)); c.stroke(KONTUR, KL * 0.7)
	c.bp(); c.mt(-0.11, kaideU + 0.1 + (p.kaide - 0.14) / 2); c.lt(0.11, kaideU + 0.1 + (p.kaide - 0.14) / 2); c.stroke(Color(60 / 255.0, 35 / 255.0, 10 / 255.0, 0.55), 0.012)
	# üst kademe
	c.bp(); c.mt(-0.27, kaideU + 0.06); c.lt(0.27, kaideU + 0.06); c.lt(0.22, kaideU); c.lt(-0.22, kaideU); c.cp()
	c.fill(_metal(c, -0.27, 0, 0.27, 0.06, gumus)); c.stroke(KONTUR, KL)
	# ayak
	var ayakU: float = kaideU - p.ayak
	c.bp(); c.mt(-0.16, kaideU); c.qt(-0.05, kaideU - 0.02, -0.045, kaideU - p.ayak * 0.4)
	c.lt(-0.035, ayakU + 0.02); c.lt(0.035, ayakU + 0.02); c.lt(0.045, kaideU - p.ayak * 0.4); c.qt(0.05, kaideU - 0.02, 0.16, kaideU); c.cp()
	c.fill(_metal(c, -0.16, 0, 0.16, 0, gumus)); c.stroke(KONTUR, KL)
	# boğum
	c.bp(); _elips(c, 0, kaideU - p.ayak * 0.45, 0.075, 0.035); c.fill(_metal(c, -0.075, 0, 0.075, 0, gumus)); c.stroke(KONTUR, KL)
	if p.has("sarmal"):   # milli: ayakta sarmal iki kurdele bant
		for sm in 3:
			var yy: float = ayakU + 0.06 + sm * p.ayak * 0.22
			c.el(0, yy, 0.06, 0.018, -0.3); c.fill(k1 if sm % 2 else k2); c.stroke(KONTUR, KL)
	var kaseA := ayakU; var kaseU: float = kaseA - p.kh
	if p.has("kure"):
		# küre tepeli kupa: altın kollar küreyi tutar
		var ky := ayakU - 0.24; var kr := 0.24
		for kl in [-1, 1]:
			c.bp(); c.mt(kl * 0.035, ayakU + 0.02); c.bt(kl * 0.22, ayakU - 0.04, kl * 0.3, ky + 0.06, kl * 0.17, ky - 0.14)
			c.stroke(KONTUR, 0.07); c.stroke(MO, 0.045)
		c.bp(); _daire(c, 0, ky, kr)
		c.fill(c.dai(-0.09, ky - 0.1, 0.02, 0, ky, kr, [[0.0, Color("#fff6c8")], [0.35, Color("#eabd4e")], [0.8, Color("#9a6416")], [1.0, Color("#5e3a0c")]]))
		c.stroke(KONTUR, KL)
		# kıta çizgileri (meridyen / enlem)
		c.save(); c.bp(); _daire(c, 0, ky, kr); c.clip()
		var mc := Color(90 / 255.0, 55 / 255.0, 12 / 255.0, 0.55)
		for m in range(-2, 3): c.bp(); _elips(c, 0, ky, absf(m) * 0.08 + 0.001, kr); c.stroke(mc, 0.012)
		for e in range(-2, 3): c.bp(); _elips(c, 0, ky + e * 0.09, kr, 0.03); c.stroke(mc, 0.012)
		c.restore()
		kaseU = ky - kr
	else:
		# kulplar (kâsenin arkasında başlar)
		for t in [-1, 1]:
			c.bp()
			if p.kulp == "yuvarlak": c.mt(t * p.ust * 0.92, kaseU + 0.08); c.bt(t * (p.ust + 0.26), kaseU + 0.02, t * (p.ust + 0.24), kaseU + p.kh * 0.62, t * p.orta * 0.8, kaseU + p.kh * 0.72)
			elif p.kulp == "kivrik": c.mt(t * p.ust * 0.95, kaseU + 0.05); c.bt(t * (p.ust + 0.3), kaseU - 0.08, t * (p.ust + 0.22), kaseU + p.kh * 0.55, t * p.orta * 0.55, kaseU + p.kh * 0.85)
			elif p.kulp == "kulak": c.mt(t * p.ust * 0.9, kaseU + 0.04); c.bt(t * (p.ust + 0.42), kaseU - 0.12, t * (p.ust + 0.44), kaseU + p.kh * 0.9, t * p.alt * 1.2, kaseU + p.kh * 0.98)
			elif p.kulp == "ince": c.mt(t * p.ust, kaseU + 0.02); c.bt(t * (p.orta + 0.14), kaseU - 0.02, t * (p.orta + 0.16), kaseU + p.kh * 0.4, t * p.orta * 0.95, kaseU + p.kh * 0.55)
			else: continue
			c.stroke(KONTUR, 0.09 if p.kulp == "kulak" else 0.075)
			c.stroke(MO, 0.062 if p.kulp == "kulak" else 0.05)
			c.stroke(Color(1, 248 / 255.0, 210 / 255.0, 0.7), 0.014)
		# kâse
		var kase := func() -> void:
			c.bp(); c.mt(-p.ust, kaseU)
			c.bt(-p.orta * 1.05, kaseU + p.kh * 0.35, -p.orta * 0.95, kaseU + p.kh * 0.75, -p.alt, kaseA)
			c.lt(p.alt, kaseA)
			c.bt(p.orta * 0.95, kaseU + p.kh * 0.75, p.orta * 1.05, kaseU + p.kh * 0.35, p.ust, kaseU); c.cp()
		kase.call(); c.fill(_metal(c, -p.orta, 0, p.orta, 0, gumus)); c.stroke(KONTUR, KL)
		# ağız (elips) ve iç gölge
		c.bp(); _elips(c, 0, kaseU, p.ust, 0.045); c.fill(Color("#4c5359") if gumus else Color("#6a4210")); c.stroke(KONTUR, KL)
		c.bp(); _elips(c, 0, kaseU + 0.004, p.ust * 0.92, 0.03, PI, TAU, false); c.stroke(Color(1, 240 / 255.0, 190 / 255.0, 0.55), 0.012)
		# kabartma kuşak ve lale nakşı
		var ky2: float = kaseU + p.kh * 0.38
		c.bp(); c.mt(-p.orta * 1.02, ky2); c.qt(0, ky2 + 0.05, p.orta * 1.02, ky2); c.stroke(Color(90 / 255.0, 55 / 255.0, 12 / 255.0, 0.6), 0.016)
		c.save(); c.tasi(0, kaseU + p.kh * 0.6); c.sc(0.28); c.bp(); _simge_yol(c, "lale")
		c.fill(Color(80 / 255.0, 88 / 255.0, 95 / 255.0, 0.45) if gumus else Color(110 / 255.0, 66 / 255.0, 12 / 255.0, 0.45)); c.restore()
		var kapak_ek := 0.0
		if p.kapak:   # kapak ve tepe topuzu
			c.bp(); c.mt(-p.ust * 0.9, kaseU - 0.01); c.qt(0, kaseU - 0.2, p.ust * 0.9, kaseU - 0.01); c.cp()
			c.fill(_metal(c, -p.ust, 0, p.ust, 0, gumus)); c.stroke(KONTUR, KL)
			c.bp(); _daire(c, 0, kaseU - 0.17, 0.05); c.fill(_metal(c, -0.05, 0, 0.05, 0, gumus)); c.stroke(KONTUR, KL)
			c.bp(); _yildiz_yol(c, 0, kaseU - 0.27, 0.07, 0.03, 5); c.fill(_metal(c, -0.05, 0, 0.05, 0, gumus)); c.stroke(KONTUR, KL)
			kaseU -= 0.3; kapak_ek = 0.3
		# dikey parlak çizgi
		c.save(); kase.call(); c.clip()   # lambda kaseU'yu kapaktan önceki değeriyle tutar
		c.frect(-1, -1, 2, 2, c.dog(-p.orta, 0, p.orta, 0, [[0.18, Color(1, 1, 1, 0)], [0.27, Color(1, 1, 240 / 255.0, 0.75)], [0.33, Color(1, 1, 1, 0)], [1.0, Color(1, 1, 1, 0)]]))
		c.restore()
		# kurdeleler (kulüp renklerinde, kulplara bağlı)
		if p.kulp != "yok" and not o.get("kurdelesiz", false):
			for r in [-1, 1]:
				var bx: float = r * (p.ust + (0.3 if p.kulp == "kulak" else 0.17)); var by: float = kaseU + kapak_ek + p.kh * 0.25
				for q in 2:
					c.bp(); c.mt(bx, by)
					c.bt(bx + r * (0.06 + q * 0.04), by + 0.14, bx - r * 0.04, by + 0.26, bx + r * (0.03 + q * 0.06), by + 0.4 + q * 0.05)
					c.stroke(KONTUR, 0.06); c.stroke(k2 if q else k1, 0.044)
				c.bp(); _elips(c, bx, by, 0.045, 0.032); c.fill(k1); c.stroke(KONTUR, KL)
	# pırıltı yıldızları
	if not o.get("sade", false):
		var R2 := Yuz.Rast.new(Yuz.hash_ad(tur + str(o.get("kod", ""))))
		for i in 3:
			var px2 := (R2.f() - 0.5) * 0.7; var py := kaseU + R2.f() * 0.5; var pr := 0.04 + R2.f() * 0.05
			c.bp(); _yildiz_yol(c, px2, py, pr, pr * 0.18, 4); c.fill(Color(1, 252 / 255.0, 230 / 255.0, 0.9))
	c.restore()

# ---------------- kupa kaldırma anı ----------------
static func kupa_ani(agac: SceneTree, o: Dictionary) -> Control:
	var eski := agac.root.get_node_or_null("KupaAni")
	if eski: eski.queue_free()
	# arayüz CanvasLayer'larda: perde en üst katmanda olsun
	var kat := CanvasLayer.new(); kat.name = "KupaAni"; kat.layer = 120
	var a := KupaAni.new(); a.o = o
	kat.add_child(a); agac.root.add_child(kat)
	a.tree_exited.connect(func() -> void: if is_instance_valid(kat): kat.queue_free())
	return a

class KupaAni extends Control:
	var o: Dictionary
	var t := 0.0
	var k1: Color; var k2: Color
	var konfeti: Array = []; var fisek: Array = []
	var son_fisek := 0.0
	var R: Yuz.Rast
	var KK: Array; var KA: Array
	var yazi: VBoxContainer
	var renkler: Array

	func _ready() -> void:
		set_anchors_preset(Control.PRESET_FULL_RECT); size = get_viewport_rect().size; mouse_filter = Control.MOUSE_FILTER_STOP
		z_index = 100
		var takim: Dictionary = o.get("takim", {})
		var kf := Arma.ozellik(Arma.kulup(takim)); k1 = kf.r1; k2 = kf.r2
		var en: bool = o.get("en", false)
		KK = Arma.komutlar({"kod": str(o.get("kod", "")), "tur": str(o.get("tur", "")), "milli": o.get("milli", false), "k1": k1.to_html(false), "k2": k2.to_html(false), "altin": true}, true, 440.0)
		KA = Arma.komutlar(Arma.kulup(takim), false, 96.0)
		R = Yuz.Rast.new(Yuz.hash_ad(str(takim.get("ad", "")) + str(o.get("ad", ""))))
		renkler = [k1, k2, Color("#ffd969"), Color("#fff3c4"), k1, k2]
		for i in 160:
			konfeti.append({"x": R.f(), "y": -R.f() * 1.2, "vy": 0.08 + R.f() * 0.12, "vx": (R.f() - 0.5) * 0.04, "a": R.f() * 6, "va": (R.f() - 0.5) * 8, "w": 4 + R.f() * 6, "r": renkler[i % renkler.size()], "s": R.f() * 6})
		yazi = VBoxContainer.new(); yazi.mouse_filter = Control.MOUSE_FILTER_IGNORE; yazi.alignment = BoxContainer.ALIGNMENT_CENTER
		add_child(yazi)
		var satirlar := [["CHAMPIONS!" if en else "ŞAMPİYON!", 44, Color("#ffd969")], [str(takim.get("ad", "")), 24, Color("#fff8e6")],
			[str(o.get("ad", "")), 18, Color(1, 0.97, 0.9, 0.85)], ["Tap to continue" if en else "Devam etmek için dokun", 13, Color(1, 0.97, 0.9, 0.6)]]
		for s in satirlar:
			var l := Label.new(); l.text = s[0]; l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			l.add_theme_font_size_override("font_size", s[1]); l.add_theme_color_override("font_color", s[2])
			l.add_theme_color_override("font_shadow_color", Color(0, 0, 0, 0.65)); l.add_theme_constant_override("shadow_offset_y", 2)
			if s[1] >= 24: l.add_theme_font_override("font", Arma.yazi())
			yazi.add_child(l)
		Input.vibrate_handheld(120)

	func _yerlestir() -> void:
		var yatay := size.x > size.y * 1.15
		if yatay:
			yazi.position = Vector2(size.x * 0.56, 0); yazi.size = Vector2(size.x * 0.42, size.y)
		else:
			var h := 150.0
			yazi.position = Vector2(16, size.y - h - 28); yazi.size = Vector2(size.x - 32, h)

	func _process(d: float) -> void:
		t += minf(d, 0.05)
		position = Vector2.ZERO; size = get_viewport_rect().size   # kök pencerede çapalar boyut vermiyor
		_yerlestir()
		queue_redraw()

	func _input(e: InputEvent) -> void:
		var kapa := false
		if e is InputEventKey and e.pressed and e.physical_keycode in [KEY_SPACE, KEY_ENTER, KEY_KP_ENTER, KEY_ESCAPE]: kapa = true
		if (e is InputEventMouseButton and e.pressed) or (e is InputEventScreenTouch and e.pressed): kapa = true
		if e is InputEventJoypadButton and e.pressed: kapa = true
		get_viewport().set_input_as_handled()
		if kapa and t > 0.4: queue_free()

	func _draw() -> void:
		var W := size.x; var H := size.y
		# gece stadyumu
		draw_polygon(PackedVector2Array([Vector2(0, 0), Vector2(W, 0), Vector2(W, H * 0.55), Vector2(0, H * 0.55)]), PackedColorArray([Color("#04070d"), Color("#04070d"), Yuz.ton(k1, -0.82), Yuz.ton(k1, -0.82)]))
		draw_polygon(PackedVector2Array([Vector2(0, H * 0.55), Vector2(W, H * 0.55), Vector2(W, H), Vector2(0, H)]), PackedColorArray([Yuz.ton(k1, -0.82), Yuz.ton(k1, -0.82), Color("#020305"), Color("#020305")]))
		# tribün ışık noktaları
		var Rt := Yuz.Rast.new(7)
		for j in 120:
			var tx := Rt.f() * W; var ty := H * (0.45 + Rt.f() * 0.25); var fl := 0.3 + 0.7 * absf(sin(t * (1 + Rt.f() * 3) + j))
			draw_rect(Rect2(tx, ty, 1.6, 1.6), Color(1, 245 / 255.0, 220 / 255.0, 0.12 + 0.35 * fl * Rt.f()))
		var yuk := minf(1.0, t / 1.4); var e := 1.0 - pow(1.0 - yuk, 3)
		var yatay := W > H * 1.15; var mx := W * 0.34 if yatay else W / 2.0
		var kh := minf(H * 0.66, W * 0.42) if yatay else minf(H * 0.42, W * 0.82)
		var kw := kh * 100.0 / 123.0
		var kx := mx - kw / 2.0; var ky := (H * 0.42 if yatay else H * 0.36) - kh / 2.0 + (1.0 - e) * H * 0.5 + sin(t * 2) * 4 * e
		# projektör huzmeleri
		for b in 4:
			var bx := W * (-0.05 if b < 2 else 1.05); var by := H * (0.08 + (b % 2) * 0.1)
			var hx := mx + sin(t * 0.7 + b) * W * 0.12; var hy := ky + kh * 0.5
			var n := Vector2(hx - bx, hy - by).normalized().orthogonal() * minf(W, H) * 0.16
			draw_polygon(PackedVector2Array([Vector2(bx, by), Vector2(hx, hy) + n, Vector2(hx, hy) - n]),
				PackedColorArray([Color(1, 248 / 255.0, 220 / 255.0, 0.22), Color(1, 248 / 255.0, 220 / 255.0, 0), Color(1, 248 / 255.0, 220 / 255.0, 0)]))
		# hale ve dönen ışınlar
		var hm := Vector2(mx, ky + kh * 0.42); var hr := kh * 0.9
		var h0 := Color(1, 220 / 255.0, 120 / 255.0, 0.5 * e); var h1 := Color(1, 220 / 255.0, 120 / 255.0, 0)
		for i in 48:   # yelpaze: merkez renkli, kenar saydam (degrade bantsız)
			var a0 := i * TAU / 48; var a1 := (i + 1) * TAU / 48
			draw_polygon(PackedVector2Array([hm, hm + Vector2(cos(a0), sin(a0)) * hr, hm + Vector2(cos(a1), sin(a1)) * hr]), PackedColorArray([h0, h1, h1]))
		for i in 14:
			var a := t * 0.25 + i * TAU / 14
			var u := Vector2(cos(a), sin(a)); var v := u.orthogonal()
			draw_polygon(PackedVector2Array([hm, hm + u * hr * 1.3 + v * hr * 0.07, hm + u * hr * 1.3 - v * hr * 0.07]),
				PackedColorArray([Color(1, 230 / 255.0, 150 / 255.0, 0.1 * e), Color(1, 230 / 255.0, 150 / 255.0, 0), Color(1, 230 / 255.0, 150 / 255.0, 0)]))
		# kupa
		var s := kw / 100.0
		Arma.ciz_komut(self, KK, Transform2D(0.0, Vector2(s, s), 0.0, Vector2(kx, ky)), s)
		# arma, kupanın altında
		var asz := minf(64.0, H * 0.09); var sa := asz / 100.0
		Arma.ciz_komut(self, KA, Transform2D(0.0, Vector2(sa, sa), 0.0, Vector2(mx - asz / 2.0, ky + kh * 0.98)), sa, e)
		# havai fişek
		if t > 1.0 and t - son_fisek > 0.52:
			son_fisek = t
			var fx := W * (0.15 + R.f() * 0.7); var fy := H * (0.08 + R.f() * 0.25); var fr: Color = renkler[int(floor(R.f() * renkler.size()))]
			for f in 38:
				var aa := f / 38.0 * TAU; var hz := 1.4 + R.f() * 1.6
				fisek.append({"x": fx, "y": fy, "vx": cos(aa) * hz, "vy": sin(aa) * hz, "o": 1.0, "r": fr})
		for q in range(fisek.size() - 1, -1, -1):
			var p: Dictionary = fisek[q]
			p.x += p.vx; p.y += p.vy; p.vy += 0.03; p.vx *= 0.985; p.o -= 0.014
			if p.o <= 0: fisek.remove_at(q); continue
			var c: Color = p.r; c.a = p.o
			draw_circle(Vector2(p.x, p.y), 1.8, c)
			draw_rect(Rect2(p.x - 0.5, p.y - 0.5, 1, 1), Color(1, 250 / 255.0, 230 / 255.0, p.o * 0.5))
		# konfeti
		for k in konfeti:
			k.y += k.vy * 0.016 * (0.0 if t < 0.6 else 1.0); k.x += k.vx * 0.016 + sin(t * 2 + k.s) * 0.0006; k.a += k.va * 0.016
			if k.y > 1.05: k.y = -0.05; k.x = R.f()
			var sy := absf(sin(t * 4 + k.s)) + 0.15
			draw_set_transform(Vector2(k.x * W, k.y * H), k.a, Vector2(1, sy))
			draw_rect(Rect2(-k.w / 2, -k.w * 0.3, k.w, k.w * 0.6), k.r)
		draw_set_transform(Vector2.ZERO, 0, Vector2.ONE)
