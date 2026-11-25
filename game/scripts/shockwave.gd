extends Node2D
## Gelombang kejut melingkar untuk serangan stomp / phase transition.

var max_radius := 180.0
var color := Color(1.0, 0.45, 0.1)
var lifetime := 0.55
var elapsed := 0.0
var thickness := 8.0

func setup(radius: float, tint: Color, duration: float = 0.55) -> void:
	max_radius = radius
	color = tint
	lifetime = duration
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	z_index = 25
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= lifetime:
		queue_free()

func _draw() -> void:
	var k := clampf(elapsed / lifetime, 0.0, 1.0)
	var ease_k := 1.0 - pow(1.0 - k, 2.4)
	var radius := max_radius * ease_k
	var fade := pow(1.0 - k, 1.8)
	for i in range(3):
		var r := radius * (1.0 - float(i) * 0.09)
		var c := color
		c.a = fade * (0.22 if i == 0 else (0.85 if i == 1 else 0.7))
		var w := (thickness * 3.0 if i == 0 else (thickness if i == 1 else 2.0)) * (1.0 - k * 0.5)
		draw_arc(Vector2.ZERO, r, 0.0, TAU, 64, c, maxf(1.0, w), true)
	# Debu di dasar lingkar.
	for i in range(10):
		var ang := TAU * float(i) / 10.0 + elapsed * 0.6
		var p := Vector2(cos(ang), sin(ang) * 0.35) * radius
		draw_circle(p, maxf(1.0, 5.0 * (1.0 - k)), Color(color.r, color.g, color.b, fade * 0.5))
