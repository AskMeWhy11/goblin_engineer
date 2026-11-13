class_name Sfx
extends Node
## Tiny procedural sound bank: every sound is synthesised once, no audio files.

const MIX_RATE := 22050
const KINDS: Array[StringName] = [&"explode", &"break", &"malfunction", &"shot", &"win"]

static var _cache: Dictionary = {}


## Plays a sound; the player node frees itself when done (or with this node).
func play(kind: StringName, volume_db := 0.0) -> void:
	var stream := make_stream(kind)
	if stream == null:
		return
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.add_to_group(&"sfx")
	player.finished.connect(player.queue_free)
	add_child(player)
	player.play()


## Returns null for an unknown kind.
static func make_stream(kind: StringName) -> AudioStreamWAV:
	if _cache.has(kind):
		return _cache[kind]
	var samples: PackedFloat32Array
	match kind:
		&"explode":
			samples = _noise(0.7, 6.0, 0.08)
		&"break":
			samples = _noise(0.14, 30.0, 0.5)
		&"shot":
			samples = _noise(0.25, 18.0, 0.25)
		&"malfunction":
			samples = _tone(0.3, 420.0, 140.0)
		&"win":
			samples = _tone(0.18, 520.0, 520.0)
			samples.append_array(_tone(0.3, 780.0, 780.0))
		_:
			return null
	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = MIX_RATE
	stream.stereo = false
	var bytes := PackedByteArray()
	bytes.resize(samples.size() * 2)
	for i in samples.size():
		bytes.encode_s16(i * 2, int(clampf(samples[i], -1.0, 1.0) * 32000.0))
	stream.data = bytes
	_cache[kind] = stream
	return stream


## Decaying noise. `smooth` in 0..1: lower = duller (stronger low-pass).
static func _noise(seconds: float, decay: float, smooth: float) -> PackedFloat32Array:
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345
	var out := PackedFloat32Array()
	var count := int(seconds * MIX_RATE)
	out.resize(count)
	var value := 0.0
	for i in count:
		var t := float(i) / MIX_RATE
		value = lerpf(value, rng.randf_range(-1.0, 1.0), smooth)
		out[i] = value * exp(-decay * t) * 2.5
	return out


## A tone gliding from one frequency to another with a soft envelope.
static func _tone(seconds: float, from_hz: float, to_hz: float) -> PackedFloat32Array:
	var out := PackedFloat32Array()
	var count := int(seconds * MIX_RATE)
	out.resize(count)
	var phase := 0.0
	for i in count:
		var k := float(i) / count
		phase += TAU * lerpf(from_hz, to_hz, k) / MIX_RATE
		out[i] = sin(phase) * sin(PI * k) * 0.6
	return out
