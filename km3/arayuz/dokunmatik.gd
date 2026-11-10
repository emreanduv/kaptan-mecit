# Kaptan Mecit 3 — telefon / tablet dokunmatik kontrolü.
# Ekranın sol yarısı: parmağı koyduğun yerde beliren sanal çubuk (koş). Sağ alt: PAS ve ŞUT düğmeleri. Üst orta: mola.
# Çok parmak: çubuk ile düğmelere aynı anda basılabilir.
extends Control
class_name Dokunmatik

signal mola_istendi

var vec := Vector2.ZERO          # -1..1, ekran yönünde (sağ +x, aşağı +y)
var pas := false                 # bu karede basıldı mı (okununca sıfırlanır)
var sut := false
var pas_birak := false          # basılı tutulan düğme bırakıldı
var sut_birak := false
var guc := {"pas": 0.0, "sut": 0.0}   # dolum halkası (0..1)
func guc_ayarla(p: float, s: float) -> void:
	if p != guc.pas or s != guc.sut: guc.pas = p; guc.sut = s; queue_redraw()
var _cubuk_parmak := -1
var _cubuk_merkez := Vector2.ZERO
var _cubuk_uc := Vector2.ZERO
var _dugme_parmak := {}          # parmak -> "pas" / "sut"
const YARICAP := 90.0
var ust := 0.0                   # çentik / durum çubuğu payı
var alt := 0.0                   # ana çubuk payı
var sag := 0.0                   # yatayda çentik payı
var klasik := false              # Klasik kumanda: iki yanda panel, solda sabit yön haçı (8 yön), sağda A (ŞUT) / B (PAS), MENÜ
func panel(w: float) -> float: return clampf(w * .15, 170.0, 230.0)
func _k() -> Dictionary:
	var s := size; var P := panel(s.x)
	return {"P": P, "hac": Vector2(sag + P * .5, s.y * .55), "yh": P * .41,
		"sut": [Vector2(s.x - sag - P * .31, s.y * .40), P * .235], "pas": [Vector2(s.x - sag - P * .69, s.y * .63), P * .235],
		"menu": Rect2(sag + P * .5 - 58, s.y - alt - 58, 116, 40)}
func _hac_yaz(p: Vector2) -> void:
	var d: Vector2 = p - (_k().hac as Vector2)
	if d.length() < 16: vec = Vector2.ZERO
	else:
		var a := snappedf(d.angle(), PI / 4)     # 8 yön (çaprazlar dahil)
		vec = Vector2(cos(a), sin(a))
	queue_redraw()
func _input_klasik(e: InputEvent) -> void:
	var K := _k()
	if e is InputEventScreenTouch:
		var p: Vector2 = e.position
		if e.pressed:
			if (K.menu as Rect2).grow(10).has_point(p): mola_istendi.emit(); get_viewport().set_input_as_handled(); return
			for ad in ["sut", "pas"]:
				if p.distance_to(K[ad][0]) < K[ad][1] * 1.3:
					_dugme_parmak[e.index] = ad
					if ad == "pas": pas = true
					else: sut = true
					get_viewport().set_input_as_handled(); queue_redraw(); return
			if p.distance_to(K.hac) < K.yh * 1.5 and _cubuk_parmak < 0:
				_cubuk_parmak = e.index; _hac_yaz(p); get_viewport().set_input_as_handled()
		else:
			if e.index == _cubuk_parmak: _cubuk_parmak = -1; vec = Vector2.ZERO
			if _dugme_parmak.has(e.index):
				if _dugme_parmak[e.index] == "pas": pas_birak = true
				else: sut_birak = true
			_dugme_parmak.erase(e.index)
		queue_redraw()
	elif e is InputEventScreenDrag and e.index == _cubuk_parmak:
		_hac_yaz(e.position)
func _ciz_klasik() -> void:
	var K := _k(); var P: float = K.P; var s := size
	var zemin := Color("#122a4b"); var altin := Color("#f0b232"); var koyu := Color("#0b1626")
	draw_rect(Rect2(0, 0, P + sag, s.y), zemin); draw_rect(Rect2(s.x - P - sag, 0, P + sag, s.y), zemin)
	draw_rect(Rect2(P + sag - 3, 0, 3, s.y), altin); draw_rect(Rect2(s.x - P - sag, 0, 3, s.y), altin)
	var yazi := ThemeDB.fallback_font
	var baslik := "KAPTAN MECİT"; var fs := 16
	var bw := yazi.get_string_size(baslik, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
	draw_string(yazi, Vector2(sag + P * .5 - bw / 2, ust + 40), baslik, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, altin)
	# yön haçı
	var c: Vector2 = K.hac; var h: float = K.yh; var k := h * .34
	draw_rect(Rect2(c.x - k, c.y - h, k * 2, h * 2), koyu); draw_rect(Rect2(c.x - h, c.y - k, h * 2, k * 2), koyu)
	draw_rect(Rect2(c.x - k, c.y - h, k * 2, h * 2), Color("#9a5f0e"), false, 2.0); draw_rect(Rect2(c.x - h, c.y - k, h * 2, k * 2), Color("#9a5f0e"), false, 2.0)
	draw_rect(Rect2(c.x - k + 2, c.y - k + 2, k * 2 - 4, k * 2 - 4), koyu)
	for yon in [Vector2.UP, Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		var uc: Vector2 = c + yon * (h - 14); var dik := Vector2(-yon.y, yon.x)
		var acik := vec != Vector2.ZERO and vec.dot(yon) > .5
		draw_colored_polygon(PackedVector2Array([uc, uc - yon * h * .2 + dik * h * .13, uc - yon * h * .2 - dik * h * .13]), Color.WHITE if acik else altin)
	# A / B
	for ad in ["sut", "pas"]:
		var bc: Vector2 = K[ad][0]; var r: float = K[ad][1]
		var basili := _dugme_parmak.values().has(ad)
		draw_circle(bc + Vector2(0, 5), r, Color(0, 0, 0, .5))
		draw_circle(bc + (Vector2(0, 3) if basili else Vector2.ZERO), r, Color("#d33a2e") if ad == "sut" else Color("#1d3f6e"))
		draw_arc(bc, r, 0, TAU, 48, Color.WHITE, 3.0, true)
		if guc[ad] > 0: draw_arc(bc, r + 7, -PI / 2, -PI / 2 + TAU * guc[ad], 48, Color("#ffd23f"), 6.0, true)
		var t1 := "A" if ad == "sut" else "B"; var t2 := Dil.cevir("ŞUT" if ad == "sut" else "PAS")
		var w1 := yazi.get_string_size(t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 28).x; var w2 := yazi.get_string_size(t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 12).x
		draw_string(yazi, bc + Vector2(-w1 / 2, 4), t1, HORIZONTAL_ALIGNMENT_LEFT, -1, 28, Color.WHITE)
		draw_string(yazi, bc + Vector2(-w2 / 2, 20), t2, HORIZONTAL_ALIGNMENT_LEFT, -1, 12, Color.WHITE)
	# MENÜ ve imza
	var mr: Rect2 = K.menu
	draw_rect(mr, Color("#1d4f22")); draw_rect(mr, Color("#9a5f0e"), false, 2.0)
	var mt := Dil.cevir("MENÜ"); var mw := yazi.get_string_size(mt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15).x
	draw_string(yazi, mr.get_center() + Vector2(-mw / 2, 6), mt, HORIZONTAL_ALIGNMENT_LEFT, -1, 15, altin)
	var im := "Bir Mr. Anduv! yapımıdır."; var iw := yazi.get_string_size(im, HORIZONTAL_ALIGNMENT_LEFT, -1, 11).x
	draw_string(yazi, Vector2(s.x - sag - P * .5 - iw / 2, s.y - alt - 30), im, HORIZONTAL_ALIGNMENT_LEFT, -1, 11, Color(altin, .7))

func _ready() -> void:
	set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	resized.connect(queue_redraw)
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func _dugmeler() -> Dictionary:
	var s := size
	var r := minf(s.y * .11, 78.0)
	return {"sut": [Vector2(s.x - sag - r * 1.5, s.y - alt - r * 1.6), r], "pas": [Vector2(s.x - sag - r * 3.9, s.y - alt - r * 1.1), r * .9],
		"mola": [Vector2(s.x * .5, ust + r * .55), r * .42]}

func _input(e: InputEvent) -> void:
	if not visible: return
	if klasik: _input_klasik(e); return
	if e is InputEventScreenTouch:
		var p: Vector2 = e.position
		if e.pressed:
			for ad in ["sut", "pas", "mola"]:
				var d: Array = _dugmeler()[ad]
				if p.distance_to(d[0]) < d[1] * 1.25:
					if ad == "mola": mola_istendi.emit()
					else:
						_dugme_parmak[e.index] = ad
						if ad == "pas": pas = true
						else: sut = true
					get_viewport().set_input_as_handled(); queue_redraw(); return
			if p.x < size.x * .5 and _cubuk_parmak < 0:
				_cubuk_parmak = e.index; _cubuk_merkez = p; _cubuk_uc = p; vec = Vector2.ZERO
				get_viewport().set_input_as_handled()
		else:
			if e.index == _cubuk_parmak: _cubuk_parmak = -1; vec = Vector2.ZERO
			if _dugme_parmak.has(e.index):
				if _dugme_parmak[e.index] == "pas": pas_birak = true
				else: sut_birak = true
			_dugme_parmak.erase(e.index)
		queue_redraw()
	elif e is InputEventScreenDrag and e.index == _cubuk_parmak:
		var d: Vector2 = e.position - _cubuk_merkez
		if d.length() > YARICAP * 1.6: _cubuk_merkez = e.position - d.normalized() * YARICAP * 1.6   # çubuk parmağı izler
		d = e.position - _cubuk_merkez
		_cubuk_uc = _cubuk_merkez + d.limit_length(YARICAP)
		vec = d / YARICAP
		vec = vec.limit_length(1.0) if vec.length() > .18 else Vector2.ZERO
		queue_redraw()

func _draw() -> void:
	if size.y < 10: return
	if klasik: _ciz_klasik(); return
	var D := _dugmeler()
	var yazi := ThemeDB.fallback_font
	for ad in ["pas", "sut"]:
		var c: Vector2 = D[ad][0]; var r: float = D[ad][1]
		var basili := _dugme_parmak.values().has(ad)
		draw_circle(c, r, Color(0.04, 0.07, 0.09, .55 if not basili else .8))
		draw_arc(c, r, 0, TAU, 48, Color("#f3d35a") if ad == "sut" else Color.WHITE, 3.0, true)
		if guc[ad] > 0: draw_arc(c, r + 7, -PI / 2, -PI / 2 + TAU * guc[ad], 48, Color("#ffd23f"), 6.0, true)
		var t := Dil.cevir("ŞUT" if ad == "sut" else "PAS")
		var fs := int(r * .42)
		var w := yazi.get_string_size(t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs).x
		draw_string(yazi, c + Vector2(-w / 2, fs * .35), t, HORIZONTAL_ALIGNMENT_LEFT, -1, fs, Color.WHITE)
	var m: Vector2 = D.mola[0]; var mr: float = D.mola[1]
	draw_circle(m, mr, Color(0.04, 0.07, 0.09, .55))
	draw_rect(Rect2(m + Vector2(-mr * .35, -mr * .4), Vector2(mr * .22, mr * .8)), Color.WHITE)
	draw_rect(Rect2(m + Vector2(mr * .13, -mr * .4), Vector2(mr * .22, mr * .8)), Color.WHITE)
	if _cubuk_parmak >= 0:
		draw_circle(_cubuk_merkez, YARICAP, Color(1, 1, 1, .12))
		draw_arc(_cubuk_merkez, YARICAP, 0, TAU, 48, Color(1, 1, 1, .5), 2.0, true)
		draw_circle(_cubuk_uc, YARICAP * .42, Color(1, 1, 1, .55))
	else:
		# boşken sol altta soluk bir çubuk ipucu
		var c0 := Vector2(YARICAP * 1.5, size.y - alt - YARICAP * 1.4)
		draw_arc(c0, YARICAP * .8, 0, TAU, 40, Color(1, 1, 1, .25), 2.0, true)
		draw_circle(c0, YARICAP * .3, Color(1, 1, 1, .2))
