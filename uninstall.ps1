# Copyright © 2022 Johann Chang <johann.chang@outlook.com>
#
# This Source Code Form is subject to the terms of the Mozilla Public
# License, v. 2.0. If a copy of the MPL was not distributed with this
# file, You can obtain one at https://mozilla.org/MPL/2.0/.


Param([switch]$NoPrompt)

cd "$PSScriptRoot"

# To run the script as Administrator
# https://stackoverflow.com/a/57035712/1592410
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole(
    [Security.Principal.WindowsBuiltInRole]::Administrator)) {
  if ($NoPrompt) {
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath' -NoPrompt;`""
  } else {
    Start-Process PowerShell -Verb RunAs "-NoProfile -ExecutionPolicy Bypass -Command `"cd '$pwd'; & '$PSCommandPath';`""
  }
  exit
}

if ((Get-Location).Path -like "$Env:WINDIR*") {
  Write-Host "ERROR: Cannot be executed inside the Windows folder"
  if (-not $NoPrompt) {
    pause
  }
  exit 1
}

if ($Env:WINDIR -like "$($(Get-Location).Path)*") {
  Write-Host "ERROR: Cannot be executed in a folder that contains Windows"
  if (-not $NoPrompt) {
    pause
  }
  exit 1
}

if (-not $NoPrompt) {
  $decision = $Host.UI.PromptForChoice(
      '', 'Uninstall all drivers in the script foler?', @('&Yes'; '&No'), 1)

  if ($decision -ne 0) {
    exit
  }
}

$Infs = (Get-ChildItem -Filter "*.inf" -Recurse).Name

# PnPUtil retrieve each driver and add to array with PSObject
# https://stackoverflow.com/q/66580801/1592410
$Drivers = New-Object System.Collections.ArrayList
((PnPUtil /enum-drivers | Select-Object -Skip 2) |
  Select-String -Pattern 'Published Name:' -Context 0,7) | foreach {
if ($PSItem.Context.PostContext[4] -like "*Class Version:*") {
  $ClassVersion = $PSItem.Context.PostContext[4] -replace '.*:\s+'
  $DriverVersion = $PSItem.Context.PostContext[5] -replace '.*:\s+'
  $SignerName = $PSItem.Context.PostContext[6] -replace '.*:\s+'
} else {
  $ClassVersion = "N/A"
  $DriverVersion = $PSItem.Context.PostContext[4] -replace '.*:\s+'
  $SignerName = $PSItem.Context.PostContext[5] -replace '.*:\s+'
}
  $y = New-Object PSCustomObject
  $y | Add-Member -Membertype NoteProperty -Name PublishedName -value (($PSitem | Select-String -Pattern 'Published Name:' ) -replace '.*:\s+')
  $y | Add-Member -Membertype NoteProperty -Name OriginalName -value (($PSItem.Context.PostContext[0]) -replace '.*:\s+')
  $y | Add-Member -Membertype NoteProperty -Name ProviderName -value (($PSItem.Context.PostContext[1]) -replace '.*:\s+')
  $y | Add-Member -Membertype NoteProperty -Name ClassName -value (($PSItem.Context.PostContext[2]) -replace '.*:\s+')
  $y | Add-Member -Membertype NoteProperty -Name ClassGUID -value (($PSItem.Context.PostContext[3]) -replace '.*:\s+')
  $y | Add-Member -Membertype NoteProperty -Name ClassVersion -value $ClassVersion
  $y | Add-Member -Membertype NoteProperty -Name DriverVersion -value $DriverVersion
  $y | Add-Member -Membertype NoteProperty -Name SignerName -value $SignerName
  $z = $Drivers.Add($y)
}

foreach ($Driver in ($Drivers | Sort-Object -Descending -Property OriginalName)) {
  foreach ($Inf in $Infs) {
    $SourceInfBaseName = [io.path]::GetFileNameWithoutExtension("$Inf")
    $InstallInfBaseName = [io.path]::GetFileNameWithoutExtension($Driver.OriginalName)
    if (-not ("$InstallInfBaseName" -eq "$SourceInfBaseName")) {
      continue
    }
    Write-Host Removing driver package: $Driver.OriginalName...
    PnPUtil /delete-driver $Driver.PublishedName /uninstall /force
    Write-Host "--"
  }
}

PnPUtil /scan-devices

if (-not $NoPrompt) {
  $decision = $Host.UI.PromptForChoice(
    '', 'Uninstallation is almost done, restart the computer to complete the process?', @('&Yes'; '&No'), 0)

  if ($decision -ne 0) {
    exit
  }

  try {
    Restart-Computer -ErrorAction Stop
  } catch {
    Write-Host "Cannot restart the computer. There may be other users logged on."
    $decision = $Host.UI.PromptForChoice(
      '', 'Force to restart the computer?', @('&Yes'; '&No'), 1)
    if ($decision -eq 0) {
      Restart-Computer -Force
    }
  }
}
