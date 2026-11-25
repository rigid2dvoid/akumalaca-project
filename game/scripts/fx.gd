extends Node2D
## Manajer efek visual: partikel, angka damage, tebasan, gelombang kejut,
## dan afterimage dash. Semua dibuat runtime supaya repo tetap ringan.

const SlashScene := preload("res://scripts/slash_effect.gd")
const ShockwaveScene := preload("res://scripts/shockwave.gd")

var spark_tex: Texture2D
var dust_tex: Texture2D
var glow_tex: Texture2D
var shard_tex: Texture2D

func _ready() -> void:
	z_index = 50
	spark_tex = load("res://assets/fx/spark.png")
	dust_tex = load("res://assets/fx/dust.png")
	glow_tex = load("res://assets/fx/glow.png")
	shard_tex = load("res://assets/fx/shard.png")

func _make_material_additive() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat

func _gradient(color: Color) -> Gradient:
	var g := Gradient.new()
	g.set_color(0, color)
	g.set_color(1, Color(color.r, color.g, color.b, 0.0))
	return g

func emit_particles(pos: Vector2, tex: Texture2D, color: Color, amount: int,
		speed_min: float, speed_max: float, gravity: Vector2, lifetime: float,
		size_min: float, size_max: float, spread_deg: float = 180.0,
		direction: Vector2 = Vector2(0, -1), additive: bool = true) -> CPUParticles2D:
	var p := CPUParticles2D.new()
	p.one_shot = true
	p.emitting = false
	p.amount = maxi(1, amount)
	p.lifetime = lifetime
	p.explosiveness = 0.94
	p.randomness = 0.45
	p.local_coords = false
	p.texture = tex
	p.direction = direction.normalized()
	p.spread = spread_deg
	p.gravity = gravity
	p.initial_velocity_min = speed_min
	p.initial_velocity_max = speed_max
	p.angular_velocity_min = -220.0
	p.angular_velocity_max = 220.0
	p.damping_min = 20.0
	p.damping_max = 60.0
	p.scale_amount_min = size_min
	p.scale_amount_max = size_max
	p.color = color
	p.color_ramp = _gradient(color)
	if additive:
		p.material = _make_material_additive()
	p.position = pos
	p.z_index = 45
	add_child(p)
	p.emitting = true
	p.finished.connect(p.queue_free)
	return p

func hit(pos: Vector2, color: Color, direction: int, heavy: bool) -> void:
	emit_particles(pos, spark_tex, color, 20 if heavy else 12, 140.0, 360.0,
		Vector2(0.0, 760.0), 0.5, 0.22, 0.48, 180.0, Vector2(-direction, -0.6))
	# Kilatan singkat di titik kontak.
	var flash := Sprite2D.new()
	flash.texture = glow_tex
	flash.position = pos
	flash.scale = Vector2(0.28, 0.28)
	flash.modulate = Color(color.r, color.g, color.b, 0.85)
	flash.material = _make_material_additive()
	flash.z_index = 46
	add_child(flash)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(1.15, 1.15), 0.16).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.16)
	tween.chain().tween_callback(flash.queue_free)
	if heavy:
		shockwave(pos + Vector2(0, 60), color, 130.0, 0.35)

func dust(pos: Vector2, direction: int, amount: int = 7, color: Color = Color(0.45, 0.5, 0.6, 0.5)) -> void:
	var p := emit_particles(pos, dust_tex, color, amount, 18.0, 75.0,
		Vector2(0.0, -30.0), 0.65, 0.28, 0.72, 70.0, Vector2(-direction, -0.45), false)
	p.z_index = 38

func jump_burst(pos: Vector2) -> void:
	emit_particles(pos, dust_tex, Color(0.55, 0.62, 0.75, 0.55), 12, 30.0, 120.0,
		Vector2(0.0, 60.0), 0.55, 0.35, 0.9, 55.0, Vector2(0, 1), false)

func death_burst(pos: Vector2, color: Color) -> void:
	emit_particles(pos, spark_tex, color, 42, 120.0, 460.0,
		Vector2(0.0, 560.0), 1.2, 0.3, 0.8, 180.0)
	emit_particles(pos, glow_tex, Color(color.r, color.g, color.b, 0.5), 10, 30.0, 160.0,
		Vector2(0.0, 40.0), 1.0, 0.4, 1.1, 180.0)
	var flash := Sprite2D.new()
	flash.texture = glow_tex
	flash.position = pos
	flash.scale = Vector2(0.5, 0.5)
	flash.modulate = Color(color.r, color.g, color.b, 0.9)
	flash.material = _make_material_additive()
	flash.z_index = 46
	add_child(flash)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(3.6, 3.6), 0.6).set_ease(Tween.EASE_OUT)
	tween.tween_property(flash, "modulate:a", 0.0, 0.6)
	tween.chain().tween_callback(flash.queue_free)

func heal_burst(pos: Vector2) -> void:
	emit_particles(pos, shard_tex, Color(0.5, 1.0, 1.0), 18, 60.0, 220.0,
		Vector2(0.0, -80.0), 0.9, 0.2, 0.45, 180.0)
	var flash := Sprite2D.new()
	flash.texture = glow_tex
	flash.position = pos
	flash.scale = Vector2(0.4, 0.4)
	flash.modulate = Color(0.4, 1.0, 1.0, 0.85)
	flash.material = _make_material_additive()
	flash.z_index = 46
	add_child(flash)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(flash, "scale", Vector2(2.4, 2.4), 0.45)
	tween.tween_property(flash, "modulate:a", 0.0, 0.45)
	tween.chain().tween_callback(flash.queue_free)

func slash(pos: Vector2, facing: int, color: Color, heavy: bool) -> void:
	var s = SlashScene.new()
	s.position = pos
	add_child(s)
	s.setup(facing, color, heavy)

func shockwave(pos: Vector2, color: Color, radius: float = 180.0, duration: float = 0.55) -> void:
	var s = ShockwaveScene.new()
	s.position = pos
	s.scale = Vector2(1.0, 0.42)
	add_child(s)
	s.setup(radius, color, duration)

func damage_number(pos: Vector2, amount: int, color: Color, heavy: bool = false, crit: bool = false) -> void:
	var label := Label.new()
	label.text = str(amount)
	label.z_index = 70
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var size := 34 if heavy or crit else 24
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.03, 0.02, 0.02, 0.95))
	label.add_theme_constant_override("outline_size", 5)
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.position = pos + Vector2(randf_range(-26.0, 26.0), -150.0)
	add_child(label)
	var rise := 54.0 if not heavy else 72.0
	var tween := create_tween().set_parallel(true)
	tween.tween_property(label, "position:y", label.position.y - rise, 0.62).set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(label, "modulate:a", 0.0, 0.62).set_delay(0.12)
	tween.tween_property(label, "scale", Vector2(1.22, 1.22) if heavy else Vector2(1.08, 1.08), 0.08)
	tween.chain().tween_callback(label.queue_free)

func afterimage(sprite: Sprite2D, tint: Color) -> void:
	if sprite == null or sprite.texture == null:
		return
	var ghost := Sprite2D.new()
	ghost.texture = sprite.texture
	ghost.global_transform = sprite.global_transform
	ghost.flip_h = sprite.flip_h
	ghost.modulate = tint
	ghost.z_index = 9
	add_child(ghost)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(ghost, "modulate:a", 0.0, 0.28)
	tween.tween_property(ghost, "scale:x", ghost.scale.x * 0.94, 0.28)
	tween.chain().tween_callback(ghost.queue_free)
