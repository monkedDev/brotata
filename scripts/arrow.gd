extends Area2D

var direction: Vector2
var damage: float = 0.0
var speed: float = 150.0

@onready var sprite: Sprite2D = $Sprite2D

func setup(dir: Vector2, dmg: float) -> void:
	direction = dir.normalized()
	damage = dmg
	rotation = direction.angle()

func _physics_process(delta: float) -> void:
	position += direction * speed * delta

func _on_body_entered(body: Node2D) -> void:
	# Игнорируем врагов — стрелы бьют только игрока и лансеров
	if body.is_in_group("enemies"):
		return
	if body.has_method("take_damage"):
		body.take_damage(damage)
	queue_free()
