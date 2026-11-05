# Kaptan Mecit 3 — gol tekrarı (Kaptan Mecit Klasik'teki gibi).
# Oyun akarken son saniyeler her motor adımında kaydedilir. Gol olunca sevinçten sonra motor durur,
# kayıt yakın yayın kamerasıyla ağır çekimde baştan oynatılır; bitince (ya da Geç ile) oyunun anlık durumu geri yüklenir.
extends RefCounted
class_name Tekrar

const SURE := 5.5          # tekrarda gösterilen saniye
const HIZ := .7            # ağır çekim
const BEKLE := 1.8         # gol sevinci görüldükten sonra başlar
const OY_ALAN := ["x", "y", "vx", "vy", "dx", "dy", "anim", "cd", "slide", "stun", "dive", "ucus", "ucus_tur", "ucus_yan", "ucus_z", "ucus_ofs"]
const TOP_ALAN := ["x", "y", "z", "vx", "vy", "vz", "owner", "kicker", "last"]

var kayit: Array = []      # her eleman bir kare
var oynat: Array = []
var aktif := false
var _i := 0.0
var _bekle := -1.0
var _anlik = null          # tekrar öncesi gerçek durum
var M

func _kare() -> Array:
	var oy := []
	for p in M.P:
		var a := []
		for k in OY_ALAN: a.append(p.get(k))
		oy.append(a)
	var t := []
	for k in TOP_ALAN: t.append(M.ball.get(k))
	return [oy, t, M.ctrl]

func _yukle(k: Array) -> void:
	for i in mini(M.P.size(), k[0].size()):
		var p = M.P[i]; var a: Array = k[0][i]
		for j in OY_ALAN.size(): p.set(OY_ALAN[j], a[j])
	for j in TOP_ALAN.size(): M.ball.set(TOP_ALAN[j], k[1][j])
	M.ctrl = k[2]

# her motor adımından sonra
func adim(mac) -> void:
	if mac != M: M = mac; kayit.clear(); aktif = false; _bekle = -1.0
	if aktif or M.demo: return
	if M.state == "play":
		kayit.append(_kare())
		var n := int(SURE * 60.0)
		if kayit.size() > n + 30: kayit = kayit.slice(kayit.size() - n)

# gol olayı geldi: sevinçten sonra başlat
func gol() -> void:
	if M == null or M.demo or kayit.size() < 60: return
	oynat = kayit.duplicate(); kayit.clear()
	_bekle = BEKLE

# her karede; true dönerse motor durur (tekrar oynuyor)
func kare(dt: float) -> bool:
	if _bekle > 0:
		_bekle -= dt
		if _bekle <= 0: _basla()
	if not aktif: return false
	_i += dt * 60.0 * HIZ
	if int(_i) >= oynat.size(): bitir(); return false
	_yukle(oynat[int(_i)])
	return true

func _basla() -> void:
	_anlik = _kare(); aktif = true; _i = 0.0

func bitir() -> void:
	if not aktif: return
	_yukle(_anlik); aktif = false; oynat.clear(); _bekle = -1.0
