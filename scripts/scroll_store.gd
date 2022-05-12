extends Node

# Store for acquiring "scrolls" as part of gameplay. Each level can have multiple scrolls.

# Note, level names must be unique!
var level_scrolls = {}
# Saved, to differentiate between "ever acquired" vs new-games.
var saved_level_scrolls = {}

func _ready():
    add_to_group("persistable")

func has_scroll(scroll_id) -> bool:
    return _get_level_scrolls().has(scroll_id)

func scroll_acquired(scroll_id):
    var scrolls = _get_level_scrolls()
    if !scrolls.has(scroll_id):
        scrolls.append(scroll_id)
        # Persist the data.
        saving.save_game()

func _level_name():
    return get_tree().get_current_scene().get_name()

func _get_level_scrolls():
    var level = _level_name()
    if !level_scrolls.has(level):
        level_scrolls[level] = []
    return level_scrolls[level]

func save_state():
    # Persist new scroll_ids into saved level scrolls.
    for level in level_scrolls.keys():
        for scroll_id in level_scrolls[level]:
            if !saved_level_scrolls.has(level):
                saved_level_scrolls[level] = []
            if !saved_level_scrolls[level].has(scroll_id):
                saved_level_scrolls[level].append(scroll_id)

    return level_scrolls

func load_state(save_data):
    # Only load into saved_level_scrolls, so that players can still start new games and find scrolls.
    saved_level_scrolls = save_data
