class_name Layers
## Physics collision layers (bit masks).

## Level geometry, cargo, targets.
const WORLD := 1
## Parts still attached to the machine: they do not collide with each other.
const MACHINE := 2
## Detached parts and projectiles: collide with everything.
const DEBRIS := 4
## Build-mode ghosts, hit only by the editor's mouse ray.
const PICK := 256
