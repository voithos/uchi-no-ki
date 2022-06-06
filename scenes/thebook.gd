extends Node2D

const CAMERA_ZOOM = 0.4
const CAMERA_ZOOM_LERP = 0.02

func _ready():
    # Randomize a position in the idle "float" animation.
    $sprite/animation.seek(rand_range(0, $sprite/animation.current_animation_length))

func _on_area_body_entered(body):
    var player = get_tree().get_nodes_in_group("player")[0]
    # Abuse the scroll acquire. :P
    player.on_scroll_acquire_start()
    $sprite/area.set_deferred("monitoring", false)
    
    # Slow down time while animating.
    time_warp.slowdown(0.01, 0.05)
    $sprite/animation.play("acquire")
    
    # Animate out the camera zoom.
    while abs(player.camera.zoom.x - CAMERA_ZOOM) > 0.01:
        player.camera.zoom.x = lerp(player.camera.zoom.x, CAMERA_ZOOM, CAMERA_ZOOM_LERP)
        player.camera.zoom.y = lerp(player.camera.zoom.y, CAMERA_ZOOM, CAMERA_ZOOM_LERP)
        yield(get_tree(), "idle_frame")
    
    var level = get_tree().get_nodes_in_group("level")[0]
    level.begin_next_level_transition()

func _play_scroll_acquire():
    sfx.play(sfx.SCROLL_ACQUIRE, sfx.EVEN_QUIETER_DB)

