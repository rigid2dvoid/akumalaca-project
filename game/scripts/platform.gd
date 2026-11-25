extends StaticBody2D
## Platform satu arah dengan underglow neon.

var platform_size := Vector2(240.0, 22.0)
var accent := Color(1.0, 0.42, 0.1)

func setup(world_position: Vector2, size: Vector2, color: Color = Color(1.0, 0.42, 0.1)) -> void:
	position = world_position
	platform_size = size
	accent = color
	collision_layer = 1
	collision_mask = 0
	z_index = -8

	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = size
	col.shape = shape
	col.one_way_collision = true
	add_child(col)
	queue_redraw()

func _draw() -> void:
	var w := platform_size.x
	var h := platform_size.y
	var rect := Rect2(-w * 0.5, -h * 0.5, w, h)
	draw_rect(rect, Color(0.045, 0.055, 0.075))
	draw_rect(Rect2(rect.position, Vector2(w, 5.0)), Color(0.16, 0.18, 0.23))
	draw_rect(Rect2(rect.position.x + 6.0, rect.position.y + 5.0, w - 12.0, 2.0), Color(0.26, 0.28, 0.34))
	# Rangka bawah.
	draw_line(Vector2(-w * 0.5 + 10.0, h * 0.5), Vector2(w * 0.5 - 10.0, h * 0.5), Color(0.02, 0.025, 0.04), 5.0)
	for i in range(1, 5):
		var tx := -w * 0.5 + w * float(i) / 5.0
		draw_line(Vector2(tx, -h * 0.5 + 4.0), Vector2(tx, h * 0.5), Color(0.09, 0.1, 0.14, 0.7), 1.0)
	# Underglow.
	draw_line(Vector2(-w * 0.5, h * 0.5 + 2.0), Vector2(w * 0.5, h * 0.5 + 2.0), Color(accent.r, accent.g, accent.b, 0.16), 14.0)
	draw_line(Vector2(-w * 0.5, h * 0.5 + 2.0), Vector2(w * 0.5, h * 0.5 + 2.0), Color(accent.r, accent.g, accent.b, 0.9), 2.5)
	draw_line(Vector2(-w * 0.5 + 4.0, h * 0.5 + 3.0), Vector2(w * 0.5 - 4.0, h * 0.5 + 3.0), Color(1.0, 0.95, 0.75, 0.8), 1.0)
