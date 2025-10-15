#include "register_types.h"

using namespace godot;

void initialize_sunfish(const ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}

	GDREGISTER_CLASS(StreamPeerFile)
	GDREGISTER_CLASS(DrawingUtil)
}

void uninitialize_sunfish(const ModuleInitializationLevel p_level) {
	if (p_level != MODULE_INITIALIZATION_LEVEL_SCENE) {
		return;
	}
}

extern "C" {
GDExtensionBool GDE_EXPORT sunfish_init(GDExtensionInterfaceGetProcAddress p_get_proc_address,
										const GDExtensionClassLibraryPtr p_library,
										GDExtensionInitialization* r_initialization) {
	const GDExtensionBinding::InitObject init_obj(p_get_proc_address, p_library, r_initialization);

	init_obj.register_initializer(initialize_sunfish);
	init_obj.register_terminator(uninitialize_sunfish);
	init_obj.set_minimum_library_initialization_level(MODULE_INITIALIZATION_LEVEL_SCENE);

	return init_obj.init();
}
}
