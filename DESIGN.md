# Design

Metroidvania where two characters are joined with a tether, can only be far
away for short periods of time. "Joined" state is main state, but tether-based
movement can be used to go into areas that are otherwise inaccessible, to
trigger traps/puzzles, fight certain enemies, etc.

## Mechanics

- Basic movement / jumping
- Press a button to go into "tether mode"
  In tether mode, you become a (smaller?) character, tethered to your main body.
  Can only travel for a certain (short) distance, and can only stay that way
  for a certain amount of time.

    Controlled via "tether meter". Guage begins depleting once in tether mode,
    and depletes faster if moving.

    Tether has short cooldown.

  Ideas for how to use this:
  - Squeeze through tight places to get to a switch
  - Gravity doesn't affect you (?) and you can get to switches up above
  - Can get items that extend your range, allowing you to reach further in tether
  - Tether mode must be used to go through certain gates / fight certain enemies?

- Fighting 
  TODO: Shooting or melee?
  Or both? Maybe tether mode can shoot?

  IDEA: Tether mode can fight, non-tether can't, but body is vulnerable while
  in tether

TODO: Decide on aesthetic / visual theme
