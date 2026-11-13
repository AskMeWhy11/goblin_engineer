# Runs a scene headless and prints its log. Usage: run_scene.ps1 res://path/to/scene.tscn
param([string]$Scene)
$godot = "D:\godot_prjct\Godot_v4.7.2-stable_win64.exe"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$log = Join-Path $root "tests\last_scene.log"
if (Test-Path $log) { Remove-Item $log }
$p = Start-Process $godot -ArgumentList "--headless", "--path", "`"$root`"", "--log-file", "`"$log`"", $Scene -Wait -PassThru
Get-Content $log | Select-Object -Skip 2
exit $p.ExitCode
