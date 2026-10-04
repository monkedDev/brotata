extends Node2D

signal wave_changed(wave: int)

@export var enemy_scenes: Array[PackedScene] = []
@export var arena: Node2D
@export var edge_margin: float = 60.0

# Настройки волн
@export var start_count: int = 3
@export var count_per_wave: int = 2
@export var max_alive: int = 16
@export var wave_delay: float = 4.0
@export var spawn_delay: float = 0.2

var current_wave: int = 0
var alive_enemies: int = 0
var wave_in_progress: bool = false

func _ready() -> void:
	add_to_group("spawner")
	if enemy_scenes.is_empty():
		push_warning("EnemySpawner: не заданы enemy_scenes")
		return
	await get_tree().create_timer(1.0).timeout
	_start_next_wave()

func _start_next_wave() -> void:
	if wave_in_progress:
		return
	wave_in_progress = true
	current_wave += 1
	wave_changed.emit(current_wave)
	var to_spawn: int = start_count + (current_wave - 1) * count_per_wave
	to_spawn = min(to_spawn, max_alive)

	for i in range(to_spawn):
		if alive_enemies >= max_alive:
			break
		_spawn_one()
		if spawn_delay > 0:
			await get_tree().create_timer(spawn_delay).timeout

	wave_in_progress = false
	await get_tree().create_timer(wave_delay).timeout
	_start_next_wave()

func _spawn_one() -> void:
	if enemy_scenes.is_empty():
		return
	var rect: Rect2 = _get_arena_rect()
	var enemy: Node2D = enemy_scenes[randi() % enemy_scenes.size()].instantiate()
	add_child(enemy)
	enemy.global_position = _random_edge_position(rect)
	alive_enemies += 1
	enemy.tree_exited.connect(func(): alive_enemies -= 1)

func _get_arena_rect() -> Rect2:
	if arena and is_instance_valid(arena):
		if arena.has_method("get_arena_rect"):
			return arena.get_arena_rect()
	var size: Vector2 = get_viewport_rect().size
	return Rect2(Vector2.ZERO, size)

func _random_edge_position(rect: Rect2) -> Vector2:
	var m := edge_margin
	var side := randi() % 4
	match side:
		0:
			return Vector2(
				randf_range(rect.position.x + m, rect.position.x + rect.size.x - m),
				rect.position.y + m
			)
		1:
			return Vector2(
				randf_range(rect.position.x + m, rect.position.x + rect.size.x - m),
				rect.position.y + rect.size.y - m
			)
		2:
			return Vector2(
				rect.position.x + m,
				randf_range(rect.position.y + m, rect.position.y + rect.size.y - m)
			)
		_:
			return Vector2(
				rect.position.x + rect.size.x - m,
				randf_range(rect.position.y + m, rect.position.y + rect.size.y - m)
			)
