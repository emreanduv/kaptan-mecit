# Kaptan Mecit 2 — ses: tamamen yordamsal (kayıt dosyası yok). Tribün uğultusu, heyecan, düdük, top vuruşu, "ooo", gol sevinci.
# Sesler açılışta BİR KEZ üretilip hazır dalga (AudioStreamWAV) olarak saklanır; maç sırasında örnek örnek hesap yapılmaz
# (Quest'te işlemciyi yormamak için).
extends Node
class_name Ses

const HZ := 22050
var acik := true
var _tribun: AudioStreamPlayer
var _tribun2: AudioStreamPlayer
var _klip := {}
var _havuz: Array = []
var _hey := 0.08
var _hey_hedef := 0.08
var _basladi := false

static func _wav(ornekler: PackedFloat32Array, dongu := false) -> AudioStreamWAV:
	var b := PackedByteArray(); b.resize(ornekler.size() * 2)
	for i in ornekler.size(): b.encode_s16(i * 2, int(clampf(ornekler[i], -1, 1) * 32000))
	var w := AudioStreamWAV.new(); w.format = AudioStreamWAV.FORMAT_16_BITS; w.mix_rate = HZ; w.stereo = false; w.data = b
	if dongu: w.loop_mode = AudioStreamWAV.LOOP_FORWARD; w.loop_end = ornekler.size()
	return w

static func _pembe(n: int, tohum: int) -> PackedFloat32Array:
	var r := RandomNumberGenerator.new(); r.seed = tohum
	var o := PackedFloat32Array(); o.resize(n)
	var b0 := 0.0; var b1 := 0.0; var b2 := 0.0
	for i in n:
		var w := r.randf() * 2 - 1
		b0 = .99765 * b0 + w * .099; b1 = .963 * b1 + w * .2965; b2 = .57 * b2 + w * 1.0526
		o[i] = (b0 + b1 + b2 + w * .1848) * .11
	return o

func _ready() -> void:
	# tribün: 4 sn'lik döngü, iki faz kaydırılmış katman (tekdüzelik duyulmasın)
	var p := _pembe(HZ * 4, 7)
	var lp := 0.0
	for i in p.size():
		lp += (p[i] - lp) * .25; p[i] = (p[i] - lp * .6) * 2.2
	# döngü dikişi: başı ve sonu yumuşak birleşsin
	var k := 2000
	for i in k:
		var t := float(i) / k
		p[i] = p[i] * t + p[p.size() - k + i] * (1 - t)
	_tribun = _oynatici(_wav(p, true), -14)
	_tribun2 = _oynatici(_wav(_pembe(HZ * 3, 11), true), -40)
	# düdük
	var d := PackedFloat32Array(); d.resize(int(HZ * .32)); var faz := 0.0
	for i in d.size():
		var t := float(i) / HZ; faz += TAU * (2900 + 140 * sin(TAU * 32 * t)) / HZ
		d[i] = signf(sin(faz)) * .35 * minf(1, t / .02) * minf(1, (.32 - t) / .05)
	_klip.duduk = _wav(d)
	var du := PackedFloat32Array(); du.resize(int(HZ * .9)); faz = 0.0
	for i in du.size():
		var t := float(i) / HZ; faz += TAU * (2900 + 140 * sin(TAU * 32 * t)) / HZ
		du[i] = signf(sin(faz)) * .35 * minf(1, t / .02) * minf(1, (.9 - t) / .05)
	_klip.duduk_uzun = _wav(du)
	# vuruş
	var v := PackedFloat32Array(); v.resize(int(HZ * .12)); var r := RandomNumberGenerator.new(); r.seed = 3
	for i in v.size():
		var t := float(i) / HZ
		v[i] = (r.randf() * 2 - 1) * exp(-t * 45) * .5 + sin(TAU * 90 * t) * exp(-t * 30) * .7
	_klip.vurus = _wav(v)
	# "ooo" ve gol: zarflı kalabalık
	_klip.ooo = _wav(_kalabalik(.9, .55))
	_klip.gol = _wav(_kalabalik(2.6, 1.0))
	var tk := PackedFloat32Array(); tk.resize(int(HZ * .07))
	for i in tk.size():
		var t := float(i) / HZ; tk[i] = sin(TAU * (880 + 6000 * t) * t) * exp(-t * 40) * .3
	_klip.tik = _wav(tk)
	for i in 6: _havuz.append(_oynatici(null, 0))

func _kalabalik(sure: float, guc: float) -> PackedFloat32Array:
	var n := int(HZ * sure * 2.2)
	var p := _pembe(n, 21)
	for i in n:
		var t := float(i) / HZ
		var e := minf(1, t / .25) * (1.0 if t < sure else exp(-(t - sure) / (sure * .35)))
		p[i] *= e * guc * 2.4
	return p

func _oynatici(s: AudioStream, db: float) -> AudioStreamPlayer:
	var a := AudioStreamPlayer.new(); a.stream = s; a.volume_db = db; add_child(a)
	return a

func baslat() -> void:
	if _basladi: return
	_basladi = true
	_tribun.play(); _tribun2.play()

func _cal(ad: String, db := 0.0, gecikme := 0.0) -> void:
	if not acik or not _basladi: return
	if gecikme > 0:
		get_tree().create_timer(gecikme).timeout.connect(func(): _cal(ad, db))
		return
	for a: AudioStreamPlayer in _havuz:
		if not a.playing:
			a.stream = _klip[ad]; a.volume_db = db; a.play(); return

func heyecan(h: float) -> void: _hey_hedef = .08 + .22 * clampf(h, 0, 1)
func duduk(kez := 1) -> void:
	for k in kez: _cal("duduk_uzun" if (kez == 3 and k == 2) else "duduk", -6.0, k * .45)
func vurus(guc := 1.0) -> void: _cal("vurus", linear_to_db(clampf(guc, .2, 1.0)) - 4)
func ooo() -> void: _cal("ooo", -6.0)
func tik() -> void: _cal("tik", -10.0)
func gol() -> void: _cal("gol", 0.0); _cal("gol", -6.0, .15)

func _process(dt: float) -> void:
	if not _basladi: return
	_hey += (_hey_hedef - _hey) * minf(1, dt * 1.5)
	_tribun.volume_db = linear_to_db(maxf(.001, _hey * 3.0)) - 2 if acik else -80.0
