class_name DeferredTask

# 10ms in μs
const IDLE_TIME = 10000
const INVALID_TASK = -9223372036854775808


static var tasks: Dictionary[int, Callable]:
	get: return Instance.instance.tasks
static var new_task_id := INVALID_TASK + 1
static var use_deferred_tasks: bool = true


static func process_tasks() -> void:
	if Instance.instance.tasks.size() > 0:
		var start_time := Time.get_ticks_usec()
		for task_id in Instance.instance.tasks.keys():
			Instance.instance.tasks[task_id].call()
			Instance.instance.tasks.erase(task_id)
			if Time.get_ticks_usec() - start_time > IDLE_TIME and use_deferred_tasks:
				break


static func create(task: Callable) -> int:
	if true: # back to queueing
		Instance.instance.tasks[new_task_id] = task
		new_task_id += 1
		return new_task_id
	else:
		task.call()
		return INVALID_TASK


static func cancel(task_id: int) -> void:
	Instance.instance.tasks.erase(task_id)


class Instance extends Object:
	static func _static_init() -> void:
		instance = new()
	static var instance: Instance
	var tasks: Dictionary[int, Callable]
