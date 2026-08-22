[CmdletBinding()]
param()

$ErrorActionPreference = 'Stop'
$Repository = [IO.Path]::GetFullPath((Split-Path -Parent $PSScriptRoot))
$TempRoot = [IO.Path]::GetFullPath([IO.Path]::GetTempPath()).TrimEnd('\')
$Work = Join-Path $TempRoot ('ai-devops-bootstrap-accept-' + [guid]::NewGuid().ToString('N'))
$Serve = Join-Path $Work 'release'
$Package = Join-Path $Work 'stage\ai-devops-open-suite'
$Prefix = Join-Path $Work 'install\ai-devops-suite'
$Server = $null

try {
    New-Item -ItemType Directory -Force -Path (Join-Path $Package 'scripts'), (Join-Path $Package 'examples'), (Join-Path $Package 'docs') | Out-Null
    Copy-Item (Join-Path $Repository 'scripts\install-suite.ps1'), (Join-Path $Repository 'scripts\install-suite.sh'), (Join-Path $Repository 'scripts\suitectl.ps1'), (Join-Path $Repository 'scripts\suitectl.sh') (Join-Path $Package 'scripts')
    Copy-Item (Join-Path $Repository 'examples\release-report.demo.json') (Join-Path $Package 'examples')
    Copy-Item (Join-Path $Repository 'docs\quickstart.md'), (Join-Path $Repository 'docs\offline-install.md') (Join-Path $Package 'docs')
    Copy-Item (Join-Path $Repository 'manifests') (Join-Path $Package 'manifests') -Recurse
    foreach ($name in 'README.md','LICENSE','SECURITY.md','COMPATIBILITY.md','SUPPORT_MATRIX.md','RELEASE_POLICY.md','suite-manifest.json') {
        Copy-Item (Join-Path $Repository $name) $Package
    }

    New-Item -ItemType Directory -Force -Path $Serve | Out-Null
    $Zip = Join-Path $Serve 'ai-devops-open-suite-online.zip'
    $Tar = Join-Path $Serve 'ai-devops-open-suite-online.tar.gz'
    Compress-Archive -Path $Package -DestinationPath $Zip -CompressionLevel Optimal
    & tar -C (Split-Path -Parent $Package) -czf $Tar (Split-Path -Leaf $Package)
    if ($LASTEXITCODE -ne 0) { throw 'Could not build the bootstrap tar archive.' }
    $Lines = foreach ($path in $Zip, $Tar) {
        $hash = (Get-FileHash -Algorithm SHA256 -LiteralPath $path).Hash.ToLowerInvariant()
        "$hash  $(Split-Path -Leaf $path)"
    }
    [IO.File]::WriteAllText((Join-Path $Serve 'checksums.txt'), (($Lines -join "`n") + "`n"), (New-Object Text.UTF8Encoding($false)))

    $Port = 41000 + (Get-Random -Minimum 0 -Maximum 10000)
    $Python = (Get-Command python).Source
    $Server = Start-Process -FilePath $Python -ArgumentList @('-m','http.server',"$Port",'--bind','127.0.0.1','--directory',$Serve) -WindowStyle Hidden -PassThru
    $Ready = $false
    foreach ($attempt in 1..20) {
        try {
            if ((Invoke-WebRequest -UseBasicParsing -TimeoutSec 1 "http://127.0.0.1:$Port/checksums.txt").StatusCode -eq 200) { $Ready = $true; break }
        } catch {}
        Start-Sleep -Milliseconds 250
    }
    if (-not $Ready) { throw 'The isolated release endpoint did not start.' }

    $PreviousReleaseUrl = $env:AI_DEVOPS_RELEASE_URL
    try {
        $env:AI_DEVOPS_RELEASE_URL = "http://127.0.0.1:$Port"
        & (Join-Path $Repository 'scripts\bootstrap.ps1') -Prefix $Prefix -NoStart
    } finally {
        $env:AI_DEVOPS_RELEASE_URL = $PreviousReleaseUrl
    }
    foreach ($name in 'lifecycle-validate.exe','devcycle.exe','infrascout.exe','fleetctl.exe','releaseguard.exe') {
        if (-not (Test-Path -LiteralPath (Join-Path $Prefix "bin\$name") -PathType Leaf)) { throw "Bootstrap installation is missing $name." }
    }
    $State = Get-Content -Raw (Join-Path $Prefix 'config\install-state.json') | ConvertFrom-Json
    $ComponentCount = @($State.components).Count
    if ($State.source -ne 'online' -or $ComponentCount -ne 5) { throw 'Bootstrap installation metadata is invalid.' }
    [ordered]@{
        schema = 'ai-devops.bootstrap-acceptance/v1'
        platform = 'windows-amd64'
        suiteVersion = $State.suiteVersion
        checksum = $true
        componentCount = $ComponentCount
        cleanInstall = $true
        cleanup = $true
    } | ConvertTo-Json -Compress
} finally {
    if ($Server) {
        Stop-Process -Id $Server.Id -Force -ErrorAction SilentlyContinue
        Wait-Process -Id $Server.Id -Timeout 5 -ErrorAction SilentlyContinue
    }
    $Resolved = [IO.Path]::GetFullPath($Work)
    if ($Resolved.StartsWith($TempRoot + '\', [StringComparison]::OrdinalIgnoreCase) -and (Split-Path -Leaf $Resolved).StartsWith('ai-devops-bootstrap-accept-')) {
        Remove-Item -LiteralPath $Resolved -Recurse -Force -ErrorAction SilentlyContinue
    }
}
