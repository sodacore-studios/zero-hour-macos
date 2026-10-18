param([string]$BuildDirectory='')
$ErrorActionPreference='Stop'
$repo=Split-Path (Split-Path $PSScriptRoot -Parent) -Parent
$source=Join-Path $repo 'work\zero-hour-macos'
if(!$BuildDirectory){$BuildDirectory=Join-Path $source 'build\windows-x86'}
$vswhere="${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vs=& $vswhere -latest -products '*' -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if(!$vs){throw 'Visual Studio 2022 C++ Build Tools are required'}
# OpenSSL's build invokes the x86 compiler and nmake directly.
$devCmd=Join-Path $vs 'Common7\Tools\VsDevCmd.bat'
& $env:ComSpec /s /c "`"`"$devCmd`" -no_logo -arch=x86 -host_arch=x64 && set`"" | ForEach-Object {
    if($_ -match '^([^=]+)=(.*)$'){[Environment]::SetEnvironmentVariable($Matches[1],$Matches[2],'Process')}
}
if(Test-Path 'C:\Strawberry\perl\bin\perl.exe'){$env:PATH='C:\Strawberry\perl\bin;'+$env:PATH}
if(!(Get-Command perl -ErrorAction SilentlyContinue)){throw 'Install Strawberry Perl to build OpenSSL'}
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
