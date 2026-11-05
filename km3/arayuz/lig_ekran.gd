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
	if dikey:
		var sc := ScrollContainer.new(); sc.size_flags_vertical = Control.SIZE_EXPAND_FILL
		sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		mv.add_child(sc); sc.add_child(ic); ic.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	else:
		mv.add_child(ic)
	ic.add_child(hb)
	hb.add_child(_tablo_panel())
	hb.add_child(_sag_panel())
	satir = mini(satir, lig.satirlar().size() - 1)
	ciz()

# seçili satırı ve mesajı tazele (her tuşta yeniden kurmadan)
func ciz() -> void:
	var S := lig.satirlar()
	for i in dugmeler.size():
		var b: Button = dugmeler[i]
		var sec := i == satir
		b.text = lig.satir_metni(i, sec)
		var ana_eylem: bool = S[i] in ["MAÇA ÇIK", "SEZONA BAŞLA", "YENİ SEZON"]
		var c := ALTIN if sec else (Color("#e5722f") if ana_eylem else SERIT)
		b.add_theme_stylebox_override("normal", _kutu(c, 6, 7))
		b.add_theme_color_override("font_color", Color("#1d2b2c") if sec else (Color.WHITE if ana_eylem else YAZI))
	if _mesaj: _mesaj.text = lig.mesaj if lig.mesaj != "" else "Oklar: satır ve değer  ·  Enter: seç  ·  Esc: ana menü"

var _mesaj: Label

func _baslik() -> Control:
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
		for k in L.size():
			v.add_child(_tablo_satir([str(k + 1), L[k].ad, "", "", "", "", "", "", "", str(int(L[k].str)), ""], 0, false, L[k] == biz, ""))
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
	if lig.var_mi():
		var mp := PanelContainer.new(); mp.add_theme_stylebox_override("panel", _kutu(PANEL, 6, 0))
		var mv := VBoxContainer.new(); mv.add_theme_constant_override("separation", 6); mp.add_child(mv)
		if lig.bitti():
			mv.add_child(_serit("SEZON SONU"))
			var s: Dictionary = lig.takim(int(lig.d.sampiyon))
			var l := _etiket("ŞAMPİYON:  " + s.ad, 20, ALTIN); l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; mv.add_child(_ic(l))
			mv.add_child(_ic(_etiket("Senin takımın %d. bitirdi." % lig.sira_biz(), 16, YAZI)))
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
		v.add_child(ip)
	var bos := Control.new(); bos.size_flags_vertical = Control.SIZE_EXPAND_FILL; v.add_child(bos)
	var S := lig.satirlar()
	for i in S.size():
		var b := Button.new(); b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.add_theme_font_size_override("font_size", 17)
		b.custom_minimum_size = Vector2(0, 36); b.clip_text = true
		b.add_theme_stylebox_override("hover", _kutu(Color("#4a5566"), 6, 7)); b.add_theme_stylebox_override("pressed", _kutu(ALTIN, 6, 7))
		b.add_theme_color_override("font_hover_color", Color.WHITE)
		b.pressed.connect(func(): satir = i; eylem.emit("bas"))
		v.add_child(b); dugmeler.append(b)
	_mesaj = _etiket("", 14, SOLUK); _mesaj.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART; v.add_child(_mesaj)
	return v

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
