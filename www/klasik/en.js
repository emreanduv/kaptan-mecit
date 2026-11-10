/* Kaptan Mecit Klasik — İngilizce katmanı.
   Oyun Türkçe yazılmıştır; dil İngilizce seçildiyse (adres ?dil=en ya da localStorage km.dil="en") ekrana düşen her
   metin burada çevrilir: DOM metinleri ve öznitelikleri (MutationObserver), tuvale yazılanlar (fillText), paylaşım metni.
   Önce tam eşleşme, sonra en uzun ifadeden başlayarak kelime sınırına dikkat eden ifade değişimi. Kulüp adları
   LEAGUES verisinden renk / şehir kelimeleriyle üretilir; oyuncu soyadları (Sarı, Kara…) bu yüzden bozulmaz. */
(function(){
  'use strict';
  var q=(location.search.match(/[?&]dil=(en|tr)\b/)||[])[1];
  try{if(q)localStorage.setItem('km.dil',q)}catch(e){}
  var dil=q||(function(){try{return localStorage.getItem('km.dil')}catch(e){return null}})()||'tr';
  window.KM_DIL=dil;
  if(dil!=='en')return;
  document.documentElement.lang='en';

  var D=[
  // ana menü ve ekranlar
  ['Tüm kulüp ve oyuncu adları kurmacadır.','All club and player names are fictional.'],['Sürüm','Version'],
  ['HIZLI MAÇ','QUICK MATCH'],['Hızlı Maç','Quick Match'],['İki takım seç, sahaya çık','Pick two teams and kick off'],
  ['LİG KARİYERİ','LEAGUE CAREER'],['Lig kariyeri','League career'],['YENİ KARİYER','NEW CAREER'],['AYARLAR','SETTINGS'],['Ayarlar','Settings'],
  ['NASIL OYNANIR?','HOW TO PLAY?'],['ARKADAŞINA ÖNER','RECOMMEND TO A FRIEND'],['Arkadaşına öner','Recommend to a friend'],
  ['NOSTALJİK FUTBOL','CLASSIC FOOTBALL'],
  // maç raporu ve takım konuşması
  ['KAPAT','CLOSE'],
  // kupalar
  ['KUPALAR','CUPS'],['🏆 Kupalar','🏆 Cups'],['Bir kıta kupası ya da Kıtalar Arası Kupa seç, kulübünle tek maçlık elemelerde finale yürü. Berabere biterse uzatma ve penaltılar var. Maçı oynayabilir ya da simüle edebilirsin.','Pick a continental cup or the Intercontinental Cup and march to the final in single-match knockouts. Extra time and penalties if level. Play the match or simulate it.'],['Kıta kupaları · Kıtalar Arası Kupa','Continental cups · Intercontinental Cup'],['Kupanı ve kulübünü seç','Pick your cup and club'],['KUPA','CUP'],
  ['Şampiyonlar Ligi','League of Champions'],['Kondor Kupası','Condor Cup'],['Kuzey Yıldızı Kupası','North Star Cup'],['İpek Yolu Kupası','Silk Road Cup'],['Savana Kupası','Savanna Cup'],['Kıtalar Arası Kupa','Intercontinental Cup'],
  ['ŞAMPİYONLAR LİGİ','LEAGUE OF CHAMPIONS'],['KONDOR KUPASI','CONDOR CUP'],['KUZEY YILDIZI KUPASI','NORTH STAR CUP'],['İPEK YOLU KUPASI','SILK ROAD CUP'],['SAVANA KUPASI','SAVANNA CUP'],['KITALAR ARASI KUPA','INTERCONTINENTAL CUP'],
  ['Güney Amerika','South America'],['Kuzey Amerika','North America'],['Dünya','World'],
  ['tek maçlık eleme, berabere biterse uzatma ve penaltılar','single-match knockout, extra time and penalties if level'],['kıta kupalarının en güçlü kulüpleri','the strongest clubs of the continental cups'],
  ['KUPAYA BAŞLA','START THE CUP'],['MAÇI SİMÜLE ET','SIMULATE MATCH'],['KUPAYI BIRAK','QUIT THE CUP'],['YENİ KUPA','NEW CUP'],['EMİN MİSİN? KUPA SİLİNİR · BİR DAHA BAS','SURE? THE CUP WILL BE DELETED · TAP AGAIN'],
  ['ŞAMPİYONSUN!','YOU ARE THE CHAMPION!'],['ŞAMPİYONLUĞU PAYLAŞ','SHARE THE TITLE'],['Şampiyon:','Champion:'],['elendi.','is knocked out.'],['elendin','knocked out'],['kupa bitti','cup over'],
  ['Yarı final','Semi-final'],['YARI FİNAL','SEMI-FINAL'],['Çeyrek final','Quarter-final'],['ÇEYREK FİNAL','QUARTER-FINAL'],['FİNAL','FINAL'],['Son 16','Round of 16'],['SON 16','ROUND OF 16'],  ['Yıl','Year'],['A milli','National team'],['kiralık','loan'],['Kariyer bilgisi yok.','No career data.'],['oyuncuya dokun: kariyeri','tap a player: career'],
  ['MAÇ RAPORU','MATCH REPORT'],['MAÇIN YILDIZI','PLAYER OF THE MATCH'],['OYUNCU NOTLARI','PLAYER RATINGS'],['KARTLAR','CARDS'],['Topla oynama','Possession'],['İsabetli şut','Shots on target'],['Pas isabeti','Pass accuracy'],
  ['Kurtarış','Saves'],['Korner','Corners'],['Ofsayt','Offsides'],['Faul','Fouls'],['Kart','Cards'],['Şut','Shots'],['⚽ gol · 👟 asist · ⭐ maçın yıldızı · yanındaki dakika: oyuna giriş','⚽ goal · 👟 assist · ⭐ player of the match · minute: came on'],
  ['MAÇ ÖNÜ KONUŞMASI','PRE-MATCH TEAM TALK'],['DEVRE ARASI KONUŞMASI','HALF-TIME TEAM TALK'],['DEVRE ARASI','HALF-TIME'],['😌 Sakin olun, oyununuzu oynayın','😌 Stay calm, play your game'],['💪 Size güveniyorum','💪 I believe in you'],['🔥 Hırslı olun, her topa basın','🔥 Be fierce, press every ball'],
  ['👏 Aynen devam','👏 Keep it up'],['📣 Daha fazlasını istiyorum','📣 I want more'],['😠 Hayal kırıklığına uğradım','😠 I am disappointed'],
  ['Oyuncular konuşmayı çok iyi karşıladı','The players responded well to the talk'],['Konuşma ters tepti, oyuncular gergin','The talk backfired, the players are tense'],['Konuşma pek etki etmedi','The talk had little effect'],
  ['II: DEĞİŞİKLİK, KONUŞMA','II: SUBS, TEAM TALK'],['II: KONUŞMA','II: TEAM TALK'],['OYUN SEÇİMİ','CHOOSE GAME'],
  ['sezon bitti','season over'],['kulüp','clubs'],['lig','leagues'],['puan','pts'],['hafta','weeks'],
  ['TAKIMINI SEÇ','PICK YOUR TEAM'],['Takımını ve rakibini seç','Pick your team and your opponent'],['Takımım','My team'],['Takımın','Your team'],['Rakip','Opponent'],['RAKİP','OPPONENT'],['RAKİBİ SEÇ','PICK OPPONENT'],
  ['KULÜP SEÇ','PICK A CLUB'],['KULÜP','CLUB'],['Kulüp','Club'],['Ligini ve kulübünü seç','Pick your league and club'],
  ['Ligini ve kulübünü seç. Kariyerin bu cihazda saklanır; istediğin an kaldığın haftadan devam edersin.','Pick your league and club. Your career is saved on this device; continue from the week you left whenever you like.'],['Ligini ve kulübünü seç. Kariyerin bu cihazda saklanır; istediğin an kaldığın haftadan devam edersin. Avrupa\'nın büyük 6 liginde maç sırası ligin bu sezonki gerçek fikstürüdür.','Pick your league and club. Your career is saved on this device; continue from the week you left whenever you like. In Europe\'s big six leagues matches follow this season\'s real fixture list.'],
  ['MAÇA ÇIK','PLAY THE MATCH'],['SİMÜLE ET','SIMULATE'],['KALANINI SİMÜLE ET','SIMULATE THE REST'],['Puan Durumu','Standings'],['Fikstür','Fixtures'],['Gol Krallığı','Top scorers'],
  ['İÇ SAHA','HOME'],['DEPLASMAN','AWAY'],['SEZON BİTTİ','SEASON OVER'],['YENİ SEZON','NEW SEASON'],['Şampiyon','Champion'],['sırada bitirdi. Şampiyon:','place. Champion:'],
  ['🏆 ŞAMPİYONLUĞU PAYLAŞ','🏆 SHARE THE TITLE'],['📣 SEZONU PAYLAŞ','📣 SHARE THE SEASON'],['📣 GALİBİYETİ PAYLAŞ','📣 SHARE THE WIN'],
  ['MAÇ SONU','FULL TIME'],['GALİBİYET','WIN'],['BERABERLİK','DRAW'],['MAĞLUBİYET','DEFEAT'],['Gol yok.','No goals.'],['Henüz gol yok.','No goals yet.'],
  ['DEVAM','CONTINUE'],['RÖVANŞ','REMATCH'],['GERİ','BACK'],['Geri','Back'],['BAŞLA','START'],['SEÇ','SELECT'],['VAZGEÇ','CANCEL'],['EVET, SİL','YES, DELETE'],
  ['MAÇ SÜRESİ','MATCH LENGTH'],['ZORLUK','DIFFICULTY'],['KAMERA','CAMERA'],['SES','SOUND'],['OYUNCU DEĞİŞİKLİĞİ','SUBSTITUTIONS'],['OYUN','GAME'],['VERİLER','DATA'],['GÖRÜŞ VE ÖNERİ','FEEDBACK'],
  ['Kolay','Easy'],['Orta','Medium'],['Zor','Hard'],['dk','min'],['Klasik','Classic'],['Dinamik','Dynamic'],['Stadyum','Stadium'],['Açık','On'],['Kapalı','Off'],['AÇIK','ON'],['KAPALI','OFF'],
  ['🤖 Asistan yapsın','🤖 Assistant does it'],['Ben yaparım','I do it'],
  ['5 değişiklik hakkı, en fazla 3 arada (devre arası sayılmaz). Asistan yorgunluğa, sakatlığa ve skora bakarak değiştirir; maçta II menüsünden sen de değiştirebilirsin.','5 substitutions in at most 3 windows (half time does not count). The assistant decides by fatigue, injuries and the score; you can also substitute from the II menu during a match.'],
  ['★ PUAN VER','★ RATE THE GAME'],['BİZE YAZ','WRITE TO US'],['✉️ BİZE YAZ','✉️ WRITE TO US'],['🗑 VERİLERİMİ SİL','🗑 DELETE MY DATA'],
  ['Bir hata gördün ya da aklına bir fikir geldi mi? Sürüm bilgisiyle hazır bir e-posta açılır.','Found a bug or have an idea? An e-mail opens with the version details filled in.'],
  ['Oyun hiçbir veri toplamaz. Kariyerin, ayarların ve rehber ilerlemen yalnız bu cihazda durur.','The game collects no data. Your career, settings and tips progress stay on this device only.'],
  ['Kariyerin ve ayarların bu cihazdan silinecek. Emin misin?','Your career and settings will be deleted from this device. Are you sure?'],
  ['KAPTAN MECİT HOŞUNA GİTTİ Mİ?','DO YOU LIKE KAPTAN MECIT?'],['Beğendiysen mağazada birkaç yıldızla destek olur musun? Bir önerin varsa onu da dinleriz.','If you enjoy it, would you leave a few stars in the store? If you have a suggestion, we would love to hear it.'],
  ['ÖNERİM VAR','I HAVE A SUGGESTION'],['SONRA','LATER'],['Anladım','Got it'],['Rehberi kapat','Turn tips off'],['REHBER','TIPS'],['↺ REHBERİ BAŞTAN GÖSTER','↺ SHOW TIPS AGAIN'],
  ['Altın çerçeveliler henüz görmediğin ipuçları','Gold-framed ones are tips you have not seen yet'],['KONTROLLER','CONTROLS'],['🎮 Kontroller','🎮 Controls'],
  ['Rehber kapandı. Nasıl Oynanır ekranından yeniden açabilirsin.','Tips are off. You can turn them back on from How to play.'],
  ['Eski kariyer kaydı bu sürümle uyumsuzdu, sıfırlandı.','The old career save did not fit this version and was reset.'],['Bir sorun oldu. Ayarlar sıfırlanıyor…','Something went wrong. Resetting settings…'],
  ['Bağlantı kopyalandı, istediğin yere yapıştır.','Link copied, paste it anywhere.'],
  // rehber ipuçları
  ['🏠 Ana menü','🏠 Main menu'],['⚡ Hızlı Maç','⚡ Quick Match'],['🏆 Lig kariyeri','🏆 League career'],['📋 Kulübün','📋 Your club'],['⚽ İlk maçın','⚽ Your first match'],['⏸︎ Mola menüsü','⏸︎ Pause menu'],['🔁 Oyuncu değişikliği','🔁 Substitutions'],['🏁 Maç sonu','🏁 Full time'],['⚙️ Ayarlar','⚙️ Settings'],
  ["HIZLI MAÇ ile iki takım seçip hemen sahaya çıkarsın. LİG ile bir kulüp seçip bütün sezonu oynarsın. Süre, zorluk, kamera ve ses AYARLAR'da.",'QUICK MATCH: pick two teams and play right away. LEAGUE: pick a club and play the whole season. Length, difficulty, camera and sound are in SETTINGS.'],
  ['Önce Takımım, sonra Rakip sekmesinden kulüp seç. Farklı liglerden takımları da karşılaştırabilirsin. Yıldızlar takımın gücünü gösterir.','Pick a club on My team, then on Opponent. Teams from different leagues can meet too. Stars show a team\'s strength.'],
  ['MAÇA ÇIK ile haftanın maçını oynarsın, SİMÜLE ET ile sonucu hemen alırsın. Puan durumu, fikstür ve gol krallığı alttaki sekmelerde.','PLAY THE MATCH plays this week\'s game, SIMULATE gives you the result at once. Standings, fixtures and top scorers are in the tabs below.'],
  ['Maçtan önce dizilişini seç ya da OTOMATİK bırak: asistan kadrona en uygununu kurar. Kamerayı burada ve maç içinde II menüsünden değiştirebilirsin.','Pick your formation before the match or leave it on AUTO: the assistant sets the best one for your squad. Change the camera here or from the II menu during the match.'],
  ['Buradan oyuncu değiştirir, asistanı açıp kapatır, kamerayı ve sesi değiştirirsin. Lig maçında kalan süreyi simüle edebilirsin.','Here you make substitutions, switch the assistant on or off and change camera and sound. In a league match you can simulate the rest.'],
  ["Önce çıkacak oyuncuya, sonra girecek yedeğe dokun, DEĞİŞTİR'e bas. Renkli çubuk kondisyonu gösterir; kırmızıya düşen oyuncu yavaşlar.",'Tap the player coming off, then the sub going on, and press SUBSTITUTE. The coloured bar shows fitness; a player in the red slows down.'],
  ["Maç raporunda istatistikler, oyuncu notları ve maçın yıldızı var; bir oyuncuya dokunursan kariyerini görürsün. Lig maçında DEVAM ile puan durumuna dönersin. Hızlı Maç'ta RÖVANŞ ile aynı eşleşmeyi yeniden oynarsın.",'The match report has stats, player ratings and the player of the match; tap a player to see his career. In a league match CONTINUE takes you back to the standings. In Quick Match REMATCH replays the same fixture.'],
  ['Görüşünü ve önerini Bize yaz ile ilet. Verilerimi sil kariyerini ve ayarlarını bu cihazdan siler.','Send feedback with Write to us. Delete my data removes your career and settings from this device.'],
  // kontroller ve kurallar
  ['kaleye hücum ediyorsun','goal'],['Sen yukarıdaki','You attack the top'],['Sen aşağıdaki','You attack the bottom'],['Sen sağdaki','You attack the right'],['Sen soldaki','You attack the left'],['Sen karşıdaki','You attack the far'],
  ['; devre arasında kaleler değişir. Başında sarı ok olan oyuncu sensin.','; ends switch at half time. The player with the yellow arrow is you.'],
  ['Koşmak:','Run:'],['telefonda sol tarafa bas ve sürükle · klavyede','on a phone press and drag on the left side · keyboard'],['ya da','or'],
  ['Pas:','Pass:'],['mavi PAS tuşu · klavyede','blue PASS button · keyboard'],['. Gittiğin yöndeki arkadaşına atar. Basılı tutup bırakırsan ','. Passes to the team-mate in the direction you run. Hold and release for a '],['ara pas','through ball'],[': top arkadaşının önündeki boşluğa gider.',': the ball goes into the space ahead of your team-mate.'],
  ['Şut:','Shoot:'],['kırmızı ŞUT tuşu · klavyede','red SHOOT button · keyboard'],['Boşluk','Space'],['. Ceza sahası yakınından vur. Ne kadar uzun basılı tutarsan şut o kadar sert gider; tuşun çevresindeki halka dolar. Fazla güç topu auta yollayabilir.','. Shoot from near the box. The longer you hold, the harder the shot; the ring around the button fills up. Too much power can send it over.'],
  ['Top rakipteyken','When the opponent has the ball'],['tuşların adı değişir:','the buttons change:'],['(X) topa en yakın oyuncunu seçer,','(X) picks your player nearest the ball,'],['(Z) rakibin ayağına kayar.','(Z) slides in on the opponent.'],
  ['Duraklat:','Pause:'],['sağ üstteki II · klavyede','II at the top right · keyboard'],['Duraklat','Pause'],['Tekrarı geç','Skip replay'],
  ['Taç, korner ve aut kendiliğinden kullanılır. Hakem faul çalar, sarı ve kırmızı kart gösterir; ceza sahasındaki faul penaltıdır. Ofsayt ve VAR var. Sol üstteki küçük harita bütün sahayı gösterir.','Throw-ins, corners and goal kicks are taken automatically. The referee calls fouls and shows yellow and red cards; a foul in the box is a penalty. There is offside and VAR. The mini-map at the top left shows the whole pitch.'],
  ['OK TUŞLARI KOŞ · X PAS · Z ŞUT · P DURAKLAT','ARROWS RUN · X PASS · Z SHOOT · P PAUSE'],['KOŞ / YÖN','RUN / AIM'],
  // maç içi
  ['PAS','PASS'],['ŞUT','SHOOT'],['KAY','SLIDE'],['DURAKLATILDI','PAUSED'],['MAÇTAN ÇEKİL (0-3)','FORFEIT (0-3)'],['MAÇTAN ÇIK','LEAVE MATCH'],
  ['🔊 Ses açık','🔊 Sound on'],['🔇 Ses kapalı','🔇 Sound off'],['❓ NASIL OYNANIR?','❓ HOW TO PLAY?'],['🤖 ASİSTAN DEĞİŞİKLİĞİ','🤖 ASSISTANT SUBS'],['🔁 DEĞİŞİKLİK','🔁 SUBSTITUTION'],
  ['DEĞİŞİKLİK','SUBSTITUTION'],['DEĞİŞTİR','SUBSTITUTE'],['HAK','LEFT'],['ARA','WINDOWS'],['SAHADA · ÇIKACAK','ON THE PITCH · OFF'],['YEDEK · GİRECEK','BENCH · ON'],['Yedek kalmadı','No subs left'],
  ['sakatlandı','is injured'],['— değiştirmen iyi olur','— better take them off'],['OTOMATİK','AUTO'],['Otomatik','Auto'],
  ['BAŞLAMA VURUŞU','KICK-OFF'],['GOOOL!','GOAL!'],['GOL','GOAL'],['KAÇTI','MISSED'],['FAUL','FOUL'],['serbest vuruş','free kick'],['PENALTI','PENALTY'],['topun başında','steps up'],['PENALTILAR','PENALTIES'],['SERİ PENALTI ATIŞLARI','PENALTY SHOOT-OUT'],['PEN','PENS'],
  ['SAKATLIK','INJURY'],['🟨 SARI KART','🟨 YELLOW CARD'],['🟥 KIRMIZI KART','🟥 RED CARD'],['🟨🟥 İKİNCİ SARI','🟨🟥 SECOND YELLOW'],['10 KİŞİ','DOWN TO 10'],['SERT MÜDAHALE','RECKLESS TACKLE'],['🚩 OFSAYT','🚩 OFFSIDE'],['OFSAYT','OFFSIDE'],
  ['DEVRE','HALF'],['ARASI','TIME'],['DEVRE ARASI','HALF TIME'],['KALELER DEĞİŞTİ','ENDS SWITCHED'],['1. YARI','1ST HALF'],['2. YARI','2ND HALF'],['UZATMA','EXTRA TIME'],['DAKİKA','MIN'],['2×15 DAKİKA · +1 DEĞİŞİKLİK','2×15 MIN · +1 SUB'],
  ['II: DEĞİŞİKLİK','II: SUBS'],['GOL GEÇERLİ','GOAL STANDS'],['GOL İPTAL','GOAL DISALLOWED'],['ATAKTA FAUL','FOUL IN THE BUILD-UP'],['OFSAYT ÇİZGİSİ ÇEKİLİYOR…','DRAWING THE OFFSIDE LINE…'],['ATAĞIN BAŞLANGICI İZLENİYOR…','CHECKING THE START OF THE ATTACK…'],
  ['PENALTI KARARI GEÇERLİ','PENALTY STANDS'],['PENALTI KARARI İNCELENİYOR…','CHECKING THE PENALTY…'],['TEMAS YETERSİZ · PENALTI İPTAL','NOT ENOUGH CONTACT · NO PENALTY'],
  ['🧠 TAKTİK','🧠 TACTICS'],['🤖 ASİSTAN','🤖 ASSISTANT'],['ORTA SAHA KALABALIKLAŞTI','MIDFIELD PACKED'],['BEŞLİ SAVUNMA','FIVE AT THE BACK'],['STOPERLER ÜÇLENDİ · ÜÇ FORVET','THREE CENTRE-BACKS · THREE STRIKERS'],['ÇİFT FORVET → ÜÇÜNCÜ FORVET','TWO STRIKERS → THIRD STRIKER'],['ÜÇ FORVET','THREE STRIKERS'],
  ['SKOR İÇİN HÜCUM','CHASING THE GAME'],['SKORU KORUMAK','HOLDING THE LEAD'],['YORGUNLUK','FATIGUE'],['KALECİ ATILDI','KEEPER SENT OFF'],['Kendi kalesine','Own goal'],['TEKNİK DİREKTÖR','MANAGER'],
  ['TEKRAR · GEÇ ▶︎','REPLAY · SKIP ▶︎'],['EV','HOME'],['DEP','AWAY'],['SIRA','POS'],['PUAN','PTS'],['FORM','FORM'],['SEN','YOU'],['KORNER','CORNER'],['SOL TARAF:','LEFT SIDE:'],['LİG','LEAGUE'],
  // diziliş
  ['Geniş','Wide'],['Hücum','Attack'],['Savunma','Defensive'],['Dar','Narrow'],['Elmas','Diamond'],['Kanat','Wing-back'],
  // lig ve ülke adları
  ['Anadolu Ligi','Anatolian League'],['Ada Ligi','Island League'],['İber Ligi','Iberian League'],['Çizme Ligi','Boot League'],['Ren Ligi','Rhine League'],['Galya Ligi','Gallic League'],
  ['İngiltere','England'],['İspanya','Spain'],['İtalya','Italy'],['Almanya','Germany'],['Fransa','France'],
  ['Pampa Ligi','Pampas League'],['Alp Ligi','Alpine League'],['Güney Haç Ligi','Southern Cross League'],['Brabant Ligi','Brabant League'],['Amazon Ligi','Amazon League'],['Yangtze Ligi','Yangtze League'],
  ['And Ligi','Andes League'],['Sahra Ligi','Sahara League'],['Nil Ligi','Nile League'],['Olimpos Ligi','Olympus League'],['Fuji Ligi','Fuji League'],['Han Ligi','Han League'],['Atlas Ligi','Atlas League'],
  ['Aztek Ligi','Aztec League'],['Lale Ligi','Tulip League'],['Lusitanya Ligi','Lusitania League'],['İnci Ligi','Pearl League'],['Necd Ligi','Najd League'],['Kaledonya Ligi','Caledonia League'],
  ['Kartaca Ligi','Carthage League'],['Yeni Dünya Ligi','New World League'],['Kap Ligi','Cape League'],
  ['Arjantin','Argentina'],['Avusturya','Austria'],['Avustralya','Australia'],['Belçika','Belgium'],['Brezilya','Brazil'],['Çin','China'],['Kolombiya','Colombia'],['Cezayir','Algeria'],['Mısır','Egypt'],
  ['Yunanistan','Greece'],['Japonya','Japan'],['Güney Kore','South Korea'],['Fas','Morocco'],['Meksika','Mexico'],['Hollanda','Netherlands'],['Portekiz','Portugal'],['Katar','Qatar'],['Suudi Arabistan','Saudi Arabia'],
  ['İskoçya','Scotland'],['Tunus','Tunisia'],['ABD','USA'],['Güney Afrika','South Africa'],
  ['Avrupa','Europe'],['Amerika','Americas'],['Asya','Asia'],['Afrika','Africa'],
  // paylaşım
  ['Kaptan Mecit: üstten görünümlü nostaljik futbol. Dört kıtada 28 lig, 496 kulüp, internetsiz. Bir maç yapalım mı?','Kaptan Mecit: top-down classic football. 28 leagues on four continents, 496 clubs, no internet needed. Fancy a match?'],
  ['Sıra sende, bir maç yapalım mı?','Your turn, fancy a match?'],['Kaptan Mecit\'te','In Kaptan Mecit,'],['şampiyonu oldum!','champion!'],['ile','with'],
  ];
  // kulüp adlarının parçaları (yalnız kulüp adı içinde kullanılır)
  var RENK={'Kırmızı':'Red','Beyaz':'White','Siyah':'Black','Mavi':'Blue','Lacivert':'Navy','Sarı':'Yellow','Yeşil':'Green','Turuncu':'Orange','Mor':'Purple','Bordo':'Maroon','Gök':'Sky','Kara':'Black','Şerit':'Stripe',
    'Londra':'London','Münih':'Munich','Cenova':'Genoa','Floransa':'Florence','Venedik':'Venice','Marsilya':'Marseille','Barselona':'Barcelona','Valensiya':'Valencia','Strazburg':'Strasbourg','Sardinya':'Sardinia','Monako':'Monaco','Köln':'Cologne','Torino':'Turin','Milano':'Milan','Roma':'Rome','Napoli':'Naples',
    'Arıları':'Bees','Şimşekleri':'Lightning','Yıldızları':'Stars','Keçileri':'Goats','Demircileri':'Ironworkers','Orman':'Forest','Boğaziçi':'Bosphorus','Haliç':'Golden Horn','Karadeniz':'Black Sea'};
  var SEHIR=['Londra','Münih','Cenova','Floransa','Venedik','Marsilya','Barselona','Valensiya','Strazburg','Sardinya','Monako','Köln','Torino','Milano','Roma','Napoli'];
  function kulupCevir(ad){return ad.split(/([ -])/).map(function(p){return RENK[p]||p}).join('')}

  var TRUP=function(s){return s.replace(/i/g,'İ').replace(/ı/g,'I').toUpperCase()};
  var esle=null,desen=null,onb=new Map();
  function kur(){
    var m=new Map();
    D.forEach(function(p){m.set(p[0],p[1]);var u=TRUP(p[0]);if(!m.has(u))m.set(u,p[1].toUpperCase())});
    try{for(var k in LEAGUES)LEAGUES[k].t.forEach(function(t){var e=kulupCevir(t[1]);if(e!==t[1]){m.set(t[1],e);var u=TRUP(t[1]);if(!m.has(u))m.set(u,e.toUpperCase())}})}catch(e){}
    SEHIR.forEach(function(s){if(!m.has(s))m.set(s,RENK[s])});
    esle=m;
    var anahtar=Array.from(m.keys()).filter(function(k){return k.length>1}).sort(function(a,b){return b.length-a.length});
    desen=new RegExp('(?<![\\p{L}\\p{N}])('+anahtar.map(function(k){return k.replace(/[.*+?^${}()|[\]\\]/g,'\\$&')}).join('|')+')(?![\\p{L}\\p{N}])','gu');
  }
  function cevir(s){
    if(!s||!/\p{L}/u.test(s))return s;
    if(onb.has(s))return onb.get(s);
    if(!esle)kur();
    var t=s.trim(),r;
    if(esle.has(t))r=s.replace(t,esle.get(t));
    else{
      r=s.replace(/(\d+)\. (hafta|HAFTA)/g,function(x,n,h){return (h==='HAFTA'?'WEEK ':'week ')+n})
         .replace(/(\d+)\. sıra/g,function(x,n){return n+(n%10==1&&n%100!=11?'st':n%10==2&&n%100!=12?'nd':n%10==3&&n%100!=13?'rd':'th')+' place'})
         .replace(/(\d+)\. bitirdim/g,function(x,n){return 'finished '+n+(n%10==1&&n%100!=11?'st':n%10==2&&n%100!=12?'nd':n%10==3&&n%100!=13?'rd':'th')});
      r=r.replace(desen,function(x){return esle.get(x)});
    }
    if(onb.size>5000)onb.clear();
    onb.set(s,r);return r;
  }
  window.kmCevir=cevir;

  var TH={O:'P',G:'W',B:'D',M:'L',AV:'GD',P:'Pts'};
  var OZ=['title','aria-label','placeholder'];
  function dugum(n){
    if(n.nodeType===3){var p=n.parentNode;if(p&&(p.nodeName==='SCRIPT'||p.nodeName==='STYLE'))return;
      if(p&&p.nodeName==='TH'&&TH[n.nodeValue]){n.nodeValue=TH[n.nodeValue];return}
      var c=cevir(n.nodeValue);if(c!==n.nodeValue)n.nodeValue=c;return}
    if(n.nodeType!==1||n.nodeName==='SCRIPT'||n.nodeName==='STYLE')return;
    OZ.forEach(function(a){var v=n.getAttribute(a);if(v){var c=cevir(v);if(c!==v)n.setAttribute(a,c)}});
    if(n.classList&&n.classList.contains('ribbon')&&/NOSTALJ/.test(n.textContent)){n.textContent='CLASSIC FOOTBALL';return}
    for(var k=n.firstChild;k;k=k.nextSibling)dugum(k);
  }
  var gozcu=new MutationObserver(function(ml){
    ml.forEach(function(m){
      if(m.type==='characterData')dugum(m.target);
      else if(m.type==='attributes')dugum(m.target);
      else m.addedNodes.forEach(dugum);
    });
  });
  function basla(){dugum(document.body);gozcu.observe(document.body,{subtree:true,childList:true,characterData:true,attributes:true,attributeFilter:OZ})}
  if(document.body)basla();else document.addEventListener('DOMContentLoaded',basla);

  var ft=CanvasRenderingContext2D.prototype.fillText,st=CanvasRenderingContext2D.prototype.strokeText,mt=CanvasRenderingContext2D.prototype.measureText;
  CanvasRenderingContext2D.prototype.fillText=function(t){arguments[0]=cevir(String(t));return ft.apply(this,arguments)};
  CanvasRenderingContext2D.prototype.strokeText=function(t){arguments[0]=cevir(String(t));return st.apply(this,arguments)};
  CanvasRenderingContext2D.prototype.measureText=function(t){arguments[0]=cevir(String(t));return mt.apply(this,arguments)};
  ['confirm','alert'].forEach(function(f){var o=window[f];if(o)window[f]=function(m){return o.call(window,cevir(String(m)))}});
  function paylas(t){
    var m;
    if(m=t.match(/^Kaptan Mecit'te (.+) ile (.+) şampiyonu oldum! 🏆/))return 'I won the '+cevir(m[2])+' with '+cevir(m[1])+' in Kaptan Mecit! 🏆';
    if(m=t.match(/^Kaptan Mecit'te (.+) ile (.+?)'[a-zıiuü]{1,3} (\d+)\. bitirdim!/)){var n=+m[3];return 'I finished '+n+(n%10==1&&n%100!=11?'st':n%10==2&&n%100!=12?'nd':n%10==3&&n%100!=13?'rd':'th')+' in the '+cevir(m[2])+' with '+cevir(m[1])+' in Kaptan Mecit!'}
    if(m=t.match(/^Kaptan Mecit'te (.+)! Sıra sende, bir maç yapalım mı\?/))return cevir(m[1])+' in Kaptan Mecit! Your turn, fancy a match?';
    return cevir(t);
  }
  if(navigator.share){var sh=navigator.share.bind(navigator);navigator.share=function(o){if(o&&o.text)o.text=paylas(o.text);return sh(o)}}
  if(navigator.clipboard&&navigator.clipboard.writeText){var cw=navigator.clipboard.writeText.bind(navigator.clipboard);navigator.clipboard.writeText=function(t){return cw(paylas(String(t)))}}
})();
