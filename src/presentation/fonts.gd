class_name Fonts
extends RefCounted
## Brand typography: Nunito (SIL Open Font License 1.1, assets/fonts/OFL-Nunito.txt).
## Latin-ext files are attached as fallbacks so Turkish letters (ş ğ ı İ) render.

static var ui: Font
static var title: Font


static func _load(weight: int) -> FontFile:
	var main: FontFile = load("res://assets/fonts/nunito-latin-%d-normal.woff2" % weight)
	var ext: FontFile = load("res://assets/fonts/nunito-latin-ext-%d-normal.woff2" % weight)
	if main == null:
		return null
	if ext != null:
		main.fallbacks = [ext]
	return main


## Installs the brand fonts as the project-wide fallback font. Returns false if missing.
static func install() -> bool:
	var f := _load(700)
	if f == null:
		return false
	ui = f
	var t := _load(800)
	title = t if t != null else f
	ThemeDB.fallback_font = ui
	return true
