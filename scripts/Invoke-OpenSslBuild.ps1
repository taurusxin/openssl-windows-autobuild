param(
    [string]$Version = '',
    [string[]]$Targets = @('x64'),

    [ValidateSet('both', 'shared', 'static')]
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

$matrixJson = & (Join-Path $PSScriptRoot 'New-OpenSslBuildMatrix.ps1') `
    -Targets $Targets `
    -Linkage $Linkage

$matrix = $matrixJson | ConvertFrom-Json
$packages = @()

foreach ($item in $matrix.include) {
    $args = @{
        Version = $Version
        Target = $item.arch
        Linkage = $item.linkage
        SourceRoot = $SourceRoot
        InstallRoot = $InstallRoot
        PackageRoot = $PackageRoot
    }

    if ($NoPackage) {
        $args.NoPackage = $true
    }

    $result = & (Join-Path $PSScriptRoot 'Build-OpenSslWindows.ps1') @args
    if (-not $NoPackage) {
        $packages += ($result | Select-Object -Last 1)
    }
}

if (-not $NoPackage) {
    $packages
}
