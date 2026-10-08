FINE AIM 1.2 -- aim down sights for Saints Reborn
==================================================

Hold right mouse with a gun to aim: the gun comes up, the camera moves over
your shoulder and narrows, your character turns to face where you look, and
your shots get tighter. Melee moves to X.

INSTALL
  1. Copy the FineAim folder into Saints Reborn's dist\mods folder.
  2. Run WhompaysModLoader.exe, tick Fine Aim, press Play.

CONTROLS
  Right mouse      aim (guns only; grenades, melee weapons and the sniper
                   scope keep their normal right click)
  X                melee
  Caps Lock        slow walk on / off
  Shift            sprint -- pressing it while aiming lowers the gun;
                   aiming while sprinting stops the sprint

  Camera tuning while you play:
  - / +            zoom in / out
  Page Up / Down   field of view wider / narrower
  Home / End       camera down / up
  Ctrl+I / Ctrl+O  shoulder left / right
  Ctrl+K / Ctrl+Y  previous / next preset
  Ctrl+J           reset to the preset's own values
  Ctrl+U           save the current camera as a preset (my_presets.ini)
  Ctrl+G           delete a saved preset

  Every key can be changed in mod.ini.

ACCURACY
  How wide your shots spread depends on what you are doing: standing,
  crouching, moving, slow-walking, from the hip or aimed. Each gun keeps its
  own accuracy; the numbers in mod.ini only set the ratios. Smaller is more
  accurate. Set cone_model = 0 for the game's own accuracy.

  The crosshair shows it too: it shrinks when you crouch or aim and grows
  when you move or sprint (guns only). See the Crosshair section of mod.ini.

VEHICLES
  Hold right mouse in a vehicle to raise your gun for a drive-by. The view
  zooms in slightly and your shots tighten while it is up.

PRESETS -- SHARING AND MAKING YOUR OWN
  presets.ini      the presets that come with the mod. Add shared presets here.
  my_presets.ini   presets you saved in game with Ctrl+U.

  A preset is a small block like this:

      [My Camera]
      style = orbit
      zoom = -0.50
      fov = 0.70
      height = 1.60
      shoulder = 0.40

  To share one, copy its block and send it. To use one somebody sent you,
  paste it at the end of presets.ini and restart the game; it shows up in the
  Ctrl+K / Ctrl+Y list under its name. To start the game on it, set
  "preset = My Camera" in mod.ini. presets.ini explains every value.

FILES THE MOD WRITES
  camera.cfg       the camera you are using right now (delete it to go back
                   to the preset in mod.ini)
  my_presets.ini   your saved presets
  overlay.txt      the tuning readout, shown by the Whompays Trainer when its
                   menu is closed

ONLINE
  Script mods are private play only: story co-op and Private Party work,
  public matches do not.
