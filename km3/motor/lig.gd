# Kaptan Mecit 3 — lig modu: tam sezon fikstürü (çift devreli, her takım her takımla bir içeride bir dışarıda),
# puan tablosu (O G B M A Y Av P), kullanıcının haftalık maçı; diğer maçlar Taktik kadroları ve güç değerleriyle hızlı simüle.
# Kayıt: user://km3-lig.json ("Verilerimi sil" bunu da siler). Ekran (arayuz/lig_ekran.gd) ve VR (vr/vr.gd) aynı satırları kullanır.
extends RefCounted
class_name Lig

const KAYIT := "user://km3-lig.json"
const SURUM := 1

var veri: Dictionary            # takimlar.json
var d: Dictionary = {}          # sezon durumu (boşsa sezon yok)
var son_rapor := ""             # son lig maçının raporu (ana doldurur)
var kip := "lig"                # lig ekranı ne gösteriyor: "lig" ya da "kupa"
var kupa := {}                  # kupa durumu (boşsa kupa yok); kayıt: user://km3-kupa.json
var kur_kupa := 0
var kur_kupa_takim := 0
const KUPA_KAYIT := "user://km3-kupa.json"
var _krng := RandomNumberGenerator.new()   # kupa simülasyonu: tek üreteç (web'de aynı milisaniyede yeni üreteçler aynı tohumu alıyordu)
var kur_lig := 0                # kurulum ekranında seçilen lig / takım
var kur_takim := 0
var mesaj := ""
var _birak_onay := 0.0
var son_hafta: Array = []       # en son oynanan haftanın maçları (ekranda "Haftanın sonuçları")
var diz := ""                   # kullanıcının ana menüde seçtiği diziliş ("" = Otomatik); kadro görünümü maçtaki ilk 11'i gösterir
var gorunum := "tablo"          # sol panel: "kadro" (kulübün kadrosu), "tablo" (puan durumu), "fikstur" (kulübün sezon fikstürü), "goller" (gol krallığı) ya da "tarih" (kulübün sezon sezon tarihçesi)
const GOL_AGIRLIK := {"F": 5.0, "O": 1.8, "D": .55, "G": 0.0}   # simüle maçta golü kimin attığı: mevkiye göre pay

func _init(v: Dictionary) -> void:
	veri = v
	yukle()

# ---------- kayıt ----------
func var_mi() -> bool: return not d.is_empty()

func yukle() -> void:
	_krng.randomize()
	kupa_yukle()
	d = {}
	if not FileAccess.file_exists(KAYIT): return
	var j = JSON.parse_string(FileAccess.get_file_as_string(KAYIT))
	if typeof(j) != TYPE_DICTIONARY or int(j.get("surum", 0)) != SURUM: return
	# bozuk / eski kayıt: lig ya da takım artık yoksa yok say
	var li := int(j.get("lig", -1))
	if li < 0 or li >= veri.ligler.size(): return
	if (j.get("takimlar", []) as Array).size() != veri.ligler[li].takimlar.size(): return
	d = j
	if not d.has("golcu") or (d.golcu as Array).size() != (d.takimlar as Array).size():   # gol krallığından önceki kayıt
		d.golcu = _golcu_kur(li); d.goller = {}
	if not d.has("goller"): d.goller = {}
	if not d.has("tarih"): d.tarih = []      # tarihçeden önceki kayıt
	if not d.has("hedef"): d.hedef = _hedef_kur()   # yönetim beklentisinden önceki kayıt
	if int(d.hafta) > 0: son_hafta = d.fikstur[int(d.hafta) - 1]

func kaydet() -> void:
	if d.is_empty(): return
	var f := FileAccess.open(KAYIT, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d)); f.close()

func sil() -> void:
	son_rapor = ""
	kupa = {}
	if FileAccess.file_exists(KUPA_KAYIT): DirAccess.remove_absolute(ProjectSettings.globalize_path(KUPA_KAYIT))
	d = {}; son_hafta = []; mesaj = ""; gorunum = "tablo"
	if FileAccess.file_exists(KAYIT): DirAccess.remove_absolute(ProjectSettings.globalize_path(KAYIT))

# ---------- sezon ----------
func lig_veri() -> Dictionary: return veri.ligler[int(d.lig)] if var_mi() else veri.ligler[kur_lig]
func takim(i: int) -> Dictionary: return lig_veri().takimlar[i]
func biz() -> int: return int(d.takim)
func hafta_sayisi() -> int: return (d.fikstur as Array).size()
func bitti() -> bool: return int(d.hafta) >= hafta_sayisi()

func yeni_sezon(lig: int, tk: int, sezon := 1, tarih: Array = []) -> void:
	var L: Array = veri.ligler[lig].takimlar
	var n := L.size()
	# güç: asistanın kurduğu ilk 11'in mevkiye uyumlu ortalama yeteneği (Taktik), yoksa kulübün güç puanından
	var guc: Array = []
	var golcu: Array = []
	for t in L:
		var k := Taktik.kadro_kur(t, veri.ligler[lig].id)
		guc.append(snappedf(float(k.get("guc", 40.0 + 9.0 * float(t.str))), .01))
		golcu.append(_golcu_listesi(k))
	d = {"surum": SURUM, "lig": lig, "takim": tk, "sezon": sezon, "hafta": 0, "takimlar": range(n),
		"guc": guc, "fikstur": gercek_fikstur(lig), "sampiyon": -1, "golcu": golcu, "goller": {}, "tarih": tarih}
	if d.fikstur.is_empty(): d.fikstur = fikstur_uret(n, randi())
	d.hedef = _hedef_kur()
	son_hafta = []
	mesaj = ""
	kaydet()

# gol krallığı: her kulübün ilk 11'i ve gol atma payı (forvet > orta saha > defans, kaleci atmaz) — [[ad, pay], ...]
static func _golcu_listesi(k: Dictionary) -> Array:
	var r: Array = []
	for o in k.get("oy", []):
		var w: float = GOL_AGIRLIK.get(str(o.get("rol", "O")), 1.0)
		if w > 0.0: r.append([str(o.n), w])
	return r

func _golcu_kur(lig: int) -> Array:
	var r: Array = []
	for t in veri.ligler[lig].takimlar: r.append(_golcu_listesi(Taktik.kadro_kur(t, veri.ligler[lig].id)))
	return r

func _gol_yaz(ti: int, ad: String, n := 1) -> void:
	var k := str(ti) + "|" + ad
	d.goller[k] = int(d.goller.get(k, 0)) + n

# simüle edilen maçta n golü kulübün oyuncularına paylarına göre dağıt
func _gol_dagit(ti: int, n: int, rng: RandomNumberGenerator) -> void:
	var G: Array = d.golcu[ti]
	if G.is_empty(): return
	var top := 0.0
	for g in G: top += float(g[1])
	for _k in n:
		var x := rng.randf() * top
		for g in G:
			x -= float(g[1])
			if x <= 0.0: _gol_yaz(ti, str(g[0])); break

# gol krallığı (ekran ve VR): [sıra, oyuncu, kulüp kısa adı, kulüp, gol, biz mi] — eşit golde aynı sıra
func gol_krallari(n := 20) -> Array:
	var L: Array = []
	for k in d.get("goller", {}):
		var p := (k as String).split("|", true, 1)
		L.append([int(p[0]), p[1], int(d.goller[k])])
	L.sort_custom(func(a, b): return a[2] > b[2] if a[2] != b[2] else a[1] < b[1])
	var r: Array = []
	var sira := 0
	for k in mini(n, L.size()):
		if k == 0 or L[k][2] != L[k - 1][2]: sira = k + 1
		r.append([sira, L[k][1], takim(L[k][0]).kisa, takim(L[k][0]).ad, L[k][2], L[k][0] == biz()])
	return r

func gol_krali_metni() -> String:
	var g := gol_krallari(1)
	if g.is_empty(): return ""
	return "%s (%s) · %d gol" % [g[0][1], g[0][2], g[0][4]]

# gerçek fikstür: ligin bu sezonki gerçek maç sırası (veri/fikstur.json; openfootball, yalnız eşleşme sırası —
# kulüpler ve sonuçlar oyunun kendisidir). Eşleşme eksik/hatalıysa boş döner, çember yöntemine düşülür.
func gercek_fikstur(lig: int) -> Array:
	var f := FileAccess.open("res://veri/fikstur.json", FileAccess.READ)
	if f == null: return []
	var j = JSON.parse_string(f.get_as_text())
	if not (j is Dictionary): return []
	var lg: Dictionary = veri.ligler[lig]
	var H: Array = j.get("ligler", {}).get(lg.id, [])
	var sira := {}
	for i in lg.takimlar.size(): sira[lg.takimlar[i].id] = i
	var n: int = lg.takimlar.size()
	if H.size() != 2 * (n - 1): return []
	var out: Array = []
	for h in H:
		var hafta: Array = []
		for mc in h:
			if not (sira.has(mc[0]) and sira.has(mc[1])): return []
			hafta.append([sira[mc[0]], sira[mc[1]], -1, -1])
		if hafta.size() != n / 2: return []
		out.append(hafta)
	return out

# çember yöntemi: n takım (tekse "bay" eklenir), n-1 hafta ilk devre, ikinci devre ev/deplasman ters.
# maç: [ev, deplasman, ev golü, deplasman golü] (oynanmadıysa gol -1)
static func fikstur_uret(n: int, tohum: int) -> Array:
	var rng := RandomNumberGenerator.new(); rng.seed = tohum
	var sira: Array = range(n)
	for i in range(n - 1, 0, -1):
		var j := rng.randi_range(0, i); var t = sira[i]; sira[i] = sira[j]; sira[j] = t
	if n % 2 == 1: sira.append(-1)
	var m := sira.size()
	var ilk: Array = []
	var son_ev := {}; var ev_say := {}     # ev/deplasman dengesi: art arda ikiden fazla iç saha / deplasman olmasın
	for r in m - 1:
		var hafta: Array = []
		for k in m / 2:
			var a: int = sira[k]; var b: int = sira[m - 1 - k]
			if a < 0 or b < 0: continue
			var ea: int = son_ev.get(a, 0); var eb: int = son_ev.get(b, 0)     # +: art arda iç saha sayısı, -: deplasman
			var a_ev: bool
			if ea != eb: a_ev = ea < eb
			elif ev_say.get(a, 0) != ev_say.get(b, 0): a_ev = ev_say.get(a, 0) < ev_say.get(b, 0)
			else: a_ev = rng.randi() % 2 == 0
			var e := a if a_ev else b; var dp := b if a_ev else a
			hafta.append([e, dp, -1, -1])
			ev_say[e] = ev_say.get(e, 0) + 1
			son_ev[e] = maxi(son_ev.get(e, 0), 0) + 1; son_ev[dp] = mini(son_ev.get(dp, 0), 0) - 1
		ilk.append(hafta)
		# döndür: ilk sabit, gerisi bir kayar
		var son = sira.pop_back(); sira.insert(1, son)
	var ikinci: Array = []
	for h in ilk:
		var y: Array = []
		for mc in h: y.append([mc[1], mc[0], -1, -1])
		ikinci.append(y)
	return ilk + ikinci

func sonraki_mac() -> Array:
	if not var_mi() or bitti(): return []
	for mc in d.fikstur[int(d.hafta)]:
		if int(mc[0]) == biz() or int(mc[1]) == biz(): return mc
	return []

# hızlı simülasyon: güç farkına göre beklenen gol (Poisson), ev sahibi avantajı
func sim_mac(e: int, dp: int, rng: RandomNumberGenerator) -> Array:
	var ge: float = d.guc[e]; var gd: float = d.guc[dp]
	var le := 1.42 * exp(.016 * (ge - gd)); var ld := 1.12 * exp(.016 * (gd - ge))
	return [_poisson(le, rng), _poisson(ld, rng)]

static func _poisson(l: float, rng: RandomNumberGenerator) -> int:
	var L := exp(-minf(l, 6.0)); var k := 0; var p := 1.0
	while true:
		p *= rng.randf()
		if p <= L or k >= 9: break
		k += 1
	return k

# kullanıcının maçı bitti: biz / rakip golleri (maç motorunda kullanıcı her zaman T[0]). Haftanın kalanını simüle et, haftayı ilerlet.
# golcuk: maç motorunun gol olayları [{"n": ad, "team": 0 biz / 1 rakip}] — gol krallığına yazılır (kendi kalesine gol sayılmaz);
# boşsa goller kadrolara simüle maçtaki gibi dağıtılır.
func kullanici_sonuc(g_biz: int, g_rakip: int, golcuk: Array = []) -> void:
	var mc := sonraki_mac()
	if mc.is_empty(): return
	if int(mc[0]) == biz(): mc[2] = g_biz; mc[3] = g_rakip
	else: mc[2] = g_rakip; mc[3] = g_biz
	var rk: int = int(mc[1]) if int(mc[0]) == biz() else int(mc[0])
	if golcuk.is_empty():
		var rng := RandomNumberGenerator.new(); rng.randomize()
		_gol_dagit(biz(), g_biz, rng); _gol_dagit(rk, g_rakip, rng)
	else:
		for e in golcuk:
			var ad := str(e.get("n", ""))
			if ad == "" or ad.begins_with("Kendi kalesine"): continue
			_gol_yaz(biz() if int(e.get("team", 0)) == 0 else rk, ad)
	hafta_bitir()

func hafta_bitir() -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var h: Array = d.fikstur[int(d.hafta)]
	for mc in h:
		if int(mc[2]) < 0:
			var s := sim_mac(int(mc[0]), int(mc[1]), rng)
			mc[2] = s[0]; mc[3] = s[1]
			_gol_dagit(int(mc[0]), s[0], rng); _gol_dagit(int(mc[1]), s[1], rng)
	son_hafta = h
	d.hafta = int(d.hafta) + 1
	if bitti():
		d.sampiyon = tablo()[0].i
		mesaj = "Sezon bitti · Şampiyon: " + takim(int(d.sampiyon)).ad
		if gol_krali_metni() != "": mesaj += " · Gol kralı: " + gol_krali_metni()
		mesaj += " · Yönetim: " + hedef_sonuc(sira_biz(), hedef_sira())
		_tarihe_yaz()
	else:
		mesaj = ""
	kaydet()

# kullanıcının maçını da simüle et (Maçı simüle et)
func haftayi_simule() -> void:
	if not var_mi() or bitti(): return
	hafta_bitir()

func tablo() -> Array:
	var n: int = (d.takimlar as Array).size()
	var T: Array = []
	for i in n: T.append({"i": i, "O": 0, "G": 0, "B": 0, "M": 0, "A": 0, "Y": 0, "Av": 0, "P": 0, "form": ""})
	for h in d.fikstur:
		for mc in h:
			var ge := int(mc[2]); var gd := int(mc[3])
			if ge < 0: continue
			for yan in 2:
				var r: Dictionary = T[int(mc[yan])]
				var a := ge if yan == 0 else gd; var y := gd if yan == 0 else ge
				r.O += 1; r.A += a; r.Y += y
				if a > y: r.G += 1; r.P += 3; r.form += "G"
				elif a == y: r.B += 1; r.P += 1; r.form += "B"
				else: r.M += 1; r.form += "M"
	for r in T: r.Av = r.A - r.Y; r.form = (r.form as String).right(5)
	T.sort_custom(func(x, y):
		if x.P != y.P: return x.P > y.P
		if x.Av != y.Av: return x.Av > y.Av
		if x.A != y.A: return x.A > y.A
		return takim(x.i).ad < takim(y.i).ad)
	return T

func sira_biz() -> int:
	var t := tablo()
	for k in t.size():
		if t[k].i == biz(): return k + 1
	return 0

func sezon_adi() -> String:
	var y := 2026 + int(d.get("sezon", 1)) - 1
	return "%d/%02d" % [y, (y + 1) % 100]

# ---------- menü satırları (ekran ve VR ortak) ----------
func satirlar() -> Array:
	if kip == "kupa": return kupa_satirlari()
	if not var_mi(): return ["Lig", "Takımın", "SEZONA BAŞLA", "Kupalar", "Ana menü"]
	var r: Array = ["YENİ SEZON", "Kadro", "Fikstür", "Gol krallığı", "Tarihçe", "Ana menü", "Ligi bırak"] if bitti() else ["MAÇA ÇIK", "Maçı simüle et", "Kadro", "Fikstür", "Gol krallığı", "Tarihçe", "Ana menü", "Ligi bırak"]
	if son_rapor != "": r.insert(r.find("Ana menü"), "Maç raporu")
	r.insert(r.find("Ana menü"), "Kupalar")
	return r

func satir_metni(i: int, sec := false) -> String:
	var s: String = satirlar()[i]
	var ok := ("»  " if sec else "")
	if kip == "kupa": return kupa_satir_metni(s, sec)
	match s:
		"Lig": return ("‹  " if sec else "") + "Lig:  " + veri.ligler[kur_lig].ad + " · " + veri.ligler[kur_lig].ulke + ("  ›" if sec else "")
		"Takımın":
			var t: Dictionary = veri.ligler[kur_lig].takimlar[kur_takim]
			return ("‹  " if sec else "") + "Takımın:  " + t.ad + "  (güç " + str(int(t.str)) + ")" + ("  ›" if sec else "")
		"MAÇA ÇIK":
			var mc := sonraki_mac()
			return ok + "MAÇA ÇIK  ·  " + takim(int(mc[0])).kisa + " - " + takim(int(mc[1])).kisa
		"YENİ SEZON": return ok + "YENİ SEZON  ·  " + str(int(d.sezon) + 1) + ". sezon"
		"Kadro": return ok + ("Puan durumu" if gorunum == "kadro" else "Kadro")
		"Fikstür": return ok + ("Puan durumu" if gorunum == "fikstur" else "Fikstür")
		"Gol krallığı": return ok + ("Puan durumu" if gorunum == "goller" else "Gol krallığı")
		"Tarihçe": return ok + ("Puan durumu" if gorunum == "tarih" else "Tarihçe")
	return ok + s

func kay(i: int, yon: int) -> void:
	var s: String = satirlar()[i]
	if kip == "kupa":
		if s == "Kupa": kur_kupa = posmod(kur_kupa + yon, KUPALAR.size()); kur_kupa_takim = 0
		elif s == "Takımın": kur_kupa_takim = posmod(kur_kupa_takim + yon, kupa_katilim(KUPALAR[kur_kupa].id).size())
		return
	if s == "Lig": kur_lig = posmod(kur_lig + yon, veri.ligler.size()); kur_takim = 0
	elif s == "Takımın": kur_takim = posmod(kur_takim + yon, veri.ligler[kur_lig].takimlar.size())

# döndürür: "mac" (maça çık), "menu" (ana menüye dön) ya da ""
func bas(i: int) -> String:
	var s: String = satirlar()[i]
	if kip == "kupa": return kupa_bas(s, i)
	match s:
		"Lig", "Takımın": kay(i, 1)
		"SEZONA BAŞLA": yeni_sezon(kur_lig, kur_takim)
		"MAÇA ÇIK": return "mac"
		"Maçı simüle et": haftayi_simule()
		"Kadro": gorunum = "tablo" if gorunum == "kadro" else "kadro"
		"Fikstür": gorunum = "tablo" if gorunum == "fikstur" else "fikstur"
		"Gol krallığı": gorunum = "tablo" if gorunum == "goller" else "goller"
		"Tarihçe": gorunum = "tablo" if gorunum == "tarih" else "tarih"
		"YENİ SEZON": sonraki_sezon()
		"Ana menü": gorunum = "tablo"; return "menu"
		"Maç raporu": return "rapor"
		"Kupalar": kip = "kupa"; mesaj = ""
		"Ligi bırak":
			var simdi := Time.get_ticks_msec() / 1000.0
			if simdi - _birak_onay > 4.0:
				_birak_onay = simdi; mesaj = "Emin misin? Sezon silinir; bir kez daha bas"
			else:
				_birak_onay = 0.0; kur_lig = int(d.lig); kur_takim = int(d.takim); sil()
	return ""

# ---------- kadro: menajer oyunlarının kadro ekranı (no · mevki · oyuncu · yetenek · lig golü · ilk 11 / yedek) ----------
# Asistan kadroyu ana menüde seçilen dizilişe göre kurar (maçtaki kadroyla aynı); goller bu sezonun lig golleri.
const MEVKI_EN := {"KL": "GK", "SĞB": "RB", "STP": "CB", "SLB": "LB", "DOS": "DM", "MOS": "CM", "SĞO": "RM", "SLO": "LM", "OOS": "AM", "SĞK": "RW", "SLK": "LW", "SF": "ST"}
const MEVKI_SIRA := ["KL", "SĞB", "STP", "SLB", "DOS", "MOS", "SĞO", "SLO", "OOS", "SĞK", "SLK", "SF"]
static func mevki_adi(m: String) -> String: return MEVKI_EN.get(m, m) if Dil.en else m

# [[no, mevki kodu, oyuncu, yetenek (0-100), lig golü, ilk 11 mi], ...] — ilk 11 mevki sırasıyla, sonra yedekler
var _kadro_on := {}   # önbellek: asistanın 34 dizilişi denemesi her çizimde tekrarlanmasın
func _kadro() -> Dictionary:
	var anahtar := "%d|%d|%s" % [int(d.lig), biz(), diz]
	if _kadro_on.get("a", "") != anahtar: _kadro_on = {"a": anahtar, "k": Taktik.kadro_kur(takim(biz()), str(lig_veri().id), diz)}
	return _kadro_on.k

func kadro_satirlari() -> Array:
	if not var_mi(): return []
	var k := _kadro()
	var r: Array = []
	for grup in [[k.get("oy", []), true], [k.get("yedek", []), false]]:
		var G: Array = []
		for o in grup[0]:
			G.append([int(o.get("no", 0)), str(o.get("mk", "")), str(o.n), yetenek(float(o.get("ca", 0.0))), int(d.goller.get(str(biz()) + "|" + str(o.n), 0)), grup[1]])
		G.sort_custom(func(a, b): return MEVKI_SIRA.find(a[1]) < MEVKI_SIRA.find(b[1]) if a[1] != b[1] else a[3] > b[3])
		r.append_array(G)
	return r

# kadro başlığı: diziliş ve ilk 11'in ortalama yeteneği
func kadro_ozet() -> String:
	var K := kadro_satirlari()
	if K.is_empty(): return ""
	var t := 0; var n := 0
	for x in K:
		if x[5]: t += int(x[3]); n += 1
	var dz := str(_kadro().get("dzAd", diz))
	return "%s  ·  ilk 11 ort. %d" % [dz, roundi(float(t) / maxf(1, n))]

# Champion'ın yetenek puanı (24–167) → 0-100
static func yetenek(ca: float) -> int: return clampi(roundi(ca / 1.7), 1, 99)

# ---------- tarihçe: kulübün sezon sezon karnesi (menajer oyunlarındaki kulüp geçmişi) ----------
# Biten her sezon d.tarih'e yazılır; "YENİ SEZON" tarihçeyi yeni sezona taşır, "Ligi bırak" / "Verilerimi sil" siler.
func _tarihe_yaz() -> void:
	if not d.has("tarih"): d.tarih = []
	for x in d.tarih:
		if int(x.s) == int(d.sezon): return       # aynı sezon iki kez yazılmaz
	var b: Dictionary = {}
	for r in tablo():
		if r.i == biz(): b = r
	d.tarih.append({"s": int(d.sezon), "sira": sira_biz(), "n": (d.takimlar as Array).size(), "P": b.P, "G": b.G, "B": b.B, "M": b.M,
		"A": b.A, "Y": b.Y, "sam": int(d.sampiyon), "kral": gol_krali_metni(), "hd": hedef_adi(), "hs": hedef_sira()})

func sonraki_sezon() -> void:
	if not var_mi(): return
	if bitti(): _tarihe_yaz()
	yeni_sezon(int(d.lig), int(d.takim), int(d.sezon) + 1, d.get("tarih", []))

# ---------- yönetim beklentisi (FM'deki yönetim kurulu hedefi ve güveni) ----------
# Sezon başında kulübün güç sırasına göre hedef konur; güven, oynanan maçlarda alınan puanın
# güce göre beklenen puandan farkıyla oynar. Sezon sonunda hedef tuttu mu yazılır (tarihçede de).
const HEDEFLER := [["Şampiyonluk", "ligi kazanmak"], ["İlk üç", "ilk üçte bitirmek"], ["İlk altı", "ilk altıda bitirmek"],
	["Orta sıra", "ilk yarının hemen altında ya da üstünde bitirmek"], ["Ligde kalmak", "son üçe düşmemek"]]

func _guc_sirasi() -> int:
	var g: float = d.guc[biz()]
	var r := 1
	for i in (d.guc as Array).size():
		if i != biz() and float(d.guc[i]) > g: r += 1
	return r

func _hedef_kur() -> Dictionary:
	var n: int = (d.takimlar as Array).size()
	var r := _guc_sirasi()
	var k := 0; var s := 1
	if r == 1: k = 0; s = 1
	elif r <= 3: k = 1; s = 3
	elif r <= 6: k = 2; s = 6
	elif r <= n - 5: k = 3; s = ceili(n * .6)
	else: k = 4; s = n - 3
	return {"k": k, "s": clampi(s, 1, n)}

func hedef_adi() -> String: return HEDEFLER[int(d.hedef.k)][0] if var_mi() else ""
func hedef_sira() -> int: return int(d.hedef.s) if var_mi() else 0
func hedef_aciklama() -> String: return HEDEFLER[int(d.hedef.k)][1] if var_mi() else ""

static func hedef_sonuc(sira: int, hs: int) -> String:
	if hs <= 0: return ""
	if sira > hs: return "Hedefin altında"
	if hs > 1 and sira <= maxi(1, hs - 3): return "Beklentinin üstü"
	return "Hedef tuttu"

# güce göre beklenen puan (sim_mac'in Poisson modeliyle: 3 × galibiyet + beraberlik olasılığı)
func beklenen_puan(e: int, dp: int, ev_biz: bool) -> float:
	var ge: float = d.guc[e]; var gd: float = d.guc[dp]
	var le := 1.42 * exp(.016 * (ge - gd)); var ld := 1.12 * exp(.016 * (gd - ge))
	var pe: Array = []; var pd: Array = []
	for k in 11:
		pe.append(exp(-le) * pow(le, k) / _fakt(k)); pd.append(exp(-ld) * pow(ld, k) / _fakt(k))
	var g := 0.0; var b := 0.0; var m := 0.0
	for x in 11:
		for y in 11:
			var p: float = pe[x] * pd[y]
			if x > y: g += p
			elif x == y: b += p
			else: m += p
	return 3.0 * (g if ev_biz else m) + b

static func _fakt(k: int) -> float:
	var f := 1.0
	for i in range(2, k + 1): f *= i
	return f

# yönetim güveni (5–99): 60'tan başlar, beklenenden fazla alınan her puan +3, eksik her puan −3;
# sezonun ikinci yarısında hedefin gerisindeysen sıra farkı başına −2, önündeysen +1
func guven() -> int:
	if not var_mi(): return 0
	var fark := 0.0
	for w in mini(int(d.hafta), hafta_sayisi()):
		for mc in d.fikstur[w]:
			var ev := int(mc[0]) == biz()
			if not ev and int(mc[1]) != biz(): continue
			if int(mc[2]) < 0: continue
			var a := int(mc[2]) if ev else int(mc[3]); var y := int(mc[3]) if ev else int(mc[2])
			var p := 3 if a > y else (1 if a == y else 0)
			fark += p - beklenen_puan(int(mc[0]), int(mc[1]), ev)
	var g := 60.0 + 3.0 * fark
	if int(d.hafta) * 2 >= hafta_sayisi():
		var sf := hedef_sira() - sira_biz()
		g += sf * (1.0 if sf > 0 else 2.0)
	return clampi(roundi(g), 5, 99)

static func yuzde(g: int) -> String: return ("%d%%" % g) if Dil.en else ("%%%d" % g)   # TR: %72, EN: 72%

static func guven_adi(g: int) -> String:
	if g >= 80: return "Çok memnun"
	if g >= 60: return "Memnun"
	if g >= 40: return "Kararsız"
	if g >= 20: return "Huzursuz"
	return "Çok huzursuz"

# kısa durum: "Hedef: İlk üç · şu an 2. · Memnun (%72)"
func yonetim_metni() -> String:
	if not var_mi(): return ""
	var g := guven()
	return "Hedef: %s · şu an %d. · %s (%s)" % [hedef_adi(), sira_biz(), guven_adi(g), yuzde(g)]

static func sezon_adi_no(no: int) -> String:
	var y := 2026 + no - 1
	return "%d/%02d" % [y, (y + 1) % 100]

# tarihçe satırları (ekran ve VR), yeniden eskiye; süren sezon en üstte:
# [sezon adı, sıra, takım sayısı, O, G, B, M, Av, P, şampiyon kısa, şampiyon ad, gol kralı, biz şampiyon mu, sürüyor mu,
#  yönetim: süren sezonda hedefin adı, biten sezonda hedef sonucu (eski kayıtta "")]
func tarih_satirlari() -> Array:
	var r: Array = []
	if not var_mi(): return r
	if not bitti():
		var b: Dictionary = {}
		for x in tablo():
			if x.i == biz(): b = x
		r.append([sezon_adi(), sira_biz(), (d.takimlar as Array).size(), b.O, b.G, b.B, b.M, b.Av, b.P, "", "", "", false, true, hedef_adi()])
	var T: Array = d.get("tarih", []).duplicate()
	T.reverse()
	for x in T:
		var o := int(x.G) + int(x.B) + int(x.M)
		var sam := int(x.sam)
		r.append([sezon_adi_no(int(x.s)), int(x.sira), int(x.n), o, int(x.G), int(x.B), int(x.M), int(x.A) - int(x.Y), int(x.P),
			takim(sam).kisa if sam >= 0 else "", takim(sam).ad if sam >= 0 else "", str(x.get("kral", "")), sam == biz(), false,
			hedef_sonuc(int(x.sira), int(x.hs)) if x.has("hs") else ""])
	return r

# tarihçe özeti: "3 sezon · 1 şampiyonluk · en iyi 1."
func tarih_ozet() -> String:
	var T: Array = d.get("tarih", []) if var_mi() else []
	if T.is_empty(): return "İlk sezonun sürüyor"
	var sam := 0; var eniyi := 99
	for x in T:
		if int(x.sam) == biz(): sam += 1
		eniyi = mini(eniyi, int(x.sira))
	return "%d sezon · %d şampiyonluk · en iyi sıra %d." % [T.size(), sam, eniyi]

# tablo satırları (ekran ve VR): [sıra, kısa ad, ad, O, G, B, M, A, Y, Av, P, biz mi]
func tablo_satirlari() -> Array:
	var r: Array = []
	var t := tablo()
	for k in t.size():
		var x: Dictionary = t[k]
		r.append([k + 1, takim(x.i).kisa, takim(x.i).ad, x.O, x.G, x.B, x.M, x.A, x.Y, x.Av, x.P, x.i == biz(), x.form])
	return r

# kulübün sezon fikstürü (ekran ve VR): her hafta için [hafta, iç saha mı, rakip, bizim gol, rakip gol] (oynanmadıysa gol -1)
func fikstur_biz() -> Array:
	var r: Array = []
	if not var_mi(): return r
	var F: Array = d.fikstur
	for w in F.size():
		for mc in F[w]:
			var ev := int(mc[0]) == biz()
			if not ev and int(mc[1]) != biz(): continue
			r.append([w + 1, ev, int(mc[1]) if ev else int(mc[0]), int(mc[2]) if ev else int(mc[3]), int(mc[3]) if ev else int(mc[2])])
			break
	return r

# fikstür satırının sonucu: "G" / "B" / "M" ya da oynanmadıysa ""
static func sonuc_harf(x: Array) -> String:
	if int(x[3]) < 0: return ""
	return "G" if int(x[3]) > int(x[4]) else ("B" if int(x[3]) == int(x[4]) else "M")


# ---------- KUPALAR (Champion Battle Manager 4.6'daki gibi) ----------
# Kıta kupaları ve Kıtalar Arası Kupa: tek maçlık eleme; berabere biterse penaltılar. Katılanlar: kupanın liglerinden
# kulüp gücü × lig itibarına göre en iyiler (bir ligden en çok 4; az ligli kupada eşit pay). Kıtalar Arası: kıta kupalarının en güçlüleri.
const KUPALAR := [{"id": "avr", "ad": "Şampiyonlar Ligi", "kita": "Avrupa", "n": 16}, {"id": "kon", "ad": "Kondor Kupası", "kita": "Güney Amerika", "lg": ["br", "ar", "co"], "n": 16},
	{"id": "kuz", "ad": "Kuzey Yıldızı Kupası", "kita": "Kuzey Amerika", "lg": ["mx", "us"], "n": 16}, {"id": "ipe", "ad": "İpek Yolu Kupası", "kita": "Asya", "lg": ["sa", "jp", "kr", "qa", "cn", "au"], "n": 16},
	{"id": "sav", "ad": "Savana Kupası", "kita": "Afrika", "lg": ["eg", "ma", "za", "dz", "tn"], "n": 16}, {"id": "kit", "ad": "Kıtalar Arası Kupa", "kita": "Dünya", "n": 8}]

func kupa_tanim(id: String) -> Dictionary:
	for k in KUPALAR:
		if k.id == id: return k
	return KUPALAR[0]

func _lig_i(lid: String) -> int:
	for i in veri.ligler.size():
		if veri.ligler[i].id == lid: return i
	return -1

func kupa_takim(x: Array) -> Dictionary:
	var li := _lig_i(str(x[0]))
	if li < 0: return {}
	for t in veri.ligler[li].takimlar:
		if str(t.id) == str(x[1]): return t
	return {}

func _kupa_havuz(id: String, n := 0) -> Array:
	var K := kupa_tanim(id)
	if n == 0: n = int(K.n)
	var lgs: Array = K.get("lg", [])
	if id == "avr":
		for l in veri.ligler:
			if l.get("kita", "") == "Avrupa": lgs.append(l.id)
	var aday := []
	for lid in lgs:
		var li := _lig_i(lid)
		if li < 0: continue
		var it := float(veri.ligler[li].get("it", .6))
		for t in veri.ligler[li].takimlar: aday.append([lid, str(t.id), float(t.str) + 6.0 * it + float(posmod(hash(lid + str(t.id)), 97)) / 1000.0])
	aday.sort_custom(func(a, b): return a[2] > b[2])
	var say := {}; var sinir := maxi(4, ceili(float(n) / maxf(1.0, lgs.size())))
	var out := []
	for a in aday:
		say[a[0]] = int(say.get(a[0], 0)) + 1
		if say[a[0]] <= sinir and out.size() < n: out.append([a[0], a[1]])
	return out

func kupa_katilim(id: String) -> Array:
	if id != "kit": return _kupa_havuz(id)
	var out := []
	for p in [["avr", 3], ["kon", 2], ["kuz", 1], ["ipe", 1], ["sav", 1]]: out.append_array(_kupa_havuz(p[0], p[1]))
	return out

func kupa_var() -> bool: return not kupa.is_empty()

func kupa_tur_adi(i: int) -> String:
	var n := (kupa.esle[0] as Array).size() * 2 >> i
	return "Final" if n == 2 else ("Yarı final" if n == 4 else ("Çeyrek final" if n == 8 else "Son " + str(n)))

func kupa_basla(id: String, ben: Array) -> void:
	var t := kupa_katilim(id)
	for i in range(t.size() - 1, 0, -1):
		var j := _krng.randi() % (i + 1); var x = t[i]; t[i] = t[j]; t[j] = x
	var ilk := []
	for i in range(0, t.size(), 2): ilk.append({"a": t[i], "b": t[i + 1], "s": []})
	kupa = {"id": id, "ben": ben, "tur": 0, "esle": [ilk], "bitti": false, "elendi": false}
	kupa_kaydet()

static func _ayni(x, y) -> bool: return x is Array and y is Array and str(x[0]) == str(y[0]) and str(x[1]) == str(y[1])

func kupa_benim_mac():
	if not kupa_var() or kupa.bitti or kupa.elendi: return null
	for m in kupa.esle[int(kupa.tur)]:
		if (m.s as Array).is_empty() and (_ayni(m.a, kupa.ben) or _ayni(m.b, kupa.ben)): return m
	return null

static func kupa_kazanan(m: Dictionary):
	var s: Array = m.s
	if s.is_empty(): return null
	return m.a if (int(s[0]) > int(s[1]) or (int(s[0]) == int(s[1]) and int(s[2]) > int(s[3]))) else m.b

func kupa_kazandi() -> bool:
	if not kupa_var() or not kupa.bitti: return false
	var f: Array = kupa.esle[(kupa.esle as Array).size() - 1]
	return f.size() == 1 and _ayni(kupa_kazanan(f[0]), kupa.ben)

# [ev gol, dep gol, ev penaltı, dep penaltı] (berabere değilse penaltılar 0)
func _kupa_sim(a: Array, b: Array) -> Array:
	var A := kupa_takim(a); var B := kupa_takim(b)
	var rng := _krng
	var fa: float = float(A.get("str", 6)); var fb: float = float(B.get("str", 6))
	var x := _poisson(clampf(1.4 + (fa - fb) * .16 + .15, .25, 4.0), rng); var y := _poisson(clampf(1.1 + (fb - fa) * .16, .2, 4.0), rng)
	return [x, y] + _penalti(x, y, fa, fb, rng)

static func _penalti(x: int, y: int, fa: float, fb: float, rng: RandomNumberGenerator) -> Array:
	if x != y: return [0, 0]
	var lo := 2 + rng.randi() % 3
	return [lo + 1, lo] if rng.randf() < clampf(.5 + (fa - fb) * .05, .2, .8) else [lo, lo + 1]

func kupa_ilerle() -> void:
	var tur: Array = kupa.esle[int(kupa.tur)]
	for m in tur:
		if (m.s as Array).is_empty() and (kupa.elendi or not (_ayni(m.a, kupa.ben) or _ayni(m.b, kupa.ben))): m.s = _kupa_sim(m.a, m.b)
	for m in tur:
		if (m.s as Array).is_empty(): return
	var biz_var := false
	for m in tur:
		if _ayni(kupa_kazanan(m), kupa.ben): biz_var = true
	if not biz_var: kupa.elendi = true
	if tur.size() == 1: kupa.bitti = true; return
	var w := []
	for m in tur: w.append(kupa_kazanan(m))
	var yeni := []
	for i in range(0, w.size(), 2): yeni.append({"a": w[i], "b": w[i + 1], "s": []})
	kupa.esle.append(yeni); kupa.tur = int(kupa.tur) + 1
	if kupa.elendi: kupa_ilerle()

# kullanıcının kupa maçı bitti (biz motor T[0]); beraberlikte penaltılar güçlere göre
func kupa_sonuc(g_biz: int, g_rakip: int) -> String:
	var m = kupa_benim_mac()
	if m == null: return ""
	var biz_a := _ayni(m.a, kupa.ben)
	var rng := _krng
	var A := kupa_takim(kupa.ben); var R := kupa_takim(m.b if biz_a else m.a)
	var p := _penalti(g_biz, g_rakip, float(A.get("str", 6)), float(R.get("str", 6)), rng)
	m.s = [g_biz, g_rakip, p[0], p[1]] if biz_a else [g_rakip, g_biz, p[1], p[0]]
	kupa_ilerle(); kupa_kaydet()
	return ("Penaltılarda %d-%d %s" % [p[0], p[1], "kazandın!" if p[0] > p[1] else "kaybettin."]) if g_biz == g_rakip else ""

func kupa_sim_mac() -> void:
	var m = kupa_benim_mac()
	if m == null: return
	m.s = _kupa_sim(m.a, m.b); kupa_ilerle(); kupa_kaydet()

func kupa_kaydet() -> void:
	var f := FileAccess.open(KUPA_KAYIT, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(kupa)); f.close()

func kupa_yukle() -> void:
	kupa = {}
	if not FileAccess.file_exists(KUPA_KAYIT): return
	var j = JSON.parse_string(FileAccess.get_file_as_string(KUPA_KAYIT))
	if typeof(j) != TYPE_DICTIONARY or not j.has("esle"): return
	kupa = j
	if kupa_takim(kupa.ben).is_empty(): kupa = {}

func kupa_satirlari() -> Array:
	if not kupa_var(): return ["Kupa", "Takımın", "KUPAYA BAŞLA", "Lige dön", "Ana menü"]
	var r: Array = []
	if kupa_benim_mac() != null: r = ["MAÇA ÇIK", "Maçı simüle et"]
	if son_rapor != "": r.append("Maç raporu")
	r.append_array(["Yeni kupa" if (kupa.bitti or kupa.elendi) else "Kupayı bırak", "Lige dön", "Ana menü"])
	return r

func kupa_satir_metni(s: String, sec: bool) -> String:
	var ok := ("»  " if sec else "")
	match s:
		"Kupa": return ("‹  " if sec else "") + "Kupa:  " + KUPALAR[kur_kupa].ad + " · " + KUPALAR[kur_kupa].kita + ("  ›" if sec else "")
		"Takımın":
			var K: Array = kupa_katilim(KUPALAR[kur_kupa].id)
			var t := kupa_takim(K[posmod(kur_kupa_takim, K.size())])
			return ("‹  " if sec else "") + "Takımın:  " + str(t.get("ad", "?")) + "  (güç " + str(int(t.get("str", 0))) + ")" + ("  ›" if sec else "")
		"MAÇA ÇIK":
			var m = kupa_benim_mac()
			var rk: Dictionary = kupa_takim(m.b if _ayni(m.a, kupa.ben) else m.a)
			return ok + "MAÇA ÇIK  ·  " + kupa_tur_adi(int(kupa.tur)) + "  ·  " + str(kupa_takim(kupa.ben).kisa) + " - " + str(rk.kisa)
	return ok + s

func kupa_bas(s: String, i: int) -> String:
	match s:
		"Kupa", "Takımın": kay(i, 1)
		"KUPAYA BAŞLA":
			var K: Array = kupa_katilim(KUPALAR[kur_kupa].id)
			kupa_basla(KUPALAR[kur_kupa].id, K[posmod(kur_kupa_takim, K.size())])
		"MAÇA ÇIK": return "kupa_mac"
		"Maçı simüle et": kupa_sim_mac()
		"Maç raporu": return "rapor"
		"Lige dön": kip = "lig"; mesaj = ""
		"Ana menü": return "menu"
		"Yeni kupa": kupa = {}; kupa_kaydet()
		"Kupayı bırak":
			var simdi := Time.get_ticks_msec() / 1000.0
			if simdi - _birak_onay > 4.0: _birak_onay = simdi; mesaj = "Emin misin? Kupa silinir; bir kez daha bas"
			else: _birak_onay = 0.0; kupa = {}; kupa_kaydet(); mesaj = ""
	return ""

# eşleşme satırları (ekran ve VR): her tur için [tur adı, [[ev, skor, dep, biz mi, kazanan 0/1/-1], ...]] (son tur önce)
func kupa_turlari() -> Array:
	var out := []
	for i in range((kupa.esle as Array).size() - 1, -1, -1):
		var sat := []
		for m in kupa.esle[i]:
			var s: Array = m.s
			var sk := "–" if s.is_empty() else ("%d-%d" % [int(s[0]), int(s[1])] + ((" (p %d-%d)" % [int(s[2]), int(s[3])]) if int(s[0]) == int(s[1]) else ""))
			var w = kupa_kazanan(m)
			sat.append([str(kupa_takim(m.a).get("ad", "?")), sk, str(kupa_takim(m.b).get("ad", "?")), _ayni(m.a, kupa.ben) or _ayni(m.b, kupa.ben), -1 if w == null else (0 if _ayni(w, m.a) else 1)])
		out.append([kupa_tur_adi(i), sat])
	return out

func kupa_ozet() -> String:
	if not kupa_var(): return "Kupanı ve kulübünü seç. Tek maçlık eleme; berabere biterse penaltılar. Kazanan bir sonraki tura çıkar."
	var K := kupa_tanim(kupa.id); var ben: Dictionary = kupa_takim(kupa.ben)
	if kupa.bitti:
		if kupa_kazandi(): return "ŞAMPİYONSUN!  " + str(ben.ad) + " · " + K.ad
		var f: Array = kupa.esle[(kupa.esle as Array).size() - 1]
		return K.ad + " bitti · Şampiyon: " + str(kupa_takim(kupa_kazanan(f[0])).get("ad", "?"))
	if kupa.elendi: return str(ben.ad) + " elendi."
	return K.ad + " · " + kupa_tur_adi(int(kupa.tur)) + " · " + str(ben.ad)
