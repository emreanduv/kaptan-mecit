# Düzenleme modu ekranı (PES'teki option file usulü): kulüp adı, kısa ad, renkler, lig adı, oyuncu adları ve forma
# numaraları; paketi paylaş / içe aktar. Telefonda (web görünümü) yazı alanları güvenilir olsun diye yazı, cihazın kendi
# giriş kutusuyla (prompt) alınır; masaüstünde doğrudan yazılır. VR'da düzenleme yok (klavye yok); paketler orada da geçerli.
extends PanelContainer
class_name DuzenEkran

signal kapandi(degisti: bool)

var ana                  # ana.gd (kutu biçimi ve afiş için)
var veri: Dictionary
var sec_lig: Secici
var sec_t: Secici
var _govde: VBoxContainer
var _lig_ad := ""
var _ad := ""; var _kisa := ""; var _c1 := ""; var _c2 := ""
var _oy: Array = []          # [{n, no}]
var _degisti := false
var _uyari: Label
var _web := OS.has_feature("web")

func _init(a, v: Dictionary) -> void:
	ana = a; veri = v
	add_theme_stylebox_override("panel", a._kutu(Color("#f5ecd8"), 16))
	custom_minimum_size = Vector2(860, 0)
	var mv := VBoxContainer.new(); mv.add_theme_constant_override("separation", 10); add_child(mv)
	var bas := PanelContainer.new(); bas.add_theme_stylebox_override("panel", a._kutu(Color("#1f3b3c"), 12))
	var bh := HBoxContainer.new(); bas.add_child(bh)
	var bv := VBoxContainer.new(); bv.size_flags_horizontal = Control.SIZE_EXPAND_FILL; bh.add_child(bv)
	bv.add_child(_yazi("Düzenleme modu", 30, Color.WHITE))
	bv.add_child(_yazi("Kulüp ve oyuncu adlarını kendine göre değiştir; paketini arkadaşlarınla paylaş ya da onlarınkini yükle.", 15, Color("#cfe3d6"), true))
	var kp := _dugme("Kapat  ×", Color("#e5722f"), 20); kp.custom_minimum_size = Vector2(150, 52); kp.size_flags_horizontal = Control.SIZE_SHRINK_END; kp.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	kp.pressed.connect(kapat); bh.add_child(kp)
	mv.add_child(bas)
	sec_lig = Secici.new(); sec_t = Secici.new()
	mv.add_child(_yazi("Lig", 15, Color("#3a3a3a"))); mv.add_child(sec_lig)
	mv.add_child(_yazi("Kulüp", 15, Color("#3a3a3a"))); mv.add_child(sec_t)
	sec_lig.item_selected.connect(func(_i): _takimlar(); _goster())
	sec_t.item_selected.connect(func(_i): _goster())
	_govde = VBoxContainer.new(); _govde.add_theme_constant_override("separation", 8); mv.add_child(_govde)
	_uyari = _yazi("", 16, Color("#a33a1a"), true); mv.add_child(_uyari)
	var a1 := HBoxContainer.new(); a1.add_theme_constant_override("separation", 10)
	var kd := _dugme("Kaydet", Color("#2f7d4a"), 22); kd.pressed.connect(_kaydet); a1.add_child(kd)
	var sf := _dugme("Bu kulübü özgün haline döndür", Color("#706b63"), 17); sf.pressed.connect(_sifirla); a1.add_child(sf)
	mv.add_child(a1)
	var a2 := HBoxContainer.new(); a2.add_theme_constant_override("separation", 10)
	var pp := _dugme("Paketimi paylaş", Color("#2f5d8c"), 18); pp.pressed.connect(_paylas); a2.add_child(pp)
	var pi := _dugme("Paket yükle", Color("#2f5d8c"), 18); pi.pressed.connect(_yukle); a2.add_child(pi)
	var hs := _dugme("Bütün düzenlemeleri sil", Color("#8c2f2f"), 16); hs.pressed.connect(_hepsini_sil); a2.add_child(hs)
	mv.add_child(a2)
	visible = false

func ac() -> void:
	sec_lig.clear()
	for l in veri.ligler: sec_lig.add_item(str(l.ad) + " · " + str(l.ulke))
	sec_lig.select(0); _takimlar(); _goster()
	_degisti = false; _sil_onay = false; _uyari.text = ""
	visible = true
	if get_parent() and get_parent().get_parent() is ScrollContainer: (get_parent().get_parent() as ScrollContainer).scroll_vertical = 0

func kapat() -> void:
	visible = false
	kapandi.emit(_degisti)

func _lg() -> Dictionary: return veri.ligler[sec_lig.selected]
func _t() -> Dictionary: return _lg().takimlar[sec_t.selected]

func _takimlar() -> void:
	sec_t.clear()
	for t in _lg().takimlar: sec_t.add_item(str(t.ad))
	sec_t.select(0)

# seçili kulübün alanlarını göster (henüz kaydedilmemiş değişiklik varsa uyarmadan atılır: Kaydet'e basılmadıysa geçerli değil)
func _goster() -> void:
	var t := _t(); var lg := _lg()
	_lig_ad = str(lg.ad); _ad = str(t.ad); _kisa = str(t.kisa); _c1 = str(t.c1); _c2 = str(t.c2)
	_oy = []
	for o in t.oy: _oy.append({"n": str(o.n), "no": int(o.no)})
	_yeniden_ciz()

func _kaydet() -> void:
	Duzen.lig_yaz(_lg(), _lig_ad)
	Duzen.takim_yaz(_t(), _ad, _kisa, _c1, _c2, _oy)
	Duzen.kaydet(); Duzen.uygula(veri)
	_degisti = true
	var ls := sec_lig.selected; var ts := sec_t.selected
	ac(); sec_lig.select(ls); _takimlar(); sec_t.select(ts); _goster(); _degisti = true
	_uyari.text = "Kaydedildi."

func _sifirla() -> void:
	Duzen.takim_sifirla(_t()); Duzen.lig_yaz(_lg(), "")
	Duzen.kaydet(); Duzen.uygula(veri); _degisti = true
	var ls := sec_lig.selected; var ts := sec_t.selected
	ac(); sec_lig.select(ls); _takimlar(); sec_t.select(ts); _goster(); _degisti = true
	_uyari.text = "Kulüp özgün haline döndü."

var _sil_onay := false
func _hepsini_sil() -> void:
	if not _sil_onay:
		_sil_onay = true; _uyari.text = "Emin misin? Bütün düzenlemeler silinir; bir kez daha bas"
		return
	Duzen.hepsini_sifirla(); Duzen.kaydet(); Duzen.uygula(veri); _degisti = true
	ac(); _degisti = true
	_uyari.text = "Bütün düzenlemeler silindi."

func _paylas() -> void:
	if Duzen.bos_mu():
		_uyari.text = "Henüz düzenleme yok: önce bir kulübü değiştirip kaydet."
		return
	var m := Duzen.paket_metni()
	if _web:
		JavaScriptBridge.eval("""(function(t){var P=window.Capacitor&&Capacitor.Plugins&&Capacitor.Plugins.Share;
			var kopya=function(){try{navigator.clipboard.writeText(t)}catch(e){}};kopya();
			try{if(P&&P.share){P.share({title:'Kaptan Mecit paketi',text:t}).catch(function(){});return}if(navigator.share){navigator.share({title:'Kaptan Mecit paketi',text:t}).catch(function(){});return}}catch(e){}
			})(""" + JSON.stringify(m) + ")")
	else:
		DisplayServer.clipboard_set(m)
	_uyari.text = "Paketin panoya kopyalandı (paylaşım da açıldıysa oradan gönderebilirsin)."

func _yukle() -> void:
	var cb := func(s: String):
		var n := Duzen.paket_al(s)
		if n < 0: _uyari.text = "Bu bir Kaptan Mecit paketi değil (KMPAKET1 ile başlamalı)."; return
		Duzen.kaydet(); Duzen.uygula(veri); _degisti = true
		var ls := sec_lig.selected; var ts := sec_t.selected
		ac(); sec_lig.select(ls); _takimlar(); sec_t.select(ts); _goster(); _degisti = true
		_uyari.text = ("Pack loaded: %d clubs / leagues." if Dil.en else "Paket yüklendi: %d kulüp / lig.") % n
	if _web:
		var r = JavaScriptBridge.eval("(function(){var r=prompt(" + JSON.stringify(Dil.cevir("Paketi buraya yapıştır")) + ",'');return r===null?'':r})()", true)
		if str(r) != "": cb.call(str(r))
	else:
		var p := DisplayServer.clipboard_get()
		if p.strip_edges() == "": _uyari.text = "Panoda paket yok: paketi kopyalayıp yeniden bas."
		else: cb.call(p)

# --- küçük yapı taşları ---
func _yazi(s: String, b: int, c: Color, sar := false) -> Label:
	var l := Label.new(); l.text = s; l.add_theme_font_size_override("font_size", b); l.add_theme_color_override("font_color", c)
	if sar: l.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	return l

func _dugme(s: String, c: Color, b: int) -> Button:
	var d := Button.new(); d.text = s; d.add_theme_font_size_override("font_size", b)
	d.add_theme_stylebox_override("normal", ana._kutu(c, 10)); d.add_theme_stylebox_override("hover", ana._kutu(c.lightened(.12), 10))
	d.add_theme_stylebox_override("pressed", ana._kutu(c.darkened(.15), 10)); d.add_theme_color_override("font_color", Color.WHITE)
	d.size_flags_horizontal = Control.SIZE_EXPAND_FILL; d.custom_minimum_size = Vector2(0, 50)
	return d

func _alan_satiri(baslik: String, al: Callable, ver: Callable, maks: int) -> Control:
	var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 10)
	var l := _yazi(baslik, 16, Color("#3a3a3a")); l.custom_minimum_size = Vector2(190, 0); h.add_child(l)
	var g := _girdi(al, ver, maks); g.size_flags_horizontal = Control.SIZE_EXPAND_FILL; h.add_child(g)
	return h

# Yazı alanı: masaüstünde LineEdit; web'de (telefon uygulaması dahil) cihazın kendi giriş kutusunu açan düğme
func _girdi(al: Callable, ver: Callable, maks: int, sayi := false) -> Control:
	if not _web:
		var le := LineEdit.new(); le.text = str(al.call()); le.max_length = maks; le.custom_minimum_size = Vector2(0, 44)
		le.add_theme_font_size_override("font_size", 18); le.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
		le.add_theme_stylebox_override("normal", ana._kutu(Color.WHITE, 8)); le.add_theme_stylebox_override("focus", ana._kutu(Color("#fffaf0"), 8))
		le.add_theme_color_override("font_color", Color("#1a1a1a")); le.add_theme_color_override("caret_color", Color("#1a1a1a"))
		le.text_changed.connect(func(s): ver.call(s))
		return le
	var b := Button.new(); b.text = str(al.call()); b.custom_minimum_size = Vector2(0, 44); b.add_theme_font_size_override("font_size", 18)
	b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED; b.clip_text = true
	b.add_theme_stylebox_override("normal", ana._kutu(Color.WHITE, 8)); b.add_theme_stylebox_override("hover", ana._kutu(Color("#fffaf0"), 8))
	b.add_theme_stylebox_override("pressed", ana._kutu(Color("#f3d35a"), 8)); b.add_theme_color_override("font_color", Color("#1a1a1a"))
	b.add_theme_color_override("font_hover_color", Color("#1a1a1a")); b.add_theme_color_override("font_pressed_color", Color("#1a1a1a"))
	b.pressed.connect(func():
		var r = JavaScriptBridge.eval("(function(){var r=prompt('', " + JSON.stringify(str(al.call())) + ");return r===null?'\\u0000':r})()", true)
		var s := str(r)
		if s == String.chr(0): return
		s = s.strip_edges().left(maks)
		if sayi and not s.is_valid_int(): return
		if s == "" and not sayi: return
		ver.call(s); b.text = str(al.call()))
	return b

func _renk(baslik: String, deger: String, ver: Callable) -> Control:
	var v := VBoxContainer.new(); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	v.add_child(_yazi(baslik, 15, Color("#3a3a3a")))
	# hazır renk paleti: dokunmatikte açılır renk seçiciden güvenilir
	var g := GridContainer.new(); g.columns = 8; g.add_theme_constant_override("h_separation", 4); g.add_theme_constant_override("v_separation", 4)
	var secili := Color.html(deger) if Color.html_is_valid(deger) else Color.WHITE
	for h in RENKLER:
		var c := Color.html(h)
		var b := Button.new(); b.custom_minimum_size = Vector2(38, 34)
		var s: StyleBoxFlat = ana._kutu(c, 6); s.set_content_margin_all(0)
		if c.is_equal_approx(secili): s.border_color = Color("#e5722f"); s.set_border_width_all(4)
		else: s.border_color = Color(0, 0, 0, .25); s.set_border_width_all(1)
		for d in ["normal", "hover", "pressed", "focus"]: b.add_theme_stylebox_override(d, s)
		var hh: String = h
		b.pressed.connect(func(): ver.call(hh); _goster_koru())
		g.add_child(b)
	v.add_child(g)
	return v

# renk seçince ekranı yeniden çiz ama yazılmamış alanları kaybetme
func _goster_koru() -> void:
	_yeniden_ciz()

func _yeniden_ciz() -> void:
	for c in _govde.get_children(): _govde.remove_child(c); c.queue_free()
	var t := _t()
	_govde.add_child(_alan_satiri("Lig adı", func(): return _lig_ad, func(s): _lig_ad = s, 40))
	_govde.add_child(_alan_satiri("Kulüp adı", func(): return _ad, func(s): _ad = s, 40))
	_govde.add_child(_alan_satiri("Kısa ad (3 harf)", func(): return _kisa, func(s): _kisa = s.to_upper(), 4))
	var rs := HBoxContainer.new(); rs.add_theme_constant_override("separation", 10)
	rs.add_child(_renk("Forma rengi", _c1, func(c): _c1 = c))
	rs.add_child(_renk("İkinci renk", _c2, func(c): _c2 = c))
	_govde.add_child(rs)
	_govde.add_child(_yazi("OYUNCULAR  ·  numara ve ad", 16, Color("#1f3b3c")))
	for i in _oy.size():
		var h := HBoxContainer.new(); h.add_theme_constant_override("separation", 8)
		var yer := _yazi(str(t.oy[i].get("yer", t.oy[i].get("rol", ""))), 15, Color("#555")); yer.custom_minimum_size = Vector2(48, 0)
		h.add_child(yer)
		var ii := i
		var no := _girdi(func(): return str(_oy[ii].no), func(s): _oy[ii].no = clampi(int(s), 1, 99), 2, true); no.custom_minimum_size = Vector2(70, 44)
		h.add_child(no)
		var ad := _girdi(func(): return _oy[ii].n, func(s): _oy[ii].n = s, 28); ad.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		h.add_child(ad)
		var oz := Duzen.ozgun_ad(t, i)
		if oz != _oy[i].n:
			var ol := _yazi("(" + oz + ")", 13, Color("#777")); ol.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED; h.add_child(ol)
		_govde.add_child(h)

const RENKLER := ["#FFFFFF", "#111111", "#C8102E", "#A90432", "#7A0019", "#E5722F", "#FDB912", "#F3D35A",
	"#0B6E3A", "#2E8B57", "#7CC242", "#0A2D6E", "#1E4FA0", "#5DADE2", "#6C2A8C", "#8B5A2B"]
