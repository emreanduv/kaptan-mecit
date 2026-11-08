# Kaptan Mecit 3 — maç motoru.
# Kaptan Mecit'in (www/index.html) yayın motorunun GDScript'e satır satır taşınmış hali:
# takım planı (blok, hat, kontra), adam paylaşımı, topsuz koşular, topçu kararları (şut, orta, pas, sürme),
# kaleci, top fiziği (sürtünme, yerçekimi, sekme), kurtarış, taç / korner / aut, gol, devreler, uzatma.
# Koordinat: x 0..68 (en), y 0..105 (boy), z yükseklik (metre). Görüntü katmanı bunu dünyaya çevirir.
# Henüz taşınmayanlar (sıradaki turlar): faul / kart / penaltı / VAR / ofsayt / oyuncu değişikliği / tekrar.
extends RefCounted
class_name Mac

const PW := 68.0
const PL := 105.0
const GW := 7.32
const GX0 := PW / 2 - GW / 2
const GX1 := PW / 2 + GW / 2
const GH := 2.44
const BOXW := 40.3
const BOXD := 16.5
const KM_SINIR := [0, 45, 90, 105, 120]
const DIFF := {"spd": [-.1, -.03, .03], "skill": [-.16, -.04, .045], "steal": [.3, .45, .75], "slide": [.25, .55, 1.0], "gk": [-.02, 0.0, .05]}
const ROLES := ["GK", "LB", "LCB", "RCB", "RB", "SS", "DM", "CM", "RW", "AM", "ST"]
const POS := ["G", "D", "D", "D", "D", "O", "O", "O", "O", "F", "F"]
const SLOT := {
	"LB": [-.86, 12.0, 1.0], "LCB": [-.3, 0.0, 0.0], "RCB": [.3, 0.0, 0.0], "RB": [.86, 13.0, 1.0],
	"SS": [-.62, 27.0, 14.0], "DM": [-.06, 9.0, 8.0], "CM": [.24, 17.0, 10.0], "RW": [.88, 27.0, 13.0], "AM": [.05, 22.0, 17.0], "ST": [0.0, 31.0, 24.0]}
const SLOT_FY := {"LB": .2, "LCB": .15, "RCB": .15, "RB": .2, "SS": .42, "DM": .3, "CM": .36, "RW": .42, "AM": .43, "ST": .47}
const TRAIT := {"GK": {}, "LB": {"cross": .7}, "RB": {"spd": .03, "cross": .45}, "RCB": {"tackle": .25}, "LCB": {"carry": 1.0},
	"DM": {"spd": .04, "tackle": .3, "press": 1.0}, "CM": {"spd": .02}, "RW": {"spd": .05, "cross": .4}, "AM": {"range": 30.0}, "SS": {"range": 26.0},
	"ST": {"hold": .55, "head": .25}}

class Oy:
	var team := 0
	var i := 0
	var role := "O"
	var pos := "CM"
	var no := 0
	var n := ""
	var ten := "#f1c9a5"
	var sac := "#2a1a10"
	var st := 1.0
	var inj := false
	var dz := false
	var fx := .5
	var fy := .5
	var x := 0.0
	var y := 0.0
	var vx := 0.0
	var vy := 0.0
	var dx := 0.0
	var dy := 0.0
	var anim := 0.0
	var cd := 0.0
	var scd := 0.0
	var slide := 0.0
	var stun := 0.0
	var hold := 0.0
	var dec := 0.0
	var hedef := false
	var tx := 0.0
	var ty := 0.0
	var run := 0.0
	var mx := 0.0
	var my := 0.0
	var dive := 0
	# kaleci uçuşu (görüntü): kalan süre, tür (0 göğüste tutma, 1 yana uçuş), yön, top yüksekliği, görüntünün yetişeceği konum farkı
	var ucus := 0.0
	var ucus_tur := 0
	var ucus_yan := 0.0
	var ucus_z := 0.0
	var ucus_ofs := Vector2.ZERO
	var first_time := false
	var ayak := false          # geri pas: kaleci topu eline alamaz, ayağıyla oynar
	var won := false
	var sari := false

class Top:
	var x := PW / 2
	var y := PL / 2
	var z := 0.0
	var vx := 0.0
	var vy := 0.0
	var vz := 0.0
	var owner: Oy = null
	var last: Oy = null
	var last_team := 0
	var kicker: Oy = null
	var intended: Oy = null
	var shot := false
	var shot_team := 0
	var shot_t := 0.0
	var gk_tried: Oy = null
	var cross := false
	var atis := false          # taçtan atıldı (doğrudan gol olmaz)
	var ofs = null       # {q, team, yakin}

# --- durum ---
var T: Array = []          # [{t, kit:{c1,c2}, score, human, str, spd, skill}]
var P: Array = []          # Oy
var ball := Top.new()
var demo := false
var kul_dep := false      # lig: kullanıcı (T[0]) deplasmanda — ev sahibi T[1]; forma önceliği ve tabela sırası ona göre
var diff := 1
var clock := 0.0
var dur := 240.0
var half := 1
var state := "pre"
var state_t := 1.2
var after := Callable()
var events: Array = []
var ctrl: Oy = null
var flip := false
var set_piece = null       # {p, t, ko, yol}
var poss_team = null
var cand_t := 0.0
var t_att = null
var trans_t := 0.0
var counter_t := 0.0
var counter_team := -1
var prep_t := 0.0
var TP = null
var marks = null
var prev_marks = null
var manual_t := 0.0
var durdu := 0
var uz = null
var kick_team := 0
var korner := [0, 0]
var faul := [0, 0]
var ofsayt := [0, 0]
var kartlar: Array = []   # [takım, ad, "S"/"K"]
# maç raporu (Champion Battle Manager 4.5.1'deki gibi): istatistik + oyuncu başına
var ist := {"sut": [0, 0], "isabet": [0, 0], "pas": [0, 0], "pas_ok": [0, 0], "top": [0.0, 0.0], "kurtar": [0, 0]}
var oy_ist := {}
var konus := {}         # takım konuşması: {"once"/"devre": sonuç, "sonuc": son metin}
# an: "once" | "devre", sec: 0..2 (mola.gd KONUSMA sırası). Etki duruma bağlı; iyi karşılanırsa takım biraz daha hızlı ve isabetli.
func konus_yap(an: String, sec: int) -> String:
	var fark: float = float(T[0].t.str) - float(T[1].t.str); var sk: int = int(T[0].score) - int(T[1].score)
	var q := 0
	if an == "once":
		q = [(1 if fark >= 1 else (-1 if fark <= -2 else 0)), (1 if fark <= 0 else 0), (1 if fark <= -1 else (-1 if fark >= 2 else 0))][sec]
	else:
		if sk > 0: q = [1, 0, -1][sec]
		elif sk == 0: q = [0, 1, (0 if fark >= 1 else -1)][sec]
		else: q = [-1, 1, (1 if fark >= 0 else 0)][sec]
	var r := randf()
	if r < .15: q = maxi(-1, q - 1)
	elif r > .85: q = mini(1, q + 1)
	T[0].spd += q * .022 + (.01 if an == "once" and sec == 2 else 0.0)
	T[0].skill = clampf(T[0].skill + q * .025 - (.01 if an == "once" and sec == 2 else 0.0), .3, .98)
	var metin := "Oyuncular konuşmayı çok iyi karşıladı" if q > 0 else ("Konuşma ters tepti, oyuncular gergin" if q < 0 else "Konuşma pek etki etmedi")
	konus[an] = metin; konus.sonuc = metin
	return metin
var asist_aday = null   # [pasör, alan, saat]
func oy_k(p: Oy) -> Dictionary:
	var k := str(p.team) + ":" + p.n
	if not oy_ist.has(k): oy_ist[k] = {"n": p.n, "no": p.no, "team": p.team, "rol": p.role, "g": 0, "a": 0, "s": 0, "i": 0, "k": 0, "p": 0, "pk": 0, "f": 0, "gir": 0}
	return oy_ist[k]
var atilan: Array = []
var avantaj_t := 0.0
var B: Array = [[], []]          # yedek kulübeleri
var hak := {"n": 5, "w": 3}      # 5 değişiklik, 3 ara (devre arası sayılmaz)
var sub: Array = [{"n": 0, "win": {}}, {"n": 0, "win": {}}]
var degisiklikler: Array = []
var oto_t := [0, 0]
var asistan := [true, true]      # asistan değişiklikleri (kullanıcı kendi takımı için kapatabilir; sakatlıkta yine devreye girer)
var yakin_ofs = null
var gol_atan: Oy = null
var kutlama_yer := Vector2.ZERO
var giris := {"x": 0.0, "y": 0.0, "pasE": false, "sutE": false, "pasS": 0.0, "sutG": -1.0}
# top bizdeyken PAS/ŞUT basılı tutulur, bırakınca çıkar: ŞUT'ta tutma süresi şut gücü, PAS'ta uzun basış ara pas
var dolum := {"pas": -1.0, "sut": -1.0}
const DOLUM_SURE := {"pas": .9, "sut": 1.0}
func dolum_olur() -> bool:
	return ctrl != null and not demo and ball.owner == ctrl and T[ctrl.team].human and (state == "play" or (set_piece != null and set_piece.p == ctrl))
func tus_bas(k: String) -> void:
	if dolum_olur(): dolum[k] = 0.0
	else: giris[k + "E"] = true
func tus_birak(k: String) -> void:
	if dolum[k] < 0: return
	if k == "pas": giris.pasS = dolum[k]
	else: giris.sutG = minf(1.0, dolum[k] / DOLUM_SURE[k])
	giris[k + "E"] = true; dolum[k] = -1.0
func dolum_orani(k: String) -> float:
	return 0.0 if dolum[k] < 0 else minf(1.0, dolum[k] / DOLUM_SURE[k])
func _dolum_adim(dt: float) -> void:
	for k in ["pas", "sut"]:
		if dolum[k] < 0: continue
		if ctrl == null or ball.owner != ctrl: dolum[k] = -1.0; continue
		dolum[k] += dt
		if dolum[k] >= DOLUM_SURE[k] + .15: tus_birak(k)
func sut_gucu() -> float:
	return 1.0 if giris.sutG < 0 else .95 + .3 * giris.sutG
func ara_pas_mi() -> bool:
	return giris.pasS >= .3
var olaylar: Array = []    # görüntü/ses katmanına: [ad, ...]
var _pass_score := 0.0

static func renk_farki(a: String, b: String) -> float:
	var A := Color(a)
	var B := Color(b)
	return Vector3(A.r - B.r, A.g - B.g, A.b - B.b).length() * 255.0

static func forma_sec(A: Dictionary, B: Dictionary) -> Array:
	var a := {"c1": A.c1, "c2": A.c2}
	var b := {"c1": B.c1, "c2": B.c2}
	if renk_farki(a.c1, b.c1) < 120:
		b = {"c1": B.c2, "c2": B.c1}
		if renk_farki(a.c1, b.c1) < 120: b = {"c1": "#f4f4f4", "c2": "#222222"}
		if renk_farki(a.c1, b.c1) < 120: b = {"c1": "#222222", "c2": "#f4f4f4"}
	return [a, b]

func _init(ev: Dictionary, dep: Dictionary, sure_dk: float, zorluk: int, gosterim: bool, deplasman := false) -> void:
	demo = gosterim
	kul_dep = deplasman
	diff = zorluk
	dur = sure_dk * 60.0
	var k := forma_sec(ev, dep)
	if kul_dep: k = forma_sec(dep, ev); k = [k[1], k[0]]   # gerçek ev sahibi kendi formasını giyer
	T = [{"t": ev, "kit": k[0], "score": 0, "human": not demo}, {"t": dep, "kit": k[1], "score": 0, "human": false}]
	for ti in 2:
		var td: Dictionary = T[ti].t
		var str_: float = float(td.str)
		T[ti].str = str_
		T[ti].spd = 1.0 + (str_ - 6.0) * .018 + (DIFF.spd[diff] if ti == 1 and not demo else 0.0)
		T[ti].skill = clampf(.45 + str_ * .05 + (DIFF.skill[diff] if ti == 1 and not demo else 0.0), .3, .98)
		var oy: Array = td.oy
		for i in oy.size():
			var s: Dictionary = oy[i]
			var p := Oy.new()
			p.team = ti; p.i = i; p.role = "G" if i == 0 else s.rol; p.pos = s.yer; p.no = int(s.no); p.n = s.n
			p.ten = s.ten; p.sac = s.sac; p.st = float(s.st); p.dz = bool(s.dz); p.fx = float(s.fx); p.fy = float(s.fy)
			p.dy = -1.0 if ti == 0 else 1.0
			P.append(p)
	for ti in 2: B[ti] = (T[ti].t.get("yedek", []) as Array).duplicate()
	for q: Oy in P: oy_k(q)
	kickoff(0)
	var e: int = 1 if kul_dep else 0
	olay("banner", T[e].t.kisa + " - " + T[1 - e].t.kisa, "BAŞLAMA VURUŞU")
	olay("duduk", 1)

func olay(ad: String, a = null, b = null) -> void:
	olaylar.append([ad, a, b])

# ---------- yardımcılar ----------
func goal_y_of(ti: int) -> float: return 0.0 if ((ti == 0) != flip) else PL
func own_goal_y(ti: int) -> float: return PL - goal_y_of(ti)
# kaleci kurtarışa uzanır: topun kale çizgisine geleceği yere doğru yana uçar (ya da yakınsa göğsünde tutar).
# Motor konumu uçuşun bittiği yere hemen geçer; görüntü ucus_ofs ile eski yerden oraya süzülür (geri sıçrama yok).
func kaleci_uc(g: Oy, b: Top, ly: float) -> void:
	var hx := b.x
	if b.vy != 0:
		var tt := (ly - b.y) / b.vy
		if tt > 0 and tt < 2: hx = b.x + b.vx * tt
	var dx := clampf(hx - g.x, -2.6, 2.6)
	g.ucus_z = clampf(b.z, 0, 2.4)
	if absf(dx) < .7 and g.ucus_z < 1.6:
		g.ucus_tur = 0; g.ucus = .7; g.ucus_yan = 0; g.ucus_ofs = Vector2.ZERO
		return
	g.ucus_tur = 1; g.ucus = 1.5; g.ucus_yan = signf(dx) if dx != 0 else 1.0
	var kay := dx * .85
	g.x = clampf(g.x + kay, GX0 - 1.2, GX1 + 1.2)
	g.ucus_ofs = Vector2(-kay, 0)
	g.vx = 0; g.vy = 0

func fwd_of(ti: int) -> float: return -1.0 if goal_y_of(ti) == 0.0 else 1.0
func depth_of(ti: int, yy: float) -> float: return absf(yy - own_goal_y(ti))
func y_at_depth(ti: int, d: float) -> float: return own_goal_y(ti) + fwd_of(ti) * d
func right_of(ti: int) -> float: return 1.0 if fwd_of(ti) == -1.0 else -1.0
static func ozl(p: Oy, k: String, d := 0.0) -> float:
	var t: Dictionary = TRAIT.get(p.pos, {})
	return float(t[k]) if t.has(k) else d
static func rnd(a: float, b: float) -> float: return a + randf() * (b - a)
static func hyp(a: float, b: float) -> float: return sqrt(a * a + b * b)

func home(p: Oy) -> Vector2:
	var up := fwd_of(p.team) == -1.0
	return Vector2(p.fx * PW if up else (1 - p.fx) * PW, PL - p.fy * PL if up else p.fy * PL)

func minute() -> int: return mini(KM_SINIR[half], int(floor(clock / dur * 90)))
func min_label() -> String:
	var r := int(floor(clock / dur * 90))
	var s: int = KM_SINIR[half]
	return (str(s) + "+" + str(r - s + 1)) if r >= s else str(r)

func kickoff(ti: int) -> void:
	var b := ball
	b.x = PW / 2; b.y = PL / 2; b.z = 0; b.vx = 0; b.vy = 0; b.vz = 0; b.owner = null; b.shot = false; b.intended = null; b.gk_tried = null; b.kicker = null
	for p: Oy in P:
		var h := home(p)
		var yy := h.y
		if fwd_of(p.team) == -1.0: yy = maxf(yy, PL / 2 + 2)
		else: yy = minf(yy, PL / 2 - 2)
		p.x = h.x; p.y = yy; p.vx = 0; p.vy = 0; p.dx = 0; p.dy = fwd_of(p.team); p.cd = 0; p.slide = 0; p.stun = 0; p.hold = 0
	var kt: Array = P.filter(func(p): return p.team == ti and p.role == "F")
	var yed: Array = P.filter(func(p): return p.team == ti and p.role != "G" and p.role != "F")
	while kt.size() < 2 and yed.size() > 0: kt.append(yed.pop_back())
	kt[0].x = PW / 2 - .2; kt[0].y = PL / 2 - fwd_of(ti) * .6; kt[1].x = PW / 2 + 4; kt[1].y = PL / 2 - fwd_of(ti) * 1.2
	b.owner = kt[0]; b.last_team = ti; kick_team = ti; poss_team = ti; cand_t = 0; TP = null; prep_t = 0; kt[0].hold = 0
	set_piece = {"p": kt[0], "t": 0.0, "ko": true}
	mesafe_kurali()
	ctrl = null
	for p: Oy in P:
		if p.team == 0 and p.role == "F": ctrl = p; break
	if ti == 0: ctrl = kt[0]

func tehlike() -> bool:
	var b := ball
	if b.shot or b.cross: return true
	return minf(b.y, PL - b.y) < PL * .3

func uzatma_kontrol(sinir: float) -> bool:
	if demo: return clock >= sinir
	if uz == null and clock >= sinir:
		uz = (1 + randi() % 4) if half == 1 else (3 + randi() % 4)
		olay("flash", "UZATMA +" + str(uz) + " DK")
	var bitis := INF if uz == null else sinir + float(uz) * dur / 90.0
	var olu := durdu
	durdu = 0
	if clock < bitis: return false
	var b := ball
	var u := minf(b.y, PL - b.y)
	var temiz := not b.shot and not b.cross
	if clock >= bitis + dur * .07: return true    # kesin sınır: top kale önünde dönüp dursa da maç biter
	if u < 20: return false
	return (olu == 1 and u > 30) or (olu == 0 and not tehlike()) or (clock >= bitis + dur * .045 and temiz and u > 24) or (clock >= bitis + dur * .08 and temiz)

# ---------- ana adım ----------
func step(dt: float) -> void:
	if demo: giris.x = 0.0; giris.y = 0.0
	_dolum_adim(dt)
	if state == "over": return
	if state != "play":
		state_t -= dt
		for p: Oy in P:
			p.vx *= .85; p.vy *= .85; p.x += p.vx * dt; p.y += p.vy * dt; p.anim += hyp(p.vx, p.vy) * dt
		if state == "goal" and gol_atan != null: gol_kutlama(dt)
		elif state == "goal" or state == "half": move_off_ball(dt, true)
		var yol = set_piece.get("yol") if (state == "pre" and set_piece != null) else null
		if yol != null:
			var q: Oy = set_piece.p
			var ddx: float = yol.tx - q.x
			var ddy: float = yol.ty - q.y
			var dd := hyp(ddx, ddy)
			if yol.bekle > 0 or state_t < .3:
				var qx := q.x; var qy := q.y; var qa := q.anim
				move_off_ball(dt, true)
				q.x = qx; q.y = qy; q.anim = qa
			q.vx = 0; q.vy = 0
			if dd > .05:
				var v := minf(11, 2 + dd * 2.5)
				var s := minf(dd, v * dt)
				q.x += ddx / dd * s; q.y += ddy / dd * s; q.anim += s; q.dx = ddx / dd; q.dy = ddy / dd
				q.vx = ddx / dd * v; q.vy = ddy / dd * v
			else:
				q.x = yol.tx; q.y = yol.ty; q.dx = yol.fx; q.dy = yol.fy
			if state_t <= 0 and dd > .3:
				yol.bekle += dt
				if yol.bekle < 6: state_t = .05
			if state_t <= 0:
				q.x = yol.tx; q.y = yol.ty; q.dx = yol.fx; q.dy = yol.fy; set_piece.erase("yol")
		if state_t <= 0:
			var f := after
			after = Callable()
			if f.is_valid(): f.call()
			else: state = "play"
		if state == "pre": mesafe_kurali()
		giris.pasE = false; giris.sutE = false; giris.pasS = 0.0; giris.sutG = -1.0
		return
	clock += dt
	if half == 1 and uzatma_kontrol(dur / 2):
		uz = null; clock = dur / 2; half = 2; state = "half"; state_t = 3.0
		olay("duduk", 2); olay("banner", "DEVRE ARASI", str(T[0].score) + " - " + str(T[1].score))
		mola(1)
		after = func():
			flip = true; t_att = null; poss_team = null; TP = null
			kickoff(1); state = "pre"; state_t = .8
			olay("duduk", 1); olay("banner", "2. YARI", "KALELER DEĞİŞTİ")
		return
	if half == 2 and uzatma_kontrol(dur):
		uz = null; bitir(); return
	manual_t = maxf(0, manual_t - dt)
	update_ctrl()
	for p: Oy in P:
		p.cd = maxf(0, p.cd - dt); p.scd = maxf(0, p.scd - dt); p.stun = maxf(0, p.stun - dt); p.dec -= dt
		if p.ucus > 0: p.ucus = maxf(0, p.ucus - dt)
	if set_piece != null:
		set_piece.t += dt
		if ball.owner != set_piece.p: set_piece = null
	kondisyon(dt); oto_degisiklik()
	tactical_prep(dt)
	for p: Oy in P.duplicate(): think(p, dt)
	for p: Oy in P.duplicate():
		if P.has(p): move_player(p, dt)
	separate()
	mesafe_kurali()
	if poss_team != null: ist.top[poss_team] += dt
	ball_step(dt)
	mesafe_kurali()
	giris.pasE = false; giris.sutE = false; giris.pasS = 0.0; giris.sutG = -1.0

func bitir() -> void:
	state = "over"
	olay("duduk", 3)
	var e: int = 1 if kul_dep else 0
	olay("banner", "MAÇ SONU", T[e].t.kisa + " " + str(T[e].score) + " - " + str(T[1 - e].score) + " " + T[1 - e].t.kisa)

func update_ctrl() -> void:
	if demo: ctrl = null; return
	var b := ball
	if b.owner != null and b.owner.team == 0: ctrl = b.owner; return
	if b.intended != null and b.intended.team == 0 and b.owner == null: ctrl = b.intended; return
	var field: Array = P.filter(func(p): return p.team == 0 and p.role != "G")
	var best: Oy = null
	var bd := 1e9
	for p: Oy in field:
		var d := hyp(p.x - b.x, p.y - b.y)
		if d < bd: bd = d; best = p
	var cur: Oy = ctrl if (ctrl != null and ctrl.team == 0 and ctrl.role != "G") else null
	if giris.pasE and not (b.owner != null and b.owner.team == 0):
		var ord := field.duplicate()
		ord.sort_custom(func(a, c): return hyp(a.x - b.x, a.y - b.y) < hyp(c.x - b.x, c.y - b.y))
		ctrl = ord[1] if (cur != null and ord[0] == cur and ord.size() > 1) else ord[0]
		giris.pasE = false; manual_t = 1.5; olay("tik"); return
	if cur == null: ctrl = best; return
	if manual_t > 0 or cur.slide > 0: return
	var cdd := hyp(cur.x - b.x, cur.y - b.y)
	var pushing: bool = giris.x != 0.0 or giris.y != 0.0
	if best != cur and ((not pushing and cdd - bd > 3.5) or (pushing and cdd - bd > 8) or cdd > 18): ctrl = best

# ---------- yapay zekâ ----------
func team_has_ball(ti: int) -> bool: return ball.owner != null and ball.owner.team == ti
func nearest_opp(p) -> Array:
	var best: Oy = null
	var bd := 1e9
	for q: Oy in P:
		if q.team != p.team:
			var d := hyp(q.x - p.x, q.y - p.y)
			if d < bd: bd = d; best = q
	return [best, bd]
func chasers(ti: int) -> Array:
	var b := ball
	var l: Array = []
	for p: Oy in P:
		if p.team == ti and p.role != "G": l.append({"p": p, "d": hyp(p.x - b.x, p.y - b.y)})
	l.sort_custom(func(a, c): return a.d < c.d)
	return l

func team_plan(ti: int) -> Dictionary:
	if TP != null: return TP[ti]
	return {"poss": false, "line": 24.0, "cx": PW / 2, "ws": .7, "last": PL - 14, "mid": PL - 30, "mode": "def"}

func dz_slot(p: Oy):
	if not SLOT.has(p.pos): return null
	var B: Array = SLOT[p.pos]
	var df = (p.fy - SLOT_FY[p.pos]) * 100.0
	return [clampf((p.fx - .5) * 2, -.95, .95), maxf(0, B[1] + df * .8), maxf(0, B[2] + df * .6)]

func slot_pos(p: Oy, in_poss: bool) -> Vector2:
	var ti := p.team
	var Pp := team_plan(ti)
	var S = dz_slot(p) if p.dz else SLOT.get(p.pos)
	if S == null: return home(p)
	var d: float = Pp.line + (S[1] if in_poss else S[2])
	var xx: float = Pp.cx + right_of(ti) * S[0] * 31.0 * (1.0 if in_poss else Pp.ws)
	return Vector2(clampf(xx, 2, PW - 2), y_at_depth(ti, clampf(d, 3, PL - 6)))

func tactical_prep(dt: float) -> void:
	var b := ball
	var cur = b.owner.team if b.owner != null else null
	if cur != null:
		if cur == poss_team: cand_t = 0
		else:
			cand_t += dt
			if cand_t > .45 or poss_team == null: poss_team = cur; cand_t = 0
	var att: int = b.last_team if poss_team == null else poss_team
	if t_att == null or att != t_att:
		t_att = att; trans_t = 1.4; prep_t = 0
		var ahead := 0
		for q: Oy in P:
			if q.team != att and q.role != "G" and depth_of(att, q.y) > depth_of(att, b.y) + 2: ahead += 1
		counter_t = 4.5 if (ahead <= 5 and depth_of(att, b.y) < 72) else 0.0
		counter_team = att
	trans_t = maxf(0, trans_t - dt); counter_t = maxf(0, counter_t - dt)
	prep_t -= dt
	if prep_t > 0 and marks != null: return
	prep_t = .25
	TP = []
	for ti in 2:
		var poss := att == ti
		var bd := depth_of(ti, b.y)
		var last := 0.0; var ms := 0.0; var mn := 0
		for q: Oy in P:
			if q.team == ti or q.role == "G": continue
			var d := depth_of(ti, q.y)
			if q.role == "D": last = maxf(last, d)
			elif q.role == "O": ms += d; mn += 1
		if last == 0: last = PL - 14
		var mid := ms / mn if mn > 0 else last - 12
		var line: float; var cx: float; var ws: float
		if poss:
			line = clampf(bd - 18, 26, 50); cx = PW / 2 + (b.x - PW / 2) * .22; ws = 1
		else:
			var hi: float = 1.0 if (demo or not T[1 - ti].human) else [.9, .96, 1.0][diff]
			line = clampf((bd * .62 - 4) * hi, 8, 38); cx = PW / 2 + (b.x - PW / 2) * .5; ws = .62
		var mode := "def"
		if poss: mode = "counter" if (counter_t > 0 and counter_team == ti) else "build"
		TP.append({"poss": poss, "line": line, "cx": cx, "ws": ws, "last": minf(last, PL - 3), "mid": mid, "mode": mode})
	marks = {}
	var def := 1 - att
	var presser: Oy = null
	var pd := 1e9
	for q: Oy in P:
		if q.team == def and q.role != "G":
			var d := hyp(q.x - b.x, q.y - b.y)
			if d < pd: pd = d; presser = q
	var used := {presser: true}
	var attackers: Array = P.filter(func(q): return q.team == att and q.role != "G" and q != b.owner)
	attackers.sort_custom(func(a, c): return depth_of(def, a.y) < depth_of(def, c.y))
	var vs_human: bool = not demo and T[att].human
	var zone: float = ([22.0, 28.0, 34.0][diff] if vs_human else 30.0) + TP[def].line
	for a: Oy in attackers:
		if depth_of(def, a.y) > zone: continue
		var best: Oy = null
		var bd := 1e9
		for d: Oy in P:
			if d.team != def or d.role == "G" or used.has(d): continue
			var s := slot_pos(d, false)
			var dd := hyp(s.x - a.x, s.y - a.y) + (14.0 if d.pos in ["ST", "AM", "SS"] else 0.0) + (5.0 if d.pos == "RW" else 0.0)
			if prev_marks != null and prev_marks.get(d) == a: dd -= 4
			if dd < bd: bd = dd; best = d
		if best != null and bd < 15: used[best] = true; marks[best] = a
	prev_marks = marks

func _fin(p: Oy, Pp: Dictionary, x: float, y: float, run = null) -> Dictionary:
	var b := ball
	var ti := p.team
	var urg := .12 if trans_t > 0 else 0.0
	x = clampf(x, 1.5, PW - 1.5); y = clampf(y, 2, PL - 2)
	if Pp.poss:
		var c: Oy = b.owner if (b.owner != null and b.owner.team == ti) else null
		if c != null and c != p:
			var ux := x - c.x; var uy := y - c.y; var d0 := hyp(ux, uy)
			if d0 == 0: d0 = 1
			if d0 < 9: x = c.x + ux / d0 * 9; y = c.y + uy / d0 * 9
		for q: Oy in P:
			if q.team != ti or q == p or q == c or q.role == "G": continue
			var ux := x - q.x; var uy := y - q.y; var d0 := hyp(ux, uy)
			if d0 < 7 and d0 > 0: x += ux / d0 * (7 - d0) * .6; y += uy / d0 * (7 - d0) * .3
		var o: Oy = null
		var od := 1e9
		for q: Oy in P:
			if q.team != ti:
				var d := hyp(q.x - x, q.y - y)
				if d < od: od = d; o = q
		if o != null and od < 3.5:
			var odd := od if od != 0 else 1.0
			var ux := (x - o.x) / odd; var uy := (y - o.y) / odd
			x += ux * (3.5 - od); y += uy * (3.5 - od) * .5
	var dd := hyp(x - p.x, y - p.y)
	var r: float = run if run != null else (.95 if dd > 7 else (.78 if dd > 2.5 else .55))
	return {"x": clampf(x, 1.5, PW - 1.5), "y": clampf(y, 2, PL - 2), "run": minf(1, r + urg)}

func off_ball_target(p: Oy) -> Dictionary:
	var b := ball
	var ti := p.team
	var Pp := team_plan(ti)
	var pos := p.pos
	var R := right_of(ti)
	var at := func(d: float, x: float, run = null): return _fin(p, Pp, x, y_at_depth(ti, clampf(d, 2, PL - 3)), run)
	var side_x := func(lx: float): return Pp.cx + R * lx * 31.0
	if not Pp.poss:
		var s := slot_pos(p, false)
		var bd := depth_of(ti, b.y)
		if pos == "DM" and bd < Pp.line + 40:
			return at.call(clampf(bd - 6, Pp.line + 3, Pp.line + 15), s.x + (b.x - s.x) * .5, .95)
		var m = marks.get(p) if marks != null else null
		if m != null:
			var og := own_goal_y(ti)
			var md := depth_of(ti, m.y)
			var ddx: float = PW / 2 - m.x; var ddy: float = og - m.y; var d := hyp(ddx, ddy)
			if d == 0: d = 1
			var gap := 1.8 if md < 22 else (2.6 if md < 34 else 3.4)
			var x: float = m.x + ddx / d * gap + m.vx * .15
			var y: float = m.y + ddy / d * gap + m.vy * .15
			var floor_: float = Pp.line - 3
			if md > floor_ and depth_of(ti, y) < floor_: y = y_at_depth(ti, floor_)
			return _fin(p, Pp, x, y, 1.0 if hyp(x - p.x, y - p.y) > 2.5 else .8)
		return _fin(p, Pp, s.x, s.y)
	var car: Oy = b.owner if (b.owner != null and b.owner.team == ti) else null
	var refx := car.x if car != null else b.x
	var refy := car.y if car != null else b.y
	var cd := depth_of(ti, refy)
	var bx := refx
	var ball_r := (bx - PW / 2) * R > 0
	var s := slot_pos(p, true)
	if car != null and car.role == "G":
		if pos == "LCB" or pos == "RCB": return at.call(8.0, PW / 2 + R * (1.0 if pos == "RCB" else -1.0) * 15, .9)
		if pos == "LB" or pos == "RB": return at.call(22.0, side_x.call(.95 if pos == "RB" else -.95), .9)
		if pos == "DM": return at.call(22.0, PW / 2 + (3.0 if p.x > PW / 2 else -3.0), .9)
	if Pp.mode == "counter" and pos in ["ST", "SS", "RW", "AM", "CM"]:
		var add := 12.0 if pos == "CM" else (16.0 if pos == "AM" else 24.0)
		var d := minf(Pp.last + 3, cd + add)
		var lx: float = {"ST": 0.0, "SS": -.55, "AM": .12, "CM": .3, "RW": .8}[pos]
		return at.call(d, side_x.call(lx), 1.0)
	match pos:
		"LB", "RB":
			var mine := (pos == "RB") == ball_r
			var tx := PW - 2.5 if ((pos == "RB") == (R > 0)) else 2.5
			if mine and cd > 34 and car != null and car != p and car.pos != "LCB" and car.pos != "RCB": return at.call(minf(cd + 10, Pp.last + 1), tx, 1.0)
			if not mine: return at.call(Pp.line + 4, side_x.call(.66 if pos == "RB" else -.66))
			return _fin(p, Pp, s.x, s.y)
		"LCB", "RCB": return at.call(Pp.line, s.x)
		"DM": return at.call(clampf(cd - 11, Pp.line + 5, Pp.line + 22), s.x + (bx - s.x) * .3)
		"CM":
			if cd > PL - 40 and car != null and car != p: return at.call(minf(PL - 11, Pp.last + 1), PW / 2 + R * 4, 1.0)
			return at.call(clampf(cd + 2, Pp.line + 10, PL - 22), PW / 2 - (bx - PW / 2) * .45 + R * 6)
		"AM": return at.call(clampf((Pp.last + Pp.mid) / 2, cd + 10, PL - 16), PW / 2 + (bx - PW / 2) * .25 + R * 3)
		"ST":
			var ph := fmod(clock * .3 + p.i * .41 + ti * .2, 1.0)
			if car != null and cd > 28 and ph < .55: return at.call(minf(Pp.last + 2.5, PL - 7), PW / 2 + (bx - PW / 2) * .2, 1.0)
			return at.call(maxf(Pp.last - 5, cd + 14), PW / 2 + (bx - PW / 2) * .2)
		"SS":
			if cd > PL - 45: return at.call(minf(Pp.last, PL - 12), PW / 2 - R * 5, 1.0)
			return at.call(minf(Pp.last - 2, depth_of(ti, s.y)), side_x.call(-.62))
		"RW":
			var fb: Oy = null
			for q: Oy in P:
				if q.team == ti and q.pos == "RB": fb = q; break
			var over := ball_r and fb != null and depth_of(ti, fb.y) > cd - 3 and fb != car
			return at.call(minf(Pp.last - 1, PL - 8), side_x.call(.42 if over else .92))
	return _fin(p, Pp, s.x, s.y)

func form_target(p: Oy) -> Vector2:
	if p.role == "G": return home(p)
	return slot_pos(p, team_plan(p.team).poss)

func ahead_gap(p: Oy) -> float:
	var f := fwd_of(p.team)
	var a := 99.0
	for q: Oy in P:
		if q.team == p.team: continue
		var ax := q.x - p.x; var ay := (q.y - p.y) * f
		if ay > 0 and ay < 14 and absf(ax) < ay * .9 + 1.5: a = minf(a, hyp(ax, ay))
	return a

func think_carrier(p: Oy, dt: float) -> void:
	var Tt: Dictionary = T[p.team]
	var gy := goal_y_of(p.team)
	var f := fwd_of(p.team)
	var Pp := team_plan(p.team)
	if set_piece != null and set_piece.p == p:
		p.mx = 0; p.my = 0
		if set_piece.t > .9:
			if set_piece.get("pen", false): do_shoot(p, 0, 1.05); return
			if set_piece.get("fk", false) and hyp(PW / 2 - p.x, goal_y_of(p.team) - p.y) < 28 and randf() < .45: do_shoot(p, 0, 1.0); return
			if is_corner(p):
				var q := cross_target(p)
				if q != null: do_cross(p, q); return
			var s := best_pass(p, 0, f, true)
			if s != null: do_pass(p, s.x - p.x, s.y - p.y, s)
			else: do_pass(p, 0, f)
		return
	var dG := hyp(PW / 2 - p.x, gy - p.y)
	var cd := depth_of(p.team, p.y)
	var no := nearest_opp(p)
	var opp: Oy = no[0]
	var od: float = no[1]
	var gap := ahead_gap(p)
	p.hold += dt
	if p.first_time:
		p.first_time = false
		if dG < 19: do_shoot(p, 0, .85); return
	var wide := absf(p.x - PW / 2) > 18
	var counter: bool = Pp.mode == "counter"
	if p.dec <= 0:
		p.dec = rnd(.2, .4)
		var ang := absf(PW / 2 - p.x) / maxf(1, absf(gy - p.y))
		var range_ := ozl(p, "range", 24)
		var sh := .75 if dG < 14 else (.38 if dG < 24 else .2)
		if dG < range_ and ang < 1.3 and randf() < sh * Tt.skill + .06: do_shoot(p, 0); return
		if wide and cd > PL - 26 and randf() < .35 + ozl(p, "cross", 0):
			var q := cross_target(p)
			if q != null: do_cross(p, q); return
		var pressed := od < 3.2
		var s := best_pass(p, 0, f, false)
		var sc := _pass_score
		var carry := ozl(p, "carry", 0) > 0 and gap > 10 and cd < PL * .6
		var want := .65 if pressed else (.5 if counter else (.08 if carry else (.6 if p.hold > 2 else (.45 if gap < 6 else .3))))
		if s != null and sc > (-.6 if pressed else .25) and randf() < want: do_pass(p, s.x - p.x, s.y - p.y, s); return
	var tx: float; var ty: float
	if wide and p.pos == "RW" and cd > PL - 40 and (p.i + int(floor(clock / 8))) % 2 == 0:
		tx = PW / 2 + (p.x - PW / 2) * .3; ty = gy - f * 16
	elif wide and cd > PL - 36:
		tx = 4.0 if p.x < PW / 2 else PW - 4; ty = gy - f * 2
	elif p.pos == "SS" and cd > PL - 50:
		tx = PW / 2; ty = gy - f * 14
	else:
		tx = PW / 2 + (p.x - PW / 2) * .6; ty = gy
	var dx := tx - p.x; var dy := ty - p.y; var d := hyp(dx, dy)
	if d == 0: d = 1
	dx /= d; dy /= d
	if opp != null and od < 6:
		var ax := opp.x - p.x; var ay := opp.y - p.y
		if ax * dx + ay * dy > 0:
			var side := 1.0 if (ax * dy - ay * dx) > 0 else -1.0
			var nx := dx + (-dy) * side * .9; var ny := dy + dx * side * .9; var n := hyp(nx, ny)
			dx = nx / n; dy = ny / n
	if p.x < 3: dx = absf(dx)
	if p.x > PW - 3: dx = -absf(dx)
	p.mx = dx; p.my = dy; p.run = 1.0 if counter else (.95 if gap > 9 else .85)

func best_pass(p: Oy, dx: float, dy: float, _any: bool) -> Oy:
	var dn := hyp(dx, dy)
	if dn == 0: dn = 1
	dx /= dn; dy /= dn
	var f := fwd_of(p.team)
	var Pp := team_plan(p.team)
	var hum: bool = T[p.team].human and p == ctrl
	var pod: float = nearest_opp(p)[1]
	var pressed := pod < 3.2
	var counter: bool = Pp.mode == "counter"
	var best: Oy = null
	var bs := -1e9
	for q: Oy in P:
		if q.team != p.team or q == p: continue
		var vx := q.x - p.x; var vy := q.y - p.y; var d := hyp(vx, vy)
		if d < 4 or d > 50: continue
		if not hum and ofsayt_mi(p, q) > 1.2 and randf() < .85: continue
		var cs := (vx * dx + vy * dy) / d
		var prog := vy * f
		var s := (cs * 2.2 if (dx != 0 or dy != 0) else 0.0) - d / 32 + (.6 if (q.vy * f > 3.5 and prog > 0) else 0.0)
		if not hum:
			s += clampf(prog, -20, 35) * (.05 if counter else .028)
			if prog < -3 and not pressed: s -= .3
		var cut := 0
		for o: Oy in P:
			if o.team == p.team: continue
			var ox := o.x - p.x; var oy := o.y - p.y
			var t := clampf((ox * vx + oy * vy) / (d * d), 0, 1)
			var dd := hyp(p.x + vx * t - o.x, p.y + vy * t - o.y)
			var lr := 1.7 + d * t * .045
			if dd < lr: s -= 2 * (1 - dd / lr) * (1.0 if t > .12 else .6)
			elif not hum and t > .2 and t < .9 and dd < 9: cut += 1
		var oq: float = nearest_opp(q)[1]
		s += minf(oq, 8) * .08
		if oq < 2.5: s -= .9
		if not hum and prog > 8: s += mini(cut, 3) * .08
		if q.role == "G": s -= .4 if pressed else 1.4
		if (dx != 0 or dy != 0) and cs < .25: s -= 2
		if s > bs: bs = s; best = q
	_pass_score = bs
	return best

func is_corner(p: Oy) -> bool: return depth_of(p.team, p.y) > PL - 2 and absf(p.x - PW / 2) > PW / 2 - 2

func cross_target(p: Oy) -> Oy:
	var ti := p.team
	var best: Oy = null
	var bs := -1e9
	for q: Oy in P:
		if q.team != ti or q == p or q.role == "G": continue
		if depth_of(ti, q.y) < PL - 22: continue
		var oq: float = nearest_opp(q)[1]
		var s := minf(oq, 6) * .5 - absf(q.x - PW / 2) * .07 + ozl(q, "head", 0) * 4 + (.5 if q.pos == "ST" else 0.0)
		if s > bs: bs = s; best = q
	return best

func do_cross(p: Oy, q: Oy) -> void:
	var gy := goal_y_of(p.team)
	var f := fwd_of(p.team)
	var Tt: Dictionary = T[p.team]
	var tx := clampf(q.x + q.vx * .5 + rnd(-1.6, 1.6) * (1.3 - Tt.skill), GX0 - 5, GX1 + 5)
	var ty := gy - f * clampf(absf(gy - q.y - q.vy * .5), 5, 13)
	var D := hyp(tx - p.x, ty - p.y)
	if D == 0: D = 1
	var ux := (tx - p.x) / D; var uy := (ty - p.y) / D
	var vz := 6.6 + D * .035
	var ta := 2 * vz / 18
	var v := D / (ta * .94)
	p.dx = ux; p.dy = uy
	release(p, ux * v, uy * v, vz, q); ball.cross = true; olay("vurus", .8)

func gk_pass(p: Oy) -> Oy:
	var best: Oy = null
	var bs := -1e9
	for q: Oy in P:
		if q.team != p.team or q == p: continue
		if not q.pos in ["LCB", "RCB", "LB", "RB", "DM"]: continue
		var d := hyp(q.x - p.x, q.y - p.y)
		if d > 34: continue
		var oq: float = nearest_opp(q)[1]
		var s := minf(oq, 10) * .3 - d * .02
		for o: Oy in P:
			if o.team == p.team: continue
			var vx := q.x - p.x; var vy := q.y - p.y
			var t := clampf(((o.x - p.x) * vx + (o.y - p.y) * vy) / (d * d), 0, 1)
			if hyp(p.x + vx * t - o.x, p.y + vy * t - o.y) < 2.5: s -= 2
		if s > bs: bs = s; best = q
	if best != null and bs > 1.4: return best
	var lb: Oy = null
	var ls := -1e9
	for q: Oy in P:
		if q.team != p.team or not q.pos in ["ST", "RW", "SS", "AM"]: continue
		var s: float = nearest_opp(q)[1] + (1.0 if q.pos == "ST" else 0.0)
		if s > ls: ls = s; lb = q
	return lb if lb != null else best

func _hedef(p: Oy, v: Vector2, run: float) -> void:
	p.hedef = true; p.tx = v.x; p.ty = v.y; p.run = run

func think(p: Oy, dt: float) -> void:
	var b := ball
	var Tt: Dictionary = T[p.team]
	p.hedef = false; p.run = 0; p.mx = 0; p.my = 0
	if p.stun > 0 or p.slide > 0: return
	var human: bool = p == ctrl and Tt.human
	if human:
		var ix: float = giris.x
		var iy: float = giris.y
		if b.owner == p:
			if set_piece != null and set_piece.p == p and set_piece.get("ko", false) and (ix != 0 or iy != 0): set_piece = null
			if set_piece != null and set_piece.p == p:
				p.mx = 0; p.my = 0
				if ix != 0 or iy != 0: p.dx = ix; p.dy = iy
				var cq: Oy = cross_target(p) if is_corner(p) else null
				if giris.pasE:
					if cq != null: do_cross(p, cq)
					elif ara_pas_mi() and not set_piece.get("tac", false): do_ara_pas(p, ix if ix != 0 else p.dx, iy if iy != 0 else p.dy)
					else: do_pass(p, ix if ix != 0 else p.dx, iy if iy != 0 else p.dy)
				elif giris.sutE:
					if cq != null: do_cross(p, cq)
					elif set_piece.get("tac", false): do_pass(p, ix if ix != 0 else p.dx, iy if iy != 0 else p.dy)   # taçta şut yok: uzun atış
					else: do_shoot(p, ix, sut_gucu())
				elif set_piece.t > (6.0 if set_piece.get("ko", false) else 2.5):
					if cq != null: do_cross(p, cq)
					else: do_pass(p, p.dx, p.dy)
				return
			if p.first_time:
				p.first_time = false
				if hyp(PW / 2 - p.x, goal_y_of(p.team) - p.y) < 19: do_shoot(p, ix, .85); return
			if p.role == "G":
				p.hold += dt
				if giris.pasE or giris.sutE or p.hold > 1.6: do_pass(p, ix, iy if iy != 0 else fwd_of(p.team)); return
			if giris.pasE:
				if ara_pas_mi(): do_ara_pas(p, ix if ix != 0 else p.dx, iy if iy != 0 else p.dy)
				else: do_pass(p, ix if ix != 0 else p.dx, iy if iy != 0 else p.dy)
				return
			if giris.sutE: do_shoot(p, ix, sut_gucu()); return
			p.hold += dt; p.mx = ix; p.my = iy; p.run = 1.0 if (ix != 0 or iy != 0) else 0.0; return
		if giris.sutE and not (p.scd > 0):
			var bd2 := hyp(b.x - p.x, b.y - p.y)
			if bd2 < 5.5:
				var lx := b.x + (b.owner.vx * .18 if b.owner != null else b.vx * .12)
				var ly := b.y + (b.owner.vy * .18 if b.owner != null else b.vy * .12)
				do_slide(p, lx - p.x, ly - p.y)
			else: do_slide(p, ix if ix != 0 else p.dx, iy if iy != 0 else p.dy)
			return
		if ix != 0 or iy != 0: p.mx = ix; p.my = iy; p.run = 1; return
		if b.owner == null or b.intended == p: _hedef(p, intercept_point(p), 1); return
		p.mx = 0; p.my = 0; return
	if p.role == "G": think_gk(p, dt); return
	if b.owner == p: think_carrier(p, dt); return
	if b.intended == p and b.owner == null: _hedef(p, intercept_point(p), 1); return
	var ch := chasers(p.team)
	var human_team_chaser: bool = Tt.human and ctrl != null
	if not team_has_ball(p.team):
		var first: Oy = ch[0].p if ch.size() > 0 else null
		var second: Oy = ch[1].p if ch.size() > 1 else null
		if not human_team_chaser and first == p:
			_hedef(p, intercept_point(p), 1)
			if b.owner != null and b.owner.team != p.team and hyp(p.x - b.x, p.y - b.y) < 2.4 and not (p.scd > 0):
				var k: float = .6 if Tt.human else (DIFF.slide[diff] if (not demo and b.owner == ctrl) else 1.0)
				if randf() < dt * (.35 + Tt.skill * .4) * k: do_slide(p, b.x - p.x, b.y - p.y)
			return
		if b.owner == null and not human_team_chaser and second == p: _hedef(p, intercept_point(p), .8); return
		if human_team_chaser and b.owner == null and ctrl != p and first == p and hyp(p.x - b.x, p.y - b.y) < hyp(ctrl.x - b.x, ctrl.y - b.y) - 6:
			_hedef(p, intercept_point(p), .9); return
		if human_team_chaser and b.owner != null and b.owner.team != p.team and p != ctrl:
			var helper = null
			for x in ch:
				if x.p != ctrl: helper = x; break
			if helper != null and helper.p == p:
				var og := own_goal_y(p.team)
				var k := .3 if diff == 2 else .15
				_hedef(p, Vector2(b.x + (PW / 2 - b.x) * .2, b.y + (og - b.y) * k), .85); return
		if p.pos == "DM" and b.owner != null and b.owner.team != p.team and p != ctrl and first != p and hyp(p.x - b.x, p.y - b.y) < 13 and depth_of(p.team, b.y) < PL * .62:
			_hedef(p, intercept_point(p), .95)
			if hyp(p.x - b.x, p.y - b.y) < 2.2 and not (p.scd > 0):
				var k: float = .7 if Tt.human else (DIFF.slide[diff] if (not demo and b.owner == ctrl) else 1.0)
				if randf() < dt * .35 * k: do_slide(p, b.x - p.x, b.y - p.y)
			return
		var dm_p: Oy = null
		for q: Oy in P:
			if q.team == p.team and q.pos == "DM": dm_p = q; break
		var dm_on := dm_p != null and dm_p != first and dm_p != ctrl and b.owner != null and hyp(dm_p.x - b.x, dm_p.y - b.y) < 13
		if b.owner != null and second == p and not dm_on and not human_team_chaser and (demo or diff == 2 or b.owner.team != 0):
			var og := own_goal_y(p.team)
			_hedef(p, Vector2((b.x + PW / 2) / 2, b.y + (og - b.y) * .25), .7); return
	var h := off_ball_target(p)
	_hedef(p, Vector2(h.x, h.y), h.run)

func move_off_ball(dt: float, soft: bool) -> void:
	for p: Oy in P:
		var h := form_target(p)
		var dx := h.x - p.x; var dy := h.y - p.y; var d := hyp(dx, dy)
		if d > .5:
			var s := 3.0 * (.8 if soft else 1.0)
			p.vx = dx / d * s; p.vy = dy / d * s; p.x += p.vx * dt; p.y += p.vy * dt; p.anim += s * dt; p.dx = dx / d; p.dy = dy / d

func intercept_point(p: Oy) -> Vector2:
	var b := ball
	if b.owner != null: return Vector2(b.owner.x + b.owner.vx * .25, b.owner.y + b.owner.vy * .25)
	var sp: float = 6.5 * T[p.team].spd
	var bx := b.x; var by := b.y
	var t := 0.0
	while t < 2.5:
		var f := exp(-1.1 * t)
		var px := b.x + b.vx * (1 - f) / 1.1; var py := b.y + b.vy * (1 - f) / 1.1
		bx = px; by = py
		if hyp(px - p.x, py - p.y) <= sp * t + .6: break
		t += .1
	return Vector2(clampf(bx, -1, PW + 1), clampf(by, -1, PL + 1))

func think_gk(p: Oy, dt: float) -> void:
	var b := ball
	var og := own_goal_y(p.team)
	var s := fwd_of(p.team)
	if b.owner == p:
		p.hold += dt; p.mx = 0; p.my = 0
		if p.hold > 1.0:
			var q := gk_pass(p)
			if q != null: do_pass(p, q.x - p.x, q.y - p.y, q)
			else: do_pass(p, 0, s)
		return
	var in_box := absf(b.y - og) < BOXD and b.x > (PW - BOXW) / 2 and b.x < (PW + BOXW) / 2
	if b.owner == null and signf(b.vy) == -s and absf(b.vy) > 6:
		var t := (p.y - b.y) / b.vy
		if t > 0 and t < 1.6:
			var xc := b.x + b.vx * t
			if xc > GX0 - 2.5 and xc < GX1 + 2.5:
				p.hedef = true; p.tx = clampf(xc, GX0 - 1, GX1 + 1); p.ty = p.y; p.run = 1.25; p.dive = 1; return
	p.dive = 0
	var sweep := b.owner == null and not in_box and depth_of(p.team, b.y) < 19 and absf(b.x - PW / 2) < 20
	if b.owner == null and (in_box or sweep):
		var myd := hyp(p.x - b.x, p.y - b.y)
		var od := 99.0
		for q: Oy in P:
			if q.team != p.team: od = minf(od, hyp(q.x - b.x, q.y - b.y))
		if myd < od + (-2.0 if sweep else 1.5) or (not sweep and myd < 4): _hedef(p, intercept_point(p), 1); return
	if b.owner != null and b.owner.team != p.team and in_box and hyp(p.x - b.x, p.y - b.y) < 7: _hedef(p, Vector2(b.x, b.y), .95); return
	var gx := PW / 2
	var dx := b.x - gx; var dy := b.y - og; var d := hyp(dx, dy)
	if d == 0: d = 1
	var out := minf(3.2, d * .12)
	p.hedef = true; p.tx = clampf(gx + dx / d * out, GX0 + .3, GX1 - .3); p.ty = og + dy / d * out
	if absf(p.ty - og) < .6: p.ty = og + s * .6
	p.run = .7

# ---------- eylemler ----------
func release(p: Oy, vx: float, vy: float, vz: float, intended: Oy = null) -> void:
	var b := ball
	if not demo and intended != null and intended.team == p.team: ist.pas[p.team] += 1; oy_k(p).p += 1
	ofsayt_bak(p, intended)
	b.owner = null; b.x = p.x + p.dx * .5; b.y = p.y + p.dy * .5; b.vx = vx; b.vy = vy; b.vz = vz; b.z = maxf(b.z, .05)
	b.last = p; b.last_team = p.team; b.kicker = p; b.intended = intended; b.gk_tried = null; b.cross = false; b.shot = false
	b.atis = set_piece != null and set_piece.get("tac", false) and set_piece.p == p
	p.cd = .35; p.hold = 0; set_piece = null

# ara pas: top alıcının önüne, savunmanın arkasındaki boşluğa yerden atılır
func do_ara_pas(p: Oy, dx: float, dy: float) -> void:
	var q: Oy = best_pass(p, dx, dy, true)
	if q == null: do_pass(p, dx, dy); return
	var f := fwd_of(p.team); var Tt: Dictionary = T[p.team]
	var tx := clampf(q.x + q.vx * .6, 3, PW - 3); var ty := clampf(q.y + f * rnd(6, 9), 2, PL - 2)
	var D := maxf(hyp(tx - p.x, ty - p.y), 1.0); var err: float = (1.0 - Tt.skill) * D * .07
	tx += rnd(-err, err); ty += rnd(-err, err)
	var ux := (tx - p.x) / D; var uy := (ty - p.y) / D; var v := clampf(D * 1.05 + 4, 9, 24)
	p.dx = ux; p.dy = uy; release(p, ux * v, uy * v, 0, q); olay("vurus", .75)

func do_pass(p: Oy, dx: float, dy: float, target: Oy = null) -> void:
	var q: Oy = target if target != null else best_pass(p, dx, dy, true)
	if q == null:
		var n := hyp(dx, dy)
		if n == 0: n = 1
		release(p, dx / n * 14, dy / n * 14, .5); olay("vurus", .6); return
	var d := hyp(q.x - p.x, q.y - p.y)
	var lead := clampf(d / 16, .2, 1.1)
	var tx := q.x + q.vx * lead; var ty := q.y + q.vy * lead
	var D := hyp(tx - p.x, ty - p.y)
	var Tt: Dictionary = T[p.team]
	var odP: float = nearest_opp(p)[1]
	var err: float = (1 - Tt.skill) * D * (.15 if D > 22 else .08) * (1.4 if odP < 2.5 else 1.0)
	tx += rnd(-err, err); ty += rnd(-err, err)
	D = maxf(.01, hyp(tx - p.x, ty - p.y))
	var ux := (tx - p.x) / D; var uy := (ty - p.y) / D
	var v: float; var vz := 0.0
	if D > 22:
		vz = 4.5 + D * .07
		var ta := 2 * vz / 18
		v = D / (ta + .75)
	else: v = clampf(D * 1.1 + 3.5, 8, 25)
	p.dx = ux; p.dy = uy
	release(p, ux * v, uy * v, vz, q); olay("vurus", .7)

func do_shoot(p: Oy, aim_x: float, pow := 1.0) -> void:
	if not demo: ist.sut[p.team] += 1; oy_k(p).s += 1
	var gy := goal_y_of(p.team)
	var f := fwd_of(p.team)
	var Tt: Dictionary = T[p.team]
	var dG := hyp(PW / 2 - p.x, gy - p.y)
	if dG > 36:
		var q := best_pass(p, 0, f, true)
		if q != null and randf() < .6: do_pass(p, q.x - p.x, q.y - p.y, q); return
		release(p, rnd(-3, 3), f * 22, 7); olay("vurus", .9); return
	var human: bool = Tt.human and p == ctrl
	var ax := PW / 2 + (aim_x * 2.9 if human else rnd(-2.6, 2.6))
	var gk: Oy = null
	for q: Oy in P:
		if q.team != p.team and q.role == "G": gk = q; break
	if not human and gk != null: ax = PW / 2 - rnd(1.4, 3.1) if gk.x > PW / 2 else PW / 2 + rnd(1.4, 3.1)
	var acc: float = Tt.skill * (1.02 if human else 1.0)
	var odS: float = nearest_opp(p)[1]
	var press := 1.35 if odS < 2.5 else 1.0
	var err := (1.15 - acc) * (1.2 + dG * .13) * press
	ax += rnd(-err, err) + (rnd(-1, 1) * rnd(2.5, 5) if randf() < .12 + (1 - acc) * .3 else 0.0)
	var tz := rnd(2.6, 3.6) if randf() < .1 + dG * .006 else rnd(.2, 2.2)
	if human and pow > 1.1 and randf() < (pow - 1.1) * 2.5: tz = rnd(GH + .4, GH + 1.6)   # fazla güç: üstten auta gidebilir
	var dx := ax - p.x; var dy := gy - p.y; var d := hyp(dx, dy)
	var v: float = (22 + Tt.str * .5) * pow
	var t := d / v
	var vz := (tz + 9 * t * t) / t
	p.dx = dx / d; p.dy = dy / d
	release(p, dx / d * v, dy / d * v, clampf(vz, 1, 8))
	ball.shot = true; ball.shot_team = p.team; ball.shot_t = 0; olay("vurus", 1.2)

func do_slide(p: Oy, dx: float, dy: float) -> void:
	var n := hyp(dx, dy)
	if n == 0: n = 1
	p.dx = dx / n; p.dy = dy / n; p.slide = .42; p.scd = 1.1; p.vx = p.dx * 10.5; p.vy = p.dy * 10.5
	olay("kayma")

# ---------- hareket ----------
func move_player(p: Oy, dt: float) -> void:
	var Tt: Dictionary = T[p.team]
	var vx: float; var vy: float
	if p.slide > 0:
		p.slide -= dt; p.vx *= pow(.15, dt); p.vy *= pow(.15, dt); vx = p.vx; vy = p.vy
		var b := ball
		var d := hyp(b.x - p.x, b.y - p.y)
		if d < 1.45 and b.z < 1 and b.owner != p and not (duran_top_bekliyor() and b.owner.team != p.team):
			if b.owner != null and b.owner.team != p.team and kayma_faul(p, b.owner):
				p.slide = 0; return
			if b.owner != null and b.owner.team != p.team:
				var o := b.owner
				o.stun = .8; o.cd = .9; b.owner = null
			if b.owner == null:
				var hum := not demo and p == ctrl
				if hum: take(p); p.won = true; olay("vurus", .5)
				else:
					b.vx = p.dx * 7 + rnd(-3, 3); b.vy = p.dy * 7 + rnd(-3, 3); b.vz = .8; b.last_team = p.team; b.last = p; b.intended = null; b.shot = false
					olay("vurus", .5)
		if p.slide <= 0:
			p.stun = 0.0 if ball.owner == p else .35; p.won = false
	elif p.stun > 0:
		vx = p.vx * .8; vy = p.vy * .8
	else:
		var hum := not demo and p == ctrl
		var ucuyor := p.ucus > .65          # uçan kaleci yerden kalkana kadar koşamaz
		var top: float = (0.0 if ucuyor else 6.6) * (Tt.spd + ozl(p, "spd", 0)) * (1.1 if hum else (.9 if ball.owner == p else 1.0)) * (1.15 if (p.role == "G" and p.dive) else 1.0) * (.72 + .28 * p.st) * (.6 if p.inj else 1.0)
		var mx := 0.0; var my := 0.0; var sp := 0.0
		if p.hedef:
			var dx := p.tx - p.x; var dy := p.ty - p.y; var d := hyp(dx, dy)
			if d > .35: mx = dx / d; my = dy / d; sp = top * p.run * minf(1, d / 1.5)
		elif p.mx != 0 or p.my != 0:
			mx = p.mx; my = p.my; sp = top * (p.run if p.run != 0 else 1.0) * minf(1, hyp(p.mx, p.my) * 1.15)
		var tvx := mx * sp; var tvy := my * sp
		var k := minf(1, dt * (7.0 if ball.owner == p else 9.0))
		p.vx += (tvx - p.vx) * k; p.vy += (tvy - p.vy) * k; vx = p.vx; vy = p.vy
		var s := hyp(vx, vy)
		if s > .5: p.dx = vx / s; p.dy = vy / s
	p.x += vx * dt; p.y += vy * dt
	p.x = clampf(p.x, -3, PW + 3); p.y = clampf(p.y, -3, PL + 3)
	if p.role == "G":
		var og := own_goal_y(p.team)
		if og == PL: p.y = maxf(p.y, PL - BOXD - 2)
		else: p.y = minf(p.y, BOXD + 2)
	p.anim += hyp(vx, vy) * dt

func separate() -> void:
	var n := P.size()
	for i in n:
		for j in range(i + 1, n):
			var a: Oy = P[i]; var b: Oy = P[j]
			var dx := b.x - a.x; var dy := b.y - a.y; var d := hyp(dx, dy)
			if d > 0 and d < .9:
				var o := (.9 - d) / 2; var ux := dx / d; var uy := dy / d
				if a.slide <= 0: a.x -= ux * o; a.y -= uy * o
				if b.slide <= 0: b.x += ux * o; b.y += uy * o

# ---------- top ----------
func ball_step(dt: float) -> void:
	if state != "play": return   # aynı adımda duran top verildiyse top yerinde kalır
	var b := ball
	if b.owner != null:
		var p := b.owner
		var ph := p.anim * 1.6
		var off := .62 + sin(ph) * .12
		b.x = p.x + p.dx * off; b.y = p.y + p.dy * off; b.z = 0; b.vx = p.vx; b.vy = p.vy; b.vz = 0; b.last_team = p.team; b.last = p
		if set_piece == null and p.role != "G" and (b.x < -.15 or b.x > PW + .15 or b.y < -.15 or b.y > PL + .15):
			b.owner = null; b.kicker = p
			if out_of_play(b): return
		for q: Oy in P:
			if q.team == p.team or q.stun > 0 or q.slide > 0 or q.cd > 0: continue
			if duran_top_bekliyor(): continue
			var d := hyp(q.x - b.x, q.y - b.y)
			if d < .85:
				var Tq: Dictionary = T[q.team]; var Tp: Dictionary = T[p.team]
				if Tp.human and p == ctrl and p.hold < .6: continue
				var rate: float = (1.1 + Tq.skill - Tp.skill * .6) * ((2.6 if q == ctrl else 1.25) if Tq.human else 1.0) * (DIFF.steal[diff] if (Tp.human and p == ctrl) else 1.0)
				if p.role == "G" and not p.ayak: rate *= .2
				rate *= (1 - ozl(p, "hold", 0)) * (1 + ozl(q, "tackle", 0))
				if not (Tp.human and p == ctrl): rate *= .55
				if randf() < rate * dt * 2.2:
					if mudahale_faul(q, p): return
					b.owner = q; q.hold = 0; p.cd = .7; p.stun = .25; b.intended = null; set_piece = null; olay("vurus", .4); break
		return
	b.x += b.vx * dt; b.y += b.vy * dt
	if b.z > 0 or b.vz > 0:
		b.vz -= 18 * dt; b.z += b.vz * dt
		var dr := pow(.88, dt)
		b.vx *= dr; b.vy *= dr
		if b.z <= 0:
			b.z = 0
			if b.vz < -2.5: b.vz = -b.vz * .42; olay("sekme")
			else: b.vz = 0
	else:
		var f := exp(-1.15 * dt)
		b.vx *= f; b.vy *= f
	if b.shot: b.shot_t += dt
	if hyp(b.vx, b.vy) < .6 and b.z == 0: b.vx = 0; b.vy = 0
	for g: Oy in P:
		if g.role != "G" or g.cd > 0: continue
		var d := hyp(g.x - b.x, g.y - b.y)
		var reach := 1.25 + (.9 if g.dive else 0.0)
		if d < reach and b.z < 2.7:
			if b.gk_tried == g: continue
			b.gk_tried = g
			var towards := b.vy > 0 if own_goal_y(g.team) == PL else b.vy < 0
			var sp := hyp(b.vx, b.vy)
			if not towards or sp < 9: take(g); return
			var ly := own_goal_y(g.team)
			if b.vy != 0:
				var tt := (ly - b.y) / b.vy
				if tt > 0 and tt < 2:
					var xc := b.x + b.vx * tt; var zc := b.z + b.vz * tt - 9 * tt * tt
					if (xc < GX0 - .35 or xc > GX1 + .35 or zc > GH + .25) and d > .6: continue
			var Tg: Dictionary = T[g.team]
			var ps: float = .56 + Tg.skill * .36 - (sp - 20) * .011 - (.1 if b.z > 1.9 else 0.0) + (.18 if d < .8 else 0.0)
			if Tg.human: ps += [.14, .07, .02][diff]
			if not Tg.human and T[1 - g.team].human: ps += DIFF.gk[diff]
			g.dive = 2  # görüntü: uçuş
			kaleci_uc(g, b, ly)
			if randf() < ps:
				if b.shot and not demo:
					ist.kurtar[g.team] += 1; ist.isabet[1 - g.team] += 1; oy_k(g).k += 1
					if b.kicker != null and b.kicker.team != g.team: oy_k(b.kicker).i += 1
				if sp < 21 and randf() < .55: take(g); olay("ooo")
				elif randf() < .45:
					var sx := -1.0 if b.x < PW / 2 else 1.0
					b.vx = sx * rnd(7, 11); b.vy = b.vy * .35; b.vz = rnd(1.5, 3); b.shot = false; b.last_team = g.team; b.last = g; b.intended = null; olay("vurus", .6); olay("ooo")
				else:
					b.vx = -b.vx * .25 + rnd(-6, 6); b.vy = -b.vy * .35; b.vz = 2.5; b.shot = false; b.last_team = g.team; b.last = g; b.intended = null; olay("vurus", .6); olay("ooo")
				g.cd = .4; return
			else: g.cd = .6
	if out_of_play(b): return
	var best: Oy = null
	var bd := 1e9
	for p: Oy in P:
		if p.cd > 0 or p.stun > 0 or p.role == "G": continue
		var d := hyp(p.x - b.x, p.y - b.y)
		if d < (1.2 if b.cross else .95) and b.z < (2.5 + ozl(p, "head", 0) * 2 if b.cross else 1.3) and d < bd:
			var sp := hyp(b.vx, b.vy)
			if sp > 17 and p != b.intended and randf() > .12: continue
			var k := b.kicker
			if k != null and p.team != k.team and sp > 7 and hyp(b.x - k.x, b.y - k.y) < 2.4 and randf() > .035: continue
			bd = d; best = p
	if best != null: take(best)

func out_of_play(b: Top) -> bool:
	if b.y < 0 or b.y > PL:
		var ti := 0 if goal_y_of(0) == (0.0 if b.y < 0 else PL) else 1
		if b.x > GX0 and b.x < GX1 and b.z < GH and b.atis and b.last == b.kicker:
			# taçtan doğrudan gol olmaz
			b.atis = false
			if b.kicker != null and b.kicker.team == ti: goal_kick(1 - ti)
			else: corner_kick(ti, 0.0 if b.x < PW / 2 else PW)
			return true
		if b.x > GX0 and b.x < GX1 and b.z < GH:
			var k := b.kicker
			score_goal(ti, k if (k != null and k.team == ti) else null, k if (k != null and k.team != ti) else null)
			return true
		if b.last_team == ti: goal_kick(1 - ti)
		else: corner_kick(ti, 0.0 if b.x < PW / 2 else PW)
		return true
	if b.x < 0 or b.x > PW:
		throw_in(1 - b.last_team, clampf(b.x, 0, PW), clampf(b.y, 1, PL - 1)); return true
	return false

func take(p: Oy) -> void:
	var b := ball
	if not demo and b.last != null and b.last != p and b.last.team == p.team and b.intended != null:
		ist.pas_ok[p.team] += 1; oy_k(b.last).pk += 1; asist_aday = [b.last, p, clock]
	elif b.last != null and b.last.team != p.team: asist_aday = null
	p.ayak = p.role == "G" and b.last_team == p.team and b.kicker != null and b.kicker != p and b.kicker.team == p.team and not b.cross   # geri pas
	if b.ofs != null and not b.ofs.get("yakin", false) and b.ofs.q == p and p.team == b.ofs.team and not demo:
		ofsayt_cal(p); return
	if b.ofs != null and b.ofs.get("yakin", false) and b.ofs.q == p: yakin_ofs = {"team": p.team, "t": clock}
	b.ofs = null
	if b.cross and p.role != "G": p.first_time = true
	b.cross = false; b.owner = p; p.hold = 0; b.intended = null; b.shot = false; b.vx = 0; b.vy = 0; b.vz = 0; b.z = 0
	b.last_team = p.team; b.last = p; p.dec = rnd(.15, .35)

# duran top kuralı: santra, taç, korner, aut, serbest vuruş ve penaltıda top oyuna girene (kullanan oyuncu
# topa vurana) kadar rakip 9,15 m uzakta durur, topa müdahale edemez; santrada rakip kendi yarı sahasında kalır.
const DURAN_MESAFE := 9.15
func duran_top_bekliyor() -> bool:
	return set_piece != null and ball.owner != null and ball.owner == set_piece.p

func mesafe_kurali() -> void:
	if not duran_top_bekliyor(): return
	var b := ball
	var ti: int = set_piece.p.team
	var ko: bool = set_piece.get("ko", false)
	var bj: Array = set_piece.get("baraj", [])
	var bj_oy := []
	for e in bj:
		var q: Oy = e[0]; bj_oy.append(q)
		q.x = e[1]; q.y = e[2]; q.vx = 0; q.vy = 0; q.dx = e[3]; q.dy = e[4]; q.slide = 0
		var ex: float = q.x - b.x; var ey: float = q.y - b.y; var ed := maxf(hyp(ex, ey), .001)
		if ed < DURAN_MESAFE: q.x = b.x + ex / ed * DURAN_MESAFE; q.y = b.y + ey / ed * DURAN_MESAFE
	for q: Oy in P:
		if q.team == ti or bj_oy.has(q): continue
		q.slide = 0
		if ko:
			# santra: rakip kendi yarısında
			if fwd_of(q.team) == -1.0: q.y = maxf(q.y, PL / 2 + .3)
			else: q.y = minf(q.y, PL / 2 - .3)
		var dx := q.x - b.x; var dy := q.y - b.y; var d := hyp(dx, dy)
		if d < DURAN_MESAFE:
			if d < .01:
				dx = 0.0; dy = -fwd_of(ti); d = 1.0
			if set_piece.get("pen", false): continue   # penaltıda kaleci çizgide kalır, diğerleri ceza sahası dışına zaten dizilir
			# çember üzerinde en yakın saha içi nokta (köşe/çizgi kenarında kayar)
			var a0 := atan2(dy, dx)
			for k in 24:
				var a := a0 + (1.0 if k % 2 == 1 else -1.0) * ceili(k / 2.0) * PI / 12.0
				var nx := b.x + cos(a) * DURAN_MESAFE; var ny := b.y + sin(a) * DURAN_MESAFE
				if nx < .5 or nx > PW - .5 or ny < .5 or ny > PL - .5: continue
				if ko and (ny < PL / 2 if fwd_of(q.team) == -1.0 else ny > PL / 2): continue
				q.x = nx; q.y = ny; break
			q.vx *= .3; q.vy *= .3

# baraj: kaleye yakın serbest vuruşta savunma, topla kale ortası arasına 9,15 m'de 2–4 kişilik duvar kurar
func baraj(ti: int) -> void:
	var b := ball
	var dx := PW / 2 - b.x; var dy := goal_y_of(ti) - b.y; var d := hyp(dx, dy)
	if d > 32 or d < 11: return
	var n := 4 if d < 20 else (3 if d < 26 else 2)
	var ux := dx / d; var uy := dy / d
	var cx := b.x + ux * DURAN_MESAFE; var cy := b.y + uy * DURAN_MESAFE
	var ad := []
	for q: Oy in P:
		if q.team != ti and q.role != "G": ad.append(q)
	ad.sort_custom(func(a: Oy, c: Oy): return hyp(a.x - cx, a.y - cy) < hyp(c.x - cx, c.y - cy))
	var liste := []
	for i in mini(n, ad.size()):
		var o := (i - (n - 1) / 2.0) * .75
		liste.append([ad[i], cx - uy * o, cy + ux * o, -ux, -uy])
	set_piece.baraj = liste
	mesafe_kurali()

func restart(ti: int, x: float, y: float, pick_role := "") -> void:
	var b := ball
	b.vx = 0; b.vy = 0; b.vz = 0; b.z = 0; b.x = x; b.y = y; b.shot = false; b.intended = null
	var p: Oy = null
	if pick_role == "G":
		for q: Oy in P:
			if q.team == ti and q.role == "G": p = q; break
	else:
		var bd := 1e9
		for q: Oy in P:
			if q.team == ti and q.role != "G":
				var d := hyp(q.x - x, q.y - y)
				if d < bd: bd = d; p = q
	var hx := x + (-.4 if x <= 0 else (.4 if x >= PW else 0.0))
	var hy := y + (-.4 if y <= 0 else (.4 if y >= PL else 0.0))
	p.vx = 0; p.vy = 0
	for q: Oy in P:
		if q.team == ti: continue
		var d := hyp(q.x - x, q.y - y)
		if d < 5:
			var dd := d if d != 0 else 1.0
			q.x = clampf(x + (q.x - x) / dd * 5, .5, PW - .5); q.y = clampf(y + (q.y - y) / dd * 5, .5, PL - .5)
	var cx := PW / 2
	var cy := maxf(y, 10) if y < PL / 2 else minf(y, PL - 10)
	var dx := cx - hx; var dy := cy - hy; var d := hyp(dx, dy)
	if d == 0: d = 1
	b.owner = p; p.hold = 0; p.cd = 0; b.last_team = ti
	set_piece = {"p": p, "t": 0.0, "yol": {"tx": hx, "ty": hy, "fx": dx / d, "fy": dy / d, "bekle": 0.0}}
	if p.team == 0 and not demo: ctrl = p
	state = "pre"; state_t = .55
	mesafe_kurali()

func throw_in(ti: int, x: float, y: float) -> void:
	durdu = 2 if absf(y - goal_y_of(ti)) < 25 else 1
	restart(ti, 0.0 if x <= 0 else PW, y); set_piece.tac = true; olay("duduk", 1); olay("flash", "TAÇ")

func corner_kick(ti: int, x: float) -> void:
	durdu = 2; korner[ti] += 1
	var y := goal_y_of(ti)
	restart(ti, .3 if x <= 0 else PW - .3, .3 if y == 0 else PL - .3); olay("duduk", 1); olay("flash", "KORNER"); olay("taraftar", ti, "alkis")

func goal_kick(ti: int) -> void:
	durdu = 1
	var y := PL - 5.5 if own_goal_y(ti) == PL else 5.5
	restart(ti, PW / 2 + rnd(-4, 4), y, "G"); set_piece.aut = true; olay("duduk", 1); olay("flash", "AUT")

func score_goal(ti: int, scorer: Oy, own: Oy) -> void:
	var Tt: Dictionary = T[ti]
	Tt.score += 1
	var who := scorer
	if who == null and own == null:
		var sq: Array = P.filter(func(p): return p.team == ti and (p.role == "F" or p.role == "O"))
		who = sq[randi() % sq.size()]
	var name: String = who.n if who != null else "Kendi kalesine (" + own.n + ")"
	var asist = null
	if who != null and own == null and asist_aday != null and asist_aday[1] == who and asist_aday[0].team == ti and clock - float(asist_aday[2]) < 14.0: asist = asist_aday[0]
	asist_aday = null
	if not demo:
		if own == null:
			ist.isabet[ti] += 1
			if who != null: oy_k(who).g += 1; oy_k(who).i += 1
		if asist != null: oy_k(asist).a += 1
	events.append({"min": maxi(1, minute()), "n": name, "team": ti, "as": asist.n if asist != null else ""})
	gol_atan = who if (who != null and P.has(who)) else null
	if gol_atan != null:
		var gy := goal_y_of(ti)
		kutlama_yer = Vector2(1.5 if gol_atan.x < PW / 2 else PW - 1.5, 2.0 if gy == 0 else PL - 2.0)
	state = "goal"; state_t = 3.2
	olay("gol", ti)
	olay("banner", "GOOOL!", (str(who.no) + " · " if who != null else "") + name + " · " + Tt.t.kisa + " " + str(T[0].score) + "-" + str(T[1].score))
	ball.vx *= .2; ball.vy *= .2
	after = func(): var_gol(ti)

func _gol_devam(ti: int) -> void:
	kickoff(1 - ti); state = "pre"; state_t = .8; olay("duduk", 1)

func son_gol_takimi() -> int:
	return events[events.size() - 1].team if (state == "goal" and events.size() > 0) else -1

# =================== Kurallar: faul, kart, penaltı, ofsayt (Kaptan Mecit motorundan taşındı) ===================
func kutuda_mi(ti: int, x: float, y: float) -> bool:
	return absf(y - goal_y_of(ti)) < BOXD and x > (PW - BOXW) / 2 and x < (PW + BOXW) / 2

# kayarak müdahale: arkadan ya da topa değmeden gelirse faul
func kayma_faul(p: Oy, o: Oy) -> bool:
	if demo: return false
	var d := maxf(hyp(o.x - p.x, o.y - p.y), .01)
	var arkadan := (o.dx * (o.x - p.x) + o.dy * (o.y - p.y)) / d > .35
	var top_yakin := hyp(ball.x - p.x, ball.y - p.y) < d - .1
	var f := (.1 if top_yakin else .3) + (.35 if arkadan else 0.0) + (-.08 if p.sari else 0.0)
	if randf() > f: return false
	faul_yap(p, o, arkadan, true); return true

# omuz / çekme: top kapma denemelerinin küçük bir kısmı faul
func mudahale_faul(q: Oy, p: Oy) -> bool:
	if demo: return false
	if randf() > (.05 if q.sari else .11): return false
	faul_yap(q, p, false, false); return true

func faul_yap(o: Oy, p: Oy, arkadan: bool, kayma: bool) -> void:
	var ti := p.team
	var b := ball
	faul[o.team] += 1
	oy_k(o).f += 1
	var kutu := kutuda_mi(ti, p.x, p.y)
	var dg := absf(goal_y_of(ti) - p.y)
	var onunde := 0
	for q: Oy in P:
		if q.team != ti and q != o and q.role != "G" and absf(goal_y_of(ti) - q.y) < dg: onunde += 1
	var son_adam := dg < 28 and onunde == 0 and absf(p.x - PW / 2) < 16 and b.owner == p and absf(p.vy) > 3
	var sari := (.05 + (.13 if arkadan else 0.0) + (.05 if kayma else 0.0) + (.2 if kutu else 0.0)) * (.35 if o.sari else 1.0)
	var kirmizi := .0015 + (.006 if (arkadan and kayma) else 0.0) + ((.04 if kutu else .14) if son_adam else 0.0)
	var kart_ver := func():
		var r := randf()
		if r < kirmizi: kart(o, "K", "NET GOL FIRSATI" if son_adam else "SERT MÜDAHALE")
		elif r < kirmizi + sari: kart(o, "S")
	# avantaj: hücum sürer, faulcü bir an oyun dışı
	if not kutu and dg < 55 and b.owner == p and randf() < .3:
		o.cd = 1.2; o.stun = .5; o.slide = 0; olay("flash", "AVANTAJ"); kart_ver.call(); return
	p.stun = .5; o.cd = .6; b.owner = null; b.vx = 0; b.vy = 0; b.vz = 0
	if kutu:
		olay("duduk", 1); kart_ver.call(); olay("taraftar", 1 - ti, "islik"); penalti_ver(ti); return
	olay("duduk", 1); kart_ver.call(); olay("taraftar", ti, "islik")
	if not atilan.has(p):
		restart(ti, clampf(p.x, 1, PW - 1), clampf(p.y, 1, PL - 1))
		set_piece.fk = true; durdu = 2 if dg < 38 else 1
		baraj(ti)
		olay("banner", "FAUL", o.n + " · " + T[ti].t.kisa + " serbest vuruş")

func penalti_ver(ti: int, incelendi := false) -> void:
	# VAR: temas yeterli mi?
	if not incelendi and not demo and randf() < .18:
		state = "var"; state_t = 3.2
		olay("banner", "VAR", "PENALTI KARARI İNCELENİYOR…")
		var iptal := randf() < .35
		after = func():
			if iptal:
				olay("banner", "VAR", "TEMAS YETERSİZ · PENALTI İPTAL"); olay("taraftar", ti, "yuh"); goal_kick(1 - ti)
			else:
				olay("banner", "VAR", "PENALTI KARARI GEÇERLİ"); penalti_ver(ti, true)
		return
	var gy := goal_y_of(ti)
	restart(ti, PW / 2, 11.0 if gy == 0 else PL - 11)
	var at: Oy = set_piece.p
	set_piece.pen = true; durdu = 2
	for q: Oy in P:
		if q == at: continue
		if q.role == "G" and q.team != ti:
			q.x = PW / 2; q.y = .4 if gy == 0 else PL - .4; continue
		if absf(q.y - gy) < BOXD + 1.5:
			q.y = (BOXD + rnd(1.8, 6)) if gy == 0 else (PL - BOXD - rnd(1.8, 6)); q.x = clampf(q.x, 6, PW - 6)
	state = "pre"; state_t = 1.4
	olay("banner", "PENALTI", at.n + " topun başında"); olay("taraftar", ti, "alkis")

func kart(o: Oy, renk: String, neden := "") -> void:
	if atilan.has(o): return
	if renk == "S" and o.sari:
		kartlar.append([o.team, o.n, "S"]); renk = "K2"
	if renk == "S":
		o.sari = true; kartlar.append([o.team, o.n, "S"]); olay("taraftar", o.team, "islik")
		olay("kart", "S", "%d %s · %s" % [o.no, o.n, T[o.team].t.kisa]); return
	kartlar.append([o.team, o.n, "K"])
	olay("duduk", 2); olay("taraftar", o.team, "yuh")
	olay("kart", renk, "%d %s · %s · 10 KİŞİ%s" % [o.no, o.n, T[o.team].t.kisa, (" · " + neden) if neden != "" else ""])
	oyundan_at(o)

func oyundan_at(p: Oy) -> void:
	var i := P.find(p)
	if i < 0: return
	P.remove_at(i); atilan.append(p)
	olay("atildi", p)
	if ball.owner == p: ball.owner = null
	if ctrl == p: ctrl = null
	if set_piece != null and set_piece.p == p: set_piece = null
	if p.role == "G":
		# kaleci atıldı: bir saha oyuncusu eldiveni giyer (önce forvet değil, en yorgun)
		var aday: Oy = null
		for q: Oy in P:
			if q.team == p.team and q.role != "G" and (aday == null or (aday.role == "F" and q.role != "F")): aday = q
		if aday != null:
			aday.role = "G"; aday.pos = "GK"; aday.fx = .5; aday.fy = .02; aday.dz = false
			olay("kaleci_degisti", aday)
	TP = null

# ofsayt: pas anında alıcı, toptan ve sondan ikinci rakipten daha ilerideyse (rakip yarı sahada). Dönüş: çizgiyi kaç metre geçtiği
func ofsayt_mi(p: Oy, q: Oy) -> float:
	if q == null or q.team != p.team: return -9.0
	var ti := p.team
	var dq := depth_of(ti, q.y)
	if dq <= PL / 2: return -9.0
	var rk: Array = []
	for o: Oy in P:
		if o.team != ti: rk.append(depth_of(ti, o.y))
	rk.sort(); rk.reverse()
	var ikinci: float = rk[1] if rk.size() > 1 else PL / 2
	var cz := maxf(maxf(ikinci, depth_of(ti, ball.y)), PL / 2)
	return dq - cz

func ofsayt_bak(p: Oy, q: Oy) -> void:
	var b := ball
	b.ofs = null
	if demo or q == null or q.team != p.team: return
	if set_piece != null and set_piece.p == p and (is_corner(p) or set_piece.get("ko", false) or set_piece.get("tac", false) or set_piece.get("aut", false)): return   # kornerde, santrada, taçta, autta ofsayt yok
	var g := ofsayt_mi(p, q)
	var f := fwd_of(p.team)
	if g > .3: b.ofs = {"q": q, "team": p.team}
	elif g > -3.5 and q.vy * f > 2.2 and depth_of(p.team, q.y) > depth_of(p.team, p.y) + 3 and randf() < .3: b.ofs = {"q": q, "team": p.team}
	elif g > -.8: b.ofs = {"q": q, "team": p.team, "yakin": true}

func ofsayt_cal(p: Oy) -> void:
	ball.ofs = null; ofsayt[p.team] += 1
	olay("duduk", 1); olay("taraftar", p.team, "islik"); olay("banner", "OFSAYT", "%d %s · %s" % [p.no, p.n, T[p.team].t.kisa])
	restart(1 - p.team, clampf(p.x, 1, PW - 1), clampf(p.y, 1, PL - 1)); durdu = 1

# =================== Kondisyon, sakatlık, oyuncu değişikliği, VAR (Kaptan Mecit / CBM'den) ===================
# kondisyon: koştukça düşer (≈90 dakikada %20–25), düşük kondisyon hızı keser; sakatlık riski yorgunlukla artar
func kondisyon(dt: float) -> void:
	if demo: return
	var gm := dt / dur * 90.0
	for p: Oy in P:
		var v := hyp(p.vx, p.vy)
		p.st = maxf(.3, p.st - gm * (.0016 + .0013 * minf(1.3, v / 6.6)) * (.35 if p.role == "G" else 1.0))
		if not p.inj and p.role != "G" and randf() < gm * .00009 * (1.6 - p.st): sakatlan(p)

func sakatlan(p: Oy) -> void:
	if p.inj or demo: return
	p.inj = true; p.st = minf(p.st, .4)
	var ti := p.team
	if degisebilir(ti):
		var b = yedek_sec(ti, p.role, false, [])
		if b == null: b = yedek_sec(ti, "O", false, [])
		if b != null: degistir(ti, p, b, "SAKATLIK"); return
	olay("banner", "SAKATLIK", p.n + " · " + T[ti].t.kisa)

func molada() -> bool: return state == "half"
func kalan(ti: int) -> Dictionary: return {"hak": hak.n - sub[ti].n, "ara": hak.w - sub[ti].win.size()}
func degisebilir(ti: int) -> bool:
	var d: Dictionary = sub[ti]
	return state != "over" and d.n < hak.n and (d.win.size() < hak.w or d.win.has(minute()) or molada()) and B[ti].size() > 0

func degistir(ti: int, p: Oy, b: Dictionary, neden: String) -> bool:
	if not degisebilir(ti) or p == null or p.team != ti or not B[ti].has(b): return false
	var d: Dictionary = sub[ti]
	if not molada(): d.win[minute()] = true
	d.n += 1
	degisiklikler.append({"team": ti, "min": maxi(1, minute()), "out": p.n, "in": b.n})
	if ball.owner == p: ball.owner = null
	var eski := p.n
	p.n = b.n; p.no = int(b.no); p.ten = b.ten; p.sac = b.sac; p.st = 1.0; p.inj = false; p.stun = 0; p.slide = 0
	oy_k(p).gir = maxi(1, minute())
	B[ti].erase(b)
	olay("degisiklik", p)
	if state != "half": olay("banner", "DEĞİŞİKLİK", "%s · %d %s ↔ %s%s" % [T[ti].t.kisa, int(b.no), b.n, eski, (" · " + neden) if neden != "" else ""])
	return true

func yedek_sec(ti: int, istenen: String, kaleci: bool, plan: Array):
	var aday: Array = B[ti].filter(func(b): return (b.mevki == "G") == kaleci and not plan.any(func(x): return x.b == b))
	if aday.is_empty(): return null
	aday.sort_custom(func(a, b): return int(a.mevki == istenen) > int(b.mevki == istenen))
	return aday[0]

func plan_kur(ti: int, kac: int) -> Array:
	var m := minute()
	var f: int = T[ti].score - T[1 - ti].score
	var son := m >= 82
	var on: Array = P.filter(func(p): return p.team == ti and p.role != "G" and not p.inj)
	var used := {}
	var out: Array = []
	for k in kac:
		var c: Array = on.filter(func(p): return not used.has(p))
		c.sort_custom(func(a, b): return a.st < b.st)
		if c.is_empty(): break
		var p: Oy = null; var istenen := ""; var neden := ""
		if f < 0 and m >= 60:
			var dler := on.filter(func(x): return x.role == "D" and not used.has(x))
			p = c[0]
			if dler.size() > 3:
				for q in c:
					if q.role == "D": p = q; break
			istenen = "F"; neden = "SKOR İÇİN HÜCUM"
		elif f > 0 and son:
			p = c[0]
			for q in c:
				if q.role == "F" and q.st < .9: p = q; break
			istenen = "D" if p.role == "F" else p.role; neden = "SKORU KORUMAK"
		else:
			p = c[0]
			if p.st >= (.84 if m >= 75 else .8): break
			istenen = p.role; neden = "YORGUNLUK %" + str(int(p.st * 100))
		var b = yedek_sec(ti, istenen, false, out)
		if b == null: break
		used[p] = true; out.append({"p": p, "b": b, "neden": neden})
	return out

# iki takımın da asistanı değişiklik yapar (insan takımında da: VR'da kulübe ekranı yok)
func oto_degisiklik() -> void:
	if demo: return
	var m := minute()
	var E := [58, 66, 74, 81, 86]
	for ti in 2:
		for p: Oy in P:
			if p.team == ti and p.inj and degisebilir(ti):
				var b = yedek_sec(ti, "G" if p.role == "G" else p.role, p.role == "G", [])
				if b == null: b = yedek_sec(ti, "O", false, [])
				if b != null: degistir(ti, p, b, "SAKATLIK")
				break
	for ti in 2:
		if not asistan[ti]: continue
		var e := -1
		for x in E:
			if m >= x and oto_t[ti] < x: e = x; break
		if e < 0: continue
		if ball.owner != null and ball.owner.team != ti and absf(ball.y - goal_y_of(ball.owner.team)) < PL * .35: continue   # tehlikede değişiklik yok
		oto_t[ti] = e
		if not degisebilir(ti): continue
		var k := kalan(ti)
		var sakla := 0 if m >= 84 else 1
		var kac := maxi(0, mini(mini(k.hak - sakla, (k.hak - sakla) if k.ara <= 1 else (2 if e == 58 else 1)), 3))
		for x in plan_kur(ti, kac): degistir(ti, x.p, x.b, x.neden)

func mola(kac: int) -> void:
	if demo: return
	for ti in 2:
		if not asistan[ti] or not degisebilir(ti): continue
		var k := kalan(ti)
		for x in plan_kur(ti, mini(kac, k.hak - 1)): degistir(ti, x.p, x.b, x.neden)

# VAR: gol öncesi çizgide kalan ofsayt ya da atak başlangıcı incelenir
func var_gol(ti: int) -> void:
	var cizgide: bool = yakin_ofs != null and yakin_ofs.team == ti and clock - yakin_ofs.t < 9
	yakin_ofs = null
	if demo or not (randf() < .9 if cizgide else randf() < .06):
		_gol_devam(ti); return
	var iptal := randf() < (.5 if cizgide else .3)
	state = "var"; state_t = 3.4
	olay("banner", "VAR", "OFSAYT ÇİZGİSİ ÇEKİLİYOR…" if cizgide else "ATAĞIN BAŞLANGICI İZLENİYOR…")
	after = func():
		if not iptal:
			olay("banner", "VAR", "GOL GEÇERLİ"); _gol_devam(ti); return
		T[ti].score -= 1
		for i in range(events.size() - 1, -1, -1):
			if events[i].team == ti: events.remove_at(i); break
		olay("gol_iptal", ti)
		olay("banner", "VAR", "GOL İPTAL · %s · %d-%d" % ["OFSAYT" if cizgide else "ATAKTA FAUL", T[0].score, T[1].score])
		var og := own_goal_y(1 - ti)
		restart(1 - ti, PW / 2, 14.0 if og == 0 else PL - 14)

# gol sevinci: golcü köşe bayrağına koşar, takım arkadaşları ona doğru koşup etrafında toplanır; rakipler başları önde yerlerine yürür
func _kos(p: Oy, hedef: Vector2, hiz: float, dt: float, dur := .4) -> void:
	var dx := hedef.x - p.x; var dy := hedef.y - p.y; var d := hyp(dx, dy)
	if d > dur:
		var v := minf(hiz, 1.2 + d * 1.4)
		p.vx = dx / d * v; p.vy = dy / d * v; p.dx = dx / d; p.dy = dy / d
	else:
		p.vx *= .8; p.vy *= .8
	p.x += p.vx * dt; p.y += p.vy * dt; p.anim += hyp(p.vx, p.vy) * dt

func gol_kutlama(dt: float) -> void:
	var g := gol_atan
	var ti := g.team
	_kos(g, kutlama_yer, 6.8, dt, .6)
	var i := 0
	for p: Oy in P:
		if p == g: continue
		if p.team == ti and p.role != "G":
			# golcünün çevresinde bir halka: herkes kendi açısında 1.3 m ötede durur
			var a := float(i) * 1.1
			i += 1
			if hyp(p.x - g.x, p.y - g.y) < 32:
				_kos(p, Vector2(g.x + cos(a) * 1.3, g.y + sin(a) * 1.3), 6.2, dt, .5)
				continue
		var h := form_target(p)
		_kos(p, h, 1.6 if p.team != ti else 2.4, dt, .5)


# ---------- maç raporu ----------
func rapor() -> Dictionary:
	var sc := [int(T[0].score), int(T[1].score)]
	var kk := {}
	for k in kartlar: kk[str(k[0]) + ":" + str(k[1])] = kk.get(str(k[0]) + ":" + str(k[1]), "") + str(k[2])
	var r := RandomNumberGenerator.new(); r.seed = hash(str(T[0].t.id) + str(T[1].t.id) + str(sc) + str(int(clock)))
	var liste := []
	for key in oy_ist:
		var o: Dictionary = oy_ist[key].duplicate()
		var ti: int = o.team; var yedi: int = sc[1 - ti]; var res: int = signi(sc[ti] - yedi)
		var n: float = 6.1 + res * .35 + o.g * 1.05 + o.a * .6 + mini(o.i, 4) * .12 + mini(o.pk, 12) * .04 - (.15 if o.p - o.pk > 4 else 0.0) - o.f * .08 + (r.randf() - .5) * .5
		if o.rol == "G": n += mini(o.k, 6) * .3 - yedi * .3 + (.6 if yedi == 0 else 0.0)
		elif o.rol == "D": n += (.45 if yedi == 0 else 0.0) - yedi * .15
		var kart_: String = kk.get(key, "")
		if kart_.contains("S"): n -= .3
		if kart_.contains("K"): n -= 1.5
		if int(o.gir) > 60: n = 6.0 + (n - 6.0) * .5
		o.not_ = snappedf(clampf(n, 3.0, 10.0), .1); o.kart = kart_
		liste.append(o)
	liste.sort_custom(func(a, b): return a.not_ > b.not_ or (a.not_ == b.not_ and a.g > b.g))
	var yildiz = null
	for o in liste:
		if sc[0] == sc[1] or o.team == (0 if sc[0] > sc[1] else 1): yildiz = o; break
	var tt: float = maxf(ist.top[0] + ist.top[1], .001)
	var top0: int = roundi(ist.top[0] / tt * 100.0)
	var pasy := [0, 0]
	for t in 2: pasy[t] = roundi(float(ist.pas_ok[t]) / ist.pas[t] * 100.0) if ist.pas[t] > 0 else 0
	return {"sc": sc, "oy": liste, "yildiz": yildiz, "ist": {"Topla oynama %": [top0, 100 - top0], "Şut": ist.sut, "İsabetli şut": ist.isabet, "Pas isabeti %": pasy,
		"Korner": korner, "Faul": faul, "Kurtarış": ist.kurtar}}

# oyuncu kariyer geçmişi (Champion 4.5.0'daki gibi): veri/kariyer.json, anahtar lig:kulüp:forma no
static var KAR := {}
static func kariyer(lig: String, kulup: String, no: int) -> String:
	if KAR.is_empty():
		var j = JSON.parse_string(FileAccess.get_file_as_string("res://veri/kariyer.json"))
		KAR = j if j is Dictionary else {"K": {}, "KLUP": []}
	var v = KAR.K.get(lig + ":" + kulup + ":" + str(no))
	if v == null: return ""
	var par := []
	var g: Array = v[0]
	for i in range(g.size() - 1, maxi(-1, g.size() - 5), -1):
		var x: Array = g[i]
		var yil := str(int(x[0])) + ("–" if int(x[1]) == 0 else ("–" + str(int(x[1])).substr(2) if int(x[1]) != int(x[0]) else ""))
		par.append("%s %s (%d M%s)%s" % [yil, KAR.KLUP[int(x[2])], int(x[3]), (" · %d G" % int(x[4])) if int(x[4]) > 0 else "", " kiralık" if x.size() > 5 and int(x[5]) == 1 else ""])
	var t := " · ".join(par)
	if v.size() > 1: t += "  ·  A milli %d M · %d G" % [int(v[1][0]), int(v[1][1])]
	return t

# rapor yazısı (ekran ve VR paneli); ev: soldaki takım indisi
func rapor_metni(ev := 0) -> String:
	var R := rapor(); var dep := 1 - ev
	var t := "MAÇ RAPORU\n%s  %d - %d  %s\n" % [T[ev].t.ad, R.sc[ev], R.sc[dep], T[dep].t.ad]
	if R.yildiz != null: t += "\nMAÇIN YILDIZI:  %s  (%s)  ·  %.1f\n" % [R.yildiz.n, T[R.yildiz.team].t.kisa, R.yildiz.not_]
	if R.yildiz != null and T[R.yildiz.team].t.has("lig"):
		var kr := kariyer(str(T[R.yildiz.team].t.lig), str(T[R.yildiz.team].t.id), int(R.yildiz.no))
		if kr != "": t += "  Kariyeri: " + kr + "\n"
	t += "\nGOLLER\n"
	if events.is_empty(): t += "  Gol yok.\n"
	for e in events: t += "  %d'  %s  %s%s\n" % [e.min, T[e.team].t.kisa, e.n, ("  (asist: %s)" % e.as) if str(e.get("as", "")) != "" else ""]
	if not kartlar.is_empty():
		t += "\nKARTLAR\n"
		for k in kartlar: t += "  %s  %s  %s\n" % ["SARI" if k[2] == "S" else "KIRMIZI", T[k[0]].t.kisa, k[1]]
	t += "\nİSTATİSTİK  (%s - %s)\n" % [T[ev].t.kisa, T[dep].t.kisa]
	for ad in R.ist: t += "  %s:  %d - %d\n" % [ad, R.ist[ad][ev], R.ist[ad][dep]]
	for ti in [ev, dep]:
		t += "\nNOTLAR · %s\n" % T[ti].t.kisa
		var sat := []
		for o in R.oy:
			if o.team == ti: sat.append("%d %s %.1f%s%s" % [o.no, o.n, o.not_, " G" + str(o.g) if o.g > 0 else "", " A" + str(o.a) if o.a > 0 else ""])
		for i in range(0, sat.size(), 3): t += "  " + "   ·   ".join(sat.slice(i, i + 3)) + "\n"
	return t
