extends Node

# Music management.

const FADE_TIME = 10
const MIN_DB = -80.0
const DEFAULT_DB = 0.0

const MUSIC_DB = -10.0

class MusicBox extends Node:
    var player
    # We have two players to allow simultaneous playback into effects-based
    # audio buses.
    var alt_player
    var tween
    var last_playback_pos = 0
    
    func _init(stream):
        player = AudioStreamPlayer.new()
        alt_player = AudioStreamPlayer.new()
        add_child(player)
        add_child(alt_player)
        player.bus = "Music"
        alt_player.bus = "MusicAlt"
        player.stream = stream
        alt_player.stream = stream
        player.volume_db = MIN_DB
        alt_player.volume_db = MIN_DB
        
        tween = Tween.new()
        add_child(tween)
        self.tween.connect("tween_completed", self, "on_fade_complete")

    func set_volume_db(volume_db):
        player.volume_db = volume_db
        alt_player.volume_db = volume_db

    func fade_in():
        player.play(last_playback_pos)
        alt_player.play(last_playback_pos)
        last_playback_pos = 0
        tween.remove_all()
        tween.interpolate_method(self, "set_volume_db", player.volume_db, MUSIC_DB, \
                FADE_TIME, Tween.TRANS_EXPO, Tween.EASE_OUT)
        tween.start()

    func fade_out():
        tween.remove_all()
        tween.interpolate_method(self, "set_volume_db", player.volume_db, MIN_DB, \
                FADE_TIME, Tween.TRANS_EXPO, Tween.EASE_IN)
        tween.start()

    func is_active():
        return tween.is_active()

    func play():
        player.volume_db = MUSIC_DB
        alt_player.volume_db = MUSIC_DB
        player.play()
        alt_player.play()

    func on_fade_complete(_object, _key):
        if player.volume_db == MIN_DB:
            tween.remove_all()
            last_playback_pos = player.get_playback_position()
            player.stop()
            alt_player.stop()

# Add music here
# TODO: Replace with non-placeholder music?
var hero_immortal = preload("res://assets/music/hero_immortal.mp3")

var level_musicbox

# The last MusicBox that was active.
var last_musicbox = null

const MUSIC_LEVEL = "LEVEL"
var current_music = null

func _ready():
    _load_music()

func _load_music():
    level_musicbox = MusicBox.new(hero_immortal)
    add_child(level_musicbox)

func play_background():
    if current_music != MUSIC_LEVEL:
        level_musicbox.play()
        current_music = MUSIC_LEVEL
        last_musicbox = level_musicbox
