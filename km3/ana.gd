# Kaptan Mecit 3 — ana sahne: menü, maç döngüsü (60 Hz sabit adım), görüntü eşlemesi, yayın kameraları, skor tabelası, ses.
extends Node3D

const PW := 68.0
const PL := 105.0
const ADIM := 1.0 / 60.0
const KAMERALAR := ["Yayın", "Tele", "Dinamik", "Saha kenarı", "Yakın"]
const SURELER := [2, 4, 6, 8]
const ZORLUK := ["Kolay", "Orta", "Zor"]

var veri: Dictionary
var M = null     # Mac; CBM Modern izleme modunda DisMac (motor/dis_mac.gd)
var stad: Stadyum = null
var oyuncular: Array = []
var top: MeshInstance3D
var isaret: MeshInstance3D
var kam: Camera3D
var kam_mod := 0
var _kam_hedef := Vector3.ZERO
var _birikim := 0.0
var ses: Ses
var sec := {"lig": 0, "ev": 0, "dep": 1, "sure": 1, "zor": 1}
var menu_acik := true
var dunya: Node3D
var gunes: DirectionalLight3D
var golgeler: MultiMeshInstance3D = null
var vr: VR = null
var vr_koltuk := 2
# telefon / tablet tarayıcısı (mobil uygulamadaki Modern de budur): hafif çizim, düşük 3B çözünürlük
var mobil_web := OS.has_feature("web") and (OS.has_feature("web_ios") or OS.has_feature("web_android") or DisplayServer.is_touchscreen_available())
var hafif := OS.has_feature("android") or mobil_web

# arayüz
var ui: CanvasLayer
var tabela: Label
var dakika: Label
var afis: PanelContainer
var afis_ust: Label
var afis_alt: Label
var _afis_t := 0.0
var bilgi: Label
var menu: PanelContainer
var sec_lig: Secici
var sec_ev: Secici
var sec_dep: Secici
var sec_sure: Secici
var sec_zor: Secici
var sec_kam: Secici
var sec_zih: Secici            # oyun anlayışı (CBM'deki zihniyet): Savunma / Dengeli / Hücum
var sec_dz: Secici

# mola (yedek kulübesi), rehber, Nasıl oynanır
var mola: Mola
var mola_panel: PanelContainer
var mola_baslik: Label
var mola_dugmeler: Array = []
var mola_mesaj: Label
var mola_satir := 0
var yardim_acik := false
var yardim_metin := ""     # boş: Nasıl oynanır; dolu: maç raporu
var son_rapor := ""
var _rapor_lig := false
var _yardim_dugmeler: Array = []
var yardim_panel: PanelContainer
var dok: Dokunmatik
var dokunmatik := false
var klasik := false     # Klasik kumanda (Gameboy modu): yön haçı solda, A/B sağda, oyun ortada (molada Kontrol satırı)
func klasik_degistir() -> void:
	klasik = not klasik
	var c := ConfigFile.new(); c.load(Mola.AYAR); c.set_value("kontrol", "klasik", klasik); c.save(Mola.AYAR)
	if dok: dok.klasik = klasik; dok.queue_redraw()
	_yerlesim()

# lig modu
var lig: Lig
var lig_ekran: LigEkran
var lig_acik := false
var lig_maci := false
var kupa_maci := false
var _lig_bitis := 0.0

# test / ekran görüntüsü (komut satırı)
var _arg := {}
var _donuk := false
var tekrar := Tekrar.new()
var _tekrar_kutu: Control

func _ready() -> void:
	# gömülü yazıda (Open Sans) olmayan işaretler (★ → ▶ ◀ ✓ …) için yedek yazı: web, telefon ve Quest'te kutu çıkmasın
	var simge = load("res://yazi/simge.ttf")
	if simge: ThemeDB.fallback_font.fallbacks = [simge]
	for a in OS.get_cmdline_user_args():
		var kv := a.trim_prefix("--").split("=", true, 1)
		_arg[kv[0]] = kv[1] if kv.size() > 1 else "1"
	if _arg.has("tohum"): seed(int(_arg.tohum))
	if _arg.has("hafif"): hafif = true
	if _arg.has("dil"): Dil.ayarla(_arg.dil == "en", false)
	else: Dil.kur()
	veri = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	Duzen.yukle(); Duzen.uygula(veri)     # oyuncunun düzenlemeleri / yüklediği paket (PES option file usulü)
	lig = Lig.new(veri)
	_ortam()
	dunya = Node3D.new(); add_child(dunya)
	kam = Camera3D.new(); kam.current = true; kam.near = .3; kam.far = 900
	add_child(kam)
	top = MeshInstance3D.new()
	var sm := SphereMesh.new(); sm.radius = .12; sm.height = .24; sm.radial_segments = 24; sm.rings = 12
	top.mesh = sm
	var tm := ShaderMaterial.new(); var sh := Shader.new(); sh.code = TOP_SHADER; tm.shader = sh
	top.material_override = tm
	dunya.add_child(top)
	isaret = MeshInstance3D.new()
	var tor := TorusMesh.new(); tor.inner_radius = .62; tor.outer_radius = .78; tor.rings = 32
	isaret.mesh = tor; isaret.scale = Vector3(1, .05, 1)
	var im := StandardMaterial3D.new(); im.albedo_color = Color("#f3d35a"); im.emission_enabled = true; im.emission = Color("#f3d35a"); im.emission_energy_multiplier = 1.5
	im.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	isaret.material_override = im; isaret.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dunya.add_child(isaret)
	ses = Ses.new(); add_child(ses)
	mola = Mola.new(self); mola.rehber_yukle()
	_arayuz()
	if mobil_web or _arg.has("mobil"):
		# telefon ekranı 3 kat yoğun: 3B sahneyi düşük çözünürlükte çiz, arayüz keskin kalsın
		get_viewport().scaling_3d_scale = .65
		get_viewport().msaa_3d = Viewport.MSAA_DISABLED
	get_tree().root.size_changed.connect(_yerlesim)
	_yerlesim()
	kam_mod = int(_arg.get("kamera", "0"))
	sec_kam.select(kam_mod)
	# açılışta arkada gösterim maçı döner (Kaptan Mecit'teki gibi)
	_mac_kur(Taktik.kadro_kur(_takim(0, 0), veri.ligler[0].id), Taktik.kadro_kur(_takim(0, 1), veri.ligler[0].id), 4, 1, true)
	if _arg.has("koltuk"): vr_koltuk = int(_arg.koltuk)
	vr = VR.baslat(self, _arg.has("vrsahte"))
	if vr:
		kam.current = false
		ses.baslat()
	if _arg.has("ligsezon"):
		# deneme: bir ligde bir kulüple sezon kur, n haftayı hızlı simüle et
		lig.sil(); lig.yeni_sezon(int(_arg.get("liglig", "0")), int(_arg.get("ligtakim", "0")))
		for i in int(_arg.ligsezon):
			if lig.bitti(): lig.sonraki_sezon()    # deneme: hafta sayısı sezonu aşarsa yeni sezona geç (tarihçe dolar)
			lig.haftayi_simule()
	if _arg.has("duzen") or (OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('duzen') || ''", true)) == "1"): duzen_ac.call_deferred()
	if _arg.has("ligtarih"): lig.gorunum = "tarih"
	if _arg.has("ligfik"): lig.gorunum = "fikstur"
	if _arg.has("liggol"): lig.gorunum = "goller"
	if _arg.has("ligkadro"): lig.gorunum = "kadro"
	if _arg.has("ligodul"): lig.gorunum = "odul"
	if _arg.has("ligist"): lig.gorunum = "ist"
	if _arg.has("lig"): lig_goster(true)
	if _arg.has("ligmac"): lig_mac_basla()
	if _arg.has("mac"):
		menu_goster(false); _mac_kur(Taktik.kadro_kur(_takim(0, 0), veri.ligler[0].id, _arg.get("dz", "")), Taktik.kadro_kur(_takim(0, 1), veri.ligler[0].id), 4, 1, _arg.has("gosterim"))
	if _arg.has("gol"):
		var n := 0
		while M.state != "goal" and n < 60 * 600: _adim(); n += 1
		for i in int(float(_arg.gol) * 60): _adim()
	if _arg.has("tekrar"):
		# deneme: golden sonra tekrarın t. saniyesine git
		tekrar.kare(Tekrar.BEKLE + .01); tekrar.kare(float(_arg.tekrar))
	if _arg.has("dalis"):
		# deneme: bir kaleci şuta erken atlayana kadar oynat, sonra dalis saniye ilerlet (görüntü denetimi)
		var n := 0
		while n < 60 * 900:
			_adim(); n += 1
			var uc := false
			for p in M.P:
				if p.role == "G" and p.ucus > 1.45 and M.ball.shot: uc = true
			if uc: break
		for i in int(float(_arg.dalis) * 60): _adim()
	if _arg.has("tutus"):
		# deneme: kaleci topu tutsun (tutus = yakalamadan sonra geçen saniye)
		var n := 0
		while n < 60 * 900:
			_adim(); n += 1
			if M.ball.owner != null and M.ball.owner.role == "G" and not M.ball.owner.ayak and M.ball.owner.ucus > 0: break
		for i in int(float(_arg.tutus) * 60): _adim()
	if _arg.has("ileri"):
		var n := int(float(_arg.ileri) * 60)
		for i in n: _adim()
	if _arg.has("eldetop"):
		for p in M.P:
			if p.role == "G": M.ball.owner = p; p.ayak = false; p.ucus = 0.0; p.dec = 5.0; p.hold = 0.0; break
	if _arg.has("dene"):
		# başsız deneme: maçı sonuna kadar oynat, skor ve olay sayısını yaz
		var t0 := Time.get_ticks_msec()
		var n := 0
		while M.state != "over" and n < 60 * 60 * 20:
			if n % 90 == 0: M.giris.x = randf_range(-1, 1); M.giris.y = randf_range(-1, 1); M.giris.pasE = randf() < .3; M.giris.sutE = randf() < .2
			M.step(ADIM)
			for o in M.olaylar:
				if o[0] == "banner" and o[1] in ["PENALTI", "OFSAYT", "VAR", "SAKATLIK"] or o[0] == "kart": print("  ", M.min_label(), "' ", o[1], " · ", o[2])
			M.olaylar.clear(); n += 1
		print("TEST bitti: ", M.T[0].t.kisa, " ", M.T[0].score, "-", M.T[1].score, " ", M.T[1].t.kisa, " adım=", n, " dk=", M.min_label(), " goller=", M.events, " süre(ms)=", Time.get_ticks_msec() - t0, " faul=", M.faul, " ofsayt=", M.ofsayt, " kart=", M.kartlar, " korner=", M.korner, " değişiklik=", M.degisiklikler.map(func(d): return str(d.min) + "' " + d.in + "↔" + d.out))
		if lig_maci:
			_lig_bitir()
			print("LİG: hafta ", int(lig.d.hafta), " sıra ", lig.sira_biz(), " · son hafta ", lig.son_hafta.map(func(m): return lig.takim(int(m[0])).kisa + " " + str(int(m[2])) + "-" + str(int(m[3])) + " " + lig.takim(int(m[1])).kisa))
		get_tree().quit(); return
	if _arg.has("plonjon"):
		# deneme: misafir kalecisini uçuşun t. saniyesinde dondur
		for p in M.P:
			if p.role == "G" and p.team == int(_arg.get("kt", "1")):
				p.ucus_tur = int(_arg.get("tur", "1")); p.ucus = Futbolcu.UCUS_T - float(_arg.plonjon); p.ucus_yan = float(_arg.get("yan", "1"))
				p.ucus_z = float(_arg.get("z", ".8")); p.ucus_ofs = Vector2.ZERO
				M.ball.x = p.x + 3; M.ball.y = p.y + M.fwd_of(p.team) * 9; M.ball.owner = null; M.ball.vx = 0; M.ball.vy = 0
		_donuk = true
	if _dis_mi(): _dis_basla()
	if _arg.has("ekran"):
		if vr and _arg.has("bak"): vr.kafa.rotation_degrees = Vector3(float(_arg.bak), float(_arg.get("don", "0")), 0)
		if not _arg.has("lig"): menu_goster(_arg.has("menu"))
		if _arg.has("yardim"): yardim_goster(true)
		if _arg.has("rapor"):   # deneme: uzun maç raporu (kariyer satırı ekranı aşacak kadar uzun)
			son_rapor = "MAÇ RAPORU\nAnkara Siyah  1 - 3  İstanbul Sarı-Lacivert\n\nMAÇIN YILDIZI:  I. Yokzek  (İSL)  ·  8.1\n  Kariyeri: " + " · ".join(range(8).map(func(i): return "2021–22 Bursa Spor (29 M · 3 G) kiralık")) + "\n" + "\nSATIR".repeat(40)
			rapor_goster()
		await get_tree().create_timer(float(_arg.get("bekle", "1.5"))).timeout
		await RenderingServer.frame_post_draw
		get_viewport().get_texture().get_image().save_png(_arg.ekran)
		print("ekran kaydedildi: ", _arg.ekran, " seyirci=", stad.seyirci_sayisi(), " fps=", Engine.get_frames_per_second(),
			" çizim=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME),
			" üçgen=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_PRIMITIVES_IN_FRAME))
		get_tree().quit()

# ---------- CBM Modern: Champion Battle Manager maçını izleme (maçı CBM oynatır, burada yalnız çizilir) ----------
var dis: DisMac = null
var _dis_bekle := 0.0
var _dis_hiz := 1.0
func _dis_mi() -> bool:
	if _arg.has("cbmdene"): return true
	return OS.has_feature("web") and str(JavaScriptBridge.eval("location.search", true)).contains("cbm=1")
func _dis_js(ifade: String) -> String:
	if not OS.has_feature("web"): return ""
	var r = JavaScriptBridge.eval(ifade, true)
	return "" if r == null else str(r)
func _dis_basla() -> void:
	dis = DisMac.new()
	_arg["tekrarsiz"] = "1"; menu_goster(false); menu.visible = false; ui.visible = false
	AudioServer.set_bus_mute(0, true)       # sesler CBM'den gelir (taraftar, düdük, spiker)
	if OS.has_feature("web"): JavaScriptBridge.eval("window.__cbmHazir = true", true)
func _dis_kur(d: Dictionary) -> void:
	dis.kur(d); M = dis; _lig_bitis = 0.0
	if stad: stad.queue_free()
	stad = Stadyum.new(); stad.hafif = hafif; dunya.add_child(stad)
	stad.kur(M.T[0].kit, M.T[1].kit, veri.panolar)
	Futbolcu.hafif = hafif
	for f in oyuncular: f.queue_free()
	oyuncular.clear()
	for p in M.P: _futbolcu_kur(p)
	if hafif: _golge_kur()
	stad.skor(skor_yazi("-"))
func _dis_kare(dt: float) -> void:
	var kurulum := ""
	if _arg.has("cbmdene"):
		if M != dis: kurulum = FileAccess.get_file_as_string(_arg.cbmdene + ".kurulum.json")
	else:
		kurulum = _dis_js("(function(){var k=window.__cbmKurulum||'';window.__cbmKurulum='';return k})()")
	if kurulum != "": _dis_kur(JSON.parse_string(kurulum))
	if M != dis: return
	var kare := ""
	if _arg.has("cbmdene"):
		_dis_bekle += dt
		var L: Array = JSON.parse_string(FileAccess.get_file_as_string(_arg.cbmdene + ".kareler.json"))
		var i := mini(int(_dis_bekle * 30), L.size() - 1)
		kare = JSON.stringify(L[i])
	else:
		kare = _dis_js("window.__cbmKare||''")
		var km := _dis_js("window.__cbmKamera==null?'':String(window.__cbmKamera)")
		if km != "" and int(km) != kam_mod: kam_mod = int(km) % KAMERALAR.size()
	if kare != "":
		var f = JSON.parse_string(kare)
		if f is Dictionary:
			# CBM maçı hızlandırınca (x2, x4) ya da tekrarı ağır çekimde oynatınca çizim de aynı oyun zamanında akar:
			# kaleci uçuşu, vuruş, kamera takibi oyunun hızına uyar (yoksa x4'te kaleci geç atlar, kamera topu kaçırır)
			_dis_hiz = clampf(float(f.get("h", 1.0)), 0.05, 6.0)
			dis.kare(f, dt * _dis_hiz)
			for o in f.get("o", []):
				var c := dis.olay(o)
				if c.size(): _olay(c)
	var ol := _dis_js("JSON.stringify((window.__cbmOlay||[]).splice(0))")
	if ol != "":
		var L = JSON.parse_string(ol)
		if L is Array:
			for o in L:
				var c := dis.olay(o)
				if c.size(): _olay(c)
	_ciz(dt * _dis_hiz)

func _futbolcu_kur(p) -> Futbolcu:
	var kit: Dictionary = M.T[p.team].kit
	var gk: bool = p.role == "G"
	var serit: String = kit.c2 if Mac.renk_farki(kit.c1, kit.c2) > 128 else "#ffffff"
	var renk := {"forma": ("#f3d35a" if p.team == 0 else "#3ec46d") if gk else kit.c1,
		"serit": "#1d1d1d" if gk else serit, "sort": "#1d1d1d" if gk else kit.c2,
		"tozluk": "#1d1d1d" if gk else kit.c1, "ten": p.ten, "sac": p.sac, "eldiven": "#f4f4f4" if gk else null}
	var f := Futbolcu.new()
	dunya.add_child(f)
	f.kur(renk, p.no, .96 + float((p.no * 37) % 9) / 100.0)
	oyuncular.append(f)
	f.set_meta("oy", p)
	return f

# oyuncu değişikliği / eldiven giyen saha oyuncusu: o oyuncunun görünümünü yeniden kur
func _yeniden_kur(p) -> void:
	for f in oyuncular:
		if f.get_meta("oy") == p:
			oyuncular.erase(f); f.queue_free(); break
	var yeni := _futbolcu_kur(p)
	yeni.position = W(p.x, p.y)

func _golge_kur() -> void:
	if golgeler: golgeler.queue_free()
	var mm := MultiMesh.new(); mm.transform_format = MultiMesh.TRANSFORM_3D
	var q := PlaneMesh.new(); q.size = Vector2(1, 1); mm.mesh = q
	mm.instance_count = M.P.size() + 1
	golgeler = MultiMeshInstance3D.new(); golgeler.multimesh = mm
	var sm := ShaderMaterial.new(); var sh := Shader.new()
	sh.code = "shader_type spatial;\nrender_mode unshaded, depth_draw_never, cull_disabled;\nvoid fragment(){ float d = length(UV - vec2(.5)) * 2.0; ALBEDO = vec3(0.0); ALPHA = .45 * (1.0 - smoothstep(.35, 1.0, d)); }"
	sm.shader = sh; golgeler.material_override = sm
	golgeler.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	dunya.add_child(golgeler)

func _takim(lig: int, i: int) -> Dictionary: return veri.ligler[lig].takimlar[i]

# ---------- ortam: gece maçı ----------
func _ortam() -> void:
	var we := WorldEnvironment.new()
	var env := Environment.new()
	var sky := Sky.new()
	var ps := ProceduralSkyMaterial.new()
	ps.sky_top_color = Color("#070b18"); ps.sky_horizon_color = Color("#1c2638")
	ps.ground_bottom_color = Color("#0b0d10"); ps.ground_horizon_color = Color("#1c2638")
	ps.sun_angle_max = 0.0
	sky.sky_material = ps
	env.background_mode = Environment.BG_SKY; env.sky = sky
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color("#8ea4c4"); env.ambient_light_energy = .55
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC; env.tonemap_exposure = 1.05
	env.glow_enabled = true; env.glow_intensity = .55; env.glow_bloom = .05; env.glow_hdr_threshold = 1.2
	env.adjustment_enabled = true; env.adjustment_contrast = 1.06; env.adjustment_saturation = 1.08
	if hafif or _arg.has("mobil"):
		env.glow_enabled = false; env.adjustment_enabled = false
	we.environment = env
	add_child(we)
	# projektörlerin birleşik ışığı: hafif sıcak beyaz, gölgeli
	var gl := DirectionalLight3D.new()
	gl.rotation_degrees = Vector3(-58, 28, 0)
	gl.light_color = Color("#fff4e2"); gl.light_energy = 1.35
	gl.shadow_enabled = true; gl.shadow_bias = .03; gl.shadow_normal_bias = 1.2
	gl.directional_shadow_mode = DirectionalLight3D.SHADOW_PARALLEL_2_SPLITS
	gl.directional_shadow_max_distance = 140.0
	add_child(gl); gunes = gl
	if hafif:
		# Quest / telefon: gerçek gölge haritası yerine oyuncu altı yumuşak leke (çok daha ucuz)
		gl.shadow_enabled = false
	# karşı projektör: gölgesiz dolgu
	var dl := DirectionalLight3D.new()
	dl.rotation_degrees = Vector3(-50, 208, 0); dl.light_color = Color("#e8eeff"); dl.light_energy = .55
	add_child(dl)

# ---------- maç kurulumu ----------
func _mac_kur(ev: Dictionary, dep: Dictionary, sure: int, zor: int, gosterim: bool, deplasman := false) -> void:
	M = Mac.new(ev, dep, sure, zor, gosterim, deplasman); _lig_bitis = 0.0
	if stad: stad.queue_free()
	stad = Stadyum.new(); stad.hafif = hafif; dunya.add_child(stad)
	# tribünler ve taraftar sesi gerçek ev sahibine göre: kullanıcı deplasmandaysa stat rakibin rengindedir
	stad.kur(M.T[_y(0)].kit, M.T[_y(1)].kit, veri.panolar)
	Futbolcu.hafif = hafif
	for f in oyuncular: f.queue_free()
	oyuncular.clear()
	for p in M.P: _futbolcu_kur(p)
	_birikim = 0.0
	if hafif: _golge_kur()
	_tabela()

# ---------- döngü ----------
func _process(dt: float) -> void:
	if dis: _dis_kare(dt); return
	_girdi()
	var tekrarda := tekrar.kare(dt) if (M != null and vr == null) else false
	if _tekrar_kutu: _tekrar_kutu.visible = tekrarda
	if tekrarda: _birikim = 0.0; afis.visible = false; _afis_t = 0.0
	# en çok 2 motor adımı / kare: yavaş bir karenin ardından "yetişmeye çalışıp" kareleri daha da yavaşlatma sarmalı olmasın
	var odt := dt * (.3 if _yavas > 0 else 1.0); _yavas -= dt
	_birikim = minf(_birikim + odt, ADIM * 2)
	var adim := 0
	while _birikim >= ADIM and adim < 2 and not _donuk and not tekrarda:
		_birikim -= ADIM; adim += 1
		_adim()
	_ciz(dt)
	if not _arg.has("temiz"): mola.rehber(dt, 1 if vr != null else (2 if dokunmatik else 0))
	if mola_panel.visible: _mola_ciz()
	if lig_maci and M and M.state == "over":
		# lig maçı bitti: düdükten birkaç saniye sonra sonuç işlenir, lig ekranına dönülür
		_lig_bitis += dt
		if _lig_bitis > 4.5: _lig_bitir()
	elif M and M.state == "over" and not M.demo and not lig_maci:
		# hızlı maç bitti: düdükten birkaç saniye sonra ana menüye dönülür, skor afişte kalır (aynı eşleşme MAÇA BAŞLA ile yeniden oynanır)
		_lig_bitis += dt
		if _lig_bitis > 4.5: _hizli_bitir()
	if _afis_t > 0:
		_afis_t -= dt
		if _afis_t <= 0: afis.visible = false

func _adim() -> void:
	if M == null: return
	if not menu_acik or M.demo:
		M.step(ADIM)
		tekrar.adim(M)
	for o in M.olaylar: _olay(o)
	M.olaylar.clear()
	if M.state == "over" and M.demo:
		# gösterim maçı biter bitmez yenisi başlar
		var lg: Dictionary = veri.ligler[randi() % veri.ligler.size()]
		var L: Array = lg.takimlar
		var a := randi() % L.size(); var b := (a + 1 + randi() % (L.size() - 1)) % L.size()
		_mac_kur(Taktik.kadro_kur(L[a], lg.id), Taktik.kadro_kur(L[b], lg.id), 4, 1, true)

func _olay(o: Array) -> void:
	match o[0]:
		"banner": afis_goster(o[1], o[2], 2.2)
		"flash": afis_goster(o[1], "", 1.0)
		"duduk": ses.duduk(int(o[1]))
		"vurus": ses.vurus(float(o[1]))
		"sut":
			# vuruşun ağırlığı (FIFA hissi): bir an ağır çekim, kamera hafifçe sarsılır, telefonda kısa titreşim
			_yavas = .07; _sarsinti = maxf(_sarsinti, .35 * float(o[2]))
			if vr == null and dokunmatik and not M.demo: Input.vibrate_handheld(25)
			if vr and not M.demo: vr.sag.trigger_haptic_pulse("haptic", 0.0, .8, .06, 0.0)
		"ooo": ses.ooo()
		"gol":
			ses.gol(); _sarsinti = 1.0
			if vr == null and dokunmatik and not M.demo: Input.vibrate_handheld(90)
			if vr and not M.demo:
				vr.sag.trigger_haptic_pulse("haptic", 0.0, 1.0, .2, 0.0); vr.sol.trigger_haptic_pulse("haptic", 0.0, 1.0, .2, 0.0)
			if vr == null and not _arg.has("tekrarsiz"): tekrar.gol()
			ses.taraftar(_y(int(o[1])), "tezahurat", 2.4); ses.taraf_sustur(_y(1 - int(o[1])), 25.0)
			_tabela()
		"taraftar": ses.taraftar(_y(int(o[1])), o[2])
		"tik": ses.tik()
		"kart":
			afis_goster({"S": "SARI KART", "K": "KIRMIZI KART", "K2": "İKİNCİ SARI · KIRMIZI"}[o[1]], o[2], 2.6)
		"degisiklik", "kaleci_degisti": _yeniden_kur(o[1])
		"gol_iptal":
			_tabela(); ses.taraftar(_y(int(o[1])), "yuh"); ses.taraftar(_y(1 - int(o[1])), "alkis", 1.2)
		"atildi":
			for f in oyuncular:
				if f.get_meta("oy") == o[1]: f.visible = false

# tekrar oynarken herhangi bir tuş / dokunuş tekrarı geçer
func _input(e: InputEvent) -> void:
	if not tekrar.aktif: return
	if (e is InputEventKey or e is InputEventScreenTouch or e is InputEventMouseButton or e is InputEventJoypadButton) and e.pressed:
		tekrar.bitir(); if _tekrar_kutu: _tekrar_kutu.visible = false
		get_viewport().set_input_as_handled()

func _girdi() -> void:
	if dok: dok.visible = dokunmatik and M != null and not M.demo and not menu_acik and vr == null and not tekrar.aktif
	if M == null or M.demo or menu_acik: return
	if vr: vr.girdi(M); return
	var v := Vector2(Input.get_axis("ui_left", "ui_right"), Input.get_axis("ui_up", "ui_down"))
	if Input.is_key_pressed(KEY_A): v.x -= 1
	if Input.is_key_pressed(KEY_D): v.x += 1
	if Input.is_key_pressed(KEY_W): v.y -= 1
	if Input.is_key_pressed(KEY_S): v.y += 1
	var joy := Vector2(Input.get_joy_axis(0, JOY_AXIS_LEFT_X), Input.get_joy_axis(0, JOY_AXIS_LEFT_Y))
	if joy.length() > .2: v = joy
	if dok and dok.vec != Vector2.ZERO: v = dok.vec
	if dok and dok.pas: M.tus_bas("pas"); dok.pas = false
	if dok and dok.sut: M.tus_bas("sut"); dok.sut = false
	if dok and dok.pas_birak: M.tus_birak("pas"); dok.pas_birak = false
	if dok and dok.sut_birak: M.tus_birak("sut"); dok.sut_birak = false
	if dok: dok.guc_ayarla(M.dolum_orani("pas"), M.dolum_orani("sut"))
	if v.length() > 1: v = v.normalized()
	# ekran yönünü sahaya çevir: kameranın sağı ve ileri yönü (yere izdüşüm)
	var sag := kam.global_basis.x; sag.y = 0; sag = sag.normalized()
	var ileri := -kam.global_basis.z; ileri.y = 0; ileri = ileri.normalized()
	var w := sag * v.x - ileri * v.y
	M.giris.x = w.x; M.giris.y = w.z

func _unhandled_input(e: InputEvent) -> void:
	if e is InputEventKey and e.pressed and lig_ekran.visible:
		var n := lig.satirlar().size()
		match e.keycode:
			KEY_UP, KEY_W: lig_ekran.satir = posmod(lig_ekran.satir - 1, n); lig_ekran.ciz(); return
			KEY_DOWN, KEY_S: lig_ekran.satir = posmod(lig_ekran.satir + 1, n); lig_ekran.ciz(); return
			KEY_LEFT, KEY_A: lig_kay(lig_ekran.satir, -1); return
			KEY_RIGHT, KEY_D: lig_kay(lig_ekran.satir, 1); return
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: lig_bas(lig_ekran.satir); return
			KEY_ESCAPE, KEY_M: lig_goster(false); return
	if e is InputEventKey and e.pressed and mola_panel.visible:
		match e.keycode:
			KEY_UP, KEY_W: mola_satir = Mola.SIRA[posmod(Mola.SIRA.find(mola_satir) - 1, Mola.SIRA.size())]; return
			KEY_DOWN, KEY_S: mola_satir = Mola.SIRA[posmod(Mola.SIRA.find(mola_satir) + 1, Mola.SIRA.size())]; return
			KEY_LEFT, KEY_A: mola.kay(mola_satir, -1); return
			KEY_RIGHT, KEY_D: mola.kay(mola_satir, 1); return
			KEY_ENTER, KEY_KP_ENTER, KEY_SPACE: mola.bas(mola_satir); return
	# bırakınca: basılı tutulan PAS / ŞUT çıkar
	if M and e is InputEventKey and not e.pressed:
		match e.keycode:
			KEY_X, KEY_K: M.tus_birak("pas")
			KEY_Z, KEY_SPACE, KEY_L: M.tus_birak("sut")
	elif M and e is InputEventJoypadButton and not e.pressed:
		match e.button_index:
			JOY_BUTTON_A: M.tus_birak("pas")
			JOY_BUTTON_B, JOY_BUTTON_X: M.tus_birak("sut")
	if e is InputEventKey and e.pressed and not e.echo:
		match e.keycode:
			KEY_X, KEY_K: if M: M.tus_bas("pas")
			KEY_Z, KEY_SPACE, KEY_L: if M: M.tus_bas("sut")
			KEY_C: _kamera((kam_mod + 1) % KAMERALAR.size())
			KEY_ESCAPE, KEY_M: if M and not M.demo: menu_goster(not menu_acik)
	elif e is InputEventJoypadButton and e.pressed:
		match e.button_index:
			JOY_BUTTON_A: if M: M.tus_bas("pas")
			JOY_BUTTON_B, JOY_BUTTON_X: if M: M.tus_bas("sut")
			JOY_BUTTON_Y: _kamera((kam_mod + 1) % KAMERALAR.size())
			JOY_BUTTON_START: if M and not M.demo: menu_goster(not menu_acik)

static func W(x: float, y: float, z := 0.0) -> Vector3: return Vector3(x - PW / 2, z, y - PL / 2)

func _ciz(dt: float) -> void:
	if M == null: return
	var now := Time.get_ticks_msec() / 1000.0
	var gol: int = -1 if tekrar.aktif else M.son_gol_takimi()
	for f: Futbolcu in oyuncular:
		if not f.visible: continue
		var p = f.get_meta("oy")
		f.position = W(p.x, p.y)
		f.poz(p, M, now, gol)
	var b = M.ball
	top.position = W(b.x, b.y, b.z + .12)
	# kaleci topu tutuyorsa top yerde değil ellerinin arasında görünür (yakalama, göğse alma, atlayıp tutma)
	if b.owner != null and b.owner.role == "G" and not b.owner.ayak:
		for f: Futbolcu in oyuncular:
			if f.get_meta("oy") != b.owner: continue
			var sk: Skeleton3D = f.iskelet
			var eL: Vector3 = sk.global_transform * (sk.get_bone_global_pose(sk.find_bone("dirsekL")) * Vector3(0, -.27, 0))
			var eR: Vector3 = sk.global_transform * (sk.get_bone_global_pose(sk.find_bone("dirsekR")) * Vector3(0, -.27, 0))
			var ileri: Vector3 = sk.global_transform.basis.z.normalized()
			top.position = (eL + eR) * .5 + ileri * .1
			break
	top.rotate(Vector3(b.vy, 0, -b.vx).normalized() if (b.vx != 0 or b.vy != 0) else Vector3.UP, Vector2(b.vx, b.vy).length() * dt / .12)
	if golgeler:
		var mm := golgeler.multimesh
		for i in M.P.size():
			var p = M.P[i]
			mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3(.9, 1, .9) * (1.6 if p.slide > 0 else 1.0)), W(p.x, p.y, .03)))
		mm.set_instance_transform(M.P.size(), Transform3D(Basis().scaled(Vector3(.28, 1, .28) * (1.0 / (1.0 + b.z * .4))), W(b.x, b.y, .03)))
		for i in range(M.P.size() + 1, mm.instance_count): mm.set_instance_transform(i, Transform3D(Basis().scaled(Vector3.ONE * .001), Vector3(0, -5, 0)))
	isaret.visible = M.ctrl != null and not M.demo
	if isaret.visible: isaret.position = W(M.ctrl.x, M.ctrl.y, .02)
	# tribün heyecanı: gol, top kaleye yaklaştıkça
	# her tribün kendi takımı için coşar: golde atan takımın taraftarı zıplar, diğeri yıkılır;
	# hücumda top rakip kaleye yaklaştıkça hücum edenin taraftarı kıpırdanır
	var hucum: int = b.owner.team if b.owner != null else b.last_team
	var yakin := 1.0 - clampf(absf(b.y - M.goal_y_of(hucum)) / 30.0, 0, 1)
	# tribün tarafları gerçek ev/deplasman: _y(takım) → taraf (0 ev sahibi tribünleri, 1 misafir)
	var gy := _y(gol) if gol >= 0 else -1; var hy := _y(hucum)
	if gy >= 0: stad.heyecan(1.0 if gy == 0 else 0.0, 1.0 if gy == 1 else 0.0, 1.0 if gy == 1 else 0.0, 1.0 if gy == 0 else 0.0)
	else: stad.heyecan(yakin * .3 if hy == 0 else 0.0, yakin * .3 if hy == 1 else 0.0)
	ses.heyecan(1.0 if gol >= 0 else yakin)
	var fark: int = M.T[_y(0)].score - M.T[_y(1)].score
	ses.taraf_heyecan(clampf((yakin if hy == 0 else 0.0) + .15 * fark, 0, 1), clampf((yakin if hy == 1 else 0.0) - .15 * fark, 0, 1))
	dakika.text = M.min_label() + "'"
	_kamera_guncelle(dt)

var _yavas := 0.0
var _sarsinti := 0.0
func _kamera_guncelle(dt: float) -> void:
	if vr: return
	var b = M.ball
	var bw := W(b.x, b.y, b.z)
	var ileri_y := 1.0 if M.goal_y_of(0) == 0.0 else -1.0     # ev sahibinin hücum yönü (dünya Z'de ters)
	var poz: Vector3; var bak: Vector3; var fov: float
	var mod := 4 if tekrar.aktif else kam_mod     # tekrar: yakın yayın kamerası
	match mod:
		0:  # yayın: yan tribün üstü, topu yatayda izler
			# FIFA 2000 ölçüsü: biraz daha yakın, oyuncular telefonda daha büyük; top hızlanınca (uzun pas, şut) hafifçe açılır
			var bhiz: float = Vector2(b.vx, b.vy).length() if b.owner == null else 0.0
			poz = Vector3(49, 19, clampf(bw.z * .8, -34, 34)); bak = Vector3(bw.x * .6, 0, bw.z); fov = 27.0 + 4.0 * clampf((bhiz - 8.0) / 16.0, 0, 1)
		1:  # tele: köşe, yüksek
			poz = Vector3(46, 24, 66); bak = Vector3(bw.x * .7, 0, bw.z * .85); fov = 34
		2:  # dinamik: ev sahibinin arkasından, hücum yönüne bakar
			poz = Vector3(bw.x * .55, 15, clampf(bw.z + ileri_y * 26, -PL / 2 - 14, PL / 2 + 14)); bak = Vector3(bw.x * .8, 0, bw.z - ileri_y * 8); fov = 48
		4:  # yakın yayın: topu yandan, yakından ve alçaktan izler (gerçek hareketler en iyi burada görünür)
			poz = Vector3(39.5, 6.5, clampf(bw.z + 3, -48, 48)); bak = Vector3(bw.x, .8, bw.z); fov = clampf(46 - (39.5 - bw.x) * .38, 18, 46)
		_:  # saha kenarı: göz hizası
			poz = Vector3(PW / 2 + 5, 1.75, clampf(bw.z, -40, 40) * .7); bak = Vector3(bw.x, .9, bw.z); fov = 52
	if dis and M == dis:
		# CBM Modern telefonda dik ekranda izlenir: yatay görüş çok dar kalır, köşe vuruşunda top kadrajdan çıkar.
		# Dik ekranda kamera topu ortalar ve görüş açısını ekran oranına göre genişletir.
		var en_boy := get_viewport().get_visible_rect().size.aspect()
		if en_boy < 1.0:
			bak = Vector3(bw.x, bak.y, bw.z)
			fov = minf(fov / sqrt(maxf(en_boy, .35)) * .85, 72.0)
	if _arg.has("golcu") and M.gol_atan != null:
		var g := W(M.gol_atan.x, M.gol_atan.y)
		kam.position = g + Vector3(-9.0 if g.x > 0 else 9.0, 4.0, 6.0); kam.fov = 45; kam.look_at(g + Vector3(0, .9, 0)); return
	if _arg.has("kyakin"):
		# deneme: uçan kaleciye yakın, sahadan kaleye bakan kamera
		for p in M.P:
			if p.role == "G" and (p.ucus > 0 or absf(p.y - M.ball.y) < 12):
				var g := W(p.x, p.y); var ic := -signf(g.z) if g.z != 0 else 1.0
				kam.position = g + Vector3(2.5, 1.6, -ic * 6.5 * float(_arg.get("kyon", "-1"))); kam.fov = 40; kam.look_at(g + Vector3(0, .8, 0)); return
	if _arg.has("yakin"):
		if b.owner != null: bw = W(b.owner.x, b.owner.y)
		kam.position = bw + Vector3(4.0, 1.9, 3.0); kam.fov = 42; kam.look_at(bw + Vector3(0, .9, 0)); return
	var k := 1.0 - exp(-dt * 3.2)
	if kam.position == Vector3.ZERO: kam.fov = fov
	kam.position = kam.position.lerp(poz, k) if kam.position != Vector3.ZERO else poz
	_kam_hedef = _kam_hedef.lerp(bak, 1.0 - exp(-dt * 4.5)) if _kam_hedef != Vector3.ZERO else bak
	kam.fov = lerpf(kam.fov, fov, k)
	kam.look_at(_kam_hedef)
	if _sarsinti > .01:
		var g := _sarsinti * _sarsinti * .012
		kam.rotate_object_local(Vector3.RIGHT, randf_range(-g, g)); kam.rotate_object_local(Vector3.UP, randf_range(-g, g))
		_sarsinti *= exp(-dt * 7.0)

func _kamera(i: int) -> void:
	kam_mod = i
	sec_kam.select(i)
	afis_goster("KAMERA", KAMERALAR[i], .9)

# ---------- arayüz ----------
func _arayuz() -> void:
	ui = CanvasLayer.new(); add_child(ui)
	var tema := Theme.new()
	tema.default_font_size = 18
	# tabela (sol üst)
	var tp := PanelContainer.new()
	tp.add_theme_stylebox_override("panel", _kutu(Color(0.04, 0.07, 0.09, .82), 10))
	tp.position = Vector2(18, 16); _tp = tp
	var th := HBoxContainer.new(); th.add_theme_constant_override("separation", 14)
	tp.add_child(th)
	tabela = Label.new(); tabela.add_theme_font_size_override("font_size", 24)
	dakika = Label.new(); dakika.add_theme_font_size_override("font_size", 24); dakika.add_theme_color_override("font_color", Color("#f3d35a"))
	th.add_child(tabela); th.add_child(dakika)
	ui.add_child(tp)
	# afiş (orta)
	afis = PanelContainer.new()
	afis.add_theme_stylebox_override("panel", _kutu(Color(0.04, 0.07, 0.09, .86), 14))
	afis.custom_minimum_size = Vector2(520, 0)
	var av := VBoxContainer.new(); av.alignment = BoxContainer.ALIGNMENT_CENTER
	afis_ust = Label.new(); afis_ust.add_theme_font_size_override("font_size", 40); afis_ust.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	afis_ust.add_theme_color_override("font_color", Color("#f3d35a"))
	afis_alt = Label.new(); afis_alt.add_theme_font_size_override("font_size", 20); afis_alt.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	av.add_child(afis_ust); av.add_child(afis_alt); afis.add_child(av)
	afis.visible = false
	var ak := CenterContainer.new(); ak.set_anchors_preset(Control.PRESET_TOP_WIDE); ak.offset_top = 110; ak.offset_bottom = 260
	ak.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ak.add_child(afis); ui.add_child(ak); _ak = ak
	# tekrar şeridi
	var tk := PanelContainer.new(); tk.add_theme_stylebox_override("panel", _kutu(Color(0.62, 0.08, 0.1, .88), 10))
	var tkh := HBoxContainer.new(); tkh.add_theme_constant_override("separation", 14); tk.add_child(tkh)
	var tl := Label.new(); tl.text = "TEKRAR"; tl.add_theme_font_size_override("font_size", 26); tl.add_theme_color_override("font_color", Color.WHITE)
	var tl2 := Label.new(); tl2.text = "Geçmek için dokun"; tl2.add_theme_font_size_override("font_size", 16); tl2.add_theme_color_override("font_color", Color(1, 1, 1, .8))
	tl2.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	tkh.add_child(tl); tkh.add_child(tl2)
	var tkc := CenterContainer.new(); tkc.set_anchors_preset(Control.PRESET_TOP_WIDE); tkc.offset_top = 70; tkc.offset_bottom = 120
	tkc.mouse_filter = Control.MOUSE_FILTER_IGNORE; tkc.add_child(tk); ui.add_child(tkc)
	tkc.visible = false; _tekrar_kutu = tkc
	# kısayollar (sol alt)
	bilgi = Label.new()
	bilgi.text = "WASD / oklar: koş · X: pas / oyuncu seç · Z / boşluk: şut · kay · C: kamera · M: menü   ·   Kol: sol çubuk koş · A pas · B şut · Y kamera"
	bilgi.add_theme_font_size_override("font_size", 14); bilgi.add_theme_color_override("font_color", Color(1, 1, 1, .75))
	bilgi.set_anchors_preset(Control.PRESET_BOTTOM_LEFT); bilgi.position = Vector2(18, -34)
	ui.add_child(bilgi)
	var imza := Label.new(); imza.text = "Bir Mr. Anduv! yapımıdır."
	imza.add_theme_stylebox_override("normal", _kutu(Color(0.04, 0.07, 0.09, .7), 8))
	imza.add_theme_font_size_override("font_size", 15); imza.add_theme_color_override("font_color", Color(1, 1, 1, .8))
	imza.set_anchors_preset(Control.PRESET_TOP_RIGHT); imza.position = Vector2(-250, 16); _imza = imza
	ui.add_child(imza)
	# dokunmatik (telefon / tablet)
	dokunmatik = DisplayServer.is_touchscreen_available() or _arg.has("dokun")
	if dokunmatik:
		bilgi.visible = false
		dok = Dokunmatik.new(); dok.visible = false; ui.add_child(dok)
		var kc := ConfigFile.new()
		klasik = false     # klasik kumanda kaldırıldı (11 Kas 2026); eski ayar yok sayılır
		dok.klasik = klasik
		dok.mola_istendi.connect(func(): if M and not M.demo: menu_goster(true))
	# menü
	menu = PanelContainer.new()
	menu.add_theme_stylebox_override("panel", _kutu(Color("#f5ecd8"), 16))
	menu.custom_minimum_size = Vector2(800, 0)
	var mv := VBoxContainer.new(); mv.add_theme_constant_override("separation", 10)
	var bas := PanelContainer.new(); bas.add_theme_stylebox_override("panel", _kutu(Color("#1f3b3c"), 12))
	var bv := VBoxContainer.new()
	var bl := Label.new(); bl.text = "Kaptan Mecit 3"; bl.add_theme_font_size_override("font_size", 34); bl.add_theme_color_override("font_color", Color.WHITE)
	var bl2 := Label.new(); bl2.text = "Bir Mr. Anduv! yapımıdır."; bl2.add_theme_font_size_override("font_size", 15); bl2.add_theme_color_override("font_color", Color("#cfe3d6"))
	bv.add_child(bl); bv.add_child(bl2); bas.add_child(bv); mv.add_child(bas)
	sec_lig = _secici(mv, "Lig"); sec_ev = _secici(mv, "Senin takımın"); sec_dep = _secici(mv, "Rakip")
	sec_dz = _secici(mv, "Diziliş (Otomatik: asistan kadroya en uygununu seçer)")
	sec_dz.add_item("Otomatik")
	for d in Taktik.siralama(): sec_dz.add_item(d)
	var sat := HBoxContainer.new(); sat.add_theme_constant_override("separation", 10)
	sec_sure = _secici(sat, "Süre"); sec_zor = _secici(sat, "Zorluk"); sec_kam = _secici(sat, "Kamera"); sec_zih = _secici(sat, "Oyun anlayışı")
	for z in ["Savunma", "Dengeli", "Hücum"]: sec_zih.add_item(z)
	sec_zih.select(1)
	mv.add_child(sat)
	for l in veri.ligler: sec_lig.add_item(l.ad + " · " + l.ulke)
	for s in SURELER: sec_sure.add_item(str(s) + " dk")
	for z in ZORLUK: sec_zor.add_item(z)
	for k in KAMERALAR: sec_kam.add_item(k)
	sec_sure.select(1); sec_zor.select(1)
	sec_lig.item_selected.connect(func(_i): _takimlari_doldur())
	sec_kam.item_selected.connect(func(i): kam_mod = i)
	_takimlari_doldur()
	var dug := Button.new(); dug.text = "Maça başla"; dug.add_theme_font_size_override("font_size", 24)
	dug.add_theme_stylebox_override("normal", _kutu(Color("#e5722f"), 12)); dug.add_theme_stylebox_override("hover", _kutu(Color("#f08442"), 12))
	dug.add_theme_stylebox_override("pressed", _kutu(Color("#c95f22"), 12)); dug.add_theme_color_override("font_color", Color.WHITE)
	dug.custom_minimum_size = Vector2(0, 58)
	dug.pressed.connect(basla)
	mv.add_child(dug)
	var lgd := Button.new(); lgd.text = "Lig · Kupalar"; lgd.add_theme_font_size_override("font_size", 22)
	lgd.add_theme_stylebox_override("normal", _kutu(Color("#2f5d8c"), 12)); lgd.add_theme_stylebox_override("hover", _kutu(Color("#3a6fa3"), 12))
	lgd.add_theme_stylebox_override("pressed", _kutu(Color("#24486d"), 12)); lgd.add_theme_color_override("font_color", Color.WHITE)
	lgd.custom_minimum_size = Vector2(0, 50)
	lgd.pressed.connect(func(): lig_goster(true))
	mv.add_child(lgd)
	if not OS.has_feature("android") or OS.has_feature("web"):    # Quest (yerel Android) derlemesinde klavye yok: düzenleme yalnız telefon/web/masaüstünde
		var dz := Button.new(); dz.text = "Düzenleme modu  ·  kulüp ve oyuncu adları"; dz.add_theme_font_size_override("font_size", 18)
		dz.add_theme_stylebox_override("normal", _kutu(Color("#5a4a7a"), 10)); dz.add_theme_stylebox_override("hover", _kutu(Color("#6a5a8c"), 10))
		dz.add_theme_color_override("font_color", Color.WHITE); dz.custom_minimum_size = Vector2(0, 46)
		dz.pressed.connect(duzen_ac)
		mv.add_child(dz)
	var yd := Button.new(); yd.text = "Nasıl oynanır"; yd.add_theme_font_size_override("font_size", 18)
	yd.add_theme_stylebox_override("normal", _kutu(Color("#1f3b3c"), 10)); yd.add_theme_stylebox_override("hover", _kutu(Color("#2a4e50"), 10))
	yd.add_theme_color_override("font_color", Color.WHITE)
	yd.pressed.connect(func(): yardim_goster(not yardim_acik))
	var alt := HBoxContainer.new(); alt.add_theme_constant_override("separation", 10)
	yd.size_flags_horizontal = Control.SIZE_EXPAND_FILL; alt.add_child(yd)
	dil_dugme = Button.new(); dil_dugme.add_theme_font_size_override("font_size", 18); dil_dugme.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	dil_dugme.add_theme_stylebox_override("normal", _kutu(Color("#1f3b3c"), 10)); dil_dugme.add_theme_stylebox_override("hover", _kutu(Color("#2a4e50"), 10))
	dil_dugme.add_theme_color_override("font_color", Color.WHITE); dil_dugme.auto_translate_mode = Node.AUTO_TRANSLATE_MODE_DISABLED
	dil_dugme.pressed.connect(dil_degistir); alt.add_child(dil_dugme)
	# mobil uygulamanın içindeyken (Klasik / Modern seçimli kabuk): oyun seçimine dön
	if OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('kabuk') || ''", true)) == "1":
		var ks := Button.new(); ks.text = "Oyun seçimi"; ks.add_theme_font_size_override("font_size", 18); ks.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		ks.add_theme_stylebox_override("normal", _kutu(Color("#1f3b3c"), 10)); ks.add_theme_stylebox_override("hover", _kutu(Color("#2a4e50"), 10))
		ks.add_theme_color_override("font_color", Color.WHITE)
		ks.pressed.connect(func(): JavaScriptBridge.eval("location.href='../index.html?sec=1'"))
		alt.add_child(ks)
	mv.add_child(alt)
	# standart: puan ver (yalnız telefon uygulamasında), arkadaşına öner, bize yaz
	var alt2 := HBoxContainer.new(); alt2.add_theme_constant_override("separation", 10)
	var std := [["Arkadaşına öner", paylas], ["Bize yaz", bize_yaz]]
	if kabuk(): std.push_front(["★ Puan ver", puan_ver])
	for x in std:
		var sb := Button.new(); sb.text = x[0]; sb.add_theme_font_size_override("font_size", 16); sb.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		sb.add_theme_stylebox_override("normal", _kutu(Color("#1f3b3c"), 10)); sb.add_theme_stylebox_override("hover", _kutu(Color("#2a4e50"), 10))
		sb.add_theme_color_override("font_color", Color.WHITE)
		sb.pressed.connect(x[1]); alt2.add_child(sb)
	mv.add_child(alt2)
	_dil_yaz()
	menu.add_child(mv)
	ui.add_child(_kaydirmali(menu))
	# düzenleme modu
	duzen_ekran = DuzenEkran.new(self, veri); ui.add_child(_kaydirmali(duzen_ekran))
	duzen_ekran.kapandi.connect(func(degisti):
		if degisti:
			var ls := sec_lig.selected; var es := sec_ev.selected; var ds := sec_dep.selected
			sec_lig.clear()
			for l in veri.ligler: sec_lig.add_item(l.ad + " · " + l.ulke)
			sec_lig.select(ls); _takimlari_doldur(); sec_ev.select(es); sec_dep.select(ds)
		menu.visible = menu_acik and not lig_acik and not (M != null and not M.demo))
	# lig ekranı (tam ekran)
	lig_ekran = LigEkran.new(lig); ui.add_child(lig_ekran)
	lig_ekran.eylem.connect(func(a):
		if a == "geri": lig_kay(lig_ekran.satir, -1)
		elif a == "ileri": lig_kay(lig_ekran.satir, 1)
		else: lig_bas(lig_ekran.satir))
	# mola: yedek kulübesi
	mola_panel = PanelContainer.new(); mola_panel.visible = false
	mola_panel.add_theme_stylebox_override("panel", _kutu(Color("#f5ecd8"), 16))
	mola_panel.custom_minimum_size = Vector2(760, 0)
	var ov := VBoxContainer.new(); ov.add_theme_constant_override("separation", 5)
	var ob := PanelContainer.new(); ob.add_theme_stylebox_override("panel", _kutu(Color("#1f3b3c"), 12))
	mola_baslik = Label.new(); mola_baslik.add_theme_font_size_override("font_size", 26); mola_baslik.add_theme_color_override("font_color", Color.WHITE)
	ob.add_child(mola_baslik); ov.add_child(ob)
	for i in Mola.SATIRLAR.size():
		var b := Button.new(); b.alignment = HORIZONTAL_ALIGNMENT_LEFT; b.add_theme_font_size_override("font_size", 17)
		b.add_theme_stylebox_override("normal", _kutu(Color(1, 1, 1, .55), 8)); b.add_theme_stylebox_override("hover", _kutu(Color(1, 1, 1, .9), 8))
		b.add_theme_stylebox_override("pressed", _kutu(Color("#f3d35a"), 8)); b.add_theme_stylebox_override("focus", _kutu(Color(1, 1, 1, .9), 8))
		b.add_theme_stylebox_override("hover_pressed", _kutu(Color("#f3d35a"), 8))
		# her durumda koyu yazı (dokununca/odakta beyaz zeminde yazı kayboluyordu)
		for k in ["font_color", "font_hover_color", "font_pressed_color", "font_focus_color", "font_hover_pressed_color"]: b.add_theme_color_override(k, Color("#1d2b2c"))
		b.pressed.connect(func(): mola_satir = i; mola.bas(i))
		mola_dugmeler.append(b)
	for i in Mola.SIRA: ov.add_child(mola_dugmeler[i])   # ekranda sıra (Kontrol satırı gizli)
	mola_mesaj = Label.new(); mola_mesaj.add_theme_font_size_override("font_size", 15); mola_mesaj.add_theme_color_override("font_color", Color("#5b6466"))
	mola_mesaj.text = "Oklar: satır ve değer  ·  Enter: seç  ·  M / Esc: maça dön"
	ov.add_child(mola_mesaj)
	mola_panel.add_child(ov)
	ui.add_child(_kaydirmali(mola_panel))
	# Nasıl oynanır
	yardim_panel = PanelContainer.new(); yardim_panel.visible = false
	yardim_panel.add_theme_stylebox_override("panel", _kutu(Color(0.04, 0.07, 0.09, .95), 16))
	var yv := VBoxContainer.new()
	var yl := Label.new(); _yardim_yazi = yl; yl.text = Mola.YARDIM; yl.add_theme_font_size_override("font_size", 17); yl.add_theme_color_override("font_color", Color.WHITE)
	var yk := Button.new(); yk.text = "Kapat"; yk.pressed.connect(func(): yardim_goster(false))
	var ys := Button.new(); ys.text = "Rehberi baştan göster"; ys.pressed.connect(func(): mola.rehber_sifirla(); yardim_goster(false))
	var yvs := Button.new(); yvs.text = "Verilerimi sil"
	yvs.pressed.connect(func(): yvs.text = mola.veri_sil())
	var yh := HBoxContainer.new(); yh.add_theme_constant_override("separation", 10); yh.add_child(ys); yh.add_child(yvs); yh.add_child(yk)
	_yardim_dugmeler = [ys, yvs]
	# üstte de her zaman görünen bir kapatma düğmesi (uzun maç raporunda alttaki düğme ekran dışında kalabiliyordu)
	var yu := HBoxContainer.new(); var ybos := Control.new(); ybos.size_flags_horizontal = Control.SIZE_EXPAND_FILL; yu.add_child(ybos)
	var yk2 := Button.new(); yk2.text = "Kapat  ×"; yk2.add_theme_font_size_override("font_size", 20); yk2.custom_minimum_size = Vector2(150, 52)
	yk2.pressed.connect(func(): yardim_goster(false)); yu.add_child(yk2); _yardim_ust_dugme = yk2
	yk.custom_minimum_size = Vector2(150, 52)
	yv.add_child(yu); yv.add_child(yl); yv.add_child(yh); yardim_panel.add_child(yv)
	ui.add_child(_kaydirmali(yardim_panel))

# küçük ekranda sığmayan panel parmakla kaydırılır; panel gizliyken dokunuşları yutmasın diye kap da gizlenir
func _kaydirmali(p: Control) -> Control:
	var sc := ScrollContainer.new(); sc.set_anchors_preset(Control.PRESET_FULL_RECT)
	sc.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	sc.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	var cc := CenterContainer.new(); cc.size_flags_horizontal = Control.SIZE_EXPAND_FILL; cc.size_flags_vertical = Control.SIZE_EXPAND_FILL
	cc.mouse_filter = Control.MOUSE_FILTER_IGNORE
	cc.add_child(p); sc.add_child(cc)
	sc.visible = p.visible
	p.visibility_changed.connect(func(): sc.visible = p.visible)
	return sc

func _mola_ciz() -> void:
	mola_baslik.text = "MOLA   ·   %s   ·   %s'" % [skor_yazi("-"), M.min_label()]
	for i in mola_dugmeler.size():
		mola_dugmeler[i].text = mola.satir_metni(i, i == mola_satir)

var dil_dugme: Button

# ---------- yerleşim: dik telefon ekranında arayüz büyür, çentik / ana çubuk payı bırakılır ----------
var _tp: Control
var _imza: Control
var _ak: Control
var _yardim_yazi: Label
var _yardim_ust_dugme: Button
var dikey := false

func _css() -> Dictionary:
	if _arg.has("css"):   # deneme: --css=430x932x59x34 (genişlik x yükseklik x üst pay x alt pay)
		var a: PackedStringArray = _arg.css.split("x")
		var d := {"w": float(a[0]), "h": float(a[1])}
		for i in range(2, a.size()): d[["t", "b", "l", "r"][i - 2]] = float(a[i])
		return d
	if not OS.has_feature("web"): return {}
	var j = JavaScriptBridge.eval("(function(){var d=document.getElementById('__gv');if(!d){d=document.createElement('div');d.id='__gv';d.style.cssText='position:fixed;left:0;top:0;width:0;height:0;visibility:hidden;padding:env(safe-area-inset-top) env(safe-area-inset-right) env(safe-area-inset-bottom) env(safe-area-inset-left)';document.body.appendChild(d)}var s=getComputedStyle(d);return JSON.stringify({w:innerWidth,h:innerHeight,t:parseFloat(s.paddingTop)||0,b:parseFloat(s.paddingBottom)||0,l:parseFloat(s.paddingLeft)||0,r:parseFloat(s.paddingRight)||0})})()", true)
	var r = JSON.parse_string(j) if j is String else null
	return r if r is Dictionary else {}

func _yerlesim() -> void:
	var w := get_tree().root
	var ps := Vector2(w.size)
	if ps.x < 2 or ps.y < 2: return
	var c := _css()
	var cw: float = c.get("w", ps.x)
	var ch: float = c.get("h", ps.y)
	dikey = ch > cw
	# dikeyde mantıksal genişlik ≈ CSS genişliğinin 1,45 katı: 18'lik yazı telefonda ~12 nokta okunur
	var f := 1280.0 / clampf(cw * 1.45, 600.0, 1280.0) if dikey else 720.0 / clampf(ch * 1.6, 600.0, 720.0)
	w.content_scale_factor = f
	var s0 := minf(ps.x / 1280.0, ps.y / 720.0) * f
	var mantik := ps / s0
	var ust: float = float(c.get("t", 0.0)) * mantik.y / ch
	var alt: float = float(c.get("b", 0.0)) * mantik.y / ch
	var sol: float = float(c.get("l", 0.0)) * mantik.x / cw
	var sag: float = float(c.get("r", 0.0)) * mantik.x / cw
	var sag0 := sag
	if dok and dok.klasik and dokunmatik:     # klasik kumandada tabela ve imza iki yandaki panellerin içine kaçmasın
		var pg: float = dok.panel(mantik.x); sol += pg; sag += pg
	if _tp: _tp.position = Vector2(18 + sol, 16 + ust)
	if _imza:
		_imza.visible = not (dok and dok.klasik and dokunmatik)   # klasik kumandada imza sağ panelde zaten yazılı
		_imza.offset_right = -14 - sag; _imza.offset_left = _imza.offset_right - _imza.get_combined_minimum_size().x
		_imza.offset_top = 16 + ust; _imza.offset_bottom = _imza.offset_top + _imza.get_combined_minimum_size().y
	if _ak: _ak.offset_top = 110 + ust; _ak.offset_bottom = 260 + ust
	if _tekrar_kutu: _tekrar_kutu.offset_top = 70 + ust; _tekrar_kutu.offset_bottom = 120 + ust
	if menu: menu.custom_minimum_size.x = minf(800, mantik.x - 24)
	if mola_panel: mola_panel.custom_minimum_size.x = minf(760, mantik.x - 24)
	if afis: afis.custom_minimum_size.x = minf(520, mantik.x - 24)
	if _yardim_yazi:
		# her yönde ekran genişliğine sarılır (uzun satır paneli ekrandan taşırıp düğmeleri dışarı itiyordu)
		_yardim_yazi.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		_yardim_yazi.custom_minimum_size.x = minf(mantik.x - 60 - sol - sag, 1100.0)
	if dok: dok.ust = ust; dok.alt = alt; dok.sag = sag0; dok.queue_redraw()
	if lig_ekran: lig_ekran.dikey = dikey; lig_ekran.ust = ust; if lig_ekran.visible: lig_ekran.yenile()
func _dil_yaz() -> void:
	if dil_dugme: dil_dugme.text = "Dil / Language: " + Dil.ad()

func dil_degistir() -> void:
	Dil.ayarla(not Dil.en)
	_dil_yaz()
	# seçicilerdeki yazılar ve tabela yeniden çevrilsin
	for s in [sec_lig, sec_ev, sec_dep, sec_dz, sec_sure, sec_zor, sec_kam, sec_zih]:
		if s: s.select(s.selected)
	if M: _tabela()

func mola_mi() -> bool: return M != null and not M.demo and menu_acik

func mola_bilgi(t: String) -> void:
	mola_mesaj.text = t
	if vr: vr.mola_bilgi(t)

func yardim_goster(v: bool, metin := "") -> void:
	yardim_acik = v
	yardim_metin = metin if v else ""
	if _yardim_yazi: _yardim_yazi.text = metin if metin != "" else Mola.YARDIM
	if _yardim_ust_dugme: _yardim_ust_dugme.text = "Devam  ›" if metin != "" else "Kapat  ×"
	if v and yardim_panel and yardim_panel.get_parent() and yardim_panel.get_parent().get_parent() is ScrollContainer:
		(yardim_panel.get_parent().get_parent() as ScrollContainer).scroll_vertical = 0
	for b in _yardim_dugmeler: b.visible = metin == ""
	yardim_panel.visible = v and vr == null
	if not v and _rapor_lig:
		# lig ekranından açılan maç raporu kapandı: lig ekranına dön
		_rapor_lig = false; lig_acik = true
		lig_ekran.visible = menu_acik and vr == null; lig_ekran.yenile()
		if vr: vr.lig_acildi(true)
		return
	# Nasıl oynanır açıkken arkadaki menü / mola paneli gizlenir
	var mol: bool = menu_acik and M != null and not M.demo
	menu.visible = menu_acik and not mol and not v
	mola_panel.visible = mol and vr == null and not v

func maci_birak() -> void:
	yardim_goster(false)
	if lig_maci:
		# lig / kupa maçı yarıda bırakıldı: oynanmamış sayılır, lig ekranına dönülür
		lig_maci = false
		_gosterim_kur()
		lig.mesaj = "Maç yarıda kaldı; kupa maçı oynanmadı." if kupa_maci else "Maç yarıda kaldı; hafta oynanmadı."
		kupa_maci = false
		lig_goster(true); return
	var lg: Dictionary = veri.ligler[sec_lig.selected]
	_mac_kur(Taktik.kadro_kur(lg.takimlar[sec_ev.selected], lg.id), Taktik.kadro_kur(lg.takimlar[sec_dep.selected], lg.id), 4, 1, true)
	menu_goster(true)

func _secici(kap: Container, ad: String) -> Secici:
	var v := VBoxContainer.new(); v.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var l := Label.new(); l.text = ad; l.add_theme_font_size_override("font_size", 14); l.add_theme_color_override("font_color", Color("#5b6466"))
	var o := Secici.new()
	v.add_child(l); v.add_child(o); kap.add_child(v)
	return o

func _zih() -> int: return (sec_zih.selected - 1) if sec_zih else 0

func _takimlari_doldur() -> void:
	var L: Array = veri.ligler[sec_lig.selected].takimlar
	for o in [sec_ev, sec_dep]:
		o.clear()
		for t in L: o.add_item("%s   ·   güç %d" % [t.ad, int(t.str)])
	sec_ev.select(0); sec_dep.select(1)

func basla() -> void:
	var L: Array = veri.ligler[sec_lig.selected].takimlar
	var a := sec_ev.selected; var b := sec_dep.selected
	if a == b: b = (b + 1) % L.size()
	menu_goster(false)
	var lig: String = veri.ligler[sec_lig.selected].id
	var dz: String = "" if sec_dz.selected <= 0 else sec_dz.metin()
	var ev := Taktik.kadro_kur(L[a], lig, dz)
	ev["zih"] = _zih()
	var dep := Taktik.kadro_kur(L[b], lig, "")
	_mac_kur(ev, dep, SURELER[sec_sure.selected], sec_zor.selected, false)
	afis_goster(ev.dzAd + "  ·  " + ev.kisa, "rakip " + dep.kisa + " · " + dep.dzAd, 2.4)
	kam_mod = sec_kam.selected
	ses.baslat()

func menu_goster(v: bool) -> void:
	menu_acik = v
	var mol: bool = v and M != null and not M.demo
	if mol or not v: lig_acik = false
	menu.visible = v and not mol and not lig_acik
	lig_ekran.visible = v and lig_acik and vr == null
	mola_panel.visible = mol and vr == null
	if mol: mola_satir = 0; mola.cikan = 0; mola.giren = 0; mola_mesaj.text = "Oklar: satır ve değer  ·  Enter: seç  ·  M / Esc: maça dön"
	yardim_goster(false)

# takım → tribün tarafı / tabela sırası: lig maçında kullanıcı deplasmandaysa ev sahibi T[1]
func _y(t: int) -> int: return 1 - t if (M != null and M.kul_dep) else t

# tabela her zaman ev sahibi önce ("EV 1-0 DEP"), sıra ile kullanıcının T[0] olmasından bağımsız
func skor_yazi(ara := " - ") -> String:
	var a: Dictionary = M.T[_y(0)]; var b: Dictionary = M.T[_y(1)]
	return "%s %d%s%d %s" % [a.t.kisa, a.score, ara, b.score, b.t.kisa]

func _tabela() -> void:
	var a: Dictionary = M.T[_y(0)]; var b: Dictionary = M.T[_y(1)]
	tabela.text = "%s  %d - %d  %s" % [a.t.kisa, a.score, b.score, b.t.kisa]
	stad.skor(skor_yazi("-"))

func afis_gorunur() -> bool: return afis.visible

func afis_goster(ust: String, alt, sure: float) -> void:
	if _arg.has("temiz"): return     # mağaza görüntüsü: afiş yok
	afis_ust.text = ust; afis_alt.text = str(alt) if alt != null else ""
	afis_alt.visible = afis_alt.text != ""
	afis.visible = true; _afis_t = sure

static func _kutu(c: Color, r: int) -> StyleBoxFlat:
	var s := StyleBoxFlat.new(); s.bg_color = c
	s.set_corner_radius_all(r); s.set_content_margin_all(12)
	return s

const TOP_SHADER := """
shader_type spatial;
varying vec3 n;
void vertex(){ n = normalize(VERTEX); }
void fragment(){
	// klasik top: 12 siyah beşgen (ikosahedron köşeleri)
	float t = 1.618034;
	vec3 v[12] = vec3[](vec3(-1,t,0),vec3(1,t,0),vec3(-1,-t,0),vec3(1,-t,0),vec3(0,-1,t),vec3(0,1,t),vec3(0,-1,-t),vec3(0,1,-t),vec3(t,0,-1),vec3(t,0,1),vec3(-t,0,-1),vec3(-t,0,1));
	float m = 0.0;
	for (int i = 0; i < 12; i++) m = max(m, dot(n, normalize(v[i])));
	vec3 c = m > 0.93 ? vec3(0.02) : vec3(0.9);
	if (m > 0.915 && m < 0.93) c = vec3(0.5);
	ALBEDO = c; ROUGHNESS = 0.45;
}
"""

# ---------- lig modu ----------
var duzen_ekran: DuzenEkran
func duzen_ac() -> void:
	menu.visible = false
	duzen_ekran.ac()

func lig_goster(v: bool) -> void:
	if v and not lig.var_mi(): lig.kur_lig = sec_lig.selected; lig.kur_takim = sec_ev.selected
	if v: lig.diz = "" if sec_dz.selected <= 0 else sec_dz.metin()
	if v: lig_ekran.satir = 0; lig_ekran.yenile()
	else: lig.mesaj = ""
	lig_acik = v
	menu_goster(true)
	if vr: vr.lig_acildi(v)

func lig_kay(i: int, yon: int) -> void:
	lig.kay(i, yon); lig_ekran.yenile()

func lig_bas(i: int) -> void:
	var r := lig.bas(i)
	if r == "mac": lig_mac_basla()
	elif r == "menu": lig_goster(false)
	elif r == "rapor": rapor_goster()
	elif r == "kupa_mac": kupa_mac_basla()
	else:
		lig_ekran.satir = mini(lig_ekran.satir, lig.satirlar().size() - 1)
		lig_ekran.yenile()

func lig_mac_basla() -> void:
	var mc := lig.sonraki_mac()
	if mc.is_empty(): return
	var lg := lig.lig_veri()
	var biz := lig.biz()
	var rk: int = int(mc[1]) if int(mc[0]) == biz else int(mc[0])
	var dz: String = "" if sec_dz.selected <= 0 else sec_dz.metin()
	# maç motorunda kullanıcı her zaman T[0]; sonuç Lig'de doğru ev/deplasman tarafına yazılır
	var ev := Taktik.kadro_kur(lg.takimlar[biz], lg.id, dz)
	ev["zih"] = _zih()
	var dep := Taktik.kadro_kur(lg.takimlar[rk], lg.id, "")
	lig_acik = false; lig_maci = true; _lig_bitis = 0.0
	menu_goster(false)
	_mac_kur(ev, dep, SURELER[sec_sure.selected], sec_zor.selected, false, int(mc[0]) != biz)
	afis_goster("HAFTA %d  ·  %s" % [int(lig.d.hafta) + 1, "İÇ SAHA" if int(mc[0]) == biz else "DEPLASMAN"], (ev.kisa + " - " + dep.kisa) if int(mc[0]) == biz else (dep.kisa + " - " + ev.kisa), 2.4)
	kam_mod = sec_kam.selected
	ses.baslat()

# kupa maçı: kullanıcı her zaman T[0] (tarafsız saha)
func kupa_mac_basla() -> void:
	var m = lig.kupa_benim_mac()
	if m == null: return
	var ben: Array = lig.kupa.ben; var rk: Array = m.b if Lig._ayni(m.a, ben) else m.a
	var dz: String = "" if sec_dz.selected <= 0 else sec_dz.metin()
	var ev := Taktik.kadro_kur(lig.kupa_takim(ben), str(ben[0]), dz)
	ev["zih"] = _zih()
	var dep := Taktik.kadro_kur(lig.kupa_takim(rk), str(rk[0]), "")
	lig_acik = false; lig_maci = true; kupa_maci = true; _lig_bitis = 0.0
	menu_goster(false)
	_mac_kur(ev, dep, SURELER[sec_sure.selected], sec_zor.selected, false, false)
	afis_goster(lig.kupa_tanim(lig.kupa.id).ad + "  ·  " + lig.kupa_tur_adi(int(lig.kupa.tur)), ev.kisa + " - " + dep.kisa, 2.4)
	kam_mod = sec_kam.selected
	ses.baslat()

# ---------- puan ver · arkadaşına öner · bize yaz (bütün oyunlarda standart) ----------
func kabuk() -> bool:
	return OS.has_feature("web") and str(JavaScriptBridge.eval("new URLSearchParams(location.search).get('kabuk') || ''", true)) == "1"

const PAY_METIN := "Kaptan Mecit: üç boyutlu stadyumda futbol. Dört kıtada 28 lig, kupalar, lig modu. Bir maç yapalım mı?"
func puan_ver() -> void:
	if OS.has_feature("web"): JavaScriptBridge.eval("try{var R=window.Capacitor&&Capacitor.Plugins&&Capacitor.Plugins.InAppReview;if(R&&R.requestReview)R.requestReview()}catch(e){}")

func paylas() -> void:
	var metin := Dil.cevir(PAY_METIN)
	if OS.has_feature("web"):
		JavaScriptBridge.eval("""(function(t){var ios=window.Capacitor&&Capacitor.getPlatform&&Capacitor.getPlatform()==='ios';
			var u=ios?'https://apps.apple.com/search?term=Kaptan%20Mecit':(window.Capacitor&&Capacitor.getPlatform&&Capacitor.getPlatform()==='android'?'https://play.google.com/store/apps/details?id=com.anduv.kaptanmecit':'https://emreanduv.github.io/kaptan-mecit-3/');
			var P=window.Capacitor&&Capacitor.Plugins&&Capacitor.Plugins.Share;
			var kopya=function(){try{navigator.clipboard.writeText(t+' '+u)}catch(e){}};
			try{if(P&&P.share){P.share({title:'Kaptan Mecit',text:t,url:u}).catch(kopya);return}if(navigator.share){navigator.share({title:'Kaptan Mecit',text:t,url:u}).catch(kopya);return}}catch(e){}
			kopya()})(""" + JSON.stringify(metin) + ")")
		afis_goster("Arkadaşına öner", "Paylaşım açıldı ya da bağlantı kopyalandı", 3.0)
	else:
		DisplayServer.clipboard_set(metin + " https://emreanduv.github.io/kaptan-mecit-3/")
		afis_goster("Arkadaşına öner", "Bağlantı panoya kopyalandı", 3.0)

func bize_yaz() -> void:
	var surum: String = str(load("res://vr/vr.gd").SURUM)
	var url: String = "mailto:emreanduvart@gmail.com?subject=" + ("Kaptan Mecit 3 – Görüş ve öneri (" + surum + ", " + OS.get_name() + ")").uri_encode() + "&body=" + ("Merhaba, oyunla ilgili görüşüm:\n\n\n— " + OS.get_name() + (" · lig: " + lig.lig_veri().ad if lig.var_mi() else "")).uri_encode()
	if OS.has_feature("web"): JavaScriptBridge.eval("location.href=" + JSON.stringify(url))
	else: OS.shell_open(url)

func _hizli_bitir() -> void:
	_lig_bitis = 0.0
	var e: int = 1 if M.kul_dep else 0
	var skor: String = M.T[e].t.kisa + " " + str(M.T[e].score) + " - " + str(M.T[1 - e].score) + " " + M.T[1 - e].t.kisa
	son_rapor = M.rapor_metni(e); lig.son_rapor = ""
	maci_birak()
	if vr: vr.mola_bilgi("MAÇ SONU  ·  " + skor)
	afis_goster("MAÇ SONU", skor, 5.0)
	rapor_goster()

# maç raporu: Nasıl oynanır panelinde (ekran) / menü panelinde (VR); lig ekranından açılırsa kapanınca oraya dönülür
func rapor_goster() -> void:
	if son_rapor == "": return
	if lig_acik:
		_rapor_lig = true; lig_acik = false; lig_ekran.visible = false
		if vr: vr.lig_acildi(false)
	menu.visible = false
	yardim_goster(true, son_rapor)

func _lig_bitir() -> void:
	if not lig_maci: return
	lig_maci = false
	if kupa_maci:
		kupa_maci = false
		son_rapor = M.rapor_metni(0); lig.son_rapor = son_rapor
		lig.mesaj = lig.kupa_sonuc(M.T[0].score, M.T[1].score)
		if lig.kupa_kazandi(): lig.mesaj = "ŞAMPİYONSUN!  " + lig.kupa_tanim(lig.kupa.id).ad
		_gosterim_kur()
		lig_goster(true)
		rapor_goster()
		return
	son_rapor = M.rapor_metni(1 if M.kul_dep else 0); lig.son_rapor = son_rapor
	lig.kullanici_sonuc(M.T[0].score, M.T[1].score, M.events)
	_gosterim_kur()
	lig_goster(true)
	rapor_goster()

func _gosterim_kur() -> void:
	var lg: Dictionary = lig.lig_veri() if lig.var_mi() else veri.ligler[sec_lig.selected]
	var L: Array = lg.takimlar
	var a := randi() % L.size(); var b := (a + 1 + randi() % (L.size() - 1)) % L.size()
	_mac_kur(Taktik.kadro_kur(L[a], lg.id), Taktik.kadro_kur(L[b], lg.id), 4, 1, true)
