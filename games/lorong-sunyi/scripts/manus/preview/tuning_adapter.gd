extends "res://scripts/manus/preview/tuning_transport.gd"

func store() -> Variant:
	return get_node_or_null("/root/TuningStore")

func settings() -> Array:
	return store().get_settings()

func requested(setting: Dictionary) -> Variant:
	return store().get_requested_value(str(setting.id))

func active(setting: Dictionary) -> Variant:
	return store().get_active_value(str(setting.id))

func commit(patch: Dictionary) -> bool:
	return store().set_values(patch, false)

func control_for(setting: Dictionary) -> Dictionary:
	var localized := setting.duplicate(true)
	localized["category_key"] = "tuning.category." + str(setting.category).to_lower()
	var control: Dictionary = super.control_for(localized)
	var apply_mode := str(control.get("applyMode", "LIVE"))
	if apply_mode != "LIVE":
		var description_key := str(setting.get("description_key", ""))
		var description := str(translate(description_key)) if not description_key.is_empty() else ""
		var timing := str(translate("tuning.apply." + apply_mode))
		control["description"] = (description + " " + timing).strip_edges()
	return control
