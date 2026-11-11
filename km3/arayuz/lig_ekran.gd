# Kaptan Mecit 3 — lig ekranı (düz ekran): menajer oyunlarının klasik koyu "panel + tablo" düzeni.
# Üstte kulüp renginde başlık şeridi; solda puan durumu (O G B M A Y Av P, form), sağda sonraki maç, haftanın sonuçları ve eylemler.
# Satırlar / eylemler Lig'den gelir (VR paneli de aynılarını kullanır).
extends PanelContainer
class_name LigEkran

const ZEMIN := Color("#1c2026")
const PANEL := Color("#262b33")
const SERIT := Color("#343c48")
const SATIR_A := Color("#2b3139")
const SATIR_B := Color("#252a31")
const BIZ_RENK := Color("#2f5d8c")
const YAZI := Color("#e6ebf0")
const SOLUK := Color("#93a3b5")
const ALTIN := Color("#f3d35a")
const YESIL := Color("#3ec46d")
const KIRMIZI := Color("#d9534f")
const SUTUNLAR := ["O", "G", "B", "M", "A", "Y", "Av", "P"]

var lig: Lig
var satir := 0
var dugmeler: Array = []
var _govde: Control
var dikey := false   # dik telefon: tablo üstte, sağ panel altta, kaydırılır
var ust := 0.0
signal eylem(ad: String)

func _init(l: Lig) -> void:
	lig = l
	set_anchors_preset(Control.PRESET_FULL_RECT)
	add_theme_stylebox_override("panel", _kutu(ZEMIN, 0, 0))
	visible = false

func yenile() -> void:
	if _govde: _govde.queue_free()
	dugmeler.clear()
	var mv := VBoxContainer.new(); mv.add_theme_constant_override("separation", 0)
	_govde = mv; add_child(mv)
	if ust > 0:
		var bos := ColorRect.new(); bos.color = SERIT; bos.custom_minimum_size = Vector2(0, ust); mv.add_child(bos)
	mv.add_child(_baslik())
	var ic := MarginContainer.new(); ic.size_flags_vertical = Control.SIZE_EXPAND_FILL
	for k in ["left", "right", "top", "bottom"]: ic.add_theme_constant_override("margin_" + k, 14)
	var hb := BoxContainer.new(); hb.vertical = dikey; hb.add_theme_constant_override("separation", 14)
	# küçük ekranda (telefon) tablo ekrana sığmaz: gövde her zaman parmakla kaydırılır
	var sc := ScrollContainer.new(); sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	mv.add_child(sc); sc.add_child(ic); ic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	ic.add_child(hb)
	var sol: Control = _kupa_panel() if lig.kip == "kupa" else _tablo_panel()
	if lig.kip == "kupa": pass
	elif lig.var_mi() and lig.gorunum == "fikstur": sol = _fikstur_panel()
	elif lig.var_mi() and lig.gorunum == "goller": sol = _goller_panel()
	elif lig.var_mi() and lig.gorunum == "kadro": sol = _kadro_panel()
	elif lig.var_mi() and lig.gorunum == "tarih": sol = _tarih_panel()
	if dikey:
		hb.add_child(_sag_panel()); hb.add_child(sol)
	else:
		hb.add_child(sol); hb.add_child(_sag_panel())
	satir = mini(satir, lig.satirlar().size() - 1)
	ciz()

# seçili satırı ve mesajı tazele (her tuşta yeniden kurmadan)
func ciz() -> void:
	var S := lig.satirlar()
	for i in dugmeler.size():
		var b: Button = dugmeler[i]
		var sec := i == satir
		b.text = lig.satir_metni(i, sec)
		if S[i] in ["Lig", "Takımın", "Kupa"]: b.text = b.text.trim_prefix("‹  ").trim_suffix("  ›")   # okları yandaki düğmeler gösterir
		var ana_eylem: bool = S[i] in ["MAÇA ÇIK", "SEZONA BAŞLA", "YENİ SEZON"]
		if ((S[i] == "Kadro" and lig.gorunum == "kadro") or (S[i] == "Fikstür" and lig.gorunum == "fikstur") or (S[i] == "Gol krallığı" and lig.gorunum == "goller") or (S[i] == "Tarihçe" and lig.gorunum == "tarih")) and not sec:   # açık görünüm sekmesi
			b.add_theme_stylebox_override("normal", _kutu(Color("#3d4a5c"), 6, 7)); b.add_theme_color_override("font_color", ALTIN); continue
		var c := ALTIN if sec else (Color("#e5722f") if ana_eylem else SERIT)
		b.add_theme_stylebox_override("normal", _kutu(c, 6, 7))
		b.add_theme_color_override("font_color", Color("#1d2b2c") if sec else (Color.WHITE if ana_eylem else YAZI))
	if _mesaj: _mesaj.text = lig.mesaj if lig.mesaj != "" else ("Kulübüne listeden dokun ya da ‹ › ile seç" if not lig.var_mi() else "Oklar: satır ve değer  ·  Enter: seç  ·  Esc: ana menü")

var _mesaj: Label

func _baslik() -> Control:
	if lig.kip == "kupa": return _kupa_baslik()
	var var_mi := lig.var_mi()
	var t: Dictionary = lig.takim(lig.biz()) if var_mi else lig.veri.ligler[lig.kur_lig].takimlar[lig.kur_takim]
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _kutu(Color(t.c1), 0, 12))
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 16); p.add_child(hb)
	var yazi_renk := Color(t.c2) if Mac.renk_farki(t.c1, t.c2) > 128 else Color.WHITE
	var ad := _etiket(t.ad, 26, yazi_renk); hb.add_child(ad)
	var lg := lig.lig_veri()
	var alt: String = "LİG  ·  " + lg.ad + " · " + lg.ulke
	if var_mi:
		alt += "  ·  " + lig.sezon_adi() + " sezonu  ·  " + ("Sezon bitti" if lig.bitti() else "Hafta %d / %d" % [int(lig.d.hafta) + 1, lig.hafta_sayisi()])
	else:
		alt += "  ·  Yeni sezon: kulübünü seç"
	var al := _etiket(alt, 17, yazi_renk); al.size_flags_horizontal = Control.SIZE_EXPAND_FILL; al.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	if dikey: al.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; al.custom_minimum_size.x = 120
	hb.add_child(al)
	if var_mi:
		var sr := _etiket("%d." % lig.sira_biz(), 26, yazi_renk); hb.add_child(sr)
	return p

func _tablo_panel() -> Control:
	var p := PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _kutu(PANEL, 6, 0))
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 0); p.add_child(v)
	v.add_child(_serit("PUAN DURUMU" if lig.var_mi() else "KULÜPLER  ·  güç sırasıyla"))
	if lig.var_mi():
		v.add_child(_tablo_satir(["#", "Takım"] + SUTUNLAR + ["Form"], -1, true, false, ""))
		var R := lig.tablo_satirlari()
		for r in R:
			var vals: Array = [str(r[0]), r[2]]
			for k in range(3, 11): vals.append(("+" if k == 9 and int(r[k]) > 0 else "") + str(r[k]))
			vals.append("")     # form sütunu
			v.add_child(_tablo_satir(vals, int(r[0]), false, r[11], r[12], R.size()))
	else:
		v.add_child(_tablo_satir(["#", "Takım", "", "", "", "", "", "", "", "Güç", ""], -1, true, false, ""))
		var L: Array = lig.veri.ligler[lig.kur_lig].takimlar.duplicate()
		var biz: Dictionary = L[lig.kur_takim]
		L.sort_custom(func(a, b): return int(a.str) > int(b.str))
		var tum: Array = lig.veri.ligler[lig.kur_lig].takimlar
		for k in L.size():
			var sat := _tablo_satir([str(k + 1), L[k].ad, "", "", "", "", "", "", "", str(int(L[k].str)), ""], 0, false, L[k] == biz, "")
			var ti: int = tum.find(L[k])
			sat.mouse_filter = Control.MOUSE_FILTER_PASS
			var bas := {"p": Vector2(-999, -999)}
			sat.gui_input.connect(func(e):
				# kaydırırken yanlışlıkla seçilmesin: basılan yerde bırakılırsa seç
				if e is InputEventMouseButton and e.button_index == MOUSE_BUTTON_LEFT:
					if e.pressed: bas.p = e.global_position
					elif e.global_position.distance_to(bas.p) < 14:
						lig.kur_takim = ti; lig.mesaj = ""; yenile())
			v.add_child(sat)
	return p

# kulübün sezon fikstürü: menajer oyunlarındaki gibi iki devre yan yana (dik ekranda alt alta).
# Satır: hafta · İ/D · rakip (sırası) · skor · sonuç; sıradaki maç vurgulu, oynanan maçlar G/B/M renginde.
func _fikstur_panel() -> Control:
	var p := PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _kutu(PANEL, 6, 0))
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 0); p.add_child(v)
	var F := lig.fikstur_biz()
	var G := 0; var B := 0; var M := 0
	for x in F:
		match Lig.sonuc_harf(x):
			"G": G += 1
			"B": B += 1
			"M": M += 1
	v.add_child(_serit("FİKSTÜR  ·  %s  ·  %dG %dB %dM" % [lig.takim(lig.biz()).ad, G, B, M]))
	var sira := {}
	for r in lig.tablo_satirlari(): sira[r[1]] = int(r[0])
	var iki := BoxContainer.new(); iki.vertical = dikey; iki.add_theme_constant_override("separation", 0 if dikey else 10)
	v.add_child(iki)
	var yari := (F.size() + 1) / 2
	var simdi := int(lig.d.hafta) + 1
	for dv in 2:
		var dvv := VBoxContainer.new(); dvv.add_theme_constant_override("separation", 0); dvv.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		iki.add_child(dvv)
		dvv.add_child(_fik_satir(["%d. DEVRE" % (dv + 1), "", "", "", ""], 0, true, false, ""))
		for k in range(dv * yari, mini((dv + 1) * yari, F.size())):
			var x: Array = F[k]
			var rk: Dictionary = lig.takim(int(x[2]))
			var rad: String = rk.ad + "  (%d.)" % int(sira.get(rk.kisa, 0))
			var skor := "%d - %d" % [int(x[3]), int(x[4])] if int(x[3]) >= 0 else ("–" if int(x[0]) != simdi else "SIRADA")
			dvv.add_child(_fik_satir([str(x[0]), "İ" if x[1] else "D", rad, skor, Lig.sonuc_harf(x)], k, false, int(x[0]) == simdi and not lig.bitti(), Lig.sonuc_harf(x)))
	return p

# gol krallığı: ligin en golcü 20 oyuncusu (kendi oyuncuların vurgulu), menajer oyunlarının istatistik listesi gibi
func _goller_panel() -> Control:
	var p := PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _kutu(PANEL, 6, 0))
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 0); p.add_child(v)
	var K := lig.gol_krallari(20)
	v.add_child(_serit("GOL KRALLIĞI  ·  %s  ·  %s sezonu" % [lig.lig_veri().ad, lig.sezon_adi()]))
	v.add_child(_gol_satir(["#", "Oyuncu", "Kulüp", "Gol"], 0, true, false))
	if K.is_empty():
		v.add_child(_ic(_etiket("Henüz gol yok. İlk hafta oynanınca liste dolar.", 15, SOLUK)))
	var k := 0
	for r in K:
		v.add_child(_gol_satir([str(r[0]), r[1], r[3], str(r[4])], k, false, r[5])); k += 1
	return p

# kadro: menajer oyunlarının kadro ekranı — no · mevki · oyuncu · yetenek (çubuk) · lig golü; ilk 11 üstte, yedekler altta
func _kadro_panel() -> Control:
	var p := PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _kutu(PANEL, 6, 0))
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 0); p.add_child(v)
	var biz: Dictionary = lig.takim(lig.biz())
	v.add_child(_serit("KADRO  ·  %s  ·  %s" % [biz.ad, lig.kadro_ozet()]))
	v.add_child(_kadro_satir(["No", "Mevki", "Oyuncu", "Yetenek", "Gol"], 0, true, 0))
	var k := 0; var yedek_yazildi := false
	for x in lig.kadro_satirlari():
		if not x[5] and not yedek_yazildi:
			yedek_yazildi = true
			var ys := _etiket("YEDEKLER", 13, SOLUK); ys.custom_minimum_size = Vector2(0, 22)
			v.add_child(_ic(ys))
		v.add_child(_kadro_satir([str(x[0]), Lig.mevki_adi(x[1]), x[2], str(x[3]), str(x[4])], k, false, int(x[3]))); k += 1
	return p

func _kadro_satir(vals: Array, k: int, baslik: bool, yet: int) -> Control:
	var p := PanelContainer.new()
	var c := SERIT if baslik else (SATIR_A if k % 2 == 0 else SATIR_B)
	var st := _kutu(c, 0, 0); st.content_margin_top = 3; st.content_margin_bottom = 3; st.content_margin_left = 8; st.content_margin_right = 8
	p.add_theme_stylebox_override("panel", st)
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 8); p.add_child(hb)
	for i in vals.size():
		var renk := ALTIN if baslik else (SOLUK if i <= 1 else YAZI)
		if not baslik and i == 4 and int(vals[i]) > 0: renk = ALTIN
		var l := _etiket(str(vals[i]), 14 if baslik else 15, renk)
		if i == 2:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL; l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			if not baslik: l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # oyuncu adı çevrilmez ("D. Gol" → "D. Goals" olmasın)
			hb.add_child(l); continue
		if i == 3 and not baslik:
			# yetenek: menajer oyunlarındaki gibi çubuk + sayı (yeşil iyi, sarı orta, kırmızı zayıf)
			var kutu := HBoxContainer.new(); kutu.add_theme_constant_override("separation", 6); kutu.custom_minimum_size = Vector2(120, 0)
			var arka := Panel.new(); arka.custom_minimum_size = Vector2(80, 10); arka.size_flags_vertical = Control.SIZE_SHRINK_CENTER
			arka.add_theme_stylebox_override("panel", _kutu(Color("#1c2026"), 3, 0))
			var dolu := Panel.new(); dolu.position = Vector2.ZERO; dolu.size = Vector2(80.0 * clampf(yet / 100.0, .03, 1.0), 10)
			dolu.add_theme_stylebox_override("panel", _kutu(YESIL if yet >= 70 else (ALTIN if yet >= 50 else KIRMIZI), 3, 0))
			arka.add_child(dolu); kutu.add_child(arka)
			l.custom_minimum_size = Vector2(30, 0); kutu.add_child(l); hb.add_child(kutu); continue
		l.custom_minimum_size = Vector2([34, 54, 0, 120, 44][i], 0)
		l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if (i == 3 and baslik) else HORIZONTAL_ALIGNMENT_CENTER
		hb.add_child(l)
	return p

# tarihçe: kulübün sezon sezon karnesi (menajer oyunlarındaki kulüp geçmişi): sezon · sıra · O G B M Av P · şampiyon · gol kralı
const TARIH_GEN := [70, 48, 30, 30, 30, 30, 40, 36]
func _tarih_panel() -> Control:
	var p := PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _kutu(PANEL, 6, 0))
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 0); p.add_child(v)
	var biz: Dictionary = lig.takim(lig.biz())
	v.add_child(_serit("TARİHÇE  ·  %s  ·  %s" % [biz.ad, lig.tarih_ozet()]))
	v.add_child(_tarih_satir(["Sezon", "Sıra", "O", "G", "B", "M", "Av", "P", "Şampiyon", "Gol kralı", "Yönetim"], 0, true, false, false))
	var k := 0
	for x in lig.tarih_satirlari():
		var sam: String = "sürüyor" if x[13] else x[10]
		var vals := [x[0], "%d." % int(x[1]), str(x[3]), str(x[4]), str(x[5]), str(x[6]), ("+" if int(x[7]) > 0 else "") + str(x[7]), str(x[8]), sam, x[11], ("Hedef: " + x[14]) if x[13] else x[14]]
		v.add_child(_tarih_satir(vals, k, false, x[12], x[13])); k += 1
	if lig.tarih_satirlari().size() <= 1:
		v.add_child(_ic(_etiket("Sezon bitince karnesi buraya yazılır: sıra, puan, şampiyon ve gol kralı.", 15, SOLUK)))
	return p

func _tarih_satir(vals: Array, k: int, baslik: bool, sampiyon: bool, suruyor: bool) -> Control:
	var p := PanelContainer.new()
	var c := SERIT if baslik else (BIZ_RENK if suruyor else (SATIR_A if k % 2 == 0 else SATIR_B))
	var st := _kutu(c, 0, 0); st.content_margin_top = 3; st.content_margin_bottom = 3; st.content_margin_left = 8; st.content_margin_right = 8
	p.add_theme_stylebox_override("panel", st)
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 6); p.add_child(hb)
	for i in vals.size():
		var renk := ALTIN if baslik else YAZI
		if not baslik:
			if i == 1 and sampiyon: renk = ALTIN
			elif i == 7: renk = ALTIN
			elif i == 10: renk = KIRMIZI if str(vals[i]) == "Hedefin altında" else (YESIL if str(vals[i]) in ["Hedef tuttu", "Beklentinin üstü"] else SOLUK)
			elif i >= 8: renk = ALTIN if (i == 8 and sampiyon) else SOLUK
		var l := _etiket(str(vals[i]), 14 if baslik else 15, renk)
		if i >= 8:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL; l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			if i == 9: l.size_flags_stretch_ratio = 1.4
			elif i == 10: l.size_flags_stretch_ratio = 1.1
		else:
			l.custom_minimum_size = Vector2(TARIH_GEN[i], 0)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_LEFT if i == 0 else HORIZONTAL_ALIGNMENT_CENTER
		hb.add_child(l)
	return p

func _gol_satir(vals: Array, k: int, baslik: bool, biz: bool) -> Control:
	var p := PanelContainer.new()
	var c := SERIT if baslik else (BIZ_RENK if biz else (SATIR_A if k % 2 == 0 else SATIR_B))
	var st := _kutu(c, 0, 0); st.content_margin_top = 3; st.content_margin_bottom = 3; st.content_margin_left = 8; st.content_margin_right = 8
	p.add_theme_stylebox_override("panel", st)
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 8); p.add_child(hb)
	for i in vals.size():
		var renk := ALTIN if (baslik or i == 3) else (SOLUK if i == 2 else YAZI)
		if not baslik and k == 0 and i == 1: renk = ALTIN
		var l := _etiket(str(vals[i]), 14 if baslik else 15, renk)
		if i == 1 or i == 2:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL; l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
			if i == 1: l.size_flags_stretch_ratio = 1.3
			if i == 1 and not baslik: l.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED   # oyuncu adı çevrilmez
		else:
			l.custom_minimum_size = Vector2(34 if i == 0 else 48, 0); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		hb.add_child(l)
	return p

func _fik_satir(vals: Array, k: int, baslik: bool, vurgu: bool, harf: String) -> Control:
	var p := PanelContainer.new()
	var c := SERIT if baslik else (BIZ_RENK if vurgu else (SATIR_A if k % 2 == 0 else SATIR_B))
	var st := _kutu(c, 0, 0); st.content_margin_top = 3; st.content_margin_bottom = 3; st.content_margin_left = 8; st.content_margin_right = 8
	p.add_theme_stylebox_override("panel", st)
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 6); p.add_child(hb)
	var boy := 14 if baslik else 15
	var genis := [30, 22, 0, 64, 26]
	for i in vals.size():
		var renk := ALTIN if baslik else (SOLUK if i == 1 else YAZI)
		if i == 3 and not baslik: renk = ALTIN if vurgu else (YAZI if harf != "" else SOLUK)
		if i == 4 and harf != "": renk = YESIL if harf == "G" else (Color("#d9b34f") if harf == "B" else KIRMIZI)
		var l := _etiket(str(vals[i]), boy, renk)
		if i == 2 or (baslik and i == 0):
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL; l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		else:
			l.custom_minimum_size = Vector2(genis[i], 0); l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if baslik and i == 0: l.custom_minimum_size.x = 0
		hb.add_child(l)
	return p

func _tablo_satir(vals: Array, sira: int, baslik: bool, biz: bool, form: String, n := 0) -> Control:
	var p := PanelContainer.new()
	var c := SERIT if baslik else (BIZ_RENK if biz else (SATIR_A if sira % 2 == 1 else SATIR_B))
	var st := _kutu(c, 0, 0); st.content_margin_top = 2; st.content_margin_bottom = 2; st.content_margin_left = 0; st.content_margin_right = 8
	p.add_theme_stylebox_override("panel", st)
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 0); p.add_child(hb)
	# sıra şeridi: şampiyonluk altın, ilk dört yeşil, son üç kırmızı
	var cizgi := ColorRect.new(); cizgi.custom_minimum_size = Vector2(5, 0)
	cizgi.color = Color(0, 0, 0, 0)
	if not baslik and n > 0:
		if sira == 1: cizgi.color = ALTIN
		elif sira <= 4: cizgi.color = YESIL
		elif sira > n - 3: cizgi.color = KIRMIZI
	hb.add_child(cizgi)
	var boy := 14 if baslik else 15
	var renk := SOLUK if baslik else YAZI
	for k in vals.size():
		if dikey and k == vals.size() - 1 and vals.size() > 10: continue   # dik ekranda form sütunu yok
		var l := _etiket(str(vals[k]), boy, renk)
		if k == 1:
			l.size_flags_horizontal = Control.SIZE_EXPAND_FILL; l.clip_text = true
			l.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		else:
			l.custom_minimum_size = Vector2((28 if dikey else 40) if k == 0 else (96 if k == vals.size() - 1 else (30 if dikey else 44)), 0)
			l.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		if k == vals.size() - 1 and not baslik and form != "":
			var rt := RichTextLabel.new(); rt.bbcode_enabled = true; rt.fit_content = true; rt.scroll_active = false
			rt.custom_minimum_size = Vector2(96, 0); rt.add_theme_font_size_override("normal_font_size", 14)
			var s := "[center]"
			for h in form: s += "[color=%s]%s[/color] " % [("#3ec46d" if h == "G" else ("#d9b34f" if h == "B" else "#d9534f")), h]
			rt.text = s + "[/center]"
			hb.add_child(rt); continue
		if k == 9 and not baslik: l.add_theme_color_override("font_color", ALTIN if biz else Color.WHITE)
		hb.add_child(l)
	return p

func _sag_panel() -> Control:
	var v := VBoxContainer.new(); v.custom_minimum_size = Vector2(400, 0); v.add_theme_constant_override("separation", 8)
	# eylem düğmeleri en üstte: küçük ekranda kaydırmadan görünsün
	var S := lig.satirlar()
	for i in S.size():
		var b := Button.new(); b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.add_theme_font_size_override("font_size", 17)
		b.custom_minimum_size = Vector2(0, 40); b.clip_text = true
		b.add_theme_stylebox_override("hover", _kutu(Color("#4a5566"), 6, 7)); b.add_theme_stylebox_override("pressed", _kutu(ALTIN, 6, 7))
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.pressed.connect(func(): satir = i; eylem.emit("bas"))
		if S[i] in ["Lig", "Takımın", "Kupa"]:
			# seçici satır: iki yanda ‹ › düğmesi, ortaya basınca ileri
			b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
			var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 6)
			for yon in [-1, 1]:
				var k := Button.new(); k.text = "‹" if yon < 0 else "›"; k.add_theme_font_size_override("font_size", 24)
				k.custom_minimum_size = Vector2(52, 40); k.add_theme_stylebox_override("normal", _kutu(SERIT, 6, 7))
				k.add_theme_stylebox_override("hover", _kutu(Color("#4a5566"), 6, 7)); k.add_theme_stylebox_override("pressed", _kutu(ALTIN, 6, 7))
				k.pressed.connect(func(): satir = i; eylem.emit("geri" if yon < 0 else "ileri"))
				if yon < 0: hb.add_child(k); hb.add_child(b)
				else: hb.add_child(k)
			v.add_child(hb)
		else:
			v.add_child(b)
		dugmeler.append(b)
	_mesaj = _etiket("", 14, SOLUK); _mesaj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(_mesaj)
	if lig.kip == "kupa":
		var kp := PanelContainer.new(); kp.add_theme_stylebox_override("panel", _kutu(PANEL, 6, 0))
		var kv := VBoxContainer.new(); kp.add_child(kv)
		kv.add_child(_serit("KUPA"))
		var kl := _etiket(lig.kupa_ozet(), 16, ALTIN if lig.kupa_kazandi() else YAZI); kl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; kv.add_child(_ic(kl))
		v.add_child(kp)
	elif lig.var_mi():
		var mp := PanelContainer.new(); mp.add_theme_stylebox_override("panel", _kutu(PANEL, 6, 0))
		var mv := VBoxContainer.new(); mv.add_theme_constant_override("separation", 6); mp.add_child(mv)
		if lig.bitti():
			mv.add_child(_serit("SEZON SONU"))
			var s: Dictionary = lig.takim(int(lig.d.sampiyon))
			var l := _etiket("ŞAMPİYON:  " + s.ad, 20, ALTIN); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; mv.add_child(_ic(l))
			mv.add_child(_ic(_etiket("Senin takımın %d. bitirdi." % lig.sira_biz(), 16, YAZI)))
			var hs := Lig.hedef_sonuc(lig.sira_biz(), lig.hedef_sira())
			var yl := _etiket("Yönetim: " + hs + "  (hedef: " + lig.hedef_adi() + ")", 16, KIRMIZI if hs == "Hedefin altında" else YESIL)
			yl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; mv.add_child(_ic(yl))
			if lig.gol_krali_metni() != "":
				var gk := _etiket("Gol kralı:  " + lig.gol_krali_metni(), 16, ALTIN); gk.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; mv.add_child(_ic(gk))
		else:
			mv.add_child(_serit("SONRAKİ MAÇ  ·  HAFTA %d" % (int(lig.d.hafta) + 1)))
			var mc := lig.sonraki_mac()
			var e: Dictionary = lig.takim(int(mc[0])); var dp: Dictionary = lig.takim(int(mc[1]))
			var l := _etiket(e.ad + "\n– " + dp.ad, 19, Color.WHITE); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; mv.add_child(_ic(l))
			var ic_dis := "İç saha" if int(mc[0]) == lig.biz() else "Deplasman"
			var rk: int = int(mc[1]) if int(mc[0]) == lig.biz() else int(mc[0])
			var rs := 0
			for r in lig.tablo_satirlari():
				if r[1] == lig.takim(rk).kisa: rs = r[0]
			mv.add_child(_ic(_etiket("%s  ·  rakip %d. sırada, güç %d" % [ic_dis, rs, int(lig.takim(rk).str)], 15, SOLUK)))
		v.add_child(mp)
		if not lig.bitti(): v.add_child(_yonetim_panel())
		if not lig.son_hafta.is_empty():
			var sp := PanelContainer.new(); sp.add_theme_stylebox_override("panel", _kutu(PANEL, 6, 0))
			var sv := VBoxContainer.new(); sv.add_theme_constant_override("separation", 0); sp.add_child(sv)
			sv.add_child(_serit("HAFTA %d SONUÇLARI" % int(lig.d.hafta)))
			var k := 0
			for mc in lig.son_hafta:
				var biz: bool = int(mc[0]) == lig.biz() or int(mc[1]) == lig.biz()
				var r := PanelContainer.new(); var st := _kutu(BIZ_RENK if biz else (SATIR_A if k % 2 == 0 else SATIR_B), 0, 0)
				st.content_margin_top = 1; st.content_margin_bottom = 1; st.content_margin_left = 10; st.content_margin_right = 10
				r.add_theme_stylebox_override("panel", st)
				var hb := HBoxContainer.new(); r.add_child(hb)
				var a := _etiket(lig.takim(int(mc[0])).kisa, 14, YAZI); a.size_flags_horizontal = Control.SIZE_EXPAND_FILL; a.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
				var s := _etiket("%d - %d" % [int(mc[2]), int(mc[3])], 14, ALTIN); s.custom_minimum_size = Vector2(70, 0); s.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
				var b := _etiket(lig.takim(int(mc[1])).kisa, 14, YAZI); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL
				hb.add_child(a); hb.add_child(s); hb.add_child(b)
				sv.add_child(r); k += 1
			v.add_child(sp)
	else:
		var ip := PanelContainer.new(); ip.add_theme_stylebox_override("panel", _kutu(PANEL, 6, 0))
		var iv := VBoxContainer.new(); ip.add_child(iv)
		iv.add_child(_serit("YENİ SEZON"))
		var l := _etiket("Ligini ve kulübünü seç. Her hafta kendi maçını oynarsın; ligin diğer maçları aynı anda sonuçlanır. Sezon sonunda en çok puanı toplayan şampiyon olur.", 15, YAZI)
		l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; iv.add_child(_ic(l))
		var l2 := _etiket("Maç sırası ligin bu sezonki gerçek fikstürüdür.", 15, ALTIN)
		l2.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; iv.add_child(_ic(l2))
		v.add_child(ip)
	return v

# yönetim beklentisi: hedef, şu anki sıra ve güven çubuğu (FM'deki yönetim kurulu güveni)
func _yonetim_panel() -> Control:
	var p := PanelContainer.new(); p.add_theme_stylebox_override("panel", _kutu(PANEL, 6, 0))
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 4); p.add_child(v)
	var g := lig.guven()
	v.add_child(_serit("YÖNETİM  ·  " + Lig.guven_adi(g)))
	var sira := lig.sira_biz(); var hs := lig.hedef_sira()
	var h := _etiket("Hedef: %s  ·  şu an %d." % [lig.hedef_adi(), sira], 16, YAZI); h.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	v.add_child(_ic(h))
	var cubuk := HBoxContainer.new(); cubuk.add_theme_constant_override("separation", 8)
	var zemin := PanelContainer.new(); zemin.size_flags_horizontal = Control.SIZE_EXPAND_FILL; zemin.custom_minimum_size = Vector2(0, 12)
	zemin.add_theme_stylebox_override("panel", _kutu(SERIT, 4, 0))
	var dolu := ColorRect.new(); dolu.color = YESIL if g >= 60 else (ALTIN if g >= 40 else KIRMIZI)
	dolu.size_flags_horizontal = Control.SIZE_EXPAND_FILL; dolu.size_flags_stretch_ratio = g
	var bos := Control.new(); bos.size_flags_horizontal = Control.SIZE_EXPAND_FILL; bos.size_flags_stretch_ratio = 100 - g
	var ic := HBoxContainer.new(); ic.add_theme_constant_override("separation", 0); ic.add_child(dolu); ic.add_child(bos); zemin.add_child(ic)
	cubuk.add_child(zemin); cubuk.add_child(_etiket(Lig.yuzde(g), 15, SOLUK))
	v.add_child(_ic(cubuk))
	var not_ := "Yönetim senden " + lig.hedef_aciklama() + " bekliyor."
	if int(lig.d.hafta) * 2 >= lig.hafta_sayisi(): not_ += ("  Şu an hedefin gerisindesin." if sira > hs else "  Şu an hedefi tutturuyorsun.")
	var nl := _etiket(not_, 14, SOLUK); nl.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(_ic(nl))
	return p

func _serit(t: String) -> Control:
	var p := PanelContainer.new(); var st := _kutu(SERIT, 0, 0)
	st.content_margin_left = 12; st.content_margin_top = 6; st.content_margin_bottom = 6
	p.add_theme_stylebox_override("panel", st)
	p.add_child(_etiket(t, 14, ALTIN))
	return p

func _ic(c: Control) -> Control:
	var m := MarginContainer.new()
	for k in ["left", "right"]: m.add_theme_constant_override("margin_" + k, 12)
	m.add_theme_constant_override("margin_bottom", 6)
	m.add_child(c); return m

func _etiket(t: String, boy: int, renk: Color) -> Label:
	var l := Label.new(); l.text = t; l.add_theme_font_size_override("font_size", boy); l.add_theme_color_override("font_color", renk)
	return l

static func _kutu(c: Color, r: int, m: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = c; s.set_corner_radius_all(r); s.set_content_margin_all(m)
	return s


# ---------- kupa ----------
func _kupa_baslik() -> Control:
	var K: Dictionary = lig.kupa_tanim(lig.kupa.id) if lig.kupa_var() else lig.KUPALAR[lig.kur_kupa]
	var t: Dictionary = lig.kupa_takim(lig.kupa.ben) if lig.kupa_var() else {}
	if t.is_empty():
		var KK: Array = lig.kupa_katilim(K.id)
		t = lig.kupa_takim(KK[posmod(lig.kur_kupa_takim, KK.size())])
	var p := PanelContainer.new()
	p.add_theme_stylebox_override("panel", _kutu(Color(t.c1), 0, 12))
	var hb := HBoxContainer.new(); hb.add_theme_constant_override("separation", 16); p.add_child(hb)
	var yazi_renk := Color(t.c2) if Mac.renk_farki(t.c1, t.c2) > 128 else Color.WHITE
	hb.add_child(_etiket(t.ad, 26, yazi_renk))
	var al := _etiket("KUPA  ·  " + K.ad + " · " + K.kita + ("  ·  " + lig.kupa_tur_adi(int(lig.kupa.tur)) if lig.kupa_var() and not lig.kupa.bitti and not lig.kupa.elendi else ""), 17, yazi_renk)
	al.size_flags_horizontal = Control.SIZE_EXPAND_FILL; al.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	hb.add_child(al)
	return p

func _kupa_panel() -> Control:
	var p := PanelContainer.new(); p.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	p.add_theme_stylebox_override("panel", _kutu(PANEL, 6, 0))
	var v := VBoxContainer.new(); v.add_theme_constant_override("separation", 0); p.add_child(v)
	if not lig.kupa_var():
		var K: Dictionary = lig.KUPALAR[lig.kur_kupa]
		v.add_child(_serit("KATILAN KULÜPLER  ·  " + K.ad + "  ·  %d kulüp" % int(K.n)))
		var k := 0
		var KK: Array = lig.kupa_katilim(K.id)
		for x in KK:
			var t: Dictionary = lig.kupa_takim(x)
			var biz := k == posmod(lig.kur_kupa_takim, KK.size())
			v.add_child(_gol_satir([str(k + 1), t.ad, lig.veri.ligler[lig._lig_i(str(x[0]))].ad, str(int(t.str))], k, false, biz)); k += 1
		return p
	for tur in lig.kupa_turlari():
		v.add_child(_serit(str(tur[0])))
		var k := 0
		for m in tur[1]:
			var r := PanelContainer.new(); var st := _kutu(BIZ_RENK if m[3] else (SATIR_A if k % 2 == 0 else SATIR_B), 0, 0)
			st.content_margin_top = 2; st.content_margin_bottom = 2; st.content_margin_left = 10; st.content_margin_right = 10
			r.add_theme_stylebox_override("panel", st)
			var hb := HBoxContainer.new(); r.add_child(hb)
			var a := _etiket(m[0], 15, ALTIN if m[4] == 0 else YAZI); a.size_flags_horizontal = Control.SIZE_EXPAND_FILL; a.clip_text = true
			var sk := _etiket(m[1], 15, Color.WHITE); sk.custom_minimum_size = Vector2(110, 0); sk.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			var b := _etiket(m[2], 15, ALTIN if m[4] == 1 else YAZI); b.size_flags_horizontal = Control.SIZE_EXPAND_FILL; b.clip_text = true; b.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
			hb.add_child(a); hb.add_child(sk); hb.add_child(b)
			v.add_child(r); k += 1
	return p
