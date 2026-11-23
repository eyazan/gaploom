class_name InputAdapter
extends RefCounted
## Normalizes mouse and touch into one-finger pointer events:
## {"kind": "press"|"move"|"release", "pos": Vector2}. Returns {} for anything else.
##
## The first finger that goes down becomes the *primary* touch, whatever its index.
## iOS Safari reports large, non-zero touch identifiers, so "index == 0" must never be
## assumed (that bug made the web build unplayable on iPhone in v0.3.0).
## Touch-emulated mouse events are ignored so touch is never handled twice.

static var primary := -1


static func reset() -> void:
	primary = -1


static func convert(event: InputEvent) -> Dictionary:
	if event is InputEventScreenTouch:
		var t := event as InputEventScreenTouch
		if t.pressed:
			if primary == -1 or primary == t.index:
				primary = t.index
				return {"kind": "press", "pos": t.position}
			return {}
		if t.index != primary:
			return {}
		primary = -1
		return {"kind": "release", "pos": t.position}
	if event is InputEventScreenDrag:
		var d := event as InputEventScreenDrag
		if d.index != primary:
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
