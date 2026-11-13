# Goblin Engineer Prototype Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Играбельный 3D-прототип конструктора машин, где детали удешевляются ценой риска отказа, а уровень требует риск не ниже порога.

**Architecture:** Данные в ресурсах Godot, чистая логика без узлов (покрыта тестами), над ней слой симуляции: каждая деталь — `RigidBody3D`, соседи скреплены соединениями Jolt. Весь код вне машины работает только через интерфейс `Machine`. Режимы сборки и симуляции переключаются внутри одной сцены уровня.

**Tech Stack:** Godot 4.7.2 stable, GDScript, Jolt Physics 3D, собственный запускатор тестов без окна.

**Spec:** `docs/superpowers/specs/2026-11-13-goblin-engineer-prototype-design.md`

## Global Constraints

- Движок: `D:\godot_prjct\Godot_v4.7.2-stable_win64.exe`. Он не в PATH и это оконное приложение: из PowerShell запускать только через `tools/run_tests.ps1` или `Start-Process -Wait`.
- Только GDScript. Сторонних аддонов нет.
- Физика 3D — Jolt (`physics/3d/physics_engine = "Jolt Physics"`).
- Сетка сборки: шаг 1 м, деталь занимает одну клетку, ядро в клетке `(0,0,0)`.
- Веса отказов: выход из строя 1/3, поломка 1/2, взрыв 1.
- Зависимости только вниз: `src/logic` не использует узлы; `src/sim` не использует `src/ui` и `src/build`.
- Код вне `src/sim/machine.gd` и `src/sim/machine_assembler.gd` не трогает `Joint3D`.
- Все числа баланса живут в `tools/part_table.gd`, `data/levels/*.tres` и `src/sim/sim_tuning.gd`. В остальном коде чисел баланса нет.
- Идентификаторы в коде английские, тексты интерфейса русские.
- Графика: примитивы и плоские цвета. Сохранения на диск нет.
- Каждая задача заканчивается коммитом. Сообщения коммитов заканчиваются строкой `Co-Authored-By: Claude Fable 5.2 <noreply@anthropic.com>`.

## Review Focus

1. **Запуск машины из одного ядра.** Риск 0 ниже порога: запуск заблокирован с причиной, без ошибок (тест в задаче 4).
2. **Удаление детали, на которой держится часть машины.** Удаление отклоняется, машина остаётся связной (тест в задаче 6).
3. **Вид отказа с нулевой частотой при огромном ударе.** Не срабатывает никогда: блок не взрывается даже от нагрузки `1e9` (тест в задаче 5).
4. **Цепная детонация по кругу.** Бочка A подрывает B, B снова задевает A: каждая деталь взрывается ровно один раз, рекурсии нет (тест в задаче 14).
5. **Возврат в сборку посреди событий.** Отложенная детонация, летящее ядро пушки или отказ в том же кадре, что и выход из симуляции, не дают ошибок обращения к удалённым узлам (тест в задаче 14, ручная проверка в задаче 11).

---

## File Structure

```
project.godot, .gitignore, export_presets.cfg
tools/run_tests.ps1            запуск тестов из PowerShell
tools/part_table.gd            таблица баланса деталей (единственный источник)
tools/generate_parts.gd        пишет data/parts/*.tres из таблицы
tests/test_case.gd             базовый класс теста
tests/run_tests.gd             запускатор
tests/test_*.gd                тесты
src/data/failure_mode.gd       FailureMode
src/data/quality_tier.gd       QualityTier
src/data/part_def.gd           PartDef
src/data/level_def.gd          LevelDef
src/data/blueprint.gd          Blueprint, BlueprintEntry
src/logic/orientations.gd      Orientations (24 поворота)
src/logic/risk_calculator.gd   RiskCalculator, RiskReport
src/logic/failure_clock.gd     FailureClock
src/logic/blueprint_rules.gd   BlueprintRules
src/core/game.gd               автозагрузка Game
src/core/part_catalog.gd       автозагрузка PartCatalog
src/core/level_session.gd      сцена уровня: переключение режимов
src/sim/sim_tuning.gd          SimTuning — константы физики и урона
src/sim/part_body.gd           PartBody
src/sim/parts/*.gd             поведения типов деталей
src/sim/machine.gd             Machine
src/sim/machine_assembler.gd   MachineAssembler
src/sim/failure_system.gd      FailureSystem
src/sim/machine_controller.gd  MachineController
src/sim/pilot.gd               Pilot
src/sim/objectives/*.gd        Objective и три наследника
src/sim/destructible.gd        Destructible (постройка-цель)
src/build/build_mode.gd        редактор
src/build/build_camera.gd, src/sim/follow_camera.gd
src/ui/*.gd, scenes/ui/*.tscn  меню, HUD, пауза, итог
scenes/parts/*.tscn, scenes/levels/*.tscn, scenes/level_session.tscn
data/parts/*.tres, data/levels/*.tres
spikes/joint_stress/           проверка физики (задача 2)
```

---

### Task 1: Каркас проекта и запуск тестов

**Files:**
- Create: `project.godot`, `.gitignore`, `tools/run_tests.ps1`, `tests/test_case.gd`, `tests/run_tests.gd`, `tests/test_smoke.gd`

**Interfaces:**
- Produces:
  - `class_name TestCase extends RefCounted` с методами `assert_true(cond: bool, msg := "")`, `assert_eq(actual, expected, msg := "")`, `assert_almost(actual: float, expected: float, tolerance: float, msg := "")`, полем `failures: Array[String]`.
  - `tests/run_tests.gd` (`extends SceneTree`): находит `tests/test_*.gd`, создаёт экземпляр, вызывает все методы с префиксом `test_`, печатает `PASS`/`FAIL имя: сообщение`, итог `N passed, M failed`, завершает процесс кодом 0 или 1.
  - `tools/run_tests.ps1`: запускает движок, ждёт завершения, выводит журнал, возвращает его код выхода.

- [ ] **Step 1:** Создать `project.godot`: имя «Goblin Engineer», `config/features` для 4.7, `physics/3d/physics_engine="Jolt Physics"`, окно 1600×900. `.gitignore`: `.godot/`, `build/`, `*.log`.

- [ ] **Step 2:** Написать `tools/run_tests.ps1`:

```powershell
$godot = "D:\godot_prjct\Godot_v4.7.2-stable_win64.exe"
$log = Join-Path $PSScriptRoot "..\tests\last_run.log"
$p = Start-Process $godot -ArgumentList "--headless","--path","$PSScriptRoot\..","--script","res://tests/run_tests.gd","--log-file",$log -Wait -PassThru
Get-Content $log
exit $p.ExitCode
```

- [ ] **Step 3:** Написать `tests/test_smoke.gd` с одним тестом `test_runner_works` (`assert_eq(1 + 1, 2)`) и вторым, временным, `test_runner_reports_failure` (`assert_eq(1, 2)`).

- [ ] **Step 4:** Реализовать `TestCase` и `run_tests.gd`.

- [ ] **Step 5:** Запустить `powershell -File tools/run_tests.ps1`. Ожидается: `1 passed, 1 failed`, код выхода 1. Удалить `test_runner_reports_failure`, запустить снова: `1 passed, 0 failed`, код 0.

- [ ] **Step 6:** Коммит (включая `docs/`): `chore: project skeleton and headless test runner`.

---

### Task 2: Проверка физики (шлюз)

Отвечает на вопрос: держат ли соединения Jolt машину из ~80 тел. Код в `spikes/` одноразовый и в игру не переносится.

**Files:**
- Create: `spikes/joint_stress/joint_stress.tscn`, `spikes/joint_stress/joint_stress.gd`
- Create: `src/sim/sim_tuning.gd`
- Modify: `project.godot` (настройки физики)

**Interfaces:**
- Produces: `class_name SimTuning` с константами `PHYSICS_TICKS: int`, `JOINT_KIND: StringName` и найденными параметрами соединения. Задача 11 берёт соединение отсюда.

- [ ] **Step 1:** Скрипт сцены строит: плоскость 200×20 м с порогом высотой 0.3 м на отметке 15 м; шасси 4×2×10 = 80 кубов 1 м по 5 кг, каждый `RigidBody3D`; между соседями по граням `Generic6DOFJoint3D` со всеми осями запертыми и `exclude_nodes_from_collision = true`; 4 колеса-цилиндра по 12 кг на `HingeJoint3D` с включённым мотором.

- [ ] **Step 2:** Скрипт измеряет каждый тик: наибольшее отклонение расстояния между соседними блоками от 1 м (`max_gap`), время физического шага, пройденный путь. Через 20 с печатает три числа и завершает сцену.

- [ ] **Step 3:** Запустить в редакторе. Критерии прохождения: `max_gap < 0.10` м, средний физический шаг `< 8` мс, путь `≥ 30` м, машина не развалилась и не «взорвалась» численно.

- [ ] **Step 4:** Если не прошло, пробовать по порядку и перемерять: (а) 120 физических тиков в секунду; (б) увеличить число шагов решателя в Project Settings → Physics → Jolt Physics 3D (точные имена параметров взять из редактора); (в) добавить соединения по диагонали между блоками, имеющими общее ребро.

- [ ] **Step 5:** Записать прошедшую конфигурацию в `SimTuning` и `project.godot`, результаты измерений — в комментарий в начале `sim_tuning.gd`.

- [ ] **Step 6:** **Шлюз.** Если ни одна конфигурация не прошла — остановиться и вернуться к автору: подход «тело на блок» пересматривается до начала остальных задач.

- [ ] **Step 7:** Коммит: `spike: validate Jolt joints for 80-body machine`.

---

### Task 3: Классы данных

**Files:**
- Create: `src/data/failure_mode.gd`, `src/data/quality_tier.gd`, `src/data/part_def.gd`, `src/data/level_def.gd`, `src/data/blueprint.gd`, `src/logic/orientations.gd`
- Test: `tests/test_blueprint.gd`, `tests/test_orientations.gd`

**Interfaces:**
- Produces:

```gdscript
class_name FailureMode
enum { MALFUNCTION = 0, BREAK = 1, EXPLODE = 2 }
const NONE := -1
const WEIGHTS: Array[float] = [1.0 / 3.0, 0.5, 1.0]

class_name QualityTier extends Resource
@export var display_name: String
@export var price_mult: float
@export var rates: Vector3            # x выход из строя, y поломка, z взрыв; доля в секунду
@export var strength_margin: float    # S

class_name PartDef extends Resource
enum Activation { NONE, HOLD, PRESS }
@export var id: StringName
@export var display_name: String
@export var scene: PackedScene
@export var base_price: int
@export var mass: float
@export var tiers: Array[QualityTier]
@export var activation: Activation
@export var always_loaded: bool
@export var default_key_positive: Key
@export var default_key_negative: Key
@export var attach_faces: Array[Vector3i]   # локальные нормали; пусто = все шесть
@export var explosion_power: float          # импульс, Н·с; 0 = не взрывается
@export var explosion_radius: float
@export var removable: bool = true
func price(tier: int) -> int                # roundi(base_price * tiers[tier].price_mult)

class_name LevelDef extends Resource
@export var id: StringName
@export var title: String
@export var task_text: String
@export var scene: PackedScene
@export var budget: int
@export var risk_min: float                 # взрывных эквивалентов в секунду
@export var allowed_parts: Array[StringName]
@export var volume_min: Vector3i
@export var volume_max: Vector3i            # включительно

class_name BlueprintEntry extends RefCounted
var part_id: StringName; var cell: Vector3i; var orientation: int; var tier: int
var key_positive: Key; var key_negative: Key; var inverted: bool

class_name Blueprint extends RefCounted
const CORE_ID := &"core"
var entries: Array[BlueprintEntry]
static func with_core() -> Blueprint        # одна запись: ядро в (0,0,0)
func get_at(cell: Vector3i) -> BlueprintEntry   # null, если пусто
func add(entry: BlueprintEntry) -> void
func remove_at(cell: Vector3i) -> void
func clear() -> void                        # оставляет только ядро

class_name Orientations
const COUNT := 24
static func basis(index: int) -> Basis
static func rotated(index: int, axis: Vector3i) -> int   # поворот на 90° вокруг мировой оси
static func world_normal(index: int, local_normal: Vector3i) -> Vector3i
```

- [ ] **Step 1:** Написать тесты:

```gdscript
# tests/test_blueprint.gd
func test_with_core_has_single_core_at_origin():
    var bp := Blueprint.with_core()
    assert_eq(bp.entries.size(), 1)
    assert_eq(bp.get_at(Vector3i.ZERO).part_id, Blueprint.CORE_ID)

func test_add_get_remove():
    var bp := Blueprint.with_core()
    var e := BlueprintEntry.new(); e.part_id = &"block"; e.cell = Vector3i(1, 0, 0)
    bp.add(e)
    assert_eq(bp.get_at(Vector3i(1, 0, 0)), e)
    bp.remove_at(Vector3i(1, 0, 0))
    assert_eq(bp.get_at(Vector3i(1, 0, 0)), null)

func test_clear_keeps_core():
    var bp := Blueprint.with_core()
    var e := BlueprintEntry.new(); e.part_id = &"block"; e.cell = Vector3i(0, 1, 0)
    bp.add(e); bp.clear()
    assert_eq(bp.entries.size(), 1)
    assert_eq(bp.entries[0].part_id, Blueprint.CORE_ID)

# tests/test_orientations.gd
func test_all_24_bases_are_distinct_rotations():
    var seen := {}
    for i in Orientations.COUNT:
        var b := Orientations.basis(i)
        assert_almost(b.determinant(), 1.0, 0.001)
        seen[str(b.x.round()) + str(b.y.round())] = true
    assert_eq(seen.size(), 24)

func test_four_turns_return_to_start():
    for axis in [Vector3i.RIGHT, Vector3i.UP, Vector3i.BACK]:
        var o := 0
        for _i in 4: o = Orientations.rotated(o, axis)
        assert_eq(o, 0)

func test_world_normal_follows_rotation():
    var o := Orientations.rotated(0, Vector3i.UP)
    var n := Orientations.world_normal(o, Vector3i.RIGHT)
    assert_eq(n.y, 0)
    assert_true(n != Vector3i.RIGHT)
```

- [ ] **Step 2:** Запустить `tools/run_tests.ps1`. Ожидается: ошибки «класс не найден».
- [ ] **Step 3:** Реализовать шесть файлов по сигнатурам выше.
- [ ] **Step 4:** Запустить тесты. Ожидается: все проходят.
- [ ] **Step 5:** Коммит: `feat: data classes and orientation table`.

---

### Task 4: RiskCalculator

**Files:**
- Create: `src/logic/risk_calculator.gd`
- Test: `tests/test_risk_calculator.gd`

**Interfaces:**
- Consumes: `Blueprint`, `PartDef`, `QualityTier`, `LevelDef`, `FailureMode.WEIGHTS`.
- Produces:

```gdscript
class_name RiskReport extends RefCounted
var cost: int
var malfunction: float; var breakage: float; var explosion: float   # суммы сырых частот
func total() -> float      # explosion + breakage / 2 + malfunction / 3

class_name RiskCalculator
static func evaluate(bp: Blueprint, catalog: Dictionary) -> RiskReport   # catalog: StringName -> PartDef
static func launch_blocker(report: RiskReport, level: LevelDef) -> String
# "" если можно; иначе "Бюджет превышен на N" или "Риск ниже порога: X из Y %/с" (проценты с одним знаком)
```

- [ ] **Step 1:** Написать тесты. Вспомогательная функция `_part(id, price, rates, price_mult := 1.0) -> PartDef` создаёт деталь с одним уровнем качества.

```gdscript
func test_spec_equivalence_3_2_1():
    # порог 3 %/с закрывают: 1 взрыв, 2 поломки или 3 выхода из строя по 3 %/с
    var cat := {
        &"core": _part(&"core", 0, Vector3.ZERO),
        &"boom": _part(&"boom", 10, Vector3(0, 0, 0.03)),
        &"snap": _part(&"snap", 10, Vector3(0, 0.03, 0)),
        &"stall": _part(&"stall", 10, Vector3(0.03, 0, 0)),
    }
    assert_almost(RiskCalculator.evaluate(_bp([&"boom"]), cat).total(), 0.03, 1e-6)
    assert_almost(RiskCalculator.evaluate(_bp([&"snap", &"snap"]), cat).total(), 0.03, 1e-6)
    assert_almost(RiskCalculator.evaluate(_bp([&"stall", &"stall", &"stall"]), cat).total(), 0.03, 1e-6)

func test_cost_uses_tier_multiplier():
    var cat := {&"core": _part(&"core", 0, Vector3.ZERO), &"b": _part(&"b", 10, Vector3.ZERO, 0.3)}
    assert_eq(RiskCalculator.evaluate(_bp([&"b", &"b"]), cat).cost, 6)

func test_core_only_is_blocked_by_risk():
    var cat := {&"core": _part(&"core", 0, Vector3.ZERO)}
    var level := LevelDef.new(); level.budget = 100; level.risk_min = 0.01
    var msg := RiskCalculator.launch_blocker(RiskCalculator.evaluate(Blueprint.with_core(), cat), level)
    assert_eq(msg, "Риск ниже порога: 0.0 из 1.0 %/с")

func test_over_budget_message():
    var cat := {&"core": _part(&"core", 0, Vector3.ZERO), &"b": _part(&"b", 60, Vector3(0, 0, 0.05))}
    var level := LevelDef.new(); level.budget = 100; level.risk_min = 0.01
    assert_eq(RiskCalculator.launch_blocker(RiskCalculator.evaluate(_bp([&"b", &"b"]), cat), level), "Бюджет превышен на 20")

func test_exactly_at_limits_is_allowed():
    var cat := {&"core": _part(&"core", 0, Vector3.ZERO), &"b": _part(&"b", 100, Vector3(0, 0, 0.01))}
    var level := LevelDef.new(); level.budget = 100; level.risk_min = 0.01
    assert_eq(RiskCalculator.launch_blocker(RiskCalculator.evaluate(_bp([&"b"]), cat), level), "")
```

`_bp(ids)` ставит детали в ряд по оси X начиная с клетки `(1,0,0)`.

- [ ] **Step 2:** Запустить тесты — падают.
- [ ] **Step 3:** Реализовать. Если нарушены оба условия, возвращается сообщение о бюджете. Сравнение риска с порогом — с допуском `1e-9`.
- [ ] **Step 4:** Запустить тесты — проходят.
- [ ] **Step 5:** Коммит: `feat: cost and risk calculation with launch gating`.

---

### Task 5: FailureClock

**Files:**
- Create: `src/logic/failure_clock.gd`
- Test: `tests/test_failure_clock.gd`

**Interfaces:**
- Consumes: `FailureMode`.
- Produces:

```gdscript
class_name FailureClock extends RefCounted
func _init(seed: int) -> void
func register(key: int, rates: Vector3, margin: float) -> void
func tick(key: int, load: float, dt: float) -> int   # FailureMode или FailureMode.NONE
func is_registered(key: int) -> bool
```

Алгоритм (из раздела 6.3 дизайн-документа), для каждой пары «деталь, вид» с частотой `λ > 0`:

```
при register:   E = -ln(1 - randf());  T = 1 + margin * E      # порядок: MALFUNCTION, BREAK, EXPLODE
при tick:       T -= margin * λ * load * dt
                вид сработал, если load >= T
```

Если сработало несколько видов — возвращается самый тяжёлый (`EXPLODE` > `BREAK` > `MALFUNCTION`). После `BREAK` или `EXPLODE` ключ снимается с учёта. После `MALFUNCTION` этот вид отключается, остальные два продолжают работать. Вид с `λ == 0` не срабатывает никогда. Генератор — собственный `RandomNumberGenerator` с переданным зерном; порядок вызовов `register` определяет результат.

- [ ] **Step 1:** Написать тесты:

```gdscript
const DT := 1.0 / 60.0

func _time_to_fail(clock: FailureClock, key: int, load: float, limit := 100000.0) -> float:
    var t := 0.0
    while t < limit:
        if clock.tick(key, load, DT) != FailureMode.NONE: return t
        t += DT
    return -1.0

func test_mean_time_matches_rate_at_load_one():
    var clock := FailureClock.new(12345); var sum := 0.0
    for k in 2000:
        clock.register(k, Vector3(0, 0.1, 0), 3.0)
        sum += _time_to_fail(clock, k, 1.0)
    assert_almost(sum / 2000.0, 10.0, 1.0)      # среднее 1/λ = 10 с

func test_margin_does_not_change_rate_at_load_one():
    var a := FailureClock.new(7); var b := FailureClock.new(7)
    a.register(1, Vector3(0, 0.2, 0), 0.5); b.register(1, Vector3(0, 0.2, 0), 8.0)
    assert_almost(_time_to_fail(a, 1, 1.0), _time_to_fail(b, 1, 1.0), 2.0 * DT)

func test_same_seed_same_result():
    var a := FailureClock.new(99); var b := FailureClock.new(99)
    a.register(1, Vector3(0.05, 0.05, 0.05), 2.0); b.register(1, Vector3(0.05, 0.05, 0.05), 2.0)
    assert_eq(_time_to_fail(a, 1, 1.0), _time_to_fail(b, 1, 1.0))

func test_no_load_no_fatigue():
    var clock := FailureClock.new(1); clock.register(1, Vector3(1, 1, 1), 1.0)
    assert_eq(_time_to_fail(clock, 1, 0.0, 1000.0), -1.0)

func test_huge_shock_fails_immediately_with_heaviest_mode():
    var clock := FailureClock.new(1); clock.register(1, Vector3(0.01, 0.01, 0.01), 5.0)
    assert_eq(clock.tick(1, 1e9, DT), FailureMode.EXPLODE)

func test_zero_rate_mode_never_fires():
    var clock := FailureClock.new(1); clock.register(1, Vector3(0.01, 0.01, 0.0), 5.0)
    assert_eq(clock.tick(1, 1e9, DT), FailureMode.BREAK)

func test_all_zero_rates_never_fail():
    var clock := FailureClock.new(1); clock.register(1, Vector3.ZERO, 5.0)
    assert_eq(clock.tick(1, 1e9, DT), FailureMode.NONE)

func test_break_unregisters_malfunction_does_not():
    var clock := FailureClock.new(1)
    clock.register(1, Vector3(0.01, 0, 0), 5.0); clock.register(2, Vector3(0, 0.01, 0), 5.0)
    clock.tick(1, 1e9, DT); clock.tick(2, 1e9, DT)
    assert_true(clock.is_registered(1)); assert_true(not clock.is_registered(2))
    assert_eq(clock.tick(1, 1e9, DT), FailureMode.NONE)   # выход из строя не повторяется

func test_weaker_shock_breaks_cheap_part_sooner():
    var cheap := 0; var solid := 0
    for s in 500:
        var c := FailureClock.new(s); c.register(1, Vector3(0, 0.01, 0), 0.8)
        var g := FailureClock.new(s); g.register(1, Vector3(0, 0.01, 0), 8.0)
        if c.tick(1, 3.0, DT) != FailureMode.NONE: cheap += 1
        if g.tick(1, 3.0, DT) != FailureMode.NONE: solid += 1
    assert_true(cheap > solid * 3)

func test_tick_unknown_key_returns_none():
    assert_eq(FailureClock.new(1).tick(42, 1.0, DT), FailureMode.NONE)
```

- [ ] **Step 2:** Запустить тесты — падают.
- [ ] **Step 3:** Реализовать по алгоритму выше.
- [ ] **Step 4:** Запустить тесты — проходят.
- [ ] **Step 5:** Коммит: `feat: strength threshold and fatigue failure clock`.

---

### Task 6: BlueprintRules

**Files:**
- Create: `src/logic/blueprint_rules.gd`
- Test: `tests/test_blueprint_rules.gd`

**Interfaces:**
- Consumes: `Blueprint`, `PartDef.attach_faces`, `Orientations.world_normal`.
- Produces:

```gdscript
class_name BlueprintRules
static func connects(bp: Blueprint, catalog: Dictionary, a: Vector3i, b: Vector3i) -> bool
# клетки соседние по грани, и обе детали допускают крепление этой гранью
static func neighbors(bp: Blueprint, catalog: Dictionary, cell: Vector3i) -> Array[Vector3i]
static func can_place(bp: Blueprint, catalog: Dictionary, part: PartDef, cell: Vector3i,
        orientation: int, level: LevelDef) -> bool
static func can_remove(bp: Blueprint, catalog: Dictionary, cell: Vector3i) -> bool
```

`can_place`: клетка свободна, внутри `[volume_min, volume_max]`, деталь входит в `level.allowed_parts`, и после установки у неё есть хотя бы одно соединение. `can_remove`: деталь `removable`, и после удаления все оставшиеся детали достижимы от ядра по соединениям.

- [ ] **Step 1:** Написать тесты (каталог: `core` и `block` крепятся всеми гранями; `wheel` — только локальной гранью `Vector3i.LEFT`; уровень с объёмом от `(-2,0,-2)` до `(2,3,2)`):
  - `test_place_next_to_core_allowed` — блок в `(1,0,0)` → `true`.
  - `test_place_in_occupied_cell_rejected` — в `(0,0,0)` → `false`.
  - `test_place_floating_rejected` — в `(2,0,0)` при пустой `(1,0,0)` → `false`.
  - `test_place_outside_volume_rejected` — в `(3,0,0)` при занятых `(1,0,0)` и `(2,0,0)` → `false`.
  - `test_place_not_allowed_part_rejected` — деталь не из `allowed_parts` → `false`.
  - `test_wheel_needs_mount_face_toward_neighbor` — колесо в `(1,0,0)` с ориентацией 0 (монтажная грань смотрит на ядро) → `true`; с ориентацией, повёрнутой на 180° вокруг Y → `false`.
  - `test_core_not_removable` → `false`.
  - `test_remove_leaf_allowed` — цепочка ядро–A–B, удалить B → `true`.
  - `test_remove_bridge_rejected` — цепочка ядро–A–B, удалить A → `false`.
  - `test_remove_allowed_when_alternate_path_exists` — кольцо из четырёх клеток, удалить одну → `true`.
- [ ] **Step 2:** Запустить тесты — падают.
- [ ] **Step 3:** Реализовать; связность — обход в ширину от ядра.
- [ ] **Step 4:** Запустить тесты — проходят.
- [ ] **Step 5:** Коммит: `feat: placement and connectivity rules`.

---

### Task 7: Каталог деталей

**Files:**
- Create: `tools/part_table.gd`, `tools/generate_parts.gd`, `src/core/part_catalog.gd`, `scenes/parts/<id>.tscn` (10 штук), `data/parts/<id>.tres` (генерируются)
- Modify: `project.godot` (автозагрузка `PartCatalog`)
- Test: `tests/test_part_catalog.gd`

**Interfaces:**
- Produces: автозагрузка `PartCatalog` с `defs: Dictionary` (`StringName -> PartDef`), `get_def(id: StringName) -> PartDef`, `static func load_all(dir := "res://data/parts") -> Dictionary`.

Таблица `tools/part_table.gd` — стартовые числа, частоты указаны для качества «Хлам» в долях в секунду:

| id | название | цена | масса, кг | выход / поломка / взрыв | взрыв: импульс, радиус | активация |
|---|---|---|---|---|---|---|
| `core` | Ядро | 0 | 20 | 0 / 0 / 0 | 0, 0 | нет |
| `block` | Блок | 10 | 5 | 0.015 / 0.012 / 0 | 0, 0 | нет |
| `ballast` | Балласт | 15 | 40 | 0 / 0.006 / 0 | 0, 0 | нет |
| `free_wheel` | Колесо | 20 | 8 | 0.010 / 0.010 / 0.002 | 200, 2 | нет |
| `motor_wheel` | Моторное колесо | 60 | 12 | 0.020 / 0.010 / 0.006 | 500, 3 | удержание |
| `steering_hinge` | Рулевой шарнир | 40 | 6 | 0.015 / 0.010 / 0.003 | 200, 2 | удержание |
| `rocket` | Ракета | 80 | 10 | 0.020 / 0.010 / 0.015 | 1200, 5 | удержание |
| `cannon` | Пушка | 100 | 30 | 0.025 / 0.008 / 0.012 | 1200, 5 | нажатие |
| `powder_barrel` | Пороховая бочка | 50 | 15 | 0.010 / 0.008 / 0.020 | 2500, 7 | нажатие |
| `whistle` | Свистелка | 120 | 60 | 0.015 / 0.010 / 0.040 | 2500, 7 | нет |

Уровни качества общие для всех деталей (кроме ядра, у него один уровень):

| название | множитель цены | множитель частот | запас `S` |
|---|---|---|---|
| Добротная | 1.0 | 0.04 | 8.0 |
| Сойдёт | 0.6 | 0.3 | 3.0 |
| Хлам | 0.3 | 1.0 | 0.8 |

Прочее: `always_loaded = true` у пассивных деталей и бочки; `removable = false` только у ядра; `attach_faces` — одна монтажная грань `Vector3i.LEFT` у колёс, ракеты и пушки, все шесть у остальных; клавиши по умолчанию: моторное колесо ↑/↓, рулевой шарнир ←/→, ракета Shift, пушка C, бочка B.

- [ ] **Step 1:** Написать тесты: в каталоге ровно 10 деталей с перечисленными `id`; у `core` один уровень качества и `removable == false`; у остальных три уровня; `get_def(&"block").price(2) == 3`; `get_def(&"whistle").tiers[0].rates.z` равно `0.0016` (допуск `1e-6`); у `block` и `ballast` `explosion_power == 0`, у остальных восьми механизмов — больше нуля, кроме `core`; у каждой детали задана `scene`.
- [ ] **Step 2:** Запустить тесты — падают.
- [ ] **Step 3:** Собрать 10 сцен деталей: корень `RigidBody3D` со скриптом-заглушкой (скрипты появятся в задачах 11–12), `MeshInstance3D` из примитива со своим плоским цветом, `CollisionShape3D`. Колёса — цилиндр диаметром 1 м.
- [ ] **Step 4:** Написать `tools/generate_parts.gd` (`extends SceneTree`): по таблице создаёт `PartDef` и сохраняет в `data/parts/<id>.tres`. Запустить без окна тем же способом, что и тесты, но с `--script res://tools/generate_parts.gd`.
- [ ] **Step 5:** Реализовать `PartCatalog`, добавить в автозагрузку.
- [ ] **Step 6:** Запустить тесты — проходят.
- [ ] **Step 7:** Коммит: `feat: part table, generator and catalog`.

---

### Task 8: Меню и переходы между сценами

**Files:**
- Create: `src/core/game.gd`, `src/core/level_session.gd`, `scenes/level_session.tscn`, `src/ui/main_menu.gd`, `scenes/ui/main_menu.tscn`, `src/ui/level_select.gd`, `scenes/ui/level_select.tscn`, `src/ui/pause_menu.gd`, `scenes/ui/pause_menu.tscn`, `scenes/ui/theme.tres`, `data/levels/level_01.tres`, `scenes/levels/level_01.tscn` (пока плоскость)
- Modify: `project.godot` (автозагрузка `Game`, главная сцена, действия ввода)

**Interfaces:**
- Produces:

```gdscript
# автозагрузка Game
var levels: Array[LevelDef]          # из data/levels, по возрастанию id
var current_level: LevelDef
func blueprint_for(level: LevelDef) -> Blueprint   # создаёт Blueprint.with_core() при первом обращении
func goto_main_menu() -> void
func goto_level_select() -> void
func start_level(level: LevelDef) -> void

# LevelSession (корень scenes/level_session.tscn)
enum Mode { BUILD, SIM }
var mode: Mode
var level_root: Node3D               # экземпляр сцены уровня
var last_seed: int
signal mode_changed(mode: Mode)
func enter_build() -> void
func enter_sim(seed: int = -1) -> void   # -1 = новое случайное зерно
```

Действия ввода: `toggle_sim` (Tab), `pause` (Esc), `repeat_seed` (F5), `build_rotate_y` (R), `build_rotate_x` (T), `build_delete` (правая кнопка мыши).

Контракт сцены уровня: корень `Node3D`; обязательные дочерние узлы `BuildOrigin` (`Marker3D` — мировая позиция клетки `(0,0,0)`) и `Objective`; необязательные `Cargo`, `Target`. Всё, что ниже `y = -30`, считается упавшим за границу мира.

- [ ] **Step 1:** Реализовать `Game` и сцены меню. Главное меню: «Играть», «Выход». Выбор уровня: карточка на каждый `LevelDef` (название, задача, бюджет, порог в %/с), кнопка «Назад».
- [ ] **Step 2:** Реализовать `LevelSession`: загружает сцену уровня, держит два пустых узла-режима (наполняются в задачах 9 и 11), переключает их по `toggle_sim`. Пауза по Esc: «Продолжить», «К уровням», «В главное меню»; на паузе дерево остановлено.
- [ ] **Step 3:** Ручная проверка в редакторе: меню → «Играть» → карточка уровня 1 → пустой уровень → Tab переключает режим (название режима временно выводится в углу) → Esc → «К уровням» → «Назад» → «Выход» закрывает игру.
- [ ] **Step 4:** Коммит: `feat: menus, level select and level session shell`.

---

### Task 9: Режим сборки

**Files:**
- Create: `src/build/build_mode.gd`, `src/build/build_camera.gd`, `src/ui/build_hud.gd`, `scenes/ui/build_hud.tscn`, `src/ui/part_panel.gd`, `scenes/ui/part_panel.tscn`
- Modify: `scenes/level_session.tscn`, `src/core/level_session.gd`

**Interfaces:**
- Consumes: `Game.blueprint_for`, `BlueprintRules.can_place/can_remove`, `PartCatalog`, `Orientations`.
- Produces: `BuildMode` (узел) с `signal blueprint_changed`, `var selected_part: PartDef`, `var selected_tier: int`, `var orientation: int`.

Поведение:

- Чертёж показывается «призраками»: экземпляры сцен деталей с замороженной физикой и коллизией для луча мыши.
- Палитра слева: кнопка на каждую деталь из `allowed_parts` и инструмент «Выбор».
- С выбранной деталью: полупрозрачный предпросмотр в клетке, соседней с гранью под курсором; зелёный, если `can_place`, иначе красный. Левая кнопка ставит деталь с текущими качеством, ориентацией и клавишами по умолчанию.
- Правая кнопка удаляет деталь, если `can_remove`; иначе деталь мигает красным.
- R и T поворачивают текущую ориентацию; клавиши 1/2/3 выбирают качество новых деталей.
- Инструмент «Выбор»: щелчок по детали открывает панель с качеством, двумя клавишами (щелчок по полю, затем нажатие клавиши) и флажком «Инверсия».
- Кнопка «Очистить» вызывает `Blueprint.clear()`.
- Объём сборки показан каркасной рамкой.
- Камера: средняя кнопка — облёт вокруг центра объёма, колесо — приближение, Shift + средняя кнопка — сдвиг.

- [ ] **Step 1:** Реализовать камеру и отображение чертежа призраками.
- [ ] **Step 2:** Реализовать установку, удаление, поворот, выбор качества.
- [ ] **Step 3:** Реализовать панель свойств детали и «Очистить».
- [ ] **Step 4:** Ручная проверка: собрать тележку (ядро, 6 блоков, 4 моторных колеса); колесо с монтажной гранью «наружу» не ставится; деталь вне рамки не ставится; блок-перемычка не удаляется; после Tab туда и обратно машина на месте; у одного колеса поменять клавиши и включить инверсию — значения сохраняются после повторного открытия панели.
- [ ] **Step 5:** Коммит: `feat: build mode editor`.

---

### Task 10: Бюджет, риск и блокировка запуска

**Files:**
- Modify: `src/ui/build_hud.gd`, `scenes/ui/build_hud.tscn`, `src/core/level_session.gd`
- Create: `src/ui/risk_bar.gd`

**Interfaces:**
- Consumes: `RiskCalculator.evaluate`, `RiskCalculator.launch_blocker`, `BuildMode.blueprint_changed`.
- Produces: `RiskBar` (`Control`) с `func show_report(report: RiskReport, risk_min: float) -> void`.

Поведение:

- Полоса бюджета: «потрачено / бюджет», красная при превышении.
- Полоса риска: три сегмента шириной по взвешенному вкладу (выход из строя ÷ 3 — жёлтый, поломка ÷ 2 — оранжевый, взрыв — красный), вертикальная отметка порога, подпись «X из Y %/с».
- Кнопка «Запуск» неактивна, пока `launch_blocker` не вернул пустую строку; причина написана под кнопкой. Tab в сборке подчиняется той же проверке.
- Наведение на деталь в палитре или на машине: подсказка с ценой выбранного качества, тремя частотами в %/с, запасом прочности, импульсом и радиусом взрыва.

- [ ] **Step 1:** Реализовать `RiskBar` и полосу бюджета, обновление по `blueprint_changed`.
- [ ] **Step 2:** Реализовать блокировку запуска и подсказки.
- [ ] **Step 3:** Ручная проверка на уровне 1 (бюджет 250, порог 0.5 %/с): одно ядро — «Риск ниже порога: 0.0 из 0.5 %/с»; тележка из добротных деталей — всё ещё ниже порога; перевод колёс в «Хлам» — запуск разрешён; добавление деталей сверх бюджета — «Бюджет превышен на N».
- [ ] **Step 4:** Коммит: `feat: budget and risk bars with launch gating`.

---

### Task 11: Сборка машины и запуск симуляции

**Files:**
- Create: `src/sim/part_body.gd`, `src/sim/machine.gd`, `src/sim/machine_assembler.gd`, `src/sim/follow_camera.gd`, `src/sim/sim_mode.gd`
- Modify: `scenes/parts/*.tscn` (назначить скрипт `PartBody`), `src/core/level_session.gd`, `src/sim/sim_tuning.gd`
- Test: `tests/test_machine_assembler.gd`

**Interfaces:**
- Consumes: `Blueprint`, `BlueprintRules.connects`, `PartCatalog`, `SimTuning` (соединение из задачи 2).
- Produces:

```gdscript
class_name PartBody extends RigidBody3D
enum State { OK, MALFUNCTIONED, DETACHED, DESTROYED }
var def: PartDef; var entry: BlueprintEntry; var tier: QualityTier
var state: State; var machine: Machine
var input_value: float                       # -1..1, выставляет MachineController
func get_load() -> float                     # базовая реализация: 1.0 при always_loaded, иначе 0.0
func set_input(value: float) -> void
func apply_malfunction() -> void             # базовая реализация пустая
func make_joint_to(other: PartBody) -> Joint3D   # базовая: жёсткое соединение из SimTuning

class_name Machine extends Node3D
signal part_failed(part: PartBody, mode: int, time: float)
var parts: Array[PartBody]
var sim_time: float
func core() -> PartBody
func attached_parts() -> Array[PartBody]     # state OK или MALFUNCTIONED
func detach(part: PartBody) -> void          # удаляет все соединения детали, state = DETACHED
func joints_of(part: PartBody) -> Array[Joint3D]

class_name MachineAssembler
static func build(bp: Blueprint, catalog: Dictionary, origin: Transform3D) -> Machine
```

`build`: по `PartBody` на запись (масса из `PartDef`, поворот из `Orientations.basis`), по одному соединению на каждую пару клеток, для которой `BlueprintRules.connects` истинно. Соединение создаёт та деталь из пары, у которой переопределён `make_joint_to` (иначе любая). `SimMode` при входе строит машину в позиции `BuildOrigin`, при выходе удаляет её вместе со всеми дочерними узлами.

- [ ] **Step 1:** Написать тесты (без окна, машина добавляется в дерево `SceneTree` запускателя):
  - `test_one_body_per_entry` — чертёж из ядра и трёх блоков в ряд → `machine.parts.size() == 4`.
  - `test_joint_per_connected_pair` — тот же чертёж → всего 3 соединения; квадрат 2×2 из ядра и трёх блоков → 4 соединения.
  - `test_positions_follow_cells` — блок в `(2,0,0)` при `origin` со сдвигом `(10,0,0)` стоит в `(12,0,0)`.
  - `test_detach_removes_only_own_joints` — в ряду ядро–A–B `detach(A)` оставляет 0 соединений у A и у B, `A.state == DETACHED`; в квадрате 2×2 `detach` одного блока оставляет 2 соединения.
  - `test_detach_twice_is_safe` — повторный `detach` не вызывает ошибок.
- [ ] **Step 2:** Запустить тесты — падают.
- [ ] **Step 3:** Реализовать `PartBody`, `Machine`, `MachineAssembler`.
- [ ] **Step 4:** Запустить тесты — проходят.
- [ ] **Step 5:** Реализовать `SimMode` и `FollowCamera` (следит за ядром, облёт мышью, колесо — приближение), подключить к `LevelSession.enter_sim/enter_build`.
- [ ] **Step 6:** Ручная проверка: тележка из задачи 9 после Tab падает на землю целой и стоит; Tab возвращает в сборку меньше чем за секунду; 20 переключений подряд без ошибок в журнале и без роста числа узлов (Отладчик → Монитор → Objects).
- [ ] **Step 7:** Коммит: `feat: machine assembly and simulation mode`.

---

### Task 12: Управление и поведение деталей

**Files:**
- Create: `src/sim/machine_controller.gd`, `src/sim/parts/free_wheel.gd`, `motor_wheel.gd`, `steering_hinge.gd`, `rocket.gd`, `cannon.gd`, `powder_barrel.gd`, `whistle.gd`, `block.gd`, `core.gd` (все в `src/sim/parts/`), `scenes/parts/cannonball.tscn`
- Modify: `scenes/parts/*.tscn` (назначить скрипты), `src/sim/sim_mode.gd`, `src/sim/sim_tuning.gd`

**Interfaces:**
- Consumes: `PartBody`, `Machine`, `BlueprintEntry.key_positive/key_negative/inverted`.
- Produces: `class_name MachineController extends Node` с `var machine: Machine`, `var enabled: bool = true`. Каждый физический тик при `enabled` вычисляет для детали `value = (нажата key_positive ? 1 : 0) - (нажата key_negative ? 1 : 0)`, меняет знак при `inverted` и вызывает `set_input`. При `enabled == false` ввод не меняется.

Поведение типов (числа — в `SimTuning`):

| Деталь | Соединение | Работа | `get_load()` | `apply_malfunction()` |
|---|---|---|---|---|
| `block` | жёсткое | — | 1 | соединения детали заменяются на соединения с угловым люфтом ±15° |
| `free_wheel` | шарнир по оси монтажа | свободно вращается | 1 | вращение запирается |
| `motor_wheel` | шарнир с мотором | целевая скорость `input × 12 рад/с` | `abs(input)` | с шансом 50% глохнет (мотор отключён), иначе залипает: ввод навсегда равен последнему ненулевому, либо +1 |
| `steering_hinge` | шарнир по вертикали с пределами ±35° | целевой угол `input × 35°` | `abs(input)` | запирается в текущем угле |
| `rocket` | жёсткое | сила 600 Н вдоль оси при `input > 0` | 1 при работе | гаснет навсегда |
| `cannon` | жёсткое | по нажатию: ядро 5 кг со скоростью 40 м/с, отдача, перезарядка 2 с | 1 во время перезарядки | осечка: больше не стреляет |
| `powder_barrel` | жёсткое | по нажатию: взрыв (задача 14) | 1 | отсырела: клавиша не работает |
| `whistle` | жёсткое | свистит (эффект в задаче 16) | 1 | замолкает |

Выбор 50/50 у мотора делается из генератора машины с зерном запуска (`Machine.rng`), а не из глобального.

- [ ] **Step 1:** Реализовать `MachineController` и подключить в `SimMode`.
- [ ] **Step 2:** Реализовать колёса и рулевой шарнир. Ручная проверка: тележка едет вперёд и назад, колесо с инверсией крутится в обратную сторону, передняя ось на шарнирах поворачивает.
- [ ] **Step 3:** Реализовать ракету, пушку, бочку (пока без взрыва — только событие в журнале), свистелку, блок, ядро. Ручная проверка: ракета толкает машину; пушка стреляет не чаще раза в 2 с и даёт отдачу; ядра пушки исчезают при возврате в сборку.
- [ ] **Step 4:** Временная отладочная клавиша F9 вызывает `apply_malfunction()` у детали под курсором. Проверить эффект выхода из строя у каждого из восьми типов по таблице. Клавишу оставить до задачи 13.
- [ ] **Step 5:** Коммит: `feat: machine control and part behaviours`.

---

### Task 13: Отказы

**Files:**
- Create: `src/sim/failure_system.gd`, `src/ui/sim_hud.gd`, `scenes/ui/sim_hud.tscn`, `src/ui/failure_label.gd`
- Modify: `src/sim/part_body.gd`, `src/sim/machine.gd`, `src/sim/sim_mode.gd`, `src/sim/sim_tuning.gd`
- Test: `tests/test_failure_system.gd`

**Interfaces:**
- Consumes: `FailureClock`, `Machine.detach`, `PartBody.get_load/apply_malfunction`, `LevelSession.last_seed`.
- Produces:

```gdscript
class_name FailureSystem extends Node
func setup(machine: Machine, seed: int) -> void   # регистрирует детали в порядке machine.parts
# в Machine:
var rng: RandomNumberGenerator                    # зерно запуска
func apply_failure(part: PartBody, mode: int) -> void
# MALFUNCTION: state = MALFUNCTIONED, part.apply_malfunction()
# BREAK: detach(part)
# EXPLODE: explode(part) — до задачи 14 работает как detach
# во всех случаях: part_failed.emit(part, mode, sim_time)
# в PartBody:
func shake() -> float
```

Встряска: `a = |скорость − скорость_в_прошлом_тике| / dt`; `shake = clampf((a − SHAKE_FREE) / SHAKE_REF, 0, SHAKE_MAX)`; стартовые значения `SHAKE_FREE = 15` м/с², `SHAKE_REF = 50` м/с², `SHAKE_MAX = 20`. Нагрузка, передаваемая в часы: `get_load() + shake()`. Первый тик после сборки встряску не считает.

`FailureSystem` каждый физический тик проходит по `machine.attached_parts()`, вызывает `clock.tick(ключ, нагрузка, dt)` и при срабатывании — `machine.apply_failure`. Оторванные и уничтоженные детали не тикают.

- [ ] **Step 1:** Написать тесты (машина-заглушка из двух `PartBody` с подменёнными `PartDef`):
  - `test_same_seed_same_first_failure` — два прогона по 600 тиков с одним зерном и нагрузкой 1 дают одинаковые (деталь, вид, номер тика) первого отказа.
  - `test_idle_active_part_never_fails` — деталь с `always_loaded = false`, вводом 0 и частотами 1.0 не отказывает за 6000 тиков.
  - `test_break_detaches_and_emits` — частоты `(0, 1000, 0)`: в первом тике `state == DETACHED`, сигнал `part_failed` получен один раз с видом `BREAK`.
  - `test_detached_part_stops_ticking` — после отрыва сигналов больше нет за 600 тиков.
  - `test_malfunctioned_part_can_still_break` — частоты `(1000, 0.5, 0)`: сначала `MALFUNCTION`, позже `BREAK`.
- [ ] **Step 2:** Запустить тесты — падают.
- [ ] **Step 3:** Реализовать `FailureSystem`, `Machine.apply_failure`, `PartBody.shake`. Убрать отладочную клавишу F9.
- [ ] **Step 4:** Запустить тесты — проходят.
- [ ] **Step 5:** Реализовать `SimHUD`: текст задачи, таймер, зерно, журнал отказов (последние 6 строк вида «12.4 с — Моторное колесо: заглохло»). При отказе деталь на 1 с окрашивается (жёлтый, оранжевый или красный по виду), над ней на 2 с появляется подпись. Тексты отказов по типам — из таблицы раздела 5 дизайн-документа.
- [ ] **Step 6:** Ручная проверка: тележка из «Хлама» разваливается за разумное время, каждый отказ виден в журнале и на детали; F5 повторяет запуск с тем же зерном — первые отказы те же, если не трогать управление; сброс машины с высоты 5 м ломает хламовые блоки сразу, а добротные — нет.
- [ ] **Step 7:** Коммит: `feat: failure system with shake load and failure log`.

---

### Task 14: Взрывы и испытатель

**Files:**
- Create: `src/sim/pilot.gd`
- Modify: `src/sim/machine.gd`, `src/sim/parts/core.gd`, `src/sim/parts/powder_barrel.gd`, `src/sim/machine_controller.gd`, `src/ui/sim_hud.gd`, `src/sim/sim_tuning.gd`
- Test: `tests/test_explosions.gd`, `tests/test_pilot.gd`

**Interfaces:**
- Consumes: `PartDef.explosion_power/explosion_radius`, `Machine.detach`.
- Produces:

```gdscript
# в Machine:
func explode(part: PartBody) -> void
# class_name Pilot extends Node (дочерний узел ядра)
signal health_changed(value: float)
signal died
var health: float = 100.0
func is_alive() -> bool
func take_damage(amount: float) -> void    # здоровье не ниже 0; died испускается один раз
static func explosion_damage(power: float, radius: float, distance: float) -> float
static func impact_damage(delta_speed: float) -> float
```

Взрыв детали с импульсом `P`, радиусом `R` в точке `c`:

1. Деталь получает `state = DESTROYED`, её соединения удаляются, узел скрывается и отключается. Повторный `explode` для неё ничего не делает.
2. Каждое физическое тело в радиусе `R` получает импульс `P × (1 − d/R)` от точки `c`.
3. Прикреплённые детали машины при `d < 0.35 × R` отрываются через `apply_failure(part, BREAK)`.
4. Испытатель получает `explosion_damage(P, R, d) = P × (1 − d/R) × 0.06`, нуль при `d ≥ R`.
5. Бочки и свистелки в радиусе, ещё не уничтоженные, взрываются через 0.15 с. Таймер — дочерний узел `Machine`, чтобы он исчезал вместе с машиной.
6. Узлы группы `destructible` в радиусе получают `take_hit(P × (1 − d/R))` (задача 15).

Удар по кабине: ядро каждый тик считает изменение своей скорости `Δv`; `impact_damage(Δv) = max(0, Δv − 4) × 10`. Первый тик после сборки не считается. Ядро ниже `y = -30` — мгновенная гибель.

Гибель: `MachineController.enabled = false` (ввод замирает), в `SimHUD` надпись «Управление потеряно». Запуск продолжается.

- [ ] **Step 1:** Написать тесты:

```gdscript
# tests/test_pilot.gd
func test_explosion_damage_falloff():
    assert_almost(Pilot.explosion_damage(2500, 7, 1), 128.57, 0.01)   # бочка вплотную убивает
    assert_almost(Pilot.explosion_damage(200, 2, 1), 6.0, 0.01)       # слабый взрыв ранит
    assert_eq(Pilot.explosion_damage(2500, 7, 7), 0.0)
    assert_eq(Pilot.explosion_damage(2500, 7, 50), 0.0)

func test_impact_damage_threshold():
    assert_eq(Pilot.impact_damage(3.9), 0.0)
    assert_almost(Pilot.impact_damage(9.0), 50.0, 0.001)

func test_health_clamps_and_dies_once():
    var p := Pilot.new(); var deaths := [0]
    p.died.connect(func(): deaths[0] += 1)
    p.take_damage(70); p.take_damage(70); p.take_damage(70)
    assert_eq(p.health, 0.0); assert_eq(deaths[0], 1); assert_true(not p.is_alive())
```

  `tests/test_explosions.gd` (машина строится в дереве запускателя, после взрыва тест ждёт нужное число физических кадров):
  - `test_explode_destroys_part_once` — два вызова `explode` подряд: один сигнал `part_failed`, `state == DESTROYED`.
  - `test_near_parts_detach_far_parts_stay` — взрыв радиусом 5 м: блок на расстоянии 1 м оторван, блок на расстоянии 3 м прикреплён.
  - `test_chain_detonation_each_barrel_once` — три бочки в ряд, взорвать крайнюю: через 1 с все три `DESTROYED`, сигналов `part_failed` с видом `EXPLODE` ровно три.
  - `test_machine_freed_during_pending_detonation` — взорвать бочку рядом с другой и сразу `machine.free()`: за следующие 30 кадров ошибок нет.
  - `test_dead_pilot_freezes_input` — задать моторному колесу ввод 1, убить испытателя, вызвать тик контроллера без нажатых клавиш: `input_value` по-прежнему 1.
- [ ] **Step 2:** Запустить тесты — падают.
- [ ] **Step 3:** Реализовать `Pilot`, `Machine.explode`, урон от удара в `core.gd`, отключение управления, срабатывание бочки по клавише.
- [ ] **Step 4:** Запустить тесты — проходят.
- [ ] **Step 5:** Добавить в `SimHUD` полосу здоровья и надпись «Управление потеряно».
- [ ] **Step 6:** Ручная проверка: взрыв свистелки на конце длинной балки ранит, но не убивает; бочка рядом с ядром убивает; падение машины кабиной вниз с высоты снимает здоровье, мягкая посадка — нет; после гибели на газу машина едет дальше сама; Tab в момент цепной детонации не даёт ошибок в журнале.
- [ ] **Step 7:** Коммит: `feat: explosions, chain detonation and test pilot health`.

---

### Task 15: Цели, уровни, экран итога

**Files:**
- Create: `src/sim/objectives/objective.gd`, `reach_zone_objective.gd`, `deliver_cargo_objective.gd`, `destroy_target_objective.gd` (в `src/sim/objectives/`), `src/sim/destructible.gd`, `src/ui/result_screen.gd`, `scenes/ui/result_screen.tscn`, `scenes/levels/level_02.tscn` … `level_04.tscn`, `data/levels/level_02.tres` … `level_04.tres`
- Modify: `scenes/levels/level_01.tscn`, `data/levels/level_01.tres`, `src/sim/sim_mode.gd`, `src/core/level_session.gd`
- Test: `tests/test_destructible.gd`, `tests/test_levels.gd`

**Interfaces:**
- Produces:

```gdscript
class_name Objective extends Node3D
signal completed
var is_completed: bool
func start(machine: Machine) -> void      # вызывается при входе в симуляцию
func reset() -> void                      # вызывается при возврате в сборку

class_name ReachZoneObjective    # дочерний Area3D; выполнена, когда в зоне тело ядра
class_name DeliverCargoObjective # выполнена, когда в зоне тело узла Cargo
class_name DestroyTargetObjective# выполнена, когда у узла Target осталось не больше
                                 # @export var survivors_allowed: int стоящих частей

class_name Destructible extends RigidBody3D   # группа "destructible"
@export var toughness: float = 300.0
var is_destroyed: bool
func take_hit(impulse: float) -> void         # накопленный импульс >= toughness -> разрушен
```

Часть постройки считается разрушенной также, если её сдвинуло от исходного места больше чем на 1.5 м. `reset()` возвращает груз и постройку в исходное состояние.

Уровни (стартовые числа):

| id | Название | Задача | Бюджет | Порог | Особенности сцены |
|---|---|---|---|---|---|
| `level_01` | Доедь | «Довези испытателя до флага» | 250 | 0.005 | прямая 40 м, кочка 0.4 м на середине; ракета, пушка и бочка недоступны |
| `level_02` | Доставка | «Довези ящик до флага» | 350 | 0.010 | ящик 30 кг лежит рядом с объёмом сборки, холм 3 м, зона в 50 м; пушка недоступна |
| `level_03` | Снеси башню | «Разрушь башню» | 400 | 0.015 | башня из 12 `Destructible` в 25 м, `survivors_allowed = 3`; все детали |
| `level_04` | Пропасть | «Переберись на ту сторону» | 450 | 0.015 | разрыв 8 м, трамплин перед ним; все детали |

Объём сборки на всех уровнях от `(-3, 0, -3)` до `(3, 4, 3)`.

Экран итога появляется по сигналу `completed`: «Задача выполнена», время, стоимость машины, зерно, полный журнал отказов, строка «Испытатель выжил» или «Испытатель не выжил». Кнопки: «В сборку», «Ещё раз с тем же зерном», «К уровням». Симуляция под экраном продолжается.

- [ ] **Step 1:** Написать тесты:
  - `test_destructible_survives_below_toughness` — `take_hit(299)` → не разрушен.
  - `test_destructible_accumulates_hits` — `take_hit(200)` дважды → разрушен.
  - `test_all_four_levels_load` — `Game.levels.size() == 4`, id по порядку.
  - `test_level_scenes_follow_contract` — в каждой сцене уровня есть узлы `BuildOrigin` и `Objective`, а `Objective` наследует класс `Objective`.
  - `test_level_parts_exist_in_catalog` — каждый id из `allowed_parts` есть в `PartCatalog`.
  - `test_level_limits_are_reachable` — для каждого уровня существует чертёж из разрешённых деталей (ядро и самая рискованная на рубль деталь в количестве, нужном для порога), у которого `launch_blocker` возвращает пустую строку.
- [ ] **Step 2:** Запустить тесты — падают.
- [ ] **Step 3:** Реализовать цели и `Destructible`, подключить `start/reset` в `SimMode`.
- [ ] **Step 4:** Собрать четыре сцены уровней из примитивов и их `LevelDef`.
- [ ] **Step 5:** Запустить тесты — проходят.
- [ ] **Step 6:** Реализовать экран итога и повтор с зерном (кнопка и F5).
- [ ] **Step 7:** Ручная проверка: пройти каждый уровень хотя бы одной машиной; на уровне 1 победа засчитывается, если ядро докатилось до флага с погибшим испытателем; на уровне 3 башня восстанавливается после возврата в сборку; на уровне 2 ящик возвращается на место.
- [ ] **Step 8:** Коммит: `feat: objectives, four levels and result screen`.

---

### Task 16: Эффекты, баланс, сборка для тестеров

**Files:**
- Create: `scenes/fx/explosion_fx.tscn`, `scenes/fx/smoke_fx.tscn`, `assets/sfx/*.wav`, `export_presets.cfg`, `docs/playtest.md`
- Modify: `src/sim/machine.gd`, `src/sim/parts/*.gd`, `tools/part_table.gd`, `data/levels/*.tres`, `src/sim/sim_tuning.gd`

- [ ] **Step 1:** Эффекты: вспышка и частицы взрыва с размером по `explosion_radius`; дымок над деталью, вышедшей из строя; огонь из работающей ракеты.
- [ ] **Step 2:** Звуки (свободные или сгенерированные, один файл на событие): взрыв, поломка, выход из строя, мотор, ракета, выстрел, свист свистелки, победа. Громкость взрыва зависит от `explosion_power`.
- [ ] **Step 3:** Проход баланса. Сыграть каждый уровень минимум 5 раз и править только `tools/part_table.gd`, `data/levels/*.tres` и `SimTuning`, после правок таблицы перегенерировать `data/parts`. Целевые ориентиры: машина на пороге риска живёт без серьёзного отказа 15–40 с; уровень проходится не с первой попытки, но в пределах десяти; уловка «только свистелка на отшибе» не дешевле, чем удешевление рабочих деталей.
- [ ] **Step 4:** Запустить `tools/run_tests.ps1` — все тесты проходят после смены чисел (тесты задач 7 и 15, зависящие от конкретных чисел таблицы, обновить вместе с таблицей).
- [ ] **Step 5:** Сборка: шаблоны экспорта ставит автор через Редактор → Управление шаблонами экспорта (нужен интернет, из командной строки не ставятся). Создать пресет «Windows Desktop» с путём `build/GoblinEngineer.exe`, собрать, запустить собранный файл и пройти уровень 1.
- [ ] **Step 6:** Написать `docs/playtest.md`: управление на одной странице и четыре вопроса из раздела 10 дизайн-документа в виде листа наблюдений.
- [ ] **Step 7:** Коммит: `feat: effects, balance pass and playtest build`.

---

## Покрытие дизайн-документа

| Раздел | Задачи |
|---|---|
| 3. Игровой цикл | 8, 11, 15 |
| 4. Сборка, испытатель | 9, 14 |
| 5. Детали и качество | 7, 12 |
| 6.1–6.3. Отказы, нагрузка, порог прочности | 5, 13, 14 |
| 6.4. Порог риска | 4, 10 |
| 6.5. Что видит игрок | 10, 13, 14, 15 |
| 7. Уровни | 15 |
| 8. Архитектура | 1–3, 11 |
| 9. Этап 1, шлюз физики | 2 |
| 10. Плейтест | 16 |
