extends Node

signal locale_changed(locale: String)

const GAME_LOCALE := "id-ID"
const CATALOG_PATHS := {
	"id-ID": "res://localization/id-ID.json"
}

var _catalogs: Dictionary = {}
var _locale := GAME_LOCALE


func _ready() -> void:
	for locale: String in CATALOG_PATHS:
		_catalogs[locale] = _load_catalog(str(CATALOG_PATHS[locale]))
	# Game language is intentionally pinned; do not consult save, OS, browser, or device locale.
	_locale = GAME_LOCALE


static func detect_locale(_os_locale: String) -> String:
	return GAME_LOCALE


static func resolve_locale(_saved: String, _os_locale: String) -> String:
	return GAME_LOCALE


func _load_catalog(path: String) -> Dictionary:
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null:
		push_error("I18n: missing catalog " + path)
		return {}
	var parsed: Variant = JSON.parse_string(file.get_as_text())
	file.close()
	if not parsed is Dictionary:
		push_error("I18n: invalid catalog " + path)
		return {}
	return parsed


func text(key: String, replacements: Dictionary = {}) -> String:
	var active: Dictionary = _catalogs.get(GAME_LOCALE, {})
	var result := str(active.get(key, key))
	for token: Variant in replacements:
		result = result.replace("{%s}" % str(token), str(replacements[token]))
	return result


func t(key: String, replacements: Dictionary = {}) -> String:
	return text(key, replacements)


func get_locale() -> String:
	return GAME_LOCALE


func set_locale(locale: String) -> void:
	# Kept for compatibility with shared helpers; there is no player-facing language switch.
	if locale != GAME_LOCALE or _locale == GAME_LOCALE:
		return
	_locale = GAME_LOCALE
	locale_changed.emit(GAME_LOCALE)


func toggle_locale() -> void:
	# Intentionally unavailable in this single-language game.
	return


func catalog_keys(locale: String) -> Array:
	if locale != GAME_LOCALE:
		return []
	return (_catalogs.get(GAME_LOCALE, {}) as Dictionary).keys()
