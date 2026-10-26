# Publish this repo to GitHub.
#
# 1. Create the target on GitHub first (either works):
#      - fork:  https://github.com/Gathin23/cleanyourtv  ->  Fork
#      - or an empty repo of your own (no README, no licence)
# 2. Run:  .\push-fork.ps1 -RepoUrl https://github.com/<you>/cleanyourtv.git
#
# GitHub refuses account passwords over HTTPS. When it asks for a password, paste a
# Personal Access Token: Settings -> Developer settings -> Personal access tokens -> repo scope.
#
# This repo keeps upstream's full history plus one commit with the local configuration, so the push
# fast-forwards your fork's main branch.
param(
    [Parameter(Mandatory = $true)][string]$RepoUrl,
    [string]$Git = "$env:USERPROFILE\mingit\cmd\git.exe"
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

if (-not (Test-Path $Git)) { $Git = 'git' }

Write-Host "Remote: $RepoUrl"
& $Git remote remove origin 2>$null
& $Git remote add origin $RepoUrl
& $Git push -u origin main
if ($LASTEXITCODE -ne 0) {
    throw "push failed - is the repo empty or an actual fork of Gathin23/cleanyourtv? A fork's main must be at or behind $(& $Git rev-parse --short HEAD~1)."
}
Write-Host ''
Write-Host "Pushed: $RepoUrl"
Write-Host 'On another computer:'
Write-Host "  git clone $RepoUrl"
Write-Host '  cd launcher; .\deploy-adb.ps1 -TvHost <new tv ip> -PreviousHome <its stock launcher>'
