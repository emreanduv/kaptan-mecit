# Kaptan Mecit 3 — taktik: Champion Battle Manager'ın 34 dizilişi ve teknik direktör asistanı.
# Kulübün 22 kişilik havuzundan (2 kaleci + en iyi 20) seçilen dizilişe göre en uygun ilk 11 ve 9 yedek kurulur;
# "Otomatik"te kadroya en uygun diziliş seçilir (eşitlikte yaygın olan). Kaptan Mecit'teki asistanKur / kadroKur'un birebir karşılığı.
extends RefCounted
class_name Taktik

static var V: Dictionary = {}
const DZ_HARF := {"KL": "G", "SĞB": "D", "STP": "D", "SLB": "D", "DOS": "O", "MOS": "O", "SĞO": "O", "SLO": "O", "OOS": "O", "SĞK": "F", "SLK": "F", "SF": "F"}
const DZ_KOD := {"KL": "GK", "SLB": "LB", "SĞB": "RB", "DOS": "DM", "MOS": "CM", "OOS": "AM", "SĞO": "RW", "SĞK": "RW", "SLO": "SS", "SLK": "SS", "SF": "ST"}
const TENLER := ["#f1c9a5", "#e0ac7e", "#c68a5a", "#8d5a3b", "#f5d6b8"]
const SACLAR := ["#2a1a10", "#4a2e1a", "#1a1a1a", "#7a4a20", "#c8a050"]

static func yukle() -> void:
	if V.is_empty(): V = JSON.parse_string(FileAccess.get_file_as_string("res://veri/taktik.json"))

static func siralama() -> Array:
	yukle(); return V.sira

static func uyum(o: Dictionary, yer: String) -> float:
	if o.m == yer: return 1.0
	if (o.y as Array).has(yer): return .92
	var yk: Array = V.yakin.get(yer, [])
	var yi := yk.find(o.m)
	if yi >= 0: return .87 if yi == 0 else .82
	if yer == "KL" or o.m == "KL": return .05
	return .7 if V.grup.get(o.m) == V.grup.get(yer) else .45

static func _puan(o, D: Array, i: int) -> float:
	if o == null: return 0.0
	var u := uyum(o, D[i][0])
	return o.ca * u * u * u

static func asistan_kur(havuz: Array, dz: String) -> Dictionary:
	var D: Array = V.dizilis[dz]
	var sec := {}
	var xi: Array = []; xi.resize(11)
	# en zor doldurulan yerlerden başla
	var sira: Array = []
	for i in D.size():
		var n := 0
		for o in havuz:
			if uyum(o, D[i][0]) >= .82: n += 1
		sira.append([i, n])
	sira.sort_custom(func(a, b): return a[1] < b[1])
	for s in sira:
		var i: int = s[0]
		var en = null; var es := -1.0
		for o in havuz:
			if sec.has(o.n): continue
			var p := _puan(o, D, i)
			if p > es: es = p; en = o
		if en != null: sec[en.n] = true; xi[i] = en
	# takasla iyileştir
	for tur in 8:
		var dg := false
		for i in 11:
			for j in range(i + 1, 11):
				if _puan(xi[j], D, i) + _puan(xi[i], D, j) > _puan(xi[i], D, i) + _puan(xi[j], D, j) + .5:
					var t = xi[i]; xi[i] = xi[j]; xi[j] = t; dg = true
		for i in 11:
			for o in havuz:
				if sec.has(o.n): continue
				if _puan(o, D, i) > _puan(xi[i], D, i) + .5:
					if xi[i] != null: sec.erase(xi[i].n)
					sec[o.n] = true; xi[i] = o; dg = true
		if not dg: break
	var kalan: Array = havuz.filter(func(o): return not sec.has(o.n))
	kalan.sort_custom(func(a, b): return a.ca > b.ca)
	var yedek: Array = []
	for o in kalan:
		if o.m == "KL": yedek.append(o); break
	for o in kalan:
		if o.m != "KL" and yedek.size() < 9: yedek.append(o)
	var top := 0.0
	for i in 11: top += _puan(xi[i], D, i)
	return {"xi": xi, "yedek": yedek, "puan": top}

static func km_dizilis(dz: String) -> Array:
	var r: Array = []
	for d in V.dizilis[dz]:
		var rol: String = d[0]
		var fx := snappedf(1.0 - float(d[2]) / 68.0, .001)
		var fy := .02 if rol == "KL" else minf(.47, float(d[1]) / 100.0)
		r.append([fx, fy, "G" if rol == "KL" else DZ_HARF[rol], ("LCB" if fx <= .5 else "RCB") if rol == "STP" else DZ_KOD[rol]])
	return r

static func _renk(ad: String, k: int) -> String:
	var h := ad.hash()
	return TENLER[posmod(h, 5)] if k == 0 else SACLAR[posmod(h >> 5, 5)]

# takım: takimlar.json'daki kulüp sözlüğü; lig: lig kimliği; dz: "" (otomatik) ya da diziliş adı
static func kadro_kur(takim: Dictionary, lig: String, dz := "") -> Dictionary:
	yukle()
	var H: Array = V.havuz.get(lig + ":" + str(takim.id), [])
	if H.is_empty(): return takim
	var havuz: Array = []
	for h in H: havuz.append({"no": int(h[0]), "n": h[1], "m": h[2], "y": (h[3] as String).split(",", false), "ca": float(h[4])})
	var en = null; var ed := dz if V.dizilis.has(dz) else ""
	if ed != "": en = asistan_kur(havuz, ed)
	else:
		for d in V.sira:
			var r := asistan_kur(havuz, d)
			var p: float = r.puan * float(V.yaygin.get(d, .985))
			if en == null or p > en.p: en = r; en.p = p; ed = d
	var yer := km_dizilis(ed)
	# ten / saç: hazır veride varsa onu kullan (oyuncu her maçta aynı görünsün), yoksa adından türet
	var eski := {}
	for o in takim.oy: eski[o.n] = o
	var oy: Array = []
	for i in 11:
		var o = en.xi[i]
		var e: Dictionary = eski.get(o.n, {})
		oy.append({"no": o.no, "n": o.n, "st": 1.0, "ten": e.get("ten", _renk(o.n, 0)), "sac": e.get("sac", _renk(o.n, 1)),
			"rol": yer[i][2], "yer": yer[i][3], "fx": yer[i][0], "fy": yer[i][1], "dz": true, "mk": str(o.m), "ca": float(o.ca)})
	var yed: Array = []
	for o in en.yedek: yed.append({"no": o.no, "n": o.n, "mevki": DZ_HARF.get(o.m, "O"), "ten": _renk(o.n, 0), "sac": _renk(o.n, 1), "mk": str(o.m), "ca": float(o.ca)})
	var t := takim.duplicate()
	t.oy = oy; t.yedek = yed; t.dzAd = ed; t.lig = lig
	t.guc = snappedf(float(en.puan) / 11.0, .01)     # lig modunun hızlı simülasyonu için
	return t
