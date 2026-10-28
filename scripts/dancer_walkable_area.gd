class_name DancerWalkableArea
extends ReferenceRect

func get_random_point() -> Vector2:
    var rand_x = randf_range(global_position.x, global_position.x + size.x)
    var rand_y = randf_range(global_position.y, global_position.y + size.y)
    return Vector2(rand_x, rand_y)