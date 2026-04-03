# Opening Beach Prototype Example

This example scene is a **playable spatial prototype** for the opening beach / ocean / dock area.

## Chosen tile size

Use **64x64** as the base tile size.

Why 64x64:
- large enough for painterly pixel-art props with readable silhouettes
- easy to block out in Godot on a 1280px-wide scene
- works well for top-down shoreline, dock planks, driftwood, and shack pieces
- gives enough room for layered tiles without becoming too tiny to edit

The prototype scene is laid out to a **20 tiles x 13 tiles** footprint:
- width: `1280`
- height: `832`

## Files added

- `scenes/opening/OpeningBeachPrototype.tscn`
- `scripts/opening/OpeningBeachPrototype.gd`

Open the scene directly in Godot and run it as the current scene.

## What this scene is for

This is **not** the final art scene.
It is a complete example you can build from.

It gives you:
- the opening beach composition
- major prop placement
- interaction spacing
- player pathing flow
- dock / shack / bluff relationship
- sprite hook placeholders you can replace later

## What to replace with final art

These placeholder nodes are the main sprite hooks:
- `Rowboat`
- `PierWalk`
- `PierHead`
- `Shack`
- `Fisher`
- `Satchel`
- `DebrisA/B/C`
- `WaveBreakRock`

The broad color bands represent terrain layers you can later convert into tiles or larger painted backgrounds:
- `SkyTop`
- `SkyHaze`
- `SeaFar`
- `SeaMid`
- `SeaNear`
- `WetSand`
- `DrySand`
- dune grass patches
- `TownPath`

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

### Dock kit
- straight dock plank tile
- end cap tile
- corner / T-junction pieces if needed
- pylon variants
- rope / mooring clutter
- lantern post
- shack wall / roof pieces

### Clutter props
- driftwood long
- driftwood short
- broken crate
- rope coil
- satchel
- net bundle
- beach grass tufts
- storm debris

### Character hooks
- player placeholder size reference
- fisher NPC reference
- rowboat reference

## Recommended next art workflow

1. Keep this scene layout.
2. Build the first sprite sheet around **64x64 tiles**.
3. Replace the placeholder nodes with `Sprite2D` or `TileMapLayer` content.
4. Keep the current interaction zones until visuals settle.
5. Only then start polishing lighting, ambient props, and shoreline variation.

## Godot setup suggestion

Use a hybrid approach:
- **TileMap / TileSet** for sand, shoreline, path, and repeated dock pieces
- **Sprite2D** scenes for rowboat, shack, fisher, satchel, and unique debris

That tends to be easier to maintain than forcing every unique prop into the tilemap.
