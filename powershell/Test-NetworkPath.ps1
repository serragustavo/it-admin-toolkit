<#
.SYNOPSIS
    Quick network health check: gateway, DNS, internet, public IP and double-NAT detection.

.DESCRIPTION
    First-response script for "the internet is slow / down" tickets.
      - Shows active adapter, IP, gateway and DNS servers
      - Pings gateway and a public host, resolves a DNS name
      - Gets the public IP
      - Traces the first hops and flags DOUBLE NAT when more than one private
        (RFC1918 / CGNAT) hop appears before the public internet.

.PARAMETER Target
    Public host used for latency and trace tests. Default: 1.1.1.1

.EXAMPLE
    .\Test-NetworkPath.ps1
#>
[CmdletBinding()]
param(
    [string]$Target = '1.1.1.1'
)

function Test-PrivateIP([string]$ip) {
    return $ip -match '^(10\.|192\.168\.|172\.(1[6-9]|2\d|3[01])\.|100\.(6[4-9]|[7-9]\d|1[01]\d|12[0-7])\.)'
}

function Write-Section($title) { Write-Host "`n=== $title ===" -ForegroundColor Cyan }

Write-Section 'Active adapter'
$cfg = Get-NetIPConfiguration | Where-Object { $_.IPv4DefaultGateway -and $_.NetAdapter.Status -eq 'Up' } | Select-Object -First 1
if (-not $cfg) { Write-Error 'No active adapter with a default gateway.'; return }
$gateway = $cfg.IPv4DefaultGateway.NextHop
[PSCustomObject]@{
    Adapter = $cfg.InterfaceAlias
    IPv4    = $cfg.IPv4Address.IPAddress
    Gateway = $gateway
    DNS     = ($cfg.DNSServer | Where-Object AddressFamily -eq 2).ServerAddresses -join ', '
} | Format-List

Write-Section 'Connectivity'
$gw  = Test-Connection -ComputerName $gateway -Count 4 -ErrorAction SilentlyContinue
$net = Test-Connection -ComputerName $Target  -Count 4 -ErrorAction SilentlyContinue
$latency = { param($r) if ($r) { [math]::Round(($r | Measure-Object -Property ResponseTime -Average).Average, 1) } else { 'FAIL' } }
Write-Host "Gateway $gateway avg ms : $(& $latency $gw)"
Write-Host "Internet $Target avg ms : $(& $latency $net)"

try {
    $dns = Resolve-DnsName -Name 'www.microsoft.com' -Type A -ErrorAction Stop | Select-Object -First 1
    Write-Host "DNS resolution          : OK"
} catch {
    Write-Warning 'DNS resolution failed.'
}

Write-Section 'Public IP'
try {
    $publicIP = (Invoke-RestMethod -Uri 'https://api.ipify.org' -TimeoutSec 5)
    Write-Host "Public IP: $publicIP"
} catch {
    Write-Warning 'Could not get public IP.'
}

Write-Section 'Path / double NAT check'
$hops = @()
for ($ttl = 1; $ttl -le 6; $ttl++) {
    $r = Test-NetConnection -ComputerName $Target -TraceRoute -Hops $ttl -WarningAction SilentlyContinue
    $hop = $r.TraceRoute | Select-Object -Last 1
    if ($hop) { $hops += $hop }
    if ($hop -and -not (Test-PrivateIP $hop) -and $hop -ne '0.0.0.0') { break }
}
$hops = $hops | Select-Object -Unique
$i = 1
foreach ($h in $hops) {
    $type = if ($h -eq '0.0.0.0') { 'no reply' } elseif (Test-PrivateIP $h) { 'private' } else { 'public' }
    Write-Host ("Hop {0}: {1,-16} {2}" -f $i, $h, $type)
    $i++
}
$privateHops = @($hops | Where-Object { $_ -ne '0.0.0.0' -and (Test-PrivateIP $_) })
if ($privateHops.Count -ge 2) {
    Write-Warning "DOUBLE NAT likely: $($privateHops.Count) private hops before the internet. Consider putting the ISP modem in bridge mode."
} else {
    Write-Host 'No double NAT detected.' -ForegroundColor Green
}
