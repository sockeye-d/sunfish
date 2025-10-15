#pragma once

#include <gdextension_interface.h>
#include <godot_cpp/core/class_db.hpp>
#include <godot_cpp/core/defs.hpp>
#include <godot_cpp/godot.hpp>

#include "drawing_util.h"
#include "stream_peer_file.h"

using namespace godot;

void initialize_sled(ModuleInitializationLevel p_level);
void uninitialize_sled(ModuleInitializationLevel p_level);
