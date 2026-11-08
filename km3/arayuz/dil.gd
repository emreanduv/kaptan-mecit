# Kaptan Mecit 3 — dil (Türkçe / English).
# Oyun Türkçe yazılır; İngilizce seçilince Godot'nun çeviri sistemine bir "ifade çevirisi" takılır:
# ekrandaki her yazı (Label, Button, Label3D, RichTextLabel) gösterilmeden önce aşağıdaki sözlükle ifade ifade çevrilir.
# Böylece "MOLA · İSK 0-2 İSL · 55'" gibi birleşik yazılar da çevrilir; kulüp ve oyuncu adları olduğu gibi kalır.
extends Translation
class_name Dil

const AYAR := "user://km3-ayar.cfg"
static var en := false
static var _ornek: Dil = null

# uzun ifadeler önce denenir (sıralama kurulumda yapılır)
const SOZLUK := {
	"Maç sırası ligin bu sezonki gerçek fikstürüdür.": "Matches follow this season's real league fixture list.",
	"Kulübüne listeden dokun ya da ‹ › ile seç": "Tap your club in the list or use ‹ ›",
	"Lazerle göster, tetikle seç  ·  çubukla da gezinebilirsin  ·  A: MAÇA BAŞLA": "Point with the laser, pull the trigger to select  ·  the stick works too  ·  A: KICK OFF",
	"TEKRAR": "REPLAY", "Geçmek için dokun": "Tap to skip",
	# ana menü, seçiciler
	"Bir Mr. Anduv! yapımıdır.": "Made by Mr. Anduv!",
	"sürüm": "version",
	"Senin takımın": "Your team", "Rakip": "Opponent", "Diziliş (Otomatik: asistan kadroya en uygununu seçer)": "Formation (Auto: the assistant picks the best one for your squad)",
	"Diziliş": "Formation", "Süre": "Length", "Zorluk": "Difficulty", "Kamera": "Camera", "Koltuk": "Seat", "Otomatik": "Auto",
	"Kolay": "Easy", "Orta": "Medium", "Zor": "Hard",
	"Yayın": "Broadcast", "Tele": "Tele", "Dinamik": "Dynamic", "Saha kenarı": "Touchline", "Yakın": "Close", "Maket": "Tabletop", "Stadyum": "Stand",
	"Maça başla": "Kick off", "MAÇA BAŞLA": "KICK OFF", "LİG MODU": "LEAGUE MODE", "Nasıl oynanır": "How to play", "NASIL OYNANIR": "HOW TO PLAY",
	"Dil / Language": "Language / Dil", "Türkçe": "Türkçe",
	"güç": "strength", "Güç": "Str",
	"Anadolu Ligi": "Anatolian League", "Ada Ligi": "Island League", "İber Ligi": "Iberian League", "Çizme Ligi": "Boot League", "Ren Ligi": "Rhine League", "Galya Ligi": "Gallic League",
	"Türkiye": "Türkiye", "İngiltere": "England", "İspanya": "Spain", "İtalya": "Italy", "Almanya": "Germany", "Fransa": "France",
	"Pampa Ligi": "Pampas League", "Alp Ligi": "Alpine League", "Güney Haç Ligi": "Southern Cross League", "Brabant Ligi": "Brabant League", "Amazon Ligi": "Amazon League", "Yangtze Ligi": "Yangtze League",
	"And Ligi": "Andes League", "Sahra Ligi": "Sahara League", "Nil Ligi": "Nile League", "Olimpos Ligi": "Olympus League", "Fuji Ligi": "Fuji League", "Han Ligi": "Han League", "Atlas Ligi": "Atlas League",
	"Aztek Ligi": "Aztec League", "Lale Ligi": "Tulip League", "Lusitanya Ligi": "Lusitania League", "İnci Ligi": "Pearl League", "Necd Ligi": "Najd League", "Kaledonya Ligi": "Caledonia League",
	"Kartaca Ligi": "Carthage League", "Yeni Dünya Ligi": "New World League", "Kap Ligi": "Cape League",
	"Arjantin": "Argentina", "Avusturya": "Austria", "Avustralya": "Australia", "Belçika": "Belgium", "Brezilya": "Brazil", "Çin": "China", "Kolombiya": "Colombia", "Cezayir": "Algeria", "Mısır": "Egypt",
	"Yunanistan": "Greece", "Japonya": "Japan", "Güney Kore": "South Korea", "Fas": "Morocco", "Meksika": "Mexico", "Hollanda": "Netherlands", "Portekiz": "Portugal", "Katar": "Qatar", "Suudi Arabistan": "Saudi Arabia",
	"Kariyeri": "Career", "kiralık": "loan", "A milli": "Caps", "Takım konuşması": "Team talk", "maç önü": "pre-match", "devre arası": "half-time", "şimdi değil (maç başında ve devre arasında)": "not now (at kick-off and half-time)", "Sakin olun, oyununuzu oynayın": "Stay calm, play your game", "Size güveniyorum": "I believe in you", "Hırslı olun, her topa basın": "Be fierce, press every ball", "Aynen devam": "Keep it up", "Daha fazlasını istiyorum": "I want more", "Hayal kırıklığına uğradım": "I am disappointed", "Oyuncular konuşmayı çok iyi karşıladı": "The players responded well to the talk", "Konuşma ters tepti, oyuncular gergin": "The talk backfired, the players are tense", "Konuşma pek etki etmedi": "The talk had little effect",
	"MAÇ RAPORU": "MATCH REPORT", "Maç raporu": "Match report", "MAÇIN YILDIZI": "PLAYER OF THE MATCH", "GOLLER": "GOALS", "Gol yok.": "No goals.", "asist": "assist", "KARTLAR": "CARDS", "KIRMIZI": "RED", "SARI": "YELLOW", "İSTATİSTİK": "STATS", "NOTLAR": "RATINGS", "Topla oynama %": "Possession %", "İsabetli şut": "Shots on target", "Pas isabeti %": "Pass accuracy %", "Korner": "Corners", "Faul": "Fouls", "Kurtarış": "Saves", "Şut": "Shots",
	"İskoçya": "Scotland", "Tunus": "Tunisia", "ABD": "USA", "Güney Afrika": "South Africa",
	"WASD / oklar: koş · X: pas / oyuncu seç · Z / boşluk: şut · kay · C: kamera · M: menü   ·   Kol: sol çubuk koş · A pas · B şut · Y kamera":
		"WASD / arrows: run · X: pass / switch player · Z / space: shoot · slide · C: camera · M: menu   ·   Pad: left stick run · A pass · B shoot · Y camera",
	"Menü: lazerle seç, tetikle bas · A: maça başla   ·   Maçta: sol çubuk koş (baktığın yöne) · Sağ tetik / A: pas · B / sağ kavrama: şut · kay · Sağ çubuk sola/sağa ya da sol X: koltuk · Sol menü / Y: menü":
		"Menu: point and pull the trigger · A: kick off   ·   In a match: left stick runs (where you look) · Right trigger / A: pass · B / right grip: shoot · slide · Right stick left/right or left X: seat · Left menu / Y: menu",
	"Çubuk yukarı/aşağı: satır  ·  sola/sağa: değiştir  ·  A ya da tetik: MAÇA BAŞLA": "Stick up/down: row  ·  left/right: change  ·  A or trigger: KICK OFF",
	"Çubuk yukarı/aşağı: satır  ·  sola/sağa: değiştir  ·  A ya da tetik: seç  ·  menü: maça dön": "Stick up/down: row  ·  left/right: change  ·  A or trigger: select  ·  menu: back to the match",
	"Çubuk yukarı/aşağı: satır  ·  sola/sağa: değiştir  ·  A ya da tetik: seç  ·  B: ana menü": "Stick up/down: row  ·  left/right: change  ·  A or trigger: select  ·  B: main menu",
	"Oklar: satır ve değer  ·  Enter: seç  ·  M / Esc: maça dön": "Arrows: row and value  ·  Enter: select  ·  M / Esc: back to the match",
	"Oklar: satır ve değer  ·  Enter: seç  ·  Esc: ana menü": "Arrows: row and value  ·  Enter: select  ·  Esc: main menu",
	"A / tetik ya da B: kapat   ·   sol X: Verilerimi sil": "A / trigger or B: close   ·   left X: Delete my data",
	# maç olayları
	"BAŞLAMA VURUŞU": "KICK-OFF", "DEVRE ARASI": "HALF-TIME", "2. YARI": "2ND HALF", "KALELER DEĞİŞTİ": "ENDS SWAPPED", "MAÇ SONU": "FULL TIME",
	"UZATMA +": "ADDED TIME +", "DK": "MIN", "GOOOL!": "GOAL!", "Kendi kalesine": "Own goal", "TAÇ": "THROW-IN", "KORNER": "CORNER", "AUT": "GOAL KICK",
	"AVANTAJ": "ADVANTAGE", "FAUL": "FOUL", "serbest vuruş": "free kick", "PENALTI KARARI İNCELENİYOR…": "CHECKING PENALTY DECISION…",
	"TEMAS YETERSİZ · PENALTI İPTAL": "NOT ENOUGH CONTACT · NO PENALTY", "PENALTI KARARI GEÇERLİ": "PENALTY STANDS", "PENALTI": "PENALTY",
	"topun başında": "steps up", "SARI KART": "YELLOW CARD", "KIRMIZI KART": "RED CARD", "İKİNCİ SARI · KIRMIZI": "SECOND YELLOW · RED",
	"10 KİŞİ": "10 MEN", "NET GOL FIRSATI": "DENYING A CLEAR CHANCE", "SERT MÜDAHALE": "SERIOUS FOUL PLAY", "OFSAYT ÇİZGİSİ ÇEKİLİYOR…": "DRAWING THE OFFSIDE LINE…",
	"ATAĞIN BAŞLANGICI İZLENİYOR…": "REVIEWING THE START OF THE ATTACK…", "GOL GEÇERLİ": "GOAL STANDS", "GOL İPTAL": "GOAL DISALLOWED", "ATAKTA FAUL": "FOUL IN THE BUILD-UP",
	"OFSAYT": "OFFSIDE", "DEĞİŞİKLİK": "SUBSTITUTION", "SAKATLIK": "INJURY", "SKOR İÇİN HÜCUM": "CHASING THE GAME", "SKORU KORUMAK": "PROTECTING THE LEAD",
	"YORGUNLUK %": "FATIGUE %", "TEKNİK DİREKTÖR": "MANAGER", "KAMERA": "CAMERA", "KOLTUK": "SEAT",
	# rehber ipuçları
	"KOŞ": "RUN", "Sol çubuk: baktığın yöne koş": "Left stick: run where you look", "WASD / oklar ya da sol çubuk: koş": "WASD / arrows or left stick: run",
	"Ekranın soluna parmağını koy ve kaydır: koş": "Put your finger on the left of the screen and slide: run",
	"PAS VE ŞUT": "PASS AND SHOOT", "A ya da tetik: pas  ·  B ya da kavrama: şut": "A or trigger: pass  ·  B or grip: shoot", "X: pas  ·  Z / boşluk: şut": "X: pass  ·  Z / space: shoot",
	"Sağ altta PAS ve ŞUT": "PASS and SHOOT at the bottom right", "TOPU KAP": "WIN THE BALL",
	"Topu kapmak için rakibin üstüne koş, şut tuşu: kayarak müdahale": "Run at the opponent to win the ball; shoot button: slide tackle",
	"Rakibin üstüne koş, Z / boşluk: kayarak müdahale": "Run at the opponent; Z / space: slide tackle", "Rakibin üstüne koş, ŞUT: kayarak müdahale": "Run at the opponent; SHOOT: slide tackle",
	"Sağ çubuk sola/sağa ya da X: başka bir koltuğa geç": "Right stick left/right or X: change seat", "C: kamerayı değiştir": "C: change camera",
	"Kamerayı molada değiştirebilirsin": "You can change the camera in the pause menu",
	"Menü düğmesi: mola, oyuncu değişikliği ve Nasıl oynanır": "Menu button: pause, substitutions and How to play",
	"M / Esc: mola, oyuncu değişikliği ve Nasıl oynanır": "M / Esc: pause, substitutions and How to play",
	"Üstteki II: mola, oyuncu değişikliği ve Nasıl oynanır": "II at the top: pause, substitutions and How to play",
	"PAS": "PASS", "ŞUT": "SHOOT", "BASILI TUT": "HOLD IT",
	"Şut tuşunu ne kadar tutarsan şut o kadar sert  ·  pası basılı tutup bırak: ara pas": "Hold shoot longer for a harder shot  ·  hold and release pass: through ball",
	"Z'yi ne kadar tutarsan şut o kadar sert  ·  X'i basılı tutup bırak: ara pas": "Hold Z longer for a harder shot  ·  hold and release X: through ball",
	"ŞUT'u ne kadar tutarsan şut o kadar sert  ·  PAS'ı basılı tutup bırak: ara pas": "Hold SHOOT longer for a harder shot  ·  hold and release PASS: through ball",
	# mola
	"MOLA": "PAUSE", "DEVAM ET": "RESUME", "Çıkan": "Off", "Giren": "On", "DEĞİŞİKLİĞİ YAP": "MAKE THE SUBSTITUTION", "Asistan değişiklikleri": "Assistant substitutions",
	"MAÇI BIRAK": "QUIT MATCH", "Açık": "On", "Kapalı (sakatlıkta yine girer)": "Off (still steps in for injuries)", "kondisyon": "fitness", "SAKAT": "INJURED",
	"kaleci": "goalkeeper", "defans": "defender", "orta saha": "midfielder", "forvet": "forward", "kulübede kimse kalmadı": "nobody left on the bench",
	"hak kalmadı": "no substitutions left", "şu an yapılamaz": "not possible now", "hak kaldı": "left", "hak": "subs", "ara kaldı": "windows left",
	"oyuna girdi,": "comes on,", "çıktı": "goes off", "Değişiklik şu an yapılamıyor": "Substitution not possible right now",
	"Kapat": "Close", "Rehberi baştan göster": "Show the tips again", "Verilerimi sil": "Delete my data",
	"Emin misin? Silmek için bir kez daha bas": "Are you sure? Press once more to delete", "Cihazdaki verilerin silindi": "Your data on this device was deleted",
	# lig
	"Lig": "League", "LİG": "LEAGUE", "Ligi bırak": "Leave the league", "SEZONA BAŞLA": "START THE SEASON", "MAÇA ÇIK": "PLAY THE MATCH", "Maçı simüle et": "Simulate the match",
	"YENİ SEZON": "NEW SEASON", "Yeni sezon: kulübünü seç": "New season: pick your club", "Yeni sezon": "New season", "Sezon bitti · Şampiyon:": "Season over · Champions:",
	"Sezon bitti": "Season over", "SEZON SONU": "END OF SEASON", "ŞAMPİYON:": "CHAMPIONS:", "PUAN DURUMU": "TABLE", "Haftanın sonuçları": "This week's results",
	"HAFTA": "WEEK", "SONUÇLARI": "RESULTS", "Hafta": "Week", "SONRAKİ MAÇ": "NEXT MATCH", "Geçen hafta:": "Last week:", "son hafta": "last week",
	"KULÜPLER  ·  güç sırasıyla": "CLUBS  ·  by strength", "Takımın": "Your team", "Takım": "Team", "Form": "Form", "İÇ SAHA": "HOME", "İç saha": "Home",
	"DEPLASMAN": "AWAY", "Deplasman": "Away", "rakip": "opponent", "sırada": "place", "sıradasın": "place", "sen": "you are", "sıra": "pos.",
	"bitirdi.": "finished.", "sezonu": "season", ". sezon": ". season",
	"Maç yarıda kaldı; hafta oynanmadı.": "The match was abandoned; the week was not played.",
	"Emin misin? Sezon silinir; bir kez daha bas": "Are you sure? The season will be deleted; press once more",
	"Ligini ve kulübünü seç. Her hafta kendi maçını oynarsın; ligin diğer maçları aynı anda sonuçlanır. Sezon sonunda en çok puanı toplayan şampiyon olur.":
		"Pick your league and club. Every week you play your own match; the league's other matches are decided at the same time. Whoever has the most points at the end of the season is champion.",
	"Ligini ve kulübünü seç. Her hafta kendi maçını oynarsın; diğer maçlar aynı anda sonuçlanır.": "Pick your league and club. Every week you play your own match; the other matches are decided at the same time.",
	"Fikstür": "Fixtures", "FİKSTÜR": "FIXTURES", "Puan durumu": "Table", "1. DEVRE": "FIRST HALF", "2. DEVRE": "SECOND HALF", "SIRADA": "NEXT", "Skor": "Score",
	"Ana menü": "Main menu", "dk": "min", "Oyun seçimi": "Choose game",
	"Gol krallığı": "Top scorers", "GOL KRALLIĞI": "TOP SCORERS", "Gol kralı:": "Top scorer:", "Oyuncu": "Player", "Kulüp": "Club", "Gol": "Goals", "gol": "goals",
	"Henüz gol yok. İlk hafta oynanınca liste dolar.": "No goals yet. The list fills up after the first week.",
}

const YARDIM_EN := """HOW TO PLAY

Your selected player has the yellow ring at his feet. When you don't have the ball,
the pass button switches to the player closest to the ball.

VR (Quest):  left stick run  ·  A / trigger pass  ·  B / grip shoot and slide
tackle  ·  right stick or X: seat  ·  menu button: pause
Touch:  run with your finger on the left of the screen  ·  PASS / SHOOT at the bottom right  ·  II at the top: pause
Keyboard:  WASD / arrows run  ·  X pass  ·  Z / space shoot  ·  C camera  ·  M pause
Gamepad:  left stick run  ·  A pass  ·  B shoot  ·  Y camera  ·  Start pause
Hold shoot longer for a harder shot; hold and release pass for a
through ball (into the space ahead of your team-mate).

Rules:  fouls, advantage, yellow / red cards, penalties, offside and VAR.
At set pieces opponents stay 9.15 m away; free kicks get a wall.
Sliding in from behind or inside the box gets a card.
Players tire: check their fitness at the break and make substitutions
(5 subs, 3 windows outside half-time). Turn the assistant off and the subs are yours.

Your data: the game collects no data about you; the device only keeps
which tips you have seen. To delete it: Delete my data.
Feedback and ideas: emreanduvart@gmail.com"""

static var _sirali: Array = []
static var _onbellek := {}

static func _harf(c: String) -> bool:
	return c != "" and (c.to_lower() != c.to_upper() or c.is_valid_int())

# ifade ifade çeviri; kelime sınırına dikkat eder (kısa kelimeler başka kelimelerin içinde değişmez)
# kulüp adları: renk ve şehir kelimeleri yalnız kulüp adının içinde çevrilir (oyuncu soyadı "Sarı" bozulmasın)
const KULUP_KELIME := {"Şimşekleri": "Lightning", "Yıldızları": "Stars", "Kırmızı": "Red", "Beyaz": "White", "Siyah": "Black", "Mavi": "Blue", "Lacivert": "Navy", "Sarı": "Yellow", "Yeşil": "Green",
	"Turuncu": "Orange", "Mor": "Purple", "Bordo": "Maroon", "Gök": "Sky", "Kara": "Black", "Şerit": "Stripe", "Londra": "London", "Münih": "Munich",
	"Cenova": "Genoa", "Floransa": "Florence", "Venedik": "Venice", "Marsilya": "Marseille", "Barselona": "Barcelona", "Valensiya": "Valencia",
	"Strazburg": "Strasbourg", "Sardinya": "Sardinia", "Monako": "Monaco", "Köln": "Cologne", "Torino": "Turin", "Milano": "Milan", "Roma": "Rome",
	"Napoli": "Naples", "Arıları": "Bees", "Keçileri": "Goats", "Demircileri": "Ironworkers", "Orman": "Forest", "Boğaziçi": "Bosphorus",
	"Haliç": "Golden Horn", "Karadeniz": "Black Sea"}
static var _tum := {}
static func _kulupler() -> void:
	var f := FileAccess.open("res://veri/takimlar.json", FileAccess.READ)
	if f == null: return
	var j = JSON.parse_string(f.get_as_text())
	if not (j is Dictionary): return
	for lg in j.get("ligler", []):
		for t in lg.get("takimlar", []):
			var ad: String = t.get("ad", "")
			var parca := ""; var cikti := ""
			for ch in ad + " ":
				if ch == " " or ch == "-":
					cikti += KULUP_KELIME.get(parca, parca) + (ch if ch == "-" else " "); parca = ""
				else: parca += ch
			cikti = cikti.strip_edges()
			if cikti != ad and not _tum.has(ad): _tum[ad] = cikti

static func cevir(s: String) -> String:
	if not en or s == "": return s
	if _onbellek.has(s): return _onbellek[s]
	if s == Mola.YARDIM: return YARDIM_EN
	if _sirali.is_empty():
		_tum = SOZLUK.duplicate()
		_kulupler()
		_sirali = _tum.keys()
		_sirali.sort_custom(func(a, b): return a.length() > b.length())
	var out := s
	for k: String in _sirali:
		if out.find(k) < 0: continue
		var v: String = _tum[k]
		var i := 0
		while true:
			i = out.find(k, i)
			if i < 0: break
			var once := out.substr(i - 1, 1) if i > 0 else ""
			var sonra := out.substr(i + k.length(), 1)
			# ifadenin kendisi harfle başlıyor/bitiyorsa komşusu harf olmamalı
			var bas_ok := not (_harf(k.substr(0, 1)) and _harf(once))
			var son_ok := not (_harf(k.substr(k.length() - 1, 1)) and _harf(sonra))
			if bas_ok and son_ok:
				out = out.substr(0, i) + v + out.substr(i + k.length())
				i += v.length()
			else:
				i += k.length()
	if _onbellek.size() > 4000: _onbellek.clear()
	_onbellek[s] = out
	return out

func _get_message(src_message: StringName, _context: StringName) -> StringName:
	var s := String(src_message)
	var c := cevir(s)
	return StringName(c) if c != s else StringName("")

static func _ekle() -> void:
	if _ornek == null:
		_ornek = Dil.new(); _ornek.locale = "en"
		TranslationServer.add_translation(_ornek)

static func kur() -> void:
	_ekle()
	var d := ""
	if OS.has_feature("web"):
		var q = JavaScriptBridge.eval("new URLSearchParams(location.search).get('dil') || ''", true)
		if q is String: d = q
	if d == "":
		var c := ConfigFile.new()
		if c.load(AYAR) == OK: d = c.get_value("ayar", "dil", "")
	if d == "": d = "en" if OS.get_locale_language() != "tr" else "tr"
	ayarla(d == "en", false)

static func ayarla(ingilizce: bool, kaydet := true) -> void:
	_ekle()
	en = ingilizce; _onbellek.clear()
	TranslationServer.set_locale("en" if en else "tr")
	if kaydet:
		var c := ConfigFile.new(); c.load(AYAR)
		c.set_value("ayar", "dil", "en" if en else "tr"); c.save(AYAR)

static func ad() -> String: return "English" if en else "Türkçe"
