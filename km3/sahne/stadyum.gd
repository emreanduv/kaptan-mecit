# Kaptan Mecit 3 — stadyum: biçilmiş çim, çizgiler, ağlı kaleler, kase biçiminde iki katlı tribün,
# on binlerce taraftar (tek çizimlik çoklu örnek), çatı ve projektör ışık bandı, LED reklam panoları, skor ekranları.
# Dünya: X = x - 34 (en), Z = y - 52.5 (boy), Y yukarı. Saha merkezi orijin.
extends Node3D
class_name Stadyum

const PW := 68.0
const PL := 105.0
const HX := PW / 2
const HZ := PL / 2

var seyirci: MultiMeshInstance3D
var seyirci_mat: ShaderMaterial
var panolar: Array = []     # [{mesh_mat, etiket, sira}]
var pano_icerik: Array = [] # [[yazı, zemin, yazı rengi], ...]
var skor_etiketleri: Array = []
var _pano_t := 0.0
var _heyecan := 0.0
var hafif := false   # Quest / telefon: daha az seyirci

func kur(ev_kit: Dictionary, dep_kit: Dictionary, icerik: Array) -> void:
	pano_icerik = icerik
	_cim()
	_cizgiler()
	for uc in [-1.0, 1.0]: _kale(uc)
	_tribun_ve_seyirci(ev_kit, dep_kit)
	_panolar()
	_skor_ekranlari()

# ---------- çim ----------
const CIM_SHADER := """
shader_type spatial;
render_mode diffuse_burley, specular_schlick_ggx;
varying vec3 wp;
float h21(vec2 p){ p = fract(p * vec2(123.34, 456.21)); p += dot(p, p + 45.32); return fract(p.x * p.y); }
float gurultu(vec2 p){ vec2 i = floor(p), f = fract(p); f = f * f * (3.0 - 2.0 * f);
	return mix(mix(h21(i), h21(i + vec2(1, 0)), f.x), mix(h21(i + vec2(0, 1)), h21(i + vec2(1, 1)), f.x), f.y); }
void vertex(){ wp = (MODEL_MATRIX * vec4(VERTEX, 1.0)).xyz; }
void fragment(){
	float s = mod(floor((wp.z + 52.5) / (105.0 / 18.0)), 2.0);          // boyuna biçme izi
	float s2 = mod(floor((wp.x + 34.0) / (68.0 / 8.0)), 2.0);           // enine hafif iz
	vec3 a = vec3(0.030, 0.115, 0.022), b = vec3(0.042, 0.16, 0.030);
	vec3 c = mix(a, b, s) * (1.0 + 0.07 * (s2 - 0.5));
	float n = gurultu(wp.xz * 0.35) * 0.6 + gurultu(wp.xz * 2.7) * 0.4;
	c *= 0.86 + 0.26 * n;
	c *= 0.9 + 0.2 * h21(floor(wp.xz * 55.0));                           // tek tek çim izleri
	// saha dışı: biraz daha koyu, aşınmış
	float dis = step(34.0, abs(wp.x)) + step(52.5, abs(wp.z));
	c *= 1.0 - 0.18 * min(dis, 1.0);
	ALBEDO = c;
	ROUGHNESS = 0.92;
	SPECULAR = 0.25;
}
"""

func _cim() -> void:
	var m := MeshInstance3D.new()
	var pm := PlaneMesh.new()
	pm.size = Vector2(PW + 20, PL + 22)
	pm.subdivide_width = 8; pm.subdivide_depth = 8
	m.mesh = pm
	var sm := ShaderMaterial.new()
	var sh := Shader.new(); sh.code = CIM_SHADER
	sm.shader = sh
	m.material_override = sm
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	# saha çevresi: pist / beton
	var z := MeshInstance3D.new()
	var zp := PlaneMesh.new(); zp.size = Vector2(PW + 70, PL + 80)
	z.mesh = zp; z.position.y = -.02
	z.material_override = _std(Color("#2b3135"), .95)
	add_child(z)

# ---------- çizgiler ----------
func _cizgiler() -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var w := .12
	var y := .012
	var seg := func(a: Vector2, b: Vector2):
		var d := (b - a).normalized()
		var n := Vector2(-d.y, d.x) * w / 2
		var p := [a + n, b + n, b - n, a - n]
		st.set_normal(Vector3.UP)
		for i in [0, 1, 2, 0, 2, 3]: st.add_vertex(Vector3(p[i].x, y, p[i].y))
	var yay := func(c: Vector2, r: float, a0: float, a1: float, n := 48):
		for i in n:
			var t0 := lerpf(a0, a1, float(i) / n); var t1 := lerpf(a0, a1, float(i + 1) / n)
			seg.call(c + Vector2(cos(t0), sin(t0)) * r, c + Vector2(cos(t1), sin(t1)) * r)
	var dik := func(x0: float, z0: float, x1: float, z1: float):
		seg.call(Vector2(x0, z0), Vector2(x1, z0)); seg.call(Vector2(x1, z0), Vector2(x1, z1))
		seg.call(Vector2(x1, z1), Vector2(x0, z1)); seg.call(Vector2(x0, z1), Vector2(x0, z0))
	dik.call(-HX, -HZ, HX, HZ)
	seg.call(Vector2(-HX, 0), Vector2(HX, 0))
	yay.call(Vector2.ZERO, 9.15, 0, TAU, 72)
	yay.call(Vector2.ZERO, .15, 0, TAU, 12)
	for s in [-1.0, 1.0]:
		var gz = s * HZ
		dik.call(-20.15, gz, 20.15, gz - s * 16.5)
		dik.call(-9.16, gz, 9.16, gz - s * 5.5)
		var ps := Vector2(0, gz - s * 11)
		yay.call(ps, .15, 0, TAU, 12)
		var a := acos(5.5 / 9.15)
		var base := -PI / 2 if s > 0 else PI / 2
		yay.call(ps, 9.15, base - (PI / 2 - a), base + (PI / 2 - a), 24)
		for sx in [-1.0, 1.0]:
			var c := Vector2(sx * HX, gz)
			var a0 := atan2(-s, -sx)
			yay.call(c, 1.0, a0 - PI / 4, a0 + PI / 4, 8)
	var m := MeshInstance3D.new()
	m.mesh = st.commit()
	var mat := _std(Color("#e9eee5"), .85)
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)

# ---------- kale ----------
const AG_SHADER := """
shader_type spatial;
render_mode cull_disabled, diffuse_burley;
uniform float aralik = 0.12;
void fragment(){
	vec2 g = abs(fract(UV * vec2(%s) / aralik) - 0.5);
	float c = min(g.x, g.y);
	if (c > 0.09) discard;
	ALBEDO = vec3(0.92);
	ROUGHNESS = 0.9;
}
"""

func _kale(s: float) -> void:
	var gz := s * HZ
	var g := Node3D.new(); add_child(g)
	var dir := _std(Color("#f7f7f7"), .35)
	var gw := 7.32; var gh := 2.44; var r := .06; var dp := 2.0
	for sx in [-1.0, 1.0]:
		var c := MeshInstance3D.new(); var cm := CylinderMesh.new()
		cm.top_radius = r; cm.bottom_radius = r; cm.height = gh + r
		c.mesh = cm; c.material_override = dir; c.position = Vector3(sx * (gw / 2 + r), (gh + r) / 2, gz + s * r)
		g.add_child(c)
		# arka direkler (ince)
		var a := MeshInstance3D.new(); var am := CylinderMesh.new()
		am.top_radius = .025; am.bottom_radius = .025; am.height = gh * .9
		a.mesh = am; a.material_override = dir; a.position = Vector3(sx * (gw / 2 + .3), gh * .45, gz + s * dp)
		g.add_child(a)
	var u := MeshInstance3D.new(); var um := CylinderMesh.new()
	um.top_radius = r; um.bottom_radius = r; um.height = gw + 4 * r
	u.mesh = um; u.material_override = dir; u.rotation.z = PI / 2; u.position = Vector3(0, gh + r, gz + s * r)
	g.add_child(u)
	# ağ: arka, üst, iki yan
	var ag := func(boy: Vector2, merkez: Vector3, rot: Vector3):
		var q := MeshInstance3D.new(); var qm := QuadMesh.new(); qm.size = boy
		q.mesh = qm
		var sm := ShaderMaterial.new(); var sh := Shader.new()
		sh.code = AG_SHADER % ("%.3f, %.3f" % [boy.x, boy.y])
		sm.shader = sh
		q.material_override = sm
		q.position = merkez; q.rotation = rot
		q.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_ON
		g.add_child(q)
	ag.call(Vector2(gw + .6, gh * .9), Vector3(0, gh * .45, gz + s * dp), Vector3.ZERO)
	var ust_derin := sqrt(dp * dp + (gh * .1) ** 2)
	ag.call(Vector2(gw + .6, ust_derin), Vector3(0, gh * .95, gz + s * dp / 2), Vector3(PI / 2 - atan2(gh * .1, dp) * s, 0, 0))
	for sx in [-1.0, 1.0]:
		ag.call(Vector2(dp, gh), Vector3(sx * (gw / 2 + .15), gh / 2, gz + s * dp / 2), Vector3(0, PI / 2, 0))

# ---------- tribün + seyirci ----------
const SEYIRCI_SHADER := """
shader_type spatial;
render_mode cull_disabled, diffuse_lambert, specular_disabled;
uniform float heyecan_ev = 0.0;
uniform float heyecan_dep = 0.0;
uniform float uzgun_ev = 0.0;
uniform float uzgun_dep = 0.0;
uniform float zaman_olcek = 1.0;
varying vec3 ten;
varying vec3 forma;
varying float faz;
void vertex(){
	forma = COLOR.rgb;
	ten = INSTANCE_CUSTOM.rgb;
	faz = INSTANCE_CUSTOM.a;
	float sic = max(0.0, sin(TIME * (5.0 + faz * 3.0) + faz * 40.0));
	float sakin = sin(TIME * 0.7 + faz * 30.0) * 0.015;
	// COLOR.a: 1 ev sahibi taraftarı, 0 misafir taraftar (tribün bölümüne göre, formasının renginden bağımsız)
	float ev = step(0.5, COLOR.a);
	float h = mix(heyecan_dep, heyecan_ev, ev);
	float u = mix(uzgun_dep, uzgun_ev, ev);
	VERTEX.y += sakin + sic * h * (0.22 + 0.18 * fract(faz * 7.0));
	VERTEX.y -= u * 0.09 * (1.0 - UV.y);     // üzgün: omuzlar çöker, baş öne düşer
}
void fragment(){
	vec2 p = UV * vec2(1.0, 1.8);          // 0..1 x 0..1.8 (üst = 0)
	float bas = length(p - vec2(0.5, 0.36)) - 0.24;
	float omuz = max(abs(p.x - 0.5) - 0.42, p.y - 1.8);
	omuz = max(omuz, 0.62 - p.y + 0.18 * pow(abs(p.x - 0.5) * 2.0, 2.0));
	bool dis = bas > 0.0 && omuz > 0.0;
	if (dis) discard;
	vec3 c = bas <= 0.0 ? ten : forma;
	if (bas <= 0.0 && p.y < 0.24 + fract(faz * 13.0) * 0.08) c = ten * 0.25;    // saç
	if (dis) c = vec3(0.035, 0.045, 0.055);
	ALBEDO = c;
	ROUGHNESS = 1.0;
}
"""

# yuvarlatılmış dikdörtgen halka üzerinde eşit aralıklı noktalar (konum, içe bakan normal)
static func _cevre(hx: float, hz: float, r: float) -> float: return 4 * (hx - r) + 4 * (hz - r) + TAU * r
static func _halka(hx: float, hz: float, r: float, aralik: float, n := 0) -> Array:
	var out: Array = []
	var duz_x := 2 * (hx - r); var duz_z := 2 * (hz - r)
	var cevre := 2 * duz_x + 2 * duz_z + TAU * r
	if n <= 0: n = int(cevre / aralik)
	for i in n:
		var s := cevre * i / n
		var p: Vector2; var dis: Vector2
		var parcalar := [duz_x, PI / 2 * r, duz_z, PI / 2 * r, duz_x, PI / 2 * r, duz_z, PI / 2 * r]
		var k := 0
		while k < 8 and s > parcalar[k]: s -= parcalar[k]; k += 1
		k = mini(k, 7)
		match k:
			0: p = Vector2(-hx + r + s, -hz); dis = Vector2(0, -1)
			2: p = Vector2(hx, -hz + r + s); dis = Vector2(1, 0)
			4: p = Vector2(hx - r - s, hz); dis = Vector2(0, 1)
			6: p = Vector2(-hx, hz - r - s); dis = Vector2(-1, 0)
			_:
				var merkez = [Vector2(hx - r, -hz + r), Vector2(hx - r, hz - r), Vector2(-hx + r, hz - r), Vector2(-hx + r, -hz + r)][(k - 1) / 2]
				var a0 = [-PI / 2, 0.0, PI / 2, PI][(k - 1) / 2]
				var a = a0 + s / r
				dis = Vector2(cos(a), sin(a)); p = merkez + dis * r
		out.append([p, -dis])
	return out

func _tribun_ve_seyirci(ev: Dictionary, dep: Dictionary) -> void:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var beton := Color("#4a5257"); var beton2 := Color("#3a4146"); var koltuk := Color("#2c3a46")
	var satirlar: Array = []   # [d, h]
	var R0 := 10.0
	var hx0 := HX + 7.0; var hz0 := HZ + 8.0
	# alt kat 20 sıra, ara kat (kutu/fascia), üst kat 18 sıra (biraz geride ve yüksekte)
	for r in 38:
		var ust := r >= 20
		var k := r - 20 if ust else r
		var d := (2.0 + 20 * .82 + 3.0 + k * .82) if ust else (k * .82)
		var h := (1.2 + 20 * .4 + 4.2 + k * .46) if ust else (1.2 + k * .4)
		satirlar.append([d, h, ust])
	var serit := func(d0: float, d1: float, y0: float, y1: float, renk: Color):
		var n := 160
		var A := _halka(hx0 + d0, hz0 + d0, R0 + d0, 0, n)
		var B := _halka(hx0 + d1, hz0 + d1, R0 + d1, 0, n)
		st.set_color(renk)
		for i in n:
			var j := (i + 1) % n
			var a0: Vector2 = A[i][0]; var a1: Vector2 = A[j][0]; var b0: Vector2 = B[i][0]; var b1: Vector2 = B[j][0]
			var v := [Vector3(a0.x, y0, a0.y), Vector3(a1.x, y0, a1.y), Vector3(b1.x, y1, b1.y), Vector3(b0.x, y1, b0.y)]
			var nn = (v[1] - v[0]).cross(v[3] - v[0]).normalized()
			if nn.y < 0 and y1 >= y0 and absf(y1 - y0) < .01: nn = -nn
			st.set_normal(nn)
			for t in [0, 2, 1, 0, 3, 2]: st.add_vertex(v[t])
	for r in satirlar.size():
		var d: float = satirlar[r][0]; var h: float = satirlar[r][1]
		var onceki_h: float = satirlar[r - 1][1] if r > 0 and satirlar[r - 1][2] == satirlar[r][2] else (0.0 if r == 0 else satirlar[r - 1][1] + .4)
		# yükseltici (dikey) ve basamak (yatay)
		serit.call(d, d, onceki_h if r > 0 else 0.0, h, beton2)
		serit.call(d, d + .82, h, h, koltuk if r % 2 == 0 else beton)
	# ara kat ön yüzü (fascia) ve kat altı
	var alt_son: Array = satirlar[19]
	var ust_ilk: Array = satirlar[20]
	serit.call(alt_son[0] + .82, ust_ilk[0], alt_son[1], alt_son[1], beton2)
	serit.call(ust_ilk[0], ust_ilk[0], alt_son[1], ust_ilk[1], Color("#14181b"))
	# arka duvar ve çatı
	var son: Array = satirlar[satirlar.size() - 1]
	serit.call(son[0] + .82, son[0] + .82, son[1], son[1] + 6, beton2)
	var tribun := MeshInstance3D.new()
	tribun.mesh = st.commit()
	var tm := StandardMaterial3D.new(); tm.vertex_color_use_as_albedo = true; tm.roughness = .95; tm.cull_mode = BaseMaterial3D.CULL_DISABLED
	tribun.material_override = tm
	add_child(tribun)
	# fascia: ışıklı bant (ara kat önünde, KM VR'daki gibi pencere ışıkları)
	_fascia(hx0, hz0, R0, ust_ilk[0], alt_son[1], ust_ilk[1])
	_cati(hx0, hz0, R0, satirlar)
	# seyirciler
	var konumlar: Array = []
	var rng := RandomNumberGenerator.new(); rng.seed = 2026
	var ev1 := Color(ev.c1); var ev2 := Color(ev.c2); var dp1 := Color(dep.c1); var dp2 := Color(dep.c2)
	var tenler := [Color("#f1c9a5"), Color("#e0ac7e"), Color("#c68a5a"), Color("#8d5a3b"), Color("#f5d6b8")]
	var notr := [Color("#e8e8e8"), Color("#2a2a2a"), Color("#3b5b8c"), Color("#7a7a7a"), Color("#c9a227")]
	for r in satirlar.size():
		var d: float = satirlar[r][0]; var h: float = satirlar[r][1]
		var nok := _halka(hx0 + d + .45, hz0 + d + .45, R0 + d + .45, .62)
		for e in nok:
			if rng.randf() > (.5 if hafif else .9): continue
			var p: Vector2 = e[0]; var ic: Vector2 = e[1]
			var p2 := p + Vector2(rng.randf_range(-.08, .08), rng.randf_range(-.08, .08))
			var deplasman := p.y < -HZ - 5 and absf(p.x) < 22    # kuzey kale arkası: misafir tribünü
			var c: Color
			var z := rng.randf()
			if deplasman: c = dp1 if z < .6 else (dp2 if z < .85 else notr[rng.randi() % 5])
			else: c = ev1 if z < .55 else (ev2 if z < .8 else notr[rng.randi() % 5])
			c = c * rng.randf_range(.8, 1.05)
			c.a = 0.0 if deplasman else 1.0
			var tn: Color = tenler[rng.randi() % 5]
			konumlar.append([Vector3(p2.x, h + .02, p2.y), ic, c, tn, rng.randf()])
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	mm.use_custom_data = true
	var q := QuadMesh.new(); q.size = Vector2(.52, .94); q.center_offset = Vector3(0, .47, 0)
	mm.mesh = q
	mm.instance_count = konumlar.size()
	for i in konumlar.size():
		var k: Array = konumlar[i]
		var ic: Vector2 = k[1]
		var yaw := atan2(ic.x, ic.y)
		var b := Basis(Vector3.UP, yaw)
		mm.set_instance_transform(i, Transform3D(b, k[0]))
		mm.set_instance_color(i, k[2])
		var tn: Color = k[3]
		mm.set_instance_custom_data(i, Color(tn.r, tn.g, tn.b, k[4]))
	seyirci = MultiMeshInstance3D.new()
	seyirci.multimesh = mm
	seyirci_mat = ShaderMaterial.new()
	var sh := Shader.new()
	# hafif modda "discard" yok: silüet dışı koyu tribün rengiyle boyanır (mobil GPU'da erken derinlik testi bozulmasın)
	sh.code = SEYIRCI_SHADER.replace("if (dis) discard;", "") if hafif else SEYIRCI_SHADER
	seyirci_mat.shader = sh
	seyirci.material_override = seyirci_mat
	seyirci.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(seyirci)

# VR koltuğunun çevresindeki seyircileri kaldır (oyuncu birinin içinde oturmasın)
func koltuk_bosalt(poz: Vector3, r: float) -> void:
	var mm := seyirci.multimesh
	for i in mm.instance_count:
		var t := mm.get_instance_transform(i)
		if Vector2(t.origin.x - poz.x, t.origin.z - poz.z).length() < r * 3 and absf(t.origin.y - poz.y) < 3.5 and t.origin.y < poz.y + 1.2:
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * .001), t.origin))

func seyirci_sayisi() -> int: return seyirci.multimesh.instance_count if seyirci else 0

func _fascia(hx0: float, hz0: float, R0: float, d: float, y0: float, y1: float) -> void:
	var nok := _halka(hx0 + d - .05, hz0 + d - .05, R0 + d - .05, 4.0)
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D
	var q := QuadMesh.new(); q.size = Vector2(2.2, .9)
	mm.mesh = q; mm.instance_count = nok.size()
	for i in nok.size():
		var p: Vector2 = nok[i][0]; var ic: Vector2 = nok[i][1]
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, atan2(ic.x, ic.y)), Vector3(p.x, (y0 + y1) / 2, p.y)))
	var m := MultiMeshInstance3D.new(); m.multimesh = mm
	var mat := StandardMaterial3D.new(); mat.albedo_color = Color("#ffe8b0"); mat.emission_enabled = true; mat.emission = Color("#ffd98a"); mat.emission_energy_multiplier = 1.6
	m.material_override = mat; m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)

func _cati(hx0: float, hz0: float, R0: float, satirlar: Array) -> void:
	var son: Array = satirlar[satirlar.size() - 1]
	var d0: float = satirlar[14][0]; var d1: float = son[0] + 2.0
	var y: float = son[1] + 7.0
	var n := 160
	var A := _halka(hx0 + d0, hz0 + d0, R0 + d0, 0, n)
	var B := _halka(hx0 + d1, hz0 + d1, R0 + d1, 0, n)
	var st := SurfaceTool.new(); st.begin(Mesh.PRIMITIVE_TRIANGLES)
	for i in n:
		var j := (i + 1) % n
		var a0: Vector2 = A[i][0]; var a1: Vector2 = A[j][0]; var b0: Vector2 = B[i][0]; var b1: Vector2 = B[j][0]
		st.set_normal(Vector3.DOWN)
		for v in [Vector3(a0.x, y, a0.y), Vector3(b1.x, y + 2, b1.y), Vector3(a1.x, y, a1.y), Vector3(a0.x, y, a0.y), Vector3(b0.x, y + 2, b0.y), Vector3(b1.x, y + 2, b1.y)]:
			st.add_vertex(v)
	var m := MeshInstance3D.new(); m.mesh = st.commit()
	var mat := _std(Color("#3b4247"), .9); mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.material_override = mat
	m.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(m)
	# çatı kenarında projektör lambaları
	var L := _halka(hx0 + d0 + .4, hz0 + d0 + .4, R0 + d0 + .4, 3.4)
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D
	var bm := BoxMesh.new(); bm.size = Vector3(1.6, .35, .5)
	mm.mesh = bm; mm.instance_count = L.size()
	for i in L.size():
		var p: Vector2 = L[i][0]; var ic: Vector2 = L[i][1]
		mm.set_instance_transform(i, Transform3D(Basis(Vector3.UP, atan2(ic.x, ic.y)), Vector3(p.x, y - .3, p.y)))
	var lm := MultiMeshInstance3D.new(); lm.multimesh = mm
	var lmat := StandardMaterial3D.new(); lmat.albedo_color = Color.WHITE; lmat.emission_enabled = true; lmat.emission = Color("#fff6e0"); lmat.emission_energy_multiplier = 6.0
	lm.material_override = lmat; lm.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(lm)

# ---------- LED panolar ----------
func _panolar() -> void:
	var y := .5
	var duzen: Array = []  # [merkez, yaw, uzunluk]
	var L := 8.0
	for s in [-1.0, 1.0]:
		var x = s * (HX + 4.5)
		var z := -HZ + L / 2
		while z < HZ:
			duzen.append([Vector3(x, y, z), -s * PI / 2, L]); z += L + .15
	for s in [-1.0, 1.0]:
		var z = s * (HZ + 5.0)
		for cx in [-28.0, -19.5, -11.0, 11.0, 19.5, 28.0]:
			duzen.append([Vector3(cx, y, z), PI if s > 0 else 0.0, L])
	for i in duzen.size():
		var d: Array = duzen[i]
		var g := Node3D.new(); g.position = d[0]; g.rotation.y = d[1]
		add_child(g)
		var b := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(d[2], .95, .25)
		b.mesh = bm
		var mat := StandardMaterial3D.new(); mat.emission_enabled = true; mat.emission_energy_multiplier = .9; mat.roughness = .4
		b.material_override = mat
		g.add_child(b)
		var lab := Label3D.new(); lab.font_size = 96; lab.pixel_size = .0062; lab.outline_size = 0
		lab.position = Vector3(0, 0, .13); lab.shaded = false; lab.double_sided = false
		lab.width = d[2] / lab.pixel_size; lab.autowrap_mode = TextServer.AUTOWRAP_OFF
		g.add_child(lab)
		panolar.append({"mat": mat, "lab": lab, "i": i})
	_pano_yenile(0)

func _pano_yenile(tur: int) -> void:
	if pano_icerik.is_empty(): return
	for p in panolar:
		var k: Array = pano_icerik[(p.i * 5 + tur * 3) % pano_icerik.size()]
		var zemin := Color(k[1])
		p.mat.albedo_color = zemin * .6
		p.mat.emission = zemin
		p.lab.text = k[0]
		p.lab.modulate = Color(k[2]) * 2.2

# ---------- skor ekranları ----------
func _skor_ekranlari() -> void:
	for s in [-1.0, 1.0]:
		var g := Node3D.new()
		g.position = Vector3(s * -24, 26, s * (HZ + 30)); g.rotation.y = 0.0 if s < 0 else PI
		g.rotation.y = PI if s > 0 else 0.0
		add_child(g)
		var b := MeshInstance3D.new(); var bm := BoxMesh.new(); bm.size = Vector3(16, 7, .6)
		b.mesh = bm; b.material_override = _std(Color("#0b0f12"), .5)
		g.add_child(b)
		var lab := Label3D.new(); lab.font_size = 160; lab.pixel_size = .02; lab.position = Vector3(0, 0, .32); lab.shaded = false
		lab.modulate = Color("#f3d35a") * 1.8; lab.outline_size = 0
		g.add_child(lab)
		skor_etiketleri.append(lab)

func skor(yazi: String) -> void:
	for l in skor_etiketleri: l.text = yazi

func heyecan(ev: float, dep: float, uzgun_ev := 0.0, uzgun_dep := 0.0) -> void:
	_heyecan = maxf(ev, dep)
	seyirci_mat.set_shader_parameter("heyecan_ev", ev)
	seyirci_mat.set_shader_parameter("heyecan_dep", dep)
	seyirci_mat.set_shader_parameter("uzgun_ev", uzgun_ev)
	seyirci_mat.set_shader_parameter("uzgun_dep", uzgun_dep)

func _process(dt: float) -> void:
	_pano_t += dt
	if _pano_t > 7.0:
		_pano_t = 0.0
		_pano_yenile(int(Time.get_ticks_msec() / 7000))

static func _std(c: Color, rough: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new(); m.albedo_color = c; m.roughness = rough
	return m
