# Runs the headless test suite. Exit code 0 = all passed.
# The Godot binary is a GUI executable, so it must be started with Start-Process -Wait.
$godot = "D:\godot_prjct\Godot_v4.7.2-stable_win64.exe"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$log = Join-Path $root "tests\last_run.log"
$importLog = Join-Path $root "tests\last_import.log"

# Refresh the global class cache so new class_name scripts are visible.
Start-Process $godot -ArgumentList "--headless", "--path", "`"$root`"", "--import", "--log-file", "`"$importLog`"" -Wait | Out-Null

if (Test-Path $log) { Remove-Item $log }
$p = Start-Process $godot -ArgumentList "--headless", "--path", "`"$root`"", "--log-file", "`"$log`"", "res://tests/run_tests.tscn" -Wait -PassThru
if (-not (Test-Path $log)) { Write-Output "No test log produced"; exit 1 }
$text = Get-Content $log
$text | Where-Object { $_ -match "^(FAIL|SCRIPT ERROR|ERROR|\s+at:|\d+ passed)" -or $env:TEST_VERBOSE }
$code = $p.ExitCode
if ($text -match "SCRIPT ERROR") { Write-Output "Script errors found in log"; $code = 1 }
if (-not ($text -match "\d+ passed, 0 failed")) { $code = 1 }
exit $code
