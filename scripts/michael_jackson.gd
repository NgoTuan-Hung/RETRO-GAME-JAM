extends CharacterBody2D

@onready var anime = $AnimationPlayer

func _process(delta: float) -> void:
	anime.play("moon_walk")
