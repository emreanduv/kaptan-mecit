# Kaptan Mecit 3 — mola ekranı (yedek kulübesi) ve oyuncu rehberi. Ekranda da VR'da da aynı satırlar kullanılır:
# ana.gd düz ekran paneli çizer, vr.gd 3B paneli; ikisi de buradaki metni okur, buradaki eylemleri çağırır.
extends RefCounted
class_name Mola

const SATIRLAR := ["DEVAM ET", "Çıkan", "Giren", "DEĞİŞİKLİĞİ YAP", "Asistan değişiklikleri", "Kamera", "Nasıl oynanır", "MAÇI BIRAK"]
const MEVKI := {"G": "kaleci", "D": "defans", "O": "orta saha", "F": "forvet"}
const ROL := {"G": "kaleci", "D": "defans", "O": "orta saha", "F": "forvet"}
const BIZ := 0

var ana
var cikan := 0
var giren := 0
var mesaj := ""

func _init(a) -> void: ana = a

func _sahadakiler() -> Array:
	var a: Array = ana.M.P.filter(func(p): return p.team == BIZ)
	# önce sakatlar, sonra en yorgunlar
	a.sort_custom(func(x, y): return (10.0 if x.inj else 0.0) + 1.0 - x.st > (10.0 if y.inj else 0.0) + 1.0 - y.st)
	return a

# kulübe, çıkacak oyuncunun mevkisine göre sıralı: aynı mevki önce, kaleci yalnız kaleci çıkarken öne gelir
func _kulube() -> Array:
	var b: Array = ana.M.B[BIZ].duplicate()
	var p = secili_cikan()
	if p == null: return b
	var puan := func(x) -> int: return (0 if x.mevki == p.role else 1) + (4 if (x.mevki == "G") != (p.role == "G") else 0)
	b.sort_custom(func(x, y): return puan.call(x) < puan.call(y))
	return b

func secili_cikan():
	var a := _sahadakiler()
	return a[posmod(cikan, a.size())] if a.size() > 0 else null

func secili_giren():
	var b := _kulube()
	return b[posmod(giren, b.size())] if b.size() > 0 else null

func deger(i: int) -> String:
	var M = ana.M
	match i:
		1:
			var p = secili_cikan()
			if p == null: return "-"
			return "%d %s · %s · kondisyon %%%d%s" % [p.no, p.n, ROL.get(p.role, ""), int(round(p.st * 100)), "  · SAKAT" if p.inj else ""]
		2:
			var b = secili_giren()
			if b == null: return "kulübede kimse kalmadı"
			return "%d %s · %s" % [int(b.no), b.n, MEVKI.get(b.mevki, "")]
		3:
			var k: Dictionary = M.kalan(BIZ)
			if not M.degisebilir(BIZ): return "şu an yapılamaz (%d hak kaldı)" % k.hak if k.hak > 0 else "hak kalmadı"
			return "%d hak · %d ara kaldı" % [k.hak, maxi(0, k.ara)]
		4: return "Açık" if M.asistan[BIZ] else "Kapalı (sakatlıkta yine girer)"
		5: return ana.vr.KOLTUKLAR[ana.vr.koltuk] if ana.vr else ana.KAMERALAR[ana.kam_mod]
	return ""

func satir_metni(i: int, secili: bool) -> String:
	var d := deger(i)
	var ad: String = ("Koltuk" if ana.vr else "Kamera") if i == 5 else SATIRLAR[i]
	if i in [1, 2, 4, 5]: return ("‹  " if secili else "") + ad + ":  " + d + ("  ›" if secili else "")
	return ("»  " if secili else "") + SATIRLAR[i] + (("   ·   " + d) if d != "" else "")

func kay(i: int, d: int) -> void:
	match i:
		1: cikan += d; giren = 0
		2: giren += d
		4: ana.M.asistan[BIZ] = not ana.M.asistan[BIZ]
		5:
			if ana.vr: ana.vr.koltuga_gec(ana.vr.koltuk + d)
			else: ana._kamera(posmod(ana.kam_mod + d, ana.KAMERALAR.size()))

func bas(i: int) -> void:
	var M = ana.M
	match i:
		0: ana.menu_goster(false)
		1, 2: kay(i, 1)
		3:
			var p = secili_cikan(); var b = secili_giren()
			if p != null and b != null and M.degistir(BIZ, p, b, "TEKNİK DİREKTÖR"):
				mesaj = "%d %s oyuna girdi, %s çıktı" % [int(b.no), b.n, M.degisiklikler.back().out]
				ana.mola_bilgi(mesaj)
				cikan = 0; giren = 0
			else:
				ana.mola_bilgi("Değişiklik şu an yapılamıyor")
		4, 5: kay(i, 1)
		6: ana.yardim_goster(not ana.yardim_acik)
		7: ana.maci_birak()

# ---------- rehber: ilk maçlarda, yeri gelince bir kez gösterilen ipuçları ----------
const AYAR := "user://km3-ayar.cfg"
const IPUCU := {
	"kos": ["KOŞ", "Sol çubuk: baktığın yöne koş", "WASD / oklar ya da sol çubuk: koş", "Ekranın soluna parmağını koy ve kaydır: koş"],
	"pas": ["PAS VE ŞUT", "A ya da tetik: pas  ·  B ya da kavrama: şut", "X: pas  ·  Z / boşluk: şut", "Sağ altta PAS ve ŞUT"],
	"guc": ["BASILI TUT", "Şut tuşunu ne kadar tutarsan şut o kadar sert  ·  pası basılı tutup bırak: ara pas", "Z'yi ne kadar tutarsan şut o kadar sert  ·  X'i basılı tutup bırak: ara pas", "ŞUT'u ne kadar tutarsan şut o kadar sert  ·  PAS'ı basılı tutup bırak: ara pas"],
	"kap": ["TOPU KAP", "Topu kapmak için rakibin üstüne koş, şut tuşu: kayarak müdahale", "Rakibin üstüne koş, Z / boşluk: kayarak müdahale", "Rakibin üstüne koş, ŞUT: kayarak müdahale"],
	"koltuk": ["KOLTUK", "Sağ çubuk sola/sağa ya da X: başka bir koltuğa geç", "C: kamerayı değiştir", "Kamerayı molada değiştirebilirsin"],
	"mola": ["MOLA", "Menü düğmesi: mola, oyuncu değişikliği ve Nasıl oynanır", "M / Esc: mola, oyuncu değişikliği ve Nasıl oynanır", "Üstteki II: mola, oyuncu değişikliği ve Nasıl oynanır"],
}
var _gorulen := {}
var _sira: Array = []
var _bekle := 0.0

func rehber_yukle() -> void:
	var c := ConfigFile.new()
	if c.load(AYAR) == OK: _gorulen = c.get_value("rehber", "gorulen", {})

# Verilerimi sil: cihazda tutulan tek dosyayı (rehber ipuçları) siler. İlk çağrı onay ister, 4 sn içinde ikincisi siler.
var _sil_onay := 0.0
func veri_sil() -> String:
	var simdi := Time.get_ticks_msec() / 1000.0
	if simdi - _sil_onay > 4.0:
		_sil_onay = simdi
		return "Emin misin? Silmek için bir kez daha bas"
	_sil_onay = 0.0
	if FileAccess.file_exists(AYAR): DirAccess.remove_absolute(ProjectSettings.globalize_path(AYAR))
	_gorulen = {}; _sira.clear()
	ana.lig.sil()     # lig sezonu kaydı da
	return "Cihazdaki verilerin silindi"

func rehber_sifirla() -> void:
	_gorulen = {}; _kaydet()

func _kaydet() -> void:
	var c := ConfigFile.new(); c.load(AYAR)
	c.set_value("rehber", "gorulen", _gorulen); c.save(AYAR)

func ipucu(ad: String) -> void:
	if _gorulen.has(ad) or _sira.has(ad): return
	_sira.append(ad)

# her karede: maç durumuna göre ipucunu sıraya koy, sıradakini afişte göster
func rehber(dt: float, kip: int) -> void:     # kip: 0 ekran, 1 VR, 2 dokunmatik
	var M = ana.M
	if M == null or M.demo or ana.menu_acik: return
	if M.state == "play":
		ipucu("kos")
		if M.ball.owner != null:
			if M.ball.owner.team == BIZ and M.ball.owner == M.ctrl:
				ipucu("pas")
				if M.clock > 20: ipucu("guc")
			elif M.ball.owner.team != BIZ and M.clock > 8: ipucu("kap")
		if M.clock > 40: ipucu("koltuk")
		if M.clock > 75: ipucu("mola")
	_bekle -= dt
	if _bekle > 0 or _sira.is_empty(): return
	var ad: String = _sira.pop_front()
	var t: Array = IPUCU[ad]
	ana.afis_goster(t[0], [t[2], t[1], t[3]][kip], 4.0)
	_gorulen[ad] = true; _kaydet()
	_bekle = 6.0

const YARDIM := """NASIL OYNANIR

Seçili oyuncun ayağının altındaki sarı halkadır. Top sende değilken
pas tuşu, topa en yakın oyuncuna geçer.

VR (Quest):  sol çubuk koş  ·  A / tetik pas  ·  B / kavrama şut ve kayarak
müdahale  ·  sağ çubuk ya da X: koltuk  ·  menü düğmesi: mola
Dokunmatik:  ekranın solunda parmakla koş  ·  sağ altta PAS / ŞUT  ·  üstte II mola
Ekran:  WASD / oklar koş  ·  X pas  ·  Z / boşluk şut  ·  C kamera  ·  M mola
Oyun kolu:  sol çubuk koş  ·  A pas  ·  B şut  ·  Y kamera  ·  Start mola
Şut tuşunu ne kadar tutarsan şut o kadar sert; pas tuşunu basılı tutup
bırakırsan ara pas (top arkadaşının önündeki boşluğa gider).

Kurallar:  faul, avantaj, sarı / kırmızı kart, penaltı, ofsayt ve VAR var.
Duran topta rakip 9,15 m uzakta bekler; serbest vuruşta baraj kurulur.
Arkadan ve kutu içinde kayarak müdahale karta gider.
Oyuncular yorulur: molada kondisyonlarına bakıp değişiklik yap
(5 hak, devre arası dışında 3 ara). Asistanı kapatırsan değişiklikler senin.

Verilerin: oyun seninle ilgili hiçbir veri toplamaz; cihazda yalnızca
gördüğün ipuçları tutulur. Silmek için: Verilerimi sil.
Görüş ve öneri: emreanduvart@gmail.com"""
