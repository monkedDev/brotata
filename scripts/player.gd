extends CharacterBody2D

@export var speed: float = 150.0
@export var max_health: float = 100.0
@export var attack_range: float = 60.0
@export var attack_damage: float = 25.0
@export var attack_cooldown: float = 0.5
@export var guard_damage_reduction: float = 0.5

signal health_changed(new_health: float, max_health: float)
signal died

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_health: float
var can_attack: bool = true
var is_attacking: bool = false
var is_guarding: bool = false

func _ready() -> void:
	add_to_group("player")
	current_health = max_health
	health_changed.emit(current_health, max_health)
	sprite.play("idle")

func _physics_process(_delta: float) -> void:
	if is_attacking:
		return

	var input_dir := Vector2(
		Input.get_axis("move_left", "move_right"),
		Input.get_axis("move_up", "move_down")
	)

	if Input.is_mouse_button_pressed(MOUSE_BUTTON_RIGHT):
		is_guarding = true
		sprite.play("guard")
		velocity = Vector2.ZERO
	else:
		is_guarding = false
		if input_dir != Vector2.ZERO:
			input_dir = input_dir.normalized()
			sprite.play("walk")
			if input_dir.x < 0:
				sprite.flip_h = true
			elif input_dir.x > 0:
				sprite.flip_h = false
		else:
			sprite.play("idle")
		velocity = input_dir * speed

	move_and_slide()

	if Input.is_action_just_pressed("attack"):
		melee_attack()
	if Input.is_action_just_pressed("special_attack"):
		special_attack()

func melee_attack() -> void:
	if not can_attack or is_guarding:
		return
	is_attacking = true
	can_attack = false
	sprite.play("attack")

	await get_tree().create_timer(0.1).timeout
	if not is_instance_valid(self):
		return
	damage_enemies_in_range()

	await get_tree().create_timer(0.4).timeout
	if not is_instance_valid(self):
		return
	is_attacking = false

	await get_tree().create_timer(max(0.0, attack_cooldown - 0.4)).timeout
	if not is_instance_valid(self):
		return
	can_attack = true
	_update_idle_anim()

func special_attack() -> void:
	if not can_attack or is_guarding:
		return
	is_attacking = true
	can_attack = false
	sprite.play("special attack")

	await get_tree().create_timer(0.2).timeout
	if not is_instance_valid(self):
		return
	damage_enemies_in_range_special()

	await get_tree().create_timer(0.6).timeout
	if not is_instance_valid(self):
		return
	is_attacking = false

	await get_tree().create_timer(1.0).timeout
	if not is_instance_valid(self):
		return
	can_attack = true
	_update_idle_anim()

func damage_enemies_in_range() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= attack_range:
			if enemy.has_method("take_damage"):
				enemy.take_damage(attack_damage)

func damage_enemies_in_range_special() -> void:
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		if global_position.distance_to(enemy.global_position) <= attack_range * 1.5:
			if enemy.has_method("take_damage"):
				enemy.take_damage(attack_damage * 2.0)

func get_nearest_enemy_in_range():
	var nearest = null
	var min_distance := attack_range
	for enemy in get_tree().get_nodes_in_group("enemies"):
		if not is_instance_valid(enemy):
			continue
		var dist := global_position.distance_to(enemy.global_position)
		if dist < min_distance:
			min_distance = dist
			nearest = enemy
	return nearest

func take_damage(amount: float) -> void:
	if is_guarding:
		amount *= guard_damage_reduction
	current_health -= amount
	health_changed.emit(current_health, max_health)
	if current_health <= 0:
		_die()

func _die() -> void:
	died.emit()
	queue_free()

func _update_idle_anim() -> void:
	if velocity.length() < 0.01:
		sprite.play("idle")
	else:
		sprite.play("walk")
