# Regenerates data/parts/*.tres and scenes/parts/*.tscn from tools/part_table.gd.
$godot = "D:\godot_prjct\Godot_v4.7.2-stable_win64.exe"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$log = Join-Path $root "tests\last_generate.log"
Start-Process $godot -ArgumentList "--headless", "--path", "`"$root`"", "--import", "--log-file", "`"$log`"" -Wait | Out-Null
$p = Start-Process $godot -ArgumentList "--headless", "--path", "`"$root`"", "--script", "res://tools/generate_parts.gd", "--log-file", "`"$log`"" -Wait -PassThru
Get-Content $log | Where-Object { $_ -match "^(GEN|SCRIPT ERROR|ERROR|\s+at:)" }
Start-Process $godot -ArgumentList "--headless", "--path", "`"$root`"", "--import", "--log-file", "`"$log`"" -Wait | Out-Null
exit $p.ExitCode
