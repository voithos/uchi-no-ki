extends Node

# Store for acquiring "scrolls" as part of gameplay. Each level can have multiple scrolls.

# Note, level names must be unique!
var level_scrolls = {}

func _ready():
    pass

func has_scroll(scroll_id) -> bool:
    print(scroll_id)
    return _get_level_scrolls().has(scroll_id)

func scroll_acquired(scroll_id):
    print(scroll_id)
    var scrolls = _get_level_scrolls()
    if !scrolls.has(scroll_id):
        scrolls.append(scroll_id)

func _level_name():
    return get_tree().get_current_scene().get_name()

func _get_level_scrolls():
    var level = _level_name()
    if !level_scrolls.has(level):
        level_scrolls[level] = []
    return level_scrolls[level]
