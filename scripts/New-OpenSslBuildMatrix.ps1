param(
    [string[]]$Targets = @('x64', 'x86'),
    [ValidateSet('both', 'shared', 'static')]
    [string]$Linkage = 'both'
)

$targetMap = @{
    x64 = @{
        arch = 'x64'
        perl_target = 'VC-WIN64A'
        vcvars_arch = 'x64'
    }
    x86 = @{
        arch = 'x86'
        perl_target = 'VC-WIN32'
        vcvars_arch = 'x86'
    }
}

$linkageMap = @{
    shared = @{
        linkage = 'shared'
        configure_extra = ''
    }
    static = @{
        linkage = 'static'
        configure_extra = 'no-shared'
    }
}

$targetList = ($Targets -join ',').Split(',') |
    ForEach-Object { $_.Trim().ToLowerInvariant() } |
    Where-Object { $_ }

if ($Linkage -eq 'both') {
    $linkageList = @('shared', 'static')
} else {
    $linkageList = @($Linkage)
}

$include = @()
foreach ($target in $targetList) {
    if (-not $targetMap.ContainsKey($target)) {
        throw "Unsupported target '$target'. Supported values are x64 and x86."
    }

    foreach ($link in $linkageList) {
        $include += @{
            arch = $targetMap[$target].arch
            perl_target = $targetMap[$target].perl_target
            vcvars_arch = $targetMap[$target].vcvars_arch
            linkage = $linkageMap[$link].linkage
            configure_extra = $linkageMap[$link].configure_extra
        }
    }
}

if ($include.Count -eq 0) {
    throw 'Build matrix is empty.'
}

@{ include = $include } | ConvertTo-Json -Compress -Depth 5
