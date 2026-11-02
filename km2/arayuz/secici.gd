# ◀ değer ▶ seçici: açılır liste yerine iki büyük ok düğmesi. VR lazeri, dokunmatik ve fare için güvenilir
# (açılır pencere gerektirmez). OptionButton'ın kullandığımız parçalarını taklit eder.
extends HBoxContainer
class_name Secici

signal item_selected(i: int)

var _ogeler: PackedStringArray = []
var selected := -1
var _etiket: Label

func _init() -> void:
	add_theme_constant_override("separation", 6)
	custom_minimum_size = Vector2(0, 46)
	var sol := _ok("<")
	sol.pressed.connect(func(): _kay(-1))
	add_child(sol)
	var kutu := PanelContainer.new(); kutu.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var s := StyleBoxFlat.new(); s.bg_color = Color("#706b63"); s.set_corner_radius_all(8); s.set_content_margin_all(8)
	kutu.add_theme_stylebox_override("panel", s)
	_etiket = Label.new(); _etiket.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER; _etiket.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_etiket.add_theme_font_size_override("font_size", 18); _etiket.add_theme_color_override("font_color", Color.WHITE)
	_etiket.clip_text = true; _etiket.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	kutu.add_child(_etiket); add_child(kutu)
	var sag := _ok(">")
	sag.pressed.connect(func(): _kay(1))
	add_child(sag)

func _ok(t: String) -> Button:
	var b := Button.new(); b.text = t; b.custom_minimum_size = Vector2(52, 46)
	b.add_theme_font_size_override("font_size", 22)
	for d in ["normal", "hover", "pressed", "focus"]:
		var s := StyleBoxFlat.new(); s.set_corner_radius_all(8)
		s.bg_color = Color("#1f3b3c") if d == "normal" or d == "focus" else (Color("#2c5354") if d == "hover" else Color("#e5722f"))
		b.add_theme_stylebox_override(d, s)
	b.add_theme_color_override("font_color", Color.WHITE)
	return b

func _kay(d: int) -> void:
	if _ogeler.is_empty(): return
	select(posmod(selected + d, _ogeler.size()))
	item_selected.emit(selected)

func add_item(t: String) -> void:
	_ogeler.append(t)
	if selected < 0: select(0)

func clear() -> void:
	_ogeler.clear(); selected = -1; _etiket.text = ""

func select(i: int) -> void:
	if _ogeler.is_empty(): return
	selected = clampi(i, 0, _ogeler.size() - 1)
	_etiket.text = _ogeler[selected]
