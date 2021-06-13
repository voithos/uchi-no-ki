extends Sprite

var is_reached = false

func _ready():
    add_to_group("checkpoints")

func _on_area_body_entered(body: Node2D):
    if !is_reached:
        checkpoint_store.set_checkpoint(global_position)
        $animation.play("reached")
        is_reached = true
