extends Resource
class_name NPCSpriteSet
## The NPCSpriteSet class references a pair of sprite sheets defining one NPC's
## appearance: its normal form and its possessed form.
##
## Sprite sets live in [code]res://resources/NPCSpriteSets[/code] and are
## consumed by [code]NPC.gd[/code]. Every NPC instance exposes an exported
## [code]spriteset[/code] property of this type.
##
## Drop a sprite set into that property to give an NPC a fixed skin. Leave it
## empty, and the NPC picks one at random from the folder on startup.

@export var normal_sheet: Texture2D
@export var possessed_sheet: Texture2D
