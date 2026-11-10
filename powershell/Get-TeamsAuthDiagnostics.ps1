<#
.SYNOPSIS
    Diagnoses common Microsoft Teams / M365 sign-in failures and optionally clears the Teams cache.

.DESCRIPTION
    Collects the signals usually behind Teams/M365 auth loops:
      - Device join state (Entra joined / registered, PRT present) from dsregcmd
      - TPM presence/readiness (TPM/keyset errors break token protection)
      - Teams client type and cache location
    With -ClearCache, closes Teams and clears the new Teams (MSTeams) and classic Teams caches.
    Read-only by default. Run as the affected user; TPM details need an elevated session.

.PARAMETER ClearCache
    Stops Teams and deletes its local cache folders.

.EXAMPLE
    .\Get-TeamsAuthDiagnostics.ps1

.EXAMPLE
    .\Get-TeamsAuthDiagnostics.ps1 -ClearCache
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$ClearCache
)

function Write-Section($title) { Write-Host "`n=== $title ===" -ForegroundColor Cyan }

# 1. Device join state
Write-Section 'Device join state (dsregcmd /status)'
$dsreg = dsregcmd /status
$keys = 'AzureAdJoined','DomainJoined','WorkplaceJoined','AzureAdPrt','TenantName','DeviceAuthStatus'
foreach ($k in $keys) {
    $line = $dsreg | Select-String -Pattern "^\s*$k\s*:" | Select-Object -First 1
    if ($line) { Write-Host ($line.ToString().Trim()) }
}
if ($dsreg -match 'AzureAdPrt\s*:\s*NO') {
    Write-Warning 'No Primary Refresh Token (PRT). SSO to M365 will fail; check device join and user sign-in.'
}

# 2. TPM
Write-Section 'TPM'
try {
    $tpm = Get-Tpm -ErrorAction Stop
    $tpm | Select-Object TpmPresent, TpmReady, TpmEnabled, TpmActivated | Format-List
    if (-not $tpm.TpmReady) { Write-Warning 'TPM not ready: can cause keyset / token errors in Teams and Office.' }
} catch {
    Write-Host 'Could not read TPM (run elevated for full details).' -ForegroundColor Yellow
}

# 3. Teams client and cache
Write-Section 'Teams client'
$newTeamsCache     = Join-Path $env:LOCALAPPDATA 'Packages\MSTeams_8wekyb3d8bbwe\LocalCache'
$classicTeamsCache = Join-Path $env:APPDATA 'Microsoft\Teams'

$newInstalled = Get-AppxPackage -Name 'MSTeams' -ErrorAction SilentlyContinue
Write-Host "New Teams installed : $([bool]$newInstalled)"
Write-Host "New Teams cache     : $(Test-Path $newTeamsCache)"
Write-Host "Classic Teams cache : $(Test-Path $classicTeamsCache)"

if ($ClearCache -and $PSCmdlet.ShouldProcess('Teams cache', 'Stop Teams and delete cache')) {
    Write-Section 'Clearing cache'
    Get-Process -Name 'ms-teams','Teams' -ErrorAction SilentlyContinue | Stop-Process -Force
    Start-Sleep -Seconds 2
    foreach ($path in @($newTeamsCache, $classicTeamsCache)) {
        if (Test-Path $path) {
            Remove-Item -Path (Join-Path $path '*') -Recurse -Force -ErrorAction SilentlyContinue
            Write-Host "Cleared: $path" -ForegroundColor Green
        }
    }
    Write-Host 'Reopen Teams and sign in again.' -ForegroundColor Yellow
}

Write-Section 'Next steps if sign-in still fails'
@(
    '- Check Entra ID sign-in logs for the user (Conditional Access failure reason).',
    '- Confirm the device is compliant if a compliance-based CA policy applies.',
    '- If TPM is not ready, clear/reinitialize TPM per vendor guidance, then re-register the device.'
) | ForEach-Object { Write-Host $_ }
