param(
    [Parameter(Mandatory = $true)]
    [string]$Repository,

    [Parameter(Mandatory = $true)]
    [string]$Version,

    [string]$GitHubToken = $env:GITHUB_TOKEN
)

$headers = @{
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
}

if (-not [string]::IsNullOrWhiteSpace($GitHubToken)) {
    $headers.Authorization = "Bearer $GitHubToken"
}

$tag = "openssl-$Version"
$encodedTag = [System.Uri]::EscapeDataString($tag)
$releaseExists = $false
$tagExists = $false

try {
    Invoke-RestMethod `
        -Uri "https://api.github.com/repos/$Repository/releases/tags/$encodedTag" `
        -Headers $headers | Out-Null
    $releaseExists = $true
} catch {
    if ($_.Exception.Response.StatusCode.value__ -ne 404) {
        throw
    }
}

try {
    Invoke-RestMethod `
        -Uri "https://api.github.com/repos/$Repository/git/ref/tags/$encodedTag" `
        -Headers $headers | Out-Null
    $tagExists = $true
} catch {
    if ($_.Exception.Response.StatusCode.value__ -ne 404) {
        throw
    }
}

if ($releaseExists -or $tagExists) {
    'true'
} else {
    'false'
}
