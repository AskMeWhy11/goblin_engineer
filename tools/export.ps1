# Builds build/GoblinEngineer.exe. Needs export templates installed once through the editor:
# Editor -> Manage Export Templates -> Download and Install.
$godot = "D:\godot_prjct\Godot_v4.7.2-stable_win64.exe"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$log = Join-Path $root "tests\last_export.log"
New-Item -ItemType Directory -Force (Join-Path $root "build") | Out-Null
$p = Start-Process $godot -ArgumentList "--headless", "--path", "`"$root`"", "--log-file", "`"$log`"", "--export-release", "`"Windows Desktop`"", "build/GoblinEngineer.exe" -Wait -PassThru
Get-Content $log | Where-Object { $_ -match "ERROR|error|template|savepack|Export" } | Select-Object -First 12
if (Test-Path (Join-Path $root "build\GoblinEngineer.exe")) { Write-Output "EXPORT OK: build\GoblinEngineer.exe" } else { Write-Output "EXPORT FAILED" }
exit $p.ExitCode
