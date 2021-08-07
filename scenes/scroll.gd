extends Sprite

func _ready():
    # Randomize a position in the idle "float" animation.
    $animation.seek(rand_range(0, $animation.current_animation_length))

func _on_area_body_entered(body):
    var player = get_tree().get_nodes_in_group("player")[0]
    # TODO: Increment the scroll count

    $area.set_deferred("monitoring", false)
