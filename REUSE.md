# Local fork — TCL BeyondTV setup

This is a **personal configuration** of [Gathin23/cleanyourtv](https://github.com/Gathin23/cleanyourtv)
(MIT), based on upstream commit `76a9312`. Everything is upstream except the single change in
`launcher/app/src/main/res/values/config.xml`, made for a **TCL BeyondTV, Android 11, 2 GB** set.

## What this fork changes

| Setting | Value here | Why |
|---|---|---|
| `dock_apps` | YouTube, Crunchyroll, Live TV (`com.tcl.tv`), Play Store | the apps actually used on this TV |
| `live_tv_package` | `com.tcl.tv` | upstream defaults to the MediaTek tuner (`com.mediatek.wwtv.tvcenter`), which does not exist here |
| `tile_menu` | `true` | long-press OK opens Add to dock / Move / App info instead of jumping straight to App info |
| `restore_key_services` | `true` | Home puts the accessibility key helpers back after a force stop |
| `settings_key_keycodes` | `83` | TCL remotes send the gear button as `KEYCODE_NOTIFICATION` (83) |

Remote keys need two more steps that are *not* in the APK (see `launcher/deploy-adb.ps1`, which does them):
enabling `HomeKeyService` / `InputKeyService` in secure settings and granting `WRITE_SECURE_SETTINGS`.

## Build

Needs **JDK 17** and Android SDK platform 34 (AGP downloads the platform if the licences are accepted).

```powershell
cd launcher
$env:JAVA_HOME = "C:\path\to\jdk-17"
$env:ANDROID_HOME = "C:\Android\sdk"
"sdk.dir=C\:\\Android\\sdk" | Out-File -Encoding ascii local.properties
.\gradlew.bat assembleRelease
```

APK: `launcher\app\build\outputs\apk\release\app-release.apk` (~530 KB).

## Install on another TV

```powershell
cd launcher
.\deploy-adb.ps1 -TvHost 192.168.1.50
```

`deploy-adb.ps1` builds, installs, starts the launcher once, makes it Home, grants the permissions and
enables both accessibility helpers. Add `-PreviousHome <package>` to disable the launcher it replaces
(e.g. `com.google.android.tvlauncher` on a stock Google TV set).

The TV needs **USB debugging / network ADB on** and the debugging prompt accepted.

## Publishing it as your own fork

This folder is already a git repo: upstream's full history plus one commit (`main`).

1. Fork on the web: <https://github.com/Gathin23/cleanyourtv> → **Fork** (or create an empty repo of your own).
2. `.\push-fork.ps1 -RepoUrl https://github.com/<you>/cleanyourtv.git`
   (paste a Personal Access Token when asked for a password).

Then on any machine: `git clone <your fork>` and run `launcher\deploy-adb.ps1`.

Keeping upstream's history means `git pull upstream main` still works for later launcher improvements;
if `config.xml` conflicts, keep this fork's values.

## Per-TV values worth checking before deploying elsewhere

- `live_tv_package` — find it with `pm list packages | grep -i tv`, or leave the upstream default.
- `dock_apps` — packages must be installed, missing ones are skipped.
- `settings_key_keycodes` / `input_key_keycodes` — only needed for remotes whose buttons the stock
  launcher used to answer. Leave empty first and add what does not work.
- `columns`, `rows_below_dock`, `dock_glass`, `cinematic_home` — cosmetic, see the comments in `config.xml`.
