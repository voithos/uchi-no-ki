tool
extends Node2D

# A unique ID to identify the specific scroll instance.
export var scroll_id = ''

# This is a hack to be able to manually create a scroll ID.
export (bool) var create_id setget _create_id

func _create_id(value):
    var uuid = preload("res://scripts/uuid.gd")
    scroll_id = uuid.v4()

func _ready():
    if Engine.editor_hint:
        return
    assert(!scroll_id.empty())

    # Randomize a position in the idle "float" animation.
    $sprite/animation.seek(rand_range(0, $sprite/animation.current_animation_length))
    if scroll_store.has_scroll(scroll_id):
        queue_free()

func _on_area_body_entered(body):
    if Engine.editor_hint:
        return
    var player = get_tree().get_nodes_in_group("player")[0]
    scroll_store.scroll_acquired(scroll_id)
    $sprite/area.set_deferred("monitoring", false)
    
    sfx.play(sfx.SCROLL_ACQUIRE, sfx.EVEN_QUIETER_DB)
    # Slow down time while animating.
    time_warp.slowdown(0.01, 0.1)
    $sprite/animation.play("acquire")
    yield($sprite/animation, "animation_finished")
    time_warp.speedup()
    queue_free()
