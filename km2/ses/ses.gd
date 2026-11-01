# Kaptan Mecit 2 — ses: tamamen yordamsal (kayıt dosyası yok). Tribün uğultusu, heyecan, düdük, top vuruşu, "ooo", gol sevinci.
extends Node
class_name Ses

const HZ := 16000.0
var oynatici: AudioStreamPlayer
var akis: AudioStreamGeneratorPlayback
var acik := true
var _b0 := 0.0
var _b1 := 0.0
var _b2 := 0.0
var _lp := 0.0
var _bp1 := 0.0
var _bp2 := 0.0
var _hey := 0.08
var _hey_hedef := 0.08
var _sesler: Array = []    # {tur, t, sure, guc, faz}

func _ready() -> void:
	oynatici = AudioStreamPlayer.new()
	var g := AudioStreamGenerator.new(); g.mix_rate = HZ; g.buffer_length = .2
	oynatici.stream = g
	oynatici.volume_db = -4
	add_child(oynatici)

func baslat() -> void:
	if not oynatici.playing:
		oynatici.play()
		akis = oynatici.get_stream_playback()

func heyecan(h: float) -> void: _hey_hedef = .08 + .22 * clampf(h, 0, 1)
func duduk(kez := 1) -> void:
	for k in kez: _sesler.append({"tur": "duduk", "t": -k * .45, "sure": .9 if kez == 3 and k == 2 else .32, "guc": .16, "faz": 0.0})
func vurus(guc := 1.0) -> void: _sesler.append({"tur": "vurus", "t": 0.0, "sure": .09, "guc": .6 * minf(1, guc), "faz": 0.0})
func ooo() -> void: _sesler.append({"tur": "kalabalik", "t": 0.0, "sure": .9, "guc": .35, "faz": 420.0})
func tik() -> void: _sesler.append({"tur": "tik", "t": 0.0, "sure": .07, "guc": .08, "faz": 0.0})
func gol() -> void:
	_sesler.append({"tur": "kalabalik", "t": 0.0, "sure": 2.4, "guc": .95, "faz": 900.0})
	_sesler.append({"tur": "kalabalik", "t": -.15, "sure": 1.6, "guc": .5, "faz": 1500.0})

func _process(_dt: float) -> void:
	if akis == null: return
	var n := akis.get_frames_available()
	if n <= 0: return
	var dt := 1.0 / HZ
	var buf := PackedVector2Array(); buf.resize(n)
	for i in n:
		_hey += (_hey_hedef - _hey) * .00005
		var w := randf() * 2 - 1
		_b0 = .99765 * _b0 + w * .099; _b1 = .963 * _b1 + w * .2965; _b2 = .57 * _b2 + w * 1.0526
		var pembe := (_b0 + _b1 + _b2 + w * .1848) * .11
		_lp += (pembe - _lp) * .25
		var s := (pembe - _lp * .6) * _hey * 1.4       # kaba bant geçiren: tribün uğultusu
		for v in _sesler:
			v.t += dt
			var t: float = v.t
			if t < 0 or t > v.sure * 2.6: continue
			match v.tur:
				"duduk":
					if t < v.sure:
						var e := minf(1, t / .02) * minf(1, (v.sure - t) / .05)
						v.faz += TAU * (2900 + 140 * sin(TAU * 32 * t)) * dt
						s += sign(sin(v.faz)) * .5 * e * v.guc
				"vurus":
					if t < v.sure: s += w * v.guc * exp(-t * 45) * .7 + sin(TAU * 90 * t) * v.guc * exp(-t * 30)
				"tik":
					if t < v.sure: s += sin(TAU * (880 + 6000 * t) * t) * v.guc * exp(-t * 40)
				"kalabalik":
					var e: float = minf(1, t / .25) * (1.0 if t < v.sure else exp(-(t - v.sure) / (v.sure * .35)))
					s += pembe * e * v.guc * (1.4 if v.faz > 1000 else 1.0)
		if not acik: s = 0
		s = clampf(s, -1, 1)
		buf[i] = Vector2(s, s)
	akis.push_buffer(buf)
	_sesler = _sesler.filter(func(v): return v.t <= v.sure * 2.6)
