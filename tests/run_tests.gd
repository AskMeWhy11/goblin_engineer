extends SceneTree
## Headless test runner: godot --headless --path . --script res://tests/run_tests.gd
## Optional filter: set env TEST_FILTER to a substring of the test file name.

const TEST_DIR := "res://tests"


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var passed := 0
	var failed := 0
	var filter := OS.get_environment("TEST_FILTER")
	var files := Array(DirAccess.get_files_at(TEST_DIR))
	files.sort()
	for file: String in files:
		if not (file.begins_with("test_") and file.ends_with(".gd")) or file == "test_case.gd":
			continue
		if not filter.is_empty() and not file.contains(filter):
			continue
		var script: GDScript = load(TEST_DIR + "/" + file)
		if script == null or not script.can_instantiate():
			print("FAIL %s: cannot load script" % file)
			failed += 1
			continue
		for method in script.get_script_method_list():
			var method_name: String = method.name
			if not method_name.begins_with("test_"):
				continue
			var test: TestCase = script.new()
			test.tree = self
			await test.call(method_name)
			var label := "%s::%s" % [file, method_name]
			if test.assert_count == 0:
				test.failures.append("no assertions ran")
			if test.failures.is_empty():
				print("PASS %s" % label)
				passed += 1
			else:
				for f in test.failures:
					print("FAIL %s: %s" % [label, f])
				failed += 1
	print("%d passed, %d failed" % [passed, failed])
	quit(1 if failed > 0 else 0)
