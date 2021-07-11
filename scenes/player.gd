extends KinematicBody2D
class_name Player

var velocity = Vector2.ZERO
var shade_velocity = Vector2.ZERO

const HORIZONTAL_VEL = 75.0
const HORIZONTAL_ACCEL = 20 # How quickly we accelerate to max speed

const SHADE_HORIZONTAL_VEL = 100.0
const SHADE_HORIZONTAL_ACCEL = 6
const SHADE_VERTICAL_VEL = 70.0
const SHADE_VERTICAL_ACCEL = 6

const SHADE_INITIAL_VEL = 1.5 # Percent of char's velocity

const GRAVITY = 6.0
const JUMP_VEL = 160
const TERM_VEL = JUMP_VEL * 2
const FAST_FALL_MULTIPLIER = 1.7 # How much faster fast fall is compared to gravity

const JUMP_RELEASE_MULTIPLIER = 0.5 # Multiplied by velocity if button released

const MAX_MANA = 100.0
var mana = MAX_MANA
const MANA_DEPLETION = 70 # Rate of depletion
const MANA_GAIN = 140 # Rate of gain when not in shade
signal mana_changed

var facing_left = true
var is_moving = false
var is_shade_moving = false
var is_airborne = false
var was_airborne = false
var is_fast_falling = false

var is_shade_out = false
var shade_button_held_duration = 0.0
var is_shade_button_held = true
# The threshold after which we treat the button as a "press and hold" instead of a "tap once".
# TODO: Instead of this, just make the player hold the button down.
const SHADE_BUTTON_HELD_THRESHOLD = 0.4

const SHADE_RETURN_TIME = 0.3

var is_controllable = true

# Shade dashing
var is_dashing = false
const DASH_DURATION = 0.15 # seconds
const DASH_VEL = 200
var dash_timer = 0.0
var dash_direction = Vector2.ZERO
var is_about_to_dash = false
var dash_start_timer = 0.0
const DASH_START_DELAY = 0.1 # seconds

const WALK_SFX_COOLDOWN = 0.3 # seconds
var walk_sfx_cooldown = 0

onready var camera = $shade/player_camera

func _ready():
    add_to_group("player")
    time_warp.set_camera(camera)
    
    $shade.hide()
    $shade.position = Vector2.ZERO
    $shade/shape.disabled = true
    $shade/aftereffect.emitting = false
    $shade/aftereffect.lifetime = DASH_DURATION + 0.15
    
    _maybe_jump_to_checkpoint()
    
    # Initial animation.
    is_controllable = false
    $animation.play("teleport")
    $animation.seek(0, true)
    $animation.stop()

    # Wait a little bit extra to allow the transition to complete fading in
    yield(get_tree().create_timer(0.2), "timeout")
    
    $animation.play("teleport")
    sfx.play(sfx.TELEPORT)
    yield($animation, "animation_finished")
    is_controllable = true
    $animation.play("idle")

func _maybe_jump_to_checkpoint():
    if checkpoint_store.has_checkpoint():
        global_position = checkpoint_store.get_checkpoint()

func _physics_process(delta):
    # Need to update mana even when uncontrolled in order to update the UI.
    _update_mana(delta)
    _animate_shade_dash(delta)

    if !is_controllable:
        return

    if Input.is_action_just_pressed("ki_burst"):
        _toggle_shade()
    if Input.is_action_just_released("ki_burst"):
        if shade_button_held_duration >= SHADE_BUTTON_HELD_THRESHOLD:
            # Button was held; treat as a release
            _toggle_shade()
        else:
            is_shade_button_held = false

    if is_shade_out:
        _move_shade(delta)
        if is_shade_button_held:
            shade_button_held_duration += delta
        else:
            shade_button_held_duration = 0

    _move_player(delta)
    
    _update_sprite_flip()
    _walk_sfx(delta)

func _toggle_shade():
    # Can't toggle shade if dashing.
    if is_dashing or is_about_to_dash:
        return
        
    if is_shade_out:
        _hide_shade()
    else:
        _show_shade()

func _hide_shade():
    time_warp.speedup()
    
    is_controllable = false
    is_shade_out = false
    $shade/shape.disabled = true
    
    sfx.play(sfx.SHADE_RETURN, sfx.QUIET_DB)
    $shade/particles.speed_scale = 3.0
    $shade_tween.interpolate_property($shade, "position", $shade.position, Vector2(0, 0),
           SHADE_RETURN_TIME, Tween.TRANS_CUBIC, Tween.EASE_IN)
    $shade_tween.start()
    yield($shade_tween, "tween_completed")
    $shade/particles.speed_scale = 1.0

    is_controllable = true
    $shade.hide()
    $shade.position = Vector2.ZERO
    shade_velocity = Vector2.ZERO
    
    shade_button_held_duration = 0.0
    is_shade_button_held = true

func _show_shade():
    time_warp.slowdown()
    
    is_shade_out = true
    is_about_to_dash = false

    $shade.show()
    $shade.position = Vector2.ZERO
    shade_velocity = velocity * SHADE_INITIAL_VEL
    $shade/shape.disabled = false
    $shade/particles.restart()
    sfx.play(sfx.SHADE, sfx.QUIET_DB)
    
    shade_button_held_duration = 0.0
    is_shade_button_held = true

func schedule_shade_dash():
    is_about_to_dash = true
    dash_start_timer = 0.0

func shade_dash(dir: Vector2):
    is_about_to_dash = false
    is_controllable = false
    is_dashing = true
    dash_timer = 0.0
    dash_direction = dir.normalized()

    global_camera.shake(DASH_DURATION * 0.6, 30, 2)
    sfx.play(sfx.SHADE_DASH, sfx.SFX_DB)
    
    if facing_left:
        $shade/aftereffect.texture = preload("res://assets/player/shade_afterimage.png")
    else:
        $shade/aftereffect.texture = preload("res://assets/player/shade_afterimage_flipped.png")
    $shade/aftereffect.restart()

func _animate_shade_dash(delta):
    if !is_dashing:
        return
    shade_velocity = dash_direction * DASH_VEL
    shade_velocity = $shade.move_and_slide(shade_velocity, Vector2.UP)
    
    dash_timer += delta
    if dash_timer >= DASH_DURATION:
        is_controllable = true
        is_dashing = false
    
func _move_player(delta):
    was_airborne = is_airborne
    
    var target_horizontal = 0
    var fall_multiplier = 1.0
    is_moving = false

    if !is_shade_out:
        if Input.is_action_pressed("move_left"):
            target_horizontal -= HORIZONTAL_VEL
            is_moving = true
        if Input.is_action_pressed("move_right"):
            target_horizontal += HORIZONTAL_VEL
            is_moving = true

        if Input.is_action_just_pressed("move_up") and is_on_floor():
            _jump()
        
        if target_horizontal != 0:
            facing_left = target_horizontal < 0

        # Apply gravity and fast falling
        # TODO: Have the shade trigger fast falling upon return?
        if is_airborne and Input.is_action_just_released("move_up"):
            is_fast_falling = true
            if velocity.y < 0:
                velocity.y *= JUMP_RELEASE_MULTIPLIER

        if is_fast_falling:
            fall_multiplier = FAST_FALL_MULTIPLIER

    velocity.y = min(TERM_VEL, velocity.y + GRAVITY * fall_multiplier * time_warp.time_scale)

    # Lerp horizontal movement
    velocity.x = lerp(velocity.x, target_horizontal, HORIZONTAL_ACCEL * delta * time_warp.time_scale)

    # Handle shade being out and time scaling
    var shade_pos = $shade.global_position
    var time_scaled_velocity = velocity * time_warp.time_scale
    time_scaled_velocity = move_and_slide(time_scaled_velocity, Vector2.UP)
    velocity = time_scaled_velocity / time_warp.time_scale
    
    if was_airborne and is_on_floor():
        # Landed.
        is_airborne = false
    if !is_airborne:
        if is_moving:
            $animation.play("run")
        else:
            $animation.play("idle")

    if is_shade_out:
        $shade.global_position = shade_pos

func _move_shade(delta):
    var target_horizontal = 0
    var target_vertical = 0
    is_shade_moving = false
    if Input.is_action_pressed("move_left"):
        target_horizontal -= SHADE_HORIZONTAL_VEL
        is_shade_moving = true
    if Input.is_action_pressed("move_right"):
        target_horizontal += SHADE_HORIZONTAL_VEL
        is_shade_moving = true

    if Input.is_action_pressed("move_up"):
        target_vertical -= SHADE_VERTICAL_VEL
    if Input.is_action_pressed("move_down"):
        target_vertical += SHADE_VERTICAL_VEL
    
    if target_horizontal != 0:
        facing_left = target_horizontal < 0

    if is_about_to_dash:
        # About to dash, so don't apply the target vel.
        dash_start_timer += delta
        if dash_start_timer >= DASH_START_DELAY:
            # Use the shade's velocity by default, unless the player is holding
            # down directions, in which case they take priority.
            var dash_input = shade_velocity
            if target_horizontal != 0 or target_vertical != 0:
                dash_input = Vector2(target_horizontal, target_vertical)
            shade_dash(dash_input)
    else:
        # Main movement.
        # No gravity for shade
        shade_velocity.x = lerp(shade_velocity.x, target_horizontal, SHADE_HORIZONTAL_ACCEL * delta)
        shade_velocity.y = lerp(shade_velocity.y, target_vertical, SHADE_VERTICAL_ACCEL * delta)

    shade_velocity = $shade.move_and_slide(shade_velocity, Vector2.UP)

func _jump():
    is_airborne = true
    is_fast_falling = false
    velocity.y = -JUMP_VEL
    sfx.play(sfx.JUMP, sfx.EXTRA_QUIET_DB)
    $animation.play("jump")
    
func _update_mana(delta):
    # Don't actually change anything if we aren't controllable, but still send the signal.
    if is_controllable:
        if is_shade_out:
            set_mana(mana - MANA_DEPLETION * delta)
        else:
            set_mana(mana + MANA_GAIN * delta)
    else:
        emit_signal("mana_changed", mana / MAX_MANA)

# Sets mana, handling 0 and max range automatically. Emits signal.
func set_mana(m):
    mana = min(max(0, m), MAX_MANA)
    if mana == 0:
        _toggle_shade()
    emit_signal("mana_changed", mana / MAX_MANA)

func _update_sprite_flip():
    if is_shade_out:
        $shade/sprite.flip_h = not facing_left
    else:
        $sprite.flip_h = not facing_left

func _walk_sfx(delta):
    if !is_on_floor() or !is_moving:
        walk_sfx_cooldown = 0
        return

    if walk_sfx_cooldown <= 0:
        sfx.play(sfx.WALK, sfx.QUIET_DB)
        walk_sfx_cooldown = WALK_SFX_COOLDOWN
    if walk_sfx_cooldown > 0:
        walk_sfx_cooldown -= delta

func _on_hurtbox_area_entered(area):
    die()

func _on_hurtbox_body_entered(body):
    die()

func die():
    is_controllable = false
    time_warp.speedup()
    # TODO: Add shade death and hide shade if body dies while shade is out
    $animation.play("death")
    sfx.play(sfx.DEATH)
    global_camera.shake(0.5, 30, 3)
    yield($animation, "animation_finished")
    var level = get_tree().get_nodes_in_group("level")[0]
    level.begin_reset_transition()

func win():
    is_controllable = false
    time_warp.speedup()
    $animation.play_backwards("teleport")
    sfx.play(sfx.TELEPORT)
    
    var level = get_tree().get_nodes_in_group("level")[0]
    level.begin_next_level_transition()
    
    global_camera.shake(0.75, 30, 1)
