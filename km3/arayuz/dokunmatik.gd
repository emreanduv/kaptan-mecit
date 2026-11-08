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
