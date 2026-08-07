# Build cl_stack_icu_mf2.dll into lib/windows-amd64/.
# Requires ICU MSVC build (CL_STACK_ICU_INCLUDE + bin64/lib beside source).
$ErrorActionPreference = "Stop"
$Root = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$Major = if ($env:ICU_MAJOR) { $env:ICU_MAJOR } else { "78" }
$Out = if ($env:DEST_DIR) { $env:DEST_DIR } else { Join-Path $Root "lib\windows-amd64" }
$Include = $env:CL_STACK_ICU_INCLUDE
if (-not $Include -and (Test-Path (Join-Path $Root "build\cl-stack-icu-include"))) {
  $Include = (Get-Content (Join-Path $Root "build\cl-stack-icu-include") -Raw).Trim()
}
if (-not $Include) { throw "CL_STACK_ICU_INCLUDE not set" }

$Src = Join-Path $Root "native\mf2\cl_stack_icu_mf2.cpp"
$HdrDir = Join-Path $Root "native\mf2"
if (-not (Test-Path $Src)) { throw "mf2 source missing: $Src" }

# Locate ICU link libs / DLLs from prior build-icu.ps1 layout.
$IcuVersion = if ($env:ICU_VERSION) { $env:ICU_VERSION } else { "78.1" }
$Build = Join-Path $Root "build\icu-$IcuVersion-windows-amd64"
$SrcRoot = Join-Path $Build "source"
if (-not (Test-Path $SrcRoot)) { $SrcRoot = Join-Path $Build "icu\source" }
$Bin64 = Join-Path $SrcRoot "bin64"
$Lib64 = Join-Path $SrcRoot "lib64"
if (-not (Test-Path $Bin64)) { throw "bin64 not found under $SrcRoot — run build-icu.ps1 first" }

$vswhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
$vsPath = $null
if (Test-Path $vswhere) {
  $vsPath = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 `
    -property installationPath
}
if (-not $vsPath) { throw "Visual Studio VC tools not found" }
$devCmd = Join-Path $vsPath "Common7\Tools\VsDevCmd.bat"
cmd /c "`"$devCmd`" -arch=amd64 -host_arch=amd64 && set" | ForEach-Object {
  if ($_ -match '^(.*?)=(.*)$') { Set-Item -Path "env:$($matches[1])" -Value $matches[2] }
}
if (-not (Get-Command cl -ErrorAction SilentlyContinue)) { throw "cl.exe not on PATH" }

New-Item -ItemType Directory -Force -Path $Out | Out-Null
$ObjDir = Join-Path $Root "build\mf2"
New-Item -ItemType Directory -Force -Path $ObjDir | Out-Null
$Obj = Join-Path $ObjDir "cl_stack_icu_mf2.obj"
$Dll = Join-Path $Out "cl_stack_icu_mf2.dll"
$Implib = Join-Path $ObjDir "cl_stack_icu_mf2.lib"

Write-Host "==> compile MF2 shim (MSVC)"
& cl /nologo /std:c++17 /EHsc /O2 /MD /LD `
  /DCL_STACK_ICU_MF2_BUILD=1 `
  /I"$Include" /I"$HdrDir" `
  /Fo"$Obj" /Fe"$Dll" /Fd"$ObjDir\cl_stack_icu_mf2.pdb" `
  "$Src" `
  /link /LIBPATH:"$Lib64" /LIBPATH:"$Bin64" `
  "icuin$Major.lib" "icuuc$Major.lib" "icudt$Major.lib" `
  /IMPLIB:"$Implib"
if ($LASTEXITCODE -ne 0) { throw "MF2 shim link failed" }

# Ensure ICU DLLs already staged in $Out (build-icu.ps1).
foreach ($name in @("icudt$Major.dll", "icuuc$Major.dll", "icuin$Major.dll")) {
  if (-not (Test-Path (Join-Path $Out $name))) {
    $srcDll = Join-Path $Bin64 $name
    if (Test-Path $srcDll) { Copy-Item $srcDll $Out -Force }
  }
}

Write-Host "OK: mf2 shim -> $Dll"
Get-Item $Dll | Format-Table Name, Length
