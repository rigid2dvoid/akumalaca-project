extends Node2D
## Direktur permainan: menyusun dunia, kamera sinematik, alur misi,
## resolusi tempur, dan seluruh feedback (shake, hitstop, partikel).

const ARENA_WIDTH := 2600.0
const GROUND_Y := 600.0
const ARENA_LEFT := 640.0
const ARENA_RIGHT := 1960.0

const PlayerScript := preload("res://scripts/player.gd")
const EnemyScript := preload("res://scripts/enemy.gd")
const HudScript := preload("res://scripts/hud.gd")
const FxScript := preload("res://scripts/fx.gd")
const AudioScript := preload("res://scripts/audio_manager.gd")
const PickupScript := preload("res://scripts/pickup.gd")
const FloorScript := preload("res://scripts/floor_art.gd")
const PlatformScript := preload("res://scripts/platform.gd")

var state := "explore" # explore | fight | won | lost
var paused := false
var player
var enemy
var camera: Camera2D
var hud
var fx
var audio

var background_root: Node2D
var ambient_glows: Array = []
var lamps: Array = []
var barrier_root: Node2D
var barrier_scan: Line2D
var barrier_core: Line2D

var cam_x := 640.0
var trauma := 0.0
var time_alive := 0.0
var battle_elapsed := 0.0
var fight_started := false
var phase_two_heal_spawned := false

var combo_count := 0
var combo_timer := 0.0
var best_combo := 0
var damage_dealt := 0
var damage_taken := 0
var healed_total := 0
var hitstop_token := 0
var result_pending := false

func _ready() -> void:
	randomize()
	process_mode = Node.PROCESS_MODE_ALWAYS
	_build_background()
	_build_world()
	_build_ambient()

	fx = Node2D.new()
	fx.set_script(FxScript)
	add_child(fx)

	audio = Node.new()
	audio.set_script(AudioScript)
	add_child(audio)

	player = PlayerScript.new()
	player.name = "JackOWay"
	player.position = Vector2(210, GROUND_Y)
	player.main = self
	player.fx = fx
	player.audio = audio
	add_child(player)
	player.health_changed.connect(_on_player_health)
	player.died.connect(_on_player_died)
	player.attack_hit.connect(_on_player_attack)

	enemy = EnemyScript.new()
	enemy.name = "Monoseeds"
	enemy.position = Vector2(2170, GROUND_Y)
	enemy.main = self
	enemy.fx = fx
	enemy.audio = audio
	enemy.player = player
	add_child(enemy)
	enemy.health_changed.connect(_on_enemy_health)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.phase_changed.connect(_on_enemy_phase)
	enemy.attack_landed.connect(_on_enemy_attack)
	enemy.activated.connect(_on_enemy_activated)

	camera = Camera2D.new()
	camera.position = Vector2(640, 360)
	camera.limit_left = 0
	camera.limit_right = int(ARENA_WIDTH)
	camera.limit_top = 0
	camera.limit_bottom = 720
	camera.position_smoothing_enabled = false
	add_child(camera)
	camera.make_current()

	hud = HudScript.new()
	add_child(hud)
	hud.set_player_health(100, 100)
	hud.set_dash_ratio(1.0)
	hud.set_boss_health(380, 380)
	hud.set_objective("TELUSURI SCRAPYARD")
	hud.banner("SECTOR 09 // AKUMALACA", "Cari Monoseeds di ujung scrapyard. Jangan biarkan lenganmu dijarah.", Color(1.0, 0.5, 0.15), 3.6)

	_spawn_pickup(Vector2(430, 552))
	_spawn_pickup(Vector2(1100, 388))
	_spawn_pickup(Vector2(1520, 552))
	_spawn_pickup(Vector2(2360, 552))

	await get_tree().create_timer(1.2).timeout
	if is_inside_tree():
		hud.set_hint("A / D  ·  SPACE  lompat  ·  J / K  serang  ·  SHIFT  dash  ·  ESC  pause")

func _process(delta: float) -> void:
	if paused:
		return

	time_alive += delta
	if state == "fight":
		battle_elapsed += delta

	_update_camera(delta)
	_update_ambient(delta)

	if player and is_instance_valid(player):
		hud.set_dash_ratio(player.get_dash_ratio())

	if combo_timer > 0.0:
		combo_timer -= delta
		if combo_timer <= 0.0 and combo_count > 0:
			combo_count = 0
			hud.set_combo(0)

	if state == "explore" and player and is_instance_valid(player) and player.global_position.x > 1430.0:
		_start_fight()

# ── Pembangunan dunia ─────────────────────────────────────────────

func _build_background() -> void:
	background_root = Node2D.new()
	background_root.z_index = -100
	add_child(background_root)

	var bg_texture: Texture2D = load("res://assets/backgrounds/akumalaca.jpg")
	for i in range(-2, 3):
		var bg := Sprite2D.new()
		bg.texture = bg_texture
		bg.centered = false
		bg.position = Vector2(i * 1408.0, 0.0)
		background_root.add_child(bg)

	# Nebula glow bergerak lambat.
	var glow_texture: Texture2D = load("res://assets/fx/glow.png")
	var nebula_data := [
		{"pos": Vector2(470, 250), "color": Color(0.25, 0.4, 1.0, 0.35), "scale": Vector2(5.0, 3.2), "phase": 0.0},
		{"pos": Vector2(1050, 180), "color": Color(0.6, 0.25, 0.95, 0.26), "scale": Vector2(4.2, 2.6), "phase": 2.1},
		{"pos": Vector2(1750, 280), "color": Color(1.0, 0.4, 0.15, 0.12), "scale": Vector2(5.5, 2.8), "phase": 4.2},
	]
	for data in nebula_data:
		var s := Sprite2D.new()
		s.texture = glow_texture
		s.position = data.pos
		s.scale = data.scale
		s.modulate = data.color
		s.material = _additive_material()
		s.z_index = -96
		background_root.add_child(s)
		ambient_glows.append({"node": s, "base": data.pos, "phase": data.phase, "alpha": data.color.a})

	# Lapisan bintang aditif di atas background.
	var star_rect := ColorRect.new()
	star_rect.position = Vector2(0, 0)
	star_rect.size = Vector2(ARENA_WIDTH, 720)
	star_rect.color = Color.WHITE
	star_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var star_mat := ShaderMaterial.new()
	star_mat.shader = load("res://shaders/starfield.gdshader")
	star_mat.set_shader_parameter("intensity", 0.7)
	star_rect.material = star_mat
	star_rect.z_index = -95
	add_child(star_rect)

	# Kabut horizon.
	for i in range(3):
		var fog := Sprite2D.new()
		fog.texture = glow_texture
		fog.position = Vector2(400.0 + i * 900.0, 555.0)
		fog.scale = Vector2(8.0, 0.9)
		fog.modulate = Color(0.3, 0.45, 0.8, 0.12)
		fog.material = _additive_material()
		fog.z_index = -94
		add_child(fog)
		ambient_glows.append({"node": fog, "base": fog.position, "phase": 1.3 * i, "alpha": 0.12})

func _build_world() -> void:
	var floor_art = StaticBody2D.new()
	floor_art.set_script(FloorScript)
	floor_art.arena_width = ARENA_WIDTH
	floor_art.ground_y = GROUND_Y
	add_child(floor_art)

	var platforms := [
		{"pos": Vector2(610, 500), "size": Vector2(250, 22), "color": Color(1.0, 0.42, 0.1)},
		{"pos": Vector2(1030, 432), "size": Vector2(210, 22), "color": Color(0.25, 0.8, 1.0)},
		{"pos": Vector2(1510, 498), "size": Vector2(260, 22), "color": Color(1.0, 0.42, 0.1)},
		{"pos": Vector2(1980, 438), "size": Vector2(230, 22), "color": Color(0.25, 0.8, 1.0)},
		{"pos": Vector2(2360, 505), "size": Vector2(190, 22), "color": Color(1.0, 0.42, 0.1)},
	]
	for p in platforms:
		var platform = StaticBody2D.new()
		platform.set_script(PlatformScript)
		platform.position = p.pos
		add_child(platform)
		platform.setup(p.pos, p.size, p.color)

	_add_lamp(360.0)
	_add_lamp(1240.0)
	_add_lamp(1880.0)
	_add_lamp(2440.0)

func _add_lamp(x: float) -> void:
	var glow_texture: Texture2D = load("res://assets/fx/glow.png")
	var pole := Line2D.new()
	pole.points = PackedVector2Array([Vector2(x, GROUND_Y), Vector2(x, 438.0), Vector2(x + 34.0, 438.0), Vector2(x + 34.0, 452.0)])
	pole.width = 5.0
	pole.default_color = Color(0.06, 0.07, 0.09)
	pole.z_index = -6
	add_child(pole)

	var light := Sprite2D.new()
	light.texture = glow_texture
	light.position = Vector2(x + 34.0, 458.0)
	light.scale = Vector2(0.65, 0.65)
	light.modulate = Color(1.0, 0.55, 0.18, 0.35)
	light.material = _additive_material()
	light.z_index = -5
	add_child(light)
	lamps.append({"node": light, "phase": randf() * TAU})

func _build_ambient() -> void:
	var glow_texture: Texture2D = load("res://assets/fx/glow.png")

	# Ember hangat yang naik dari lantai.
	var embers := CPUParticles2D.new()
	embers.texture = glow_texture
	embers.position = Vector2(ARENA_WIDTH * 0.5, GROUND_Y)
	embers.amount = 70
	embers.lifetime = 11.0
	embers.preprocess = 7.0
	embers.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	embers.emission_rect_extents = Vector2(ARENA_WIDTH * 0.5, 40.0)
	embers.direction = Vector2(0, -1)
	embers.spread = 32.0
	embers.gravity = Vector2(0, -12)
	embers.initial_velocity_min = 8.0
	embers.initial_velocity_max = 38.0
	embers.scale_amount_min = 0.04
	embers.scale_amount_max = 0.17
	embers.color = Color(1.0, 0.52, 0.16, 0.65)
	var ember_ramp := Gradient.new()
	ember_ramp.set_color(0, Color(1.0, 0.6, 0.2, 0.7))
	ember_ramp.set_color(1, Color(1.0, 0.2, 0.05, 0.0))
	embers.color_ramp = ember_ramp
	embers.material = _additive_material()
	embers.z_index = -3
	add_child(embers)

	# Debu halus di foreground.
	var dust := CPUParticles2D.new()
	dust.texture = load("res://assets/fx/dust.png")
	dust.position = Vector2(ARENA_WIDTH * 0.5, 260)
	dust.amount = 26
	dust.lifetime = 16.0
	dust.preprocess = 10.0
	dust.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	dust.emission_rect_extents = Vector2(ARENA_WIDTH * 0.5, 220.0)
	dust.direction = Vector2(1, 0.2)
	dust.spread = 40.0
	dust.gravity = Vector2(4, -2)
	dust.initial_velocity_min = 4.0
	dust.initial_velocity_max = 18.0
	dust.scale_amount_min = 0.35
	dust.scale_amount_max = 1.1
	dust.color = Color(0.7, 0.82, 1.0, 0.07)
	dust.z_index = 35
	add_child(dust)

func _additive_material() -> CanvasItemMaterial:
	var mat := CanvasItemMaterial.new()
	mat.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	return mat

# ── Alur misi ─────────────────────────────────────────────────────

func _start_fight() -> void:
	if state != "explore":
		return
	state = "fight"
	fight_started = true
	_spawn_barrier()
	hud.show_boss(380.0)
	hud.set_objective("HANCURKAN MONOSEEDS")
	hud.banner("WARNING // MONOSEEDS", "Heavy Enforcer menghadang. Baca telegraph-nya, dash saat serangan datang.", Color(1.0, 0.28, 0.12), 3.2)
	hud.flash(Color(1.0, 0.15, 0.05), 0.28)
	add_trauma(0.5)
	audio.play("enemy_attack", -3.0, 0.72)
	enemy.activate()

func _spawn_barrier() -> void:
	if barrier_root != null:
		return
	barrier_root = Node2D.new()
	barrier_root.position = Vector2(1320, 0)
	barrier_root.z_index = 7
	add_child(barrier_root)

	var body := StaticBody2D.new()
	body.collision_layer = 1
	body.collision_mask = 0
	var col := CollisionShape2D.new()
	var shape := RectangleShape2D.new()
	shape.size = Vector2(28, 600)
	col.shape = shape
	col.position = Vector2(0, 300)
	body.add_child(col)
	barrier_root.add_child(body)

	var field := Polygon2D.new()
	field.polygon = PackedVector2Array([Vector2(-9, 0), Vector2(9, 0), Vector2(9, 600), Vector2(-9, 600)])
	field.color = Color(0.2, 0.75, 1.0, 0.1)
	field.material = _additive_material()
	barrier_root.add_child(field)

	var glow := Sprite2D.new()
	glow.texture = load("res://assets/fx/glow.png")
	glow.position = Vector2(0, 300)
	glow.scale = Vector2(0.4, 4.2)
	glow.modulate = Color(0.3, 0.8, 1.0, 0.28)
	glow.material = _additive_material()
	barrier_root.add_child(glow)

	barrier_core = Line2D.new()
	barrier_core.points = PackedVector2Array([Vector2(0, 0), Vector2(0, 600)])
	barrier_core.width = 4.0
	barrier_core.default_color = Color(0.65, 0.95, 1.0, 0.9)
	barrier_core.material = _additive_material()
	barrier_root.add_child(barrier_core)

	barrier_scan = Line2D.new()
	barrier_scan.points = PackedVector2Array([Vector2(-40, 0), Vector2(40, 0)])
	barrier_scan.width = 3.0
	barrier_scan.default_color = Color(0.7, 1.0, 1.0, 0.55)
	barrier_scan.material = _additive_material()
	barrier_root.add_child(barrier_scan)

func _spawn_pickup(pos: Vector2) -> void:
	var orb = PickupScript.new()
	orb.position = pos
	add_child(orb)

# ── Kamera & ambience ─────────────────────────────────────────────

func _update_camera(delta: float) -> void:
	if player == null or not is_instance_valid(player):
		return
	var look: float = clampf(player.velocity.x * 0.16, -130.0, 130.0) + player.facing * 44.0
	var target := clampf(player.global_position.x + look, ARENA_LEFT, ARENA_RIGHT)
	cam_x = lerpf(cam_x, target, 1.0 - exp(-5.0 * delta))
	camera.position = Vector2(cam_x, 360.0)

	trauma = maxf(0.0, trauma - delta * 1.7)
	var shake := trauma * trauma
	camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * shake * 24.0

	# Parallax: latar bergerak 82% kecepatan kamera.
	background_root.position.x = cam_x * 0.82

func _update_ambient(delta: float) -> void:
	var t := time_alive
	for data in ambient_glows:
		var node: Sprite2D = data.node
		if not is_instance_valid(node):
			continue
		node.position.x = data.base.x + sin(t * 0.09 + data.phase) * 46.0
		node.position.y = data.base.y + sin(t * 0.06 + data.phase * 1.7) * 12.0
		node.modulate.a = data.alpha * (0.82 + 0.18 * sin(t * 0.8 + data.phase))
	for data in lamps:
		var light: Sprite2D = data.node
		if is_instance_valid(light):
			light.modulate.a = 0.3 + 0.12 * sin(t * 2.0 + data.phase)
	if barrier_root != null:
		barrier_core.modulate.a = 0.65 + 0.35 * sin(t * 4.0)
		barrier_scan.position.y = fmod(t * 240.0, 600.0)

func add_trauma(amount: float) -> void:
	trauma = clampf(trauma + amount, 0.0, 1.0)

func _hitstop(duration: float) -> void:
	hitstop_token += 1
	var token := hitstop_token
	Engine.time_scale = 0.06
	await get_tree().create_timer(duration, true, false, true).timeout
	if token == hitstop_token:
		Engine.time_scale = 1.0

# ── Resolusi tempur ───────────────────────────────────────────────

func _on_player_attack(data: Dictionary) -> void:
	if not is_instance_valid(enemy) or enemy.dead:
		return
	var dx: float = enemy.global_position.x - player.global_position.x
	var dy: float = absf(enemy.global_position.y - player.global_position.y)
	var facing: int = data.facing
	var in_arc := absf(dx) <= float(data.reach) and (signf(dx) == facing or absf(dx) < 55.0)
	if not in_arc or dy > 180.0:
		return

	var multiplier := 1.0 + minf(combo_count, 10) * 0.03
	var dmg := int(round(float(data.damage) * multiplier))
	var landed: bool = enemy.take_damage(dmg, player.global_position.x, float(data.knockback), bool(data.heavy))
	if not landed:
		return

	combo_count += 1
	best_combo = maxi(best_combo, combo_count)
	combo_timer = 2.1
	damage_dealt += dmg
	hud.set_combo(combo_count)
	fx.damage_number(enemy.global_position + Vector2(randf_range(-46.0, 46.0), -150.0),
		dmg, Color(1.0, 0.78, 0.28), bool(data.heavy), combo_count >= 5)
	add_trauma(0.34 if data.heavy else 0.18)
	_hitstop(0.055 if data.heavy else 0.03)
	hud.flash(Color(1.0, 0.55, 0.18), 0.05)

func _on_enemy_attack(kind: String, origin: Vector2, radius: float, damage: int) -> void:
	if player == null or not is_instance_valid(player) or player.dead:
		return
	var dx := absf(player.global_position.x - origin.x)
	var dy := absf(player.global_position.y - origin.y)
	if dx > radius or dy > 175.0:
		return
	var knockback := 430.0 if kind == "charge" else 300.0
	if player.take_damage(damage, origin.x, knockback):
		hud.flash(Color(1.0, 0.08, 0.02), 0.32)
		add_trauma(0.6 if kind == "charge" else 0.4)
		_hitstop(0.06)

func on_player_damaged(amount: int) -> void:
	damage_taken += amount

func _on_player_health(value: int, max_value: int) -> void:
	if hud:
		hud.set_player_health(value, max_value)

func _on_enemy_health(value: int, max_value: int) -> void:
	if hud:
		hud.set_boss_health(value, max_value)

func _on_enemy_activated() -> void:
	pass

func _on_enemy_phase(value: int) -> void:
	if value < 2:
		return
	hud.set_boss_phase(2)
	hud.banner("PHASE 2 // OVERDRIVE", "Monoseeds mengamuk. Serangan charge dan stomp jadi jauh lebih cepat.", Color(1.0, 0.2, 0.1), 2.8)
	hud.flash(Color(1.0, 0.1, 0.03), 0.35)
	hud.set_hint("Awas charge! Dash (SHIFT) memberi i-frame.")
	add_trauma(0.65)
	if not phase_two_heal_spawned:
		phase_two_heal_spawned = true
		_spawn_pickup(Vector2(1550, 540))

func _on_enemy_defeated() -> void:
	if result_pending:
		return
	result_pending = true
	state = "won"
	hud.set_boss_health(0, 380)
	hud.set_objective("SEKTOR AMAN")
	hud.banner("TARGET ELIMINATED", "Monoseeds hancur. Lengan cybernetic Jack aman.", Color(1.0, 0.62, 0.2), 2.6)
	hud.flash(Color(1.0, 0.75, 0.35), 0.3)
	add_trauma(0.55)
	audio.play("victory", -3.0, 1.0)
	enemy.set_physics_process(false)
	await get_tree().create_timer(2.0).timeout
	if is_inside_tree():
		hud.show_result(true, _stats())

func _on_player_died() -> void:
	if result_pending:
		return
	result_pending = true
	state = "lost"
	hud.set_objective("MISSION FAILED")
	hud.banner("SIGNAL LOST", "Jack jatuh. Monoseeds menjarah lengan cybernetic-nya.", Color(1.0, 0.18, 0.1), 2.4)
	await get_tree().create_timer(1.8).timeout
	if is_inside_tree():
		hud.show_result(false, _stats())

func on_pickup_collected(pos: Vector2) -> void:
	healed_total += 22
	if hud:
		hud.flash(Color(0.35, 1.0, 1.0), 0.14)
		hud.set_hint("Nanite cache diserap: +22 VITALITY")
	if fx:
		fx.heal_burst(pos)
	if audio:
		audio.play("heal", -5.0, 1.0)

func _stats() -> Dictionary:
	return {
		"time": battle_elapsed,
		"damage_dealt": damage_dealt,
		"damage_taken": damage_taken,
		"best_combo": best_combo,
		"healed": healed_total,
	}

# ── Input global ──────────────────────────────────────────────────

func is_input_locked() -> bool:
	return state == "won" or state == "lost" or paused

func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("pause") and (state == "explore" or state == "fight"):
		_toggle_pause()
		get_viewport().set_input_as_handled()
	elif event.is_action_pressed("restart") and (state == "won" or state == "lost"):
		get_tree().paused = false
		Engine.time_scale = 1.0
		get_tree().reload_current_scene()
	elif event.is_action_pressed("mute"):
		var muted: bool = audio.toggle_mute()
		hud.set_hint("Audio: %s" % ("MUTE" if muted else "ON"))
		get_viewport().set_input_as_handled()

func _toggle_pause() -> void:
	paused = not paused
	get_tree().paused = paused
	hud.show_pause(paused)
	if audio:
		if paused:
			audio.process_mode = Node.PROCESS_MODE_DISABLED
		else:
			audio.process_mode = Node.PROCESS_MODE_INHERIT

func _exit_tree() -> void:
	Engine.time_scale = 1.0
	get_tree().paused = false
