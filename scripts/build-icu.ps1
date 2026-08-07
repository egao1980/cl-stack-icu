# Build shared ICU4C into lib/windows-amd64/ with MSVC (allinone.sln).
# Env: ICU_VERSION (default 78.1)
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Version = if ($env:ICU_VERSION) { $env:ICU_VERSION } else { "78.1" }
$Major = $Version.Split('.')[0]
$Out = Join-Path $Root "lib\windows-amd64"
$Build = Join-Path $Root "build\icu-$Version-windows-amd64"
$Tgz = Join-Path $Root "build\icu4c-$Version-sources.tgz"
$Url = "https://github.com/unicode-org/icu/releases/download/release-$Version/icu4c-$Version-sources.tgz"

New-Item -ItemType Directory -Force -Path (Join-Path $Root "build") | Out-Null
if (-not (Test-Path $Tgz)) {
  Write-Host "==> download $Url"
  Invoke-WebRequest -Uri $Url -OutFile $Tgz
}

if (Test-Path $Build) { Remove-Item -Recurse -Force $Build }
New-Item -ItemType Directory -Force -Path $Build | Out-Null
tar -xzf $Tgz -C $Build --strip-components=1

$Src = Join-Path $Build "source"
if (-not (Test-Path (Join-Path $Src "allinone\allinone.sln"))) {
  $Src = Join-Path $Build "icu\source"
}
$Sln = Join-Path $Src "allinone\allinone.sln"
if (-not (Test-Path $Sln)) {
  throw "allinone.sln not found under $Build"
}

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vsPath = $null
if (Test-Path $vswhere) {
  $vsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath
}
if (-not $vsPath) {
  throw "Visual Studio with VC tools not found (vswhere)"
}
$devCmd = Join-Path $vsPath "Common7\Tools\VsDevCmd.bat"
if (-not (Test-Path $devCmd)) {
  throw "VsDevCmd.bat not found under $vsPath"
}
Write-Host "==> enter VS x64 env via VsDevCmd.bat ($vsPath)"
cmd /c "`"$devCmd`" -arch=amd64 -host_arch=amd64 && set" | ForEach-Object {
  if ($_ -match '^(.*?)=(.*)$') {
    Set-Item -Path "env:$($matches[1])" -Value $matches[2]
  }
}

if (-not (Get-Command msbuild -ErrorAction SilentlyContinue)) {
  throw "msbuild not on PATH after VsDevCmd"
}

Write-Host "==> msbuild ICU $Version (x64 Release, SkipUWP)"
& msbuild $Sln `
  /m `
  /p:Configuration=Release `
  /p:Platform=x64 `
  /p:SkipUWP=true
if ($LASTEXITCODE -ne 0) { throw "msbuild failed" }

# Headers: ICU copies unicode/*.h beside the source tree via targets.
$IncludeCandidates = @(
  (Join-Path $Build "include"),
  (Join-Path $Src "..\include"),
  (Join-Path $Src "common\unicode")
)
$Include = $null
foreach ($c in $IncludeCandidates) {
  $utypes = Join-Path $c "unicode\utypes.h"
  $utypesFlat = Join-Path $c "utypes.h"
  if (Test-Path $utypes) { $Include = $c; break }
  if (Test-Path $utypesFlat) {
    # Point grovel at parent that has unicode/ — create a staging include root.
    $stageInc = Join-Path $Build "prefix\include"
    New-Item -ItemType Directory -Force -Path (Join-Path $stageInc "unicode") | Out-Null
    Copy-Item (Join-Path $Src "common\unicode\*") (Join-Path $stageInc "unicode") -Force
    Copy-Item (Join-Path $Src "i18n\unicode\*") (Join-Path $stageInc "unicode") -Force -ErrorAction SilentlyContinue
    $Include = $stageInc
    break
  }
}
if (-not $Include) {
  # Fallback: assemble include/unicode from common+i18n headers.
  $stageInc = Join-Path $Build "prefix\include"
  New-Item -ItemType Directory -Force -Path (Join-Path $stageInc "unicode") | Out-Null
  Copy-Item (Join-Path $Src "common\unicode\*") (Join-Path $stageInc "unicode") -Force
  if (Test-Path (Join-Path $Src "i18n\unicode")) {
    Copy-Item (Join-Path $Src "i18n\unicode\*") (Join-Path $stageInc "unicode") -Force
  }
  $Include = $stageInc
}
if (-not (Test-Path (Join-Path $Include "unicode\utypes.h"))) {
  throw "unicode/utypes.h not found for grovel (include=$Include)"
}

$env:CL_STACK_ICU_INCLUDE = $Include
$incFile = Join-Path $Root "build\cl-stack-icu-include"
Set-Content -Path $incFile -Value $Include -NoNewline
Write-Host "CL_STACK_ICU_INCLUDE=$Include"

$Bin64 = Join-Path $Src "bin64"
if (-not (Test-Path $Bin64)) {
  $Bin64 = Join-Path $Build "bin64"
}
if (-not (Test-Path $Bin64)) {
  throw "bin64/ not found after msbuild"
}

Write-Host "==> stage DLLs from $Bin64 -> $Out"
if (Test-Path $Out) { Remove-Item -Recurse -Force $Out }
New-Item -ItemType Directory -Force -Path $Out | Out-Null

$needed = @(
  "icudt$Major.dll",
  "icuuc$Major.dll",
  "icuin$Major.dll"
)
foreach ($name in $needed) {
  $srcDll = Join-Path $Bin64 $name
  if (-not (Test-Path $srcDll)) {
    Get-ChildItem $Bin64 -Filter *.dll | Format-Table Name
    throw "missing $name under $Bin64"
  }
  Copy-Item $srcDll (Join-Path $Out $name) -Force
  Write-Host "  copied $name"
}

Write-Host "==> staged:"
Get-ChildItem $Out | Format-Table Name, Length
Write-Host "OK: icu $Version -> windows/amd64"
