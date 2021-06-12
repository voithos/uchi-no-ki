extends Sprite

func _ready():
    add_to_group("goal")
    $animation.play("idle")

func _on_area_body_entered(body: Node2D):
    body.win()
