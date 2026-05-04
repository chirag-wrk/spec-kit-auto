# Record a deterministic snapshot (hashes + metadata) of spec.md for reproducibility.
# Run from repository root after spec.md exists.
$ErrorActionPreference = 'Stop'

. "$PSScriptRoot/common.ps1"

$paths = Get-FeaturePathsEnv

if (-not (Test-Path $paths.FEATURE_SPEC -PathType Leaf)) {
    Write-Error "spec.md not found at $($paths.FEATURE_SPEC)"
}

$slug = Split-Path -Leaf $paths.FEATURE_DIR
$outDir = Join-Path $paths.REPO_ROOT '.specify/spec-snapshots'
New-Item -ItemType Directory -Force -Path $outDir | Out-Null
$outFile = Join-Path $outDir "$slug.json"

$ts = (Get-Date).ToUniversalTime().ToString('yyyy-MM-ddTHH:mm:ssZ')
$commit = $null
if ($paths.HAS_GIT) {
    try {
        $commit = git -C $paths.REPO_ROOT rev-parse HEAD 2>$null
    } catch {
        $commit = $null
    }
}

$specHash = (Get-FileHash -Path $paths.FEATURE_SPEC -Algorithm SHA256).Hash.ToLowerInvariant()
$reqFile = Join-Path $paths.FEATURE_DIR 'checklists/requirements.md'
$reqHash = $null
if (Test-Path $reqFile -PathType Leaf) {
    $reqHash = (Get-FileHash -Path $reqFile -Algorithm SHA256).Hash.ToLowerInvariant()
}

$obj = [ordered]@{
    feature_dir   = $paths.FEATURE_DIR
    spec_path     = $paths.FEATURE_SPEC
    spec_sha256   = $specHash
    recorded_at   = $ts
    git_commit    = $commit
}
if ($reqHash) {
    $obj['requirements_path'] = $reqFile
    $obj['requirements_sha256'] = $reqHash
}

[PSCustomObject]$obj | ConvertTo-Json -Depth 4 | Set-Content -Path $outFile -Encoding utf8
Write-Output "Wrote $outFile"
