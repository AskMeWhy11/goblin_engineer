# Saves a PNG of a scene. Usage:
#   screenshot.ps1 -Scene res://scenes/ui/main_menu.tscn -Out C:\tmp\menu.png [-Level level_01] [-Setup res://tools/shots/x.gd] [-Frames 30]
param([string]$Scene, [string]$Out, [string]$Level = "", [string]$Setup = "", [int]$Frames = 30)
$godot = "D:\godot_prjct\Godot_v4.7.2-stable_win64.exe"
$root = (Resolve-Path (Join-Path $PSScriptRoot "..")).Path
$log = Join-Path $root "tests\last_shot.log"
$env:SHOT_SCENE = $Scene; $env:SHOT_OUT = $Out; $env:SHOT_LEVEL = $Level; $env:SHOT_SETUP = $Setup; $env:SHOT_FRAMES = "$Frames"
$p = Start-Process $godot -ArgumentList "--path", "`"$root`"", "--log-file", "`"$log`"", "res://tools/screenshot.tscn" -Wait -PassThru
Get-Content $log | Where-Object { $_ -match "^(SHOT|SCRIPT ERROR|ERROR|\s+at:)" }
exit $p.ExitCode
