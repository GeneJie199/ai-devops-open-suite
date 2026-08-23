[CmdletBinding()]
param(
    [string]$Prefix = $(if ($env:AI_DEVOPS_HOME) { $env:AI_DEVOPS_HOME } else { Join-Path $env:LOCALAPPDATA 'ai-devops-suite' }),
    [switch]$NoStart,
    [switch]$EnableAutostart
)

$ErrorActionPreference = 'Stop'
$baseUrl = if ($env:AI_DEVOPS_RELEASE_URL) { $env:AI_DEVOPS_RELEASE_URL.TrimEnd('/') } else { 'https://github.com/GeneJie199/ai-devops-open-suite/releases/latest/download' }
$archive = 'ai-devops-open-suite-online.zip'
$stage = Join-Path ([IO.Path]::GetTempPath()) ('ai-devops-bootstrap-' + [guid]::NewGuid().ToString('N'))

try {
    New-Item -ItemType Directory -Path $stage | Out-Null
    $archivePath = Join-Path $stage $archive
    $checksumsPath = Join-Path $stage 'checksums.txt'
    Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl/$archive" -OutFile $archivePath -TimeoutSec 120
    Invoke-WebRequest -UseBasicParsing -Uri "$baseUrl/checksums.txt" -OutFile $checksumsPath -TimeoutSec 120
    $entry = Get-Content -LiteralPath $checksumsPath | Where-Object { $_ -match ('^[0-9a-fA-F]{64}\s+\*?' + [regex]::Escape($archive) + '$') } | Select-Object -First 1
    if (-not $entry) { throw "Checksum entry not found for $archive" }
    $expected = ($entry -split '\s+')[0].ToLowerInvariant()
    $actual = (Get-FileHash -LiteralPath $archivePath -Algorithm SHA256).Hash.ToLowerInvariant()
    if ($actual -ne $expected) { throw "SHA-256 verification failed for $archive" }
    Expand-Archive -LiteralPath $archivePath -DestinationPath $stage
    $installer = Join-Path $stage 'ai-devops-open-suite\scripts\install-suite.ps1'
    if (-not (Test-Path -LiteralPath $installer -PathType Leaf)) { throw 'Verified archive does not contain the suite installer.' }
    & $installer -Prefix $Prefix -Start:(-not $NoStart) -EnableAutostart:$EnableAutostart
    if (-not $NoStart) {
        & (Join-Path $Prefix 'bin\suitectl.ps1') doctor -SuiteHome $Prefix
    }
} finally {
    $resolved = [IO.Path]::GetFullPath($stage)
    $tempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath())
    if ($resolved.StartsWith($tempRoot, [StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $resolved).StartsWith('ai-devops-bootstrap-')) {
        Remove-Item -LiteralPath $resolved -Recurse -Force -ErrorAction SilentlyContinue
    }
}
