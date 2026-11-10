extends CharacterBody2D
signal health_changed(value)
signal defeated
var hp := 180
var gravity := 1500.0
var attack_timer := 0.0
var hit_flash := 0.0
var player: Node2D
var sprite: Sprite2D
var active := true

func _ready() -> void:
    sprite = Sprite2D.new()
    sprite.texture = load("res://assets/monoseeds_transparent-removebg-preview.png")
    sprite.scale = Vector2(0.43, 0.43)
    sprite.position = Vector2(0, -92)
    add_child(sprite)
    var col := CollisionShape2D.new()
    var shape := CapsuleShape2D.new()
    shape.radius = 48
    shape.height = 150
    col.shape = shape
    col.position = Vector2(0, -77)
    add_child(col)

func _physics_process(delta: float) -> void:
    if not active: return
    if not is_on_floor(): velocity.y += gravity * delta
    attack_timer = maxf(0.0, attack_timer - delta)
    hit_flash = maxf(0.0, hit_flash - delta)
    if player and is_instance_valid(player):
        var dx := player.global_position.x - global_position.x
        if absf(dx) > 112:
            velocity.x = signf(dx) * 105.0
        else:
            velocity.x = 0.0
            if attack_timer <= 0.0:
                attack_timer = 1.65
                if player.has_method("take_damage"):
                    player.take_damage(13)
        sprite.flip_h = dx < 0
    if hit_flash > 0: sprite.modulate = Color(1.8, 0.5, 0.35)
    else: sprite.modulate = Color.WHITE
    move_and_slide()

func take_damage(amount: int) -> void:
    if not active: return
    hp = maxi(0, hp - amount)
    hit_flash = 0.13
    health_changed.emit(hp)
    if hp <= 0:
        active = false
        velocity = Vector2.ZERO
        defeated.emit()
        queue_free()
