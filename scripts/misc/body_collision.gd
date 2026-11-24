class_name BodyCollision
extends Area2D

@export var push_force: float = 120.0

func get_push_vector() -> Vector2:
    var push_vector: Vector2 = Vector2.ZERO
    var overlapping_areas = get_overlapping_areas()

    for area in overlapping_areas:
        # Check correct group (as a precaution) and do not push itself
        if area != self and area.is_in_group("body_collision"):
            var diff = global_position - area.global_position
            var distance = diff.length()

            if distance > 0:
                # Push direction: push away from the center of the other area
                # Closer distance results in a stronger push force
                var direction = diff.normalized()
                # If uniform push force is desired: push_vector += direction * push_force
                # If stronger push force is desired the more they overlap:
                push_vector += direction * (push_force / max(distance, 1.0))
            else:
                # If both centers overlap completely (0 distance), push in a random direction to separate them
                push_vector += Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized() * push_force

    return push_vector
