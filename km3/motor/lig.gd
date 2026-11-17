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
var gorunum := "tablo"          # sol panel: "kadro" (kulübün kadrosu), "tablo" (puan durumu), "fikstur" (kulübün sezon fikstürü), "goller" (gol krallığı), "odul" (sezon ödülleri), "ist" (lig istatistikleri), "seyir" (sezon seyri: hafta hafta sıra) ya da "tarih" (kulübün sezon sezon tarihçesi)
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
	_camia_ses()
	if bitti():
		if gorunum == "rakip": gorunum = "tablo"
		d.sampiyon = tablo()[0].i
		mesaj = "Sezon bitti · Şampiyon: " + takim(int(d.sampiyon)).ad
		if gol_krali_metni() != "": mesaj += " · Gol kralı: " + gol_krali_metni()
		if yilin_oyuncusu_metni() != "": mesaj += " · Yılın oyuncusu: " + yilin_oyuncusu_metni()
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
	var r: Array = ["YENİ SEZON", "Kulüp raporu", "Kadro", "Fikstür", "Gol krallığı", "İstatistik", "Sezon seyri", "Ödüller", "Tarihçe", "Ana menü", "Ligi bırak"] if bitti() else ["MAÇA ÇIK", "Maçı simüle et", "Rakip raporu", "Kulüp raporu", "Kadro", "Fikstür", "Gol krallığı", "İstatistik", "Sezon seyri", "Ödüller", "Tarihçe", "Ana menü", "Ligi bırak"]
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
		"Ödüller": return ok + ("Puan durumu" if gorunum == "odul" else "Ödüller")
		"İstatistik": return ok + ("Puan durumu" if gorunum == "ist" else "İstatistik")
		"Rakip raporu": return ok + ("Puan durumu" if gorunum == "rakip" else "Rakip raporu")
		"Sezon seyri": return ok + ("Puan durumu" if gorunum == "seyir" else "Sezon seyri")
	return ok + s

func kay(i: int, yon: int) -> void:
	var s: String = satirlar()[i]
	if kip == "kupa":
		if s == "Kupa": kur_kupa = posmod(kur_kupa + yon, KUPALAR.size()); kur_kupa_takim = 0
		elif s == "Takımın": kur_kupa_takim = posmod(kur_kupa_takim + yon, kupa_katilim(KUPALAR[kur_kupa].id).size())
		return
	if s == "Lig":
		kur_lig = posmod(kur_lig + yon, veri.ligler.size()); kur_takim = 0
		if str(veri.ligler[kur_lig].id) == "mt": kur_lig = posmod(kur_lig + yon, veri.ligler.size())   # milli takımlar ligde değil, Milletler Kupası'nda
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
		"Ödüller": gorunum = "tablo" if gorunum == "odul" else "odul"
		"İstatistik": gorunum = "tablo" if gorunum == "ist" else "ist"
		"Rakip raporu": gorunum = "tablo" if gorunum == "rakip" else "rakip"
		"Kulüp raporu": gorunum = "tablo" if gorunum == "kulup" else "kulup"
		"Sezon seyri": gorunum = "tablo" if gorunum == "seyir" else "seyir"
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

# ---------- sezon ödülleri: yılın oyuncusu, yılın teknik direktörü, sezonun 11'i (menajer oyunlarındaki sezon sonu ödülleri) ----------
# Her kulübün ilk 11'i (kendi kulübümüzde ana menüdeki dizilişle kurulan kadro) bir sezon puanı alır:
# yetenek + kulübün puan ortalaması ve sırası + lig golü (mevkiye göre ağırlık) + kaleci/defansta yenilen gol ortalaması.
# Sezon sürerken "ödül yarışı" gösterilir; sezon bitince kazananlar mesaja ve tarihçeye yazılır.
const ODUL_GOL := {"F": 2.0, "O": 2.6, "D": 3.2, "G": 0.0}
var _ilk11_on := {}
func _ilk11ler() -> Array:      # her kulüp için [[ad, rol, mevki, yetenek], ...]
	var a := "%d|%d|%d|%s" % [int(d.lig), int(d.sezon), biz(), diz]
	if _ilk11_on.get("a", "") != a:
		var r: Array = []
		var T: Array = lig_veri().takimlar
		for i in T.size():
			var k: Dictionary = _kadro() if i == biz() else Taktik.kadro_kur(T[i], str(lig_veri().id))
			var L: Array = []
			for o in k.get("oy", []): L.append([str(o.n), str(o.get("rol", "O")), str(o.get("mk", "")), yetenek(float(o.get("ca", 0.0)))])
			r.append(L)
		_ilk11_on = {"a": a, "r": r}
	return _ilk11_on.r

# bütün ilk 11'lerin sezon puanı, yüksekten düşüğe: [puan, ad, rol, mevki, kulüp, gol, yetenek]
func odul_puanlari() -> Array:
	var r: Array = []
	if not var_mi(): return r
	var T := tablo()
	var n := T.size()
	var bilgi := {}
	for k in n: bilgi[int(T[k].i)] = [T[k], k + 1]
	var I := _ilk11ler()
	for ti in I.size():
		var t: Dictionary = bilgi[ti][0]
		if int(t.O) == 0: continue
		var o := float(t.O)
		var takim_p := float(t.P) / o * 8.0 + float(n - int(bilgi[ti][1])) / maxf(1.0, n - 1.0) * 10.0
		var savunma := clampf((1.35 - float(t.Y) / o) * 9.0, -8.0, 9.0)
		for x in I[ti]:
			var g := int(d.goller.get(str(ti) + "|" + str(x[0]), 0))
			var rol := str(x[1])
			var p := float(x[3]) * .5 + takim_p + float(g) * float(ODUL_GOL.get(rol, 2.0)) * (34.0 / maxf(o, 1.0)) * .35
			if rol == "G": p += savunma * 1.1
			elif rol == "D": p += savunma * .75
			elif rol == "O": p += 4.0     # oyun kurucu: golü az ama oyunun yükünü taşır
			r.append([snappedf(p, .1), str(x[0]), rol, str(x[2]), ti, g, int(x[3])])
	r.sort_custom(func(a, b): return a[0] > b[0] if a[0] != b[0] else a[1] < b[1])
	return r

# yılın oyuncusu yarışı (ekran ve VR): [sıra, oyuncu, mevki kodu, kulüp kısa, kulüp ad, gol, puan, biz mi]
func yilin_oyuncusu_adaylari(n := 10) -> Array:
	var r: Array = []
	var P := odul_puanlari()
	for k in mini(n, P.size()):
		var x: Array = P[k]
		r.append([k + 1, x[1], x[3], takim(x[4]).kisa, takim(x[4]).ad, x[5], roundi(x[0]), x[4] == biz()])
	return r

func yilin_oyuncusu_metni() -> String:
	var y := yilin_oyuncusu_adaylari(1)
	return "" if y.is_empty() else "%s (%s)" % [y[0][1], y[0][3]]

# sezonun 11'i (4-3-3): en yüksek puanlı 1 kaleci, 4 defans, 3 orta saha, 3 forvet — [rol, mevki kodu, oyuncu, kulüp kısa, puan, biz mi, kulüp ad]
func sezonun_11i() -> Array:
	var r: Array = []
	var kota := {"G": 1, "D": 4, "O": 3, "F": 3}
	for x in odul_puanlari():
		var rol := str(x[2])
		if int(kota.get(rol, 0)) <= 0: continue
		kota[rol] = int(kota[rol]) - 1
		r.append([rol, x[3], x[1], takim(x[4]).kisa, roundi(x[0]), x[4] == biz(), takim(x[4]).ad])
	var sira := ["G", "D", "O", "F"]
	r.sort_custom(func(a, b): return sira.find(a[0]) < sira.find(b[0]) if a[0] != b[0] else a[4] > b[4])
	return r

# yılın teknik direktörü: güç sırasına göre beklenenin en çok üstüne çıkan kulüp (eşitlikte puan) — [kulüp, güç sırası, lig sırası] ya da []
func yilin_td() -> Array:
	if not var_mi(): return []
	var T := tablo()
	if T.is_empty() or int(T[0].O) == 0: return []
	var gs: Array = range(T.size())
	gs.sort_custom(func(a, b): return float(d.guc[a]) > float(d.guc[b]))
	var en: Array = []; var en_f := -999; var en_p := -1
	for k in T.size():
		var ti := int(T[k].i)
		var f: int = gs.find(ti) + 1 - (k + 1)
		if f > en_f or (f == en_f and int(T[k].P) > en_p): en_f = f; en_p = int(T[k].P); en = [ti, gs.find(ti) + 1, k + 1]
	return en

func yilin_td_metni() -> String:
	var y := yilin_td()
	if y.is_empty(): return ""
	return "%s  ·  güç sırası %d → ligde %d." % ["Sen · " + takim(y[0]).ad if y[0] == biz() else takim(y[0]).ad, y[1], y[2]]

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
		"A": b.A, "Y": b.Y, "sam": int(d.sampiyon), "kral": gol_krali_metni(), "hd": hedef_adi(), "hs": hedef_sira(),
		"yo": yilin_oyuncusu_metni(), "td": not yilin_td().is_empty() and int(yilin_td()[0]) == biz()})

func sonraki_sezon() -> void:
	if not var_mi(): return
	if bitti(): _tarihe_yaz()
	yeni_sezon(int(d.lig), int(d.takim), int(d.sezon) + 1, d.get("tarih", []))

# ---------- camia (Champion Battle Manager ile aynı başkan; derbi ülkeye göre) ----------
# veri/camia.json: "lig-kulüp" → [başkan, tarz, büyük kulüp mü (0/1), şehir]. Türkiye'de derbi yalnız dört büyük arasında;
# başka ülkelerde aynı şehrin kulüpleri ya da en büyükler arası. Taraftar nabzı son maçlardan, başkanın sözü maçtan sonra.
var _camia: Dictionary = {}
const TARZ := {"sabirsiz": "Sabırsız", "mali": "Mali disiplinci", "populist": "Popülist", "altyapici": "Altyapıcı", "vizyoner": "Vizyoner"}
const MEDYA := ["Manşet Spor", "Gol Gazetesi", "Saha Kenarı TV", "Tribün Sesi"]
func camia_veri() -> Dictionary:
	if _camia.is_empty():
		var f := FileAccess.get_file_as_string("res://veri/camia.json")
		var j = JSON.parse_string(f) if f != "" else null
		_camia = j if j is Dictionary else {"_": 1}
	return _camia
func _ck(i: int) -> String: return "%s-%s" % [str(lig_veri().get("id", "")), str(takim(i).get("id", ""))]
func baskan() -> Array:   # [ad, tarz adı]; veri yoksa boş
	var x = camia_veri().get(_ck(biz()))
	if x == null: return ["", ""]
	return [str(x[0]), TARZ.get(str(x[1]), "")]
func derbi_mi(a: int, b: int) -> bool:
	if a == b: return false
	var C := camia_veri(); var x = C.get(_ck(a)); var y = C.get(_ck(b))
	if x == null or y == null: return false
	if str(lig_veri().get("id", "")) == "tr": return int(x[2]) == 1 and int(y[2]) == 1
	return (str(x[3]) != "" and str(x[3]) == str(y[3])) or (int(x[2]) == 1 and int(y[2]) == 1)
func _son_sonuclar(n: int) -> Array:   # [[atılan, yenilen, derbi], ...] eskiden yeniye
	var r: Array = []
	for w in mini(int(d.hafta), hafta_sayisi()):
		for mc in d.fikstur[w]:
			var ev := int(mc[0]) == biz()
			if (not ev and int(mc[1]) != biz()) or int(mc[2]) < 0: continue
			r.append([int(mc[2]) if ev else int(mc[3]), int(mc[3]) if ev else int(mc[2]), derbi_mi(int(mc[0]), int(mc[1]))])
	return r.slice(maxi(0, r.size() - n))
func taraftar() -> int:   # taraftar nabzı (5–99)
	if not var_mi(): return 0
	var t := 55.0
	for x in _son_sonuclar(6):
		var f: int = clampi(int(x[0]) - int(x[1]), -3, 3)
		t += f * 4.0 * (2.0 if x[2] else 1.0)
	if int(d.hafta) * 2 >= hafta_sayisi(): t += (hedef_sira() - sira_biz()) * 1.5
	return clampi(roundi(t), 5, 99)
func _camia_ses() -> void:   # kullanıcının maçından sonra başkanın sözü
	var S := _son_sonuclar(3); if S.is_empty(): return
	var son: Array = S[S.size() - 1]; var ad: String = baskan()[0]
	if ad == "": return
	var a := int(son[0]); var y := int(son[1]); var soz := ""
	if son[2] and a > y: soz = "%s soyunma odasına indi: \"Bu derbi bizim!\"" % ad
	elif son[2] and a < y: soz = "%s derbiden sonra sessiz kaldı; yönetimden sızan bilgiye göre çok öfkeli." % ad
	elif S.size() == 3 and S.all(func(x): return int(x[0]) < int(x[1])):
		soz = ("%s: \"Herkes görevini sorgulamalı. Bu sonuçlar kabul edilemez.\"" % ad) if guven() < 45 or baskan()[1] == "Sabırsız" else ("%s: \"Hocamıza güvenimiz tam, bu kötü gidişi birlikte aşacağız.\"" % ad)
	elif S.size() == 3 and S.all(func(x): return int(x[0]) > int(x[1])): soz = "%s: \"Takımımızla gurur duyuyoruz.\"" % ad
	if soz != "": d.camia_soz = soz; d.camia_hafta = int(d.hafta)
func camia_sozu() -> String:   # son 3 hafta içindeki söz
	if not var_mi() or not d.has("camia_soz") or int(d.hafta) - int(d.get("camia_hafta", 0)) > 3: return ""
	return str(d.camia_soz)
func manset() -> String:   # haftanın manşeti
	if not var_mi() or int(d.hafta) == 0: return ""
	var ad: String = takim(biz()).ad; var g := guven(); var o: String = MEDYA[int(d.hafta) % MEDYA.size()]
	if g >= 70: return "%s: \"%s uçuyor!\"" % [o, ad]
	if g >= 45: return "%s: \"%s istikrar arıyor\"" % [o, ad]
	return "%s: \"%s için zor günler\"" % [o, ad]

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
	var ol := olasiliklar(e, dp)
	return 3.0 * (ol[0] if ev_biz else ol[2]) + ol[1]

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
	var td := 0
	for x in T:
		if bool(x.get("td", false)): td += 1
	return "%d sezon · %d şampiyonluk · en iyi sıra %d." % [T.size(), sam, eniyi] + ((" · %d kez yılın teknik direktörü" % td) if td > 0 else "")

# tablo satırları (ekran ve VR): [sıra, kısa ad, ad, O, G, B, M, A, Y, Av, P, biz mi]
func tablo_satirlari() -> Array:
	var r: Array = []
	var t := tablo()
	for k in t.size():
		var x: Dictionary = t[k]
		r.append([k + 1, takim(x.i).kisa, takim(x.i).ad, x.O, x.G, x.B, x.M, x.A, x.Y, x.Av, x.P, x.i == biz(), x.form])
	return r

# ---------- lig istatistikleri (menajer oyunlarının "İstatistikler" sayfası gibi) ----------
# Fikstürdeki oynanmış maçlardan: ligin rekorları + kulübün iç saha / deplasman karnesi, en farklı galibiyet / yenilgi, seri.
# Döndürür: [[tür, etiket, değer, biz], ...] — tür "b" (bölüm başlığı) ya da "s" (satır). Ayrı kayıt yok.
static func _ondalik(x: float) -> String:
	var s := "%.2f" % x
	return s if Dil.en else s.replace(".", ",")

func _skor_metni(mc: Array, w: int) -> String:
	return "%s %d-%d %s  ·  %s" % [takim(int(mc[0])).kisa, int(mc[2]), int(mc[3]), takim(int(mc[1])).kisa, ("week %d" if Dil.en else "%d. hafta") % (w + 1)]

func istatistik() -> Array:
	var r: Array = []
	if not var_mi(): return r
	var n: int = (d.takimlar as Array).size()
	var S: Array = []
	for i in n: S.append({"evp": 0, "dpp": 0, "ev": [0, 0, 0], "dp": [0, 0, 0], "sonuc": "", "gs": 0, "ys": 0})
	var mac := 0; var gol := 0; var evg := 0; var ber := 0
	var fark: Array = []; var golcu_mac: Array = []
	var biz_g: Array = []; var biz_m: Array = []
	var F: Array = d.fikstur
	for w in F.size():
		for mc in F[w]:
			var ge := int(mc[2]); var gd := int(mc[3])
			if ge < 0: continue
			mac += 1; gol += ge + gd
			var e: Dictionary = S[int(mc[0])]; var dp: Dictionary = S[int(mc[1])]
			if ge > gd: evg += 1; e.ev[0] += 1; e.evp += 3; dp.dp[2] += 1; e.sonuc += "G"; dp.sonuc += "M"
			elif ge == gd: ber += 1; e.ev[1] += 1; e.evp += 1; dp.dp[1] += 1; dp.dpp += 1; e.sonuc += "B"; dp.sonuc += "B"
			else: e.ev[2] += 1; dp.dp[0] += 1; dp.dpp += 3; e.sonuc += "M"; dp.sonuc += "G"
			var fk := absi(ge - gd)
			if fark.is_empty() or fk > int(fark[0]) or (fk == int(fark[0]) and ge + gd > int(fark[1])): fark = [fk, ge + gd, mc, w]
			if golcu_mac.is_empty() or ge + gd > int(golcu_mac[0]): golcu_mac = [ge + gd, mc, w]
			for yan in 2:
				if int(mc[yan]) != biz(): continue
				var a := ge if yan == 0 else gd; var y := gd if yan == 0 else ge
				if a > y and (biz_g.is_empty() or a - y > int(biz_g[0]) or (a - y == int(biz_g[0]) and a > int(biz_g[1]))): biz_g = [a - y, a, mc, w]
				if a < y and (biz_m.is_empty() or y - a > int(biz_m[0]) or (y - a == int(biz_m[0]) and y > int(biz_m[1]))): biz_m = [y - a, y, mc, w]
	if mac == 0: return r
	var T := tablo()
	var en_iyi := func(anahtar: Callable, buyuk := true) -> Array:   # [takım, değer]; eşitlikte tablodaki sıra
		var best := -1; var bv := 0
		for x in T:
			var v: int = anahtar.call(int(x.i))
			if best < 0 or (v > bv if buyuk else v < bv): best = int(x.i); bv = v
		return [best, bv]
	var seri := func(i: int, harfler: String, son := false) -> int:   # en uzun (ya da sondaki) seri
		var s: String = S[i].sonuc; var en := 0; var k := 0
		for c in s:
			k = k + 1 if harfler.contains(c) else 0; en = maxi(en, k)
		return k if son else en
	var ad := func(i: int) -> String: return takim(i).ad
	r.append(["b", "LİG REKORLARI", "", false])
	var x: Array = en_iyi.call(func(i): return int(T.filter(func(t): return int(t.i) == i)[0].A))
	r.append(["s", "En golcü takım (gol)", "%s  ·  %d" % [ad.call(x[0]), x[1]], x[0] == biz()])
	x = en_iyi.call(func(i): return int(T.filter(func(t): return int(t.i) == i)[0].Y), false)
	r.append(["s", "En sağlam savunma (yenilen gol)", "%s  ·  %d" % [ad.call(x[0]), x[1]], x[0] == biz()])
	x = en_iyi.call(func(i): return int(S[i].evp))
	r.append(["s", "İç sahanın en iyisi (puan)", "%s  ·  %d" % [ad.call(x[0]), x[1]], x[0] == biz()])
	x = en_iyi.call(func(i): return int(S[i].dpp))
	r.append(["s", "Deplasmanın en iyisi (puan)", "%s  ·  %d" % [ad.call(x[0]), x[1]], x[0] == biz()])
	x = en_iyi.call(func(i):
		var p := 0
		for c in (S[i].sonuc as String).right(5): p += 3 if c == "G" else (1 if c == "B" else 0)
		return p)
	r.append(["s", "Formda takım (son 5 maçta puan)", "%s  ·  %d" % [ad.call(x[0]), x[1]], x[0] == biz()])
	x = en_iyi.call(func(i): return seri.call(i, "G"))
	r.append(["s", "En uzun galibiyet serisi (maç)", "%s  ·  %d" % [ad.call(x[0]), x[1]], x[0] == biz()])
	x = en_iyi.call(func(i): return seri.call(i, "GB"))
	r.append(["s", "En uzun yenilmezlik serisi (maç)", "%s  ·  %d" % [ad.call(x[0]), x[1]], x[0] == biz()])
	r.append(["s", "En farklı skor", _skor_metni(fark[2], int(fark[3])), int(fark[2][0]) == biz() or int(fark[2][1]) == biz()])
	r.append(["s", "En gollü maç", _skor_metni(golcu_mac[1], int(golcu_mac[2])), int(golcu_mac[1][0]) == biz() or int(golcu_mac[1][1]) == biz()])
	r.append(["s", "Maç başına gol", _ondalik(float(gol) / mac), false])
	r.append(["s", "Ev sahibi · beraberlik · deplasman", "%s  ·  %s  ·  %s" % [yuzde(roundi(100.0 * evg / mac)), yuzde(roundi(100.0 * ber / mac)), yuzde(roundi(100.0 * (mac - evg - ber) / mac))], false])
	var b: Dictionary = S[biz()]
	r.append(["b", takim(biz()).ad, "", true])
	r.append(["s", "İç saha (G-B-M · puan)", "%d-%d-%d  ·  %d" % [b.ev[0], b.ev[1], b.ev[2], b.evp], true])
	r.append(["s", "Deplasman (G-B-M · puan)", "%d-%d-%d  ·  %d" % [b.dp[0], b.dp[1], b.dp[2], b.dpp], true])
	r.append(["s", "En farklı galibiyetimiz", _skor_metni(biz_g[2], int(biz_g[3])) if not biz_g.is_empty() else "—", true])
	r.append(["s", "En ağır yenilgimiz", _skor_metni(biz_m[2], int(biz_m[3])) if not biz_m.is_empty() else "—", true])
	var son: String = (b.sonuc as String).right(1)
	var adlar := {"G": "galibiyet", "B": "beraberlik", "M": "yenilgi"}
	if Dil.en: adlar = {"G": "win", "B": "draw", "M": "defeat"}
	var sn: int = seri.call(biz(), son, true) if son != "" else 0
	r.append(["s", "Süren seri", ("%d %s%s" % [sn, adlar[son], "s" if Dil.en and sn > 1 else ""]) if son != "" else "—", true])
	r.append(["s", "Yenilmezlik serisi (en uzun · şu an)", "%d  ·  %d" % [seri.call(biz(), "GB"), seri.call(biz(), "GB", true)], true])
	return r

# ---------- rakip raporu (menajer oyunlarının maç önü "scout" sayfası; Champion Battle Manager 4.9.6 maç analizi / 4.9.7 scout) ----------
# Sıradaki rakip: sırası, formu, iç saha / deplasman karnesi, gol ortalamaları, en golcüsü, dizilişi ve yıldızı;
# karşılaştırma: güç, sim_mac modeliyle galibiyet / beraberlik / yenilgi olasılığı, beklenen puan, ilk devredeki maç ve asistanın önerisi.
# Biçim istatistik() ile aynı: [[tür, etiket, değer, vurgu], ...]. Ayrı kayıt yok.
func olasiliklar(e: int, dp: int) -> Array:   # ev sahibinin [galibiyet, beraberlik, yenilgi] olasılığı (sim_mac'in Poisson modeli)
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
	return [g, b, m]

static func form_metni(f: String) -> String:
	var r: PackedStringArray = []
	for c in f: r.append({"G": "W", "B": "D", "M": "L"}[c] if Dil.en else c)
	return " ".join(r) if r.size() > 0 else "—"

func rakip_raporu() -> Array:
	var r: Array = []
	var mc := sonraki_mac()
	if mc.is_empty(): return r
	var ev := int(mc[0]) == biz()
	var rk: int = int(mc[1]) if ev else int(mc[0])
	var T := tablo()
	var x: Dictionary = {}; var sira := 0
	for k in T.size():
		if int(T[k].i) == rk: x = T[k]; sira = k + 1
	# rakibin iç saha / deplasman karnesi ve ilk devredeki maçımız
	var ic := [0, 0, 0]; var dis := [0, 0, 0]; var onceki := ""
	var F: Array = d.fikstur
	for w in F.size():
		for m in F[w]:
			var ge := int(m[2]); var gd := int(m[3])
			if ge < 0: continue
			if int(m[0]) == rk: ic[0 if ge > gd else (1 if ge == gd else 2)] += 1
			elif int(m[1]) == rk: dis[0 if gd > ge else (1 if ge == gd else 2)] += 1
			if (int(m[0]) == rk and int(m[1]) == biz()) or (int(m[1]) == rk and int(m[0]) == biz()): onceki = _skor_metni(m, w)
	var kd := Taktik.kadro_kur(takim(rk), str(lig_veri().id))
	var yildiz := ""; var yy := -1
	for o in kd.get("oy", []):
		var yt := yetenek(float(o.get("ca", 0.0)))
		if yt > yy: yy = yt; yildiz = "%s · %s · %d" % [mevki_adi(str(o.get("mk", ""))), str(o.n), yt]
	var golcu := ""
	for g in gol_krallari(999):
		if g[2] == takim(rk).kisa and g[3] == takim(rk).ad: golcu = "%s  ·  %d" % [g[1], g[4]]; break
	var om := maxi(1, int(x.O))
	r.append(["b", "SIRADAKİ RAKİP  ·  " + takim(rk).ad, "", false])
	r.append(["s", "Maç", ("%d. hafta" % (int(d.hafta) + 1) if not Dil.en else "week %d" % (int(d.hafta) + 1)) + "  ·  " + ("iç saha" if ev else "deplasman"), false])
	r.append(["s", "Sıra · puan", "%d.  ·  %d" % [sira, int(x.P)], false])
	r.append(["s", "O G B M · averaj", "%d %d %d %d  ·  %s%d" % [x.O, x.G, x.B, x.M, "+" if int(x.Av) > 0 else "", int(x.Av)], false])
	r.append(["s", "Son 5 maç", form_metni(x.form), false])
	if ev: r.append(["s", "Deplasmanda (G-B-M)", "%d-%d-%d" % dis, false])
	else: r.append(["s", "Evinde (G-B-M)", "%d-%d-%d" % ic, false])
	r.append(["s", "Maç başına attığı · yediği", ("%s  ·  %s" % [_ondalik(float(x.A) / om), _ondalik(float(x.Y) / om)]) if int(x.O) > 0 else "—", false])
	r.append(["s", "En golcüsü", golcu if golcu != "" else "—", false])
	r.append(["s", "Dizilişi", str(kd.get("dzAd", "—")), false])
	r.append(["s", "Yıldızı", yildiz if yildiz != "" else "—", false])
	r.append(["b", "MAÇ ANALİZİ", "", true])
	var gb: float = d.guc[biz()]; var gr: float = d.guc[rk]
	r.append(["s", "Güç (biz · rakip)", "%d  ·  %d" % [roundi(gb), roundi(gr)], true])
	var ol := olasiliklar(int(mc[0]), int(mc[1]))
	var bg: float = ol[0] if ev else ol[2]; var bm: float = ol[2] if ev else ol[0]
	r.append(["s", "Galibiyet · beraberlik · yenilgi", "%s  ·  %s  ·  %s" % [yuzde(roundi(100 * bg)), yuzde(roundi(100 * ol[1])), yuzde(roundi(100 * bm))], true])
	r.append(["s", "Beklenen puan", _ondalik(beklenen_puan(int(mc[0]), int(mc[1]), ev)), true])
	r.append(["s", "İlk devredeki maç", onceki if onceki != "" else "—", true])
	var fark := gb - gr + (3.0 if ev else -3.0)
	r.append(["s", "Asistanın önerisi", "Oyun anlayışı: " + ("Hücum" if fark >= 6.0 else ("Savunma" if fark <= -6.0 else "Dengeli")), true])
	return r

# ---------- kulüp raporu (Champion Battle Manager'ın aylık kulüp raporunun karşılığı): her birim kendi bölümünü yazar ----------
# Yönetim, taraftar ve medya, teknik ekip (kadro), maç önü ve senden beklenenler. Satırlar istatistik ekranıyla aynı biçimde.
func kulup_raporu() -> Array:
	var r: Array = []
	if not var_mi(): return r
	var g := guven(); var t := taraftar(); var sira := sira_biz(); var hs := hedef_sira()
	var bk := baskan()
	r.append(["b", "YÖNETİM", "", false])
	if bk[0] != "": r.append(["s", "Başkan", "%s  ·  %s" % [bk[0], bk[1]], false])
	r.append(["s", "Güven", "%s  ·  %s" % [guven_adi(g), yuzde(g)], false])
	r.append(["s", "Hedef · şu an", "%s  ·  %d." % [hedef_adi(), sira], false])
	r.append(["b", "TARAFTAR VE MEDYA", "", false])
	r.append(["s", "Taraftar nabzı", yuzde(t), false])
	var S := _son_sonuclar(5); var f := ""
	for x in S: f += "G" if int(x[0]) > int(x[1]) else ("B" if int(x[0]) == int(x[1]) else "M")
	r.append(["s", "Son 5 maç", form_metni(f) if f != "" else "—", false])
	var dg := 0; var dk := 0
	for x in _son_sonuclar(99):
		if x[2]: dk += 1; dg += 1 if int(x[0]) > int(x[1]) else 0
	if dk > 0: r.append(["s", "Derbiler (kazanılan · oynanan)", "%d  ·  %d" % [dg, dk], false])
	var ms := manset(); if ms != "": r.append(["n", "📰 " + ms, "", false])
	r.append(["b", "TEKNİK EKİP", "", true])
	var K := kadro_satirlari(); var en_iyi := ""; var ey := -1
	for x in K:
		if int(x[3]) > ey: ey = int(x[3]); en_iyi = "%s · %s · %d" % [mevki_adi(str(x[1])), str(x[2]), int(x[3])]
	r.append(["s", "Diziliş · ilk 11", kadro_ozet() if kadro_ozet() != "" else "—", true])
	r.append(["s", "Takımın yıldızı", en_iyi if en_iyi != "" else "—", true])
	var gk := gol_krallari(999); var golcu := "—"
	for x in gk:
		if x[2] == takim(biz()).kisa and x[3] == takim(biz()).ad: golcu = "%s  ·  %d" % [x[1], x[4]]; break
	r.append(["s", "En golcümüz", golcu, true])
	var mc := sonraki_mac()
	if not mc.is_empty():
		var ev := int(mc[0]) == biz(); var rk: int = int(mc[1]) if ev else int(mc[0])
		var ol := olasiliklar(int(mc[0]), int(mc[1]))
		r.append(["s", "Sıradaki maç", "%s  ·  %s%s" % [takim(rk).ad, "iç saha" if ev else "deplasman", "  ·  ⚔ DERBİ" if derbi_mi(int(mc[0]), int(mc[1])) else ""], true])
		r.append(["s", "Kazanma olasılığı", yuzde(roundi(100 * (ol[0] if ev else ol[2]))), true])
	r.append(["b", "SENDEN BEKLENENLER", "", false])
	var bek: Array = []
	if int(d.hafta) >= 5 and sira > hs: bek.append(("We are %d places behind the target; the board expects a recovery." if Dil.en else "Hedefin %d sıra gerisindeyiz; yönetim toparlanma bekliyor.") % (sira - hs))
	if g < 40: bek.append("Board confidence is low; the next matches are critical." if Dil.en else "Yönetimin güveni düşük; önümüzdeki maçlar kritik.")
	if t < 40: bek.append("The fans are restless; a home win is a must." if Dil.en else "Taraftar huzursuz; iç sahada galibiyet şart.")
	if not mc.is_empty() and derbi_mi(int(mc[0]), int(mc[1])): bek.append("The next match is a derby: the game of the season for the club." if Dil.en else "Sıradaki maç derbi: camia için sezonun maçı.")
	if bek.is_empty(): bek.append("Nothing pending; all in order." if Dil.en else "Şu an bekleyen bir şey yok; işler yolunda.")
	for x in bek: r.append(["n", "• " + x, "", false])
	return r

# ---------- sezon seyri (menajer oyunlarının "lig sırası" grafiği): her haftanın sonundaki sıra ve puan ----------
# Kayıt gerekmez: fikstürdeki skorlardan hafta hafta yeniden kurulur. Sıralama tablo() ile aynı (puan, averaj, atılan, ad).
func sira_gecmisi() -> Array:   # [{"w": hafta, "s": [kulüp → sıra], "p": [kulüp → puan]}, ...] yalnız oynanan haftalar
	var r: Array = []
	if not var_mi(): return r
	var n: int = (d.takimlar as Array).size()
	var P: Array = []; var A: Array = []; var Y: Array = []
	for i in n: P.append(0); A.append(0); Y.append(0)
	var F: Array = d.fikstur
	for w in mini(int(d.hafta), F.size()):
		for mc in F[w]:
			var ge := int(mc[2]); var gd := int(mc[3])
			if ge < 0: continue
			var e := int(mc[0]); var dp := int(mc[1])
			A[e] += ge; Y[e] += gd; A[dp] += gd; Y[dp] += ge
			if ge > gd: P[e] += 3
			elif ge == gd: P[e] += 1; P[dp] += 1
			else: P[dp] += 3
		var s: Array = range(n)
		s.sort_custom(func(x, y):
			if P[x] != P[y]: return P[x] > P[y]
			var ax: int = A[x] - Y[x]; var ay: int = A[y] - Y[y]
			if ax != ay: return ax > ay
			if A[x] != A[y]: return A[x] > A[y]
			return takim(x).ad < takim(y).ad)
		var sira: Array = []; sira.resize(n)
		for k in n: sira[s[k]] = k + 1
		r.append({"w": w + 1, "s": sira, "p": P.duplicate()})
	return r

# grafik için: {"n": kulüp sayısı, "biz": [sıra...], "lider": [sıra...], "lider_ad": kısa ad, "hedef": hedef sırası, "hafta": toplam hafta}
func seyir_grafik() -> Dictionary:
	var G := sira_gecmisi()
	if G.is_empty(): return {}
	var lid := int(tablo()[0].i)
	var b: Array = []; var l: Array = []
	for x in G: b.append(int(x.s[biz()])); l.append(int(x.s[lid]))
	return {"n": (d.takimlar as Array).size(), "biz": b, "lider": l if lid != biz() else [], "lider_ad": takim(lid).kisa, "hedef": hedef_sira(), "hafta": hafta_sayisi()}

# sezon seyri satırları (ekran ve VR; istatistik() biçimi): [[tür, etiket, değer, vurgu], ...]
func sezon_seyri() -> Array:
	var r: Array = []
	var G := sira_gecmisi()
	if G.is_empty(): return r
	var b := biz()
	var en_iyi := 99; var en_iyi_w := 0; var en_kotu := 0; var en_kotu_w := 0; var zirve := 0
	for x in G:
		var s := int(x.s[b])
		if s < en_iyi: en_iyi = s; en_iyi_w = int(x.w)
		if s > en_kotu: en_kotu = s; en_kotu_w = int(x.w)
		if s == 1: zirve += 1
	var T := tablo()
	var sira := sira_biz(); var biz_p := int(T[sira - 1].P); var oyn := maxi(1, int(T[sira - 1].O))
	var hf := func(w: int) -> String: return ("week %d" % w) if Dil.en else ("%d. hafta" % w)
	r.append(["b", "SEZON SEYRİ  ·  " + takim(b).ad, "", true])
	r.append(["s", "Şu anki sıra · puan", "%d.  ·  %d" % [sira, biz_p], true])
	r.append(["s", "En iyi sıra", "%d.  ·  %s" % [en_iyi, hf.call(en_iyi_w)], true])
	r.append(["s", "En kötü sıra", "%d.  ·  %s" % [en_kotu, hf.call(en_kotu_w)], true])
	r.append(["s", "Zirvede geçen hafta", str(zirve), true])
	if sira == 1:
		var fk: int = biz_p - int(T[1].P) if T.size() > 1 else 0
		r.append(["s", "Lidere fark (puan)", ("leader  ·  %+d over 2nd" if Dil.en else "lider  ·  ikinciyle %+d") % fk, true])
	else:
		r.append(["s", "Lidere fark (puan)", "%d  ·  %s" % [int(T[0].P) - biz_p, takim(int(T[0].i)).ad], true])
	var hs := clampi(hedef_sira(), 1, T.size())
	var hd := ""
	if sira <= hs:
		var alt: int = biz_p - int(T[hs].P) if hs < T.size() else biz_p
		hd = ("on track  ·  %+d over place %d" if Dil.en else "tutuyor  ·  %d.'ye %+d") % ([alt, hs + 1] if Dil.en else [hs + 1, alt])
	else:
		hd = ("%d points behind place %d" if Dil.en else "%d. sıranın %d puan gerisinde") % ([int(T[hs - 1].P) - biz_p, hs] if Dil.en else [hs, int(T[hs - 1].P) - biz_p])
	r.append(["s", "Hedef (" + hedef_adi() + ")", hd, true])
	var toplam := fikstur_biz().size()
	r.append(["s", "Puan ortalaması · sezon sonu tahmini", "%s  ·  %d" % [_ondalik(float(biz_p) / oyn), roundi(float(biz_p) / oyn * toplam)], true])
	r.append(["b", "HAFTA HAFTA SIRA", "", false])
	var k := 0
	while k < G.size():
		var son := mini(k + 6, G.size())
		var parca: PackedStringArray = []
		for j in range(k, son): parca.append(str(int(G[j].s[b])))
		var et := ("Weeks %d–%d" % [k + 1, son]) if Dil.en else ("%d.–%d. hafta" % [k + 1, son])
		if son == k + 1: et = hf.call(k + 1)
		r.append(["s", et, "  ".join(parca), false])
		k = son
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
	{"id": "sav", "ad": "Savana Kupası", "kita": "Afrika", "lg": ["eg", "ma", "za", "dz", "tn"], "n": 16}, {"id": "kit", "ad": "Kıtalar Arası Kupa", "kita": "Dünya", "n": 8},
	{"id": "mil", "ad": "Milletler Kupası", "kita": "Milli takımlar", "lg": ["mt"], "n": 32, "grup": true}]
# Milletler Kupası (KM3 0.10.6): 32 milli takım, 8 grup × 4 (torbalar güce göre), tek devre; grubunda ilk iki olan
# Son 16'ya çıkar (1A-2B, 1C-2D, … 1B-2A), sonra tek maçlık eleme. Grup durumu kupa.gruplar / kupa.gm / kupa.gtur

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

func grupta() -> bool: return kupa_var() and kupa.has("gruplar") and (kupa.esle as Array).is_empty()

func kupa_tur_adi(i: int) -> String:
	if grupta(): return "Grup %d/3" % (int(kupa.get("gtur", 0)) + 1)
	var n := (kupa.esle[0] as Array).size() * 2 >> i
	return "Final" if n == 2 else ("Yarı final" if n == 4 else ("Çeyrek final" if n == 8 else "Son " + str(n)))

func kupa_basla(id: String, ben: Array) -> void:
	var t := kupa_katilim(id)
	for i in range(t.size() - 1, 0, -1):
		var j := _krng.randi() % (i + 1); var x = t[i]; t[i] = t[j]; t[j] = x
	if bool(kupa_tanim(id).get("grup", false)): _grup_kur(id, ben, t); kupa_kaydet(); return
	var ilk := []
	for i in range(0, t.size(), 2): ilk.append({"a": t[i], "b": t[i + 1], "s": []})
	kupa = {"id": id, "ben": ben, "tur": 0, "esle": [ilk], "bitti": false, "elendi": false}
	kupa_kaydet()

const GRUP_HARF := "ABCDEFGH"
const GRUP_TUR := [[[0, 1], [2, 3]], [[0, 2], [3, 1]], [[3, 0], [1, 2]]]   # dört takımlı grupta üç maç günü
# kura: güce göre dört torba (her torbadan her gruba bir takım), torba içi karışık
func _grup_kur(id: String, ben: Array, t: Array) -> void:
	t = t.duplicate()
	t.sort_custom(func(a, b): return float(kupa_takim(a).get("str", 0)) > float(kupa_takim(b).get("str", 0)))
	var ng := t.size() / 4
	var gruplar := []
	for g in ng: gruplar.append([])
	for tor in 4:
		var torba: Array = t.slice(tor * ng, (tor + 1) * ng)
		for i in range(torba.size() - 1, 0, -1):
			var j := _krng.randi() % (i + 1); var x = torba[i]; torba[i] = torba[j]; torba[j] = x
		for g in ng: gruplar[g].append(torba[g])
	var gm := []
	for r in 3:
		var gun := []
		for g in ng:
			for e in GRUP_TUR[r]: gun.append({"g": g, "a": gruplar[g][e[0]], "b": gruplar[g][e[1]], "s": []})
		gm.append(gun)
	kupa = {"id": id, "ben": ben, "tur": 0, "esle": [], "bitti": false, "elendi": false, "gruplar": gruplar, "gm": gm, "gtur": 0}

# grubun puan durumu: [{"t": takım, O, G, B, M, A, Y, Av, P}, ...] sıralı (puan, averaj, atılan gol, güç)
func grup_tablosu(g: int) -> Array:
	var T := []
	for x in kupa.gruplar[g]: T.append({"t": x, "O": 0, "G": 0, "B": 0, "M": 0, "A": 0, "Y": 0, "Av": 0, "P": 0})
	for gun in kupa.gm:
		for m in gun:
			if int(m.g) != g or (m.s as Array).is_empty(): continue
			for r in T:
				var yan := 0 if _ayni(r.t, m.a) else (1 if _ayni(r.t, m.b) else -1)
				if yan < 0: continue
				var a := int(m.s[yan]); var y := int(m.s[1 - yan])
				r.O += 1; r.A += a; r.Y += y; r.Av = r.A - r.Y
				if a > y: r.G += 1; r.P += 3
				elif a == y: r.B += 1; r.P += 1
				else: r.M += 1
	T.sort_custom(func(x, y):
		if x.P != y.P: return x.P > y.P
		if x.Av != y.Av: return x.Av > y.Av
		if x.A != y.A: return x.A > y.A
		return float(kupa_takim(x.t).get("str", 0)) > float(kupa_takim(y.t).get("str", 0)))
	return T

func grubum() -> int:
	if not kupa_var() or not kupa.has("gruplar"): return -1
	for g in (kupa.gruplar as Array).size():
		for x in kupa.gruplar[g]:
			if _ayni(x, kupa.ben): return g
	return -1

# grup satırları (ekran ve VR): her grup için ["GRUP A", [[sıra, ad, O, G, B, M, A, Y, Av, P, biz, çıktı mı], ...]]; bizim grup önce
func grup_satirlari() -> Array:
	var out := []
	if not kupa_var() or not kupa.has("gruplar"): return out
	var sira := [grubum()]
	for g in (kupa.gruplar as Array).size():
		if g != sira[0]: sira.append(g)
	var bitti_mi := not grupta()
	for g in sira:
		if g < 0: continue
		var sat := []
		var T := grup_tablosu(g)
		for k in T.size():
			var r: Dictionary = T[k]
			sat.append([k + 1, str(kupa_takim(r.t).get("ad", "?")), r.O, r.G, r.B, r.M, r.A, r.Y, r.Av, r.P, _ayni(r.t, kupa.ben), bitti_mi and k < 2])
		out.append(["GRUP " + GRUP_HARF[g], sat])
	return out

# bizim grubun maçları: [[gün, ev, skor, dep], ...]
func grup_maclarim() -> Array:
	var out := []; var g := grubum()
	if g < 0: return out
	for r in (kupa.gm as Array).size():
		for m in kupa.gm[r]:
			if int(m.g) != g: continue
			var s: Array = m.s
			out.append([r + 1, str(kupa_takim(m.a).get("kisa", "?")), "–" if s.is_empty() else "%d-%d" % [int(s[0]), int(s[1])], str(kupa_takim(m.b).get("kisa", "?")), _ayni(m.a, kupa.ben) or _ayni(m.b, kupa.ben)])
	return out

# grup maç günü bitti: sonraki gün ya da Son 16 eşleşmeleri (1A-2B, 1C-2D, 1E-2F, 1G-2H, 1B-2A, 1D-2C, 1F-2E, 1H-2G)
func _grup_ilerle() -> void:
	var gun: Array = kupa.gm[int(kupa.gtur)]
	for m in gun:
		if (m.s as Array).is_empty() and (kupa.elendi or not (_ayni(m.a, kupa.ben) or _ayni(m.b, kupa.ben))): m.s = _kupa_sim(m.a, m.b).slice(0, 2); _kupa_gol_mac(m)
	for m in gun:
		if (m.s as Array).is_empty(): return
	if int(kupa.gtur) < 2: kupa.gtur = int(kupa.gtur) + 1; return
	var ilk2 := []
	for g in (kupa.gruplar as Array).size():
		var T := grup_tablosu(g); ilk2.append([T[0].t, T[1].t])
	var ilk := []
	for p in [[0, 1], [2, 3], [4, 5], [6, 7], [1, 0], [3, 2], [5, 4], [7, 6]]:
		if p[0] < ilk2.size() and p[1] < ilk2.size(): ilk.append({"a": ilk2[p[0]][0], "b": ilk2[p[1]][1], "s": []})
	var cikti := false
	for m in ilk:
		if _ayni(m.a, kupa.ben) or _ayni(m.b, kupa.ben): cikti = true
	kupa.esle = [ilk]; kupa.tur = 0
	if not cikti:
		kupa.elendi = true; kupa_ilerle()

static func _ayni(x, y) -> bool: return x is Array and y is Array and str(x[0]) == str(y[0]) and str(x[1]) == str(y[1])

func kupa_benim_mac():
	if not kupa_var() or kupa.bitti or kupa.elendi: return null
	var liste: Array = kupa.gm[int(kupa.gtur)] if grupta() else kupa.esle[int(kupa.tur)]
	for m in liste:
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
	if grupta(): _grup_ilerle(); return
	var tur: Array = kupa.esle[int(kupa.tur)]
	for m in tur:
		if (m.s as Array).is_empty() and (kupa.elendi or not (_ayni(m.a, kupa.ben) or _ayni(m.b, kupa.ben))): m.s = _kupa_sim(m.a, m.b); _kupa_gol_mac(m)
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
func kupa_sonuc(g_biz: int, g_rakip: int, golcuk: Array = []) -> String:
	var m = kupa_benim_mac()
	if m == null: return ""
	var biz_a := _ayni(m.a, kupa.ben)
	_kupa_gol_biz(m, g_biz, g_rakip, golcuk)
	var rng := _krng
	var A := kupa_takim(kupa.ben); var R := kupa_takim(m.b if biz_a else m.a)
	if grupta():
		m.s = [g_biz, g_rakip] if biz_a else [g_rakip, g_biz]
		kupa_ilerle(); kupa_kaydet()
		return _grup_haberi()
	var p := _penalti(g_biz, g_rakip, float(A.get("str", 6)), float(R.get("str", 6)), rng)
	m.s = [g_biz, g_rakip, p[0], p[1]] if biz_a else [g_rakip, g_biz, p[1], p[0]]
	kupa_ilerle(); kupa_kaydet()
	return ("Penaltılarda %d-%d %s" % [p[0], p[1], "kazandın!" if p[0] > p[1] else "kaybettin."]) if g_biz == g_rakip else ""

func kupa_sim_mac() -> void:
	var m = kupa_benim_mac()
	if m == null: return
	var gr := grupta()
	m.s = _kupa_sim(m.a, m.b)
	if gr: m.s = (m.s as Array).slice(0, 2)
	_kupa_gol_mac(m)
	kupa_ilerle(); kupa_kaydet()
	mesaj = _grup_haberi() if gr else ""

# grup bitince kullanıcıya: çıktı mı, elendi mi
func _grup_haberi() -> String:
	if grupta() or not kupa.has("gruplar"): return ""
	if kupa.elendi: return "Gruptan çıkamadın."
	return "Gruptan çıktın! Son 16'dasın."

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
	if not kupa_var():
		if bool(KUPALAR[kur_kupa].get("grup", false)): return "32 milli takım, 8 grup. Grubunda ilk iki olan Son 16'ya çıkar; sonrası tek maçlık eleme, berabere biterse penaltılar."
		return "Kupanı ve kulübünü seç. Tek maçlık eleme; berabere biterse penaltılar. Kazanan bir sonraki tura çıkar."
	var K := kupa_tanim(kupa.id); var ben: Dictionary = kupa_takim(kupa.ben)
	if kupa.bitti:
		var gk := kupa_gol_krali_metni()
		gk = ("\nGol kralı: " + gk) if gk != "" else ""
		if kupa_kazandi(): return "ŞAMPİYONSUN!  " + str(ben.ad) + " · " + K.ad + gk
		var f: Array = kupa.esle[(kupa.esle as Array).size() - 1]
		return K.ad + " bitti · Şampiyon: " + str(kupa_takim(kupa_kazanan(f[0])).get("ad", "?")) + gk
	if kupa.elendi: return str(ben.ad) + " elendi."
	if grupta():
		var T := grup_tablosu(grubum()); var s := 0
		for k in T.size():
			if _ayni(T[k].t, kupa.ben): s = k + 1
		return K.ad + " · Grup " + GRUP_HARF[grubum()] + " (%d/3) · " % (int(kupa.gtur) + 1) + str(ben.ad) + " %d. (%d puan)" % [s, int(T[s - 1].P)]
	return K.ad + " · " + kupa_tur_adi(int(kupa.tur)) + " · " + str(ben.ad)

# ---------- kupa gol krallığı (0.10.7) ----------
# kupa.goller: "lig|kulüp|oyuncu" → gol. Simüle maçlarda goller kadroya mevkiye göre paylaştırılır (lig gibi);
# kullanıcının maçında motorun gol olayları yazılır. Penaltı atışları sayılmaz.
var _kupa_golcu := {}
func _kupa_golculer(x: Array) -> Array:
	var k := str(x[0]) + "|" + str(x[1])
	if not _kupa_golcu.has(k):
		var t := kupa_takim(x)
		_kupa_golcu[k] = [] if t.is_empty() else _golcu_listesi(Taktik.kadro_kur(t, str(x[0])))
	return _kupa_golcu[k]

func _kupa_gol_yaz(x: Array, ad: String, n := 1) -> void:
	if not kupa.has("goller"): kupa.goller = {}
	var k := str(x[0]) + "|" + str(x[1]) + "|" + ad
	kupa.goller[k] = int(kupa.goller.get(k, 0)) + n

func _kupa_gol_dagit(x: Array, n: int) -> void:
	var G := _kupa_golculer(x)
	if G.is_empty(): return
	var top := 0.0
	for g in G: top += float(g[1])
	for _k in n:
		var r := _krng.randf() * top
		for g in G:
			r -= float(g[1])
			if r <= 0.0: _kupa_gol_yaz(x, str(g[0])); break

func _kupa_gol_mac(m: Dictionary) -> void:
	var s: Array = m.s
	if s.size() < 2: return
	_kupa_gol_dagit(m.a, int(s[0])); _kupa_gol_dagit(m.b, int(s[1]))

# kullanıcının maçı: motorun gol olayları (team 0 = biz); olay yoksa simüle maç gibi paylaştır
func _kupa_gol_biz(m: Dictionary, g_biz: int, g_rakip: int, golcuk: Array) -> void:
	var rk: Array = m.b if _ayni(m.a, kupa.ben) else m.a
	if golcuk.is_empty():
		_kupa_gol_dagit(kupa.ben, g_biz); _kupa_gol_dagit(rk, g_rakip); return
	for e in golcuk:
		var ad := str(e.get("n", ""))
		if ad == "" or ad.begins_with("Kendi kalesine"): continue
		_kupa_gol_yaz(kupa.ben if int(e.get("team", 0)) == 0 else rk, ad)

# [sıra, oyuncu, kulüp kısa adı, kulüp, gol, biz mi] — eşit golde aynı sıra
func kupa_gol_krallari(n := 10) -> Array:
	var L: Array = []
	if not kupa_var(): return L
	for k in kupa.get("goller", {}):
		var p := (k as String).split("|", true, 2)
		if p.size() < 3: continue
		L.append([[p[0], p[1]], p[2], int(kupa.goller[k])])
	L.sort_custom(func(a, b): return a[2] > b[2] if a[2] != b[2] else a[1] < b[1])
	var r: Array = []
	var sira := 0
	for k in mini(n, L.size()):
		if k == 0 or L[k][2] != L[k - 1][2]: sira = k + 1
		var t := kupa_takim(L[k][0])
		r.append([sira, L[k][1], str(t.get("kisa", "?")), str(t.get("ad", "?")), L[k][2], _ayni(L[k][0], kupa.ben)])
	return r

func kupa_gol_krali_metni() -> String:
	var g := kupa_gol_krallari(1)
	if g.is_empty(): return ""
	return "%s (%s) %d" % [g[0][1], g[0][2], g[0][4]]
