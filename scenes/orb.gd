extends Sprite

export var respawn_timeout = 3.0 # seconds

func _ready():
    pass

func _on_area_body_entered(body):
    var player = get_tree().get_nodes_in_group("player")[0]
    player.set_mana(player.MAX_MANA)
    global_camera.shake(0.15, 30, 2.5)
    sfx.play(sfx.ORB_SHATTER, sfx.EVEN_QUIETER_DB)
    
    $animation.play("break")
    $area.set_deferred("monitoring", false)

    $timer.wait_time = respawn_timeout
    $timer.one_shot = true
    $timer.start()
    yield($timer, "timeout")
    
    $animation.play("spawn")
    yield($animation, "animation_finished")
    $animation.play("idle")
    $area.set_deferred("monitoring", true)
