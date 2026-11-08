class_name LorongAtmosphereAudio
extends RefCounted
## Optional, original atmosphere cues for Lorong Sunyi's peaceful village slice.
##
## Nothing is registered or played until a caller explicitly enables this helper.
## Create one instance for the active Lorong run, configure it with AudioDirector,
## and call the event methods from gameplay when their state transitions occur.

const ProceduralSfx = preload("res://scripts/manus/procedural_sfx.gd")

const CUE_NPC_GREETING := "lorong.npc_greeting"
const CUE_NPC_CHAT := "lorong.npc_chat"
const CUE_FOUND_SOMETHING := "lorong.found_something"
const CUE_HELPED_NEIGHBOR := "lorong.helped_neighbor"
const CUE_EVENING_VILLAGE := "lorong.evening_village"
const CUE_CONDITIONS_CHANGED := "lorong.conditions_changed"
const CUE_IDS := [
	CUE_NPC_GREETING,
	CUE_NPC_CHAT,
	CUE_FOUND_SOMETHING,
	CUE_HELPED_NEIGHBOR,
	CUE_EVENING_VILLAGE,
	CUE_CONDITIONS_CHANGED,
]

const SAMPLE_RATE := 22050
const NOTE_GAP_SECONDS := 0.014

# Quiet, warm motifs for village life. The cues are original to Lorong and use
# no external assets. Each note is {start_hz, end_hz, duration, gain}.
const CUE_NOTES := {
	CUE_NPC_GREETING: [
		{"start_hz": 392.0, "end_hz": 440.0, "duration": 0.085, "gain": 0.030},
		{"start_hz": 523.0, "end_hz": 587.0, "duration": 0.105, "gain": 0.032},
	],
	CUE_NPC_CHAT: [
		{"start_hz": 247.0, "end_hz": 220.0, "duration": 0.070, "gain": 0.026},
		{"start_hz": 294.0, "end_hz": 262.0, "duration": 0.075, "gain": 0.026},
	],
	CUE_FOUND_SOMETHING: [
		{"start_hz": 392.0, "end_hz": 440.0, "duration": 0.080, "gain": 0.030},
		{"start_hz": 523.0, "end_hz": 659.0, "duration": 0.105, "gain": 0.032},
	],
	CUE_HELPED_NEIGHBOR: [
		{"start_hz": 330.0, "end_hz": 392.0, "duration": 0.085, "gain": 0.028},
		{"start_hz": 494.0, "end_hz": 587.0, "duration": 0.095, "gain": 0.030},
		{"start_hz": 659.0, "end_hz": 784.0, "duration": 0.120, "gain": 0.032},
	],
	CUE_EVENING_VILLAGE: [
		{"start_hz": 330.0, "end_hz": 294.0, "duration": 0.180, "gain": 0.020},
		{"start_hz": 392.0, "end_hz": 349.0, "duration": 0.220, "gain": 0.018},
	],
	CUE_CONDITIONS_CHANGED: [
		{"start_hz": 392.0, "end_hz": 440.0, "duration": 0.075, "gain": 0.022},
		{"start_hz": 523.0, "end_hz": 587.0, "duration": 0.095, "gain": 0.024},
	],
}

var _audio_director: Node
var _enabled := false
var _registered_streams: Dictionary = {}
var _daypart := ""
var _weather := ""
var _evening_cue_played := false


## Binds the game's audio director. Registration stays off unless [param enable]
## is explicitly true; the default configuration is therefore silent.
func configure(audio_director: Node, enable: bool = false) -> bool:
	shutdown()
	if audio_director == null or not is_instance_valid(audio_director):
		return false
	if not audio_director.has_method("get_cue_ids") \
			or not audio_director.has_method("register_stream") \
			or not audio_director.has_method("unregister_cue") \
			or not audio_director.has_method("play_cue"):
		return false

	var available_ids: Array = audio_director.call("get_cue_ids")
	for cue_id: String in CUE_IDS:
		if cue_id not in available_ids:
			return false

	_audio_director = audio_director
	return not enable or set_enabled(true)


## Enables the cue bank only after an explicit gameplay opt-in.
func set_enabled(enabled: bool) -> bool:
	if enabled == _enabled:
		return true
	if not enabled:
		_unregister_streams()
		_enabled = false
		return true
	if _audio_director == null or not is_instance_valid(_audio_director):
		return false

	for cue_id: String in CUE_IDS:
		var stream := _build_stream(CUE_NOTES[cue_id])
		if not bool(_audio_director.call("register_stream", cue_id, stream)):
			_unregister_streams()
			_enabled = false
			return false
		_registered_streams[cue_id] = stream
	_enabled = true
	if not _daypart.is_empty() and not _weather.is_empty() and _daypart != "evening":
		_play(CUE_CONDITIONS_CHANGED, _condition_pitch(_daypart, _weather))
	return true


func is_enabled() -> bool:
	return _enabled


## Call once when a nearby resident greets the player.
func greeted_npc() -> bool:
	return _play(CUE_NPC_GREETING)


## Call for a completed NPC conversation, not while dialogue is still advancing.
func finished_npc_chat() -> bool:
	return _play(CUE_NPC_CHAT)


## Call once when a clue, collectible, or useful detail is discovered.
func found_something() -> bool:
	return _play(CUE_FOUND_SOMETHING)


## Call once when helping a neighbor or completing a small village task.
func helped_neighbor() -> bool:
	return _play(CUE_HELPED_NEIGHBOR)


## Call when entering a quiet evening area; this is a short one-shot, not a loop.
func entered_evening_village() -> bool:
	if _evening_cue_played or not _play(CUE_EVENING_VILLAGE):
		return false
	_evening_cue_played = true
	return true


## Receives state from the village simulation; this helper never advances time
## or chooses weather. The first value establishes a baseline silently. Later
## valid changes play one soft cue, with pitch shaped by the resulting state.
func set_village_conditions(daypart: String, weather: String) -> bool:
	var next_daypart := daypart.strip_edges().to_lower()
	var next_weather := weather.strip_edges().to_lower()
	if next_daypart not in ["morning", "day", "evening", "night"]:
		return false
	if next_weather not in ["clear", "cloudy", "rain", "wind"]:
		return false

	var daypart_changed := next_daypart != _daypart
	var changed := daypart_changed or next_weather != _weather
	if daypart_changed and next_daypart != "evening":
		_evening_cue_played = false
	_daypart = next_daypart
	_weather = next_weather
	if not changed:
		return true
	# The dedicated evening one-shot supersedes the generic condition cue when
	# the daypart first enters evening, avoiding two overlapping transition cues.
	if _enabled and not (daypart_changed and next_daypart == "evening"):
		_play(CUE_CONDITIONS_CHANGED, _condition_pitch(next_daypart, next_weather))
	return true


## Stops and unregisters generated streams. Safe to call repeatedly.
func shutdown() -> void:
	_unregister_streams()
	_enabled = false
	_audio_director = null
	_daypart = ""
	_weather = ""
	_evening_cue_played = false


func _play(cue_id: String, pitch_scale: float = 1.0) -> bool:
	if not _enabled or _audio_director == null or not is_instance_valid(_audio_director):
		return false
	return bool(_audio_director.call("play_cue", cue_id, pitch_scale))


func _condition_pitch(daypart: String, weather: String) -> float:
	var daypart_pitch: float = float({
		"morning": 1.18,
		"day": 1.08,
		"evening": 0.96,
		"night": 0.86,
	}[daypart])
	var weather_offset: float = float({"clear": 0.04, "cloudy": 0.0, "rain": -0.06, "wind": -0.03}[weather])
	return clampf(daypart_pitch + weather_offset, 0.75, 1.35)


func _unregister_streams() -> void:
	if _audio_director != null and is_instance_valid(_audio_director):
		for cue_id: String in _registered_streams:
			_audio_director.call("unregister_cue", cue_id)
	_registered_streams.clear()


static func _build_stream(notes: Array) -> AudioStreamWAV:
	var samples := PackedByteArray()
	for index: int in notes.size():
		var note: Dictionary = notes[index]
		var wav: AudioStreamWAV = ProceduralSfx.tone(
			float(note.start_hz),
			float(note.duration),
			float(note.gain),
			float(note.end_hz),
			SAMPLE_RATE,
		)
		samples.append_array(wav.data)
		if index + 1 < notes.size():
			var silence_bytes := roundi(SAMPLE_RATE * NOTE_GAP_SECONDS) * 2
			samples.resize(samples.size() + silence_bytes)

	var stream := AudioStreamWAV.new()
	stream.format = AudioStreamWAV.FORMAT_16_BITS
	stream.mix_rate = SAMPLE_RATE
	stream.stereo = false
	stream.loop_mode = AudioStreamWAV.LOOP_DISABLED
	stream.data = samples
	return stream
