extends StaticBody2D
## Lantai logam Akumalaca digambar secara prosedural supaya tajam di semua
## resolusi dan bisa memakai aksen neon yang konsisten.

@export var arena_width := 2600.0
@export var ground_y := 600.0

func _ready() -> void:
	z_index = -20
	collision_layer = 1
	collision_mask = 0
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(arena_width + 400.0, 240.0)
	col.shape = shape
	col.position = Vector2(arena_width * 0.5, ground_y + 120.0)
	add_child(col)
	queue_redraw()

func _draw() -> void:
	var bottom := ground_y + 190.0
	draw_rect(Rect2(0.0, ground_y, arena_width, bottom - ground_y), Color(0.035, 0.042, 0.058))

	# Pelat lantai bergantian warna.
	var x := -40.0
	var index := 0
	while x < arena_width + 40.0:
		var w := 150.0 if index % 3 != 0 else 210.0
		var shade := 0.055 + float(index % 2) * 0.012
		draw_rect(Rect2(x + 5.0, ground_y + 10.0, w - 10.0, 106.0), Color(shade, shade + 0.008, shade + 0.024))
		draw_rect(Rect2(x + 5.0, ground_y + 10.0, w - 10.0, 3.0), Color(0.16, 0.18, 0.23, 0.55))
		draw_line(Vector2(x + 5.0, ground_y + 10.0), Vector2(x + 5.0, ground_y + 116.0), Color(0.01, 0.014, 0.022, 0.9), 3.0)
		# Baut dan goresan.
		draw_circle(Vector2(x + 18.0, ground_y + 24.0), 2.4, Color(0.35, 0.31, 0.26, 0.8))
		draw_circle(Vector2(x + w - 18.0, ground_y + 24.0), 2.4, Color(0.35, 0.31, 0.26, 0.8))
		if index % 4 == 1:
			draw_line(Vector2(x + 34.0, ground_y + 92.0), Vector2(x + w - 30.0, ground_y + 78.0), Color(0.22, 0.12, 0.06, 0.5), 2.0)
		x += w
		index += 1

	# Pita hazard di area awal & akhir.
	for start_x in [-40.0, arena_width - 170.0]:
		var hx: float = start_x
		while hx < start_x + 210.0:
			var pts := PackedVector2Array([
				Vector2(hx, ground_y + 118.0), Vector2(hx + 26.0, ground_y + 118.0),
				Vector2(hx + 46.0, ground_y + 152.0), Vector2(hx + 20.0, ground_y + 152.0),
			])
			draw_colored_polygon(pts, Color(0.75, 0.35, 0.07, 0.35))
			hx += 52.0

	# Garis neon utama + core panas.
	draw_rect(Rect2(0.0, ground_y - 4.0, arena_width, 4.0), Color(0.08, 0.09, 0.12))
	draw_line(Vector2(0.0, ground_y - 6.0), Vector2(arena_width, ground_y - 6.0), Color(1.0, 0.34, 0.06, 0.18), 14.0)
	draw_line(Vector2(0.0, ground_y - 6.0), Vector2(arena_width, ground_y - 6.0), Color(1.0, 0.42, 0.08, 0.85), 3.0)
	draw_line(Vector2(0.0, ground_y - 7.0), Vector2(arena_width, ground_y - 7.0), Color(1.0, 0.82, 0.45, 0.9), 1.0)
