extends Area2D
## Nanite cache: orb penyembuh yang mengapung dan berdenyut.

@export var heal_amount := 22
var _time := 0.0
var _base_y := 0.0
var _glow: Sprite2D
var _core: Sprite2D
var _collected := false

func _ready() -> void:
	collision_layer = 0
	collision_mask = 2
	monitoring = true
	_base_y = position.y
	z_index = 4

	var shape := CollisionShape2D.new()
	var circle := CircleShape2D.new()
	circle.radius = 30.0
	shape.shape = circle
	add_child(shape)

	_glow = Sprite2D.new()
	_glow.texture = load("res://assets/fx/glow.png")
	_glow.modulate = Color(0.3, 0.95, 1.0, 0.55)
	var gm := CanvasItemMaterial.new()
	gm.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	_glow.material = gm
	_glow.scale = Vector2(0.7, 0.7)
	add_child(_glow)

	_core = Sprite2D.new()
	_core.texture = load("res://assets/fx/shard.png")
	_core.modulate = Color(0.72, 1.0, 1.0)
	_core.scale = Vector2(0.72, 0.72)
	add_child(_core)

	body_entered.connect(_on_body_entered)

func _process(delta: float) -> void:
	if _collected:
		return
	_time += delta
	position.y = _base_y + sin(_time * 2.4) * 7.0
	_core.rotation = sin(_time * 1.3) * 0.25
	_core.scale = Vector2.ONE * (0.68 + sin(_time * 3.0) * 0.06)
	var pulse := 0.55 + sin(_time * 2.7) * 0.12
	_glow.modulate.a = pulse
	_glow.scale = Vector2.ONE * (0.66 + sin(_time * 2.7) * 0.06)

func _on_body_entered(body: Node) -> void:
	if _collected or not body.has_method("heal"):
		return
	# Jangan buang cache kalau HP masih penuh — biarkan mengapung untuk nanti.
	if body.get("hp") != null and body.get("max_hp") != null and int(body.hp) >= int(body.max_hp):
		return
	_collected = true
	body.heal(heal_amount)
	var main := get_tree().current_scene
	if main and main.has_method("on_pickup_collected"):
		main.on_pickup_collected(global_position)
	set_deferred("monitoring", false)
	var tween := create_tween().set_parallel(true)
	tween.tween_property(self, "scale", Vector2(1.8, 1.8), 0.22).set_ease(Tween.EASE_OUT)
	tween.tween_property(self, "modulate:a", 0.0, 0.22)
	tween.chain().tween_callback(queue_free)
