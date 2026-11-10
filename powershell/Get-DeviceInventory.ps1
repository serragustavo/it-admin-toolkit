<#
.SYNOPSIS
    Collects hardware/OS inventory from the local machine (or remote ones) and exports to CSV.

.DESCRIPTION
    Gathers hostname, serial number, manufacturer/model, CPU, RAM, system disk usage,
    OS version/build, last boot time, logged-on user and BitLocker status.
    Useful for asset audits, refresh planning and onboarding checks.

.PARAMETER ComputerName
    One or more computers to query. Defaults to the local machine.
    Remote queries require WinRM and admin rights on the target.

.PARAMETER OutputPath
    CSV output path. Defaults to .\inventory_<date>.csv

.EXAMPLE
    .\Get-DeviceInventory.ps1

.EXAMPLE
    .\Get-DeviceInventory.ps1 -ComputerName PC-001,PC-002 -OutputPath C:\temp\inv.csv
#>
[CmdletBinding()]
param(
    [string[]]$ComputerName = $env:COMPUTERNAME,
    [string]$OutputPath = ".\inventory_$(Get-Date -Format 'yyyy-MM-dd').csv"
)

$results = foreach ($computer in $ComputerName) {
    Write-Verbose "Querying $computer"
    try {
        $sessionParams = @{ ErrorAction = 'Stop' }
        if ($computer -ne $env:COMPUTERNAME) {
            $session = New-CimSession -ComputerName $computer -ErrorAction Stop
            $sessionParams.CimSession = $session
        }

        $cs   = Get-CimInstance Win32_ComputerSystem @sessionParams
        $bios = Get-CimInstance Win32_BIOS @sessionParams
        $os   = Get-CimInstance Win32_OperatingSystem @sessionParams
        $cpu  = Get-CimInstance Win32_Processor @sessionParams | Select-Object -First 1
        $disk = Get-CimInstance Win32_LogicalDisk -Filter "DeviceID='$($os.SystemDrive)'" @sessionParams

        $bitlocker = 'Unknown'
        try {
            $vol = Get-CimInstance -Namespace 'root\cimv2\Security\MicrosoftVolumeEncryption' `
                -ClassName Win32_EncryptableVolume -Filter "DriveLetter='$($os.SystemDrive)'" @sessionParams
            if ($vol) {
                $bitlocker = switch ($vol.ProtectionStatus) { 0 {'Off'} 1 {'On'} default {'Unknown'} }
            }
        } catch { $bitlocker = 'Requires admin' }

        [PSCustomObject]@{
            ComputerName  = $cs.Name
            SerialNumber  = $bios.SerialNumber
            Manufacturer  = $cs.Manufacturer
            Model         = $cs.Model
            CPU           = $cpu.Name.Trim()
            RAM_GB        = [math]::Round($cs.TotalPhysicalMemory / 1GB, 1)
            Disk_Total_GB = [math]::Round($disk.Size / 1GB, 1)
            Disk_Free_GB  = [math]::Round($disk.FreeSpace / 1GB, 1)
            OS            = $os.Caption
            OS_Build      = $os.BuildNumber
            LastBoot      = $os.LastBootUpTime
            LoggedOnUser  = $cs.UserName
            BitLocker     = $bitlocker
            Status        = 'OK'
        }

        if ($session) { Remove-CimSession $session; $session = $null }
    }
    catch {
        [PSCustomObject]@{ ComputerName = $computer; Status = "Error: $($_.Exception.Message)" }
    }
}

$results | Export-Csv -Path $OutputPath -NoTypeInformation -Encoding UTF8
$results | Format-Table ComputerName, SerialNumber, Model, RAM_GB, Disk_Free_GB, OS_Build, BitLocker, Status -AutoSize
Write-Host "`nInventory saved to $OutputPath" -ForegroundColor Green
