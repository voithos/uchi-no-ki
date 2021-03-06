extends Sprite

var is_reached = false

func _ready():
    add_to_group("checkpoints")

func _on_area_body_entered(body: Node2D):
    if !is_reached:
        # We need some special logic when we're spawning at a checkpoint.
        var is_spawning = false
        if checkpoint_store.has_checkpoint() and checkpoint_store.get_checkpoint() == global_position:
            is_spawning = true
        
        checkpoint_store.set_checkpoint(global_position)
        $animation.play("reached")
        is_reached = true
        
        if !is_spawning:
            sfx.play(sfx.CHECKPOINT)
