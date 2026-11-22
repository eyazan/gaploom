class_name InputAdapter
extends RefCounted
## Normalizes mouse and touch into one-finger pointer events:
## {"kind": "press"|"move"|"release", "pos": Vector2}. Returns {} for anything else.
## Touch-emulated mouse events are ignored so touch is never handled twice.


static func convert(event: InputEvent) -> Dictionary:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.index != 0:
			return {}
		return {"kind": "press" if t.pressed else "release", "pos": t.position}
	if event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index != 0:
			return {}
		return {"kind": "move", "pos": d.position}
	if event is InputEventMouseButton:
		var b := event as InputEventMouseButton
		if b.device == InputEvent.DEVICE_ID_EMULATION or b.button_index != MOUSE_BUTTON_LEFT:
			return {}
		return {"kind": "press" if b.pressed else "release", "pos": b.position}
	if event is InputEventMouseMotion:
		var m := event as InputEventMouseMotion
		if m.device == InputEvent.DEVICE_ID_EMULATION:
			return {}
		return {"kind": "move", "pos": m.position}
	return {}
