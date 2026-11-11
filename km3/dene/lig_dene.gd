# Lig modu denemesi: godot --headless --path km3 -s dene/lig_dene.gd
# Sezonu baştan sona oynatır (kullanıcı maçları da hızlı simüle), fikstür dengesini, tabloyu, kaydı ve silmeyi denetler.
extends SceneTree

func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var hata := 0
	for li in veri.ligler.size():
		var L := Lig.new(veri)
		L.sil()
		var t0 := Time.get_ticks_msec()
		L.yeni_sezon(li, 0)
		var kur_ms := Time.get_ticks_msec() - t0
		var n: int = veri.ligler[li].takimlar.size()
		# fikstür: her çift tam iki kez (bir ev, bir deplasman), her takım her hafta tek maç
		var cift := {}; var ev := {}
		for h in L.d.fikstur:
			var bu := {}
			for mc in h:
				for x in [mc[0], mc[1]]:
					if bu.has(x): hata += 1; print("  HATA hafta içinde iki maç: ", x)
					bu[x] = true
				var k := str(mc[0]) + ">" + str(mc[1])
				if cift.has(k): hata += 1
				cift[k] = true
				ev[mc[0]] = ev.get(mc[0], 0) + 1
			if bu.size() != n: hata += 1; print("  HATA eksik takım, hafta")
		if cift.size() != n * (n - 1): hata += 1; print("  HATA çift sayısı ", cift.size())
		# ardışık ev/deplasman serisi en çok kaç?
		var seri := 0
		for x in n:
			var s := 0; var onceki := -1
			for h in L.d.fikstur:
				for mc in h:
					if mc[0] == x or mc[1] == x:
						var e := 1 if mc[0] == x else 0
						s = s + 1 if e == onceki else 1; onceki = e; seri = maxi(seri, s)
		# yönetim beklentisi: hedef geçerli sırada, güven 5–99, beklenen puan 0–3
		var hs0 := L.hedef_sira()
		if hs0 < 1 or hs0 > n or L.hedef_adi() == "" or L.guven() != 60: hata += 1; print("  HATA hedef ", L.d.hedef, " güven ", L.guven())
		var bp := L.beklenen_puan(0, 1, true) + L.beklenen_puan(0, 1, false)
		if bp < 2.0 or bp > 3.0: hata += 1; print("  HATA beklenen puan toplamı ", bp)   # G+B+M=1 → 3G+B + 3M+B ∈ [2,3]
		var oynanan := 0
		while not L.bitti():
			var mc := L.sonraki_mac()
			if oynanan % 2 == 0: L.kullanici_sonuc(randi() % 4, randi() % 3)
			else: L.haftayi_simule()
			oynanan += 1
		# kaydet / yükle aynı tabloyu vermeli
		var L2 := Lig.new(veri)
		var t1 := L.tablo(); var t2 := L2.tablo()
		if JSON.stringify(t1) != JSON.stringify(t2): hata += 1; print("  HATA kayıt farklı")
		var gol := 0; var mac := 0; var bera := 0
		for h in L.d.fikstur:
			for mc in h: gol += int(mc[2]) + int(mc[3]); mac += 1; bera += 1 if int(mc[2]) == int(mc[3]) else 0
		# gol krallığı: dağıtılan gol sayısı = ligde atılan gol; kayıttan aynı liste
		var kt := 0
		for k in L.d.goller: kt += int(L.d.goller[k])
		if kt != gol: hata += 1; print("  HATA gol krallığı toplamı ", kt, " != ", gol)
		if JSON.stringify(L.gol_krallari()) != JSON.stringify(L2.gol_krallari()): hata += 1; print("  HATA gol krallığı kayıt")
		print("   gol kralı: ", L.gol_krali_metni(), " · ilk 3: ", L.gol_krallari(3).map(func(r): return "%s %s %d" % [r[1], r[2], r[4]]))
		# kadro: 11 ilk + yedekler, ligdeki golleriyle; kulübün gol toplamını aşmaz
		var KD := L.kadro_satirlari()
		var ilk := KD.filter(func(x): return x[5]).size()
		var kg := 0
		for x in KD: kg += int(x[4])
		var bizgol := 0
		for k in L.d.goller: if (k as String).begins_with(str(L.biz()) + "|"): bizgol += int(L.d.goller[k])
		if ilk != 11 or KD.size() < 11 or kg > bizgol or L.kadro_ozet() == "": hata += 1; print("  HATA kadro ilk11=", ilk, " n=", KD.size(), " gol ", kg, "/", bizgol)
		for x in KD: if x[3] < 1 or x[3] > 99 or str(x[1]) == "": hata += 1; print("  HATA kadro satırı ", x); break
		if li == 0: print("   kadro: ", L.kadro_ozet(), " · ", KD.slice(0, 3))
		var gv := L.guven()
		if gv < 5 or gv > 99: hata += 1; print("  HATA güven ", gv)
		if L.guven() != Lig.new(veri).guven(): hata += 1; print("  HATA güven kayıt")
		print("   yönetim: güç sırası %d → %s (%d.) · bitirdi %d. · %s · güven %d" % [L._guc_sirasi(), L.hedef_adi(), L.hedef_sira(), L.sira_biz(), Lig.hedef_sonuc(L.sira_biz(), L.hedef_sira()), gv])
		var top: Dictionary = t1[0]; var son: Dictionary = t1[-1]
		print("%s: %d takım, %d hafta, kurulum %d ms, en uzun ev/dep serisi %d, maç başı gol %.2f, beraberlik %%%d · şampiyon %s %dP (%d-%d-%d, %d:%d) · sonuncu %s %dP · güç %s" % [
			veri.ligler[li].ad, n, L.hafta_sayisi(), kur_ms, seri, float(gol) / mac, 100 * bera / mac,
			L.takim(top.i).kisa, top.P, top.G, top.B, top.M, top.A, top.Y, L.takim(son.i).kisa, son.P, str(L.d.guc.slice(0, 4))])
		if li == 0:
			for r in L.tablo_satirlari().slice(0, 4): print("   ", r)
		# tarihçe: biten sezon yazılır, yeni sezona taşınır, kayıttan geri gelir
		var sira := L.sira_biz()
		L.sonraki_sezon()
		for _k in 3: L.haftayi_simule()
		var TS := L.tarih_satirlari()
		if (L.d.tarih as Array).size() != 1 or int(L.d.sezon) != 2 or TS.size() != 2 or int(TS[1][1]) != sira or not TS[0][13]:
			hata += 1; print("  HATA tarihçe ", TS)
		if JSON.stringify(Lig.new(veri).tarih_satirlari()) != JSON.stringify(TS): hata += 1; print("  HATA tarihçe kayıt")
		if TS[1][14] != Lig.hedef_sonuc(sira, int(L.d.tarih[0].hs)) or TS[1][14] == "" or TS[0][14] != L.hedef_adi(): hata += 1; print("  HATA tarihçe yönetim ", TS[1])
		# eski kayıt (hedefsiz) açılınca hedef kurulur
		L.d.erase("hedef"); L.kaydet()
		if Lig.new(veri).hedef_sira() < 1: hata += 1; print("  HATA eski kayıtta hedef yok")
		if li == 0: print("   tarihçe: ", L.tarih_ozet(), " · ", TS)
		L.sil()
		if FileAccess.file_exists(Lig.KAYIT): hata += 1; print("  HATA silinmedi")
	print("LİG DENEMESİ: ", "TAMAM" if hata == 0 else str(hata) + " HATA")
	quit()
