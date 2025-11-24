class_name AppInfoContainer extends Resource

const VERSION = "1.0"
const LICENSE = """Copyright (c) 2025 sockeye-d

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitation the rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
"""
@export_storage var git_hash: String:
	get:
		if git_hash.is_empty() and OS.has_feature("editor"):
			git_hash = get_git_hash()
		return git_hash


var git_hash_short: String:
	get:
		return git_hash.substr(0, 7)


static func get_shell_arguments(working_dir: String) -> PackedStringArray:
	match OS.get_name():
		"Linux", "macOS", "FreeBSD", "NetBSD", "OpenBSD", "BSD":
			return ["sh", "-c", "cd '%s' && git rev-parse HEAD" % working_dir]
		"Windows":
			return ["cmd.exe", "/C", "cd '%s' && git rev-parse HEAD" % working_dir]
		"Android":
			assert(false, "Android is not supported!")
			return []
		"iOS":
			assert(false, "iOS is not supported!")
			return []
		"Web":
			assert(false, "Web is not supported!")
			return []
	return []


static func get_git_hash() -> String:
	var wd := ProjectSettings.globalize_path("res://")
	var output: Array[String] = []
	var args := get_shell_arguments(wd)
	OS.execute(args[0], args.slice(1), output, true)
	return output[0].strip_edges()
