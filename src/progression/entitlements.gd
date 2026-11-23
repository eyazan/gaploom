class_name Entitlements
extends RefCounted
## Free vs full game. The commercial plan is "first world free, the rest with a one-time
## unlock". No store purchase is implemented yet (needs the owner's Apple Developer account
## and StoreKit); until then every build is a full build unless the project setting
## gaploom/demo_build is true.

const FREE_LAST_LEVEL := 10
const SETTING := "gaploom/demo_build"


static func is_full_version() -> bool:
	return not bool(ProjectSettings.get_setting(SETTING, false))


static func level_available(n: int) -> bool:
	return is_full_version() or n <= FREE_LAST_LEVEL
