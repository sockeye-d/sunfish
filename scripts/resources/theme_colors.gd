@tool
class_name ThemeColors extends Resource

## The lightest background color
@export var background_0: Color

## The middle background color
@export var background_1: Color

## The darkest background color
@export var background_2: Color

## Background color of surface elements like cards and buttons
@export var surface: Color
## Background color of hovered surface elements like cards and buttons
@export var surface_hover: Color
## Background color of pressed surface elements like cards and buttons
@export var surface_press: Color

## Color of overlay elements
@export var overlay: Color
## Color of hovered overlay elements
@export var overlay_hover: Color
## Color of pressed overlay elements
@export var overlay_press: Color

## Plain text color, also used for icons
@export var text: Color
## Subtle text color
@export var subtext: Color

## Accent color 1
@export var accent_0: Color
## Accent color 2
@export var accent_1: Color

## A color for error messages, normally red
@export var error: Color
## A color for warning messages, normally yellow
@export var warning: Color
## A color for positive messages, normally green
@export var success: Color

## The reverse-DNS identifier of this theme
@export var id: String:
	set(value):
		ThemeManager.unregister_theme(id)
		id = value
		ThemeManager.register_theme(self)

## The name of this theme
@export var name: String


func _property_can_revert(property: StringName) -> bool:
	return property in [&"id", &"name"]


func _property_get_revert(property: StringName) -> Variant:
	if property == &"id":
		return ReverseDNSUtil.get_resource_id(self)
	if property == &"name":
		return ReverseDNSUtil.tail(id).capitalize()
	return null


func _set(property: StringName, value: Variant) -> bool:
	Util.unused(value)
	if property not in [&"id"]:
		emit_changed.call_deferred()
	return false
