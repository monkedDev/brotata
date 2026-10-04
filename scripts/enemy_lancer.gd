extends CharacterBody2D

@export var speed: float = 50.0
@export var max_health: float = 50.0
@export var damage: float = 12.0
@export var attack_range: float = 35.0
@export var attack_cooldown: float = 1.0
@export var separation_radius: float = 24.0
@export var separation_force: float = 30.0

@onready var sprite: AnimatedSprite2D = $AnimatedSprite2D

var current_health: float
var can_attack: bool = true
var is_attacking: bool = false
var health_bar: ProgressBar

func _ready() -> void:
	add_to_group("enemies")
	current_health = max_health
	sprite.play("idle")
	_create_health_bar()

func _create_health_bar() -> void:
	health_bar = ProgressBar.new()
	health_bar.min_value = 0
	health_bar.max_value = max_health
	health_bar.value = current_health
	health_bar.custom_minimum_size = Vector2(30, 1.33)
	health_bar.position = Vector2(-15, -35)
	health_bar.show_percentage = false
	health_bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
	
	var style := StyleBoxFlat.new()
	style.bg_color = Color.RED
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	health_bar.set("theme_override_styles/fg", style)
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color.DARK_GRAY
	bg_style.content_margin_left = 0
	bg_style.content_margin_right = 0
	bg_style.content_margin_top = 0
	bg_style.content_margin_bottom = 0
	health_bar.set("theme_override_styles/bg", bg_style)
	
	add_child(health_bar)

func _physics_process(_delta: float) -> void:
	if is_attacking:
		return

	var target = _find_nearest_target()
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
		try_attack(target)

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

func try_attack(target) -> void:
	if not can_attack or is_attacking:
		return
	is_attacking = true
	can_attack = false
	sprite.play("attack")

	await get_tree().create_timer(0.15).timeout
	if not is_instance_valid(self) or is_queued_for_deletion():
		return

	if is_instance_valid(target) and target.has_method("take_damage"):
		target.take_damage(damage)

	await get_tree().create_timer(max(0.0, attack_cooldown - 0.15)).timeout
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
	if health_bar:
		health_bar.value = current_health
	_flash_red()
	if current_health <= 0:
		queue_free()

func _flash_red() -> void:
	sprite.modulate = Color.RED
	await get_tree().create_timer(0.1).timeout
	if not is_instance_valid(self) or is_queued_for_deletion():
		return
	sprite.modulate = Color.WHITE
