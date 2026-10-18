$ErrorActionPreference='Stop'
$root=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$out=Join-Path $env:TEMP ('zero-hour-tests-'+[guid]::NewGuid())
New-Item -ItemType Directory $out | Out-Null
$inc=Join-Path $root 'work\zero-hour-macos\Core\GameEngine\Include'
$clang=(Get-Command clang++).Source
function Build-And-Run([string]$name,[string[]]$sources,[string[]]$extra) {
    $exe=Join-Path $out ($name+'.exe')
    & $clang -std=c++17 -Wall -Wextra -Werror '-fprofile-instr-generate' '-fcoverage-mapping' "-I$inc" @extra @sources -o $exe
    if($LASTEXITCODE -ne 0){throw "Compile failed: $name"}
    $env:LLVM_PROFILE_FILE=Join-Path $out ($name+'.profraw')
    & $exe;if($LASTEXITCODE -ne 0){throw "Tests failed: $name"}
    & llvm-profdata merge -sparse $env:LLVM_PROFILE_FILE -o (Join-Path $out ($name+'.profdata'))
    if($LASTEXITCODE -ne 0){throw 'Coverage merge failed'}
    & llvm-cov show $exe ('-instr-profile='+ (Join-Path $out ($name+'.profdata'))) -format=html ('-output-dir='+ (Join-Path $out ('coverage\'+$name)))
    if($LASTEXITCODE -ne 0){throw 'Coverage export failed'}
}
Build-And-Run 'pacing' @((Join-Path $root 'work\performance-tests\fixed_step_test.cpp')) @()
Build-And-Run 'input' @((Join-Path $root 'work\input-tests\events.cpp')) @("-I$inc\Common")
Build-And-Run 'game-speed' @((Join-Path $root 'work\performance-tests\game_speed_test.cpp'),(Join-Path $root 'work\zero-hour-macos\Core\GameEngine\Source\Common\FramePacer.cpp')) @("-I$root\work\performance-tests\stubs")
& powershell.exe -NoLogo -NoProfile -STA -ExecutionPolicy Bypass -File (Join-Path $PSScriptRoot 'Launcher.ps1') -ValidateOnly
if($LASTEXITCODE -ne 0){throw 'Launcher validation failed'}
$destination=Join-Path $root 'outputs\windows-coverage'
New-Item -ItemType Directory -Force $destination | Out-Null
Copy-Item (Join-Path $out 'coverage\*') $destination -Recurse -Force
