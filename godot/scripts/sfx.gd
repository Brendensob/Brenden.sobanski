extends Node
## Sound effects. Every sound is made in code when the game starts: short
## 8-bit square, triangle and noise blips in the style of the original, so
## there are no sound files to ship. Sfx.play("coin") plays one.
## Sound on/off is kept in user://settings.cfg.

const RATE := 22050
const VOICES := 12
const SETTINGS := "user://settings.cfg"

var sounds := {}
var players: Array[AudioStreamPlayer] = []
var _next := 0
var on := true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		on = bool(cfg.get_value("audio", "sound", true))
	for i in VOICES:
		var p := AudioStreamPlayer.new()
		add_child(p)
		players.append(p)
	_build()
	# every menu button clicks
	get_tree().node_added.connect(func(n: Node):
		if n is BaseButton:
			n.pressed.connect(func(): play("click", 0.0)))

func set_on(v: bool) -> void:
	on = v
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("audio", "sound", v)
	cfg.save(SETTINGS)

func play(id: String, jitter: float = 0.05, db: float = 0.0) -> void:
	if not on or not sounds.has(id):
		return
	var p := players[_next]
	_next = (_next + 1) % players.size()
	p.stream = sounds[id]
	p.pitch_scale = 1.0 + randf_range(-jitter, jitter)
	p.volume_db = db
	p.play()

# ---------------------------------------------------------------- the synth
## A sound is a list of notes played one after another. A note is a
## dictionary: w (square, tri, saw, noise), f / f1 (start and end pitch in Hz),
## d (seconds), v / v1 (start and end volume), duty (square width),
## lp (noise smoothing, 0..1: lower is duller), gap (silence after).
func _make(notes: Array) -> AudioStreamWAV:
	var out := PackedFloat32Array()
	var rng := RandomNumberGenerator.new()
	rng.seed = 7
	for nt in notes:
		var w: String = nt.get("w", "square")
		var f0: float = nt.get("f", 440.0)
		var f1: float = nt.get("f1", f0)
		var d: float = nt.get("d", 0.1)
		var v0: float = nt.get("v", 0.5)
		var v1: float = nt.get("v1", 0.0)
		var duty: float = nt.get("duty", 0.5)
		var lp: float = nt.get("lp", 1.0)
		var vib: float = nt.get("vib", 0.0)
		var n := int(d * RATE)
		var ph := 0.0
		var y := 0.0
		var hold := 0.0
		for i in n:
			var k := float(i) / maxf(n - 1, 1)
			var f := lerpf(f0, f1, k) * (1.0 + vib * sin(TAU * 18.0 * i / RATE))
			ph = fmod(ph + f / RATE, 1.0)
			var s := 0.0
			match w:
				"square":
					s = 1.0 if ph < duty else -1.0
				"tri":
					s = 4.0 * absf(ph - 0.5) - 1.0
				"saw":
					s = 2.0 * ph - 1.0
				"noise":
					# a new random value each "cycle" gives pitched 8-bit noise
					if ph < f / RATE:
						hold = rng.randf_range(-1.0, 1.0)
					s = hold
			y += lp * (s - y)
			# short fade in and out so nothing pops
			var edge := minf(1.0, minf(i, n - i) / 40.0)
			out.append(y * lerpf(v0, v1, k) * edge)
		for i in int(nt.get("gap", 0.0) * RATE):
			out.append(0.0)
	var data := PackedByteArray()
	data.resize(out.size() * 2)
	for i in out.size():
		data.encode_s16(i * 2, int(clampf(out[i], -1.0, 1.0) * 26000.0))
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	return wav

func _build() -> void:
	var defs := {
		# fighting
		"swing": [{"w": "noise", "f": 9000, "f1": 2500, "d": 0.09, "v": 0.35, "lp": 0.35}],
		"hit": [{"w": "square", "f": 240, "f1": 90, "d": 0.06, "v": 0.45, "v1": 0.2, "duty": 0.5},
			{"w": "noise", "f": 4000, "f1": 1500, "d": 0.05, "v": 0.35, "lp": 0.6}],
		"crit": [{"w": "square", "f": 900, "f1": 500, "d": 0.04, "v": 0.35, "duty": 0.25},
			{"w": "square", "f": 260, "f1": 80, "d": 0.08, "v": 0.5, "duty": 0.5}],
		"mob_die": [{"w": "noise", "f": 3000, "f1": 600, "d": 0.16, "v": 0.45, "lp": 0.7},
			{"w": "square", "f": 330, "f1": 55, "d": 0.18, "v": 0.35, "duty": 0.5}],
		"hurt": [{"w": "square", "f": 520, "f1": 140, "d": 0.16, "v": 0.45, "duty": 0.5}],
		"die": [{"w": "tri", "f": 523, "d": 0.12, "v": 0.5, "v1": 0.4}, {"w": "tri", "f": 392, "d": 0.12, "v": 0.5, "v1": 0.4},
			{"w": "tri", "f": 262, "f1": 98, "d": 0.45, "v": 0.5}],
		"shoot": [{"w": "tri", "f": 900, "f1": 250, "d": 0.09, "v": 0.5}, {"w": "noise", "f": 6000, "d": 0.03, "v": 0.2, "lp": 0.5}],
		"cast": [{"w": "square", "f": 500, "f1": 1300, "d": 0.14, "v": 0.3, "duty": 0.25, "vib": 0.04}],
		"boom": [{"w": "noise", "f": 2200, "f1": 200, "d": 0.4, "v": 0.6, "lp": 0.45}],
		# gathering
		"chop": [{"w": "tri", "f": 330, "f1": 170, "d": 0.05, "v": 0.6}, {"w": "noise", "f": 2500, "f1": 900, "d": 0.05, "v": 0.35, "lp": 0.4}],
		"mine": [{"w": "square", "f": 1500, "f1": 1300, "d": 0.03, "v": 0.3, "duty": 0.25}, {"w": "tri", "f": 2100, "d": 0.12, "v": 0.35}],
		"hammer": [{"w": "square", "f": 120, "f1": 60, "d": 0.12, "v": 0.5, "duty": 0.5}, {"w": "noise", "f": 1500, "f1": 400, "d": 0.12, "v": 0.4, "lp": 0.3}],
		"burn": [{"w": "noise", "f": 5000, "f1": 2000, "d": 0.3, "v": 0.25, "v1": 0.05, "lp": 0.25}],
		"break": [{"w": "noise", "f": 3500, "f1": 500, "d": 0.22, "v": 0.5, "lp": 0.5},
			{"w": "square", "f": 200, "f1": 70, "d": 0.1, "v": 0.3, "duty": 0.5}],
		"thud": [{"w": "square", "f": 150, "f1": 110, "d": 0.05, "v": 0.35, "duty": 0.5}],
		"place": [{"w": "tri", "f": 180, "f1": 120, "d": 0.06, "v": 0.6}, {"w": "noise", "f": 1800, "d": 0.04, "v": 0.2, "lp": 0.3}],
		# moving
		"jump": [{"w": "square", "f": 280, "f1": 640, "d": 0.09, "v": 0.3, "v1": 0.15, "duty": 0.25}],
		"portal": [{"w": "tri", "f": 200, "f1": 900, "d": 0.35, "v": 0.45, "v1": 0.1, "vib": 0.08}],
		# getting things
		"pickup": [{"w": "square", "f": 660, "d": 0.045, "v": 0.3, "v1": 0.3, "duty": 0.25}, {"w": "square", "f": 990, "d": 0.07, "v": 0.3, "duty": 0.25}],
		"coin": [{"w": "square", "f": 988, "d": 0.06, "v": 0.3, "v1": 0.3, "duty": 0.5}, {"w": "square", "f": 1319, "d": 0.22, "v": 0.3, "duty": 0.5}],
		"eat": [{"w": "noise", "f": 2500, "d": 0.04, "v": 0.4, "lp": 0.4, "gap": 0.03}, {"w": "noise", "f": 2200, "d": 0.04, "v": 0.35, "lp": 0.4, "gap": 0.03},
			{"w": "noise", "f": 2000, "d": 0.05, "v": 0.3, "lp": 0.4}],
		"craft": [{"w": "square", "f": 523, "d": 0.06, "v": 0.3, "v1": 0.3, "duty": 0.25}, {"w": "square", "f": 659, "d": 0.06, "v": 0.3, "v1": 0.3, "duty": 0.25},
			{"w": "square", "f": 784, "d": 0.06, "v": 0.3, "v1": 0.3, "duty": 0.25}, {"w": "square", "f": 1047, "d": 0.16, "v": 0.3, "duty": 0.25}],
		"quest": [{"w": "square", "f": 784, "d": 0.08, "v": 0.3, "v1": 0.3, "duty": 0.5}, {"w": "square", "f": 1047, "d": 0.08, "v": 0.3, "v1": 0.3, "duty": 0.5},
			{"w": "square", "f": 1319, "d": 0.08, "v": 0.3, "v1": 0.3, "duty": 0.5}, {"w": "square", "f": 1568, "d": 0.25, "v": 0.3, "duty": 0.5}],
		"fail": [{"w": "square", "f": 220, "d": 0.08, "v": 0.3, "v1": 0.3, "duty": 0.5, "gap": 0.02}, {"w": "square", "f": 165, "d": 0.14, "v": 0.3, "duty": 0.5}],
		# menus and people
		"click": [{"w": "square", "f": 1100, "d": 0.025, "v": 0.18, "duty": 0.25}],
		"tap": [{"w": "square", "f": 560, "d": 0.03, "v": 0.3, "v1": 0.3, "duty": 0.25}, {"w": "square", "f": 840, "d": 0.05, "v": 0.3, "duty": 0.25}],
		"open": [{"w": "tri", "f": 450, "f1": 800, "d": 0.07, "v": 0.45}],
		"close": [{"w": "tri", "f": 800, "f1": 450, "d": 0.07, "v": 0.45}],
		"night": [{"w": "tri", "f": 392, "d": 0.18, "v": 0.45, "v1": 0.4}, {"w": "tri", "f": 311, "d": 0.18, "v": 0.45, "v1": 0.4},
			{"w": "tri", "f": 262, "d": 0.4, "v": 0.45}],
	}
	for id in defs:
		sounds[id] = _make(defs[id])
