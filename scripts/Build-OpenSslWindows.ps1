param(
    [string]$Version = '',

    [ValidateSet('x64', 'x86')]
    [string]$Target = 'x64',

    [ValidateSet('shared', 'static')]
    [string]$Linkage = 'shared',

    [string]$SourceRoot = (Join-Path $PSScriptRoot '..\build'),
    [string]$InstallRoot = (Join-Path $PSScriptRoot '..\dist'),
    [string]$PackageRoot = (Join-Path $PSScriptRoot '..\packages'),

    [switch]$NoPackage
)

$ErrorActionPreference = 'Stop'

if ([string]::IsNullOrWhiteSpace($Version)) {
    $Version = & (Join-Path $PSScriptRoot 'Get-LatestOpenSslVersion.ps1')
}

$targetMap = @{
    x64 = @{
        PerlTarget = 'VC-WIN64A'
        VcVarsArch = 'x64'
    }
    x86 = @{
        PerlTarget = 'VC-WIN32'
        VcVarsArch = 'x86'
    }
}

$configureArgs = @($targetMap[$Target].PerlTarget)
if ($Linkage -eq 'static') {
    $configureArgs += 'no-shared'
}

New-Item -ItemType Directory -Force -Path $SourceRoot | Out-Null
New-Item -ItemType Directory -Force -Path $InstallRoot | Out-Null
New-Item -ItemType Directory -Force -Path $PackageRoot | Out-Null

$sourceRootPath = (Resolve-Path -LiteralPath $SourceRoot).Path
$installRootPath = (Resolve-Path -LiteralPath $InstallRoot).Path
$packageRootPath = (Resolve-Path -LiteralPath $PackageRoot).Path

$sourceCacheDir = Join-Path $sourceRootPath "openssl-$Version-src"
$sourceDir = Join-Path $sourceRootPath "openssl-$Version-$Target-$Linkage"
$installDir = Join-Path $installRootPath "openssl-$Version-windows-$Target-$Linkage"
$archive = Join-Path $sourceRootPath "openssl-$Version.tar.gz"
$sourceUrl = "https://github.com/openssl/openssl/releases/download/openssl-$Version/openssl-$Version.tar.gz"

function Test-IsChildPath {
    param(
        [Parameter(Mandatory = $true)]
        [string]$Parent,

        [Parameter(Mandatory = $true)]
        [string]$Child
    )

    $parentPath = [System.IO.Path]::GetFullPath($Parent).TrimEnd('\') + '\'
    $childPath = [System.IO.Path]::GetFullPath($Child)
    $childPath.StartsWith($parentPath, [System.StringComparison]::OrdinalIgnoreCase)
}

if (-not (Get-Command perl -ErrorAction SilentlyContinue)) {
    throw 'Perl was not found in PATH. Install Strawberry Perl and open a new terminal.'
}

if (-not (Get-Command nasm -ErrorAction SilentlyContinue)) {
    throw 'NASM was not found in PATH. Install NASM and open a new terminal.'
}

if (-not (Get-Command nmake -ErrorAction SilentlyContinue)) {
    Write-Host 'nmake was not found in the current PATH. The script will load the VS developer environment before building.'
}

$vsWhere = "${env:ProgramFiles(x86)}\Microsoft Visual Studio\Installer\vswhere.exe"
if (-not (Test-Path $vsWhere)) {
    throw 'vswhere.exe was not found. Install Visual Studio 2026 Build Tools with the Desktop development with C++ workload.'
}

$vsInstall = & $vsWhere -latest -products * -requires Microsoft.VisualStudio.Component.VC.Tools.x86.x64 -property installationPath
if ([string]::IsNullOrWhiteSpace($vsInstall)) {
    throw 'Visual Studio C++ tools were not found. Install Visual Studio 2026 Build Tools with the Desktop development with C++ workload.'
}

$vcVars = Join-Path $vsInstall 'VC\Auxiliary\Build\vcvarsall.bat'
if (-not (Test-Path $vcVars)) {
    throw "vcvarsall.bat was not found: $vcVars"
}

if (-not (Test-Path $sourceCacheDir)) {
    if (-not (Test-Path $archive)) {
        Write-Host "Downloading $sourceUrl"
        Invoke-WebRequest -Uri $sourceUrl -OutFile $archive
    }

    Write-Host "Extracting $archive"
    tar -xzf $archive -C $sourceRootPath

    $extractedDir = Join-Path $sourceRootPath "openssl-$Version"
    if (-not (Test-Path $extractedDir)) {
        throw "Source directory was not created: $extractedDir"
    }

    Move-Item -LiteralPath $extractedDir -Destination $sourceCacheDir
}

if (Test-Path $sourceDir) {
    if (-not (Test-IsChildPath -Parent $sourceRootPath -Child $sourceDir)) {
        throw "Refusing to remove a source directory outside SourceRoot: $sourceDir"
    }

    Remove-Item -LiteralPath $sourceDir -Recurse -Force
}

Copy-Item -LiteralPath $sourceCacheDir -Destination $sourceDir -Recurse -Force
New-Item -ItemType Directory -Force -Path $installDir | Out-Null

$configureLine = "perl Configure $($configureArgs -join ' ') --prefix=`"$installDir`" --openssldir=`"$installDir\ssl`""
$cmdFile = Join-Path ([System.IO.Path]::GetTempPath()) "build-openssl-$Version-$Target-$Linkage-$PID.cmd"
$cmdLines = @(
    '@echo on',
    "call `"$vcVars`" $($targetMap[$Target].VcVarsArch)",
    $configureLine,
    'nmake',
    'nmake install_sw'
)

Write-Host "Building OpenSSL $Version for Windows $Target $Linkage"
Set-Content -LiteralPath $cmdFile -Value $cmdLines -Encoding ASCII

Push-Location $sourceDir
try {
    cmd /d /s /c "`"$cmdFile`""
    if ($LASTEXITCODE -ne 0) {
        throw "OpenSSL build failed with exit code $LASTEXITCODE."
    }
} finally {
    Pop-Location
    Remove-Item -LiteralPath $cmdFile -Force -ErrorAction SilentlyContinue
}

$opensslExe = Join-Path $installDir 'bin\openssl.exe'
if (-not (Test-Path $opensslExe)) {
    throw "OpenSSL executable was not found: $opensslExe"
}

& $opensslExe version -a

Get-ChildItem -Path $installDir -Recurse -Include *.pdb -File |
    Remove-Item -Force

if ($NoPackage) {
    Write-Host "Installed to $installDir"
    return
}

$packageName = "openssl-$Version-windows-$Target-$Linkage"
$zipPath = Join-Path $packageRootPath "$packageName.zip"
Compress-Archive -Path "$installDir\*" -DestinationPath $zipPath -Force

Write-Host "Package created: $zipPath"
$zipPath
