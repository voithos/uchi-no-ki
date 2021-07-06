extends Sprite

func _ready():
    pass

func _on_area_body_entered(body):
    var player = get_tree().get_nodes_in_group("player")[0]
    player.set_mana(player.MAX_MANA)
