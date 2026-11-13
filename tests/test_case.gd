class_name TestCase
extends RefCounted
## Base class for headless tests. Methods named test_* are run by tests/run_tests.gd.

var failures: Array[String] = []
var assert_count := 0
## Set by the runner; tests that need nodes add them under tree.root.
var tree: SceneTree


func assert_true(cond: bool, msg := "") -> void:
	assert_count += 1
	if not cond:
		failures.append("expected true" + _suffix(msg))


func assert_eq(actual: Variant, expected: Variant, msg := "") -> void:
	assert_count += 1
	if typeof(actual) != typeof(expected) or actual != expected:
		failures.append("expected %s, got %s%s" % [str(expected), str(actual), _suffix(msg)])


func assert_almost(actual: float, expected: float, tolerance: float, msg := "") -> void:
	assert_count += 1
	if absf(actual - expected) > tolerance:
		failures.append("expected %s ± %s, got %s%s" % [expected, tolerance, actual, _suffix(msg)])


func _suffix(msg: String) -> String:
	return "" if msg.is_empty() else " (" + msg + ")"
