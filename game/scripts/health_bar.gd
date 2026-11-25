extends Control
## Health bar bergaya HUD cyberpunk: segmen, ghost damage, dan pulse saat low HP.
## Dipakai untuk nyawa Jack, boss, serta bar cooldown dash.

var max_value := 100.0
var value := 100.0
var _display := 100.0
var _ghost := 100.0
var _flash := 0.0
var _time := 0.0

var fill_color := Color(0.95, 0.35, 0.09)
var fill_top := Color(1.0, 0.72, 0.3)
var ghost_color := Color(0.9, 0.16, 0.12, 0.75)
var back_color := Color(0.02, 0.035, 0.06, 0.94)
var border_color := Color(0.36, 0.32, 0.28, 0.85)
var low_color := Color(1.0, 0.16, 0.1)
var segments := 12
var show_ghost := true
var pulse_when_low := true
var corner_cut := 5.0

func setup(max_hp: float, bar_color: Color, segment_count: int = 12) -> void:
	max_value = max_hp
	value = max_hp
	_display = max_hp
	_ghost = max_hp
	fill_color = bar_color
	fill_top = bar_color.lightened(0.45)
	segments = segment_count
	queue_redraw()

func set_value(new_value: float, instant: bool = false) -> void:
	var clamped := clampf(new_value, 0.0, max_value)
	if clamped < value:
		_flash = 1.0
	value = clamped
	if instant:
		_display = clamped
		_ghost = clamped
	queue_redraw()

func set_instant_max() -> void:
	_display = max_value
	_ghost = max_value
	queue_redraw()

func _process(delta: float) -> void:
	_time += delta
	_display = lerpf(_display, value, clampf(delta * 16.0, 0.0, 1.0))
	if _ghost > value:
		_ghost = move_toward(_ghost, value, delta * max_value * 0.35)
	else:
		_ghost = lerpf(_ghost, value, clampf(delta * 10.0, 0.0, 1.0))
	_flash = maxf(0.0, _flash - delta * 5.0)
	queue_redraw()

func _pole(rect: Rect2, cut: float) -> PackedVector2Array:
	var x := rect.position.x
	var y := rect.position.y
	var w := rect.size.x
	var h := rect.size.y
	cut = minf(cut, minf(w * 0.3, h * 0.45))
	return PackedVector2Array([
		Vector2(x + cut, y), Vector2(x + w, y), Vector2(x + w, y + h),
		Vector2(x, y + h), Vector2(x, y + cut),
	])

func _draw() -> void:
	var ratio := clampf(_display / max_value, 0.0, 1.0)
	var ghost_ratio := clampf(_ghost / max_value, 0.0, 1.0)
	var rect := Rect2(Vector2.ZERO, size)
	var base_pts := _pole(rect, corner_cut)
	draw_colored_polygon(base_pts, back_color)

	# Ghost damage (jejak merah yang menyusut).
	if show_ghost and ghost_ratio > ratio:
		var ghost_pts := _pole(Rect2(Vector2.ZERO, Vector2(size.x * ghost_ratio, size.y)), corner_cut)
		draw_colored_polygon(ghost_pts, ghost_color)

	var fill_w := size.x * ratio
	if fill_w > 1.0:
		var low := ratio < 0.3 and pulse_when_low
		var pulse := 1.0 + sin(_time * 8.0) * 0.16 if low else 1.0
		var col := fill_color
		if low:
			col = low_color.lerp(fill_color, 0.35 + 0.3 * sin(_time * 8.0))
		col = Color(col.r * pulse, col.g * pulse, col.b * pulse)
		var fill_rect := Rect2(0.0, 0.0, fill_w, size.y)
		var fill_pts := _pole(fill_rect, corner_cut)
		draw_colored_polygon(fill_pts, col)

		# Kilau atas + hot core.
		var top_rect := Rect2(1.0, 1.0, maxf(0.0, fill_w - 2.0), maxf(1.0, size.y * 0.34))
		draw_rect(top_rect, Color(fill_top.r, fill_top.g, fill_top.b, 0.55))
		draw_rect(Rect2(1.0, size.y * 0.5, maxf(0.0, fill_w - 2.0), maxf(1.0, size.y * 0.16)), Color(1.0, 1.0, 1.0, 0.08))

	# Segmen.
	if segments > 0:
		for i in range(1, segments):
			var sx := size.x * float(i) / float(segments)
			draw_line(Vector2(sx, 1.0), Vector2(sx, size.y - 1.0), Color(0.01, 0.015, 0.025, 0.55), 1.5)

	# Border.
	var border_pts := _pole(rect.grow(-0.75), corner_cut)
	border_pts.append(border_pts[0])
	draw_polyline(border_pts, border_color, 1.5, true)

	# Flash putih saat kehilangan HP.
	if _flash > 0.01:
		draw_colored_polygon(base_pts, Color(1.0, 0.95, 0.85, _flash * 0.6))
