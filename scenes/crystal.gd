extends Sprite

export var respawn_timeout = 3.0 # seconds

func _ready():
    pass

func _on_area_body_entered(body):
    var player = get_tree().get_nodes_in_group("player")[0]
    player.schedule_shade_dash()

    global_camera.shake(0.15, 30, 3)
    
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