extends CanvasLayer

@onready var health_bar: ProgressBar = $HealthBar
@onready var health_label: Label = $HealthLabel
@onready var wave_label: Label = $WaveLabel
@onready var summon_label: Label = $SummonLabel

func _ready() -> void:
	# Красная полоска здоровья
	var fg_style := StyleBoxFlat.new()
	fg_style.bg_color = Color.RED
	fg_style.content_margin_left = 0
	fg_style.content_margin_right = 0
	fg_style.content_margin_top = 0
	fg_style.content_margin_bottom = 0
	health_bar.set("theme_override_styles/fg", fg_style)
	
	var bg_style := StyleBoxFlat.new()
	bg_style.bg_color = Color.DARK_GRAY
	bg_style.content_margin_left = 0
	bg_style.content_margin_right = 0
	bg_style.content_margin_top = 0
	bg_style.content_margin_bottom = 0
	health_bar.set("theme_override_styles/bg", bg_style)
	
	var player = get_tree().get_first_node_in_group("player")
	if player:
		player.health_changed.connect(_on_player_health_changed)
		health_bar.max_value = player.max_health
		health_bar.value = player.current_health
		health_label.text = "%d / %d" % [int(player.current_health), int(player.max_health)]

	var spawner = get_tree().get_first_node_in_group("spawner")
	if spawner and spawner.has_signal("wave_changed"):
		spawner.wave_changed.connect(_on_wave_changed)

func _process(_delta: float) -> void:
	var player = get_tree().get_first_node_in_group("player")
	if player and "lancer_timer" in player:
		if player.lancer_timer > 0:
			summon_label.text = "Призыв: %.1f сек" % player.lancer_timer
		else:
			summon_label.text = "Призыв готов [L]"

func _on_player_health_changed(new_health: float, max_health: float) -> void:
	health_bar.value = new_health
	health_label.text = "%d / %d" % [int(new_health), int(max_health)]

func _on_wave_changed(wave: int) -> void:
	wave_label.text = "Волна: %d" % wave
