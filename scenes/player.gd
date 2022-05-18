extends KinematicBody2D
class_name Player

var velocity = Vector2.ZERO
var previous_velocity = Vector2.ZERO
var shade_velocity = Vector2.ZERO

const HORIZONTAL_VEL = 75.0
const HORIZONTAL_ACCEL = 20 # How quickly we accelerate to max speed

const SHADE_HORIZONTAL_VEL = 100.0
const SHADE_HORIZONTAL_ACCEL = 6
const SHADE_VERTICAL_VEL = 70.0
const SHADE_VERTICAL_ACCEL = 6

const SHADE_INITIAL_VEL = 1.5 # Percent of char's velocity

const GRAVITY = 6.0
const GRAVITY_DECREASE_THRESHOLD = 10 # The speed below which gravity is decreased.
const GRAVITY_DECREASE_MULTIPLIER = 0.5 # The amount of decrease for low gravity (at the height of a jump).
const JUMP_VEL = 160
const TERM_VEL = JUMP_VEL * 2
const FAST_FALL_MULTIPLIER = 1.7 # How much faster fast fall is compared to gravity
const JUMP_SIDE_DUST_SPEED = 20 # Speed after which we emit "side" jump particles
const LAND_DUST_SPEED = 80 # Speed after which we emit dust in the landed state

const JUMP_RELEASE_MULTIPLIER = 0.5 # Multiplied by velocity if button released

const MAX_MANA = 100.0
var mana = MAX_MANA
const MANA_DEPLETION = 70 # Rate of depletion
const MANA_GAIN = 140 # Rate of gain when not in shade
signal mana_changed

export (bool) var facing_left = true
var is_dying = false
var is_moving = false
var is_shade_moving = false
var is_airborne = false
var was_airborne = false
var is_fast_falling = false

var is_shade_out = false
const SHADE_RETURN_TIME = 0.3

# Squash and stretch
var squash_stretch_scale = Vector2.ONE
const JUMP_SQUASH_STRETCH = Vector2(0.8, 1.2)
const LAND_SQUASH_STRETCH = Vector2(1.5, 0.4)
const DASHBURST_SQUASH_STRETCH = Vector2(1.4, 0.7)
const SQUASH_LERP_SPEED = 10

var is_controllable = true

export (bool) var has_dash_powerup = false # Whether shade can dash at will
const DASH_POWERUP_MANA_COST = 50.0

# Shade dashing
var is_dashing = false
var is_accel_dashing = false
var is_dashburst = false
const DASH_ACCEL_DURATION = 0.15 # seconds
const DASH_DURATION = 0.4 # Includes DASH_ACCEL_DURATION, must be greater than it
const DASH_VEL = 200
var dash_timer = 0.0
var dash_direction = Vector2.ZERO
var is_about_to_dash = false
var dash_start_timer = 0.0
const DASH_START_DELAY = 0.13 # seconds

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
    $shade/aftereffect.lifetime = DASH_ACCEL_DURATION + 0.15
    
    _maybe_jump_to_checkpoint()
    
    _update_sprite_flip()
    
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
        print("JUMPING TO CHECKPOINT")
        global_position = checkpoint_store.get_checkpoint()

func _physics_process(delta):
    _maybe_die()
    # Adjust playback speed based on current time scale.
    $animation.playback_speed = time_warp.time_scale
    
    # Need to update mana even when uncontrolled in order to update the UI.
    _update_mana(delta)
    _animate_dash(delta)
    _animate_squash_stretch(delta)

    if !is_controllable:
        return

    if Input.is_action_just_pressed("restart"):
        die()
        return

    if Input.is_action_just_pressed("ki_burst"):
        _toggle_shade(true)
    if Input.is_action_just_released("ki_burst"):
        _toggle_shade(false)

    if is_shade_out:
        _move_shade(delta)

    _move_player(delta)
    
    _update_sprite_flip()
    _walk_sfx(delta)

func _animate_squash_stretch(delta):
    _maybe_update_offset()
    if is_dashburst and abs(velocity.y) < DASH_VEL / 2.0:
        _apply_dashburst_squash_stretch()
    elif is_airborne and velocity.y < 0:
        _apply_jump_squash_stretch()
    else:
        # We could actually use delta here, but we don't have to.
        # https://www.construct.net/en/blogs/ashleys-blog-2/using-lerp-delta-time-924
        var lerp_val = SQUASH_LERP_SPEED * delta * time_warp.time_scale
        assert(lerp_val <= 1.0)
        squash_stretch_scale.x = lerp(squash_stretch_scale.x, 1.0, lerp_val)
        squash_stretch_scale.y = lerp(squash_stretch_scale.y, 1.0, lerp_val)
    $sprite.scale = squash_stretch_scale

func _maybe_update_offset():
    if is_dashburst:
        $sprite.offset = Vector2.ZERO
        $sprite.position = Vector2.ZERO
    else:
        $sprite.offset = Vector2(0, -8)
        $sprite.position = Vector2(0, 8)

func _apply_jump_squash_stretch():
    squash_stretch_scale.x = range_lerp(abs(velocity.y), 0, JUMP_VEL, 1.0, JUMP_SQUASH_STRETCH.x)
    squash_stretch_scale.y = range_lerp(abs(velocity.y), 0, JUMP_VEL, 1.0, JUMP_SQUASH_STRETCH.y)
    $sprite.scale = squash_stretch_scale

func _apply_dashburst_squash_stretch():
    squash_stretch_scale.x = range_lerp(min(dash_timer, DASH_DURATION), 0, DASH_DURATION, DASHBURST_SQUASH_STRETCH.x, 1.0)
    squash_stretch_scale.y = range_lerp(min(dash_timer, DASH_DURATION), 0, DASH_DURATION, DASHBURST_SQUASH_STRETCH.y, 1.0)
    $sprite.scale = squash_stretch_scale

func _toggle_shade(desired_state: bool):
    # Can't toggle shade if dashing.
    if is_dashing or is_about_to_dash:
        return
        
    if is_shade_out and !desired_state:
        _hide_shade()
    elif desired_state:
        _show_shade()

func _hide_shade(quiet=false):
    time_warp.speedup()
    
    is_controllable = false
    is_shade_out = false
    $shade/shape.set_deferred("disabled", true)
    
    if !quiet:
        sfx.play(sfx.SHADE_RETURN, sfx.QUIET_DB)
        $shade/particles.speed_scale = 3.0
        $shade_tween.interpolate_property($shade, "position", $shade.position, Vector2(0, 0),
               SHADE_RETURN_TIME, Tween.TRANS_CUBIC, Tween.EASE_IN)
        $shade_tween.start()
        yield($shade_tween, "tween_completed")
        $shade/particles.speed_scale = 1.0

    $shade/particles.restart()
    $shade/aftereffect.restart()
    $shade/particles.emitting = false
    $shade/aftereffect.emitting = false
    is_controllable = true
    $shade.hide()
    $shade.position = Vector2.ZERO
    shade_velocity = Vector2.ZERO

func _show_shade():
    time_warp.slowdown()
    
    is_shade_out = true
    is_about_to_dash = false

    $shade.show()
    $shade.position = Vector2.ZERO
    shade_velocity = Vector2.ZERO
    $shade/shape.disabled = false
    $shade/particles.restart()
    sfx.play(sfx.SHADE, sfx.QUIET_DB)

func _maybe_schedule_powerup_dash():
    if !has_dash_powerup:
        return
    if mana <= 0:
        # We're completely spent.
        return
    # We want to allow the dash even when there isn't enough mana
    mana -= DASH_POWERUP_MANA_COST
    var input_vector = _get_shade_input_vector()
    shade_dash(_shade_vector_with_input(input_vector))

func schedule_shade_dash():
    is_about_to_dash = true
    dash_start_timer = 0.0

func shade_dash(dir: Vector2):
    is_about_to_dash = false
    is_controllable = false
    is_dashing = true
    is_accel_dashing = true
    is_dashburst = false
    dash_timer = 0.0
    dash_direction = dir.normalized()

    global_camera.shake(DASH_ACCEL_DURATION * 0.6, 30, 2)
    sfx.play(sfx.SHADE_DASH, sfx.SFX_DB)
    
    if facing_left:
        $shade/aftereffect.texture = preload("res://assets/player/shade_afterimage.png")
    else:
        $shade/aftereffect.texture = preload("res://assets/player/shade_afterimage_flipped.png")
    $shade/aftereffect.restart()

# Animates both the shade dash and the dashburst.
func _animate_dash(delta):
    if !is_dashing:
        return
    if is_accel_dashing:
        shade_velocity = dash_direction * DASH_VEL
        shade_velocity = $shade.move_and_slide(shade_velocity, Vector2.UP)
    if is_dashburst:
        velocity = dash_direction * DASH_VEL
        previous_velocity = velocity
        velocity = move_and_slide(velocity, Vector2.UP)
    
    dash_timer += delta
    if dash_timer >= DASH_ACCEL_DURATION:
        is_controllable = true
        is_accel_dashing = false
    if dash_timer >= DASH_DURATION:
        is_dashing = false
        is_dashburst = false
    
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
        if is_airborne and Input.is_action_just_released("move_up"):
            is_fast_falling = true
            if velocity.y < 0:
                velocity.y *= JUMP_RELEASE_MULTIPLIER

        if is_fast_falling:
            fall_multiplier = FAST_FALL_MULTIPLIER

    # When we're nearing the top of the jump, decrease gravity.
    var grav_multiplier = 1.0 if is_fast_falling or abs(velocity.y) > GRAVITY_DECREASE_THRESHOLD else GRAVITY_DECREASE_MULTIPLIER
    velocity.y = min(TERM_VEL, velocity.y + GRAVITY * grav_multiplier * fall_multiplier * time_warp.time_scale)

    # Lerp horizontal movement
    velocity.x = lerp(velocity.x, target_horizontal, HORIZONTAL_ACCEL * delta * time_warp.time_scale)

    # Handle shade being out and time scaling
    var shade_pos = $shade.global_position
    var time_scaled_velocity = velocity * time_warp.time_scale
    time_scaled_velocity = move_and_slide(time_scaled_velocity, Vector2.UP)
    previous_velocity = velocity
    velocity = time_scaled_velocity / time_warp.time_scale
    
    if was_airborne and is_on_floor():
        # Landed.
        is_airborne = false
        _landed()
    elif !was_airborne and !is_on_floor():
        # Fell off a cliff.
        is_airborne = true

    if !is_airborne and !is_dashburst:
        if is_moving:
            $animation.play("run")
        else:
            $animation.play("idle")
            
    # Special case for 'was_dashburst'
    if is_airborne and $animation.current_animation == "dashburst" and velocity.y > GRAVITY_DECREASE_THRESHOLD:
        $animation.play("jump")

    if is_shade_out:
        $shade.global_position = shade_pos

func _get_shade_input_vector():
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

    return Vector2(target_horizontal, target_vertical)

func _move_shade(delta):
    var input_vector = _get_shade_input_vector()
    
    if input_vector.x != 0:
        facing_left = input_vector.x < 0

    if is_about_to_dash:
        # About to dash, so don't apply the target vel.
        dash_start_timer += delta
        if dash_start_timer >= DASH_START_DELAY:
            shade_dash(_shade_vector_with_input(input_vector))
    else:
        # Main movement.
        # No gravity for shade
        shade_velocity.x = lerp(shade_velocity.x, input_vector.x, SHADE_HORIZONTAL_ACCEL * delta)
        shade_velocity.y = lerp(shade_velocity.y, input_vector.y, SHADE_VERTICAL_ACCEL * delta)

    shade_velocity = $shade.move_and_slide(shade_velocity, Vector2.UP)

func _shade_vector_with_input(input_vector):
    # Use the shade's velocity by default, unless the player is holding
    # down directions, in which case they take priority.
    var shade_vector = shade_velocity
    if input_vector.x != 0 or input_vector.y != 0:
        shade_vector = input_vector
    return shade_vector

func _jump():
    is_airborne = true
    is_fast_falling = false
    velocity.y = -JUMP_VEL
    sfx.play(sfx.JUMP, sfx.EXTRA_QUIET_DB)
    $animation.play("jump")
    _apply_jump_squash_stretch()

    # Create the dust animation
    _create_dust()

func _landed():
    if previous_velocity.y > LAND_DUST_SPEED:
        # Set the squash/stretch scales based on the landing speed.
        squash_stretch_scale.x = clamp(range_lerp(previous_velocity.y, 0, JUMP_VEL, 1.0, LAND_SQUASH_STRETCH.x), 1.0, LAND_SQUASH_STRETCH.x)
        squash_stretch_scale.y = clamp(range_lerp(previous_velocity.y, 0, JUMP_VEL, 1.0, LAND_SQUASH_STRETCH.y), LAND_SQUASH_STRETCH.y, 1.0)

        _create_dust(true)
        # The walk sound works well as a landed sound.
        sfx.play(sfx.WALK, sfx.QUIET_DB)

func _create_dust(is_landing=false):
    var dust = preload("res://scenes/jump_dust_particles.tscn").instance()
    dust.flip_h = not facing_left
    dust.global_position = global_position
    _add_sibling_above(dust)
    
    if is_landing:
        dust.play_once("land")
    # Play different animations based on horizontal speed
    elif abs(velocity.x) > JUMP_SIDE_DUST_SPEED:
        dust.play_once("side")
    else:
        dust.play_once("up")

# Adds a sibling node above the player.
func _add_sibling_above(node):
    var parent = get_parent()
    parent.add_child(node)
    parent.move_child(node, get_index())

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
        _toggle_shade(false)
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
    if is_dying: return
    is_dying = true
    _hide_shade(true)
    is_controllable = false
    is_dashing = false
    death_counter.die()
    time_warp.speedup()
    
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


func _on_burstbox_body_entered(body):
    if is_dashing:
        dashburst()

func dashburst():
    is_controllable = false
    is_dashing = true
    is_dashburst = true
    # Update mana
    set_mana(MAX_MANA)
    # Reset timer
    dash_timer = 0.0

    _hide_shade(true)
    
    $animation.play("dashburst")
    _apply_dashburst_squash_stretch()
    
    global_camera.shake(DASH_ACCEL_DURATION * 0.6, 30, 2)
    sfx.play(sfx.DASHBURST, sfx.SFX_DB)
    $shockwave.global_position = global_position
    $shockwave.shockwave()
    
    #if facing_left:
    #    $shade/aftereffect.texture = preload("res://assets/player/shade_afterimage.png")
    #else:
    #    $shade/aftereffect.texture = preload("res://assets/player/shade_afterimage_flipped.png")
    #$shade/aftereffect.restart()

func on_scroll_acquire_start():
    var was_controllable = is_controllable
    is_controllable = false
    return was_controllable
    
func on_scroll_acquire_stop(was_controllable):
    is_controllable = was_controllable

const ABYSS_DEATH_THRESHOLD_Y = 1250
func _maybe_die():
    # Special case handling in case the player falls off the edge of the world.
    if position.y > ABYSS_DEATH_THRESHOLD_Y:
        die()
