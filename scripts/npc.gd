extends CharacterBody2D

## The [NPCSpriteSet] defining this NPC's appearance.
##
## Drag a Spriteset from [code]res://resources/NPCSpriteSets[/code] into the
## Spriteset property in the Inspector to give this NPC a specific skin.
## Or leave it blank to allow the scence to select a random skin on _ready().
@export var spriteset: NPCSpriteSet

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
