extends Node

# Store for acquiring "scrolls" as part of gameplay. Each level can have multiple scrolls.

# Note, level names must be unique!
var level_scrolls = {}

func _ready():
    add_to_group("persistable")

func has_scroll(scroll_id) -> bool:
    return _get_level_scrolls().has(scroll_id)

func scroll_acquired(scroll_id):
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

func save_state():
    return level_scrolls

func load_state(save_data):
    level_scrolls = save_data
