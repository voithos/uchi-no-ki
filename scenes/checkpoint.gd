extends Sprite

var is_reached = false

func _ready():
    add_to_group("checkpoints")

func _on_area_body_entered(body: Node2D):
    # TODO: This is also triggered when a level loads into a checkpoint.
    # The animation is OK but probably shouldn't play any sounds or anything.
    if !is_reached:
        checkpoint_store.set_checkpoint(global_position)
        $animation.play("reached")
        is_reached = true
