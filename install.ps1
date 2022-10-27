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
      '', 'Install all drivers in the script foler?', @('&Yes'; '&No'), 1)

  if ($decision -ne 0) {
    exit
  }
}

Get-ChildItem -Filter *.inf -Recurse -File -Name | ForEach-Object -Process {
  PnPUtil /add-driver $_ /install
  Write-Host "--"
}

# weird delay of the output of an object when followed by start-sleep (or until script end)
# https://stackoverflow.com/q/59330539/1592410
PnPUtil /scan-devices | Out-Host

if (-not $NoPrompt) {
  pause
}
