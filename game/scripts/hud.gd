extends CanvasLayer
## HUD sinematik: health bar animasi, bar boss, combo chain, banner misi,
## overlay pause, dan layar hasil. Semua dibangun runtime tanpa file tema.

const HealthBarScript := preload("res://scripts/health_bar.gd")

var root: Control
var player_panel: Panel
var player_bar
var player_hp_text: Label
var dash_bar
var dash_label: Label
var boss_panel: Panel
var boss_bar
var boss_hp_text: Label
var boss_name: Label
var boss_phase: Label
var objective_label: Label
var banner_root: Control
var banner_main: Label
var banner_sub: Label
var combo_root: Control
var combo_value: Label
var hint_label: Label
var flash_rect: ColorRect
var low_rect: ColorRect
var vignette: ColorRect
var pause_root: Control
var result_root: Control
var result_title: Label
var result_sub: Label
var result_stats: Label
var result_prompt: Label

var _last_player_ratio := 1.0
var _time := 0.0
var _banner_tween: Tween
var _combo_tween: Tween
var _result_visible := false
var _hint_timer := 0.0
var _low_health := false

func _ready() -> void:
	layer = 20
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build()

func _build() -> void:
	# ── Overlay efek layar ──────────────────────────────────────────
	vignette = ColorRect.new()
	vignette.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	vignette.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var vmat := ShaderMaterial.new()
	vmat.shader = load("res://shaders/vignette.gdshader")
	vignette.material = vmat
	add_child(vignette)

	low_rect = ColorRect.new()
	low_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	low_rect.color = Color(0.65, 0.02, 0.02, 0.0)
	low_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(low_rect)

	root = Control.new()
	root.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(root)

	# ── Panel pemain ────────────────────────────────────────────────
	player_panel = _panel(Vector2(20, 16), Vector2(392, 118), Color(1.0, 0.42, 0.1, 0.9))
	root.add_child(player_panel)

	var portrait_frame := Panel.new()
	portrait_frame.position = Vector2(14, 14)
	portrait_frame.size = Vector2(68, 88)
	var pf_st := StyleBoxFlat.new()
	pf_st.bg_color = Color(0.02, 0.04, 0.07, 1.0)
	pf_st.border_color = Color(0.35, 0.28, 0.22)
	pf_st.set_border_width_all(1)
	pf_st.set_corner_radius_all(4)
	portrait_frame.add_theme_stylebox_override("panel", pf_st)
	player_panel.add_child(portrait_frame)

	var portrait := TextureRect.new()
	portrait.texture = load("res://assets/characters/jack_o_way_tpose.png")
	portrait.position = Vector2(3, 3)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	portrait.clip_contents = true
	portrait.modulate = Color(0.9, 0.95, 1.0)
	portrait_frame.add_child(portrait)
	portrait.size = Vector2(62, 82)
	portrait.position = Vector2(3, 3)

	_label(player_panel, "JACK O' WAY", Vector2(96, 8), 19, Color(1.0, 0.55, 0.18), 248, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label(player_panel, "AKUMALACA // SECTOR 09", Vector2(96, 31), 9, Color(0.62, 0.68, 0.8), 248, HORIZONTAL_ALIGNMENT_LEFT)
	_label(player_panel, "VITALITY", Vector2(96, 50), 10, Color(0.75, 0.8, 0.9), 100, HORIZONTAL_ALIGNMENT_LEFT)
	player_hp_text = _label(player_panel, "100 / 100", Vector2(196, 47), 11, Color(0.95, 0.88, 0.75), 148, HORIZONTAL_ALIGNMENT_RIGHT)

	player_bar = HealthBarScript.new()
	player_bar.position = Vector2(96, 65)
	player_bar.size = Vector2(248, 15)
	player_bar.setup(100.0, Color(1.0, 0.38, 0.09), 12)
	player_panel.add_child(player_bar)

	dash_label = _label(player_panel, "DASH  READY", Vector2(96, 87), 9, Color(0.45, 0.9, 1.0), 110, HORIZONTAL_ALIGNMENT_LEFT)
	dash_bar = HealthBarScript.new()
	dash_bar.position = Vector2(196, 89)
	dash_bar.size = Vector2(148, 6)
	dash_bar.setup(100.0, Color(0.25, 0.8, 1.0), 0)
	dash_bar.set_instant_max()
	player_panel.add_child(dash_bar)

	# ── Panel boss ─────────────────────────────────────────────────
	boss_panel = _panel(Vector2(772, 16), Vector2(488, 104), Color(1.0, 0.22, 0.12, 0.9))
	boss_panel.modulate.a = 0.0
	root.add_child(boss_panel)

	boss_name = _label(boss_panel, "MONOSEEDS", Vector2(16, 6), 17, Color(1.0, 0.45, 0.2), 360, HORIZONTAL_ALIGNMENT_LEFT, true)
	_label(boss_panel, "HEAVY ENFORCER // THE GREED MACHINE", Vector2(16, 28), 9, Color(0.7, 0.6, 0.55), 420, HORIZONTAL_ALIGNMENT_LEFT)
	boss_phase = _label(boss_panel, "PHASE 1", Vector2(348, 28), 9, Color(1.0, 0.55, 0.25), 124, HORIZONTAL_ALIGNMENT_RIGHT)

	boss_bar = HealthBarScript.new()
	boss_bar.position = Vector2(16, 49)
	boss_bar.size = Vector2(456, 18)
	boss_bar.setup(380.0, Color(0.58, 0.9, 0.2), 18)
	boss_panel.add_child(boss_bar)

	boss_hp_text = _label(boss_panel, "380 / 380", Vector2(16, 70), 10, Color(0.8, 0.85, 0.9), 456, HORIZONTAL_ALIGNMENT_RIGHT)

	# ── Objective chip ─────────────────────────────────────────────
	var obj_panel := _panel(Vector2(500, 18), Vector2(272, 32), Color(0.3, 0.65, 0.9, 0.7))
	obj_panel.modulate = Color(1, 1, 1, 0.9)
	root.add_child(obj_panel)
	objective_label = _label(obj_panel, "OBJECTIVE // EXPLORE THE SCRAPYARD", Vector2(0, 0), 10, Color(0.72, 0.86, 1.0), 272, HORIZONTAL_ALIGNMENT_CENTER)
	objective_label.size = Vector2(272, 32)
	objective_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# ── Banner misi ────────────────────────────────────────────────
	banner_root = Control.new()
	banner_root.position = Vector2(0, 150)
	banner_root.size = Vector2(1280, 110)
	banner_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	banner_root.modulate.a = 0.0
	root.add_child(banner_root)

	var banner_back := ColorRect.new()
	banner_back.color = Color(0.008, 0.015, 0.03, 0.42)
	banner_back.position = Vector2(230, 4)
	banner_back.size = Vector2(820, 86)
	banner_root.add_child(banner_back)

	var line_l := ColorRect.new()
	line_l.color = Color(1.0, 0.45, 0.12, 0.65)
	line_l.position = Vector2(300, 52)
	line_l.size = Vector2(300, 2)
	banner_root.add_child(line_l)
	var line_r := ColorRect.new()
	line_r.color = Color(1.0, 0.45, 0.12, 0.65)
	line_r.position = Vector2(680, 52)
	line_r.size = Vector2(300, 2)
	banner_root.add_child(line_r)

	banner_main = _label(banner_root, "", Vector2(0, 0), 40, Color(1.0, 0.5, 0.15), 1280, HORIZONTAL_ALIGNMENT_CENTER, true)
	banner_main.size = Vector2(1280, 58)
	banner_main.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	banner_main.add_theme_constant_override("outline_size", 9)
	banner_sub = _label(banner_root, "", Vector2(0, 60), 14, Color(0.9, 0.94, 1.0), 1280, HORIZONTAL_ALIGNMENT_CENTER, true)
	banner_sub.size = Vector2(1280, 32)
	banner_sub.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

	# ── Combo counter ──────────────────────────────────────────────
	combo_root = Control.new()
	combo_root.position = Vector2(1060, 146)
	combo_root.size = Vector2(200, 110)
	combo_root.mouse_filter = Control.MOUSE_FILTER_IGNORE
	combo_root.modulate.a = 0.0
	root.add_child(combo_root)
	combo_value = _label(combo_root, "x2", Vector2(0, 0), 52, Color(1.0, 0.72, 0.2), 200, HORIZONTAL_ALIGNMENT_RIGHT, true)
	combo_value.size = Vector2(200, 62)
	combo_value.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	var combo_caption := _label(combo_root, "HIT CHAIN", Vector2(0, 60), 11, Color(0.85, 0.85, 0.9), 200, HORIZONTAL_ALIGNMENT_RIGHT)
	combo_caption.add_theme_constant_override("outline_size", 4)
	combo_caption.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.8))

	# ── Hint bawah ─────────────────────────────────────────────────
	hint_label = _label(root, "", Vector2(0, 676), 13, Color(0.75, 0.8, 0.9), 1280, HORIZONTAL_ALIGNMENT_CENTER)
	hint_label.add_theme_constant_override("outline_size", 4)
	hint_label.add_theme_color_override("font_outline_color", Color(0, 0, 0, 0.9))
	set_hint("A / D  ·  SPACE  lompat  ·  J / K  serang  ·  SHIFT  dash  ·  ESC  pause")

	# ── Flash & pause & result ─────────────────────────────────────
	flash_rect = ColorRect.new()
	flash_rect.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	flash_rect.color = Color(1, 0.2, 0.1, 0.0)
	flash_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root.add_child(flash_rect)

	pause_root = _overlay_root()
	pause_root.visible = false
	var pause_card := _panel(Vector2(440, 250), Vector2(400, 220), Color(0.35, 0.6, 1.0, 0.6))
	pause_root.add_child(pause_card)
	_label(pause_card, "PAUSED", Vector2(0, 30), 42, Color(0.7, 0.88, 1.0), 400, HORIZONTAL_ALIGNMENT_CENTER, true)
	_label(pause_card, "SISTEM TEMPORER DIBEKUKAN", Vector2(0, 88), 12, Color(0.7, 0.8, 0.95), 400, HORIZONTAL_ALIGNMENT_CENTER)
	_label(pause_card, "ESC / P  untuk lanjut", Vector2(0, 132), 14, Color(0.9, 0.9, 0.95), 400, HORIZONTAL_ALIGNMENT_CENTER)

	result_root = _overlay_root()
	result_root.visible = false
	var result_card := _panel(Vector2(330, 190), Vector2(620, 360), Color(1.0, 0.42, 0.1, 0.55))
	result_root.add_child(result_card)
	result_title = _label(result_card, "", Vector2(0, 34), 46, Color(1.0, 0.55, 0.18), 620, HORIZONTAL_ALIGNMENT_CENTER, true)
	result_title.size = Vector2(620, 64)
	result_title.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	result_sub = _label(result_card, "", Vector2(0, 108), 13, Color(0.82, 0.88, 0.95), 620, HORIZONTAL_ALIGNMENT_CENTER)
	result_sub.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	result_sub.size = Vector2(560, 40)
	result_sub.position = Vector2(30, 108)
	result_stats = _label(result_card, "", Vector2(30, 168), 14, Color(0.75, 0.82, 0.92), 560, HORIZONTAL_ALIGNMENT_CENTER)
	result_stats.size = Vector2(560, 100)
	result_stats.vertical_alignment = VERTICAL_ALIGNMENT_TOP
	result_prompt = _label(result_card, "R  //  RESTART MISI", Vector2(0, 302), 16, Color(1.0, 0.7, 0.3), 620, HORIZONTAL_ALIGNMENT_CENTER, true)
	result_prompt.size = Vector2(620, 36)
	result_prompt.vertical_alignment = VERTICAL_ALIGNMENT_CENTER

func _overlay_root() -> Control:
	var overlay := Control.new()
	overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var dim := ColorRect.new()
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	dim.color = Color(0.005, 0.01, 0.02, 0.78)
	dim.mouse_filter = Control.MOUSE_FILTER_IGNORE
	overlay.add_child(dim)
	root.add_child(overlay)
	return overlay

func _panel(pos: Vector2, panel_size: Vector2, accent: Color) -> Panel:
	var p := Panel.new()
	p.position = pos
	p.size = panel_size
	p.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var st := StyleBoxFlat.new()
	st.bg_color = Color(0.012, 0.022, 0.04, 0.9)
	st.border_color = accent
	st.set_border_width_all(2)
	st.set_corner_radius_all(5)
	st.shadow_color = Color(0, 0, 0, 0.55)
	st.shadow_size = 8
	st.content_margin_left = 0
	p.add_theme_stylebox_override("panel", st)
	return p

func _label(parent: Control, text: String, pos: Vector2, font_size: int, color: Color,
		width: float = 0.0, align: int = HORIZONTAL_ALIGNMENT_LEFT, bold: bool = false) -> Label:
	var l := Label.new()
	l.text = text
	l.position = pos
	l.size = Vector2(width, font_size * 1.65)
	l.horizontal_alignment = align
	l.mouse_filter = Control.MOUSE_FILTER_IGNORE
	l.add_theme_font_size_override("font_size", font_size)
	l.add_theme_color_override("font_color", color)
	l.add_theme_constant_override("outline_size", 3 if bold else 2)
	l.add_theme_color_override("font_outline_color", Color(0.01, 0.015, 0.025, 0.9))
	parent.add_child(l)
	return l

# ── API yang dipanggil Main ─────────────────────────────────────────

func set_player_health(value: int, max_value: int) -> void:
	player_bar.set_value(value)
	player_hp_text.text = "%d / %d" % [value, max_value]
	var ratio := float(value) / float(max_value)
	_last_player_ratio = ratio
	var low := ratio <= 0.3
	if low != _low_health:
		_low_health = low
		if low:
			flash(Color(1.0, 0.05, 0.02), 0.22)

func set_boss_health(value: int, max_value: int) -> void:
	boss_bar.set_value(value)
	boss_hp_text.text = "%d / %d" % [value, max_value]

func show_boss(max_hp: float) -> void:
	boss_bar.setup(max_hp, Color(0.58, 0.9, 0.2), 18)
	boss_hp_text.text = "%d / %d" % [int(max_hp), int(max_hp)]
	boss_phase.text = "PHASE 1"
	boss_phase.add_theme_color_override("font_color", Color(1.0, 0.55, 0.25))
	boss_panel.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(boss_panel, "modulate:a", 1.0, 0.45)

func set_boss_phase(value: int) -> void:
	if value >= 2:
		boss_phase.text = "PHASE 2 // OVERDRIVE"
		boss_phase.add_theme_color_override("font_color", Color(1.0, 0.25, 0.15))
		boss_name.text = "MONOSEEDS // OVERDRIVE"
		boss_bar.fill_color = Color(1.0, 0.22, 0.1)
		boss_bar.fill_top = Color(1.0, 0.55, 0.3)
		boss_bar.queue_redraw()

func set_objective(text: String) -> void:
	objective_label.text = "OBJECTIVE // " + text

func set_hint(text: String) -> void:
	hint_label.text = text
	_hint_timer = 8.0
	hint_label.modulate.a = 1.0

func set_dash_ratio(ratio: float) -> void:
	dash_bar.set_value(ratio * 100.0)
	if ratio >= 0.999:
		dash_label.text = "DASH  READY"
		dash_label.add_theme_color_override("font_color", Color(0.45, 0.95, 1.0))
		dash_bar.fill_color = Color(0.25, 0.85, 1.0)
	else:
		dash_label.text = "DASH  CHARGING"
		dash_label.add_theme_color_override("font_color", Color(0.45, 0.55, 0.65))
		dash_bar.fill_color = Color(0.22, 0.42, 0.58)
	dash_bar.queue_redraw()

func set_combo(count: int) -> void:
	if count < 2:
		var t := create_tween()
		t.tween_property(combo_root, "modulate:a", 0.0, 0.18)
		return
	combo_value.text = "x%d" % count
	combo_root.modulate.a = 1.0
	if _combo_tween:
		_combo_tween.kill()
	_combo_tween = create_tween()
	combo_root.scale = Vector2(1.18, 1.18)
	_combo_tween.tween_property(combo_root, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	var hot := count >= 6
	combo_value.add_theme_color_override("font_color", Color(1.0, 0.35, 0.15) if hot else Color(1.0, 0.72, 0.2))

func banner(title: String, subtitle: String, color: Color, duration: float = 2.6) -> void:
	banner_main.text = title
	banner_sub.text = subtitle
	banner_main.add_theme_color_override("font_color", color)
	banner_root.position.y = 140.0
	banner_root.modulate.a = 0.0
	if _banner_tween:
		_banner_tween.kill()
	_banner_tween = create_tween()
	_banner_tween.set_parallel(true)
	_banner_tween.tween_property(banner_root, "modulate:a", 1.0, 0.22)
	_banner_tween.tween_property(banner_root, "position:y", 158.0, 0.28).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	_banner_tween.chain().tween_interval(duration)
	_banner_tween.chain().tween_property(banner_root, "modulate:a", 0.0, 0.35)

func flash(color: Color = Color(1, 0.1, 0.05), alpha: float = 0.3) -> void:
	flash_rect.color = Color(color.r, color.g, color.b, alpha)
	var tween := create_tween()
	tween.tween_property(flash_rect, "color:a", 0.0, 0.32)

func show_pause(value: bool) -> void:
	pause_root.visible = value
	if value:
		pause_root.modulate.a = 0.0
		var t := create_tween()
		t.tween_property(pause_root, "modulate:a", 1.0, 0.16)

func show_result(victory: bool, stats: Dictionary) -> void:
	_result_visible = true
	result_root.visible = true
	result_root.modulate.a = 0.0
	if victory:
		result_title.text = "TARGET ELIMINATED"
		result_title.add_theme_color_override("font_color", Color(1.0, 0.58, 0.18))
		result_sub.text = "Lengan cybernetic Jack aman. Monoseeds hancur di scrapyard Akumalaca."
		result_prompt.text = "R  //  MAIN LAGI"
	else:
		result_title.text = "JACK DOWN"
		result_title.add_theme_color_override("font_color", Color(1.0, 0.2, 0.12))
		result_sub.text = "Monoseeds menjarah lenganmu. Sektor 09 kembali sunyi."
		result_prompt.text = "R  //  COBA LAGI"
	var minutes := int(stats.get("time", 0.0)) / 60
	var seconds := int(stats.get("time", 0.0)) % 60
	result_stats.text = "WAKTU  %02d:%02d     DAMAGE DIKIRIM  %d     DAMAGE DITERIMA  %d\nHIT CHAIN TERBAIK  x%d     HEALING  %d" % [
		minutes, seconds, int(stats.get("damage_dealt", 0)), int(stats.get("damage_taken", 0)),
		int(stats.get("best_combo", 0)), int(stats.get("healed", 0)),
	]
	var tween := create_tween()
	tween.tween_property(result_root, "modulate:a", 1.0, 0.5)
	result_title.scale = Vector2(1.12, 1.12)
	result_title.pivot_offset = result_title.size * 0.5
	tween.parallel().tween_property(result_title, "scale", Vector2.ONE, 0.55).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

func _process(delta: float) -> void:
	_time += delta
	if _result_visible:
		result_prompt.modulate.a = 0.35 + 0.65 * absf(sin(_time * 3.2))
	if _hint_timer > 0.0:
		_hint_timer -= delta
		if _hint_timer < 1.5:
			hint_label.modulate.a = clampf(_hint_timer / 1.5, 0.0, 1.0)
	if _low_health and not _result_visible:
		var pulse := 0.5 + 0.5 * sin(_time * 5.0)
		low_rect.color = Color(0.6, 0.02, 0.02, 0.06 + pulse * 0.09)
	else:
		low_rect.color.a = 0.0
