extends CharacterBody2D
signal attack_requested
signal health_changed(value)
signal player_died

const SPEED := 330.0
const JUMP_VELOCITY := -620.0
var gravity: float = 1500.0
var hp := 100
var facing := 1
var attack_cooldown := 0.0
var invulnerable := 0.0
var sprite: Sprite2D

func _ready() -> void:
    var tex := load("res://assets/jack_o_way_depan.png") as Texture2D
    sprite = Sprite2D.new()
    sprite.texture = tex
    sprite.scale = Vector2(0.52, 0.52)
    sprite.position = Vector2(0, -151)
    sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR
    add_child(sprite)
    var col := CollisionShape2D.new()
    var shape := CapsuleShape2D.new()
    shape.radius = 34
    shape.height = 174
    col.shape = shape
    col.position = Vector2(0, -91)
    add_child(col)

func _physics_process(delta: float) -> void:
    attack_cooldown = maxf(0.0, attack_cooldown - delta)
    invulnerable = maxf(0.0, invulnerable - delta)
    if not is_on_floor():
        velocity.y += gravity * delta
    else:
        if Input.is_key_pressed(KEY_SPACE) or Input.is_key_pressed(KEY_W) or Input.is_key_pressed(KEY_UP):
            velocity.y = JUMP_VELOCITY
    var dir := Input.get_axis("ui_left", "ui_right")
    if Input.is_key_pressed(KEY_A): dir -= 1.0
    if Input.is_key_pressed(KEY_D): dir += 1.0
    dir = clampf(dir, -1.0, 1.0)
    velocity.x = dir * SPEED
    if dir != 0:
        facing = int(sign(dir))
        sprite.flip_h = facing < 0
    if (Input.is_key_pressed(KEY_J) or Input.is_key_pressed(KEY_K)) and attack_cooldown <= 0.0:
        attack_cooldown = 0.48
        attack_requested.emit()
    if invulnerable > 0.0:
        sprite.modulate.a = 0.45 if int(Time.get_ticks_msec() / 90) % 2 == 0 else 1.0
    else:
        sprite.modulate.a = 1.0
    move_and_slide()
    global_position.x = clampf(global_position.x, 55.0, 2145.0)

func take_damage(amount: int) -> void:
    if invulnerable > 0.0 or hp <= 0: return
    hp = maxi(0, hp - amount)
    invulnerable = 0.75
    health_changed.emit(hp)
    if hp <= 0: player_died.emit()
