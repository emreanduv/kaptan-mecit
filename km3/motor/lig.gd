# Kaptan Mecit 3 — lig modu: tam sezon fikstürü (çift devreli, her takım her takımla bir içeride bir dışarıda),
# puan tablosu (O G B M A Y Av P), kullanıcının haftalık maçı; diğer maçlar Taktik kadroları ve güç değerleriyle hızlı simüle.
# Kayıt: user://km3-lig.json ("Verilerimi sil" bunu da siler). Ekran (arayuz/lig_ekran.gd) ve VR (vr/vr.gd) aynı satırları kullanır.
extends RefCounted
class_name Lig

const KAYIT := "user://km3-lig.json"
const SURUM := 1

var veri: Dictionary            # takimlar.json
var d: Dictionary = {}          # sezon durumu (boşsa sezon yok)
var kur_lig := 0                # kurulum ekranında seçilen lig / takım
var kur_takim := 0
var mesaj := ""
var _birak_onay := 0.0
var son_hafta: Array = []       # en son oynanan haftanın maçları (ekranda "Haftanın sonuçları")
var gorunum := "tablo"          # sol panel: "tablo" (puan durumu) ya da "fikstur" (kulübün sezon fikstürü)

func _init(v: Dictionary) -> void:
	veri = v
	yukle()

# ---------- kayıt ----------
func var_mi() -> bool: return not d.is_empty()

func yukle() -> void:
	d = {}
	if not FileAccess.file_exists(KAYIT): return
	var j = JSON.parse_string(FileAccess.get_file_as_string(KAYIT))
	if typeof(j) != TYPE_DICTIONARY or int(j.get("surum", 0)) != SURUM: return
	# bozuk / eski kayıt: lig ya da takım artık yoksa yok say
	var li := int(j.get("lig", -1))
	if li < 0 or li >= veri.ligler.size(): return
	if (j.get("takimlar", []) as Array).size() != veri.ligler[li].takimlar.size(): return
	d = j
	if int(d.hafta) > 0: son_hafta = d.fikstur[int(d.hafta) - 1]

func kaydet() -> void:
	if d.is_empty(): return
	var f := FileAccess.open(KAYIT, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d)); f.close()

func sil() -> void:
	d = {}; son_hafta = []; mesaj = ""; gorunum = "tablo"
	if FileAccess.file_exists(KAYIT): DirAccess.remove_absolute(ProjectSettings.globalize_path(KAYIT))

# ---------- sezon ----------
func lig_veri() -> Dictionary: return veri.ligler[int(d.lig)] if var_mi() else veri.ligler[kur_lig]
func takim(i: int) -> Dictionary: return lig_veri().takimlar[i]
func biz() -> int: return int(d.takim)
func hafta_sayisi() -> int: return (d.fikstur as Array).size()
func bitti() -> bool: return int(d.hafta) >= hafta_sayisi()

func yeni_sezon(lig: int, tk: int, sezon := 1) -> void:
	var L: Array = veri.ligler[lig].takimlar
	var n := L.size()
	# güç: asistanın kurduğu ilk 11'in mevkiye uyumlu ortalama yeteneği (Taktik), yoksa kulübün güç puanından
	var guc: Array = []
	for t in L:
		var k := Taktik.kadro_kur(t, veri.ligler[lig].id)
		guc.append(snappedf(float(k.get("guc", 40.0 + 9.0 * float(t.str))), .01))
	d = {"surum": SURUM, "lig": lig, "takim": tk, "sezon": sezon, "hafta": 0, "takimlar": range(n),
		"guc": guc, "fikstur": fikstur_uret(n, randi()), "sampiyon": -1}
	son_hafta = []
	mesaj = ""
	kaydet()

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
func kullanici_sonuc(g_biz: int, g_rakip: int) -> void:
	var mc := sonraki_mac()
	if mc.is_empty(): return
	if int(mc[0]) == biz(): mc[2] = g_biz; mc[3] = g_rakip
	else: mc[2] = g_rakip; mc[3] = g_biz
	hafta_bitir()

func hafta_bitir() -> void:
	var rng := RandomNumberGenerator.new(); rng.randomize()
	var h: Array = d.fikstur[int(d.hafta)]
	for mc in h:
		if int(mc[2]) < 0:
			var s := sim_mac(int(mc[0]), int(mc[1]), rng)
			mc[2] = s[0]; mc[3] = s[1]
	son_hafta = h
	d.hafta = int(d.hafta) + 1
	if bitti():
		d.sampiyon = tablo()[0].i
		mesaj = "Sezon bitti · Şampiyon: " + takim(int(d.sampiyon)).ad
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
	if not var_mi(): return ["Lig", "Takımın", "SEZONA BAŞLA", "Ana menü"]
	if bitti(): return ["YENİ SEZON", "Fikstür", "Ana menü", "Ligi bırak"]
	return ["MAÇA ÇIK", "Maçı simüle et", "Fikstür", "Ana menü", "Ligi bırak"]

func satir_metni(i: int, sec := false) -> String:
	var s: String = satirlar()[i]
	var ok := ("▶  " if sec else "")
	match s:
		"Lig": return ("‹  " if sec else "") + "Lig:  " + veri.ligler[kur_lig].ad + " · " + veri.ligler[kur_lig].ulke + ("  ›" if sec else "")
		"Takımın":
			var t: Dictionary = veri.ligler[kur_lig].takimlar[kur_takim]
			return ("‹  " if sec else "") + "Takımın:  " + t.ad + "  (güç " + str(int(t.str)) + ")" + ("  ›" if sec else "")
		"MAÇA ÇIK":
			var mc := sonraki_mac()
			return ok + "MAÇA ÇIK  ·  " + takim(int(mc[0])).kisa + " - " + takim(int(mc[1])).kisa
		"YENİ SEZON": return ok + "YENİ SEZON  ·  " + str(int(d.sezon) + 1) + ". sezon"
		"Fikstür": return ok + ("Fikstür" if gorunum == "tablo" else "Puan durumu")
	return ok + s

func kay(i: int, yon: int) -> void:
	var s: String = satirlar()[i]
	if s == "Lig": kur_lig = posmod(kur_lig + yon, veri.ligler.size()); kur_takim = 0
	elif s == "Takımın": kur_takim = posmod(kur_takim + yon, veri.ligler[kur_lig].takimlar.size())

# döndürür: "mac" (maça çık), "menu" (ana menüye dön) ya da ""
func bas(i: int) -> String:
	var s: String = satirlar()[i]
	match s:
		"Lig", "Takımın": kay(i, 1)
		"SEZONA BAŞLA": yeni_sezon(kur_lig, kur_takim)
		"MAÇA ÇIK": return "mac"
		"Maçı simüle et": haftayi_simule()
		"Fikstür": gorunum = "fikstur" if gorunum == "tablo" else "tablo"
		"YENİ SEZON":
			var lg := int(d.lig); var tk := int(d.takim); var sz := int(d.sezon) + 1
			yeni_sezon(lg, tk, sz)
		"Ana menü": gorunum = "tablo"; return "menu"
		"Ligi bırak":
			var simdi := Time.get_ticks_msec() / 1000.0
			if simdi - _birak_onay > 4.0:
				_birak_onay = simdi; mesaj = "Emin misin? Sezon silinir; bir kez daha bas"
			else:
				_birak_onay = 0.0; kur_lig = int(d.lig); kur_takim = int(d.takim); sil()
	return ""

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
