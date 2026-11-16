# Camia denemesi (CBM ile ortak başkan, ülkeye göre derbi, taraftar nabzı, başkanın sözü): godot --headless --path km3 -s dene/camia_dene.gd
extends SceneTree

func _init() -> void:
	var veri: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://veri/takimlar.json"))
	var hata := 0
	for li in veri.ligler.size():
		var lid: String = veri.ligler[li].id
		if not lid in ["tr", "en", "es"]: continue
		var L := Lig.new(veri); L.sil(); L.yeni_sezon(li, 0)
		var derbi := 0; var sozler := {}
		for i in L.takimlar_say() if L.has_method("takimlar_say") else range(veri.ligler[li].takimlar.size()):
			for j in range(i + 1, veri.ligler[li].takimlar.size()):
				if L.derbi_mi(i, j): derbi += 1
		while not L.bitti():
			L.haftayi_simule()
			if L.camia_sozu() != "": sozler[L.camia_sozu()] = 1
		print("%s: başkan %s · derbi çifti %d · taraftar %d · söz %d · manşet %s" % [lid, L.baskan(), derbi, L.taraftar(), sozler.size(), L.manset()])
		for s in sozler.keys().slice(0, 3): print("   ", s)
		if L.baskan()[0] == "": hata += 1
		if lid == "tr" and derbi != 6: hata += 1; print("   HATA: TR'de 6 derbi çifti beklenirdi")
		L.sil()
	print("CAMİA DENEMESİ: ", "TAMAM" if hata == 0 else "HATA %d" % hata)
	quit()
