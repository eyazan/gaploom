class_name Sfx
extends Node
## Procedurally synthesized sound effects (no audio assets, no licensing risk).

const RATE := 22050

static var instance: Sfx
var enabled := true
var _streams: Dictionary = {}
var _players: Array[AudioStreamPlayer] = []
var _next := 0


func _ready() -> void:
	instance = self
	for i in 6:
		var p := AudioStreamPlayer.new()
		p.volume_db = -6.0
		add_child(p)
		_players.append(p)
	_streams["pick"] = _tone([[880.0, 0.05]], 0.25, 0.004)
	_streams["drop"] = _tone([[520.0, 0.07], [780.0, 0.10]], 0.3, 0.004)
	_streams["invalid"] = _tone([[160.0, 0.12]], 0.35, 0.01, true)
	_streams["light"] = _tone([[660.0, 0.06], [880.0, 0.06], [1320.0, 0.14]], 0.18, 0.003)
	_streams["roll"] = _tone([[300.0, 0.03]], 0.2, 0.002, true)
	_streams["dock"] = _tone([[392.0, 0.06], [587.0, 0.12]], 0.28, 0.004)
	_streams["undo"] = _tone([[600.0, 0.04], [450.0, 0.05]], 0.2, 0.003)
	_streams["win"] = _tone([[523.0, 0.10], [659.0, 0.10], [784.0, 0.10], [1047.0, 0.35]], 0.28, 0.004)
	_streams["tap"] = _tone([[700.0, 0.03]], 0.18, 0.002)


static func play(name: String, pitch: float = 1.0) -> void:
	if instance == null or not instance.enabled:
		return
	var s: AudioStream = instance._streams.get(name)
	if s == null:
		return
	var p := instance._players[instance._next]
	instance._next = (instance._next + 1) % instance._players.size()
	p.stream = s
	p.pitch_scale = pitch
	p.play()


## notes: [[freq, seconds], ...] played in sequence with soft attack/decay.
func _tone(notes: Array, amp: float, attack: float, buzzy: bool = false) -> AudioStreamWAV:
	var data := PackedByteArray()
	for n in notes:
		var freq: float = n[0]
		var dur: float = n[1]
		var count := int(dur * RATE)
		for i in count:
			var t := float(i) / RATE
			var env := minf(1.0, t / maxf(attack, 0.0001)) * pow(1.0 - float(i) / count, 2.0)
			var ph := TAU * freq * t
			var v := sin(ph) * 0.7 + sin(ph * 2.0) * 0.2 + sin(ph * 3.0) * 0.1
			if buzzy:
				v = signf(sin(ph)) * 0.5 + sin(ph) * 0.5
			var sample := int(clampf(v * env * amp, -1.0, 1.0) * 32767.0)
			data.append(sample & 0xff)
			data.append((sample >> 8) & 0xff)
	var w := AudioStreamWAV.new()
	w.format = AudioStreamWAV.FORMAT_16_BITS
	w.mix_rate = RATE
	w.stereo = false
	w.data = data
	return w
