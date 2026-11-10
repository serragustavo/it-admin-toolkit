<#
.SYNOPSIS
    Fixes keyboard layout for Brazilian users by setting pt-BR ABNT2 as the only input method.

.DESCRIPTION
    A common ticket: users end up with US / US-International layouts after imaging or
    MDM policies, and characters like ç, ´ and / stop working.
    This script sets the current user's language list to pt-BR with the ABNT2 layout
    (input tip 0416:00000416), optionally keeping English as a display language.
    Run in the USER context (not as SYSTEM) — e.g. via an MDM "run as user" command.

.PARAMETER KeepEnglish
    Keeps en-US in the language list but forces its keyboard to ABNT2 as well.

.EXAMPLE
    .\Set-KeyboardLayoutABNT2.ps1

.EXAMPLE
    .\Set-KeyboardLayoutABNT2.ps1 -KeepEnglish
#>
[CmdletBinding(SupportsShouldProcess)]
param(
    [switch]$KeepEnglish
)

$abnt2 = '0416:00000416'

Write-Host "Current language list:" -ForegroundColor Cyan
Get-WinUserLanguageList | Format-Table LanguageTag, InputMethodTips -AutoSize

$list = New-WinUserLanguageList -Language 'pt-BR'
$list[0].InputMethodTips.Clear()
$list[0].InputMethodTips.Add($abnt2)

if ($KeepEnglish) {
    $list.Add('en-US')
    $en = $list | Where-Object LanguageTag -eq 'en-US'
    $en.InputMethodTips.Clear()
    $en.InputMethodTips.Add($abnt2)
}

if ($PSCmdlet.ShouldProcess('Current user', 'Set keyboard layout to pt-BR ABNT2')) {
    Set-WinUserLanguageList -LanguageList $list -Force
    Set-WinDefaultInputMethodOverride -InputTip $abnt2
    Write-Host "`nNew language list:" -ForegroundColor Green
    Get-WinUserLanguageList | Format-Table LanguageTag, InputMethodTips -AutoSize
    Write-Host "Done. Sign out and back in if the change does not show immediately." -ForegroundColor Yellow
}
