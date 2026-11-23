class_name VoidProperty
extends RefCounted
## Functional families carried by gaps. A gap is not "nothing": it is a
## selective opening. Each family passes only its own force and can only be
## sent to where that force is currently pressing against solid material.

const Mat = LevelDefinition.Mat

enum Family { LIGHT, MOTION }


static func family_of(mat: int) -> int:
	if mat == Mat.LIGHT_GAP or mat == Mat.LIGHT_RED or mat == Mat.LIGHT_BLUE:
		return Family.LIGHT
	if mat == Mat.MOTION_GAP:
		return Family.MOTION
	return -1


static func mat_of(family: int) -> int:
	return Mat.LIGHT_GAP if family == Family.LIGHT else Mat.MOTION_GAP


static func passes_light(mat: int) -> bool:
	return mat == Mat.NONE or mat == Mat.LIGHT_GAP or mat == Mat.LIGHT_RED or mat == Mat.LIGHT_BLUE


## Hue of light after passing a cell, or -1 if the cell blocks it.
## Clear glass/air keep the hue; tinted glass turns white or same-hue light into its hue
## and blocks the other hue.
static func filter_hue(mat: int, hue: int) -> int:
	const Hue = LevelDefinition.Hue
	if mat == Mat.NONE or mat == Mat.LIGHT_GAP:
		return hue
	if mat == Mat.LIGHT_RED:
		return Hue.RED if hue != Hue.BLUE else -1
	if mat == Mat.LIGHT_BLUE:
		return Hue.BLUE if hue != Hue.RED else -1
	return -1


static func passes_motion(mat: int) -> bool:
	return mat == Mat.NONE or mat == Mat.MOTION_GAP


static func family_name(family: int) -> String:
	return "light" if family == Family.LIGHT else "motion"
