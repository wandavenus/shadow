extends SceneTree

const AtmosphereAudio = preload("res://scripts/lorong/atmosphere_audio.gd")

class RecordingAudioDirector extends Node:
	var cue_ids: Array[String] = [
		"lorong.npc_greeting",
		"lorong.npc_chat",
		"lorong.found_something",
		"lorong.helped_neighbor",
		"lorong.evening_village",
		"lorong.conditions_changed",
	]
	var streams: Dictionary = {}
	var played: Array[Dictionary] = []

	func get_cue_ids() -> Array[String]:
		return cue_ids

	func register_stream(cue_id: String, stream: AudioStream) -> bool:
		if cue_id not in cue_ids or stream == null:
			return false
		streams[cue_id] = stream
		return true

	func unregister_cue(cue_id: String) -> void:
		streams.erase(cue_id)

	func play_cue(cue_id: String, pitch_scale: float = 1.0) -> bool:
		if not streams.has(cue_id):
			return false
		played.append({"cue_id": cue_id, "pitch_scale": pitch_scale})
		return true


var _failures := PackedStringArray()
var _checks := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var director: Node = root.get_node_or_null("AudioDirector")
	_check(director != null, "AudioDirector autoload harus tersedia")
	if director == null:
		_finish()
		return

	var registered_ids: Array = director.call("get_cue_ids")
	for cue_id: String in AtmosphereAudio.CUE_IDS:
		_check(cue_id.begins_with("lorong."), "cue harus memakai namespace Lorong: " + cue_id)
		_check(cue_id in registered_ids, "AudioDirector harus mengenali " + cue_id)
		_check(not bool(director.call("play_cue", cue_id)), "cue default harus sunyi: " + cue_id)

	for cue_id: String in AtmosphereAudio.CUE_IDS:
		var notes: Array = AtmosphereAudio.CUE_NOTES[cue_id]
		var stream: AudioStreamWAV = AtmosphereAudio._build_stream(notes)
		_check(stream.data.size() > 0, "cue harus memiliki PCM: " + cue_id)
		_check(stream.format == AudioStreamWAV.FORMAT_16_BITS, "cue harus PCM 16-bit: " + cue_id)
		_check(stream.mix_rate == AtmosphereAudio.SAMPLE_RATE, "sample rate harus konsisten: " + cue_id)
		_check(not stream.stereo, "cue mono menghemat data: " + cue_id)
		_check(stream.loop_mode == AudioStreamWAV.LOOP_DISABLED, "cue satu-shot tidak boleh loop: " + cue_id)
		_check(stream.get_length() > 0.0 and stream.get_length() < 1.0, "cue harus pendek: " + cue_id)

	var helper = AtmosphereAudio.new()
	_check(bool(helper.call("configure", director)), "helper harus dapat dikonfigurasi tanpa opt-in")
	_check(not bool(helper.call("is_enabled")), "helper harus tetap nonaktif secara default")
	_check(not bool(helper.call("greeted_npc")), "sapaan nonaktif tidak boleh memutar audio")
	_check(not bool(helper.call("finished_npc_chat")), "percakapan nonaktif tidak boleh memutar audio")
	_check(not bool(helper.call("found_something")), "temuan nonaktif tidak boleh memutar audio")
	_check(not bool(helper.call("helped_neighbor")), "bantuan nonaktif tidak boleh memutar audio")
	_check(not bool(helper.call("entered_evening_village")), "suasana nonaktif tidak boleh memutar audio")

	_check(bool(helper.call("set_enabled", true)), "explicit opt-in harus mendaftarkan cue")
	_check(bool(helper.call("is_enabled")), "helper harus aktif setelah opt-in")
	_check(bool(helper.call("greeted_npc")), "cue sapaan NPC harus siap dipanggil")
	_check(bool(helper.call("finished_npc_chat")), "cue percakapan harus siap dipanggil")
	_check(bool(helper.call("found_something")), "cue temuan harus siap dipanggil")
	_check(bool(helper.call("helped_neighbor")), "cue bantuan warga harus siap dipanggil")
	_check(bool(helper.call("entered_evening_village")), "cue sore hari harus siap dipanggil")
	_check(bool(helper.call("set_enabled", true)), "aktivasi berulang harus idempotent")
	_check(bool(helper.call("set_enabled", false)), "helper harus dapat dinonaktifkan")
	_check(not bool(helper.call("is_enabled")), "helper harus nonaktif setelah dimatikan")
	_check(not bool(helper.call("found_something")), "cue harus dilepas saat dimatikan")
	_check(bool(helper.call("set_enabled", true)), "helper harus dapat diaktifkan lagi")

	helper.call("shutdown")
	_check(not bool(helper.call("is_enabled")), "shutdown harus menonaktifkan helper")
	_check(not bool(helper.call("found_something")), "shutdown harus melepas semua cue")
	helper.call("shutdown")

	var recorder := RecordingAudioDirector.new()
	root.add_child(recorder)
	var conditions_helper = AtmosphereAudio.new()
	_check(bool(conditions_helper.call("configure", recorder)), "helper harus menerima director yang sesuai kontrak")
	_check(bool(conditions_helper.call("set_village_conditions", " MORNING ", " CLEAR ")), "baseline waktu/cuaca valid harus diterima")
	_check(recorder.played.is_empty(), "baseline awal tidak boleh berbunyi")
	_check(bool(conditions_helper.call("set_enabled", true)), "helper kondisi harus dapat diaktifkan")
	_check(recorder.played.size() == 1, "opt-in harus mengumumkan ambience baseline sekali")
	_check(is_equal_approx(float(recorder.played[0].pitch_scale), 1.22), "pitch baseline mengikuti pagi cerah")
	_check(bool(conditions_helper.call("set_village_conditions", "morning", "clear")), "state identik harus diterima")
	_check(recorder.played.size() == 1, "state identik tidak boleh mengulang cue")
	_check(bool(conditions_helper.call("set_village_conditions", "day", "clear")), "transisi waktu harus diterima")
	_check(recorder.played.size() == 2, "transisi waktu harus memainkan satu cue")
	_check(recorder.played[1].cue_id == AtmosphereAudio.CUE_CONDITIONS_CHANGED, "transisi harus memakai cue khusus kondisi")
	_check(is_equal_approx(float(recorder.played[1].pitch_scale), 1.12), "pitch cue mengikuti waktu/cuaca baru")
	_check(bool(conditions_helper.call("set_village_conditions", "day", "rain")), "perubahan cuaca harus diterima")
	_check(recorder.played.size() == 3, "perubahan cuaca harus memainkan satu cue lagi")
	_check(is_equal_approx(float(recorder.played[2].pitch_scale), 1.02), "cuaca hujan menurunkan pitch secara halus")
	_check(not bool(conditions_helper.call("set_village_conditions", "dawn", "rain")), "daypart tak dikenal harus ditolak")
	_check(not bool(conditions_helper.call("set_village_conditions", "day", "snow")), "cuaca tak dikenal harus ditolak")
	_check(recorder.played.size() == 3, "state invalid tidak boleh memicu cue")
	_check(bool(conditions_helper.call("set_village_conditions", "evening", "rain")), "transisi sore harus diterima")
	_check(recorder.played.size() == 3, "transisi sore menunggu cue khusus, tanpa cue kondisi bertumpuk")
	_check(bool(conditions_helper.call("entered_evening_village")), "transisi sore harus memainkan cue khusus")
	_check(recorder.played.size() == 4, "cue khusus sore hanya diputar satu kali")
	_check(recorder.played[3].cue_id == AtmosphereAudio.CUE_EVENING_VILLAGE, "transisi sore memakai cue desa sore")
	_check(not bool(conditions_helper.call("entered_evening_village")), "pemanggilan sore duplikat harus diabaikan")
	_check(recorder.played.size() == 4, "pemanggilan sore duplikat tidak boleh menumpuk cue")
	_check(bool(conditions_helper.call("set_village_conditions", "night", "rain")), "keluar dari sore harus diterima")
	_check(recorder.played.size() == 5, "peralihan ke malam memakai cue kondisi biasa")
	_check(bool(conditions_helper.call("set_village_conditions", "evening", "rain")), "masuk sore berikutnya harus diterima")
	_check(recorder.played.size() == 5, "sore baru juga menunggu cue khusus")
	_check(bool(conditions_helper.call("entered_evening_village")), "sore berikutnya harus dapat berbunyi lagi")
	_check(recorder.played.size() == 6, "setiap transisi sore baru memutar tepat satu cue")
	_check(not bool(conditions_helper.call("entered_evening_village")), "duplikasi sore kedua juga harus diabaikan")
	_check(recorder.played.size() == 6, "sore kedua tetap tidak boleh menumpuk cue")
	conditions_helper.call("shutdown")
	_check(recorder.streams.is_empty(), "shutdown harus melepas cue dari director")
	recorder.queue_free()
	await process_frame

	if _failures.is_empty():
		print("[atmosphere-audio-tests] PASS: %d checks" % _checks)
	else:
		for failure: String in _failures:
			push_error("[atmosphere-audio-tests] " + failure)
		print("[atmosphere-audio-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])

	director.call("release_streams")
	await process_frame
	quit(0 if _failures.is_empty() else 1)


func _finish() -> void:
	for failure: String in _failures:
		push_error("[atmosphere-audio-tests] " + failure)
	print("[atmosphere-audio-tests] FAIL: %d failures across %d checks" % [_failures.size(), _checks])
	quit(1)


func _check(condition: bool, message: String) -> void:
	_checks += 1
	if not condition:
		_failures.append(message)
