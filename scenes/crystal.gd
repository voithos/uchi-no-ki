extends Sprite

export var respawn_timeout = 3.0 # seconds

func _ready():
    # Randomize a position in the idle "float" animation.
    $animation.seek(rand_range(0, $animation.current_animation_length))

func _on_area_body_entered(body):
    var player = get_tree().get_nodes_in_group("player")[0]
    player.schedule_shade_dash()
    
    global_camera.shake(0.1, 30, 2)
    # Sfx doesn't sound good here since the dash already has sfx.
    #sfx.play(sfx.ORB_SHATTER, sfx.EVEN_QUIETER_DB)
    
    $animation.play("break")
    $area.set_deferred("monitoring", false)

    $warp_timer.timeout = respawn_timeout
    $warp_timer.start()
    yield($warp_timer, "timeout")
    
    $animation.play("spawn")
    yield($animation, "animation_finished")
    $animation.play("idle")
    $area.set_deferred("monitoring", true)
