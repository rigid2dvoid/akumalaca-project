extends Node2D

var player: CharacterBody2D
var enemy: CharacterBody2D
var camera: Camera2D
var player_bar: ProgressBar
var enemy_bar: ProgressBar
var status_label: Label
var hint_label: Label
var ended := false
var won := false

func _ready() -> void:
    _build_world()
    _build_hud()
    player = CharacterBody2D.new()
    player.set_script(load("res://Player.gd"))
    player.name = "JackOWay"
    player.position = Vector2(250, 620)
    add_child(player)
    player.attack_requested.connect(_on_player_attack)
    player.health_changed.connect(_on_player_health)
    player.player_died.connect(_on_player_died)

    enemy = CharacterBody2D.new()
    enemy.set_script(load("res://Enemy.gd"))
    enemy.name = "Monoseeds"
    enemy.position = Vector2(1720, 604)
    enemy.player = player
    add_child(enemy)
    enemy.health_changed.connect(_on_enemy_health)
    enemy.defeated.connect(_on_enemy_defeated)

    camera = Camera2D.new()
    camera.position = Vector2(640, 360)
    camera.position_smoothing_enabled = true
    camera.position_smoothing_speed = 5.0
    camera.limit_left = 0
    camera.limit_right = 2200
    camera.limit_top = 0
    camera.limit_bottom = 720
    camera.enabled = true
    add_child(camera)
    camera.make_current()
    hint_label.text = "A / D atau ← / → : Bergerak     SPACE : Lompat     J / K : Serang"

func _build_world() -> void:
    for i in range(2):
        var bg := Sprite2D.new()
        bg.texture = load("res://assets/akumalaca.jpeg")
        bg.position = Vector2(704 + i * 1408, 384)
        bg.scale = Vector2.ONE
        bg.z_index = -20
        add_child(bg)
    # subtle dark overlay for readable gameplay
    var shade := ColorRect.new()
    shade.color = Color(0.015, 0.025, 0.045, 0.20)
    shade.position = Vector2(0, 0)
    shade.size = Vector2(2816, 720)
    shade.z_index = -10
    add_child(shade)
    var floor_body := StaticBody2D.new()
    floor_body.name = "WalkableGround"
    floor_body.position = Vector2(1100, 652)
    var floor_col := CollisionShape2D.new()
    var floor_shape := RectangleShape2D.new()
    floor_shape.size = Vector2(2200, 100)
    floor_col.shape = floor_shape
    floor_body.add_child(floor_col)
    add_child(floor_body)
    var floor_visual := Polygon2D.new()
    floor_visual.polygon = PackedVector2Array([Vector2(0, 602), Vector2(2200, 602), Vector2(2200, 720), Vector2(0, 720)])
    floor_visual.color = Color(0.075, 0.085, 0.105, 0.92)
    floor_visual.z_index = -1
    add_child(floor_visual)
    var top_line := Line2D.new()
    top_line.points = PackedVector2Array([Vector2(0, 603), Vector2(2200, 603)])
    top_line.width = 5
    top_line.default_color = Color(1.0, 0.36, 0.08, 0.9)
    top_line.z_index = 0
    add_child(top_line)
    for x in range(80, 2200, 220):
        var seam := Line2D.new()
        seam.points = PackedVector2Array([Vector2(x, 610), Vector2(x + 70, 690)])
        seam.width = 2
        seam.default_color = Color(0.9, 0.32, 0.08, 0.28)
        add_child(seam)

func _build_hud() -> void:
    var layer := CanvasLayer.new()
    add_child(layer)
    var panel := ColorRect.new()
    panel.color = Color(0.015, 0.025, 0.045, 0.82)
    panel.position = Vector2(22, 18)
    panel.size = Vector2(360, 116)
    layer.add_child(panel)
    var title := Label.new()
    title.text = "JACK O' WAY  //  AKUMALACA"
    title.position = Vector2(38, 26)
    title.add_theme_font_size_override("font_size", 19)
    title.add_theme_color_override("font_color", Color(1, 0.43, 0.13))
    layer.add_child(title)
    var ptxt := Label.new()
    ptxt.text = "VITALITY"
    ptxt.position = Vector2(38, 57)
    ptxt.add_theme_font_size_override("font_size", 12)
    layer.add_child(ptxt)
    player_bar = ProgressBar.new()
    player_bar.position = Vector2(38, 78)
    player_bar.size = Vector2(315, 17)
    player_bar.max_value = 100
    player_bar.value = 100
    player_bar.show_percentage = false
    layer.add_child(player_bar)
    var enemy_title := Label.new()
    enemy_title.text = "MONOSEEDS // HEAVY ENFORCER"
    enemy_title.position = Vector2(920, 27)
    enemy_title.size = Vector2(330, 24)
    enemy_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
    enemy_title.add_theme_font_size_override("font_size", 16)
    enemy_title.add_theme_color_override("font_color", Color(1, 0.55, 0.22))
    layer.add_child(enemy_title)
    enemy_bar = ProgressBar.new()
    enemy_bar.position = Vector2(930, 57)
    enemy_bar.size = Vector2(320, 17)
    enemy_bar.max_value = 180
    enemy_bar.value = 180
    enemy_bar.show_percentage = false
    layer.add_child(enemy_bar)
    status_label = Label.new()
    status_label.position = Vector2(0, 280)
    status_label.size = Vector2(1280, 70)
    status_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    status_label.add_theme_font_size_override("font_size", 38)
    status_label.add_theme_color_override("font_color", Color(1, 0.55, 0.18))
    layer.add_child(status_label)
    hint_label = Label.new()
    hint_label.position = Vector2(0, 676)
    hint_label.size = Vector2(1280, 25)
    hint_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
    hint_label.add_theme_font_size_override("font_size", 14)
    hint_label.add_theme_color_override("font_color", Color(0.82, 0.86, 0.92))
    layer.add_child(hint_label)

func _on_player_attack() -> void:
    if ended or not is_instance_valid(enemy): return
    var distance := absf(player.global_position.x - enemy.global_position.x)
    var direction := signf(enemy.global_position.x - player.global_position.x)
    if distance < 205 and (direction == 0 or direction == player.facing):
        enemy.take_damage(24)

func _on_player_health(value: int) -> void:
    player_bar.value = value

func _on_enemy_health(value: int) -> void:
    enemy_bar.value = value

func _on_player_died() -> void:
    ended = true
    status_label.text = "MISSION FAILED  //  JACK DOWN"
    hint_label.text = "Tekan R untuk mencoba lagi"

func _on_enemy_defeated() -> void:
    ended = true
    won = true
    status_label.text = "TARGET ELIMINATED  //  SEKTOR AMAN"
    hint_label.text = "Jack berhasil mengamankan lengan cybernetic-nya. Tekan R untuk bermain lagi."

func _process(_delta: float) -> void:
    if is_instance_valid(player) and is_instance_valid(camera):
        camera.global_position.x = clampf(player.global_position.x, 640.0, 1560.0)
    if ended and Input.is_key_pressed(KEY_R):
        get_tree().reload_current_scene()
