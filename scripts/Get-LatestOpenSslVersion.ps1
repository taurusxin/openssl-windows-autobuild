param(
    [string]$GitHubToken = $env:GITHUB_TOKEN
)

$headers = @{
    Accept = 'application/vnd.github+json'
    'X-GitHub-Api-Version' = '2022-11-28'
}

if (-not [string]::IsNullOrWhiteSpace($GitHubToken)) {
    $headers.Authorization = "Bearer $GitHubToken"
}

$releases = Invoke-RestMethod `
    -Uri 'https://api.github.com/repos/openssl/openssl/releases?per_page=50' `
    -Headers $headers

$latest = $releases |
    Where-Object {
        -not $_.draft -and
        -not $_.prerelease -and
        $_.tag_name -match '^openssl-(\d+)\.(\d+)\.(\d+)([a-z]?)$'
    } |
    ForEach-Object {
        $_.tag_name -match '^openssl-(\d+)\.(\d+)\.(\d+)([a-z]?)$' | Out-Null
        [pscustomobject]@{
            TagName = $_.tag_name
            Major = [int]$Matches[1]
            Minor = [int]$Matches[2]
            Patch = [int]$Matches[3]
            Suffix = $Matches[4]
        }
    } |
    Sort-Object -Property Major, Minor, Patch, Suffix -Descending |
    Select-Object -First 1

if (-not $latest) {
    throw 'Could not resolve the latest OpenSSL release from GitHub.'
}

$latest.TagName -replace '^openssl-', ''
