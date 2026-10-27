class_name NPC
extends CharacterBody2D

## The [NPCSpriteSet] defining this NPC's appearance.
##
## Drag a Spriteset from [code]res://resources/NPCSpriteSets[/code] into the
## Spriteset property in the Inspector to give this NPC a specific skin.
## Or leave it blank to allow the scence to select a random skin on _ready().
@export var spriteset: NPCSpriteSet
@onready var sprite: Sprite2D = $Sprite2D
@onready var animation: AnimationPlayer = $AnimationPlayer

enum State { NORMAL, BEING_POSSESSED, POSSESSED }
var current_state: State = State.NORMAL
var possessed_by: Node2D

const SPEED = 300.0

func _ready() -> void:
	if spriteset == null:
		var spritesetfolder : String = "res://resources/NPCSpriteSets/"
		var dir = DirAccess.open(spritesetfolder)
		var npcspritesetnames : Array[String] = []
		dir.list_dir_begin()
		var f = dir.get_next()
		while f != "":
			if f.ends_with(".tres"):
				npcspritesetnames.append(f)
			f = dir.get_next()
		dir.list_dir_end()
		spriteset= load(spritesetfolder + npcspritesetnames.pick_random())
	$Sprite2D.texture = spriteset.normal_sheet
	$AnimationPlayer.play("dance")
	GameManager.instance.register_as_ghost_target(self) # Register as a ghost target so it can be picked by the ghost

## Starts the possession process for this NPC, making it switch to the "being possessed" state and play the corresponding animation. 
## The possession lasts for the specified duration, during which the NPC's sprite alternates between its normal and possessed appearances.
## The speed of the sprite switching accelerates over time, and a shaking effect is applied towards the end of the possession duration.
## TODO: Handle the case where the player sprays holy water on the ghost while it is possessing this NPC.
func start_possession(duration: float, possessed_by: Node2D) -> void:
	if current_state == State.NORMAL:
		current_state = State.BEING_POSSESSED
		self.possessed_by = possessed_by
	else:
		return
	animation.play("being_possessed")

	var is_showing_possessed: bool = false
	var elapsed: float = 0.0

	var initial_interval: float = 0.28  # Initial interval (slow)
	var final_interval: float = 0.03    # Final interval (very fast)

	var original_offset: Vector2 = sprite.offset

	while elapsed < duration:
		# Toggle between normal and possessed sprites
		is_showing_possessed = !is_showing_possessed
		sprite.texture = spriteset.possessed_sheet if is_showing_possessed else spriteset.normal_sheet

		var progress: float = clamp(elapsed / duration, 0.0, 1.0)

		# Quad In easing (progress^2) to accelerate towards the end
		# If you want to see some visualization, check this out: https://easings.net/#easeInQuad
		var eased_progress: float = progress * progress
		var current_interval: float = lerp(initial_interval, final_interval, eased_progress)

		# Some shaking effect towards the end of the possession duration
		if progress > 0.6:
			var shake_strength: float = lerp(0.0, 2.5, (progress - 0.6) / 0.4)
			sprite.offset = original_offset + Vector2(
				randf_range(-shake_strength, shake_strength),
				randf_range(-shake_strength, shake_strength)
			)

		await get_tree().create_timer(current_interval).timeout
		elapsed += current_interval

	sprite.texture = spriteset.possessed_sheet
	if current_state == State.BEING_POSSESSED:
		current_state = State.POSSESSED
