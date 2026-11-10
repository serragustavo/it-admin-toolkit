# IT Admin Toolkit — Gustavo Serra

IT Analyst focused on **identity, endpoints and networking** for small and mid-size environments.
This repo collects scripts and write-ups from real-world work (all data anonymized).

**Stack:** JumpCloud · Microsoft Entra ID · Intune · Microsoft 365 · Active Directory · UniFi · Cisco · Huawei firewalls · PowerShell

## PowerShell

| Script | What it does |
|---|---|
| [`Get-DeviceInventory.ps1`](powershell/Get-DeviceInventory.ps1) | Hardware/OS/BitLocker inventory → CSV, local or remote |
| [`Set-KeyboardLayoutABNT2.ps1`](powershell/Set-KeyboardLayoutABNT2.ps1) | Fixes Brazilian ABNT2 keyboard layout for the current user |
| [`Get-TeamsAuthDiagnostics.ps1`](powershell/Get-TeamsAuthDiagnostics.ps1) | Diagnoses Teams/M365 sign-in failures (PRT, TPM, cache) and optionally clears the cache |
| [`Test-NetworkPath.ps1`](powershell/Test-NetworkPath.ps1) | Gateway/DNS/internet checks and **double NAT** detection |

## Case studies

- [PIN-based secure printing with JumpCloud Cloud LDAP (no AD)](case-studies/jumpcloud-ldap-secure-print.md)
- [UniFi Wi-Fi optimization for a dense office](case-studies/unifi-wifi-tuning.md)

## Contact

[LinkedIn](https://www.linkedin.com/in/gustavodserra) · serragustavo.98@gmail.com
