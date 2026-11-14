class_name Duzen
# Düzenleme modu (PES'teki "option file" usulü): oyuncu kulüp adını, kısa adı, renkleri, oyuncu adlarını ve
# forma numaralarını kendi cihazında değiştirir; değişiklikler bir paket metni olarak dışa aktarılıp paylaşılabilir,
# başkasının paketi içe aktarılabilir. Oyunun kendi verisi (res://veri/takimlar.json) hiç değişmez; düzenleme
# yüklenince üstüne uygulanır. Haftalık kadro güncellemesinde oyuncu sırası değişebileceği için oyuncu
# düzenlemeleri oyunun verdiği ada bağlanır (o oyuncu kulüpten ayrılırsa düzenlemesi sessizce uygulanmaz).
#
# Kayıt: { "t": { kulüp_kimliği: { "ad", "kisa", "c1", "c2", "o": { özgün_ad: { "n", "no" } } } }, "l": { lig_kimliği: ad } }

const KAYIT := "user://duzen.json"
const PAKET_BAS := "KMPAKET1 "

static var d: Dictionary = {"t": {}, "l": {}}
static var _orijinal: Dictionary = {}     # kulüp/lig kimliği → özgün alanlar (sıfırlamak için)

static func yukle() -> void:
	d = {"t": {}, "l": {}}
	if not FileAccess.file_exists(KAYIT): return
	var j = JSON.parse_string(FileAccess.get_file_as_string(KAYIT))
	if j is Dictionary:
		d.t = j.get("t", {}) if j.get("t") is Dictionary else {}
		d.l = j.get("l", {}) if j.get("l") is Dictionary else {}

static func kaydet() -> void:
	var f := FileAccess.open(KAYIT, FileAccess.WRITE)
	if f: f.store_string(JSON.stringify(d))

static func bos_mu() -> bool:
	return d.t.is_empty() and d.l.is_empty()

# Düzenlemeleri oyun verisinin üstüne uygular (yerinde; Lig ve menüler aynı sözlükleri tuttuğu için referanslar bozulmaz).
# Her çağrıda önce özgün değerlere döner, sonra düzenlemeyi koyar: sıfırlama ve paket değişimi de bununla çalışır.
static func uygula(veri: Dictionary) -> void:
	for lg in veri.get("ligler", []):
		var lk := "l:" + str(lg.id)
		if not _orijinal.has(lk): _orijinal[lk] = {"ad": lg.ad}
		lg.ad = str(d.l.get(str(lg.id), _orijinal[lk].ad))
		for t in lg.takimlar:
			var tk := "t:" + str(t.id)
			if not _orijinal.has(tk):
				var oy := []
				for o in t.oy: oy.append({"n": o.n, "no": o.no})
				_orijinal[tk] = {"ad": t.ad, "kisa": t.kisa, "c1": t.c1, "c2": t.c2, "oy": oy}
			var oz: Dictionary = _orijinal[tk]
			var e: Dictionary = d.t.get(str(t.id), {})
			t.ad = str(e.get("ad", oz.ad)); t.kisa = str(e.get("kisa", oz.kisa))
			t.c1 = str(e.get("c1", oz.c1)); t.c2 = str(e.get("c2", oz.c2))
			var eo: Dictionary = e.get("o", {})
			for i in t.oy.size():
				if i >= oz.oy.size(): break
				var ozg: Dictionary = oz.oy[i]; var o: Dictionary = t.oy[i]
				var x: Dictionary = eo.get(ozg.n, {})
				o.n = str(x.get("n", ozg.n)); o.no = int(x.get("no", ozg.no))

static func ozgun_ad(t: Dictionary, i: int) -> String:
	var oz = _orijinal.get("t:" + str(t.id))
	return str(oz.oy[i].n) if oz and i < oz.oy.size() else str(t.oy[i].n)

static func ozgun(t: Dictionary) -> Dictionary:
	return _orijinal.get("t:" + str(t.id), {})

# Bir kulübün düzenlemesini yazar (özgünle aynı alanlar kaydedilmez, kayıt küçük kalır)
static func takim_yaz(t: Dictionary, ad: String, kisa: String, c1: String, c2: String, oyuncular: Array) -> void:
	var oz := ozgun(t)
	var e := {}
	if ad.strip_edges() != "" and ad != oz.get("ad"): e.ad = ad.strip_edges().left(40)
	if kisa.strip_edges() != "" and kisa != oz.get("kisa"): e.kisa = kisa.strip_edges().to_upper().left(4)
	if c1 != oz.get("c1"): e.c1 = c1
	if c2 != oz.get("c2"): e.c2 = c2
	var eo := {}
	for i in mini(oyuncular.size(), oz.get("oy", []).size()):
		var ozg: Dictionary = oz.oy[i]; var y: Dictionary = oyuncular[i]
		var x := {}
		if str(y.n).strip_edges() != "" and str(y.n) != str(ozg.n): x.n = str(y.n).strip_edges().left(28)
		if int(y.no) != int(ozg.no) and int(y.no) >= 1 and int(y.no) <= 99: x.no = int(y.no)
		if not x.is_empty(): eo[str(ozg.n)] = x
	if not eo.is_empty(): e.o = eo
	if e.is_empty(): d.t.erase(str(t.id))
	else: d.t[str(t.id)] = e

static func lig_yaz(lg: Dictionary, ad: String) -> void:
	var oz = _orijinal.get("l:" + str(lg.id), {"ad": lg.ad})
	if ad.strip_edges() == "" or ad == oz.ad: d.l.erase(str(lg.id))
	else: d.l[str(lg.id)] = ad.strip_edges().left(40)

static func takim_sifirla(t: Dictionary) -> void:
	d.t.erase(str(t.id))

static func hepsini_sifirla() -> void:
	d = {"t": {}, "l": {}}

# Paylaşılabilir paket metni: tek satır, başında sürüm imi
static func paket_metni() -> String:
	return PAKET_BAS + JSON.stringify(d)

# Başkasının paketini içe aktarır (üstüne yazar, kendi diğer düzenlemelerin kalır). Dönüş: kaç kulüp/lig geldi, -1 = geçersiz.
static func paket_al(metin: String) -> int:
	var m := metin.strip_edges()
	var i := m.find(PAKET_BAS.strip_edges())
	if i < 0: return -1
	m = m.substr(i + PAKET_BAS.strip_edges().length()).strip_edges()
	var j = JSON.parse_string(m)
	if not (j is Dictionary): return -1
	var n := 0
	var jt = j.get("t", {}); var jl = j.get("l", {})
	if jt is Dictionary:
		for k in jt:
			if jt[k] is Dictionary: d.t[str(k)] = _temiz(jt[k]); n += 1
	if jl is Dictionary:
		for k in jl: d.l[str(k)] = str(jl[k]).left(40); n += 1
	return n

# İçe aktarılan veriyi yalnız bilinen alanlara indir (başka bir şey gelmesin)
static func _temiz(e: Dictionary) -> Dictionary:
	var r := {}
	for k in ["ad", "kisa", "c1", "c2"]:
		if e.has(k): r[k] = str(e[k]).left(40)
	if r.has("kisa"): r.kisa = str(r.kisa).left(4)
	for k in ["c1", "c2"]:
		if r.has(k) and not Color.html_is_valid(str(r[k])): r.erase(k)
	if e.get("o") is Dictionary:
		var o := {}
		for ad in e.o:
			var x = e.o[ad]
			if not (x is Dictionary): continue
			var y := {}
			if x.has("n"): y.n = str(x.n).left(28)
			if x.has("no") and int(x.no) >= 1 and int(x.no) <= 99: y.no = int(x.no)
			if not y.is_empty(): o[str(ad).left(40)] = y
		if not o.is_empty(): r.o = o
	return r
