extends Node2D

@export var enemy_scene: PackedScene
@export var enemy_count: int = 10
@export var arena: Node2D                       # перетащи сюда ноду арены в инспекторе
@export var edge_margin: float = 60.0           # отступ от края внутрь арены

func _ready() -> void:
	if not enemy_scene:
		push_warning("EnemySpawner: не задан enemy_scene")
		return
	if not arena:
		push_warning("EnemySpawner: не задана нода arena")
		return

	var rect: Rect2 = arena.get_arena_rect()
	for i in range(enemy_count):
		var enemy := enemy_scene.instantiate()
		add_child(enemy)  # сначала в дерево, потом задаём global_position
		enemy.global_position = _random_edge_position(rect)

func _random_edge_position(rect: Rect2) -> Vector2:
	var m := edge_margin
	var side := randi() % 4
	match side:
		0:  # верх
			return Vector2(
				randf_range(rect.position.x + m, rect.position.x + rect.size.x - m),
				rect.position.y + m
			)
		1:  # низ
			return Vector2(
				randf_range(rect.position.x + m, rect.position.x + rect.size.x - m),
				rect.position.y + rect.size.y - m
			)
		2:  # лево
			return Vector2(
				rect.position.x + m,
				randf_range(rect.position.y + m, rect.position.y + rect.size.y - m)
			)
		_:  # право
			return Vector2(
				rect.position.x + rect.size.x - m,
				randf_range(rect.position.y + m, rect.position.y + rect.size.y - m)
			)
