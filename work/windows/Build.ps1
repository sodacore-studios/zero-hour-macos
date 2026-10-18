param([string]$BuildDirectory='')
$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$source=Join-Path $repo 'work\zero-hour-macos'
if(!$BuildDirectory){$BuildDirectory=Join-Path $source 'build\windows-x86'}
$cmake=Get-Command cmake -ErrorAction SilentlyContinue
if(!$cmake){
    $vswhere="${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
    $vs=& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
    $cmake=Join-Path $vs 'Common7\IDE\CommonExtensions\Microsoft\CMake\CMake\bin\cmake.exe'
}else{$cmake=$cmake.Source}
& $cmake -S $source -B $BuildDirectory -G 'Visual Studio 17 2022' -A Win32 -DRTS_BUILD_GENERALS=OFF -DRTS_BUILD_CORE_TOOLS=OFF -DRTS_BUILD_ZEROHOUR_TOOLS=OFF '-DCMAKE_MSVC_RUNTIME_LIBRARY=MultiThreadedDLL'
if($LASTEXITCODE -ne 0){throw 'Windows configure failed'}
& $cmake --build $BuildDirectory --config Release --target z_generals --parallel 2
if($LASTEXITCODE -ne 0){throw 'Windows build failed'}
