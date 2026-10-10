@tool
extends Control

var petals: Array = []
var tex: Texture2D

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	# top_level = true để không bị layout của container cha can thiệp kích thước/vị trí
	top_level = true
	z_index = 1000
	tex = load("res://addons/sakura_inspector/sakura_petal.png")
	_init_petals()

func _init_petals() -> void:
	petals.clear()
	var w = max(size.x, 300.0)
	var h = max(size.y, 600.0)
	for i in range(40):
		petals.append({
			"pos": Vector2(randf_range(0, w), randf_range(0, h)),
			"speed": randf_range(40.0, 90.0),
			"drift": randf_range(15.0, 35.0),
			"angle": randf_range(0, TAU),
			"rot_speed": randf_range(-1.5, 1.5),
			"scale": randf_range(0.5, 0.9),
			"alpha": randf_range(0.7, 0.95),
			"sway_offset": randf_range(0, 10.0)
		})

func _process(delta: float) -> void:
	var inspector = EditorInterface.get_inspector()
	if not inspector or not inspector.is_visible_in_tree():
		visible = false
		return

	# Đồng bộ vị trí và kích thước toàn cục theo Inspector
	visible = true
	global_position = inspector.global_position
	size = inspector.size

	var w = size.x
	var h = size.y
	if w <= 10.0 or h <= 10.0:
		return

	if petals.is_empty():
		_init_petals()

	var time = Time.get_ticks_msec() / 1000.0
	for p in petals:
		var sway = sin(time * 2.0 + p["sway_offset"]) * 20.0
		p["pos"].y += p["speed"] * delta
		p["pos"].x += (p["drift"] + sway) * delta
		p["angle"] += p["rot_speed"] * delta

		if p["pos"].y > h + 20:
			p["pos"].y = -20
			p["pos"].x = randf_range(-20, w)
		if p["pos"].x > w + 20:
			p["pos"].x = -20
		elif p["pos"].x < -30:
			p["pos"].x = w + 10

	queue_redraw()

func _draw() -> void:
	if not tex or size.x <= 10.0:
		return
	var tex_size = tex.get_size()
	var center_offset = -tex_size * 0.5

	for p in petals:
		draw_set_transform(p["pos"], p["angle"], Vector2(p["scale"], p["scale"]))
		draw_texture(tex, center_offset, Color(1, 1, 1, p["alpha"]))
