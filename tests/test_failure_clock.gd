extends TestCase

const DT := 1.0 / 60.0


func _time_to_fail(clock: FailureClock, key: int, load: float, limit := 100000.0) -> float:
	var t := 0.0
	while t < limit:
		if clock.tick(key, load, DT) != FailureMode.NONE:
			return t
		t += DT
	return -1.0


func test_mean_time_matches_rate_at_load_one() -> void:
	var clock := FailureClock.new(12345)
	var sum := 0.0
	for k in 2000:
		clock.register(k, Vector3(0, 0.1, 0), 3.0)
		sum += _time_to_fail(clock, k, 1.0)
	assert_almost(sum / 2000.0, 10.0, 1.0)


func test_margin_does_not_change_rate_at_load_one() -> void:
	var a := FailureClock.new(7)
	var b := FailureClock.new(7)
	a.register(1, Vector3(0, 0.2, 0), 0.5)
	b.register(1, Vector3(0, 0.2, 0), 8.0)
	assert_almost(_time_to_fail(a, 1, 1.0), _time_to_fail(b, 1, 1.0), 2.0 * DT)


func test_same_seed_same_result() -> void:
	var a := FailureClock.new(99)
	var b := FailureClock.new(99)
	a.register(1, Vector3(0.05, 0.05, 0.05), 2.0)
	b.register(1, Vector3(0.05, 0.05, 0.05), 2.0)
	var ta := _time_to_fail(a, 1, 1.0)
	assert_true(ta >= 0.0)
	assert_eq(ta, _time_to_fail(b, 1, 1.0))


func test_no_load_no_fatigue() -> void:
	var clock := FailureClock.new(1)
	clock.register(1, Vector3(1, 1, 1), 1.0)
	assert_eq(_time_to_fail(clock, 1, 0.0, 1000.0), -1.0)


func test_huge_shock_fails_immediately_with_heaviest_mode() -> void:
	var clock := FailureClock.new(1)
	clock.register(1, Vector3(0.01, 0.01, 0.01), 5.0)
	assert_eq(clock.tick(1, 1e9, DT), FailureMode.EXPLODE)


func test_zero_rate_mode_never_fires() -> void:
	var clock := FailureClock.new(1)
	clock.register(1, Vector3(0.01, 0.01, 0.0), 5.0)
	assert_eq(clock.tick(1, 1e9, DT), FailureMode.BREAK)


func test_all_zero_rates_never_fail() -> void:
	var clock := FailureClock.new(1)
	clock.register(1, Vector3.ZERO, 5.0)
	assert_eq(clock.tick(1, 1e9, DT), FailureMode.NONE)


func test_break_unregisters_malfunction_does_not() -> void:
	var clock := FailureClock.new(1)
	clock.register(1, Vector3(0.01, 0, 0), 5.0)
	clock.register(2, Vector3(0, 0.01, 0), 5.0)
	assert_eq(clock.tick(1, 1e9, DT), FailureMode.MALFUNCTION)
	assert_eq(clock.tick(2, 1e9, DT), FailureMode.BREAK)
	assert_true(clock.is_registered(1))
	assert_true(not clock.is_registered(2))
	assert_eq(clock.tick(1, 1e9, DT), FailureMode.NONE)


func test_weaker_shock_breaks_cheap_part_sooner() -> void:
	var cheap := 0
	var solid := 0
	for s in 500:
		var c := FailureClock.new(s)
		c.register(1, Vector3(0, 0.01, 0), 0.8)
		var g := FailureClock.new(s)
		g.register(1, Vector3(0, 0.01, 0), 8.0)
		if c.tick(1, 3.0, DT) != FailureMode.NONE:
			cheap += 1
		if g.tick(1, 3.0, DT) != FailureMode.NONE:
			solid += 1
	assert_true(cheap > solid * 3, "cheap=%d solid=%d" % [cheap, solid])


func test_tick_unknown_key_returns_none() -> void:
	assert_eq(FailureClock.new(1).tick(42, 1.0, DT), FailureMode.NONE)
