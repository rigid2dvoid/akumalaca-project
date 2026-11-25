extends Node2D
## Busur tebasan yang digambar prosedural, mengikuti arah hadap pemain.

var facing := 1
var color := Color(1.0, 0.55, 0.15)
var heavy := false
var lifetime := 0.2
var elapsed := 0.0

func setup(dir: int, tint: Color, is_heavy: bool) -> void:
	facing = dir
	color = tint
	heavy = is_heavy
	lifetime = 0.36 if is_heavy else 0.24
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = mat
	z_index = 40
	queue_redraw()

func _process(delta: float) -> void:
	elapsed += delta
	queue_redraw()
	if elapsed >= lifetime:
		queue_free()

func _draw() -> void:
	var k := clampf(elapsed / lifetime, 0.0, 1.0)
	var fade := pow(1.0 - k, 1.15)
	var base_radius := (112.0 if heavy else 92.0) * (0.72 + k * 0.55)
	var span := lerpf(1.25, 1.9, k)
	var a0 := -span if facing > 0 else PI - span
	var a1 := span if facing > 0 else PI + span
	var center := Vector2(facing * 10.0, 0.0)

	# Beberapa lapis busur: halo lebar, warna utama, lalu core putih.
	for i in range(3):
		var radius := base_radius * (1.0 - float(i) * 0.11)
		var alpha := fade * (0.28 if i == 0 else (1.0 if i == 1 else 0.95))
		var width := (26.0 if i == 0 else (12.0 if i == 1 else 3.5)) * (1.0 - k * 0.4)
		var c := color
		if i == 2:
			c = Color(1.0, 0.96, 0.86)
		c.a = alpha
		draw_arc(center, radius, a0, a1, 40, c, maxf(1.0, width), true)

	# Percikan kecil di ujung busur.
	var tip := center + Vector2(cos(a1), sin(a1)) * base_radius
	draw_circle(tip, (5.0 if heavy else 3.0) * (1.0 - k), Color(1.0, 0.85, 0.55, fade))
