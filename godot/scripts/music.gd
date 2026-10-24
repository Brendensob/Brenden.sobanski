extends Node
## Background music. Every track is an original chiptune loop composed here and
## synthesized in code when the game starts (in a background thread), the same
## way the sound effects are, so there are no music files to ship or license.
## Music.want("field") fades over to a track; Music.want("") fades out.
## The music volume is kept in user://settings.cfg next to the sound settings.

const RATE := 16000
const SETTINGS := "user://settings.cfg"
const FADE := 1.2

# A track: tempo, key (MIDI note of the tonic), scale, the chord roots as scale
# degrees (one chord per bar), the melody as scale degrees over the chord per
# eighth note (-99 is a rest), and which parts play.
const MAJOR := [0, 2, 4, 5, 7, 9, 11]
const MINOR := [0, 2, 3, 5, 7, 8, 10]
const R := -99
const TRACKS := {
	# title screen: slow and calm
	"menu": {"bpm": 84, "key": 60, "scale": "major", "prog": [0, 5, 3, 4],
		"a": [4, R, 2, R, 0, 2, 4, 7], "b": [7, R, 6, 4, 2, R, 0, R], "drums": "soft", "arp": true, "lead": 0.25},
	# Pixel Town: cheerful
	"town": {"bpm": 112, "key": 65, "scale": "major", "prog": [0, 3, 4, 0, 5, 3, 1, 4],
		"a": [0, 2, 4, 2, 7, 4, 2, 4], "b": [4, 4, 5, 4, 2, R, 0, R], "drums": "full", "arp": false, "lead": 0.5},
	# out in the open: upbeat
	"field": {"bpm": 124, "key": 67, "scale": "major", "prog": [0, 4, 5, 3, 0, 4, 3, 4],
		"a": [0, R, 4, 2, 4, 7, 6, 4], "b": [2, 4, 2, 0, -1, 0, 2, R], "drums": "full", "arp": true, "lead": 0.25},
	# caves and the dark worlds: sparse and low
	"cave": {"bpm": 76, "key": 57, "scale": "minor", "prog": [0, 5, 3, 4],
		"a": [0, R, R, 2, 4, R, 2, R], "b": [4, R, 3, R, 2, R, -1, R], "drums": "soft", "arp": true, "lead": 0.125},
	# Hell: driving minor
	"hell": {"bpm": 136, "key": 50, "scale": "minor", "prog": [0, 0, 5, 4, 0, 0, 3, 4],
		"a": [0, 0, 7, 0, 6, 0, 4, 3], "b": [4, 3, 2, 1, 0, R, 4, R], "drums": "full", "arp": false, "lead": 0.5},
	# a boss is here
	"boss": {"bpm": 152, "key": 52, "scale": "minor", "prog": [0, 5, 0, 4, 0, 5, 6, 4],
		"a": [0, 2, 3, 2, 0, 7, 6, 4], "b": [7, 7, 6, 4, 3, 4, 6, 7], "drums": "hard", "arp": true, "lead": 0.25},
	# Survival Grasslands at night
	"danger": {"bpm": 118, "key": 48, "scale": "minor", "prog": [0, 6, 5, 4],
		"a": [0, R, 0, 3, R, 2, 0, R], "b": [4, R, 3, 2, R, 3, 2, -1], "drums": "full", "arp": true, "lead": 0.125},
}

var tracks := {} # id -> AudioStreamWAV, filled by the background thread
var volume := 0.6
var current := ""
var _wanted := ""
var _players: Array[AudioStreamPlayer] = []
var _active := 0
var _thread: Thread
var _mutex := Mutex.new()
var _jobs := [] # without threads (the web build): tracks still to make, a slice per frame
var _job: Dictionary = {}
const SLICE_MS := 3

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	var cfg := ConfigFile.new()
	if cfg.load(SETTINGS) == OK:
		volume = clampf(float(cfg.get_value("audio", "music", 0.6)), 0.0, 1.0)
	for i in 2:
		var p := AudioStreamPlayer.new()
		p.volume_db = -80.0
		add_child(p)
		_players.append(p)
	if OS.has_feature("threads"):
		_thread = Thread.new()
		_thread.start(_build_all)
	else:
		_jobs = TRACKS.keys()

func _exit_tree() -> void:
	if _thread and _thread.is_started():
		_thread.wait_to_finish()

func ready_count() -> int:
	_mutex.lock()
	var n := tracks.size()
	_mutex.unlock()
	return n

func set_volume(v: float) -> void:
	volume = clampf(v, 0.0, 1.0)
	var cfg := ConfigFile.new()
	cfg.load(SETTINGS)
	cfg.set_value("audio", "music", volume)
	cfg.save(SETTINGS)

## The track that should be playing; switching fades the old one out.
func want(id: String) -> void:
	_wanted = id

## Without threads, makes a little of the next track each frame, starting
## with the one that should be playing, so there's never a long freeze.
func _work_slice() -> void:
	if _job.is_empty():
		if _jobs.is_empty():
			return
		var id: String = _wanted if _wanted in _jobs else _jobs[0]
		_jobs.erase(id)
		_job = render_begin(TRACKS[id])
		_job.id = id
	var t0 := Time.get_ticks_msec()
	while Time.get_ticks_msec() - t0 < SLICE_MS:
		if render_step(_job):
			tracks[_job.id] = _job.wav
			_job = {}
			return

func _process(delta: float) -> void:
	if not _jobs.is_empty() or not _job.is_empty():
		_work_slice()
	if _wanted != current:
		var stream: AudioStreamWAV = null
		_mutex.lock()
		stream = tracks.get(_wanted)
		_mutex.unlock()
		if _wanted == "" or stream != null:
			current = _wanted
			_active = 1 - _active
			var p := _players[_active]
			if stream:
				p.stream = stream
				p.volume_db = -80.0
				p.play()
			else:
				p.stop()
	var target := linear_to_db(maxf(volume, 0.0001) * 0.55) if volume > 0.0 else -80.0
	for i in 2:
		var p := _players[i]
		if not p.playing:
			continue
		var goal := target if i == _active and current != "" else -80.0
		p.volume_db = move_toward(p.volume_db, goal, delta * 60.0 / FADE)
		if i != _active and p.volume_db <= -79.0:
			p.stop()

## Which track fits where the player is: the screen, the world, a boss, night.
static func pick(title: bool, kind: String, theme: String, boss: bool, night: bool, deep: bool) -> String:
	if title:
		return "menu"
	if boss:
		return "boss"
	if kind == "town":
		return "town"
	if kind == "survival":
		return "danger" if night else "field"
	if theme == "hell":
		return "hell"
	if theme in ["dark", "ghost", "tomb", "modina", "nightmare"] or deep:
		return "cave"
	return "field"

# ---------------------------------------------------------------- the synth
func _build_all() -> void:
	for id in TRACKS:
		var wav := render(TRACKS[id])
		_mutex.lock()
		tracks[id] = wav
		_mutex.unlock()

static func _freq(midi: float) -> float:
	return 440.0 * pow(2.0, (midi - 69.0) / 12.0)

static func _note(t: Dictionary, chord: int, deg: int) -> float:
	var scale: Array = MAJOR if t.scale == "major" else MINOR
	var d := chord + deg
	var octave := floori(d / 7.0)
	return float(t.key) + scale[posmod(d, 7)] + 12 * octave

## Renders one track in one go: 16 bars, the A melody over the progression,
## then the B melody.
static func render(t: Dictionary) -> AudioStreamWAV:
	var job := render_begin(t)
	while not render_step(job):
		pass
	return job.wav

## A track being made a piece at a time (an eighth note per step, then the encoding).
static func render_begin(t: Dictionary) -> Dictionary:
	var step := 60.0 / float(t.bpm) / 2.0 # an eighth note
	var bars := 16
	var total := int(bars * 8 * step * RATE)
	var buf := PackedFloat32Array()
	buf.resize(total)
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(t))
	return {"t": t, "step": step, "notes": bars * 8, "total": total, "buf": buf, "rng": rng, "at": 0, "pk": 0, "peak": 0.001, "enc": 0}

## Does one more piece of a track (one eighth note, or a chunk of encoding);
## true when it's finished (job.wav is set).
static func render_step(job: Dictionary) -> bool:
	var t: Dictionary = job.t
	var buf: PackedFloat32Array = job.buf
	if job.at < job.notes:
		_render_eighth(t, buf, job.at / 8, job.at % 8, job.step, job.rng)
		job.at += 1
		return false
	# find the loudest point, a chunk at a time
	if job.pk < job.total:
		var peak: float = job.peak
		var end := mini(job.pk + 6000, job.total)
		for i in range(job.pk, end):
			peak = maxf(peak, absf(buf[i]))
		job.peak = peak
		job.pk = end
		return false
	if job.enc == 0 and not job.has("data"):
		job.gain = 0.7 / float(job.peak)
		job.data = PackedByteArray()
		job.data.resize(job.total * 2)
	# encode in chunks of a bar's worth of samples
	var data: PackedByteArray = job.data
	var gain: float = job.gain
	var stop := mini(job.enc + 6000, job.total)
	for i in range(job.enc, stop):
		data.encode_s16(i * 2, int(clampf(buf[i] * gain, -1.0, 1.0) * 30000.0))
	job.enc = stop
	if job.enc < job.total:
		return false
	var wav := AudioStreamWAV.new()
	wav.format = AudioStreamWAV.FORMAT_16_BITS
	wav.mix_rate = RATE
	wav.stereo = false
	wav.data = data
	wav.loop_mode = AudioStreamWAV.LOOP_FORWARD
	wav.loop_begin = 0
	wav.loop_end = job.total
	job.wav = wav
	return true

static func _render_eighth(t: Dictionary, buf: PackedFloat32Array, bar: int, s: int, step: float, rng: RandomNumberGenerator) -> void:
	var prog: Array = t.prog
	var chord: int = prog[bar % prog.size()]
	var mel: Array = t.a if (bar / prog.size()) % 2 == 0 else t.b
	if true:
		var start := int((bar * 8 + s) * step * RATE)
		# lead
		if mel[s] != R:
			var len := step
			if s < 7 and mel[s + 1] == R:
				len = step * 2.0
			_tone(buf, start, len * 0.92, _freq(_note(t, chord, mel[s]) + 12), "square", float(t.lead), 0.16)
		# bass on every beat, an octave and a fifth below on the off-beats
		if s % 2 == 0:
			_tone(buf, start, step * 0.9, _freq(_note(t, chord, 0) - 12), "tri", 0.5, 0.30)
		elif t.drums != "soft":
			_tone(buf, start, step * 0.5, _freq(_note(t, chord, 4) - 12), "tri", 0.5, 0.16)
		# a quiet arpeggio of the chord
		if t.arp:
			for k in 2:
				var a := start + int(k * step * 0.5 * RATE)
				_tone(buf, a, step * 0.45, _freq(_note(t, chord, [0, 2, 4, 2][(s * 2 + k) % 4]) + 24), "square", 0.125, 0.045)
		# drums
		match t.drums:
			"soft":
				if s == 0:
					_kick(buf, start, 0.22)
				if s % 2 == 1:
					_noise(buf, start, 0.02, 0.025, rng)
			"full":
				if s == 0 or s == 4:
					_kick(buf, start, 0.32)
				if s == 2 or s == 6:
					_noise(buf, start, 0.11, 0.13, rng)
				_noise(buf, start, 0.025, 0.04, rng)
			"hard":
				if s % 2 == 0:
					_kick(buf, start, 0.34)
				if s == 2 or s == 6:
					_noise(buf, start, 0.12, 0.16, rng)
				_noise(buf, start, 0.025, 0.05, rng)

static func _tone(buf: PackedFloat32Array, start: int, dur: float, f: float, wave: String, duty: float, vol: float) -> void:
	var n := mini(int(dur * RATE), buf.size() - start)
	var ph := 0.0
	var inc := f / RATE
	for i in n:
		ph += inc
		ph -= floorf(ph)
		var s: float
		if wave == "tri":
			s = 4.0 * absf(ph - 0.5) - 1.0
		else:
			s = 1.0 if ph < duty else -1.0
		# quick attack, gentle decay, short release so nothing clicks
		var env := minf(1.0, i / 80.0) * (1.0 - 0.45 * float(i) / n) * minf(1.0, (n - i) / 120.0)
		buf[start + i] += s * vol * env

static func _kick(buf: PackedFloat32Array, start: int, vol: float) -> void:
	var n := mini(int(0.09 * RATE), buf.size() - start)
	var ph := 0.0
	for i in n:
		var k := float(i) / n
		ph += lerpf(130.0, 40.0, k) / RATE
		buf[start + i] += sin(TAU * ph) * vol * (1.0 - k)

static func _noise(buf: PackedFloat32Array, start: int, dur: float, vol: float, rng: RandomNumberGenerator) -> void:
	var n := mini(int(dur * RATE), buf.size() - start)
	var prev := 0.0
	for i in n:
		var w := rng.randf_range(-1.0, 1.0)
		# a crude high-pass keeps the hiss light
		buf[start + i] += (w - prev * 0.6) * vol * (1.0 - float(i) / n)
		prev = w
