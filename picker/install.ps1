param([switch]$Force, [switch]$SkipShortcuts)
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

# ---------- section 1: clone / refresh the template repo ----------
$repo = Join-Path $PSScriptRoot 'repo'
if (-not (Test-Path (Join-Path $repo '.git'))) {
    git clone --depth 1 https://github.com/zarazhangrui/beautiful-html-templates $repo
} else {
    git -C $repo fetch --depth 1 origin main
    git -C $repo reset --hard origin/main
}

# ---------- section 2: templates.json + library.json.js ----------
$index = Get-Content (Join-Path $repo 'index.json') -Raw -Encoding UTF8 | ConvertFrom-Json
$templates = @(
    $index.templates | ForEach-Object {
        [ordered]@{
            slug        = $_.slug
            name        = $_.name
            tagline     = $_.tagline
            scheme      = $_.scheme
            formality   = $_.formality
            density     = $_.density
            slide_count = $_.slide_count
            occasion    = @($_.occasion)
        }
    }
)
$payload = [ordered]@{
    updated_at = (Get-Date).ToUniversalTime().ToString('o')
    templates  = $templates
}
$json = ConvertTo-Json $payload -Depth 5
Set-Content (Join-Path $PSScriptRoot 'templates.json')   -Value $json -Encoding UTF8
Set-Content (Join-Path $PSScriptRoot 'library.json.js')  -Value ('window.LIBRARY = ' + $json + ';' + [Environment]::NewLine) -Encoding UTF8

# ---------- sections 3+ are appended in later tasks ----------
Write-Host 'install: sections 1-2 done (templates.json + library.json.js)'
