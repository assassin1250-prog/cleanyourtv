# Build the launcher and deploy it to a TV over ADB, without the repo's Python tooling.
# Usage: .\deploy-adb.ps1 -TvHost 192.168.1.50 [-PreviousHome com.google.android.tvlauncher] [-Sdk C:\Android\sdk] [-Jdk C:\path\to\jdk-17]
param(
    [Parameter(Mandatory = $true)][string]$TvHost,
    [string]$PreviousHome = '',
    [string]$Sdk = $env:ANDROID_HOME,
    [string]$Jdk = $env:JAVA_HOME
)
$ErrorActionPreference = 'Stop'
Set-Location $PSScriptRoot

if (-not $Jdk -or -not (Test-Path "$Jdk\bin\java.exe")) {
    $candidates = @(
        "$env:USERPROFILE\jdk17\jdk-17.0.20.1+1",
        'C:\Program Files\Android\Android Studio\jbr'
    ) + (Get-ChildItem 'C:\Program Files\Microsoft' -Directory -ErrorAction SilentlyContinue |
         Where-Object { $_.Name -like 'jdk-17*' } | ForEach-Object { $_.FullName })
    $Jdk = $candidates | Where-Object { $_ -and (Test-Path "$_\bin\java.exe") } | Select-Object -First 1
}
if (-not $Jdk) { throw 'No JDK 17 found. Pass -Jdk or set JAVA_HOME.' }
if (-not $Sdk) { $Sdk = 'C:\Android\sdk' }
if (-not (Test-Path $Sdk)) { throw "Android SDK not found at $Sdk. Pass -Sdk." }

$env:JAVA_HOME = $Jdk
$env:ANDROID_HOME = $Sdk
"1/5 build"
"sdk.dir=$($Sdk -replace '\\', '\\')" | Out-File -Encoding ascii local.properties
& .\gradlew.bat assembleRelease -q --console=plain
if ($LASTEXITCODE -ne 0) { throw 'Gradle build failed' }

$apk = 'app\build\outputs\apk\release\app-release.apk'
$adb = 'adb'
"2/5 connect $TvHost"
& $adb connect $TvHost | Out-Null

"3/5 install"
& $adb -s $TvHost install -r $apk | Select-Object -Last 1

"4/5 start it once, then make it Home"
& $adb -s $TvHost shell am start -W -a android.intent.action.MAIN -c android.intent.category.HOME -n com.gathin.tvhome/.MainActivity | Out-Null
& $adb -s $TvHost shell cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity
& $adb -s $TvHost shell pm grant com.gathin.tvhome android.permission.WRITE_SECURE_SETTINGS
& $adb -s $TvHost shell pm grant com.gathin.tvhome android.permission.ACCESS_FINE_LOCATION

"5/5 remote key helpers"
& $adb -s $TvHost shell "settings put secure enabled_accessibility_services com.gathin.tvhome/.HomeKeyService:com.gathin.tvhome/.InputKeyService; settings put secure accessibility_enabled 1"
if ($PreviousHome) {
    & $adb -s $TvHost shell pm disable-user --user 0 $PreviousHome
    & $adb -s $TvHost shell cmd package set-home-activity --user 0 com.gathin.tvhome/.MainActivity
}

& $adb -s $TvHost shell input keyevent KEYCODE_HOME
"Done. Home now resolves to:"
& $adb -s $TvHost shell "cmd package resolve-activity --brief -a android.intent.action.MAIN -c android.intent.category.HOME"
