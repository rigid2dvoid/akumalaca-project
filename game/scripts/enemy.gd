extends CharacterBody2D
## Monoseeds — Heavy Enforcer.
## State machine dengan telegraph, stomp, charge (fase 2), stagger,
## dan animasi prosedural yang membuat siluet T-pose terasa hidup.

signal health_changed(hp: int, max_hp: int)
signal defeated
signal phase_changed(phase: int)
signal activated
signal attack_landed(kind: String, origin: Vector2, radius: float, damage: int)

enum State { DORMANT, CHASE, WINDUP, ATTACK, CHARGE_WINDUP, CHARGE, RECOVER, STAGGER, DEAD }

const MAX_HP := 380
const GRAVITY := 1850.0

var main
var fx
var audio
var player

var state: State = State.DORMANT
var hp := MAX_HP
var max_hp := MAX_HP
var phase := 1
var facing := -1
var active := false
var dead := false
var state_timer := 0.0
var attack_cooldown := 1.2
var charge_cooldown := 5.5
var windup_kind := "melee"
var hit_done := true
var flash_time := 0.0
var anim_time := 0.0
var run_phase := 0.0
var shake_amount := 0.0

var visual: Node2D
var sprite: Sprite2D
var glow: Sprite2D
var shadow: Sprite2D
var warning: Label
var char_mat: ShaderMaterial

func _ready() -> void:
	z_index = 9
	collision_layer = 4
	collision_mask = 1
	floor_snap_length = 10.0

	var shape := CapsuleShape2D.new()
	shape.radius = 52.0
	shape.height = 146.0
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -73)
	add_child(col)

	shadow = Sprite2D.new()
	shadow.texture = load("res://assets/fx/glow.png")
	shadow.modulate = Color(0.0, 0.0, 0.0, 0.55)
	shadow.scale = Vector2(1.05, 0.22)
	shadow.position = Vector2(0, 2)
	shadow.show_behind_parent = true
	add_child(shadow)

	visual = Node2D.new()
	visual.position = Vector2(0, -92)
	add_child(visual)

	glow = Sprite2D.new()
	glow.texture = load("res://assets/fx/glow.png")
	glow.modulate = Color(0.75, 0.32, 1.0, 0.2)
	glow.scale = Vector2(1.6, 1.15)
	glow.material = _additive_material()
	visual.add_child(glow)

	char_mat = ShaderMaterial.new()
	char_mat.shader = load("res://shaders/character.gdshader")
	char_mat.set_shader_parameter("flash_color", Color(0.85, 1.0, 0.7, 1.0))
	char_mat.set_shader_parameter("aura_color", Color(1.0, 0.22, 0.12, 1.0))

	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/characters/monoseeds.png")
	sprite.scale = Vector2(0.54, 0.54)
	sprite.material = char_mat
	visual.add_child(sprite)

	warning = Label.new()
	warning.text = "!"
	warning.visible = false
	warning.z_index = 15
	warning.position = Vector2(-16, -238)
	warning.add_theme_font_size_override("font_size", 46)
	warning.add_theme_color_override("font_color", Color(1.0, 0.35, 0.15))
	warning.add_theme_color_override("font_outline_color", Color(0.05, 0.01, 0.01, 0.95))
	warning.add_theme_constant_override("outline_size", 7)
	add_child(warning)

	health_changed.emit(hp, MAX_HP)

func _additive_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat

func activate() -> void:
	if active or dead:
		return
	active = true
	state = State.CHASE
	attack_cooldown = 1.0
	charge_cooldown = 4.5
	activated.emit()

func _physics_process(delta: float) -> void:
	anim_time += delta
	flash_time = maxf(0.0, flash_time - delta)
	attack_cooldown = maxf(0.0, attack_cooldown - delta)
	charge_cooldown = maxf(0.0, charge_cooldown - delta)
	shake_amount = maxf(0.0, shake_amount - delta * 4.0)

	if dead:
		return

	if not is_on_floor():
		velocity.y = minf(velocity.y + GRAVITY * delta, 1150.0)
	else:
		velocity.y = 0.0

	if not active:
		velocity.x = move_toward(velocity.x, 0.0, 2000.0 * delta)
		move_and_slide()
		_update_animation(delta)
		return

	if player == null or not is_instance_valid(player):
		_update_animation(delta)
		return

	var dx: float = player.global_position.x - global_position.x
	var dist := absf(dx)
	if dist > 20.0:
		facing = 1 if dx > 0.0 else -1

	match state:
		State.CHASE:
			_do_chase(delta, dx, dist)
		State.WINDUP:
			_do_windup(delta)
		State.ATTACK:
			_do_attack(delta)
		State.CHARGE_WINDUP:
			_do_charge_windup(delta)
		State.CHARGE:
			_do_charge(delta, dist)
		State.RECOVER:
			_do_recover(delta)
		State.STAGGER:
			_do_stagger(delta)

	velocity.x = move_toward(velocity.x, 0.0, 650.0 * delta) if state in [State.WINDUP, State.RECOVER, State.STAGGER] else velocity.x
	move_and_slide()
	global_position.x = clampf(global_position.x, 130.0, 2500.0)
	_update_animation(delta)

func _do_chase(delta: float, dx: float, dist: float) -> void:
	var speed := 120.0 if phase == 1 else 172.0
	if dist > 150.0:
		velocity.x = move_toward(velocity.x, signf(dx) * speed, 650.0 * delta)
		if randf() < delta * 6.0 and fx:
			fx.dust(global_position + Vector2(-facing * 40.0, -3.0), -facing, 2, Color(0.4, 0.38, 0.45, 0.4))
	else:
		velocity.x = move_toward(velocity.x, 0.0, 1400.0 * delta)
		if attack_cooldown <= 0.0 and is_on_floor():
			_enter_windup("melee")
			return
	if phase == 2 and charge_cooldown <= 0.0 and dist > 360.0 and is_on_floor():
		_enter_windup("charge")
		return

func _do_windup(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		if windup_kind == "charge":
			_enter_charge()
		else:
			_enter_attack()

func _do_attack(delta: float) -> void:
	state_timer -= delta
	if not hit_done and state_timer <= 0.19:
		hit_done = true
		var origin := global_position + Vector2(facing * 80.0, -50.0)
		attack_landed.emit("melee", origin, 170.0, 18)
		if fx:
			fx.shockwave(global_position + Vector2(facing * 90.0, 0.0), Color(1.0, 0.45, 0.12), 150.0, 0.38)
		if main:
			main.add_trauma(0.32)
		if audio:
			audio.play("enemy_attack", -3.0, randf_range(0.9, 1.0))
	if state_timer <= 0.0:
		_enter_recover(0.6 if phase == 1 else 0.38)

func _do_charge_windup(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		_enter_charge()

func _do_charge(delta: float, dist: float) -> void:
	state_timer -= delta
	velocity.x = facing * (560.0 if phase == 1 else 680.0)
	if not hit_done and dist < 130.0 and absf(player.global_position.y - global_position.y) < 170.0:
		hit_done = true
		var origin := global_position + Vector2(facing * 60.0, -50.0)
		attack_landed.emit("charge", origin, 150.0, 26)
		if main:
			main.add_trauma(0.5)
		if fx:
			fx.shockwave(global_position + Vector2(0, 0), Color(1.0, 0.25, 0.1), 190.0, 0.45)
		if audio:
			audio.play("hit_heavy", -2.0, 0.8)
	if state_timer <= 0.0:
		charge_cooldown = 5.0
		_enter_recover(0.5)

func _do_recover(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		state = State.CHASE
		attack_cooldown = 1.5 if phase == 1 else 1.0

func _do_stagger(delta: float) -> void:
	state_timer -= delta
	if state_timer <= 0.0:
		state = State.CHASE
		attack_cooldown = 0.7

func _enter_windup(kind: String) -> void:
	windup_kind = kind
	state = State.WINDUP if kind == "melee" else State.CHARGE_WINDUP
	state_timer = 0.62 if phase == 1 else 0.48
	if kind == "charge":
		state_timer = 0.52 if phase == 1 else 0.4
	velocity.x = 0.0
	shake_amount = 0.5
	warning.visible = true
	if audio:
		audio.play("windup", -7.0, 0.85 if kind == "charge" else 1.0)
	if fx:
		fx.emit_particles(global_position + Vector2(0, -70), fx.spark_tex,
			Color(1.0, 0.35, 0.12), 8, 20.0, 80.0, Vector2(0, -60), 0.6, 0.2, 0.4, 180.0)

func _enter_attack() -> void:
	state = State.ATTACK
	state_timer = 0.34
	hit_done = false
	velocity.x = facing * 290.0
	if fx:
		fx.dust(global_position + Vector2(-facing * 50.0, -4.0), -facing, 8, Color(0.4, 0.38, 0.42, 0.45))

func _enter_charge() -> void:
	state = State.CHARGE
	state_timer = 0.48 if phase == 1 else 0.42
	hit_done = false
	velocity.x = facing * 620.0
	if audio:
		audio.play("charge", -6.0, 0.8)
	if fx:
		fx.dust(global_position + Vector2(-facing * 60.0, -4.0), -facing, 14, Color(0.5, 0.42, 0.4, 0.5))

func _enter_recover(duration: float) -> void:
	state = State.RECOVER
	state_timer = duration
	warning.visible = false
	shake_amount = 0.0

func take_damage(amount: int, source_x: float, knockback: float, heavy: bool) -> bool:
	if dead:
		return false
	hp = maxi(0, hp - amount)
	flash_time = 0.14
	health_changed.emit(hp, MAX_HP)
	var dir := 1
	if global_position.x < source_x:
		dir = -1
	if heavy:
		velocity.x = dir * knockback * 0.85
		if state != State.DEAD:
			state = State.STAGGER
			state_timer = 0.42 if phase == 1 else 0.25
			warning.visible = false
	else:
		velocity.x = dir * knockback * 0.35
	if audio:
		audio.play("hit", -5.0, randf_range(0.9, 1.06))
	if fx:
		fx.hit(global_position + Vector2(randf_range(-40.0, 40.0), -95.0),
			Color(0.7, 1.0, 0.35), -dir, heavy)
	if hp <= 0:
		_die()
	elif hp <= MAX_HP / 2 and phase == 1:
		_enter_phase_two()
	return true

func _enter_phase_two() -> void:
	phase = 2
	charge_cooldown = 1.2
	state = State.RECOVER
	state_timer = 0.7
	warning.visible = false
	shake_amount = 0.8
	if main:
		main.add_trauma(0.55)
	if fx:
		fx.shockwave(global_position + Vector2(0, 0), Color(1.0, 0.22, 0.1), 240.0, 0.7)
		fx.emit_particles(global_position + Vector2(0, -80), fx.spark_tex,
			Color(1.0, 0.3, 0.1), 24, 80.0, 260.0, Vector2(0, 300), 0.8, 0.2, 0.5, 180.0)
	if audio:
		audio.play("windup", -4.0, 0.6)
	phase_changed.emit(2)

func _die() -> void:
	if dead:
		return
	dead = true
	active = false
	state = State.DEAD
	collision_layer = 0
	collision_mask = 0
	velocity = Vector2.ZERO
	warning.visible = false
	health_changed.emit(0, MAX_HP)
	if fx:
		fx.death_burst(global_position + Vector2(0, -90), Color(0.65, 1.0, 0.35))
		fx.shockwave(global_position, Color(0.65, 1.0, 0.35), 220.0, 0.65)
	if audio:
		audio.play("enemy_attack", -6.0, 0.7)
	defeated.emit()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(visual, "rotation", -facing * 1.4, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(visual, "position:y", -40.0, 1.0)
	tween.tween_method(func(v: float) -> void: char_mat.set_shader_parameter("dissolve", v), 0.0, 0.85, 1.5).set_delay(0.3)
	tween.tween_property(visual, "modulate:a", 0.0, 1.6).set_delay(0.25)
	tween.tween_property(shadow, "modulate:a", 0.0, 1.0)
	tween.chain().tween_callback(queue_free)

func _update_animation(delta: float) -> void:
	var base_y := -92.0
	var bob := 0.0
	var xoff := 0.0
	var target_scale := Vector2.ONE
	var target_rot := 0.0
	var speed_ratio := clampf(absf(velocity.x) / 560.0, 0.0, 1.0)

	match state:
		State.DORMANT:
			bob = sin(anim_time * 1.9) * 1.8
			var breath := sin(anim_time * 1.9)
			target_scale = Vector2(1.0 + breath * 0.014, 1.0 - breath * 0.02)
			target_rot = sin(anim_time * 0.9) * 0.012
		State.CHASE:
			run_phase += delta * (5.5 + absf(velocity.x) * 0.03)
			bob = absf(sin(run_phase)) * 7.0 * speed_ratio
			target_scale = Vector2(1.0 + sin(run_phase * 2.0) * 0.025, 1.0 - sin(run_phase * 2.0) * 0.022)
			target_rot = facing * (0.045 + sin(run_phase) * 0.02) * maxf(0.35, speed_ratio)
		State.WINDUP, State.CHARGE_WINDUP:
			var charge := state == State.CHARGE_WINDUP
			target_scale = Vector2(1.09 if charge else 1.06, 0.9 if charge else 0.93)
			bob = -3.0
			xoff = randf_range(-4.0, 4.0)
			target_rot = randf_range(-0.035, 0.035)
		State.ATTACK:
			var k := clampf(1.0 - state_timer / 0.34, 0.0, 1.0)
			var swing := sin(k * PI)
			target_scale = Vector2(1.0 + 0.1 * swing, 1.0 - 0.07 * swing)
			target_rot = facing * lerpf(-0.16, 0.15, k)
			xoff = facing * swing * 12.0
		State.CHARGE:
			target_scale = Vector2(1.12, 0.92)
			target_rot = facing * 0.13
		State.STAGGER:
			target_scale = Vector2(0.94, 1.05)
			target_rot = -facing * 0.16
			xoff = randf_range(-3.0, 3.0)
		State.RECOVER:
			var breath2 := sin(anim_time * 3.2)
			target_scale = Vector2(1.0 + breath2 * 0.01, 1.0 - breath2 * 0.015)
			bob = 2.0

	if phase == 2:
		target_scale *= 1.045

	visual.position = Vector2(xoff, base_y - bob)
	visual.scale = visual.scale.lerp(target_scale, 1.0 - exp(-12.0 * delta))
	visual.rotation = lerp_angle(visual.rotation, target_rot, 1.0 - exp(-13.0 * delta))
	sprite.flip_h = facing < 0

	var windup_boost := 0.4 if state in [State.WINDUP, State.CHARGE_WINDUP] else 0.0
	var aura := (0.34 if phase == 2 else 0.0) + windup_boost
	aura += sin(anim_time * (4.0 if phase == 2 else 2.0)) * 0.06
	char_mat.set_shader_parameter("aura", clampf(aura, 0.0, 1.0))
	char_mat.set_shader_parameter("flash", clampf(flash_time / 0.14, 0.0, 1.0))

	glow.modulate.a = (0.24 if phase == 2 else 0.18) + 0.06 * sin(anim_time * 2.6)
	glow.modulate = Color(0.75, 0.32, 1.0, glow.modulate.a) if phase == 1 else Color(1.0, 0.25, 0.1, glow.modulate.a)
	shadow.modulate.a = 0.55

	if warning.visible:
		warning.modulate.a = 0.55 + 0.45 * sin(anim_time * 18.0)
		warning.scale = Vector2.ONE * (0.9 + 0.15 * sin(anim_time * 10.0))
