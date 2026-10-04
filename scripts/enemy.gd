extends CharacterBody2D

@export var speed: float = 60.0
@export var max_health: float = 100.0
@export var damage: float = 15.0
@export var attack_range: float = 50.0
@export var attack_cooldown: float = 1.0
@export var separation_radius: float = 28.0
@export var separation_force: float = 40.0

@onready var sprite: AnimatedSprite2D = $Sprite  # проверь, что нода врага реально называется Sprite

var current_health: float
var player: CharacterBody2D
var can_attack: bool = true
var is_attacking: bool = false

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	sprite.play("idle")
	player = get_tree().get_first_node_in_group("player")

func _physics_process(_delta: float) -> void:
	if not is_instance_valid(player):
		player = get_tree().get_first_node_in_group("player")
		return

	var to_player := player.global_position - global_position
	var distance := to_player.length()

	if distance > attack_range:
		var dir := to_player.normalized()
		velocity = dir * speed + _separation()
		sprite.play("walk")
		sprite.flip_h = dir.x < 0
	else:
		velocity = Vector2.ZERO
		try_attack()

	move_and_slide()

func _separation() -> Vector2:
	# Расталкивание, чтобы враги не слипались в одну точку
	var push := Vector2.ZERO
	for other in get_tree().get_nodes_in_group("enemies"):
		if other == self or not is_instance_valid(other):
			continue
		var diff: Vector2 = global_position - other.global_position
		var d := diff.length()
		if d > 0.01 and d < separation_radius:
			push += diff.normalized() * (1.0 - d / separation_radius)
	return push * separation_force

func try_attack() -> void:
	if not can_attack or is_attacking:
		return
	is_attacking = true
	can_attack = false
	sprite.play("attack")

	if is_instance_valid(player) and player.has_method("take_damage"):
		player.take_damage(damage)

	await get_tree().create_timer(attack_cooldown).timeout
	if not is_instance_valid(self) or is_queued_for_deletion():
		return
	is_attacking = false
	can_attack = true

	if velocity.length() > 0.01:
		sprite.play("walk")
	else:
		sprite.play("idle")

func take_damage(amount: float) -> void:
	current_health -= amount
	_flash_red()
	if current_health <= 0:
		queue_free()

func _flash_red() -> void:
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if not is_instance_valid(self) or is_queued_for_deletion():
		return
	sprite.modulate = Color.WHITE
