extends Node2D

##################################################
const SCREEN_SIZE: Vector2 = Vector2(1920.0, 1080.0)
const FISH_SCENE: PackedScene = preload("res://scenes/fish/fish.tscn")

##################################################
func _ready() -> void:
	for i in range(200):
		var fish_instance = FISH_SCENE.instantiate()
		fish_instance.position = \
			Vector2(randf_range(64.0, SCREEN_SIZE.x - 64.0), \
			randf_range(64.0, SCREEN_SIZE.y - 64.0))
		add_child(fish_instance)
