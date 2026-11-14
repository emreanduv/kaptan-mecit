# Dış maç: Champion Battle Manager'ın (CBM) "Modern" izleme modu.
# Maçı CBM'in kendi motoru oynatır (sonuç, taktik, değişiklik, kart hepsi CBM'de); Kaptan Mecit 3 yalnızca çizer.
# Web derlemesinde ?cbm=1 ile açılır; CBM her karede pencereye (iframe) durum yazar:
#   window.__cbmKurulum  : JSON {ev:{kisa,ad,c1,c2}, dep:{...}, oy:[[takım, no, kaleci 0/1, ten, saç], ...]}
#   window.__cbmKare     : JSON {k:[x,y,vx,vy, ...], b:[x,y,z,vx,vy], s:[a,b], dk:"45+1", yon0: 1|-1, d:"oyun"|"gol0"|"gol1"|"bitti"}
#   window.__cbmOlay     : dizi [["vurus", i, güç], ["gol", t], ["duduk", n], ["kart", "S"|"K", ad], ["degisiklik", i, no, ten, saç], ["atildi", i], ["kayma", i], ["dusme", i], ["uc", i, yan], ...]
# CBM koordinatı: x boy (0..105), y en (0..68). Burada: x en, y boy → x = cbm.y, y = cbm.x.
class_name DisMac
extends RefCounted

const PW := 68.0
const PL := 105.0

var T: Array = []
var P: Array = []
var ball := Mac.Top.new()
var demo := true
var state := "play"
var ctrl = null
var kul_dep := false
var olaylar: Array = []
var _dk := "0"
var _yon0 := 1.0
var _gol := -1
var _gol_t := 0.0

func kur(d: Dictionary) -> void:
	T = []
	for k in ["ev", "dep"]:
		var t: Dictionary = d[k]
		T.append({"t": {"kisa": t.get("kisa", "?"), "ad": t.get("ad", "?")}, "kit": {"c1": t.get("c1", "#ffffff"), "c2": t.get("c2", "#222222")}, "score": 0, "human": false})
	P = []
	var i := 0
	for o in d.oy:
		var p := Mac.Oy.new()
		p.team = int(o[0]); p.i = i; p.no = int(o[1]); p.role = "G" if int(o[2]) == 1 else "O"
		p.ten = str(o[3]); p.sac = str(o[4]); p.x = PW / 2; p.y = PL / 2
		P.append(p); i += 1

func goal_y_of(ti: int) -> float:
	# t takımının hücum ettiği kalenin boy koordinatı
	var sag := (_yon0 > 0) == (ti == 0)
	return PL if sag else 0.0
func own_goal_y(ti: int) -> float: return PL - goal_y_of(ti)
func fwd_of(ti: int) -> float: return 1.0 if goal_y_of(ti) == PL else -1.0
func min_label() -> String: return _dk
func son_gol_takimi() -> int: return _gol if _gol_t > 0 else -1

# bir CBM karesini uygula (dt: son kareden beri geçen süre)
func kare(f: Dictionary, dt: float) -> void:
	_yon0 = float(f.get("yon0", 1))
	_dk = str(f.get("dk", _dk))
	var s: Array = f.get("s", [0, 0])
	T[0].score = int(s[0]); T[1].score = int(s[1])
	var d := str(f.get("d", "oyun"))
	state = "over" if d == "bitti" else ("goal" if d.begins_with("gol") else "play")
	if d.begins_with("gol"): _gol = int(d.substr(3)); _gol_t = 0.6
	else: _gol_t = maxf(0, _gol_t - dt)
	var k: Array = f.get("k", [])
	for i in mini(P.size(), k.size() / 4):
		var p: Mac.Oy = P[i]
		var x: float = k[i * 4]; var y: float = k[i * 4 + 1]
		if x < -50: p.inj = true; continue          # sahada değil (atıldı / çıktı)
		p.inj = false
		var vx: float = k[i * 4 + 3]; var vy: float = k[i * 4 + 2]
		var nx := y; var ny := x                     # CBM (boy, en) → (en, boy)
		p.anim += Vector2(nx - p.x, ny - p.y).length() if p.x != PW / 2 or p.y != PL / 2 else 0.0
		p.x = nx; p.y = ny; p.vx = vx; p.vy = vy
		var hiz := Vector2(vx, vy).length()
		if p.cd > 0: pass                            # vuruş anında yüz topun gittiği yöne dönük kalır (topukla vuruş görünmesin)
		elif hiz > .3: p.dx = vx / hiz; p.dy = vy / hiz
		elif ball.owner == null:
			# dururken topa döner
			var b := Vector2(ball.x - p.x, ball.y - p.y)
			if b.length() > .5: p.dx = lerpf(p.dx, b.normalized().x, .1); p.dy = lerpf(p.dy, b.normalized().y, .1)
		p.kafa = maxf(0, p.kafa - dt)
		p.cd = maxf(0, p.cd - dt); p.slide = maxf(0, p.slide - dt); p.stun = maxf(0, p.stun - dt); p.ucus = maxf(0, p.ucus - dt)
		if p.ucus <= 0: p.dive = 0
	var b: Array = f.get("b", [])
	if b.size() >= 5:
		ball.x = b[1]; ball.y = b[0]; ball.z = b[2]; ball.vx = b[4]; ball.vy = b[3]
	if ball.kicker and ball.kicker.cd <= 0: ball.kicker = null

# CBM olaylarını çizime/sese çevir: ana.gd'nin _olay'ı anlar
func olay(o: Array) -> Array:
	match str(o[0]):
		"vurus":
			var p: Mac.Oy = P[int(o[1])] if int(o[1]) < P.size() else null
			if p:
				p.cd = .35; ball.kicker = p
				# top baş hizasındaysa CBM'deki vuruş kafa vuruşudur: Kaptan Mecit'teki sıçrama hareketi
				if ball.z > 1.2 and p.role != "G": p.kafa = Mac.KAFA_SURE
				# vuran oyuncu topun gittiği yöne bakar; top yavaşsa hücum ettiği kaleye
				var v := Vector2(ball.vx, ball.vy)
				if v.length() < 1.0: v = Vector2(PW / 2 - p.x, goal_y_of(p.team) - p.y)
				if v.length() > .01:
					v = v.normalized(); p.dx = v.x; p.dy = v.y
			return ["vurus", float(o[2]) if o.size() > 2 else .6]
		"kayma":
			if int(o[1]) < P.size(): P[int(o[1])].slide = .7
			return []
		"dusme":
			if int(o[1]) < P.size(): P[int(o[1])].stun = 1.2
			return []
		"uc":
			if int(o[1]) < P.size():
				var g: Mac.Oy = P[int(o[1])]
				g.dive = 1; g.ucus = Futbolcu.UCUS_T; g.ucus_tur = 1; g.ucus_yan = float(o[2]) if o.size() > 2 else 1.0; g.ucus_z = .6; g.ucus_ofs = Vector2.ZERO
			return []
		"gol": return ["gol", int(o[1])]
		"duduk": return ["duduk", int(o[1])]
		"kart": return ["kart", str(o[1]), str(o[2])]
		"degisiklik":
			var i := int(o[1])
			if i < P.size():
				var p: Mac.Oy = P[i]; p.no = int(o[2]); p.ten = str(o[3]); p.sac = str(o[4])
				return ["degisiklik", p]
		"atildi":
			if int(o[1]) < P.size(): return ["atildi", P[int(o[1])]]
		"taraftar": return ["taraftar", int(o[1]), str(o[2])]
		"ooo": return ["ooo"]
	return []
