extends Sprite

func _ready():
    add_to_group("goal")

func _on_area_body_entered(body: Node2D):
    # TODO: Only have this work for the main body
    var level = get_tree().get_nodes_in_group("level")[0]
    level.begin_next_level_transition()
    
    global_camera.shake(0.75, 30, 1)
