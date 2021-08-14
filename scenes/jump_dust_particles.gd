extends Sprite

func _ready():
    pass

func play(direction):
    $animation.play(direction)

func _animation_end():
    queue_free()
