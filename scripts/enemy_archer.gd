extends CharacterBody2D

@export var speed: float = 35.0
@export var max_health: float = 40.0
@export var damage: float = 10.0
@export var attack_range: float = 150.0
@export var attack_cooldown: float = 2.5
@export var arrow_scene: PackedScene
@export var separation_radius: float = 28.0
@export var separation_force: float = 40.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_health: float
var target: Node2D
var can_attack: bool = true
var is_attacking: bool = false

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	sprite.play("idle")
	target = _find_nearest_target()

func _physics_process(_delta: float) -> void:
	if is_attacking:
		return

	# Каждый кадр ищем ближайшую цель
	target = _find_nearest_target()
	if not target:
		velocity = Vector2.ZERO
		sprite.play("idle")
		move_and_slide()
		return

	var to_target: Vector2 = target.global_position - global_position
	var distance: float = to_target.length()

	if distance > attack_range:
		var dir := to_target.normalized()
		velocity = dir * speed + _separation()
		sprite.play("walk")
		sprite.flip_h = dir.x < 0
	else:
		velocity = Vector2.ZERO
		try_attack()

	move_and_slide()

func _find_nearest_target():
	var nearest = null
	var min_dist := INF
	for group_name in ["player", "allies"]:
		for node in get_tree().get_nodes_in_group(group_name):
			if not is_instance_valid(node):
				continue
			var dist := global_position.distance_to(node.global_position)
			if dist < min_dist:
				min_dist = dist
				nearest = node
	return nearest

func _separation() -> Vector2:
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

	await get_tree().create_timer(0.3).timeout
	if not is_instance_valid(self) or is_queued_for_deletion():
		return

	_shoot_arrow()

	await get_tree().create_timer(attack_cooldown - 0.3).timeout
	if not is_instance_valid(self) or is_queued_for_deletion():
		return
	is_attacking = false
	can_attack = true

	if velocity.length() > 0.01:
		sprite.play("walk")
	else:
		sprite.play("idle")

func _shoot_arrow() -> void:
	if not arrow_scene:
		return
	if not is_instance_valid(target):
		return
	var arrow := arrow_scene.instantiate()
	get_tree().current_scene.add_child(arrow)
	arrow.global_position = global_position
	var dir: Vector2 = (target.global_position - global_position).normalized()
	arrow.setup(dir, damage)

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
