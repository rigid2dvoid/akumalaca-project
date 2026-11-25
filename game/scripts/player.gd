extends CharacterBody2D
## Jack O' Way — kontrol pemain yang responsif:
## akselerasi, coyote time, jump buffer, variable jump, dash i-frame,
## combo 3-hit, serta animasi prosedural (idle/run/jump/attack/hurt/death).

signal health_changed(hp: int, max_hp: int)
signal died
signal attack_hit(data: Dictionary)
signal dash_started

const MAX_HP := 100
const SPEED := 330.0
const GROUND_ACCEL := 2600.0
const AIR_ACCEL := 1700.0
const GROUND_FRICTION := 3000.0
const AIR_FRICTION := 900.0
const GRAVITY := 1850.0
const MAX_FALL := 1150.0
const JUMP_VELOCITY := -670.0
const DASH_SPEED := 760.0
const DASH_TIME := 0.16
const DASH_COOLDOWN := 0.72
const COYOTE_TIME := 0.11
const JUMP_BUFFER_TIME := 0.13
const ATTACK_TIME := [0.27, 0.29, 0.36]
const ATTACK_DAMAGE := [15, 17, 26]
const ATTACK_REACH := [165.0, 178.0, 210.0]
const ATTACK_KNOCKBACK := [150.0, 185.0, 330.0]
const ATTACK_HIT_DELAY := [0.07, 0.08, 0.13]

var main
var fx
var audio

var hp := MAX_HP
var max_hp := MAX_HP
var facing := 1
var active := true
var dead := false
var invulnerable := 0.0
var hurt_time := 0.0
var dash_time := 0.0
var dash_cooldown := 0.0
var dash_dir := 1
var jump_buffer := 0.0
var coyote := 0.0
var attack_time := 0.0
var attack_elapsed := 0.0
var attack_duration := 0.27
var attack_hit_done := true
var attack_heavy := false
var attack_hit_delay := 0.07
var attack_buffer := 0.0
var combo_index := 0
var combo_window := 0.0
var flash_time := 0.0
var land_squash := 0.0
var anim_time := 0.0
var run_phase := 0.0
var last_step_sign := 0.0
var was_on_floor := true
var trail_timer := 0.0

var visual: Node2D
var sprite: Sprite2D
var glow: Sprite2D
var eye_glow: Sprite2D
var shadow: Sprite2D
var char_mat: ShaderMaterial
var air_peak_y := 0.0

func _ready() -> void:
	z_index = 10
	collision_layer = 2
	collision_mask = 1
	floor_snap_length = 10.0

	var shape := CapsuleShape2D.new()
	shape.radius = 29.0
	shape.height = 168.0
	var col := CollisionShape2D.new()
	col.shape = shape
	col.position = Vector2(0, -84)
	add_child(col)

	# Bayangan.
	shadow = Sprite2D.new()
	shadow.texture = load("res://assets/fx/glow.png")
	shadow.modulate = Color(0.0, 0.0, 0.0, 0.55)
	shadow.scale = Vector2(0.52, 0.13)
	shadow.position = Vector2(0, 2)
	shadow.show_behind_parent = true
	add_child(shadow)

	# Visual (origin di dada supaya rotasi/scale terasa natural).
	visual = Node2D.new()
	visual.position = Vector2(0, -99)
	add_child(visual)

	glow = Sprite2D.new()
	glow.texture = load("res://assets/fx/glow.png")
	glow.modulate = Color(1.0, 0.45, 0.12, 0.22)
	glow.scale = Vector2(0.9, 1.05)
	glow.material = _additive_material()
	visual.add_child(glow)

	char_mat = ShaderMaterial.new()
	char_mat.shader = load("res://shaders/character.gdshader")
	char_mat.set_shader_parameter("flash_color", Color(1.0, 0.55, 0.4, 1.0))

	sprite = Sprite2D.new()
	sprite.texture = load("res://assets/characters/jack_o_way.png")
	sprite.scale = Vector2(0.365, 0.365)
	sprite.material = char_mat
	visual.add_child(sprite)

	eye_glow = Sprite2D.new()
	eye_glow.texture = load("res://assets/fx/glow.png")
	eye_glow.modulate = Color(1.0, 0.55, 0.12, 0.45)
	eye_glow.scale = Vector2(0.17, 0.09)
	eye_glow.position = Vector2(0, -78)
	eye_glow.material = _additive_material()
	visual.add_child(eye_glow)

	health_changed.emit(hp, MAX_HP)

func get_dash_ratio() -> float:
	return clampf(1.0 - dash_cooldown / DASH_COOLDOWN, 0.0, 1.0)

func _additive_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat

func _physics_process(delta: float) -> void:
	_tick_timers(delta)

	if dead:
		if not is_on_floor():
			velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
			move_and_slide()
		return

	var dir := 0.0
	if active and not _main_locked():
		dir = Input.get_axis("move_left", "move_right")

	# ── Dash ────────────────────────────────────────────────────────
	if active and not _main_locked() and Input.is_action_just_pressed("dash") and dash_cooldown <= 0.0 and hurt_time <= 0.0:
		_start_dash(dir)

	if dash_time > 0.0:
		velocity.x = dash_dir * DASH_SPEED
		velocity.y = 0.0
		trail_timer -= delta
		if trail_timer <= 0.0:
			trail_timer = 0.035
			if fx:
				fx.afterimage(sprite, Color(0.35, 0.9, 1.0, 0.55))
	else:
		# ── Gerak horizontal ────────────────────────────────────────
		var speed_scale := 0.3 if attack_time > 0.0 else 1.0
		var target := dir * SPEED * speed_scale
		var accel := GROUND_ACCEL if is_on_floor() else AIR_ACCEL
		var friction := GROUND_FRICTION if is_on_floor() else AIR_FRICTION
		if absf(dir) > 0.01:
			velocity.x = move_toward(velocity.x, target, accel * delta)
		else:
			velocity.x = move_toward(velocity.x, 0.0, friction * delta)
		if attack_time <= 0.0 and hurt_time <= 0.0 and absf(dir) > 0.01:
			facing = 1 if dir > 0.0 else -1

		# ── Lompat ──────────────────────────────────────────────────
		if is_on_floor():
			coyote = COYOTE_TIME
		if active and not _main_locked() and Input.is_action_just_pressed("jump"):
			jump_buffer = JUMP_BUFFER_TIME
		if jump_buffer > 0.0 and coyote > 0.0 and hurt_time <= 0.0:
			velocity.y = JUMP_VELOCITY
			jump_buffer = 0.0
			coyote = 0.0
			land_squash = 0.0
			if fx:
				fx.jump_burst(global_position + Vector2(0, -6))
			if audio:
				audio.play("jump", -8.0, randf_range(0.95, 1.06))
			if main:
				main.add_trauma(0.04)
		if not Input.is_action_pressed("jump") and velocity.y < -230.0:
			velocity.y = maxf(velocity.y, -230.0)

		if not is_on_floor():
			velocity.y = minf(velocity.y + GRAVITY * delta, MAX_FALL)
		else:
			velocity.y = 0.0

	# ── Serangan ────────────────────────────────────────────────────
	if active and not _main_locked() and Input.is_action_just_pressed("attack"):
		attack_buffer = 0.18
	if attack_buffer > 0.0 and attack_time <= 0.0 and hurt_time <= 0.0 and dash_time <= 0.0:
		_start_attack()

	if attack_time > 0.0:
		attack_elapsed += delta
		if not attack_hit_done and attack_elapsed >= attack_hit_delay:
			attack_hit_done = true
			attack_hit.emit({
				"damage": ATTACK_DAMAGE[combo_index - 1],
				"reach": ATTACK_REACH[combo_index - 1],
				"knockback": ATTACK_KNOCKBACK[combo_index - 1],
				"heavy": attack_heavy,
				"combo": combo_index,
				"facing": facing,
			})

	# ── Fisika & pendaratan ─────────────────────────────────────────
	var fall_speed := velocity.y
	move_and_slide()
	global_position.x = clampf(global_position.x, 48.0, 2552.0)

	if is_on_floor() and not was_on_floor and fall_speed > 220.0:
		land_squash = 0.15
		if fx:
			fx.jump_burst(global_position + Vector2(0, -4))
		if audio:
			audio.play("land", -10.0, randf_range(0.9, 1.05))
		if main:
			main.add_trauma(clampf(fall_speed / 2400.0, 0.05, 0.28))
	was_on_floor = is_on_floor()

	_update_animation(delta)

func _tick_timers(delta: float) -> void:
	invulnerable = maxf(0.0, invulnerable - delta)
	hurt_time = maxf(0.0, hurt_time - delta)
	dash_cooldown = maxf(0.0, dash_cooldown - delta)
	jump_buffer = maxf(0.0, jump_buffer - delta)
	coyote = maxf(0.0, coyote - delta)
	combo_window = maxf(0.0, combo_window - delta)
	flash_time = maxf(0.0, flash_time - delta)
	land_squash = maxf(0.0, land_squash - delta)
	attack_buffer = maxf(0.0, attack_buffer - delta)
	if combo_window <= 0.0:
		combo_index = 0

	var was_dashing := dash_time > 0.0
	dash_time = maxf(0.0, dash_time - delta)
	if was_dashing and dash_time <= 0.0:
		velocity.x *= 0.55

	if attack_time > 0.0:
		attack_time = maxf(0.0, attack_time - delta)
		if attack_time <= 0.0:
			attack_heavy = false

func _start_dash(dir: float) -> void:
	dash_dir = facing if absf(dir) < 0.01 else (1 if dir > 0.0 else -1)
	facing = dash_dir
	dash_time = DASH_TIME
	dash_cooldown = DASH_COOLDOWN
	invulnerable = maxf(invulnerable, 0.2)
	hurt_time = 0.0
	attack_time = 0.0
	attack_buffer = 0.0
	trail_timer = 0.0
	velocity.y = 0.0
	if fx:
		fx.dust(global_position + Vector2(-dash_dir * 20.0, -8.0), -dash_dir, 10, Color(0.45, 0.75, 0.9, 0.45))
		fx.afterimage(sprite, Color(0.35, 0.9, 1.0, 0.7))
	if audio:
		audio.play("dash", -7.0, randf_range(0.94, 1.06))
	if main:
		main.add_trauma(0.08)
	dash_started.emit()

func _start_attack() -> void:
	combo_index = combo_index + 1 if combo_window > 0.0 else 1
	if combo_index > 3:
		combo_index = 1
	combo_window = 0.85
	attack_duration = ATTACK_TIME[combo_index - 1]
	attack_time = attack_duration
	attack_elapsed = 0.0
	attack_hit_delay = ATTACK_HIT_DELAY[combo_index - 1]
	attack_hit_done = false
	attack_heavy = combo_index == 3
	attack_buffer = 0.0
	velocity.x = facing * (250.0 if attack_heavy else 165.0)
	flash_time = 0.0
	if fx:
		fx.slash(global_position + Vector2(facing * 34.0, -108.0), facing, Color(1.0, 0.5, 0.14), attack_heavy)
	if audio:
		audio.play("slash%d" % combo_index, -6.0, randf_range(0.94, 1.06))

func _main_locked() -> bool:
	return main != null and main.has_method("is_input_locked") and main.is_input_locked()

func _update_animation(delta: float) -> void:
	anim_time += delta
	var base_y := -99.0
	var bob := 0.0
	var xoff := 0.0
	var target_scale := Vector2.ONE
	var target_rot := 0.0

	if hurt_time > 0.0:
		xoff = randf_range(-5.0, 5.0)
		target_scale = Vector2(0.94, 1.05)
		target_rot = randf_range(-0.06, 0.06)
	elif dash_time > 0.0:
		target_scale = Vector2(1.14, 0.9)
		target_rot = facing * 0.17
		xoff = facing * 8.0
	elif attack_time > 0.0:
		var k := clampf(1.0 - attack_time / attack_duration, 0.0, 1.0)
		var swing := sin(k * PI)
		var power := 1.35 if attack_heavy else 1.0
		target_scale = Vector2(1.0 + 0.07 * swing * power, 1.0 - 0.05 * swing)
		target_rot = facing * lerpf(-0.2, 0.14, swing) * power
		xoff = facing * swing * (16.0 if attack_heavy else 10.0)
	elif not is_on_floor():
		if velocity.y < 0.0:
			target_scale = Vector2(0.95, 1.07)
			target_rot = -facing * 0.06
		else:
			target_scale = Vector2(1.04, 0.96)
			target_rot = facing * 0.05
	elif absf(velocity.x) > 26.0:
		var ratio := clampf(absf(velocity.x) / SPEED, 0.0, 1.0)
		run_phase += delta * (8.0 + absf(velocity.x) * 0.028)
		bob = absf(sin(run_phase)) * 7.0 * ratio
		target_scale = Vector2(1.0 + sin(run_phase * 2.0) * 0.022 * ratio, 1.0 - sin(run_phase * 2.0) * 0.02 * ratio)
		target_rot = facing * (0.055 + sin(run_phase) * 0.02) * ratio
		var step_sign := signf(sin(run_phase))
		if step_sign != last_step_sign and fx:
			last_step_sign = step_sign
			fx.dust(global_position, -facing, 3, Color(0.42, 0.48, 0.6, 0.38))
	else:
		bob = sin(anim_time * 2.2) * 2.0
		var breath := sin(anim_time * 2.2)
		target_scale = Vector2(1.0 + breath * 0.012, 1.0 - breath * 0.02)
		target_rot = sin(anim_time * 1.15) * 0.014

	if land_squash > 0.0:
		target_scale = Vector2(1.15, 0.85)
		bob = 0.0

	visual.position = Vector2(xoff, base_y - bob)
	visual.scale = visual.scale.lerp(target_scale, 1.0 - exp(-18.0 * delta))
	visual.rotation = lerp_angle(visual.rotation, target_rot, 1.0 - exp(-15.0 * delta))
	sprite.flip_h = facing < 0

	glow.modulate.a = 0.2 + 0.06 * sin(anim_time * 2.1)
	eye_glow.modulate.a = 0.42 + 0.2 * sin(anim_time * 3.3)
	shadow.modulate.a = (0.5 if is_on_floor() else 0.18) * (0.9 + 0.1 * sin(anim_time * 2.0))
	shadow.scale = Vector2(0.52, 0.13)

	if invulnerable > 0.0 and not dead:
		sprite.modulate.a = 0.45 if int(anim_time * 24.0) % 2 == 0 else 1.0
	else:
		sprite.modulate.a = 1.0

	var flash := 0.0
	if flash_time > 0.0:
		flash = clampf(flash_time / 0.16, 0.0, 1.0)
	char_mat.set_shader_parameter("flash", flash)
	char_mat.set_shader_parameter("aura", 0.0)

func take_damage(amount: int, source_x: float, knockback: float = 300.0) -> bool:
	if dead or invulnerable > 0.0:
		return false
	hp = maxi(0, hp - amount)
	invulnerable = 0.95
	hurt_time = 0.28
	attack_time = 0.0
	attack_buffer = 0.0
	dash_time = 0.0
	flash_time = 0.2
	var dir := 1
	if global_position.x < source_x:
		dir = -1
	velocity = Vector2(dir * knockback, -270.0)
	health_changed.emit(hp, MAX_HP)
	if fx:
		fx.hit(global_position + Vector2(dir * -20.0, -100.0), Color(1.0, 0.35, 0.2), -dir, false)
	if audio:
		audio.play("hurt", -4.0, randf_range(0.92, 1.05))
	if main:
		main.on_player_damaged(amount)
	if hp <= 0:
		_die()
	return true

func heal(amount: int) -> void:
	if dead:
		return
	hp = mini(MAX_HP, hp + amount)
	health_changed.emit(hp, MAX_HP)
	if fx:
		fx.heal_burst(global_position + Vector2(0, -100))
	if audio:
		audio.play("heal", -5.0, 1.0)

func _die() -> void:
	if dead:
		return
	dead = true
	active = false
	velocity = Vector2(0, -180)
	if fx:
		fx.death_burst(global_position + Vector2(0, -90), Color(1.0, 0.4, 0.15))
	if audio:
		audio.play("defeat", -3.0, 1.0)
	died.emit()

	var tween := create_tween().set_parallel(true)
	tween.tween_property(visual, "rotation", facing * 1.45, 1.0).set_trans(Tween.TRANS_CUBIC)
	tween.tween_property(visual, "position:y", -55.0, 1.0)
	tween.tween_method(func(v: float) -> void: char_mat.set_shader_parameter("dissolve", v), 0.0, 0.75, 1.4).set_delay(0.25)
	tween.tween_property(visual, "modulate:a", 0.0, 1.5).set_delay(0.2)
	tween.tween_property(shadow, "modulate:a", 0.0, 1.0)
