extends CharacterBody2D

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
