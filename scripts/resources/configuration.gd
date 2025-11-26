## Represents a set of serializable, editable parameters in the
## ["scripts/autoload/settings/settings.gd"] window. Use exported properties as usual to
## expose setting options.
## [br]
## All [Configuration]s must be registered to the [PluginManager] in the static initializer before
## use:
## [codeblock]
## static func _static_init() -> void:
## 	PluginManager.register_configuration(new())
## [/codeblock]
@abstract class_name Configuration extends Resource

enum Location {
	## This configuration object is for settings that should be saved to
	## [member "scripts/autoload/settings/settings.gd".config_path].
	## This is normally used for a configuration that only contains
	## [annotation @GDScript.export] variables, or contains a mix of [annotation @GDScript.export]
	## and [annotation @GDScript.export_storage] variables.
	CONFIG,
	## This configuration object is for local state that should be saved to
	## [member "scripts/autoload/settings/settings.gd".local_path].
	## This is normally used for a configuration that only contains
	## [annotation @GDScript.export_storage] variables.
	LOCAL,
}

## Returns a reverse-DNS style identifier unique to this Configuration type.
@abstract func get_id() -> StringName

## Returns a [enum Location] as a hint to where ["scripts/autoload/settings/settings.gd"] should
## save this configuration to.
func get_location() -> Location: return Location.CONFIG
