class_name FailureMode
## The three ways a part can fail, ordered from lightest to heaviest.

enum { MALFUNCTION = 0, BREAK = 1, EXPLODE = 2 }
const NONE := -1
## Weight of each mode in the level risk threshold: 3 malfunctions = 2 breaks = 1 explosion.
const WEIGHTS: Array[float] = [1.0 / 3.0, 0.5, 1.0]
