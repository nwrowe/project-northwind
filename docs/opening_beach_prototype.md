# Opening Beach Prototype Example

This example scene is a **playable explorable prototype** for the opening beach / ocean / dock area.

## Chosen tile size

Use **64x64** as the base tile size.

Why 64x64:
- large enough for painterly pixel-art props with readable silhouettes
- easy to block out in Godot on a large scrolling scene
- works well for top-down shoreline, dock planks, driftwood, and shack pieces
- gives enough room for layered tiles without becoming too tiny to edit

## Updated world size

The explorable prototype world is now much larger than the visible game window:
- world width: `3072`
- world height: `1792`
- base grid footprint: `48 x 28 tiles`

The player remains near the center of the screen while moving, until the camera reaches a playable edge.
After that, the camera stops and the player can continue walking toward the boundary.

## Files added / updated

- `scenes/opening/OpeningBeachPrototype.tscn`
- `scripts/opening/OpeningBeachPrototype.gd`
- `docs/opening_beach_prototype.md`

Open the scene directly in Godot and run it as the current scene.

## Main layout goals

This version changes the composition so that:
- **land dominates the upper and middle screen space**
- **water sits at the bottom**
- the **rowboat lands on the lower shore**
- the **dock extends downward into the water**
- the player can explore inland, eastward, and along the beach

## What this scene is for

This is **not** the final art scene.
It is a complete example you can build from.

It gives you:
- the opening beach composition
- major prop placement
- interaction spacing
- player pathing flow
- dock / shack / bluff / inland route relationship
- sprite hook placeholders you can replace later
- a camera-follow model for larger maps

## What to replace with final art

These placeholder nodes are the main sprite hooks:
- `Rowboat`
- `PierWalk`
- `PierHead`
- `Shack`
- `Fisher`
- `Satchel`
- debris and rock markers
- bridge-ruin marker

The broad color bands represent terrain layers you can later convert into tiles or larger painted backgrounds:
- sky
- distant bluff
- upper dunes
- lower dunes
- wet sand
- foam bands
- shallow / mid / deep sea
- inland path
- upriver path

## Suggested sprite-sheet breakdown

If you build a first real beach sprite sheet, organize it roughly like this:

### Terrain tiles
- dry sand
- wet sand
- foam edge
- shallow surf
- sea surface variants
- dune grass edge
- bluff/path dirt
- rock clusters
- storm debris transitions

### Dock kit
- straight dock plank tile
- end cap tile
- corner / T-junction pieces if needed
- pylon variants
- rope / mooring clutter
- lantern post
- shack wall / roof pieces
- broken or storm-bent dock variants

### Clutter props
- driftwood long
- driftwood short
- broken crate
- rope coil
- satchel
- net bundle
- beach grass tufts
- storm debris
- broken sign or bridge fragment

### Character hooks
- player placeholder size reference
- fisher NPC reference
- rowboat reference

## Godot setup suggestion

Use a hybrid approach:
- **TileMap / TileSet** for sand, shoreline, path, and repeated dock pieces
- **Sprite2D** scenes for rowboat, shack, fisher, satchel, bridge fragments, and unique debris

That tends to be easier to maintain than forcing every unique prop into the tilemap.

## Current navigation logic

The script currently supports:
- player movement across the larger world
- camera follow by shifting the world under the HUD
- clamped camera edges
- interaction prompts for rowboat, satchel, and fisher
- a north exit hint for Aurelia
- an east exit hint for a future upriver / bridge-ruin scene

## Recommended next art workflow

1. Keep this expanded scene layout.
2. Build the first sprite sheet around **64x64 tiles**.
3. Replace the placeholder nodes with `Sprite2D` or `TileMapLayer` content.
4. Keep the current interaction zones until visuals settle.
5. Only then start polishing lighting, ambient props, shoreline variation, and transition scenes.
