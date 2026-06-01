@echo off
setlocal EnableExtensions DisableDelayedExpansion
chcp 65001 >nul 2>nul
color 0B
title SC Zero to Hero Setup - DirectorGunner's Anti-Slicer Script

set "DG_SELF=%~f0"
set "DG_LAUNCHER_DIR=%~dp0"
set "DG_DEVROOT=D:\dev"
set "DG_EXIT=0"
set "DG_MODE=live"
set "DG_SCRIPT_VERSION=v0.38"
set "DG_SCRIPT_BUILD=%DG_SCRIPT_VERSION%"
set "DG_VERSION=%DG_SCRIPT_VERSION%"
set "DG_STAR_CITIZEN_TESTED_BUILDS=LIVE-4.8-and-older"
set "DG_STAR_CITIZEN_COMPAT=%DG_STAR_CITIZEN_TESTED_BUILDS%"
set "DG_CLI_SKIPTOOLS=0"
set "DG_CLI_SELFTEST=0"

where powershell.exe >nul 2>nul
if errorlevel 1 (
    echo.
    echo PowerShell was not found. This launcher needs Windows PowerShell 5.1 or newer.
    echo On Windows 10/11, powershell.exe is normally included with Windows.
    pause
    exit /b 1
)

if /I "%~1"=="--elevated-config" goto :ElevatedFromConfig
if /I "%~1"=="--winget-bootstrap" goto :ElevatedWingetBootstrap

for %%A in (%*) do (
    if /I "%%~A"=="-SkipTools" set "DG_CLI_SKIPTOOLS=1"
    if /I "%%~A"=="-SelfTest" set "DG_CLI_SELFTEST=1"
)

if "%DG_CLI_SELFTEST%"=="1" goto :RunSelfTest

goto :StartLauncher

:RunSelfTest
cls
call :PrintIntro
echo.
echo Running script version %DG_SCRIPT_VERSION% self-test mode. No installers, downloads, PATH edits, repo actions, or build actions will run.
echo.
call :RunPayload -SelfTest -DevRoot "%DG_DEVROOT%"
set "DG_EXIT=%ERRORLEVEL%"
goto :Finished

:StartLauncher
cls
call :PrintIntro
echo.
echo Single-file launcher for SC Zero to Hero Setup.
echo.
echo Ready to launch?
echo   Y = live setup. You will choose the install root next; Windows UAC may ask for Administrator permission.
echo   N = cancel. Nothing is changed.
echo.

:PromptLaunchChoice
<nul set /p "=Ready to launch? Type Y or N: "
set "DG_LAUNCH_KEY="
for /f "usebackq delims=" %%K in (`powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$k=[Console]::ReadKey($true).KeyChar; if($k -match '^[Yy]$'){ 'Y' } elseif($k -match '^[Nn]$'){ 'N' } elseif($k -match '^[Hh]$'){ 'H' } else { '?' }"`) do set "DG_LAUNCH_KEY=%%K"
if /I "%DG_LAUNCH_KEY%"=="Y" (
    echo Y
    set "DG_MODE=live"
    goto :ChooseInstallRoot
)
if /I "%DG_LAUNCH_KEY%"=="N" (
    echo N
    goto :Cancelled
)
if /I "%DG_LAUNCH_KEY%"=="H" (
    echo.
    set "DG_MODE=hidden"
    goto :ChooseInstallRoot
)
echo.
echo Please type Y or N.
echo.
goto :PromptLaunchChoice

:PrintIntro
echo.
echo    ___ ___ ___ ___ ___ _____ ___  ___  ___ _   _ _  _ _  _ ___ ___
echo   ^|   \_ _^| _ \ __/ __^|_   _/ _ \^| _ \/ __^| ^| ^| ^| \^| ^| \^| ^| __^| _ \
echo   ^| ^|) ^| ^|^|   / _^| (__  ^| ^|^| (_) ^|   / (_ ^| ^|_^| ^| .` ^| .` ^| _^|^|   /
echo   ^|___/___^|_^|_\___\___^| ^|_^| \___/^|_^|_\\___^|\___/^|_^|\_^|_^|\_^|___^|_^|_\
echo.
echo                               presents
echo.
echo      .----[ DirectorGunner's Anti-Slicer Script ]----.
echo    _/         ZERO TO HERO :: LOCAL RIG SETUP        \_
echo   /__  MAKE IT EASY // MAKE IT FAST // MAKE IT SEXY  __\
exit /b 0

:ChooseInstallRoot
cls
call :PrintIntro
echo.
if /I "%DG_MODE%"=="hidden" (
    echo     .----[ VISUAL PREVIEW MODE ACTIVE ]----.
    echo     No installers, downloads, PATH edits, repo actions, or build actions will run.
    echo     Choose a root only so the preview can show realistic paths.
    echo.
)
echo Choose the environment root for setup files, repos, caches, exports, and logs.
echo.
echo Recommended:
echo   1^) D:\dev
echo   2^) C:\dev
echo   3^) Custom path
echo.
choice /C 123 /N /M "Environment root [1/2/3]: "
set "DG_CHOICE=%ERRORLEVEL%"
if "%DG_CHOICE%"=="3" (
    echo.
    set /P "DG_DEVROOT=Enter custom environment root, example E:\dev: "
) else if "%DG_CHOICE%"=="2" (
    set "DG_DEVROOT=C:\dev"
) else (
    set "DG_DEVROOT=D:\dev"
)
if "%DG_DEVROOT%"=="" set "DG_DEVROOT=D:\dev"
set "DG_DEVROOT=%DG_DEVROOT:"=%"
call :ValidateInstallRoot
if errorlevel 1 (
    echo.
    echo Choose another location.
    echo.
    pause
    goto :ChooseInstallRoot
)

echo.
if /I "%DG_MODE%"=="hidden" (
    echo VISUAL PREVIEW MODE ACTIVE
    echo Selected display-only environment root:
    echo   %DG_DEVROOT%
    echo.
    choice /C YN /N /M "Preview with this location? Y/N: "
) else (
    echo Selected environment root:
    echo   %DG_DEVROOT%
    echo.
    choice /C YN /N /M "Use this location? Y/N: "
)
if "%ERRORLEVEL%"=="2" goto :ChooseInstallRoot
call :SetProjectRootEnvironment
if /I "%DG_MODE%"=="hidden" goto :HiddenPreview
goto :PrepareLiveMode

:SetProjectRootEnvironment
set "SC_DEV_ROOT=%DG_DEVROOT%"
set "SC_DATA_ROOT=%DG_DEVROOT%\scdata"
set "SC_P4K_ROOT=%DG_DEVROOT%\scdata\p4k"
set "SC_EXPORT_ROOT=%DG_DEVROOT%\scdata\exports"
set "SC_WORK_ROOT=%DG_DEVROOT%\scdata\work"
exit /b 0

:ValidateInstallRoot
set "DG_ROOTCHECK=%TEMP%\SC-Zero-to-Hero-Setup-root-%RANDOM%%RANDOM%.txt"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $p=$env:DG_DEVROOT; if([string]::IsNullOrWhiteSpace($p)){ Write-Host 'Environment root cannot be blank.'; exit 2 }; $p=$p.Trim().Trim([char]34).TrimEnd([char]92,[char]47); if([string]::IsNullOrWhiteSpace($p)){ Write-Host 'Environment root cannot be blank.'; exit 2 }; $root=[IO.Path]::GetPathRoot($p); if([string]::IsNullOrWhiteSpace($root) -or -not [IO.Directory]::Exists($root)){ Write-Host ('Drive/root does not exist: '+$root); exit 3 }; if($p -match '^[A-Za-z]:\\?$'){ Write-Host 'Please choose a folder, not the root of an entire drive.'; exit 4 }; if($p -match '(?i)\\(Windows|Program Files|Program Files \\(x86\\))($|\\)'){ Write-Host 'Please choose a user-controlled dev folder, not Windows or Program Files.'; exit 5 }; $utf8=New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($env:DG_ROOTCHECK,$p,$utf8)"
if errorlevel 1 (
    if exist "%DG_ROOTCHECK%" del "%DG_ROOTCHECK%" >nul 2>nul
    exit /b 1
)
set /P "DG_DEVROOT="<"%DG_ROOTCHECK%"
del "%DG_ROOTCHECK%" >nul 2>nul
exit /b 0

:PrepareLiveMode
echo.
echo Project root selected: %DG_DEVROOT%
echo Validating WinGet before the installer phase...
call :CheckWingetAvailable
if not errorlevel 1 goto :LiveSetup

echo.
echo WinGet was not found or is not usable yet.
echo This launcher will repair/install Microsoft App Installer / WinGet first,
echo then close so you can relaunch with a fresh terminal environment.
echo.
call :IsAdmin
if errorlevel 1 (
    echo Requesting Administrator permission to bootstrap WinGet...
    powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $q=[char]34; $cmdLine='/d /c '+$q+$env:DG_SELF+$q+' --winget-bootstrap'; Start-Process -FilePath $env:ComSpec -ArgumentList $cmdLine -Verb RunAs"
    if errorlevel 1 (
        echo.
        echo Failed to request Administrator permission for WinGet bootstrap.
        pause
        exit /b 1
    )
    exit /b 0
)
call :BootstrapWinget
set "DG_EXIT=%ERRORLEVEL%"
if "%DG_EXIT%"=="0" (
    call :CheckWingetAvailable
    if not errorlevel 1 (
        echo.
        echo WinGet is now available in this terminal. Continuing setup.
        goto :LiveSetup
    )
    echo.
    echo WinGet bootstrap completed, but this terminal cannot invoke winget.exe yet.
    echo Close this window, then double-click this launcher again so the fresh terminal can see WinGet.
    echo.
    pause
    exit /b 0
)
echo.
echo WinGet bootstrap failed. See the messages above.
pause
exit /b %DG_EXIT%

:CheckWingetAvailable
set "DG_WINGET_EXE="
set "DG_WINGET_PROBE=%TEMP%\SC-Zero-to-Hero-Setup-winget-%RANDOM%%RANDOM%.txt"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='SilentlyContinue'; $ProgressPreference='SilentlyContinue'; $out=$env:DG_WINGET_PROBE; $candidates=New-Object System.Collections.Generic.List[string]; function Add-Candidate([string]$p){ if([string]::IsNullOrWhiteSpace($p)){ return }; $expanded=[Environment]::ExpandEnvironmentVariables($p.Trim().Trim([char]34)); if([string]::IsNullOrWhiteSpace($expanded)){ return }; if([IO.Directory]::Exists($expanded)){ $expanded=Join-Path $expanded 'winget.exe' }; if([IO.File]::Exists($expanded)){ [void]$candidates.Add((Resolve-Path -LiteralPath $expanded).Path) } }; $cmd=Get-Command winget.exe -ErrorAction SilentlyContinue; if($cmd){ Add-Candidate $cmd.Source }; Add-Candidate (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe'); foreach($scope in 'Process','User','Machine'){ $path=[Environment]::GetEnvironmentVariable('Path',$scope); if($path){ foreach($part in ($path -split ';')){ if(-not [string]::IsNullOrWhiteSpace($part)){ Add-Candidate (Join-Path $part 'winget.exe') } } } }; Get-AppxPackage -Name Microsoft.DesktopAppInstaller -AllUsers -ErrorAction SilentlyContinue | ForEach-Object { if($_.InstallLocation){ Add-Candidate (Join-Path $_.InstallLocation 'winget.exe') } }; $windowsApps=Join-Path $env:ProgramFiles 'WindowsApps'; if(Test-Path -LiteralPath $windowsApps){ Get-ChildItem -LiteralPath $windowsApps -Directory -Filter 'Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe' -ErrorAction SilentlyContinue | ForEach-Object { Add-Candidate (Join-Path $_.FullName 'winget.exe') } }; foreach($candidate in ($candidates | Select-Object -Unique)){ try { & $candidate --version *> $null; if($LASTEXITCODE -eq 0){ $utf8=New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($out,$candidate,$utf8); exit 0 } } catch {} }; exit 1"
if errorlevel 1 (
    if exist "%DG_WINGET_PROBE%" del "%DG_WINGET_PROBE%" >nul 2>nul
    exit /b 1
)
set /P "DG_WINGET_EXE="<"%DG_WINGET_PROBE%"
del "%DG_WINGET_PROBE%" >nul 2>nul
if "%DG_WINGET_EXE%"=="" exit /b 1
for %%I in ("%DG_WINGET_EXE%") do set "PATH=%%~dpI;%LOCALAPPDATA%\Microsoft\WindowsApps;%PATH%"
"%DG_WINGET_EXE%" --version >nul 2>nul
if errorlevel 1 exit /b 1
exit /b 0

:IsAdmin
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$p=New-Object Security.Principal.WindowsPrincipal([Security.Principal.WindowsIdentity]::GetCurrent()); if($p.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)){ exit 0 } else { exit 1 }"
exit /b %ERRORLEVEL%

:BootstrapWinget
echo Attempting WinGet repair/install through Microsoft's App Installer path...
echo.
set "DG_BOOTSTRAP=%TEMP%\SC-Zero-to-Hero-Setup-WinGet-%RANDOM%%RANDOM%.ps1"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $self=$env:DG_SELF; $out=$env:DG_BOOTSTRAP; $raw=[IO.File]::ReadAllText($self,[Text.Encoding]::UTF8); $startMarker=('# WINGET_'+'BOOTSTRAP_PAYLOAD_BELOW'); $endMarker=('# POWER'+'SHELL_PAYLOAD_BELOW'); $s=$raw.LastIndexOf($startMarker); $e=$raw.LastIndexOf($endMarker); if($s -lt 0 -or $e -lt 0 -or $e -le $s){ throw 'Embedded WinGet bootstrap payload was not found.' }; $payload=$raw.Substring($s + $startMarker.Length, $e - ($s + $startMarker.Length)).TrimStart([char[]]@([char]13,[char]10)); $utf8=New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($out,$payload,$utf8)"
if errorlevel 1 (
    echo.
    echo Could not extract the embedded WinGet bootstrap script.
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DG_BOOTSTRAP%"
set "DG_EXIT=%ERRORLEVEL%"
del "%DG_BOOTSTRAP%" >nul 2>nul
exit /b %DG_EXIT%

:ElevatedWingetBootstrap
cls
call :PrintIntro
echo.
echo WinGet / App Installer bootstrap
echo.
call :BootstrapWinget
set "DG_EXIT=%ERRORLEVEL%"
if "%DG_EXIT%"=="0" (
    call :CheckWingetAvailable
    echo.
    if not errorlevel 1 (
        echo WinGet is now installed or repaired and validates in this terminal.
    ) else (
        echo WinGet is installed or repaired, but this terminal cannot invoke winget.exe yet.
    )
    echo Close this window, then double-click %~nx0 again to continue setup from the beginning.
    echo.
) else (
    echo.
    echo WinGet bootstrap failed with exit code %DG_EXIT%.
    echo Try opening Microsoft Store, updating App Installer, then relaunch this file.
    echo.
)
pause
exit /b %DG_EXIT%

:LiveSetup
call :IsAdmin
if not errorlevel 1 goto :LiveSetupAdmin

echo.
echo Requesting Administrator permission through Windows UAC...
echo.
set "DG_CONFIG=%TEMP%\SC-Zero-to-Hero-Setup-%RANDOM%%RANDOM%.cfg"
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $lines=@('DG_DEVROOT='+$env:DG_DEVROOT,'DG_CLI_SKIPTOOLS='+$env:DG_CLI_SKIPTOOLS,'DG_CLI_SELFTEST='+$env:DG_CLI_SELFTEST,'DG_SELF='+$env:DG_SELF,'DG_LAUNCHER_DIR='+$env:DG_LAUNCHER_DIR); $utf8=New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllLines($env:DG_CONFIG,$lines,$utf8)"
if errorlevel 1 (
    echo.
    echo Could not prepare the elevated launch configuration.
    pause
    exit /b 1
)
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $q=[char]34; $cmdLine='/d /c '+$q+$env:DG_SELF+$q+' --elevated-config '+$q+$env:DG_CONFIG+$q; Start-Process -FilePath $env:ComSpec -ArgumentList $cmdLine -Verb RunAs"
if errorlevel 1 (
    echo.
    echo Failed to request Administrator permission.
    pause
    exit /b 1
)
exit /b 0

:ElevatedFromConfig
set "DG_CONFIG=%~2"
if not exist "%DG_CONFIG%" (
    echo Elevated launcher could not find its config file: "%DG_CONFIG%"
    pause
    exit /b 1
)
for /F "usebackq tokens=1,* delims==" %%A in ("%DG_CONFIG%") do (
    if /I "%%A"=="DG_DEVROOT" set "DG_DEVROOT=%%B"
    if /I "%%A"=="DG_CLI_SKIPTOOLS" set "DG_CLI_SKIPTOOLS=%%B"
    if /I "%%A"=="DG_CLI_SELFTEST" set "DG_CLI_SELFTEST=%%B"
    if /I "%%A"=="DG_SELF" set "DG_SELF=%%B"
    if /I "%%A"=="DG_LAUNCHER_DIR" set "DG_LAUNCHER_DIR=%%B"
)
del "%DG_CONFIG%" >nul 2>nul
call :SetProjectRootEnvironment
goto :LiveSetupAdmin

:LiveSetupAdmin
call :SetProjectRootEnvironment
call :CheckWingetAvailable
if errorlevel 1 (
    echo.
    echo WinGet is still not available in this Administrator window.
    echo The launcher will attempt the WinGet bootstrap now.
    echo.
    call :BootstrapWinget
    set "DG_EXIT=%ERRORLEVEL%"
    if "%DG_EXIT%"=="0" (
        call :CheckWingetAvailable
        if not errorlevel 1 (
            echo.
            echo WinGet validates in this Administrator window. Continuing setup.
            goto :RunLivePayloadAfterWinget
        )
        echo.
        echo WinGet bootstrap completed, but this Administrator terminal cannot invoke winget.exe yet.
        echo Close this window, then double-click %~nx0 again so a fresh terminal can see WinGet.
        echo.
    ) else (
        echo.
        echo WinGet bootstrap failed. See the messages above.
        echo.
    )
    pause
    exit /b %DG_EXIT%
)
:RunLivePayloadAfterWinget
if "%DG_CLI_SKIPTOOLS%"=="1" (
    call :RunPayload -All -SkipTools -AssumeYes -DevRoot "%DG_DEVROOT%"
) else (
    call :RunPayload -All -AssumeYes -DevRoot "%DG_DEVROOT%"
)
set "DG_EXIT=%ERRORLEVEL%"
goto :Finished

:HiddenPreview
echo.
echo VISUAL PREVIEW MODE ACTIVE
echo No Administrator request will be made by this launcher.
echo No installers, downloads, PATH edits, repo actions, or build actions will run.
call :RunPayload -All -HiddenPreview -DevRoot "%DG_DEVROOT%"
set "DG_EXIT=%ERRORLEVEL%"
goto :Finished

:RunPayload
set "DG_PAYLOAD_BUILD=%DG_SCRIPT_BUILD%"
if not defined DG_PAYLOAD_BUILD set "DG_PAYLOAD_BUILD=payload"
set "DG_PAYLOAD=%TEMP%\SC-Zero-to-Hero-Setup-%DG_PAYLOAD_BUILD%-%RANDOM%%RANDOM%.ps1"
echo.
echo Preparing embedded PowerShell payload...
powershell.exe -NoProfile -ExecutionPolicy Bypass -Command "$ErrorActionPreference='Stop'; $self=$env:DG_SELF; $out=$env:DG_PAYLOAD; $raw=[IO.File]::ReadAllText($self,[Text.Encoding]::UTF8); $marker=('# POWER'+'SHELL_PAYLOAD_BELOW'); $idx=$raw.LastIndexOf($marker); if($idx -lt 0){ throw 'Embedded PowerShell payload was not found.' }; $payload=$raw.Substring($idx + $marker.Length).TrimStart([char[]]@([char]13,[char]10)); $utf8=New-Object System.Text.UTF8Encoding($false); [IO.File]::WriteAllText($out,$payload,$utf8)"
if errorlevel 1 (
    echo.
    echo Could not extract the embedded PowerShell script.
    pause
    exit /b 1
)

echo Launching SC-Zero-to-Hero-Setup...
echo.
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%DG_PAYLOAD%" %*
set "DG_EXIT=%ERRORLEVEL%"
del "%DG_PAYLOAD%" >nul 2>nul
exit /b %DG_EXIT%

:Cancelled
echo.
echo Setup cancelled. No changes were made.
pause
exit /b 0

:Finished
echo.
echo Launcher finished with exit code %DG_EXIT%.
echo.
pause
exit /b %DG_EXIT%

# WINGET_BOOTSTRAP_PAYLOAD_BELOW
#Requires -Version 5.1
Set-StrictMode -Version 2.0
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

function Write-Info([string]$Message) { Write-Host $Message -ForegroundColor Cyan }
function Write-SoftWarn([string]$Message) { Write-Host $Message -ForegroundColor Yellow }
function Write-Fail([string]$Message) { Write-Host $Message -ForegroundColor Red }

function Get-ArchitectureToken {
    $arch = [Runtime.InteropServices.RuntimeInformation]::OSArchitecture.ToString().ToLowerInvariant()
    switch ($arch) {
        'x64' { return 'x64' }
        'arm64' { return 'arm64' }
        'x86' { return 'x86' }
        default { return 'x64' }
    }
}

function Add-ProcessPathEntry([string]$Path) {
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    if (-not (Test-Path -LiteralPath $Path)) { return }
    $parts = @($env:Path -split ';' | Where-Object { -not [string]::IsNullOrWhiteSpace($_) })
    foreach ($part in $parts) {
        if ($part.TrimEnd('\','/') -ieq $Path.TrimEnd('\','/')) { return }
    }
    $env:Path = "$Path;$env:Path"
}

function Resolve-WinGetCandidatePaths {
    $candidates = New-Object 'System.Collections.Generic.List[string]'

    function Add-Candidate([string]$Path) {
        if ([string]::IsNullOrWhiteSpace($Path)) { return }
        $expanded = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim([char]34))
        if ([string]::IsNullOrWhiteSpace($expanded)) { return }
        if ([IO.Directory]::Exists($expanded)) { $expanded = Join-Path $expanded 'winget.exe' }
        if ([IO.File]::Exists($expanded)) {
            try { [void]$candidates.Add((Resolve-Path -LiteralPath $expanded).Path) } catch {}
        }
    }

    $cmd = Get-Command winget.exe -ErrorAction SilentlyContinue
    if ($cmd) { Add-Candidate $cmd.Source }

    Add-Candidate (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps\winget.exe')

    foreach ($scope in @('Process','User','Machine')) {
        $pathValue = [Environment]::GetEnvironmentVariable('Path', $scope)
        if ([string]::IsNullOrWhiteSpace($pathValue)) { continue }
        foreach ($part in ($pathValue -split ';')) {
            if (-not [string]::IsNullOrWhiteSpace($part)) {
                Add-Candidate (Join-Path $part 'winget.exe')
            }
        }
    }

    Get-AppxPackage -Name Microsoft.DesktopAppInstaller -AllUsers -ErrorAction SilentlyContinue | ForEach-Object {
        if (-not [string]::IsNullOrWhiteSpace($_.InstallLocation)) {
            Add-Candidate (Join-Path $_.InstallLocation 'winget.exe')
        }
    }

    $windowsApps = Join-Path $env:ProgramFiles 'WindowsApps'
    if (Test-Path -LiteralPath $windowsApps) {
        Get-ChildItem -LiteralPath $windowsApps -Directory -Filter 'Microsoft.DesktopAppInstaller_*_8wekyb3d8bbwe' -ErrorAction SilentlyContinue | ForEach-Object {
            Add-Candidate (Join-Path $_.FullName 'winget.exe')
        }
    }

    return @($candidates | Select-Object -Unique)
}

function Test-WinGetNow {
    Add-ProcessPathEntry (Join-Path $env:LOCALAPPDATA 'Microsoft\WindowsApps')

    foreach ($candidate in Resolve-WinGetCandidatePaths) {
        try {
            $folder = Split-Path -Parent $candidate
            Add-ProcessPathEntry $folder
            $version = & $candidate --version 2>$null
            if ($LASTEXITCODE -eq 0) {
                Write-Info "WinGet validated: $candidate $version"
                return $true
            }
        } catch {}
    }

    return $false
}

function Invoke-DownloadFile {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$OutFile
    )
    Write-Host "Downloading: $Uri"
    Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing
}

function Try-AppInstallerRegistration {
    Write-Info 'Step 1/3: checking App Installer registration...'
    try {
        Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction Stop
        return $true
    } catch {
        Write-SoftWarn "App Installer registration did not complete: $($_.Exception.Message)"
        return $false
    }
}

function Try-RepairWinGetPackageManager {
    Write-Info 'Step 2/3: trying Microsoft.WinGet.Client / Repair-WinGetPackageManager...'
    try {
        Install-PackageProvider -Name NuGet -Force -ErrorAction Stop | Out-Null
        try { Set-PSRepository -Name PSGallery -InstallationPolicy Trusted -ErrorAction SilentlyContinue } catch {}
        Install-Module -Name Microsoft.WinGet.Client -Force -Repository PSGallery -Scope AllUsers -AllowClobber -ErrorAction Stop | Out-Null
        Repair-WinGetPackageManager -AllUsers -ErrorAction Stop
        return $true
    } catch {
        Write-SoftWarn "Repair-WinGetPackageManager did not complete: $($_.Exception.Message)"
        return $false
    }
}

function Try-DirectWinGetPackageInstall {
    Write-Info 'Step 3/3: direct WinGet package install from Microsoft GitHub release...'

    $arch = Get-ArchitectureToken
    $work = Join-Path $env:TEMP ('SC-Zero-to-Hero-WinGet-' + [guid]::NewGuid().ToString('N'))
    New-Item -ItemType Directory -Force -Path $work | Out-Null

    try {
        $vclibsUri = switch ($arch) {
            'arm64' { 'https://aka.ms/Microsoft.VCLibs.arm64.14.00.Desktop.appx' }
            'x86'   { 'https://aka.ms/Microsoft.VCLibs.x86.14.00.Desktop.appx' }
            default { 'https://aka.ms/Microsoft.VCLibs.x64.14.00.Desktop.appx' }
        }
        $xamlUri = "https://github.com/microsoft/microsoft-ui-xaml/releases/download/v2.8.6/Microsoft.UI.Xaml.2.8.$arch.appx"

        $vclibsPath = Join-Path $work "Microsoft.VCLibs.$arch.14.00.Desktop.appx"
        $xamlPath = Join-Path $work "Microsoft.UI.Xaml.2.8.$arch.appx"
        $bundlePath = Join-Path $work 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'

        Invoke-DownloadFile -Uri $vclibsUri -OutFile $vclibsPath
        Invoke-DownloadFile -Uri $xamlUri -OutFile $xamlPath

        Write-Host 'Resolving latest stable WinGet release asset from microsoft/winget-cli...'
        $headers = @{ 'User-Agent' = 'SC-Zero-to-Hero-Setup' }
        $release = Invoke-RestMethod -Uri 'https://api.github.com/repos/microsoft/winget-cli/releases/latest' -Headers $headers
        $asset = $release.assets | Where-Object { $_.name -eq 'Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle' } | Select-Object -First 1
        if ($null -eq $asset) {
            Write-SoftWarn 'Could not find the GitHub release asset; falling back to https://aka.ms/getwinget.'
            Invoke-DownloadFile -Uri 'https://aka.ms/getwinget' -OutFile $bundlePath
        } else {
            Invoke-DownloadFile -Uri $asset.browser_download_url -OutFile $bundlePath
        }

        foreach ($dependency in @($vclibsPath, $xamlPath)) {
            try {
                Write-Host "Installing dependency: $(Split-Path -Leaf $dependency)"
                Add-AppxPackage -Path $dependency -ForceApplicationShutdown -ErrorAction Stop
            } catch {
                Write-SoftWarn "Dependency install was skipped or already satisfied: $($_.Exception.Message)"
            }
        }

        Write-Host 'Installing Microsoft Desktop App Installer / WinGet bundle...'
        Add-AppxPackage -Path $bundlePath -ForceApplicationShutdown -ErrorAction Stop

        try {
            Add-AppxPackage -RegisterByFamilyName -MainPackage Microsoft.DesktopAppInstaller_8wekyb3d8bbwe -ErrorAction SilentlyContinue
        } catch {}

        return $true
    } catch {
        Write-Fail "Direct WinGet package install failed: $($_.Exception.Message)"
        return $false
    } finally {
        try { Remove-Item -LiteralPath $work -Recurse -Force -ErrorAction SilentlyContinue } catch {}
    }
}

Write-Info 'Checking for WinGet in PATH, user aliases, App Installer package locations, and WindowsApps...'
if (Test-WinGetNow) { exit 0 }

[void](Try-AppInstallerRegistration)
if (Test-WinGetNow) { exit 0 }

[void](Try-RepairWinGetPackageManager)
if (Test-WinGetNow) { exit 0 }

[void](Try-DirectWinGetPackageInstall)
if (Test-WinGetNow) { exit 0 }

$app = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -AllUsers -ErrorAction SilentlyContinue | Sort-Object Version -Descending | Select-Object -First 1
if ($null -ne $app) {
    Write-SoftWarn "App Installer package is present ($($app.Version)), but winget.exe is not callable from this terminal yet."
    Write-SoftWarn 'Close this console and relaunch the setup so Windows can refresh the app execution alias.'
    exit 0
}

Write-Fail 'WinGet bootstrap could not validate App Installer / winget.exe on this system.'
exit 1


# POWERSHELL_PAYLOAD_BELOW
#Requires -Version 5.1
<#
.SYNOPSIS
  SC Zero to Hero setup automation for the Star Citizen / StarBreaker workflow tutorial.

.DESCRIPTION
  This script automates the safe, repeatable parts of the tutorial:
  - Creates the D:\dev-style folder layout.
  - Installs Git, GitHub CLI, Visual Studio Build Tools, Rust, Python 3.12, .NET 8/9, CMake, VS Code, Node.js, Codex CLI.
  - Can pause at VS Code setup, accept a custom VS Code folder or code.cmd path, validate it, then continue.
  - Shows a nostalgic Anti-Slicer / NFO-style sticky progress header based on setup steps, not file-copy bytes.
  - Supports an internal visual-only preview mode that installs nothing.
  - Includes preflight checks, a setup plan preview, safer reruns, optional repo updates, and clearer recovery guidance.
  - Clones the community repositories.
  - Creates the VS Code multi-root workspace.
  - Creates safe development branches.
  - Optionally builds StarBreaker and StarBreaker MCP.
  - Optionally links the StarBreaker Blender add-on.
  - Optionally runs the Aurora MR Data.p4k example, if you provide or already placed Data.p4k.

  Intended for personal learning, fan art, research, and community tooling. Keep Data.p4k read-only and do not redistribute extracted assets.

.EXAMPLE
  PowerShell as Administrator:
    Set-ExecutionPolicy -Scope CurrentUser RemoteSigned -Force
    .\SC-Zero-to-Hero-Setup.ps1 -All

.EXAMPLE
  Full setup plus copy Data.p4k and run the Aurora example:
    .\SC-Zero-to-Hero-Setup.ps1 -All -DataP4kSource "C:\Program Files\Roberts Space Industries\StarCitizen\LIVE\Data.p4k" -StarCitizenBuild "4.4.1-LIVE-9457020" -RunAuroraExample

.EXAMPLE
  Use a different root drive:
    .\SC-Zero-to-Hero-Setup.ps1 -All -DevRoot "E:\dev"

.EXAMPLE
  Pause at VS Code setup and require the user to validate the VS Code CLI path:
    .\SC-Zero-to-Hero-Setup.ps1 -All -PromptForVSCodePath

.EXAMPLE
  Use an existing custom VS Code installation and skip the VS Code installer:
    .\SC-Zero-to-Hero-Setup.ps1 -All -SkipVSCodeInstall -VSCodePath "E:\Apps\Microsoft VS Code"

.EXAMPLE
  Show the generated step plan and progress math without installing anything:
    .\SC-Zero-to-Hero-Setup.ps1 -All -ListSteps

.EXAMPLE
  Skip the installer/tool phase after fixing tools manually:
    .\SC-Zero-to-Hero-Setup.ps1 -All -SkipTools

.EXAMPLE
  Run unattended after reviewing the setup plan once:
    .\SC-Zero-to-Hero-Setup.ps1 -All -AssumeYes

.EXAMPLE
  Run the launcher preview mode to review the visual step flow without installing anything.

.EXAMPLE
  Emit a non-live setup plan snapshot without installing, downloading, cloning, launching GUIs, or touching Data.p4k:
    .\SC-Zero-to-Hero-Setup.ps1 -HarnessMode -PlanOnly -EmitPlanJson "D:\dev\starcitizen\work\plan.json" -NoPause

.EXAMPLE
  Run the safe non-live harness self-test under a fake DevRoot:
    .\SC-Zero-to-Hero-Setup.ps1 -HarnessMode -SelfTest -NoPause
#>

[CmdletBinding()]
param(
    [string]$DevRoot = "D:\dev",

    [switch]$All,
    [switch]$SkipTools,
    [switch]$InstallTools,
    [switch]$CloneRepos,
    [switch]$CreateWorkspace,
    [switch]$CreateBranches,
    [switch]$BuildStarBreaker,
    [switch]$InstallBlenderAddon,
    [switch]$RunAuroraExample,
    [switch]$SetupP4K,
    [switch]$NoOpenBlenderAfterExport,

    [switch]$SkipBlender,
    [switch]$PromptForBlender,
    [string]$BlenderPath = "",
    [string]$BlenderInstallRoot = "",

    [switch]$SkipP4K,
    [switch]$PromptForP4K,
    [string]$P4KBuildLabel = "",

    [switch]$IgnoreCache,
    [switch]$SelfTest,
    [switch]$IncludeVSCMakeProjectComponent,
    [switch]$NoDashboardTranscript,

    [switch]$SkipCodex,
    [switch]$RunInteractiveAuth,
    [switch]$OpenWorkspace,
    [switch]$AllowNonAdmin,
    [switch]$DryRun,
    [switch]$HiddenPreview,
    [switch]$HarnessMode,
    [string]$HarnessRoot = "",
    [switch]$NoExternalActions,
    [switch]$NoNetwork,
    [switch]$NoGui,
    [switch]$NoUserEnvWrites,
    [switch]$NoGlobalGitConfig,
    [switch]$PlanOnly,
    [string]$EmitPlanJson = "",
    [switch]$NoPause,

    [switch]$NoProgressHeader,
    [ValidateRange(20,100)][int]$ProgressBarWidth = 42,
    [ValidateSet("CompactNfo","DirectorGunnerAscii","SceneBox","UnicodeGlitch")][string]$BannerStyle = "CompactNfo",
    [switch]$AssumeYes,
    [switch]$ListSteps,
    [switch]$UpdateExistingRepos,
    [switch]$ReplaceBlenderAddonLink,

    [switch]$SkipVSCodeInstall,
    [switch]$PromptForVSCodePath,
    [string]$VSCodePath = "",

    [string]$StarCitizenBuild = "4.4.1-LIVE-9457020",
    [string]$DataP4kSource = "",
    [string]$BlenderVersion = "",

    # PythonVersion may be exact (3.12.13) or a major/minor series (3.12).
    # If an exact version has no Windows x64 installer, the script selects the newest available installer in that same series.
    [string]$PythonVersion = "3.12.13",
    [string]$CMakeVersion = "4.3.1",
    [string]$NodeVersion = "v22.21.1"
)

Set-StrictMode -Version 2.0
$ErrorActionPreference = "Stop"
$ProgressPreference = "SilentlyContinue"
[Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

$Script:OriginalDevRoot = $DevRoot.TrimEnd([char[]]@('\','/'))
$Script:OriginalStarCitizenRoot = Join-Path $Script:OriginalDevRoot "starcitizen"
$Script:OriginalAgentWorkRoot = Join-Path $Script:OriginalStarCitizenRoot "work"
$Script:HarnessTimestamp = (Get-Date).ToString('yyyyMMdd-HHmmss')

if (($HarnessMode -or $SelfTest) -and [string]::IsNullOrWhiteSpace($HarnessRoot)) {
    $HarnessRoot = Join-Path (Join-Path $Script:OriginalAgentWorkRoot ("installer-harness-" + $Script:HarnessTimestamp)) "devroot"
}
if ($HarnessMode -or $SelfTest) {
    $HarnessMode = $true
    $HarnessRoot = ([IO.Path]::GetFullPath($HarnessRoot.Trim().Trim('"'))).TrimEnd([char[]]@('\','/'))
    $realDevRoot = ([IO.Path]::GetFullPath($Script:OriginalDevRoot)).TrimEnd([char[]]@('\','/'))
    $realProjectRoot = ([IO.Path]::GetFullPath($Script:OriginalStarCitizenRoot)).TrimEnd([char[]]@('\','/'))
    if ($HarnessRoot.Equals($realDevRoot, [StringComparison]::OrdinalIgnoreCase) -or $HarnessRoot.Equals($realProjectRoot, [StringComparison]::OrdinalIgnoreCase)) {
        throw "HarnessRoot must not be the real DevRoot or Star Citizen project root: $HarnessRoot"
    }
    $DevRoot = $HarnessRoot
}
if ($HarnessMode -or $PlanOnly -or $SelfTest) {
    $NoExternalActions = $true
    $NoNetwork = $true
    $NoGui = $true
    $NoUserEnvWrites = $true
    $NoGlobalGitConfig = $true
}
if ($NoExternalActions) {
    $NoNetwork = $true
    $NoGui = $true
    $NoUserEnvWrites = $true
    $NoGlobalGitConfig = $true
}
if ($PlanOnly -or $SelfTest) {
    $AssumeYes = $true
    $NoPause = $true
}
if ($NoExternalActions -and (-not $HarnessMode) -and (-not $SelfTest)) {
    $PlanOnly = $true
}
if ($HarnessMode -and (-not $PlanOnly) -and (-not $SelfTest)) {
    # HarnessMode is deliberately non-live. Without an explicit harness self-test,
    # it falls back to plan emission so it cannot install, download, clone, or launch.
    $PlanOnly = $true
}

if ($All) {
    $InstallTools = $true
    $CloneRepos = $true
    $CreateWorkspace = $true
    $CreateBranches = $true
    $BuildStarBreaker = $true
    $InstallBlenderAddon = $true
    if (-not $SkipBlender) { $PromptForBlender = $true }
    if (-not $SkipP4K) { $PromptForP4K = $true }
}
if ($SkipTools) { $InstallTools = $false } # v14-skiptools-after-all

if (-not ($InstallTools -or $CloneRepos -or $CreateWorkspace -or $CreateBranches -or $BuildStarBreaker -or $InstallBlenderAddon -or $RunAuroraExample)) {
    # Default behavior: do the normal setup, but do not run the Data.p4k export unless explicitly requested.
    $InstallTools = $true
    $CloneRepos = $true
    $CreateWorkspace = $true
    $CreateBranches = $true
    $BuildStarBreaker = $true
    $InstallBlenderAddon = $true
    if (-not $SkipBlender) { $PromptForBlender = $true }
    if (-not $SkipP4K) { $PromptForP4K = $true }
}
if ($SkipTools) { $InstallTools = $false } # v14-skiptools-after-default
if ($SkipBlender) { $PromptForBlender = $false; $InstallBlenderAddon = $false }
if ($SkipP4K) { $PromptForP4K = $false; $SetupP4K = $false; $RunAuroraExample = $false }
if (-not $SkipP4K -and (-not [string]::IsNullOrWhiteSpace($DataP4kSource))) { $SetupP4K = $true }
if (-not $SkipP4K -and $PromptForP4K) { $SetupP4K = $true }

$DevRoot = $DevRoot.TrimEnd([char[]]@('\','/'))
$InstallersRoot = Join-Path $DevRoot "installers"
$GhRoot = Join-Path $DevRoot "gh"
$RustRoot = Join-Path $DevRoot "rust"
$CargoHome = Join-Path $RustRoot ".cargo"
$RustupHome = Join-Path $RustRoot ".rustup"
$PythonRoot = Join-Path $DevRoot "python"
$PythonInstallDir = Join-Path $PythonRoot "Python312"
$PythonVenvDir = Join-Path $PythonRoot "venvs\scdev"
$PipCacheDir = Join-Path $PythonRoot "pip-cache"
$DotNetRoot = Join-Path $DevRoot "dotnet"
$CMakeRoot = Join-Path $DevRoot "cmake"
$NodeRoot = Join-Path $DevRoot "node"
$NpmCacheDir = Join-Path $NodeRoot "npm-cache"
$NpmGlobalDir = Join-Path $NodeRoot "npm-global"
$ScDataRoot = Join-Path $DevRoot "scdata"
$ScP4kRoot = Join-Path $ScDataRoot "p4k"
$ScExportRoot = Join-Path $ScDataRoot "exports"
$ScWorkRoot = Join-Path $ScDataRoot "work"
$ScLogsRoot = Join-Path $ScDataRoot "logs"
$StarCitizenRoot = Join-Path $DevRoot "starcitizen"
$WorkspaceRoot = Join-Path $StarCitizenRoot "_workspace"
$WorkspacePath = Join-Path $WorkspaceRoot "starcitizen-tools.code-workspace"
$AgentPromptsRoot = Join-Path $StarCitizenRoot "prompts"
$AgentWorkRoot = Join-Path $StarCitizenRoot "work"
$AgentOutputRoot = Join-Path $StarCitizenRoot "output"
$AgentReportsRoot = Join-Path $AgentOutputRoot "reports"
$WorkspaceLaunchCmdPath = Join-Path $StarCitizenRoot "Open-StarCitizen-Workspace.cmd"
$ProjectAgentsPath = Join-Path $StarCitizenRoot "AGENTS.md"
$ProjectClaudePath = Join-Path $StarCitizenRoot "CLAUDE.md"
$GuideRepoName = "How-to-Guide-for-Extracting-and-Modding-Star-Citizen-Assets"
$GuideRepoUrl = "https://github.com/DirectorGunner/How-to-Guide-for-Extracting-and-Modding-Star-Citizen-Assets.git"
$GuideRepoPath = Join-Path $StarCitizenRoot $GuideRepoName
$SetupSummaryPath = Join-Path $ScLogsRoot ("setup-summary-{0}.txt" -f (Get-Date).ToString('yyyyMMdd-HHmmss'))
$SetupCacheRoot = Join-Path $ScDataRoot ".setup-cache"
$scriptVersionFromEnv = if (-not [string]::IsNullOrWhiteSpace($env:DG_SCRIPT_VERSION)) { [string]$env:DG_SCRIPT_VERSION } elseif (-not [string]::IsNullOrWhiteSpace($env:DG_SCRIPT_BUILD)) { [string]$env:DG_SCRIPT_BUILD } elseif (-not [string]::IsNullOrWhiteSpace($env:DG_VERSION)) { [string]$env:DG_VERSION } else { "v0.38" }
$testedBuildsFromEnv = if (-not [string]::IsNullOrWhiteSpace($env:DG_STAR_CITIZEN_TESTED_BUILDS)) { [string]$env:DG_STAR_CITIZEN_TESTED_BUILDS } elseif (-not [string]::IsNullOrWhiteSpace($env:DG_STAR_CITIZEN_COMPAT)) { [string]$env:DG_STAR_CITIZEN_COMPAT } else { "LIVE-4.8-and-older" }
$Script:ScriptVersion = $scriptVersionFromEnv
$Script:InternalBuildVersion = $Script:ScriptVersion
$Script:ReleaseVersion = $Script:ScriptVersion
$Script:StarCitizenTestedBuilds = $testedBuildsFromEnv
$Script:StarCitizenTestedBuildsDisplay = (($Script:StarCitizenTestedBuilds -replace '-', ' ').Trim())
$Script:StarCitizenCompatibility = $Script:StarCitizenTestedBuilds
$Script:VSCodeCommandPath = $null
$Script:SetupSteps = @()
$Script:SetupStepLookup = @{}
$Script:ProgressHeaderEnabled = $false
$Script:ProgressHeaderTop = 0
$Script:ProgressHeaderHeight = 5
$Script:ProgressLastPercent = -1
$Script:ProgressLastText = ""
$Script:TranscriptStarted = $false
$Script:TranscriptLogPath = ""
$Script:CurrentStepNumber = 0
$Script:CurrentStepName = "Initializing"
$Script:CurrentCompletedBefore = 0
$Script:HiddenDryRun = $false
$Script:VisualPreviewMode = $false
$Script:HarnessMode = [bool]$HarnessMode
$Script:HarnessRoot = [string]$HarnessRoot
$Script:NoExternalActions = [bool]$NoExternalActions
$Script:NoNetwork = [bool]$NoNetwork
$Script:NoGui = [bool]$NoGui
$Script:NoUserEnvWrites = [bool]$NoUserEnvWrites
$Script:NoGlobalGitConfig = [bool]$NoGlobalGitConfig
$Script:PlanOnly = [bool]$PlanOnly
$Script:EmitPlanJson = [string]$EmitPlanJson
$Script:NoPause = [bool]$NoPause
$Script:AgentPromptsRoot = [string]$AgentPromptsRoot
$Script:AgentWorkRoot = [string]$AgentWorkRoot
$Script:AgentOutputRoot = [string]$AgentOutputRoot
$Script:AgentReportsRoot = [string]$AgentReportsRoot
$Script:WorkspaceLaunchCmdPath = [string]$WorkspaceLaunchCmdPath
$Script:ProjectAgentsPath = [string]$ProjectAgentsPath
$Script:ProjectClaudePath = [string]$ProjectClaudePath
$Script:GuideUrl = "https://github.com/DirectorGunner/How-to-Guide-for-Extracting-and-Modding-Star-Citizen-Assets"
$Script:CommandLogCounter = 0
$Script:LiveDashboardEnabled = $true
$Script:LastCommandLogPath = ""
$Script:LastCommandDisplay = ""
$Script:LastActivityNote = ""
$Script:ActivityExtraStatusCache = @()
$Script:ActivityExtraStatusLastRefresh = [datetime]::MinValue
$Script:FileOpWatchPaths = @()
# v11 additions
$Script:CachedConsoleWidth = 0          # cached console width (refreshed every 2s)
$Script:CachedConsoleWidthTick = 0
$Script:StepTimings = New-Object 'System.Collections.Generic.List[object]'  # per-step elapsed times for end-of-run summary
$Script:CurrentStepStart = $null         # set by Invoke-SetupStep at start of each step
$Script:CurrentStepId = ""               # so the failure handler can emit a tailored resume hint
$Script:LongStepThresholdSeconds = 300   # >5 minutes is a "long" step (gets sound notification)
# v12 additions
$Script:LastDirectorySizeBytes = @{}     # path -> last sampled byte total (populated by Get-DirectorySizeApprox)
$Script:VSCacheSamples = New-Object 'System.Collections.Generic.List[object]'  # rolling samples (timestamp, bytes) for throughput math
# v13 additions
$Script:SetupFailures = New-Object 'System.Collections.Generic.List[object]'   # recoverable failures collected for the final summary
$Script:SetupSkips = New-Object 'System.Collections.Generic.List[object]'      # dependency-based skips collected for the final summary
$Script:SetupStatePath = Join-Path $ScDataRoot "setup-state.json"              # best-effort resume/history state
$Script:FatalFailure = $false
$Script:IsSandbox = $false
$Script:AbortRequested = $false
$Script:LauncherPath = [Environment]::GetEnvironmentVariable("DG_SELF")
$Script:LauncherDir = [Environment]::GetEnvironmentVariable("DG_LAUNCHER_DIR")
$Script:ToolStates = @{}
$Script:RepoStates = @{}
$Script:BranchStates = New-Object 'System.Collections.Generic.List[object]'
$Script:OrchestrationRepoPath = ""
$Script:BlenderState = [ordered]@{ status = "NotStarted"; exe = ""; version = ""; installRoot = ""; userConfigRoot = ""; addonLinked = $false; addonLinkType = "" }
$Script:P4KState = [ordered]@{ status = "NotStarted"; build = ""; source = ""; destination = ""; partialDestination = ""; sizeBytes = 0; spaceWarning = $false; readOnly = $false; skippedReason = ""; channel = ""; starCitizenExe = ""; productVersion = ""; fileVersion = "" }
$Script:AgentGuidanceState = [ordered]@{
    status = "NotStarted"; reason = ""
    promptsRoot = [string]$AgentPromptsRoot; workRoot = [string]$AgentWorkRoot; outputRoot = [string]$AgentOutputRoot; reportsRoot = [string]$AgentReportsRoot
    agentsPath = [string]$ProjectAgentsPath; agentsStatus = ""; agentsFallbackPath = ""
    claudePath = [string]$ProjectClaudePath; claudeStatus = ""; claudeFallbackPath = ""
    launcherPath = [string]$WorkspaceLaunchCmdPath; launcherStatus = ""
}
$Script:TutorialRepoState = [ordered]@{ path = ""; originatedFromLauncher = $false; branchStatus = ""; branchStatusReason = "" }

if ($HiddenPreview) {
    $DryRun = $true
    $AssumeYes = $true
    $Script:HiddenDryRun = $true
    $Script:VisualPreviewMode = $true
}


function Write-Step {
    param([string]$Message)
    if ($Script:VisualPreviewMode) { return }
    Write-Host "`n=== $Message ===" -ForegroundColor Cyan
}

function Write-SubStep {
    param([string]$Message)
    if ($Script:VisualPreviewMode) { return }
    Write-Host "--- $Message" -ForegroundColor DarkCyan
}

function Get-InstallerFullPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    try { return ([IO.Path]::GetFullPath($Path)).TrimEnd([char[]]@('\','/')) } catch { return ([string]$Path).TrimEnd([char[]]@('\','/')) }
}

function Test-InstallerPathUnderRoot {
    param([string]$Path, [string]$Root)
    $full = Get-InstallerFullPath -Path $Path
    $base = Get-InstallerFullPath -Path $Root
    if ([string]::IsNullOrWhiteSpace($full) -or [string]::IsNullOrWhiteSpace($base)) { return $false }
    if ($full.Equals($base, [StringComparison]::OrdinalIgnoreCase)) { return $true }
    $prefix = $base.TrimEnd([char[]]@('\','/')) + [IO.Path]::DirectorySeparatorChar
    return $full.StartsWith($prefix, [StringComparison]::OrdinalIgnoreCase)
}

function Test-NonLiveInstallerMode {
    return ($Script:HarnessMode -or $Script:PlanOnly -or $SelfTest -or $Script:NoExternalActions)
}

function Get-InstallerAllowedWriteRoots {
    $roots = New-Object 'System.Collections.Generic.List[string]'
    if (-not [string]::IsNullOrWhiteSpace($Script:HarnessRoot)) { [void]$roots.Add($Script:HarnessRoot) }
    if (-not [string]::IsNullOrWhiteSpace($Script:OriginalAgentWorkRoot)) { [void]$roots.Add($Script:OriginalAgentWorkRoot) }
    if (-not [string]::IsNullOrWhiteSpace($Script:AgentWorkRoot)) { [void]$roots.Add($Script:AgentWorkRoot) }
    return @($roots.ToArray() | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)
}

function Assert-HarnessPathAllowed {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$Purpose = "write"
    )
    if (-not (Test-NonLiveInstallerMode)) { return }
    $full = Get-InstallerFullPath -Path $Path
    foreach ($root in @(Get-InstallerAllowedWriteRoots)) {
        if (Test-InstallerPathUnderRoot -Path $full -Root $root) { return }
    }
    $allowed = (Get-InstallerAllowedWriteRoots) -join "; "
    throw "Harness safety blocked $Purpose outside allowed test roots. Path: $full Allowed roots: $allowed"
}

function Test-ExternalActionsAllowed {
    return (-not $Script:NoExternalActions -and -not $Script:PlanOnly)
}

function Test-InstallerGitCommandAllowed {
    param(
        [string[]]$Arguments = @(),
        [string]$WorkingDirectory = ""
    )
    if (-not (Test-NonLiveInstallerMode)) { return $true }
    if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) {
        Assert-HarnessPathAllowed -Path $WorkingDirectory -Purpose "Git working directory"
    }
    $joined = (($Arguments | ForEach-Object { [string]$_ }) -join " ")
    if ($joined -match '(?i)(^|\s)(clone|pull|push|fetch|rebase|clean|reset)(\s|$)') { return $false }
    if ($joined -match '(?i)(^|\s)credential(\s|$)') { return $false }
    if (($Arguments -contains "config") -and ($Arguments -contains "--global")) { return $false }
    return $true
}

function Assert-InstallerExternalCommandAllowed {
    param(
        [Parameter(Mandatory=$true)][string]$Exe,
        [string[]]$Arguments = @(),
        [string]$WorkingDirectory = ""
    )
    if (Test-ExternalActionsAllowed) { return }
    $leaf = [IO.Path]::GetFileName($Exe)
    if ($leaf -match '^(?i:git(\.exe)?)$' -and (Test-InstallerGitCommandAllowed -Arguments $Arguments -WorkingDirectory $WorkingDirectory)) { return }
    throw "Non-live harness blocked external command: $(Format-CommandDisplay -Exe $Exe -Arguments $Arguments)"
}

function Invoke-InstallerExternalCommand {
    param(
        [Parameter(Mandatory=$true)][string]$Exe,
        [string[]]$Arguments = @(),
        [switch]$IgnoreExitCode,
        [string]$WorkingDirectory = ""
    )
    Assert-InstallerExternalCommandAllowed -Exe $Exe -Arguments $Arguments -WorkingDirectory $WorkingDirectory
    Run-Native -Exe $Exe -Arguments $Arguments -IgnoreExitCode:$IgnoreExitCode -WorkingDirectory $WorkingDirectory
}

function Invoke-InstallerGitCommand {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string[]]$Arguments = @(),
        [switch]$IgnoreExitCode
    )
    $allArgs = @("-C", $Path) + @($Arguments)
    Assert-InstallerExternalCommandAllowed -Exe "git" -Arguments $allArgs -WorkingDirectory $Path
    Run-Native -Exe "git" -Arguments $allArgs -IgnoreExitCode:$IgnoreExitCode -WorkingDirectory $Path
}

function Invoke-InstallerDownload {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$OutFile,
        [string]$Method = ""
    )
    if ($Script:NoNetwork -or (Test-NonLiveInstallerMode)) { throw "Non-live harness blocked network request: $Uri" }
    Assert-HarnessPathAllowed -Path $OutFile -Purpose "download output"
    if ([string]::IsNullOrWhiteSpace($Method)) {
        Invoke-WebRequest -Uri $Uri -OutFile $OutFile -UseBasicParsing
    } else {
        Invoke-WebRequest -Uri $Uri -Method $Method -OutFile $OutFile -UseBasicParsing
    }
}

function New-InstallerDirectory {
    param([Parameter(Mandatory=$true)][string]$Path)
    Assert-HarnessPathAllowed -Path $Path -Purpose "directory creation"
    if ($DryRun) {
        Write-Host "[dry-run] mkdir $Path"
        return
    }
    New-Item -ItemType Directory -Force -Path $Path | Out-Null
}

function Write-InstallerFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Text
    )
    Assert-HarnessPathAllowed -Path $Path -Purpose "file write"
    $parent = Split-Path $Path -Parent
    if (-not [string]::IsNullOrWhiteSpace($parent)) { New-InstallerDirectory -Path $parent }
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($Path, $Text, $utf8)
}

function Set-InstallerUserEnvironmentVariable {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Value
    )
    if ($Script:NoUserEnvWrites) { throw "Non-live harness blocked user environment write: $Name" }
    [Environment]::SetEnvironmentVariable($Name, $Value, "User")
}

function Start-InstallerGuiProcess {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string[]]$ArgumentList = @()
    )
    if ($Script:NoGui -or (Test-NonLiveInstallerMode)) { throw "Non-live harness blocked GUI launch: $FilePath" }
    Start-Process -FilePath $FilePath -ArgumentList $ArgumentList | Out-Null
}


function New-SetupStepObject {
    param(
        [Parameter(Mandatory=$true)][string]$Id,
        [Parameter(Mandatory=$true)][string]$Name
    )
    return [pscustomobject]@{ Id = $Id; Name = $Name }
}

function Test-ShouldRunGitVersioning {
    return ($CreateBranches -or $CreateWorkspace -or $BuildStarBreaker -or $InstallBlenderAddon -or $SetupP4K -or $PromptForP4K -or $RunAuroraExample -or (-not [string]::IsNullOrWhiteSpace($DataP4kSource)))
}

function Test-ShouldWriteAgentGuidance {
    return ($CloneRepos -or (Test-ShouldRunGitVersioning) -or $CreateWorkspace -or $RunInteractiveAuth -or $OpenWorkspace -or $Script:HarnessMode -or $SelfTest)
}

function Initialize-SetupPlan {
    $steps = New-Object 'System.Collections.Generic.List[System.Object]'

    # Mandatory setup bookkeeping steps always run unless the entire script is only listing steps.
    $steps.Add((New-SetupStepObject -Id "preflight-folders" -Name "Preflight checks, root validation, drive-space warning, and Sandbox detection"))
    $steps.Add((New-SetupStepObject -Id "logging-env" -Name "Transcript log, setup-state initialization, and environment variables"))

    if ($InstallTools) {
        $steps.Add((New-SetupStepObject -Id "winget-check" -Name "Validate WinGet availability"))
        $steps.Add((New-SetupStepObject -Id "install-git" -Name "Install or validate Git"))
        $steps.Add((New-SetupStepObject -Id "install-gh" -Name "Install or validate GitHub CLI"))
        $steps.Add((New-SetupStepObject -Id "install-vsbuildtools" -Name "Install Visual Studio Build Tools"))
        $steps.Add((New-SetupStepObject -Id "install-rust" -Name "Install or validate Rust"))
        $steps.Add((New-SetupStepObject -Id "install-python" -Name "Install Python and shared venv"))
        $steps.Add((New-SetupStepObject -Id "install-dotnet" -Name "Install .NET SDKs"))
        $steps.Add((New-SetupStepObject -Id "install-cmake" -Name "Install CMake"))
        $steps.Add((New-SetupStepObject -Id "install-vscode" -Name "Install or validate VS Code"))
        $steps.Add((New-SetupStepObject -Id "install-node-codex" -Name "Install Node.js, npm cache, and optional Codex CLI"))
        $steps.Add((New-SetupStepObject -Id "execution-policy" -Name "Set CurrentUser PowerShell execution policy"))
    }

    if ($CloneRepos) {
        $steps.Add((New-SetupStepObject -Id "clone-repos" -Name "Clone or validate community repositories"))
        $steps.Add((New-SetupStepObject -Id "clone-guide-repo" -Name "Clone or validate DirectorGunner tutorial repository"))
    }
    if (Test-ShouldWriteAgentGuidance) {
        $steps.Add((New-SetupStepObject -Id "write-agent-guidance" -Name "Create agent guidance, prompt archive, work log, and report folders"))
    }
    if (Test-ShouldRunGitVersioning) {
        $steps.Add((New-SetupStepObject -Id "setup-git-versioning" -Name "Initialize local Git versioning and safe development branches"))
    }
    if ($CreateWorkspace) {
        $steps.Add((New-SetupStepObject -Id "write-workspace" -Name "Create VS Code multi-root workspace"))
        $steps.Add((New-SetupStepObject -Id "vscode-extensions" -Name "Install recommended VS Code extensions"))
    }
    if ($BuildStarBreaker) { $steps.Add((New-SetupStepObject -Id "build-starbreaker" -Name "Build StarBreaker and StarBreaker MCP")) }
    if (-not $SkipBlender -and ($PromptForBlender -or $InstallBlenderAddon -or -not [string]::IsNullOrWhiteSpace($BlenderPath))) {
        $steps.Add((New-SetupStepObject -Id "locate-blender" -Name "Locate or install Blender"))
    }
    if (-not $SkipBlender -and $InstallBlenderAddon) { $steps.Add((New-SetupStepObject -Id "install-blender-addon" -Name "Link StarBreaker Blender add-on")) }
    if (-not $SkipP4K -and ($SetupP4K -or $PromptForP4K -or $RunAuroraExample -or -not [string]::IsNullOrWhiteSpace($DataP4kSource))) {
        $steps.Add((New-SetupStepObject -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k"))
        $steps.Add((New-SetupStepObject -Id "verify-sc-build" -Name "Verify Star Citizen build environment"))
        $steps.Add((New-SetupStepObject -Id "p4k-explore" -Name "Explore P4K paths"))
    }
    if (-not $SkipP4K -and ($SetupP4K -or $PromptForP4K -or $RunAuroraExample -or -not [string]::IsNullOrWhiteSpace($DataP4kSource))) {
        $steps.Add((New-SetupStepObject -Id "aurora-example" -Name "Optional Aurora MR export example"))
    }
    if ($RunInteractiveAuth) { $steps.Add((New-SetupStepObject -Id "interactive-auth" -Name "Start interactive authentication helpers")) }

    $steps.Add((New-SetupStepObject -Id "final-verification" -Name "Final verification summary"))
    if ($OpenWorkspace) { $steps.Add((New-SetupStepObject -Id "open-workspace" -Name "Open generated VS Code workspace")) }
    $steps.Add((New-SetupStepObject -Id "complete" -Name "Completion notes"))

    $Script:SetupSteps = @($steps.ToArray())
    $Script:SetupStepLookup = @{}
    for ($i = 0; $i -lt $Script:SetupSteps.Count; $i++) {
        $Script:SetupStepLookup[$Script:SetupSteps[$i].Id] = ($i + 1)
    }
}

function Get-ConsoleWidthSafe {
    # v11: Cache console width for 2 seconds. Fit-ConsoleLine is called dozens
    # of times per dashboard repaint, and each call hit RawUI.WindowSize.Width.
    # On Windows hosts where that call traps into the conhost subsystem, this
    # was a measurable slice of per-frame CPU and a source of dashboard flicker
    # during fast steps. Two seconds is short enough that interactive window
    # resizes still feel responsive.
    try {
        $now = [Environment]::TickCount
        if ($Script:CachedConsoleWidth -gt 0 -and ($now - $Script:CachedConsoleWidthTick) -lt 2000) {
            return $Script:CachedConsoleWidth
        }
        $w = $Host.UI.RawUI.WindowSize.Width
        if ($w -lt 60) { $w = 60 }
        $Script:CachedConsoleWidth = $w
        $Script:CachedConsoleWidthTick = $now
        return $w
    } catch {
        return 100
    }
}

function Fit-ConsoleLine {
    param([string]$Text)
    $width = Get-ConsoleWidthSafe
    $max = [Math]::Max(20, $width - 1)
    if ($null -eq $Text) { $Text = "" }
    if ($Text.Length -gt $max) { return $Text.Substring(0, $max) }
    return $Text.PadRight($max)
}

function Convert-ArtToLines {
    param([string]$Art)

    if ($null -eq $Art) { return @() }

    $items = New-Object 'System.Collections.Generic.List[string]'
    foreach ($line in ($Art -split '\r?\n')) {
        [void]$items.Add($line.TrimEnd("`r"))
    }

    while (($items.Count -gt 0) -and [string]::IsNullOrWhiteSpace($items[0])) {
        $items.RemoveAt(0)
    }

    while (($items.Count -gt 0) -and [string]::IsNullOrWhiteSpace($items[$items.Count - 1])) {
        $items.RemoveAt($items.Count - 1)
    }

    return @($items.ToArray())
}

function Resolve-ProgressBannerStyle {
    # Author-controlled. The launcher no longer exposes banner selection to users.
    # Keep the sticky header stable and branded so the progress bar always sits
    # under the exact Anti-Slicer decoration.
    return "CompactNfo"
}

function Get-ProgressBannerLines {
    param([string]$Style = $BannerStyle)

    if ([string]::IsNullOrWhiteSpace($Style)) {
        $Style = Resolve-ProgressBannerStyle
    }

    switch ($Style) {
        "CompactNfo" {
            return @(
                "     .----[ DirectorGunner's Anti-Slicer Script ]----.",
                "   _/         ZERO TO HERO :: LOCAL RIG SETUP        \_",
                "  /__  MAKE IT EASY // MAKE IT FAST // MAKE IT SEXY  __\"
            )
        }

        "DirectorGunnerAscii" {
            $art = @'
  ___ ___ ___ ___ ___ _____ ___  ___  ___ _   _ _  _ _  _ ___ ___
 |   \_ _| _ \ __/ __|_   _/ _ \| _ \/ __| | | | \| | \| | __| _ \
 | |) | ||   / _| (__  | || (_) |   / (_ | |_| | .` | .` | _||   /
 |___/___|_|_\___\___| |_| \___/|_|_\\___|\___/|_|\_|_|\_|___|_|_\
'@
            $lines = New-Object 'System.Collections.Generic.List[string]'
            [void]$lines.Add("     .----[ DirectorGunner's Anti-Slicer Script ]----.")
            [void]$lines.Add("   _/         ZERO TO HERO :: LOCAL RIG SETUP        \_")
            [void]$lines.Add("  /__  MAKE IT EASY // MAKE IT FAST // MAKE IT SEXY  __\")
            foreach ($line in (Convert-ArtToLines $art)) { [void]$lines.Add($line) }
            return @($lines.ToArray())
        }

        "SceneBox" {
            $art = @'
  +--------------------------------------------------------------------+
  | DirectorGunner's Anti-Slicer Script                                |
  | ZERO TO HERO :: LOCAL RIG SETUP                                    |
  | MAKE IT EASY // MAKE IT FAST // MAKE IT SEXY                       |
  +--------------------------------------------------------------------+
'@
            return Convert-ArtToLines $art
        }

        "UnicodeGlitch" {
            $art = @'
  ░▒▓ DirectorGunner's Anti-Slicer Script ▓▒░
  ⣿⠿⠛⠉⠁  ZERO TO HERO :: LOCAL RIG SETUP  ⠈⠉⠛⠿⣿
  ░▒▓ MAKE IT EASY // MAKE IT FAST // MAKE IT SEXY ▓▒░
'@
            return Convert-ArtToLines $art
        }

        default {
            return @(
                "     .----[ DirectorGunner's Anti-Slicer Script ]----.",
                "   _/         ZERO TO HERO :: LOCAL RIG SETUP        \_",
                "  /__  MAKE IT EASY // MAKE IT FAST // MAKE IT SEXY  __\"
            )
        }
    }
}

function Get-ProgressHeaderLineCount {
    $bannerLines = @(Get-ProgressBannerLines -Style $BannerStyle)
    return [Math]::Max(5, $bannerLines.Count + 4)
}

function Get-StarshipProgressBar {
    param([int]$Percent)
    $barWidth = [Math]::Max(20, [Math]::Min(100, $ProgressBarWidth))
    $pct = [Math]::Max(0, [Math]::Min(100, $Percent))
    $filled = [int][Math]::Floor(($pct / 100.0) * $barWidth)
    if ($pct -ge 100) {
        return "[" + ("=" * $barWidth) + "]"
    }
    if ($filled -lt 1) { $filled = 1 }
    $left = "=" * ($filled - 1)
    $right = "." * ($barWidth - $filled)
    return "[" + $left + ">" + $right + "]"
}

function Get-CenteredProgressLine {
    param(
        [Parameter(Mandatory=$true)][string]$Ship,
        [Parameter(Mandatory=$true)][string]$Bar,
        [Parameter(Mandatory=$true)][int]$Percent
    )

    $text = ("{0}  {1}  {2}%" -f $Ship, $Bar, $Percent)
    $bannerWidth = 0
    foreach ($line in (Get-ProgressBannerLines -Style $BannerStyle)) {
        if ($null -ne $line -and $line.Length -gt $bannerWidth) { $bannerWidth = $line.Length }
    }
    if ($bannerWidth -le 0) { return $text }

    $pad = [Math]::Max(0, [Math]::Floor(($bannerWidth - $text.Length) / 2))
    return ((" " * $pad) + $text)
}


function Get-RecordedStepStatus {
    param([string]$Id)
    if ([string]::IsNullOrWhiteSpace($Id) -or $null -eq $Script:StepTimings) { return "" }
    $match = @($Script:StepTimings | Where-Object { $_.Id -eq $Id } | Select-Object -Last 1)
    if ($match.Count -eq 0) { return "" }
    return [string]$match[0].Status
}

function Test-SetupStepFailedOrSkipped {
    param([string]$Id)
    $status = Get-RecordedStepStatus -Id $Id
    return ($status -in @("FAIL", "FAILED", "SKIPPED", "FATAL"))
}

function Get-StepDisplayState {
    param(
        [string]$StepId,
        [int]$StepIndex,
        [int]$CompletedCount,
        [int]$CurrentStepNumber,
        [string]$CurrentStatus,
        [switch]$Preview
    )

    $recorded = Get-RecordedStepStatus -Id $StepId
    if (-not [string]::IsNullOrWhiteSpace($recorded)) {
        switch ($recorded) {
            "OK"      { return @{ State="DONE "; Glyph="[OK]"; Color="DarkGray" } }
            "Preview" { return @{ State="DONE "; Glyph="[OK]"; Color="DarkGray" } }
            "FAILED"  { return @{ State="FAIL "; Glyph="[!!]"; Color="Red" } }
            "FATAL"   { return @{ State="FATAL"; Glyph="[XX]"; Color="Red" } }
            "SKIPPED" { return @{ State="SKIP "; Glyph="[SK]"; Color="DarkYellow" } }
            "WARN"    { return @{ State="WARN "; Glyph="[!!]"; Color="Yellow" } }
        }
    }

    $n = $StepIndex + 1
        if ($n -eq $CurrentStepNumber) {
            if ($CurrentStatus -eq "Complete") { return @{ State="DONE "; Glyph="[OK]"; Color="Green" } }
            if ($CurrentStatus -eq "FAILED") { return @{ State="FAIL "; Glyph="[!!]"; Color="Red" } }
            if ($CurrentStatus -eq "WARN") { return @{ State="WARN "; Glyph="[!!]"; Color="Yellow" } }
            if ($CurrentStatus -eq "SKIPPED") { return @{ State="SKIP "; Glyph="[SK]"; Color="DarkYellow" } }
            if ($Preview) { return @{ State="WORK "; Glyph="[>>]"; Color="Cyan" } } else { return @{ State="WORK "; Glyph="[>>]"; Color="Yellow" } }
        }

    if ($n -le $CompletedCount) { return @{ State="DONE "; Glyph="[OK]"; Color="DarkGray" } }
    return @{ State="WAIT "; Glyph="[--]"; Color="DarkGray" }
}

function Add-SetupFailureRecord {
    param(
        [string]$Id,
        [string]$Name,
        [string]$Reason,
        [string]$LogPath = "",
        [switch]$Fatal
    )
    if ([string]::IsNullOrWhiteSpace($Reason)) { $Reason = "Unknown failure." }
    $existingFailures = @()
    try { $existingFailures = @($Script:SetupFailures.ToArray()) } catch { $existingFailures = @() }
    foreach ($existing in $existingFailures) {
        try {
            if (([string]$existing.Id -ieq $Id) -and
                ([string]$existing.Reason -ieq $Reason) -and
                ([bool]$existing.Fatal -eq [bool]$Fatal)) {
                if ($Fatal) { $Script:FatalFailure = $true }
                return
            }
        } catch { }
    }
    $Script:SetupFailures.Add([pscustomobject]@{
        Id = $Id; Name = $Name; Reason = $Reason; LogPath = $LogPath; Fatal = [bool]$Fatal; Time = (Get-Date).ToString('s')
    }) | Out-Null
    if ($Fatal) { $Script:FatalFailure = $true }
}

function Add-SetupSkipRecord {
    param([string]$Id, [string]$Name, [string]$Reason)
    if ([string]::IsNullOrWhiteSpace($Reason)) { $Reason = "Skipped." }
    $existingSkips = @()
    try { $existingSkips = @($Script:SetupSkips.ToArray()) } catch { $existingSkips = @() }
    foreach ($existing in $existingSkips) {
        try {
            if (([string]$existing.Id -ieq $Id) -and
                ([string]$existing.Reason -ieq $Reason)) {
                return
            }
        } catch { }
    }
    $Script:SetupSkips.Add([pscustomobject]@{
        Id = $Id; Name = $Name; Reason = $Reason; Time = (Get-Date).ToString('s')
    }) | Out-Null
}

function Set-CurrentSetupStepSkipped {
    param([string]$Id, [string]$Name, [string]$Reason)
    if ([string]::IsNullOrWhiteSpace($Reason)) { $Reason = "Skipped." }
    Add-SetupSkipRecord -Id $Id -Name $Name -Reason $Reason
    $Script:CurrentStepResultStatus = "SKIPPED"
    $Script:CurrentStepResultReason = $Reason
}

function Get-SetupSkipReason {
    param([string]$Id)
    if ([string]::IsNullOrWhiteSpace($Id)) { return "" }
    try {
        $matches = @($Script:SetupSkips | Where-Object { [string]$_.Id -eq $Id } | Select-Object -Last 1)
        if ($matches.Count -gt 0) { return [string]$matches[0].Reason }
    } catch { }
    return ""
}

function Test-BuildToolsSkippedByUserChoice {
    $reason = Get-SetupSkipReason -Id "install-vsbuildtools"
    if ((Get-RecordedStepStatus -Id "install-vsbuildtools") -eq "SKIPPED" -and $reason -eq "Build Tools skipped by user choice.") { return $true }
    try {
        if ($Script:ToolStates.ContainsKey("vsbuildtools")) {
            $tool = $Script:ToolStates["vsbuildtools"]
            return (([string]$tool.status -eq "SKIPPED") -and ([string]$tool.reason -eq "Build Tools skipped by user choice."))
        }
    } catch { }
    return $false
}

function Get-StarBreakerReleaseBinaryState {
    param([string]$StarBreakerRoot = "")
    if ([string]::IsNullOrWhiteSpace($StarBreakerRoot)) { $StarBreakerRoot = Join-Path $StarCitizenRoot "StarBreaker" }
    $starbreakerExe = Join-Path $StarBreakerRoot "target\release\starbreaker.exe"
    $mcpExe = Join-Path $StarBreakerRoot "target\release\starbreaker-mcp.exe"
    return [pscustomobject]@{
        Ready = ((Test-Path -LiteralPath $starbreakerExe) -and (Test-Path -LiteralPath $mcpExe))
        StarBreakerRoot = $StarBreakerRoot
        StarBreakerExe = $starbreakerExe
        McpExe = $mcpExe
    }
}

function Test-StarBreakerReleaseBinariesReady {
    param([string]$StarBreakerRoot = "")
    return [bool](Get-StarBreakerReleaseBinaryState -StarBreakerRoot $StarBreakerRoot).Ready
}

function Get-StepDependencySkipReason {
    param([string]$Id)

    $depends = @()
    switch ($Id) {
        "install-git"          { $depends = @("winget-check") }
        "install-rust"         { $depends = @("winget-check") }
        "clone-repos"          { $depends = @("install-git") }
        "clone-guide-repo"     { $depends = @("install-git") }
        "write-agent-guidance" { $depends = @("clone-guide-repo") }
        "setup-git-versioning" { $depends = @("install-git", "clone-repos", "clone-guide-repo", "write-agent-guidance") }
        "vscode-extensions"    { $depends = @("write-workspace", "install-vscode") }
        "create-branches"      { $depends = @("install-git", "clone-repos", "clone-guide-repo") }
        "build-starbreaker"    { $depends = @("install-vsbuildtools", "install-rust", "clone-repos", "setup-git-versioning") }
        "write-workspace"      { $depends = @("clone-repos", "clone-guide-repo", "write-agent-guidance", "setup-git-versioning") }
        "locate-blender"       { $depends = @("setup-git-versioning") }
        "install-blender-addon"{ $depends = @("clone-repos", "setup-git-versioning", "locate-blender") }
        "select-data-p4k"      { $depends = @("setup-git-versioning") }
        "verify-sc-build"      { $depends = @("select-data-p4k") }
        "p4k-explore"          { $depends = @("verify-sc-build", "build-starbreaker") }
        "aurora-example"       { $depends = @("build-starbreaker", "verify-sc-build") }
        "open-workspace"       { $depends = @("write-workspace", "install-vscode") }
        default                 { $depends = @() }
    }

    $blocked = New-Object 'System.Collections.Generic.List[string]'
    foreach ($dep in $depends) {
        if ($Id -eq "build-starbreaker" -and $dep -eq "install-vsbuildtools" -and (Test-BuildToolsSkippedByUserChoice)) {
            if (Test-StarBreakerReleaseBinariesReady) { continue }
            return "Skipped because Build Tools were skipped by user choice and no existing StarBreaker release binaries were available to reuse."
        }
        if (Test-SetupStepFailedOrSkipped -Id $dep) { [void]$blocked.Add($dep) }
    }
    if ($blocked.Count -gt 0) {
        return ("Skipped because required earlier step(s) did not complete: " + (($blocked.ToArray()) -join ", "))
    }
    return ""
}

function ConvertTo-PlainStateRecord {
    param($Value)
    try {
        if ($null -eq $Value) { return $null }
        if ($Value -is [string]) { return [string]$Value }
        if ($Value -is [bool]) { return [bool]$Value }
        if ($Value -is [datetime]) { return $Value.ToString('s') }
        if ($Value -is [timespan]) { return $Value.ToString() }
        if ($Value -is [int] -or $Value -is [long] -or $Value -is [double] -or $Value -is [decimal] -or $Value -is [single] -or $Value -is [byte]) { return $Value }
        return [string]$Value
    } catch { return "" }
}

function Get-SimpleObjectFromProperties {
    param($Object, [string[]]$PropertyNames)
    $out = [ordered]@{}
    if ($null -eq $Object) { return $out }
    foreach ($name in $PropertyNames) {
        try { $out[$name] = ConvertTo-PlainStateRecord -Value $Object.$name } catch { $out[$name] = "" }
    }
    return $out
}

function Get-ListSnapshot {
    param($List)
    if ($null -eq $List) { return @() }
    try {
        if ($List.PSObject.Methods.Name -contains "ToArray") { return @($List.ToArray()) }
    } catch { }
    try { return @($List | ForEach-Object { $_ }) } catch { return @() }
}

function Get-StepTimingPlainList {
    param([string[]]$Statuses = @())
    $list = New-Object 'System.Collections.Generic.List[object]'
    try {
        foreach ($r in (Get-ListSnapshot $Script:StepTimings)) {
            if ($null -eq $r) { continue }
            $status = [string]$r.Status
            if ($Statuses.Count -gt 0 -and -not ($Statuses -contains $status)) { continue }
            $elapsedValue = 0.0
            try { $elapsedValue = [double]$r.ElapsedSeconds } catch { $elapsedValue = 0.0 }
            [void]$list.Add([ordered]@{
                id = [string]$r.Id
                name = [string]$r.Name
                elapsedSeconds = $elapsedValue
                status = $status
                reason = [string]$r.Reason
            })
        }
    } catch { }
    return @($list.ToArray())
}

function Get-SkipPlainList {
    $list = New-Object 'System.Collections.Generic.List[object]'
    try { foreach ($r in (Get-ListSnapshot $Script:SetupSkips)) { [void]$list.Add((Get-SimpleObjectFromProperties -Object $r -PropertyNames @('Id','Name','Reason','Time'))) } } catch { }
    return @($list.ToArray())
}

function Get-FailurePlainList {
    $list = New-Object 'System.Collections.Generic.List[object]'
    try { foreach ($r in (Get-ListSnapshot $Script:SetupFailures)) { [void]$list.Add((Get-SimpleObjectFromProperties -Object $r -PropertyNames @('Id','Name','Reason','LogPath','Fatal','Time'))) } } catch { }
    return @($list.ToArray())
}

function Get-BranchPlainList {
    $list = New-Object 'System.Collections.Generic.List[object]'
    try {
        foreach ($r in (Get-ListSnapshot $Script:BranchStates)) {
            [void]$list.Add((Get-SimpleObjectFromProperties -Object $r -PropertyNames @(
                'Repo','Role','Path','GitExists','Branch','CurrentBranch','Dirty','DirtyStatus',
                'IdentityStatus','IdentityLocalPresent','IdentityCopiedFromGlobal','IdentityFallbackWritten',
                'Status','Reason'
            )))
        }
    } catch { }
    return @($list.ToArray())
}

function Get-RepoPlainList {
    $list = New-Object 'System.Collections.Generic.List[object]'
    try {
        foreach ($key in @($Script:RepoStates.Keys)) {
            $r = $Script:RepoStates[$key]
            $repoPath = ""; $repoUrl = ""; $repoStatus = ""; $repoReason = ""
            try { $repoPath = [string]$r.path } catch { }
            try { $repoUrl = [string]$r.url } catch { }
            try { $repoStatus = [string]$r.status } catch { }
            try { $repoReason = [string]$r.reason } catch { }
            [void]$list.Add([ordered]@{
                name = [string]$key
                path = $repoPath
                url = $repoUrl
                status = $repoStatus
                reason = $repoReason
            })
        }
    } catch { }
    return @($list.ToArray())
}

function Set-ToolState {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [string]$Status = "",
        [string]$Path = "",
        [string]$Version = "",
        [string]$Source = "",
        [string]$Reason = "",
        [bool]$LocalValidated = $false,
        [bool]$InstallNeeded = $false,
        [bool]$NetworkLookupNeeded = $false,
        [bool]$NetworkBlocked = $false,
        [string]$VenvStatus = ""
    )
    $Script:ToolStates[$Name] = [ordered]@{
        name = $Name
        status = $Status
        path = $Path
        version = $Version
        source = $Source
        reason = $Reason
        localValidated = [bool]$LocalValidated
        installNeeded = [bool]$InstallNeeded
        networkLookupNeeded = [bool]$NetworkLookupNeeded
        networkBlocked = [bool]$NetworkBlocked
        venvStatus = $VenvStatus
    }
}

function Get-ToolStatePlainList {
    $list = New-Object 'System.Collections.Generic.List[object]'
    try {
        foreach ($key in @($Script:ToolStates.Keys)) {
            $r = $Script:ToolStates[$key]
            if ($null -eq $r) { continue }
            [void]$list.Add([ordered]@{
                name = [string]$r.name
                status = [string]$r.status
                path = [string]$r.path
                version = [string]$r.version
                source = [string]$r.source
                reason = [string]$r.reason
                localValidated = [bool]$r.localValidated
                installNeeded = [bool]$r.installNeeded
                networkLookupNeeded = [bool]$r.networkLookupNeeded
                networkBlocked = [bool]$r.networkBlocked
                venvStatus = [string]$r.venvStatus
            })
        }
    } catch { }
    return @($list.ToArray())
}


function Get-SafeInt64Value {
    param($Value)
    try { return [int64]$Value } catch { return [int64]0 }
}

function Get-TutorialRepoStatePlain {
    $path = ""; $originated = $false; $branchStatus = ""; $branchReason = ""
    try { $path = [string]$Script:TutorialRepoState.path } catch { }
    try { $originated = [bool]$Script:TutorialRepoState.originatedFromLauncher } catch { }
    try { $branchStatus = [string]$Script:TutorialRepoState.branchStatus } catch { }
    try { $branchReason = [string]$Script:TutorialRepoState.branchStatusReason } catch { }
    return [ordered]@{
        path = $path
        originatedFromLauncher = $originated
        branchStatus = $branchStatus
        branchStatusReason = $branchReason
    }
}


function Save-SetupState {
    if ($DryRun -or $Script:HiddenDryRun -or $Script:VisualPreviewMode) { return }
    if ([string]::IsNullOrWhiteSpace($Script:SetupStatePath)) { return }

    function New-PlainStepRecord([object]$r) {
        $elapsed = 0.0
        try { $elapsed = [double]$r.ElapsedSeconds } catch { $elapsed = 0.0 }
        return [ordered]@{
            id = [string]$r.Id
            name = [string]$r.Name
            status = [string]$r.Status
            elapsedSeconds = $elapsed
            reason = [string]$r.Reason
        }
    }

    $writeState = {
        param($StateObject)
        Assert-HarnessPathAllowed -Path $Script:SetupStatePath -Purpose "setup-state write"
        Ensure-Directory (Split-Path $Script:SetupStatePath -Parent)
        $json = [string]($StateObject | ConvertTo-Json -Depth 10)
        if ([string]::IsNullOrWhiteSpace($json)) { $json = "{}" }
        $tmp = "$($Script:SetupStatePath).tmp"
        $bytes = [System.Text.Encoding]::UTF8.GetBytes($json)
        [System.IO.File]::WriteAllBytes($tmp, $bytes)
        if (Test-Path -LiteralPath $Script:SetupStatePath) {
            Remove-Item -LiteralPath $Script:SetupStatePath -Force -ErrorAction SilentlyContinue
        }
        Move-Item -LiteralPath $tmp -Destination $Script:SetupStatePath -Force
    }

    try {
        $stepList = New-Object 'System.Collections.Generic.List[object]'
        foreach ($r in (Get-ListSnapshot $Script:StepTimings)) {
            if ($null -eq $r) { continue }
            [void]$stepList.Add((New-PlainStepRecord $r))
        }

        $skipList = New-Object 'System.Collections.Generic.List[object]'
        foreach ($r in (Get-ListSnapshot $Script:SetupSkips)) {
            if ($null -eq $r) { continue }
            [void]$skipList.Add([ordered]@{ id=[string]$r.Id; name=[string]$r.Name; reason=[string]$r.Reason; time=[string]$r.Time })
        }

        $failList = New-Object 'System.Collections.Generic.List[object]'
        foreach ($r in (Get-ListSnapshot $Script:SetupFailures)) {
            if ($null -eq $r) { continue }
            $fatal = $false
            try { $fatal = [bool]$r.Fatal } catch { $fatal = $false }
            [void]$failList.Add([ordered]@{ id=[string]$r.Id; name=[string]$r.Name; reason=[string]$r.Reason; logPath=[string]$r.LogPath; fatal=$fatal; time=[string]$r.Time })
        }

        $branchList = New-Object 'System.Collections.Generic.List[object]'
        foreach ($r in (Get-ListSnapshot $Script:BranchStates)) {
            if ($null -eq $r) { continue }
            $gitExists = $false; $dirty = $false; $identityLocal = $false; $identityCopied = $false; $identityFallback = $false
            try { $gitExists = [bool]$r.GitExists } catch { }
            try { $dirty = [bool]$r.Dirty } catch { }
            try { $identityLocal = [bool]$r.IdentityLocalPresent } catch { }
            try { $identityCopied = [bool]$r.IdentityCopiedFromGlobal } catch { }
            try { $identityFallback = [bool]$r.IdentityFallbackWritten } catch { }
            [void]$branchList.Add([ordered]@{
                repo=[string]$r.Repo
                role=[string]$r.Role
                path=[string]$r.Path
                gitExists=$gitExists
                branchTarget=[string]$r.Branch
                currentBranch=[string]$r.CurrentBranch
                dirty=$dirty
                dirtyStatus=[string]$r.DirtyStatus
                identityStatus=[string]$r.IdentityStatus
                identityLocalPresent=$identityLocal
                identityCopiedFromGlobal=$identityCopied
                identityFallbackWritten=$identityFallback
                status=[string]$r.Status
                reason=[string]$r.Reason
            })
        }

        $repoList = New-Object 'System.Collections.Generic.List[object]'
        try {
            foreach ($key in @($Script:RepoStates.Keys)) {
                $r = $Script:RepoStates[$key]
                [void]$repoList.Add([ordered]@{
                    name=[string]$key
                    path=[string]$r.path
                    url=[string]$r.url
                    status=[string]$r.status
                    reason=[string]$r.reason
                })
            }
        } catch { }

        $completedList = New-Object 'System.Collections.Generic.List[object]'
        foreach ($r in (Get-ListSnapshot $Script:StepTimings)) {
            if ($null -eq $r) { continue }
            $statusValue = ""
            try { $statusValue = [string]$r.Status } catch { $statusValue = "" }
            if (@('OK','Preview') -contains $statusValue) { [void]$completedList.Add((New-PlainStepRecord $r)) }
        }

        $toolList = New-Object 'System.Collections.Generic.List[object]'
        foreach ($r in (Get-ToolStatePlainList)) {
            if ($null -eq $r) { continue }
            [void]$toolList.Add($r)
        }

        $state = [ordered]@{
            version = [string]$Script:ScriptVersion
            scriptVersion = [string]$Script:ScriptVersion
            starCitizenTestedBuilds = [string]$Script:StarCitizenTestedBuilds
            starCitizenTestedBuildsDisplay = [string]$Script:StarCitizenTestedBuildsDisplay
            lastRun = (Get-Date).ToString('s')
            devRoot = [string]$DevRoot
            isSandbox = [bool]$Script:IsSandbox
            launcherPath = [string]$Script:LauncherPath
            launcherDir = [string]$Script:LauncherDir
            tools = @($toolList.ToArray())
            repositories = @($repoList.ToArray())
            branches = @($branchList.ToArray())
            tutorialRepo = [ordered]@{
                path = [string]$Script:TutorialRepoState.path
                originatedFromLauncher = [bool]$Script:TutorialRepoState.originatedFromLauncher
                branchStatus = [string]$Script:TutorialRepoState.branchStatus
                branchStatusReason = [string]$Script:TutorialRepoState.branchStatusReason
            }
            blender = [ordered]@{
                status = [string]$Script:BlenderState.status
                exe = [string]$Script:BlenderState.exe
                version = [string]$Script:BlenderState.version
                installRoot = [string]$Script:BlenderState.installRoot
                userConfigRoot = [string]$Script:BlenderState.userConfigRoot
                addonLinked = [bool]$Script:BlenderState.addonLinked
                addonLinkType = [string]$Script:BlenderState.addonLinkType
            }
            p4k = [ordered]@{
                status = [string]$Script:P4KState.status
                build = [string]$Script:P4KState.build
                source = [string]$Script:P4KState.source
                destination = [string]$Script:P4KState.destination
                partialDestination = [string]$Script:P4KState.partialDestination
                sizeBytes = [string]$Script:P4KState.sizeBytes
                spaceWarning = [bool]$Script:P4KState.spaceWarning
                readOnly = [bool]$Script:P4KState.readOnly
                skippedReason = [string]$Script:P4KState.skippedReason
                channel = [string]$Script:P4KState.channel
                starCitizenExe = [string]$Script:P4KState.starCitizenExe
                productVersion = [string]$Script:P4KState.productVersion
                fileVersion = [string]$Script:P4KState.fileVersion
            }
            agentGuidance = [ordered]@{
                status = [string]$Script:AgentGuidanceState.status
                reason = [string]$Script:AgentGuidanceState.reason
                promptsRoot = [string]$Script:AgentGuidanceState.promptsRoot
                workRoot = [string]$Script:AgentGuidanceState.workRoot
                outputRoot = [string]$Script:AgentGuidanceState.outputRoot
                reportsRoot = [string]$Script:AgentGuidanceState.reportsRoot
                agentsPath = [string]$Script:AgentGuidanceState.agentsPath
                agentsStatus = [string]$Script:AgentGuidanceState.agentsStatus
                agentsFallbackPath = [string]$Script:AgentGuidanceState.agentsFallbackPath
                claudePath = [string]$Script:AgentGuidanceState.claudePath
                claudeStatus = [string]$Script:AgentGuidanceState.claudeStatus
                claudeFallbackPath = [string]$Script:AgentGuidanceState.claudeFallbackPath
                launcherPath = [string]$Script:AgentGuidanceState.launcherPath
                launcherStatus = [string]$Script:AgentGuidanceState.launcherStatus
            }
            stepTimings = @($stepList.ToArray())
            completedSteps = @($completedList.ToArray())
            skippedSteps = @($skipList.ToArray())
            failedSteps = @($failList.ToArray())
            lastCommandLog = [string]$Script:LastCommandLogPath
            transcriptLog = [string]$Script:TranscriptLogPath
            summaryLog = [string]$SetupSummaryPath
        }
        & $writeState $state
    } catch {
        try {
            $fallback = [ordered]@{
                version = [string]$Script:ScriptVersion
                scriptVersion = [string]$Script:ScriptVersion
                starCitizenTestedBuilds = [string]$Script:StarCitizenTestedBuilds
                lastRun = (Get-Date).ToString('s')
                devRoot = [string]$DevRoot
                warning = 'Reduced setup-state written because full state serialization failed.'
                error = [string]$_.Exception.Message
            }
            & $writeState $fallback
        } catch {
            # State is useful, but it must never make a setup look failed.
            try { Write-Warning "Setup-state save was skipped: $($_.Exception.Message)" } catch { }
        }
    }
}

function Test-WindowsSandbox {
    try {
        $cs = Get-CimInstance Win32_ComputerSystem -ErrorAction Stop
        if (($env:USERNAME -eq 'WDAGUtilityAccount') -or ($cs.Model -match '(?i)Virtual|Sandbox')) { return $true }
    } catch { }
    return $false
}

function Register-SetupCancelHandler {
    try {
        [Console]::CancelKeyPress += {
            param($sender, $eventArgs)
            $eventArgs.Cancel = $true
            $Script:AbortRequested = $true
            try { Write-Host "`nAbort requested. The current operation will stop at its next safe checkpoint." -ForegroundColor Yellow } catch { }
        }
    } catch { }
}

function Get-DriveFreeBytesForPath {
    param([Parameter(Mandatory=$true)][string]$Path)
    try {
        $root = [IO.Path]::GetPathRoot($Path)
        if ([string]::IsNullOrWhiteSpace($root)) { return 0 }
        $drive = New-Object System.IO.DriveInfo($root)
        return [int64]$drive.AvailableFreeSpace
    } catch { return 0 }
}

function Show-DevRootSpaceWarning {
    $free = Get-DriveFreeBytesForPath -Path $DevRoot
    if ($free -le 0) { return }
    $freeText = Format-ByteSize $free
    $minTool = [int64]30GB
    $recTool = [int64]50GB
    $currentP4kWarn = [int64]175GB
    $futureP4kWarn = [int64]275GB
    Write-Host "Drive space check for DevRoot: $DevRoot" -ForegroundColor Cyan
    Write-Host "  Available: $freeText" -ForegroundColor Gray
    if ($free -lt $minTool) {
        Write-Warning "Less than 30 GB is free. Toolchain setup may fail or run out of space."
    } elseif ($free -lt $recTool) {
        Write-Warning "Less than 50 GB is free. Toolchain setup should fit, but there is not much margin."
    }
    if ($free -lt $currentP4kWarn) {
        Write-Warning "This drive may not have enough room for a copied Data.p4k. Current Data.p4k files are around 150 GB."
        $Script:P4KState.spaceWarning = $true
    } elseif ($free -lt $futureP4kWarn) {
        Write-Warning "This drive can likely hold today's Data.p4k, but may not be future-proof for 250 GB post-1.0 files."
        $Script:P4KState.spaceWarning = $true
    }
}

function Test-EnoughSpaceForLargeCopy {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination
    )
    if (-not (Test-Path -LiteralPath $Source)) { throw "Source file not found: $Source" }
    $sourceSize = [int64](Get-Item -LiteralPath $Source).Length
    $buffer = [int64][Math]::Max([double]10GB, [double]$sourceSize * 0.05)
    $required = $sourceSize + $buffer
    $free = Get-DriveFreeBytesForPath -Path $Destination
    $postCopyFree = $free - $sourceSize
    return [pscustomobject]@{
        SourceSize = $sourceSize
        Buffer = $buffer
        RequiredFree = $required
        Free = $free
        PostCopyFree = $postCopyFree
        Enough = ($free -ge $required)
        LowAfterCopy = ($postCopyFree -lt [int64]10GB)
    }
}

function Set-StepCacheMarker {
    param([string]$StepId, [string]$ValidationKey = "")
    if ($DryRun -or $Script:HiddenDryRun -or [string]::IsNullOrWhiteSpace($StepId)) { return }
    try {
        Ensure-Directory $SetupCacheRoot
        $path = Join-Path $SetupCacheRoot ("$StepId.ok")
        $data = [ordered]@{ stepId=$StepId; completedAt=(Get-Date).ToString('s'); validationKey=$ValidationKey; scriptVersion=[string]$Script:ScriptVersion }
        $json = $data | ConvertTo-Json -Depth 4
        $utf8 = New-Object System.Text.UTF8Encoding($false)
        [IO.File]::WriteAllText($path, $json, $utf8)
    } catch { }
}

function Get-CommandText {
    param([string]$Exe, [string[]]$Arguments = @())
    return (Format-CommandDisplay -Exe $Exe -Arguments $Arguments)
}

function Invoke-MonitoredFileOperation {
    param(
        [Parameter(Mandatory=$true)][string]$Operation,
        [string]$Source = "",
        [string]$Destination = "",
        [Parameter(Mandatory=$true)][scriptblock]$ScriptBlock,
        [string]$ActivityNote = ""
    )
    $display = "$Operation"
    if (-not [string]::IsNullOrWhiteSpace($Source)) { $display += " $Source" }
    if (-not [string]::IsNullOrWhiteSpace($Destination)) { $display += " -> $Destination" }
    if ([string]::IsNullOrWhiteSpace($ActivityNote)) { $ActivityNote = "Working on local files. The WATCH lines show changing file/folder size while this operation runs." }
    if ($DryRun) { Write-Host "[dry-run] $display" -ForegroundColor DarkGray; return }

    $commandLog = Get-CommandLogPath -Exe "fileop"
    $Script:LastCommandLogPath = $commandLog
    $Script:LastCommandDisplay = $display
    $Script:LastActivityNote = $ActivityNote
    $Script:ActivityExtraStatusCache = @()
    $Script:ActivityExtraStatusLastRefresh = [datetime]::MinValue
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($commandLog, "COMMAND: $display`r`nSTARTED: $((Get-Date).ToString('s'))`r`n`r`n", $utf8)
    try {
        & $ScriptBlock
        Add-Content -LiteralPath $commandLog -Value "FINISHED: $((Get-Date).ToString('s'))`r`nEXIT CODE: 0" -Encoding UTF8
    } catch {
        Add-Content -LiteralPath $commandLog -Value ("ERROR: " + $_.Exception.Message + "`r`nFINISHED: " + (Get-Date).ToString('s') + "`r`nEXIT CODE: 1") -Encoding UTF8
        throw
    }
}

function Copy-LargeFileWithProgress {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination,
        [string]$ActivityNote = "Copying a large file. This can take a long time; throughput and ETA update every few seconds."
    )
    if (-not (Test-Path -LiteralPath $Source)) { throw "Source file not found: $Source" }
    $sourceItem = Get-Item -LiteralPath $Source
    Ensure-Directory (Split-Path $Destination -Parent)
    $partial = "$Destination.partial"
    if (Test-Path -LiteralPath $partial) {
        $partialSize = (Get-Item -LiteralPath $partial).Length
        Write-Warning "Partial copy found: $partial ($(Format-ByteSize $partialSize))"
        if (-not $AssumeYes) {
            $ans = Read-Host "Delete partial copy and restart? Type D to delete/restart or S to skip"
            if ($ans.Trim() -notmatch '^(d|delete)$') {
                $reason = "Data.p4k copy was skipped because a partial copy already exists."
                $Script:P4KState.status = "SKIPPED"
                $Script:P4KState.skippedReason = $reason
                Set-CurrentSetupStepSkipped -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason $reason
                return $false
            }
        }
        Remove-Item -LiteralPath $partial -Force -ErrorAction SilentlyContinue
    }
    $check = Test-EnoughSpaceForLargeCopy -Source $Source -Destination $Destination
    if (-not $check.Enough) {
        $Script:P4KState.status = "SKIPPED"
        $Script:P4KState.skippedReason = "Insufficient destination drive space."
        Write-Warning "Data.p4k copy skipped because the selected dev drive does not have enough free space."
        Write-Host ("  Source size : {0}" -f (Format-ByteSize $check.SourceSize)) -ForegroundColor Yellow
        Write-Host ("  Available   : {0}" -f (Format-ByteSize $check.Free)) -ForegroundColor Yellow
        Write-Host ("  Required    : {0}" -f (Format-ByteSize $check.RequiredFree)) -ForegroundColor Yellow
        Set-CurrentSetupStepSkipped -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason "Insufficient free space for Data.p4k copy."
        return $false
    }
    if ($check.LowAfterCopy) {
        Write-Warning "The copy can proceed, but free space after copy may be below 10 GB."
    }
    if ($DryRun) { Write-Host "[dry-run] Would copy $Source to $Destination via $partial"; return $true }

    $bufferSize = 4MB
    $buffer = New-Object byte[] $bufferSize
    $total = [int64]$sourceItem.Length
    $readTotal = [int64]0
    $start = Get-Date
    $lastPaint = Get-Date
    $commandLog = Get-CommandLogPath -Exe "DataP4K-copy"
    $Script:LastCommandLogPath = $commandLog
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($commandLog, "COMMAND: Copy Data.p4k`r`nSOURCE: $Source`r`nDESTINATION: $Destination`r`nTEMP: $partial`r`nSTARTED: $((Get-Date).ToString('s'))`r`n", $utf8)
    $in = $null; $out = $null
    try {
        $in = [IO.File]::Open($Source, [IO.FileMode]::Open, [IO.FileAccess]::Read, [IO.FileShare]::Read)
        $out = [IO.File]::Open($partial, [IO.FileMode]::Create, [IO.FileAccess]::Write, [IO.FileShare]::None)
        while (($n = $in.Read($buffer,0,$buffer.Length)) -gt 0) {
            if ($Script:AbortRequested) { throw "Abort requested by user during Data.p4k copy." }
            $out.Write($buffer,0,$n)
            $readTotal += $n
            $now = Get-Date
            if (($now - $lastPaint).TotalSeconds -ge 1) {
                $elapsed = $now - $start
                $rate = if ($elapsed.TotalSeconds -gt 0) { $readTotal / $elapsed.TotalSeconds } else { 0 }
                $remaining = $total - $readTotal
                $eta = if ($rate -gt 0) { [TimeSpan]::FromSeconds($remaining / $rate) } else { [TimeSpan]::Zero }
                $pct = [int][Math]::Floor(($readTotal / [double]$total) * 100)
                $note = "Copying Data.p4k: $(Format-ByteSize $readTotal) / $(Format-ByteSize $total), $pct%, throughput $(Format-ByteSize ([int64]$rate))/s, ETA $($eta.ToString('hh\:mm\:ss'))."
                Write-ActiveCommandDashboard -CommandDisplay "Copy Data.p4k" -LogPath $commandLog -ActivityNote $note -Spinner "|" -Elapsed $elapsed -Status "RUNNING"
                try { Add-Content -LiteralPath $commandLog -Value $note -Encoding UTF8 } catch { }
                $lastPaint = $now
            }
        }
    } finally {
        if ($null -ne $out) { $out.Dispose() }
        if ($null -ne $in) { $in.Dispose() }
    }
    Move-Item -LiteralPath $partial -Destination $Destination -Force
    try { Set-ItemProperty -LiteralPath $Destination -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue } catch { }
    Add-Content -LiteralPath $commandLog -Value "FINISHED: $((Get-Date).ToString('s'))`r`nEXIT CODE: 0" -Encoding UTF8
    return $true
}

function Get-BlenderLatestStableVersion {
    param([string]$Fallback = "5.1.0")
    if (-not [string]::IsNullOrWhiteSpace($BlenderVersion)) { return $BlenderVersion }
    if ($Script:NoNetwork -or (Test-NonLiveInstallerMode)) { return $Fallback }
    try {
        $root = Invoke-WebRequest -Uri "https://download.blender.org/release/" -UseBasicParsing -ErrorAction Stop
        $folders = New-Object 'System.Collections.Generic.List[version]'
        foreach ($m in [regex]::Matches($root.Content, 'Blender(\d+\.\d+)/')) {
            try { [void]$folders.Add([version]$m.Groups[1].Value) } catch { }
        }
        foreach ($folderVersion in ($folders | Sort-Object -Descending | Where-Object { $_.Major -ge 3 })) {
            $folderName = $folderVersion.ToString()
            try {
                $folderUri = "https://download.blender.org/release/Blender$folderName/"
                $page = Invoke-WebRequest -Uri $folderUri -UseBasicParsing -ErrorAction Stop
                $full = New-Object 'System.Collections.Generic.List[version]'
                foreach ($fm in [regex]::Matches($page.Content, 'blender-(\d+\.\d+\.\d+)-windows-x64\.zip')) {
                    try { [void]$full.Add([version]$fm.Groups[1].Value) } catch { }
                }
                $latest = @($full | Sort-Object -Descending | Select-Object -First 1)
                if ($latest.Count -gt 0) { return $latest[0].ToString() }
            } catch { }
        }
    } catch { }
    return $Fallback
}

function Get-BlenderInstallChoices {
    param([string]$Version)
    $choices = New-Object 'System.Collections.Generic.List[object]'
    if (Test-NonLiveInstallerMode) {
        $root = Join-Path $DevRoot "Blender Foundation"
        [void]$choices.Add([pscustomobject]@{ Label=(Join-Path $root "Blender $Version"); Path=(Join-Path $root "Blender $Version"); Available=$true })
        [void]$choices.Add([pscustomobject]@{ Label=(Join-Path $root "Blender $Version Portable"); Path=(Join-Path $root "Blender $Version Portable"); Available=$true })
        return @($choices.ToArray())
    }
    [void]$choices.Add([pscustomobject]@{ Label="C:\Blender Foundation\Blender $Version"; Path="C:\Blender Foundation\Blender $Version"; Available=$true })
    $dAvailable = Test-Path -LiteralPath "D:\"
    [void]$choices.Add([pscustomobject]@{ Label="D:\Blender Foundation\Blender $Version"; Path="D:\Blender Foundation\Blender $Version"; Available=$dAvailable })
    return @($choices.ToArray())
}

function Resolve-BlenderExeFromPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    $clean = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"'))
    if (Test-Path -LiteralPath $clean) {
        $item = Get-Item -LiteralPath $clean -ErrorAction SilentlyContinue
        if ($null -eq $item) { return "" }
        if ($item.PSIsContainer) {
            $candidate = Join-Path $item.FullName "blender.exe"
            if (Test-Path -LiteralPath $candidate) { return (Resolve-Path -LiteralPath $candidate).Path }
        } elseif ($item.Name -ieq "blender.exe") {
            return $item.FullName
        }
    }
    return ""
}

function Test-BlenderExe {
    param([string]$Exe)
    if ([string]::IsNullOrWhiteSpace($Exe) -or -not (Test-Path -LiteralPath $Exe)) { return $false }
    try {
        $out = & $Exe --version 2>$null | Select-Object -First 1
        if ($out -match 'Blender\s+([0-9]+\.[0-9]+(\.[0-9]+)?)') {
            $Script:BlenderState.version = $matches[1]
        }
        return $true
    } catch { return $false }
}

function Find-BlenderInstalls {
    $found = New-Object 'System.Collections.Generic.List[string]'
    try { $cmd = Get-Command blender.exe -ErrorAction SilentlyContinue; if ($cmd) { [void]$found.Add($cmd.Source) } } catch { }
    $common = @(
        "C:\Program Files\Blender Foundation\Blender*\blender.exe",
        "C:\Program Files (x86)\Blender Foundation\Blender*\blender.exe",
        "C:\Blender Foundation\Blender*\blender.exe",
        "D:\Blender Foundation\Blender*\blender.exe",
        (Join-Path $env:LOCALAPPDATA "Programs\Blender*\blender.exe"),
        (Join-Path $DevRoot "Blender Foundation\Blender*\blender.exe")
    )
    foreach ($pattern in $common) {
        try { Get-ChildItem -Path $pattern -ErrorAction SilentlyContinue | ForEach-Object { [void]$found.Add($_.FullName) } } catch { }
    }
    try {
        $uninstallKeys = @(
            'HKLM:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKLM:\Software\WOW6432Node\Microsoft\Windows\CurrentVersion\Uninstall\*',
            'HKCU:\Software\Microsoft\Windows\CurrentVersion\Uninstall\*'
        )
        foreach ($key in $uninstallKeys) {
            Get-ItemProperty -Path $key -ErrorAction SilentlyContinue | Where-Object {
                $displayName = ""
                try { $displayName = [string]$_.DisplayName } catch { $displayName = "" }
                $displayName -match '(?i)Blender'
            } | ForEach-Object {
                $loc = ""
                try { $loc = [string]$_.InstallLocation } catch { $loc = "" }
                $exe = Resolve-BlenderExeFromPath -Path $loc
                if (-not [string]::IsNullOrWhiteSpace($exe)) { [void]$found.Add($exe) }
            }
        }
    } catch { }
    return @($found.ToArray() | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)
}

function Select-OrInstallBlender {
    Write-Step "Locating or installing Blender"
    if ($SkipBlender) {
        $reason = "User skipped Blender setup via -SkipBlender."
        $Script:BlenderState.status = "SKIPPED"
        Set-CurrentSetupStepSkipped -Id "locate-blender" -Name "Locate or install Blender" -Reason $reason
        return
    }
    if (-not [string]::IsNullOrWhiteSpace($BlenderPath)) {
        $exe = Resolve-BlenderExeFromPath -Path $BlenderPath
        if (Test-BlenderExe -Exe $exe) {
            $Script:BlenderState.exe = $exe
            $Script:BlenderState.installRoot = Split-Path $exe -Parent
            $Script:BlenderState.status = "OK"
            Set-UserEnv "SC_BLENDER_EXE" $exe
            Set-UserEnv "SC_BLENDER_VERSION" $Script:BlenderState.version
            return
        }
        Write-Warning "Provided BlenderPath did not validate: $BlenderPath"
    }
    $existing = @(Find-BlenderInstalls)
    if ($existing.Count -gt 0) {
        $chosen = $existing[0]
        if ($existing.Count -gt 1 -and -not $AssumeYes -and -not $Script:VisualPreviewMode) {
            Write-Host "Multiple Blender installs were found:" -ForegroundColor Cyan
            for ($i=0; $i -lt $existing.Count; $i++) { Write-Host ("  {0}) {1}" -f ($i+1), $existing[$i]) }
            Write-Host "  C) Custom path"
            Write-Host "  S) Skip"
            $ans = Read-Host "Choose Blender install"
            if ($ans.Trim() -match '^[Ss]$') {
                $Script:BlenderState.status = "SKIPPED"
                Set-CurrentSetupStepSkipped -Id "locate-blender" -Name "Locate or install Blender" -Reason "User skipped Blender setup."
                return
            }
            if ($ans.Trim() -match '^[Cc]$') { $chosen = Resolve-BlenderExeFromPath -Path (Read-Host "Enter blender.exe path") }
            elseif ($ans.Trim() -match '^\d+$') { $idx = [int]$ans - 1; if ($idx -ge 0 -and $idx -lt $existing.Count) { $chosen = $existing[$idx] } }
        }
        if (Test-BlenderExe -Exe $chosen) {
            $Script:BlenderState.exe = $chosen
            $Script:BlenderState.installRoot = Split-Path $chosen -Parent
            $Script:BlenderState.status = "OK"
            Set-UserEnv "SC_BLENDER_EXE" $chosen
            Set-UserEnv "SC_BLENDER_VERSION" $Script:BlenderState.version
            return
        }
    }
    if ($Script:VisualPreviewMode) {
        $v = Get-BlenderLatestStableVersion
        Write-Host "VISUAL PREVIEW MODE ACTIVE" -ForegroundColor Magenta
        Write-Host "Would offer Blender install locations:" -ForegroundColor Cyan
        foreach ($c in (Get-BlenderInstallChoices -Version $v)) { Write-Host ("  - {0}" -f $c.Label) }
        $Script:BlenderState.status = "Preview"
        return
    }
    if (-not $PromptForBlender -and $AssumeYes) {
        Write-Warning "Blender was not found. Use -PromptForBlender or -BlenderPath to configure it."
        $Script:BlenderState.status = "SKIPPED"
        Set-CurrentSetupStepSkipped -Id "locate-blender" -Name "Locate or install Blender" -Reason "Blender executable was not selected and prompting was disabled."
        return
    }
    Write-Host "Do you already have Blender installed?" -ForegroundColor Cyan
    Write-Host "  Y = yes, enter/find Blender"
    Write-Host "  N = no, install Blender"
    Write-Host "  S = skip Blender setup for now"
    $answer = Read-Host "Blender setup choice"
    if ($answer.Trim() -match '^[Ss]$') {
        $Script:BlenderState.status = "SKIPPED"
        Set-CurrentSetupStepSkipped -Id "locate-blender" -Name "Locate or install Blender" -Reason "User skipped Blender setup."
        return
    }
    if ($answer.Trim() -match '^[Yy]$') {
        $custom = Resolve-BlenderExeFromPath -Path (Read-Host "Enter blender.exe path or Blender folder")
        if (Test-BlenderExe -Exe $custom) {
            $Script:BlenderState.exe = $custom
            $Script:BlenderState.installRoot = Split-Path $custom -Parent
            $Script:BlenderState.status = "OK"
            Set-UserEnv "SC_BLENDER_EXE" $custom
            Set-UserEnv "SC_BLENDER_VERSION" $Script:BlenderState.version
            return
        }
        throw "Blender path did not validate."
    }
    $version = Get-BlenderLatestStableVersion
    $choices = @(Get-BlenderInstallChoices -Version $version)
    Write-Host "Choose Blender install location:" -ForegroundColor Cyan
    for ($i=0; $i -lt $choices.Count; $i++) {
        $suffix = if ($choices[$i].Available) { "" } else { " [drive not found]" }
        Write-Host ("  {0}) {1}{2}" -f ($i+1), $choices[$i].Label, $suffix)
    }
    Write-Host "  C) Custom path"
    Write-Host "  S) Skip"
    $choice = Read-Host "Install location"
    if ($choice.Trim() -match '^[Ss]$') {
        $Script:BlenderState.status = "SKIPPED"
        Set-CurrentSetupStepSkipped -Id "locate-blender" -Name "Locate or install Blender" -Reason "User skipped Blender install."
        return
    }
    $installDir = ""
    if ($choice.Trim() -match '^[Cc]$') { $installDir = Read-Host "Enter install folder, example C:\Blender Foundation\Blender $version" }
    elseif ($choice.Trim() -match '^\d+$') { $idx = [int]$choice - 1; if ($idx -ge 0 -and $idx -lt $choices.Count) { $installDir = $choices[$idx].Path } }
    if ([string]::IsNullOrWhiteSpace($installDir)) { throw "No Blender install folder selected." }
    # Install from official archive index when possible.
    $majorMinor = if ($version -match '^(\d+\.\d+)') { $matches[1] } else { $version }
    $fileName = "blender-$version-windows-x64.zip"
    $uri = "https://download.blender.org/release/Blender$majorMinor/$fileName"
    $zip = Join-Path $InstallersRoot $fileName
    Download-File -Uri $uri -OutFile $zip
    $tempExtract = Join-Path $InstallersRoot ("blender-extract-" + [guid]::NewGuid().ToString('N'))
    $extractScript = Join-Path $InstallersRoot ("extract-blender-" + [guid]::NewGuid().ToString('N') + ".ps1")
    Ensure-Directory $InstallersRoot
    Ensure-Directory (Split-Path $installDir -Parent)
    $Script:FileOpWatchPaths = @(
        [pscustomobject]@{ Label = "archive"; Path = $zip },
        [pscustomobject]@{ Label = "extract temp"; Path = $tempExtract },
        [pscustomobject]@{ Label = "install target"; Path = $installDir }
    )
    $zipLiteral = $zip -replace "'", "''"
    $installDirLiteral = $installDir -replace "'", "''"
    $tempExtractLiteral = $tempExtract -replace "'", "''"
    $extractCode = @"
`$ErrorActionPreference = 'Stop'
`$zip = '$zipLiteral'
`$installDir = '$installDirLiteral'
`$tempExtract = '$tempExtractLiteral'
if (Test-Path -LiteralPath `$installDir) { Remove-Item -LiteralPath `$installDir -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path (Split-Path `$installDir -Parent) | Out-Null
if (Test-Path -LiteralPath `$tempExtract) { Remove-Item -LiteralPath `$tempExtract -Recurse -Force -ErrorAction SilentlyContinue }
New-Item -ItemType Directory -Force -Path `$tempExtract | Out-Null
Expand-Archive -LiteralPath `$zip -DestinationPath `$tempExtract -Force
`$folder = Get-ChildItem -LiteralPath `$tempExtract -Directory | Select-Object -First 1
if (`$null -eq `$folder) { throw 'Blender archive extraction did not produce a folder.' }
Move-Item -LiteralPath `$folder.FullName -Destination `$installDir -Force
Remove-Item -LiteralPath `$tempExtract -Recurse -Force -ErrorAction SilentlyContinue
"@
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($extractScript, $extractCode, $utf8)
    try {
        Run-Native -Exe "powershell.exe" -Arguments @("-NoProfile","-ExecutionPolicy","Bypass","-File",$extractScript) -ActivityNote "Extracting Blender archive into the selected Blender Foundation folder. The WATCH lines show archive, temp, and install target activity."
    } finally {
        $Script:FileOpWatchPaths = @()
        Remove-Item -LiteralPath $extractScript -Force -ErrorAction SilentlyContinue
        Remove-Item -LiteralPath $tempExtract -Recurse -Force -ErrorAction SilentlyContinue
    }
    $exe = Join-Path $installDir "blender.exe"
    if (-not (Test-BlenderExe -Exe $exe)) { throw "Installed Blender did not validate: $exe" }
    $Script:BlenderState.exe = $exe
    $Script:BlenderState.installRoot = $installDir
    $Script:BlenderState.status = "OK"
    Set-UserEnv "SC_BLENDER_EXE" $exe
    Set-UserEnv "SC_BLENDER_VERSION" $Script:BlenderState.version
}

function Test-StarCitizenProcessesClear {
    $patterns = @('StarCitizen','RSI Launcher','RSILauncher','RSI')
    try {
        $running = @(Get-Process -ErrorAction SilentlyContinue | Where-Object {
            $n = $_.ProcessName
            ($n -match '(?i)StarCitizen') -or ($n -match '(?i)RSI')
        })
        return @($running)
    } catch { return @() }
}

function Get-StarCitizenBuildInfoFromDataP4kPath {
    param([string]$DataP4kPath)
    $channelRoot = Split-Path $DataP4kPath -Parent
    $channel = Split-Path $channelRoot -Leaf
    $channelUpper = $channel.ToUpperInvariant()
    $exe = Join-Path $channelRoot "Bin64\StarCitizen.exe"
    $version = ""; $build = ""; $label = ""
    $raw = ""
    $productVersion = ""
    $fileVersion = ""
    $fileDescription = ""
    $productName = ""

    if (Test-Path -LiteralPath $exe) {
        try {
            $info = [Diagnostics.FileVersionInfo]::GetVersionInfo($exe)
            $productVersion = [string]$info.ProductVersion
            $fileVersion = [string]$info.FileVersion
            $fileDescription = [string]$info.FileDescription
            $productName = [string]$info.ProductName
            $rawParts = @(
                $info.ProductVersion,
                $info.FileVersion,
                $info.FileDescription,
                $info.ProductName,
                $info.Comments,
                $info.OriginalFilename
            ) | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) }
            $raw = ($rawParts -join " ")

            try {
                if ([string]::IsNullOrWhiteSpace($version) -and $info.FileMajorPart -gt 0 -and $info.FilePrivatePart -gt 9999) {
                    $version = "{0}.{1}.{2}" -f $info.FileMajorPart, $info.FileMinorPart, $info.FileBuildPart
                    $build = [string]$info.FilePrivatePart
                }
            } catch { }

            try {
                if ([string]::IsNullOrWhiteSpace($version) -and $info.ProductMajorPart -gt 0 -and $info.ProductPrivatePart -gt 9999) {
                    $version = "{0}.{1}.{2}" -f $info.ProductMajorPart, $info.ProductMinorPart, $info.ProductBuildPart
                    $build = [string]$info.ProductPrivatePart
                }
            } catch { }

            # Common useful forms include "4.4.1.9457020", "4.4.1-LIVE-9457020",
            # or file/product text that contains a semantic game version plus a 6+ digit build.
            if ($raw -match '(?<!\d)(\d+\.\d+\.\d+)[\.-](\d{6,})(?!\d)') {
                $version = $matches[1]
                $build = $matches[2]
            }
            if ([string]::IsNullOrWhiteSpace($version) -and $raw -match '(?<!\d)(\d+\.\d+\.\d+)(?!\d)') {
                $version = $matches[1]
            }
            if ([string]::IsNullOrWhiteSpace($build) -and $raw -match '(?<!\d)(\d{6,})(?!\d)') {
                $build = $matches[1]
            }
        } catch { }
    }

    # Conservative fallback: inspect small text/manifest-style files near the channel root.
    # This is only used to improve detection; if still uncertain, v17 prompts the user instead of inventing LIVE-unknown.
    if (([string]::IsNullOrWhiteSpace($version) -or [string]::IsNullOrWhiteSpace($build)) -and (Test-Path -LiteralPath $channelRoot)) {
        try {
            $smallFiles = @(Get-ChildItem -LiteralPath $channelRoot -File -ErrorAction SilentlyContinue |
                Where-Object { $_.Length -lt 5MB -and $_.Extension -match '(?i)^\.(txt|json|xml|ini|cfg|manifest|id|version)$' } |
                Select-Object -First 20)
            foreach ($f in $smallFiles) {
                try {
                    $txt = [IO.File]::ReadAllText($f.FullName)
                    if ([string]::IsNullOrWhiteSpace($version) -and $txt -match '(?<!\d)(\d+\.\d+\.\d+)(?!\d)') { $version = $matches[1] }
                    if ([string]::IsNullOrWhiteSpace($build) -and $txt -match '(?<!\d)(\d{6,})(?!\d)') { $build = $matches[1] }
                    if (-not [string]::IsNullOrWhiteSpace($version) -and -not [string]::IsNullOrWhiteSpace($build)) { break }
                } catch { }
            }
        } catch { }
    }

    if (-not [string]::IsNullOrWhiteSpace($P4KBuildLabel)) {
        $label = $P4KBuildLabel
    } elseif (-not [string]::IsNullOrWhiteSpace($version) -and -not [string]::IsNullOrWhiteSpace($build)) {
        $label = "$version-$channelUpper-$build"
    } else {
        # Important v17 behavior: leave blank if uncertain. Do not create LIVE-unknown automatically.
        $label = ""
    }

    return [pscustomobject]@{
        Channel=$channelUpper
        Version=$version
        Build=$build
        Label=$label
        Exe=$exe
        ChannelRoot=$channelRoot
        ProductVersion=$productVersion
        FileVersion=$fileVersion
        FileDescription=$fileDescription
        ProductName=$productName
        RawVersionText=$raw
    }
}

function Show-StarCitizenBuildDetection {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [object]$DetectedInfo = $null,
        [string]$ProposedLabel = ""
    )

    Write-Host "" -ForegroundColor Cyan
    Write-Host "Detected installed Star Citizen build metadata:" -ForegroundColor Cyan
    Write-Host "  Data.p4k source: $Source" -ForegroundColor DarkCyan

    if ($null -eq $DetectedInfo) {
        Write-Host "  StarCitizen.exe ProductVersion: not available" -ForegroundColor DarkYellow
        Write-Host "  StarCitizen.exe FileVersion   : not available" -ForegroundColor DarkYellow
        Write-Host "  Detected channel              : not available" -ForegroundColor DarkYellow
        if (-not [string]::IsNullOrWhiteSpace($ProposedLabel)) {
            Write-Host "  Proposed build label          : $ProposedLabel" -ForegroundColor Yellow
        }
        return
    }

    $pv = if ([string]::IsNullOrWhiteSpace([string]$DetectedInfo.ProductVersion)) { "not available" } else { [string]$DetectedInfo.ProductVersion }
    $fv = if ([string]::IsNullOrWhiteSpace([string]$DetectedInfo.FileVersion)) { "not available" } else { [string]$DetectedInfo.FileVersion }
    $channel = if ([string]::IsNullOrWhiteSpace([string]$DetectedInfo.Channel)) { "not available" } else { [string]$DetectedInfo.Channel }
    $exe = if ([string]::IsNullOrWhiteSpace([string]$DetectedInfo.Exe)) { "not available" } else { [string]$DetectedInfo.Exe }
    if ([string]::IsNullOrWhiteSpace($ProposedLabel) -and -not [string]::IsNullOrWhiteSpace([string]$DetectedInfo.Label)) {
        $ProposedLabel = [string]$DetectedInfo.Label
    }
    if ([string]::IsNullOrWhiteSpace($ProposedLabel)) { $ProposedLabel = "not confidently detected" }

    Write-Host "  StarCitizen.exe path          : $exe" -ForegroundColor DarkGray
    Write-Host "  StarCitizen.exe ProductVersion: $pv" -ForegroundColor DarkCyan
    Write-Host "  StarCitizen.exe FileVersion   : $fv" -ForegroundColor DarkCyan
    Write-Host "  Detected channel              : $channel" -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace([string]$DetectedInfo.Version)) { Write-Host "  Detected game version         : $($DetectedInfo.Version)" -ForegroundColor Cyan }
    if (-not [string]::IsNullOrWhiteSpace([string]$DetectedInfo.Build)) { Write-Host "  Detected build number         : $($DetectedInfo.Build)" -ForegroundColor Cyan }
    Write-Host "  Proposed build label          : $ProposedLabel" -ForegroundColor Yellow
}

function Read-ManualDataP4kBuildLabel {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [object]$DetectedInfo = $null,
        [string]$Reason = ""
    )

    Write-Host "" -ForegroundColor Cyan
    if (-not [string]::IsNullOrWhiteSpace($Reason)) { Write-Host $Reason -ForegroundColor Yellow }
    Write-Host "Enter the exact Star Citizen build label for this Data.p4k, or type S to skip." -ForegroundColor Yellow
    Write-Host "Example: 4.4.1-LIVE-9457020" -ForegroundColor Gray
    if ($null -ne $DetectedInfo) {
        if (-not [string]::IsNullOrWhiteSpace([string]$DetectedInfo.Channel)) { Write-Host "Detected channel: $($DetectedInfo.Channel)" -ForegroundColor DarkCyan }
        if (-not [string]::IsNullOrWhiteSpace([string]$DetectedInfo.ProductVersion)) { Write-Host "StarCitizen.exe ProductVersion: $($DetectedInfo.ProductVersion)" -ForegroundColor DarkCyan }
        if (-not [string]::IsNullOrWhiteSpace([string]$DetectedInfo.FileVersion)) { Write-Host "StarCitizen.exe FileVersion   : $($DetectedInfo.FileVersion)" -ForegroundColor DarkCyan }
    }
    Write-Host "Source:" -ForegroundColor DarkCyan
    Write-Host "  $Source" -ForegroundColor DarkCyan
    $customLabel = Read-Host "Star Citizen build label"
    if ($customLabel.Trim() -match '^[Ss]$') { return "" }
    return $customLabel.Trim()
}

function Confirm-InstalledDataP4kBuildLabel {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)]$DetectedInfo,
        [string]$CurrentLabel = ""
    )

    if (-not [string]::IsNullOrWhiteSpace($P4KBuildLabel)) {
        Show-StarCitizenBuildDetection -Source $Source -DetectedInfo $DetectedInfo -ProposedLabel $P4KBuildLabel
        Write-Host "Using -P4KBuildLabel override: $P4KBuildLabel" -ForegroundColor Yellow
        return $P4KBuildLabel.Trim()
    }

    $proposed = $CurrentLabel
    if ([string]::IsNullOrWhiteSpace($proposed) -and $null -ne $DetectedInfo -and -not [string]::IsNullOrWhiteSpace([string]$DetectedInfo.Label)) {
        $proposed = [string]$DetectedInfo.Label
    }

    Show-StarCitizenBuildDetection -Source $Source -DetectedInfo $DetectedInfo -ProposedLabel $proposed

    if (-not [string]::IsNullOrWhiteSpace($proposed) -and ($proposed -notmatch '(?i)unknown')) {
        $ans = Read-Host "Use this build label? Y/N/S [Y]"
        if ([string]::IsNullOrWhiteSpace($ans) -or $ans.Trim() -match '^[Yy]') { return $proposed.Trim() }
        if ($ans.Trim() -match '^[Ss]$') { return "" }
        return (Read-ManualDataP4kBuildLabel -Source $Source -DetectedInfo $DetectedInfo -Reason "Manual build label requested.")
    }

    return (Read-ManualDataP4kBuildLabel -Source $Source -DetectedInfo $DetectedInfo -Reason "The build label was not confidently detected from StarCitizen.exe metadata.")
}


function Test-IsInstalledDataP4kCandidate {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return $false }
    $p = $Path.Trim().Trim('"') -replace '/', '\'
    $patterns = @(
        '^[A-Z]:\\Roberts Space Industries\\StarCitizen\\[^\\]+\\Data\.p4k$',
        '^[A-Z]:\\Program Files\\Roberts Space Industries\\StarCitizen\\[^\\]+\\Data\.p4k$',
        '^[A-Z]:\\Program Files \(x86\)\\Roberts Space Industries\\StarCitizen\\[^\\]+\\Data\.p4k$',
        '^[A-Z]:\\Games\\Roberts Space Industries\\StarCitizen\\[^\\]+\\Data\.p4k$',
        '^[A-Z]:\\RSI\\StarCitizen\\[^\\]+\\Data\.p4k$',
        '^[A-Z]:\\StarCitizen\\[^\\]+\\Data\.p4k$'
    )
    foreach ($pattern in $patterns) {
        if ($p -match ('(?i)' + $pattern)) { return $true }
    }
    return $false
}

function Find-InstalledDataP4kFiles {
    # Finds Data.p4k files that look like they belong to an installed Star Citizen build.
    # This intentionally does not return arbitrary loose Data.p4k files from random folders;
    # custom/raw P4K files are handled by option 2, and dev-root copies by option 3.
    if (Test-NonLiveInstallerMode) { return @() }
    $found = New-Object 'System.Collections.Generic.List[string]'
    $seen = @{}

    function Add-P4KCandidateFromPattern {
        param([string]$Pattern)
        try {
            foreach ($item in @(Get-ChildItem -Path $Pattern -File -ErrorAction SilentlyContinue)) {
                if ($null -eq $item) { continue }
                if ($item.Name -ine 'Data.p4k') { continue }
                $full = $item.FullName
                $key = $full.ToLowerInvariant()
                if (-not $seen.ContainsKey($key)) {
                    $seen[$key] = $true
                    [void]$found.Add($full)
                }
            }
        } catch { }
    }

    # Prefer normal Star Citizen install layouts on every fixed drive, including
    # D:\Roberts Space Industries\StarCitizen\LIVE\Data.p4k.
    $drives = @()
    try {
        $drives = @(Get-CimInstance Win32_LogicalDisk -ErrorAction SilentlyContinue |
            Where-Object { $_.DriveType -eq 3 } |
            ForEach-Object { $_.DeviceID })
    } catch { }
    if ($drives.Count -eq 0) {
        try {
            $drives = @(Get-PSDrive -PSProvider FileSystem -ErrorAction SilentlyContinue |
                Where-Object { $_.Root -match '^[A-Z]:\\$' } |
                ForEach-Object { $_.Root.TrimEnd('\\') })
        } catch { }
    }

    foreach ($drive in @($drives | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)) {
        $d = ([string]$drive).TrimEnd('\\')
        Add-P4KCandidateFromPattern (Join-Path $d 'Roberts Space Industries\StarCitizen\*\Data.p4k')
        Add-P4KCandidateFromPattern (Join-Path $d 'Program Files\Roberts Space Industries\StarCitizen\*\Data.p4k')
        Add-P4KCandidateFromPattern (Join-Path $d 'Program Files (x86)\Roberts Space Industries\StarCitizen\*\Data.p4k')
        Add-P4KCandidateFromPattern (Join-Path $d 'Games\Roberts Space Industries\StarCitizen\*\Data.p4k')
        Add-P4KCandidateFromPattern (Join-Path $d 'RSI\StarCitizen\*\Data.p4k')
        Add-P4KCandidateFromPattern (Join-Path $d 'StarCitizen\*\Data.p4k')
    }

    # Also check the most common C/D/E variants explicitly in case a provider/drive
    # query is restricted by policy or a shell host behaves oddly.
    foreach ($p in @(
        'C:\Roberts Space Industries\StarCitizen\*\Data.p4k',
        'D:\Roberts Space Industries\StarCitizen\*\Data.p4k',
        'E:\Roberts Space Industries\StarCitizen\*\Data.p4k',
        'C:\Program Files\Roberts Space Industries\StarCitizen\*\Data.p4k',
        'D:\Program Files\Roberts Space Industries\StarCitizen\*\Data.p4k',
        'E:\Program Files\Roberts Space Industries\StarCitizen\*\Data.p4k',
        'C:\Games\Roberts Space Industries\StarCitizen\*\Data.p4k',
        'D:\Games\Roberts Space Industries\StarCitizen\*\Data.p4k',
        'E:\Games\Roberts Space Industries\StarCitizen\*\Data.p4k'
    )) {
        Add-P4KCandidateFromPattern $p
    }

    # Sort so candidates with a matching Bin64\StarCitizen.exe and newer writes appear first.
    $items = New-Object 'System.Collections.Generic.List[object]'
    foreach ($path in @($found.ToArray())) {
        try {
            $item = Get-Item -LiteralPath $path -ErrorAction Stop
            $channelRoot = Split-Path $path -Parent
            $exe = Join-Path $channelRoot 'Bin64\StarCitizen.exe'
            $hasExe = Test-Path -LiteralPath $exe
            $channel = (Split-Path $channelRoot -Leaf).ToUpperInvariant()
            $rank = 0
            if ($hasExe) { $rank += 100 }
            if ($channel -eq 'LIVE') { $rank += 20 }
            elseif ($channel -eq 'PTU') { $rank += 10 }
            [void]$items.Add([pscustomobject]@{
                Path = $path
                Rank = $rank
                LastWriteTime = $item.LastWriteTime
                Size = [int64]$item.Length
            })
        } catch { }
    }

    return @($items |
        Sort-Object @{Expression='Rank';Descending=$true}, @{Expression='LastWriteTime';Descending=$true}, @{Expression='Size';Descending=$true} |
        ForEach-Object { $_.Path })
}

function Format-DataP4kCandidateLine {
    param([string]$Path, [int]$Index = 0)
    $size = "?"
    $modified = "?"
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        $size = Format-ByteSize ([int64]$item.Length)
        $modified = $item.LastWriteTime.ToString('yyyy-MM-dd HH:mm')
    } catch { }
    $info = $null
    try { $info = Get-StarCitizenBuildInfoFromDataP4kPath -DataP4kPath $Path } catch { }
    $label = if ($null -ne $info -and -not [string]::IsNullOrWhiteSpace($info.Label)) { $info.Label } else { "build label not detected" }
    $channel = if ($null -ne $info -and -not [string]::IsNullOrWhiteSpace($info.Channel)) { $info.Channel } else { "channel ?" }
    $pv = if ($null -ne $info -and -not [string]::IsNullOrWhiteSpace($info.ProductVersion)) { $info.ProductVersion } else { "ProductVersion ?" }
    $prefix = if ($Index -gt 0) { ("{0}) " -f $Index) } else { "" }
    return ("{0}{1} | {2} | modified {3} | {4} | proposed {5} | {6}" -f $prefix, $Path, $size, $modified, $channel, $label, $pv)
}

function Read-DataP4kBuildLabel {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [object]$DetectedInfo = $null,
        [switch]$CustomSource
    )

    if (-not [string]::IsNullOrWhiteSpace($P4KBuildLabel)) { return $P4KBuildLabel.Trim() }
    if ($null -ne $DetectedInfo -and -not [string]::IsNullOrWhiteSpace($DetectedInfo.Label)) { return ([string]$DetectedInfo.Label).Trim() }

    Write-Host "" -ForegroundColor Cyan
    if ($CustomSource) {
        Write-Host "This custom Data.p4k source is not from a detected Star Citizen install folder." -ForegroundColor Yellow
    } else {
        Write-Host "The script found a Data.p4k source, but could not confidently detect the exact Star Citizen build label." -ForegroundColor Yellow
    }
    Write-Host "Source:" -ForegroundColor DarkCyan
    Write-Host "  $Source" -ForegroundColor DarkCyan
    if ($null -ne $DetectedInfo) {
        Write-Host ("Detected channel: {0}" -f $DetectedInfo.Channel) -ForegroundColor DarkCyan
        if (-not [string]::IsNullOrWhiteSpace($DetectedInfo.Exe)) { Write-Host ("Version source: {0}" -f $DetectedInfo.Exe) -ForegroundColor DarkGray }
        if (-not [string]::IsNullOrWhiteSpace($DetectedInfo.ProductVersion)) { Write-Host ("StarCitizen.exe ProductVersion: {0}" -f $DetectedInfo.ProductVersion) -ForegroundColor DarkCyan }
        if (-not [string]::IsNullOrWhiteSpace($DetectedInfo.FileVersion)) { Write-Host ("StarCitizen.exe FileVersion   : {0}" -f $DetectedInfo.FileVersion) -ForegroundColor DarkCyan }
        if (-not [string]::IsNullOrWhiteSpace($DetectedInfo.RawVersionText)) { Write-Host ("Raw version text: {0}" -f $DetectedInfo.RawVersionText) -ForegroundColor DarkGray }
    }
    Write-Host "Do not use LIVE-unknown. Enter the exact build label, or type S to skip." -ForegroundColor Yellow
    Write-Host "Example: 4.4.1-LIVE-9457020" -ForegroundColor Gray
    $customLabel = Read-Host "Star Citizen build label"
    if ($customLabel.Trim() -match '^[Ss]$') { return "" }
    return $customLabel.Trim()
}

function Select-OrCopyDataP4k {
    Write-Step "Selecting or copying Data.p4k"
    if ($SkipP4K) {
        $Script:P4KState.status = "SKIPPED"
        $Script:P4KState.skippedReason = "-SkipP4K supplied."
        Set-CurrentSetupStepSkipped -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason "-SkipP4K supplied."
        return
    }

    $source = ""
    $buildLabel = $P4KBuildLabel
    $selectedInstalledInfo = $null
    $sourceIsCustom = $false

    if (-not [string]::IsNullOrWhiteSpace($DataP4kSource)) {
        $source = $DataP4kSource
    } elseif ($Script:VisualPreviewMode) {
        Write-Host "VISUAL PREVIEW MODE ACTIVE" -ForegroundColor Magenta
        Write-Host "Would offer Data.p4k choices: installed Star Citizen build, custom Data.p4k, already-copied dev-root Data.p4k, or skip." -ForegroundColor Cyan
        $Script:P4KState.status = "Preview"
        return
    } elseif ($PromptForP4K) {
        Write-Host "Do you want to set up Data.p4k now?" -ForegroundColor Cyan
        Write-Host "  1 = copy from an installed Star Citizen build"
        Write-Host "  2 = use a custom Data.p4k path"
        Write-Host "  3 = use an already-copied Data.p4k under the dev root"
        Write-Host "  4 = skip for now"
        Write-Host "" -ForegroundColor Cyan
        Write-Host "NOTE: Data.p4k is very large. This step intentionally waits for your choice even when the rest of setup uses AssumeYes." -ForegroundColor Yellow
        $choice = Read-Host "Data.p4k setup choice [1/2/3/4, default 4]"
        if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "4" }

        switch ($choice.Trim()) {
            "1" {
                $candidates = @(Find-InstalledDataP4kFiles)
                if ($candidates.Count -eq 0) {
                    $reason = "No installed Data.p4k was found in common Star Citizen install locations."
                    Write-Warning $reason
                    $Script:P4KState.status = "SKIPPED"
                    $Script:P4KState.skippedReason = $reason
                    Add-SetupSkipRecord -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason $reason
                    $Script:CurrentStepResultStatus = "SKIPPED"
                    $Script:CurrentStepResultReason = $reason
                    return
                }

                Write-Host "Installed Star Citizen Data.p4k candidates:" -ForegroundColor Cyan
                for ($i = 0; $i -lt $candidates.Count; $i++) {
                    Write-Host ("  " + (Format-DataP4kCandidateLine -Path $candidates[$i] -Index ($i + 1)))
                }
                Write-Host "  S) Skip Data.p4k setup for now"
                $ans = Read-Host "Choose installed Data.p4k"
                if ($ans.Trim() -match '^[Ss]$' -or [string]::IsNullOrWhiteSpace($ans)) {
                    $Script:P4KState.status = "SKIPPED"
                    $Script:P4KState.skippedReason = "User skipped installed Data.p4k selection."
                    Add-SetupSkipRecord -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason $Script:P4KState.skippedReason
                    $Script:CurrentStepResultStatus = "SKIPPED"
                    $Script:CurrentStepResultReason = $Script:P4KState.skippedReason
                    return
                }
                if ($ans.Trim() -match '^\d+$') {
                    $idx = [int]$ans - 1
                    if ($idx -ge 0 -and $idx -lt $candidates.Count) { $source = $candidates[$idx] }
                }
                if ([string]::IsNullOrWhiteSpace($source)) { throw "Invalid Data.p4k selection: $ans" }
            }
            "2" {
                $source = Read-Host "Enter path to custom Data.p4k"
                if ([string]::IsNullOrWhiteSpace($source) -or $source.Trim() -match '^[Ss]$') {
                    $Script:P4KState.status = "SKIPPED"
                    $Script:P4KState.skippedReason = "User skipped custom Data.p4k selection."
                    Set-CurrentSetupStepSkipped -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason $Script:P4KState.skippedReason
                    return
                }
                $sourceIsCustom = $true
            }
            "3" {
                $existing = @(Get-ChildItem -Path (Join-Path $ScP4kRoot "*\Data.p4k") -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending)
                if ($existing.Count -eq 0) {
                    $reason = "No already-copied Data.p4k found under $ScP4kRoot"
                    Write-Warning $reason
                    $Script:P4KState.status = "SKIPPED"
                    $Script:P4KState.skippedReason = $reason
                    Add-SetupSkipRecord -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason $reason
                    $Script:CurrentStepResultStatus = "SKIPPED"
                    $Script:CurrentStepResultReason = $reason
                    return
                }
                Write-Host "Already-copied dev-root Data.p4k files:" -ForegroundColor Cyan
                for ($i = 0; $i -lt $existing.Count; $i++) {
                    Write-Host ("  {0}) {1} ({2})" -f ($i+1), $existing[$i].FullName, (Format-ByteSize $existing[$i].Length))
                }
                Write-Host "  S) Skip Data.p4k setup for now"
                $ans = Read-Host "Choose already-copied Data.p4k"
                if ($ans.Trim() -match '^[Ss]$' -or [string]::IsNullOrWhiteSpace($ans)) {
                    $Script:P4KState.status = "SKIPPED"
                    $Script:P4KState.skippedReason = "User skipped already-copied Data.p4k selection."
                    Add-SetupSkipRecord -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason $Script:P4KState.skippedReason
                    $Script:CurrentStepResultStatus = "SKIPPED"
                    $Script:CurrentStepResultReason = $Script:P4KState.skippedReason
                    return
                }
                if ($ans.Trim() -match '^\d+$') {
                    $idx = [int]$ans - 1
                    if ($idx -ge 0 -and $idx -lt $existing.Count) {
                        $source = $existing[$idx].FullName
                        $buildLabel = Split-Path (Split-Path $source -Parent) -Leaf
                    }
                }
                if ([string]::IsNullOrWhiteSpace($source)) { throw "Invalid already-copied Data.p4k selection: $ans" }
                if ($buildLabel -match '(?i)unknown') {
                    $manual = Read-DataP4kBuildLabel -Source $source -CustomSource
                    if ([string]::IsNullOrWhiteSpace($manual)) {
                        $Script:P4KState.status = "SKIPPED"
                        $Script:P4KState.skippedReason = "User skipped because the already-copied Data.p4k build label was unknown."
                        Add-SetupSkipRecord -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason $Script:P4KState.skippedReason
                        $Script:CurrentStepResultStatus = "SKIPPED"
                        $Script:CurrentStepResultReason = $Script:P4KState.skippedReason
                        return
                    }
                    $newDir = Join-Path $ScP4kRoot $manual
                    $newPath = Join-Path $newDir "Data.p4k"
                    if ($newPath -ne $source) {
                        Write-Host "The selected file is in an unknown-label folder." -ForegroundColor Yellow
                        Write-Host "  Current : $source" -ForegroundColor DarkYellow
                        Write-Host "  Correct : $newPath" -ForegroundColor DarkYellow
                        $moveAns = Read-Host "Move it into the corrected build-label folder? Y/N"
                        if ($moveAns.Trim() -match '^[Yy]$') {
                            if (Test-Path -LiteralPath $newPath) {
                                Write-Warning "Corrected destination already exists. Using existing selected path instead of moving."
                            } else {
                                Ensure-Directory $newDir
                                Move-Item -LiteralPath $source -Destination $newPath -Force
                                try {
                                    $oldDir = Split-Path $source -Parent
                                    if ((Get-ChildItem -LiteralPath $oldDir -Force -ErrorAction SilentlyContinue | Measure-Object).Count -eq 0) {
                                        Remove-Item -LiteralPath $oldDir -Force -ErrorAction SilentlyContinue
                                    }
                                } catch { }
                                $source = $newPath
                            }
                        }
                    }
                    $buildLabel = $manual
                }
                $Script:P4KState.destination = $source
                $Script:P4KState.build = $buildLabel
                $Script:P4KState.status = "OK"
                Set-UserEnv "SC_BUILD" $buildLabel
                Set-UserEnv "SC_DATA_P4K" $source
                return
            }
            default {
                $Script:P4KState.status = "SKIPPED"
                $Script:P4KState.skippedReason = "User skipped Data.p4k setup."
                Add-SetupSkipRecord -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason "User skipped Data.p4k setup."
                $Script:CurrentStepResultStatus = "SKIPPED"
                $Script:CurrentStepResultReason = "User skipped Data.p4k setup."
                return
            }
        }
    } else {
        # Non-prompt path: only proceed with explicit source arguments or already selected environment.
        $existingEnv = [Environment]::GetEnvironmentVariable("SC_DATA_P4K", "User")
        if (-not [string]::IsNullOrWhiteSpace($existingEnv) -and (Test-Path -LiteralPath $existingEnv)) {
            $source = $existingEnv
            $buildLabel = [Environment]::GetEnvironmentVariable("SC_BUILD", "User")
            $Script:P4KState.destination = $source
            $Script:P4KState.build = $buildLabel
            $Script:P4KState.status = "OK"
            Write-Host "Using existing SC_DATA_P4K environment path:" -ForegroundColor Green
            Write-Host "  $source" -ForegroundColor Green
            return
        }
        $reason = "Data.p4k setup was not prompted and no explicit Data.p4k source was supplied."
        Write-Warning $reason
        $Script:P4KState.status = "SKIPPED"
        $Script:P4KState.skippedReason = $reason
        Add-SetupSkipRecord -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason $reason
        $Script:CurrentStepResultStatus = "SKIPPED"
        $Script:CurrentStepResultReason = $reason
        return
    }

    if ([string]::IsNullOrWhiteSpace($source) -or -not (Test-Path -LiteralPath $source)) { throw "Data.p4k source was not found: $source" }
    $source = (Resolve-Path -LiteralPath $source).Path
    if ([IO.Path]::GetFileName($source) -ine "Data.p4k") { throw "Selected file is not named Data.p4k: $source" }

    $looksInstalled = ($source -match '(?i)\\Roberts Space Industries\\StarCitizen\\[^\\]+\\Data\.p4k$')
    if ($looksInstalled) {
        $running = @(Test-StarCitizenProcessesClear)
        while ($running.Count -gt 0) {
            Write-Warning "Star Citizen or RSI Launcher appears to be running. Close it before copying Data.p4k."
            foreach ($p in $running) { Write-Host ("  Running: {0} ({1})" -f $p.ProcessName, $p.Id) -ForegroundColor DarkYellow }
            $ans = Read-Host "Press Enter to recheck, or S to skip"
            if ($ans.Trim() -match '^[Ss]$') {
                $Script:P4KState.status = "SKIPPED"
                $Script:P4KState.skippedReason = "User skipped because Star Citizen/RSI processes were running."
                Add-SetupSkipRecord -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason $Script:P4KState.skippedReason
                $Script:CurrentStepResultStatus = "SKIPPED"
                $Script:CurrentStepResultReason = $Script:P4KState.skippedReason
                return
            }
            $running = @(Test-StarCitizenProcessesClear)
        }
        $selectedInstalledInfo = Get-StarCitizenBuildInfoFromDataP4kPath -DataP4kPath $source
        try {
            $Script:P4KState.channel = [string]$selectedInstalledInfo.Channel
            $Script:P4KState.starCitizenExe = [string]$selectedInstalledInfo.Exe
            $Script:P4KState.productVersion = [string]$selectedInstalledInfo.ProductVersion
            $Script:P4KState.fileVersion = [string]$selectedInstalledInfo.FileVersion
        } catch { }
        $buildLabel = Confirm-InstalledDataP4kBuildLabel -Source $source -DetectedInfo $selectedInstalledInfo -CurrentLabel $buildLabel
    } else {
        if ([string]::IsNullOrWhiteSpace($buildLabel)) { $buildLabel = Read-DataP4kBuildLabel -Source $source -CustomSource }
    }

    if ([string]::IsNullOrWhiteSpace($buildLabel)) {
        $reason = "Data.p4k setup skipped because no build label was provided."
        Write-Warning $reason
        $Script:P4KState.status = "SKIPPED"
        $Script:P4KState.skippedReason = $reason
        Add-SetupSkipRecord -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason $reason
        $Script:CurrentStepResultStatus = "SKIPPED"
        $Script:CurrentStepResultReason = $reason
        return
    }
    if ($buildLabel -match '(?i)unknown') {
        $reason = "Data.p4k setup skipped because the build label is still unknown: $buildLabel"
        Write-Warning $reason
        $Script:P4KState.status = "SKIPPED"
        $Script:P4KState.skippedReason = $reason
        Add-SetupSkipRecord -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason $reason
        $Script:CurrentStepResultStatus = "SKIPPED"
        $Script:CurrentStepResultReason = $reason
        return
    }

    $targetDir = Join-Path $ScP4kRoot $buildLabel
    $target = Join-Path $targetDir "Data.p4k"
    $Script:P4KState.source = $source
    $Script:P4KState.destination = $target
    $Script:P4KState.partialDestination = "$target.partial"
    $Script:P4KState.build = $buildLabel
    $Script:P4KState.sizeBytes = [int64](Get-Item -LiteralPath $source).Length

    if ((Test-Path -LiteralPath $target) -and ((Get-Item -LiteralPath $target).Length -eq (Get-Item -LiteralPath $source).Length)) {
        Write-Host "Data.p4k already exists at destination with matching size. Using existing file." -ForegroundColor Green
        $Script:P4KState.status = "OK"
    } else {
        Write-Host "" -ForegroundColor Cyan
        Write-Host "Ready to copy Data.p4k:" -ForegroundColor Cyan
        Write-Host "  Source:      $source"
        Write-Host "  Destination: $target"
        Write-Host "  Build label: $buildLabel"
        Write-Host ("  Size:        {0}" -f (Format-ByteSize $Script:P4KState.sizeBytes))
        try {
            $spacePreview = Test-EnoughSpaceForLargeCopy -Source $source -Destination $target
            Write-Host ("  Available:   {0}" -f (Format-ByteSize $spacePreview.Free)) -ForegroundColor DarkCyan
            Write-Host ("  Required:    {0}" -f (Format-ByteSize $spacePreview.RequiredFree)) -ForegroundColor DarkCyan
            if (-not $spacePreview.Enough) { Write-Warning "Destination drive does not have enough space; the copy will be skipped safely." }
            elseif ($spacePreview.LowAfterCopy) { Write-Warning "The copy can proceed, but free space after copy may be below 10 GB." }
        } catch { }
        $confirm = Read-Host "Copy Data.p4k now? Y/N"
        if ($confirm.Trim() -notmatch '^[Yy]$') {
            $reason = "User declined Data.p4k copy."
            $Script:P4KState.status = "SKIPPED"
            $Script:P4KState.skippedReason = $reason
            Add-SetupSkipRecord -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason $reason
            $Script:CurrentStepResultStatus = "SKIPPED"
            $Script:CurrentStepResultReason = $reason
            return
        }
        $copied = Copy-LargeFileWithProgress -Source $source -Destination $target
        if (-not $copied) { return }
        $Script:P4KState.status = "OK"
    }

    Set-UserEnv "SC_BUILD" $buildLabel
    Set-UserEnv "SC_DATA_P4K" $target
    try { Set-ItemProperty -LiteralPath $target -Name IsReadOnly -Value $true -ErrorAction SilentlyContinue; $Script:P4KState.readOnly = $true } catch { }
}

function Verify-StarCitizenBuildEnvironment {
    Write-Step "Verifying Star Citizen build environment"
    $p = $Script:P4KState.destination
    if ([string]::IsNullOrWhiteSpace($p)) { $p = [Environment]::GetEnvironmentVariable("SC_DATA_P4K", "User") }
    if ([string]::IsNullOrWhiteSpace($p) -or -not (Test-Path -LiteralPath $p)) {
        $reason = "No Data.p4k selected."
        Add-SetupSkipRecord -Id "verify-sc-build" -Name "Verify Star Citizen build environment" -Reason $reason
        $Script:P4KState.status = if ([string]::IsNullOrWhiteSpace($Script:P4KState.status)) { "SKIPPED" } else { $Script:P4KState.status }
        $Script:CurrentStepResultStatus = "SKIPPED"
        $Script:CurrentStepResultReason = $reason
        return
    }
    Write-Host "Data.p4k verified: $p" -ForegroundColor Green
}

function Invoke-TemporaryPowerShellCommand {
    param(
        [Parameter(Mandatory=$true)][string]$ScriptText,
        [string]$ActivityNote = "",
        [string]$WorkingDirectory = ""
    )
    Ensure-Directory $InstallersRoot
    $tmp = Join-Path $InstallersRoot ("sc-zth-command-" + [guid]::NewGuid().ToString('N') + ".ps1")
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($tmp, $ScriptText, $utf8)
    try {
        Run-Native -Exe "powershell.exe" -Arguments @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $tmp) -WorkingDirectory $WorkingDirectory -ActivityNote $ActivityNote
    } finally {
        Remove-Item -LiteralPath $tmp -Force -ErrorAction SilentlyContinue
    }
}


function Explore-P4KPaths {
    Write-Step "Exploring P4K paths"
    $dataP4k = $Script:P4KState.destination
    if ([string]::IsNullOrWhiteSpace($dataP4k) -or -not (Test-Path -LiteralPath $dataP4k)) {
        $reason = "Skipping P4K exploration; no confirmed Data.p4k is available."
        Write-Warning $reason
        Add-SetupSkipRecord -Id "p4k-explore" -Name "Explore P4K paths" -Reason $reason
        $Script:CurrentStepResultStatus = "SKIPPED"
        $Script:CurrentStepResultReason = $reason
        return
    }
    $starBreakerPath = Join-Path $StarCitizenRoot "StarBreaker"
    $starBreakerExe = Join-Path $starBreakerPath "target\release\starbreaker.exe"
    if (-not (Test-Path -LiteralPath $starBreakerExe)) {
        $reason = "Skipping P4K exploration; StarBreaker is not built yet."
        Write-Warning $reason
        Add-SetupSkipRecord -Id "p4k-explore" -Name "Explore P4K paths" -Reason $reason
        $Script:CurrentStepResultStatus = "SKIPPED"
        $Script:CurrentStepResultReason = $reason
        return
    }

    $build = if (-not [string]::IsNullOrWhiteSpace($Script:P4KState.build)) { $Script:P4KState.build } else { $StarCitizenBuild }
    Ensure-Directory $ScWorkRoot

    $spaceshipsLog = Join-Path $ScWorkRoot "spaceships_top_level_$build.txt"
    $makersLog = Join-Path $ScWorkRoot "spaceships_ship_manufacturers_$build.txt"
    $rsiFoldersLog = Join-Path $ScWorkRoot "spaceships_rsi_ship_folders_$build.txt"
    $auroraLog = Join-Path $ScWorkRoot "aurora_rsi_ship_paths_$build.txt"
    $allLog = Join-Path $ScWorkRoot "p4k_spaceships_paths_$build.txt"
    $allRawLog = Join-Path $ScWorkRoot "p4k_spaceships_paths_raw_$build.txt"
    $shipRawLog = Join-Path $ScWorkRoot "p4k_spaceships_ships_raw_$build.txt"
    $rsiRawLog = Join-Path $ScWorkRoot "rsi_ship_paths_raw_$build.txt"

    function Get-DataPathsFromP4kLog {
        param([Parameter(Mandatory=$true)][string]$Path)
        $out = New-Object 'System.Collections.Generic.List[string]'
        if (-not (Test-Path -LiteralPath $Path)) { return @() }
        foreach ($line in Get-Content -LiteralPath $Path -ErrorAction SilentlyContinue) {
            $text = [string]$line
            if ($text -notmatch '^\s*Data[\\/]') { continue }
            $first = ($text.Trim() -split '\s+')[0]
            if (-not [string]::IsNullOrWhiteSpace($first)) { [void]$out.Add($first) }
        }
        return @($out.ToArray())
    }

    Write-Host "Writing P4K exploration logs under: $ScWorkRoot" -ForegroundColor Cyan
    Write-Host "This step now streams StarBreaker output directly into monitored logs so the dashboard shows activity instead of looking frozen." -ForegroundColor DarkCyan

    $activityAll = "Listing every Data/Objects/Spaceships path from Data.p4k. This can take a while; recent P4K paths should appear in the dashboard as StarBreaker emits them."
    $ec = Invoke-StarBreakerLoggedV23 -Exe $starBreakerExe -Arguments @('p4k','list','--filter','Data/Objects/Spaceships/**','--p4k',$dataP4k) -LogPath $allRawLog -WorkingDirectory $starBreakerPath -ActivityNote $activityAll
    if ($ec -ne 0) { throw "StarBreaker P4K Spaceships listing failed with exit code $ec. See $allRawLog" }
    $allSpaceships = @(Get-DataPathsFromP4kLog -Path $allRawLog)
    $allSpaceships | Set-Content -LiteralPath $allLog -Encoding UTF8
    $allSpaceships |
        ForEach-Object { if ($_ -match '^Data[\\/]+Objects[\\/]+Spaceships[\\/]+([^\\/]+)') { $matches[1] } } |
        Sort-Object -Unique |
        Set-Content -LiteralPath $spaceshipsLog -Encoding UTF8

    $activityShips = "Listing Ships/** manufacturer folders from Data.p4k. The dashboard tails the raw StarBreaker output while the scan runs."
    $ec = Invoke-StarBreakerLoggedV23 -Exe $starBreakerExe -Arguments @('p4k','list','--filter','Data/Objects/Spaceships/Ships/**','--p4k',$dataP4k) -LogPath $shipRawLog -WorkingDirectory $starBreakerPath -ActivityNote $activityShips
    if ($ec -ne 0) { throw "StarBreaker P4K Ships listing failed with exit code $ec. See $shipRawLog" }
    $shipPaths = @(Get-DataPathsFromP4kLog -Path $shipRawLog)
    $shipPaths |
        ForEach-Object { if ($_ -match '^Data[\\/]+Objects[\\/]+Spaceships[\\/]+Ships[\\/]+([^\\/]+)') { $matches[1] } } |
        Sort-Object -Unique |
        Set-Content -LiteralPath $makersLog -Encoding UTF8

    $activityRsi = "Listing RSI ship paths and filtering Aurora entries. This is the last P4K exploration scan before the Aurora loadout/export step."
    $ec = Invoke-StarBreakerLoggedV23 -Exe $starBreakerExe -Arguments @('p4k','list','--filter','Data/Objects/Spaceships/Ships/RSI/**','--p4k',$dataP4k) -LogPath $rsiRawLog -WorkingDirectory $starBreakerPath -ActivityNote $activityRsi
    if ($ec -ne 0) { throw "StarBreaker P4K RSI listing failed with exit code $ec. See $rsiRawLog" }
    $rsiPaths = @(Get-DataPathsFromP4kLog -Path $rsiRawLog)
    $rsiPaths |
        ForEach-Object { if ($_ -match '^Data[\\/]+Objects[\\/]+Spaceships[\\/]+Ships[\\/]+RSI[\\/]+([^\\/]+)') { $matches[1] } } |
        Sort-Object -Unique |
        Set-Content -LiteralPath $rsiFoldersLog -Encoding UTF8
    $rsiPaths |
        Where-Object { $_ -match 'Aurora' } |
        Set-Content -LiteralPath $auroraLog -Encoding UTF8

    Write-Host "Top-level spaceships log: $spaceshipsLog" -ForegroundColor Green
    Write-Host "Manufacturer log: $makersLog" -ForegroundColor Green
    Write-Host "RSI folder log: $rsiFoldersLog" -ForegroundColor Green
    Write-Host "Aurora path log: $auroraLog" -ForegroundColor Green
    Write-Host "Raw P4K logs: $allRawLog ; $shipRawLog ; $rsiRawLog" -ForegroundColor DarkGreen
}

function Write-VisualPreviewDashboard {
    param(
        [string[]]$HeaderLines,
        [int]$CompletedCount,
        [int]$StepNumber,
        [string]$Status
    )

    try { Clear-Host } catch { }

    $bannerLines = @(Get-ProgressBannerLines -Style $BannerStyle)
    for ($i = 0; $i -lt $HeaderLines.Count; $i++) {
        $color = if ($i -lt $bannerLines.Count) {
            "DarkCyan"
        } elseif ($i -eq $bannerLines.Count) {
            "Cyan"
        } elseif ($i -eq ($bannerLines.Count + 1)) {
            "Gray"
        } else {
            "DarkGray"
        }
        Write-Host (Fit-ConsoleLine $HeaderLines[$i]) -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "VISUAL PREVIEW MODE - no installers, downloads, PATH changes, repo actions, or build actions are executed." -ForegroundColor DarkCyan

    $total = [Math]::Max(1, $Script:SetupSteps.Count)
    $windowHeight = 34
    try { $windowHeight = [Math]::Max(20, $Host.UI.RawUI.WindowSize.Height) } catch { }
    $availableRows = [Math]::Max(8, $windowHeight - $HeaderLines.Count - 5)

    $start = 0
    if ($Script:SetupSteps.Count -gt $availableRows) {
        $center = [Math]::Max(0, $StepNumber - 1)
        $start = [Math]::Max(0, $center - [Math]::Floor($availableRows / 2))
        $start = [Math]::Min($start, $Script:SetupSteps.Count - $availableRows)
    }
    $end = [Math]::Min($Script:SetupSteps.Count - 1, $start + $availableRows - 1)

    if ($start -gt 0) {
        Write-Host (Fit-ConsoleLine ("      ... {0} earlier step(s) ..." -f $start)) -ForegroundColor DarkGray
    }

    for ($i = $start; $i -le $end; $i++) {
        $n = $i + 1
        $name = $Script:SetupSteps[$i].Name

        $render = Get-StepDisplayState -StepId $Script:SetupSteps[$i].Id -StepIndex $i -CompletedCount $CompletedCount -CurrentStepNumber $StepNumber -CurrentStatus $Status -Preview
        $state = $render.State
        $glyph = $render.Glyph
        $color = $render.Color

        $line = (" {0,2}/{1,2} {2} {3} {4}" -f $n, $total, $glyph, $state, $name)
        Write-Host (Fit-ConsoleLine $line) -ForegroundColor $color
    }

    if ($end -lt ($Script:SetupSteps.Count - 1)) {
        $remaining = $Script:SetupSteps.Count - 1 - $end
        Write-Host (Fit-ConsoleLine ("      ... {0} upcoming step(s) ..." -f $remaining)) -ForegroundColor DarkGray
    }
}


function Write-StepWindow {
    param(
        [int]$CompletedCount,
        [int]$StepNumber,
        [string]$Status,
        [int]$MaxRows = 10
    )

    $total = [Math]::Max(1, $Script:SetupSteps.Count)
    $rows = [Math]::Max(4, $MaxRows)
    $start = 0
    if ($Script:SetupSteps.Count -gt $rows) {
        $center = [Math]::Max(0, $StepNumber - 1)
        $start = [Math]::Max(0, $center - [Math]::Floor($rows / 2))
        $start = [Math]::Min($start, $Script:SetupSteps.Count - $rows)
    }
    $end = [Math]::Min($Script:SetupSteps.Count - 1, $start + $rows - 1)

    if ($start -gt 0) {
        Write-Host (Fit-ConsoleLine ("      ... {0} earlier step(s) ..." -f $start)) -ForegroundColor DarkGray
    }

    for ($i = $start; $i -le $end; $i++) {
        $n = $i + 1
        $name = $Script:SetupSteps[$i].Name

        $render = Get-StepDisplayState -StepId $Script:SetupSteps[$i].Id -StepIndex $i -CompletedCount $CompletedCount -CurrentStepNumber $StepNumber -CurrentStatus $Status
        $state = $render.State
        $glyph = $render.Glyph
        $color = $render.Color

        $line = (" {0,2}/{1,2} {2} {3} {4}" -f $n, $total, $glyph, $state, $name)
        Write-Host (Fit-ConsoleLine $line) -ForegroundColor $color
    }

    if ($end -lt ($Script:SetupSteps.Count - 1)) {
        $remaining = $Script:SetupSteps.Count - 1 - $end
        Write-Host (Fit-ConsoleLine ("      ... {0} upcoming step(s) ..." -f $remaining)) -ForegroundColor DarkGray
    }
}

function Write-LiveProgressDashboard {
    param(
        [string[]]$HeaderLines,
        [int]$CompletedCount,
        [int]$StepNumber,
        [string]$Status
    )

    if ($NoProgressHeader) { return }

    try { Clear-Host } catch { }

    $bannerLines = @(Get-ProgressBannerLines -Style $BannerStyle)
    for ($i = 0; $i -lt $HeaderLines.Count; $i++) {
        $color = if ($i -lt $bannerLines.Count) {
            "DarkCyan"
        } elseif ($i -eq $bannerLines.Count) {
            "Cyan"
        } elseif ($i -eq ($bannerLines.Count + 1)) {
            "Gray"
        } else {
            "DarkGray"
        }
        Write-Host (Fit-ConsoleLine $HeaderLines[$i]) -ForegroundColor $color
    }

    Write-Host ""
    Write-Host "LIVE SETUP MODE - installer output is captured to logs; the dashboard redraws at step and command boundaries." -ForegroundColor DarkCyan
    if (-not [string]::IsNullOrWhiteSpace($Script:LastCommandLogPath)) {
        Write-Host (Fit-ConsoleLine ("last command log: {0}" -f $Script:LastCommandLogPath)) -ForegroundColor DarkGray
    }
    Write-Host ""

    $windowHeight = 34
    try { $windowHeight = [Math]::Max(20, $Host.UI.RawUI.WindowSize.Height) } catch { }
    $rows = [Math]::Max(6, $windowHeight - $HeaderLines.Count - 8)
    Write-StepWindow -CompletedCount $CompletedCount -StepNumber $StepNumber -Status $Status -MaxRows $rows
}

function Get-DefaultActivityNote {
    param([string]$Display)

    if ([string]::IsNullOrWhiteSpace($Display)) {
        return "The current command is running. The spinner and elapsed timer mean the process is still alive."
    }

    if ($Display -match '(?i)vs_BuildTools|VisualStudio|Microsoft\.VisualStudio') {
        return @"
Visual Studio Build Tools is usually the longest setup step.
It may be quiet for 20-60+ minutes while Windows downloads, verifies, and installs C++ toolchain packages.
Watch the activity lines above; the spinner and elapsed timer mean the process is still alive.
Do not close this window unless you intentionally want to abort setup.
"@.Trim()
    }
    if ($Display -match '(?i)winget\s+install') {
        return "WinGet is downloading/verifying/installing. It may look quiet between progress updates; the elapsed timer confirms the process is still running."
    }
    if ($Display -match '(?i)cargo\s+build') {
        return "Rust/Cargo builds can be quiet for long stretches while compiling. This is normal."
    }
    if ($Display -match '(?i)npm\s+install') {
        return "npm is downloading packages and may pause while resolving dependencies."
    }
    if ($Display -match '(?i)pip\s+install') {
        return "pip is downloading/installing Python packages. Some packages may take a few minutes."
    }
    if ($Display -match '(?i)code\.cmd.*--install-extension') {
        return "VS Code is installing an extension from the command line. This should usually be quick, but Marketplace/network delays are possible."
    }
    if ($Display -match '(?i)git\s+clone') {
        return "Git is cloning repository data. Network speed controls how long this takes."
    }

    return "This command is running in the background with output captured to the log. The spinner and elapsed timer indicate activity."
}

function Get-LogLastWriteSummary {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) { return "waiting for log output" }
    try {
        $age = (Get-Date) - (Get-Item -LiteralPath $Path).LastWriteTime
        if ($age.TotalSeconds -lt 2) { return "just now" }
        if ($age.TotalMinutes -lt 1) { return ("{0}s ago" -f [int]$age.TotalSeconds) }
        return ("{0}m {1}s ago" -f [int]$age.TotalMinutes, ([int]$age.TotalSeconds % 60))
    } catch {
        return "unknown"
    }
}

function Format-ByteSize {
    param([Nullable[Int64]]$Bytes)
    if ($null -eq $Bytes) { return "unknown" }
    $b = [double]$Bytes
    if ($b -ge 1GB) { return ("{0:N2} GB" -f ($b / 1GB)) }
    if ($b -ge 1MB) { return ("{0:N1} MB" -f ($b / 1MB)) }
    if ($b -ge 1KB) { return ("{0:N0} KB" -f ($b / 1KB)) }
    return ("{0:N0} B" -f $b)
}

function Get-FileSizeSummary {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $item = Get-Item -LiteralPath $Path -ErrorAction Stop
        return ("{0} = {1}" -f $item.Name, (Format-ByteSize $item.Length))
    } catch { return $null }
}

function Get-DirectorySizeApprox {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [int]$MaxFiles = 2500
    )
    if (-not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $count = 0
        [Int64]$sum = 0
        Get-ChildItem -LiteralPath $Path -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First $MaxFiles | ForEach-Object {
            $count++
            $sum += [Int64]$_.Length
        }
        # v12: Stash the raw byte total in a script-scoped variable keyed by
        # the path. Callers that want to do throughput math (delta bytes per
        # delta time) can pull this without doing a second recursive scan.
        # Light-touch: nothing breaks for callers that ignore it.
        if ($null -eq $Script:LastDirectorySizeBytes) { $Script:LastDirectorySizeBytes = @{} }
        $Script:LastDirectorySizeBytes[$Path] = $sum
        $prefix = if ($count -ge $MaxFiles) { ">=" } else { "" }
        return ("{0}{1} across {2} files" -f $prefix, (Format-ByteSize $sum), $count)
    } catch { return $null }
}

function Get-NewestPathSummary {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) { return $null }
    try {
        $newest = Get-ChildItem -LiteralPath $Path -Recurse -ErrorAction SilentlyContinue | Sort-Object LastWriteTime -Descending | Select-Object -First 1
        if ($null -eq $newest) { return "present, no child activity yet" }
        $age = (Get-Date) - $newest.LastWriteTime
        $ageText = if ($age.TotalMinutes -lt 1) { ("{0}s ago" -f [int]$age.TotalSeconds) } else { ("{0}m {1}s ago" -f [int]$age.TotalMinutes, ([int]$age.TotalSeconds % 60)) }
        return ("latest write {0}: {1}" -f $ageText, $newest.Name)
    } catch { return $null }
}

function Get-VSBuildToolsActivitySummary {
    param([string]$LogPath)

    # v11: Refresh interval bumped from 5s to 12s. The VS package cache routinely
    # grows to 30,000-50,000 files during install, and a recursive enumeration
    # (even capped) at 5s intervals was chewing measurable CPU on slower disks.
    # 12s is still frequent enough to feel live while letting the dashboard
    # spinner stay smooth.
    $now = Get-Date
    if ($Script:ActivityExtraStatusCache -and (($now - $Script:ActivityExtraStatusLastRefresh).TotalSeconds -lt 12)) {
        return $Script:ActivityExtraStatusCache
    }

    $lines = New-Object 'System.Collections.Generic.List[string]'

    if (-not [string]::IsNullOrWhiteSpace($LogPath) -and (Test-Path -LiteralPath $LogPath)) {
        try {
            $logItem = Get-Item -LiteralPath $LogPath -ErrorAction Stop
            [void]$lines.Add(("command log size: {0}" -f (Format-ByteSize $logItem.Length)))
        } catch { }
    }

    $bootstrapper = Join-Path $InstallersRoot "vs_BuildTools.exe"
    $bootstrapperSize = Get-FileSizeSummary -Path $bootstrapper
    if ($bootstrapperSize) { [void]$lines.Add(("bootstrapper: {0}" -f $bootstrapperSize)) }

    try {
        $tempCandidate = Get-ChildItem -LiteralPath $env:TEMP -Directory -ErrorAction SilentlyContinue |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName 'vs_bootstrapper_d15') } |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 1
        if ($null -ne $tempCandidate) {
            $tempVs = Join-Path $tempCandidate.FullName 'vs_bootstrapper_d15'
            # v11: MaxFiles 2500 -> 800. Still enough to detect "stuck/empty" vs
            # "actively growing" for the dashboard; the bootstrapper payload
            # rarely exceeds ~500 files anyway.
            $summary = Get-DirectorySizeApprox -Path $tempVs -MaxFiles 800
            $newest = Get-NewestPathSummary -Path $tempVs
            if ($summary) { [void]$lines.Add(("VS temp payload: {0}" -f $summary)) }
            if ($newest) { [void]$lines.Add(("VS temp activity: {0}" -f $newest)) }
        }
    } catch { }

    $packageCache = Join-Path $env:ProgramData 'Microsoft\VisualStudio\Packages'
    if (Test-Path -LiteralPath $packageCache) {
        # v11: MaxFiles 2500 -> 800 for the same reason. The bytes-prefix in
        # Get-DirectorySizeApprox (">=") already signals "sampled, not total"
        # so the user understands they're seeing a floor, not a precise figure.
        $summary = Get-DirectorySizeApprox -Path $packageCache -MaxFiles 800
        $newest = Get-NewestPathSummary -Path $packageCache
        if ($summary) { [void]$lines.Add(("VS package cache: {0}" -f $summary)) }
        if ($newest) { [void]$lines.Add(("VS package cache activity: {0}" -f $newest)) }

        # v12: Throughput line. Get-DirectorySizeApprox just stored the latest
        # byte total for $packageCache in $Script:LastDirectorySizeBytes; pair
        # it with previous samples to compute MB/min over the last ~90 seconds.
        # This is the most concrete proof of life for users watching the GUI
        # show 0% - they can see "VS throughput: 14.6 MB/min" and know real
        # work is happening regardless of what the GUI says.
        try {
            $bytesNow = [Int64]$Script:LastDirectorySizeBytes[$packageCache]
            if ($bytesNow -gt 0) {
                # Keep only the last ~3 minutes of samples so transient stalls
                # don't dominate the average forever.
                $cutoff = $now.AddSeconds(-180)
                if ($Script:VSCacheSamples.Count -gt 0) {
                    $kept = New-Object 'System.Collections.Generic.List[object]'
                    foreach ($s in $Script:VSCacheSamples) { if ($s.Time -gt $cutoff) { $kept.Add($s) | Out-Null } }
                    $Script:VSCacheSamples = $kept
                }
                # Add the current sample and compute throughput against the
                # oldest sample we still have (window <= 180s).
                $Script:VSCacheSamples.Add([pscustomobject]@{ Time = $now; Bytes = $bytesNow }) | Out-Null
                if ($Script:VSCacheSamples.Count -ge 2) {
                    $first = $Script:VSCacheSamples[0]
                    $deltaBytes = $bytesNow - [Int64]$first.Bytes
                    $deltaSeconds = ($now - $first.Time).TotalSeconds
                    if ($deltaSeconds -ge 5 -and $deltaBytes -gt 0) {
                        $mbPerMin = ($deltaBytes / 1MB) * (60.0 / $deltaSeconds)
                        [void]$lines.Add(("VS throughput: {0:N1} MB/min (over last {1}s)" -f $mbPerMin, [int]$deltaSeconds))
                    } elseif ($deltaSeconds -ge 30 -and $deltaBytes -le 0) {
                        # Honest reporting: if cache hasn't grown in 30+ seconds during
                        # the early phase, surface it instead of staying silent.
                        [void]$lines.Add(("VS throughput: idle for the last {0}s (normal during MSI custom-action phases)" -f [int]$deltaSeconds))
                    }
                }
            }
        } catch { }
    } else {
        [void]$lines.Add("VS package cache: not created yet")
    }

    $installRoot = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
    if (Test-Path -LiteralPath $installRoot) {
        $summary = Get-DirectorySizeApprox -Path $installRoot -MaxFiles 800
        $newest = Get-NewestPathSummary -Path $installRoot
        if ($summary) { [void]$lines.Add(("Build Tools install root: {0}" -f $summary)) }
        if ($newest) { [void]$lines.Add(("Build Tools install activity: {0}" -f $newest)) }
    } else {
        [void]$lines.Add("Build Tools install root: not created yet")
    }


    try {
        $setupProcesses = @(Get-Process -Name setup,vs_setup_bootstrapper,vs_installer,vs_installerservice -ErrorAction SilentlyContinue | Select-Object -First 6)
        if ($setupProcesses.Count -gt 0) {
            $names = ($setupProcesses | ForEach-Object { "{0}:{1}" -f $_.ProcessName, $_.Id }) -join ", "
            [void]$lines.Add(("VS setup processes: {0}" -f $names))
        }
    } catch { }

    try {
        $vsLogs = @(Get-ChildItem -LiteralPath $env:TEMP -Filter 'dd_*.log' -ErrorAction SilentlyContinue |
            Sort-Object LastWriteTime -Descending |
            Select-Object -First 3)
        foreach ($vsLog in $vsLogs) {
            $age = (Get-Date) - $vsLog.LastWriteTime
            $ageText = if ($age.TotalMinutes -lt 1) { ("{0}s ago" -f [int]$age.TotalSeconds) } else { ("{0}m {1}s ago" -f [int]$age.TotalMinutes, ([int]$age.TotalSeconds % 60)) }
            [void]$lines.Add(("VS setup log: {0} ({1}, {2})" -f $vsLog.Name, (Format-ByteSize $vsLog.Length), $ageText))
        }
    } catch { }

    if ($lines.Count -eq 0) { [void]$lines.Add("Build Tools monitor: waiting for installer activity") }
    $Script:ActivityExtraStatusCache = @($lines.ToArray())
    $Script:ActivityExtraStatusLastRefresh = $now
    return $Script:ActivityExtraStatusCache
}

function Get-ActivityExtraStatus {
    param(
        [string]$CommandDisplay,
        [string]$LogPath
    )

    if ([string]::IsNullOrWhiteSpace($CommandDisplay)) { return @() }
    if ($Script:FileOpWatchPaths -and $Script:FileOpWatchPaths.Count -gt 0) {
        $lines = New-Object 'System.Collections.Generic.List[string]'
        foreach ($watch in $Script:FileOpWatchPaths) {
            try {
                $label = [string]$watch.Label
                $path = [string]$watch.Path
                if ([string]::IsNullOrWhiteSpace($path)) { continue }
                if (Test-Path -LiteralPath $path) {
                    $item = Get-Item -LiteralPath $path -ErrorAction Stop
                    if ($item.PSIsContainer) {
                        $summary = Get-DirectorySizeApprox -Path $path -MaxFiles 1200
                        $newest = Get-NewestPathSummary -Path $path
                        if ($summary) { [void]$lines.Add(("{0}: {1}" -f $label, $summary)) }
                        if ($newest) { [void]$lines.Add(("{0} activity: {1}" -f $label, $newest)) }
                    } else {
                        [void]$lines.Add(("{0}: {1}" -f $label, (Get-FileSizeSummary -Path $path)))
                    }
                } else {
                    [void]$lines.Add(("{0}: not created yet" -f $label))
                }
            } catch { }
        }
        if ($lines.Count -gt 0) { return @($lines.ToArray()) }
    }
    if ($CommandDisplay -match '(?i)vs_BuildTools|VisualStudio|Microsoft\.VisualStudio|vs_setup_bootstrapper') {
        return @(Get-VSBuildToolsActivitySummary -LogPath $LogPath)
    }

    if ($CommandDisplay -match '(?i)^Download\s+') {
        $m = [regex]::Match($CommandDisplay, '->\s*(.+)$')
        if ($m.Success) {
            $target = $m.Groups[1].Value.Trim()
            $size = Get-FileSizeSummary -Path $target
            if ($size) { return @("download target: $size") }
        }
    }

    return @()
}


function Write-WrappedDashboardNotice {
    param(
        [string]$Label,
        [string]$Text,
        [string]$ForegroundColor = "Yellow"
    )

    if ([string]::IsNullOrWhiteSpace($Text)) { return }

    $width = Get-ConsoleWidthSafe
    $maxLine = [Math]::Max(40, $width - 2)
    $prefix = if ([string]::IsNullOrWhiteSpace($Label)) { "" } else { "${Label}: " }
    $continuation = " " * $prefix.Length
    $first = $true

    foreach ($paragraph in ($Text -split "`r?`n")) {
        $remaining = $paragraph.Trim()
        if ([string]::IsNullOrWhiteSpace($remaining)) {
            Write-Host "" -ForegroundColor $ForegroundColor
            $first = $false
            continue
        }

        while ($remaining.Length -gt 0) {
            $lead = if ($first) { $prefix } else { $continuation }
            $limit = [Math]::Max(20, $maxLine - $lead.Length)
            if ($remaining.Length -le $limit) {
                Write-Host (Fit-ConsoleLine ($lead + $remaining)) -ForegroundColor $ForegroundColor
                $remaining = ""
            } else {
                $cut = $remaining.LastIndexOf(' ', [Math]::Min($limit, $remaining.Length - 1))
                if ($cut -lt 20) { $cut = $limit }
                $line = $remaining.Substring(0, $cut).TrimEnd()
                Write-Host (Fit-ConsoleLine ($lead + $line)) -ForegroundColor $ForegroundColor
                $remaining = $remaining.Substring([Math]::Min($cut, $remaining.Length)).TrimStart()
            }
            $first = $false
        }
    }
}

function Write-ActiveCommandDashboard {
    param(
        [string]$CommandDisplay,
        [string]$LogPath,
        [string]$ActivityNote,
        [string]$Spinner = "|",
        [TimeSpan]$Elapsed = ([TimeSpan]::Zero),
        [string]$Status = "RUNNING"
    )

    if ($NoProgressHeader) { return }

    try { Clear-Host } catch { }

    $total = [Math]::Max(1, $Script:SetupSteps.Count)
    $stepNumber = [Math]::Max(0, $Script:CurrentStepNumber)
    $completed = if ($Status -eq "COMPLETE") { [Math]::Min($total, $stepNumber) } else { [Math]::Max(0, [Math]::Min($total, $Script:CurrentCompletedBefore)) }
    $pct = [int][Math]::Floor(($completed / [double]$total) * 100)
    if ($Status -eq "COMPLETE" -and $stepNumber -eq $total) { $pct = 100 }

    $bar = Get-StarshipProgressBar -Percent $pct
    $ship = if ($pct -ge 100) { "<| DONE |>" } else { "<|===>" }
    $stepDisplay = if ($stepNumber -le 0) { "Step 0/$total" } else { "Step $stepNumber/$total" }
    $stepName = if ([string]::IsNullOrWhiteSpace($Script:CurrentStepName)) { "Working" } else { $Script:CurrentStepName }
    $elapsedText = ("{0:00}:{1:00}:{2:00}" -f [int]$Elapsed.TotalHours, $Elapsed.Minutes, $Elapsed.Seconds)
    $lastLog = Get-LogLastWriteSummary -Path $LogPath

    # v11: Spinner color escalates with elapsed time so the user gets a visual
    # cue when a step is running longer than expected, without panicking them
    # at the start of a known-long step like Build Tools.
    #   - up to expected-duration: green (normal)
    #   - 1x-2x expected:          yellow (taking longer than usual)
    #   - >2x expected:            red    (consider Task Manager / abort)
    # The expected duration is "10 minutes" by default, but Build Tools and
    # WinGet steps get longer budgets so they don't immediately turn yellow.
    $expectedSeconds = 600
    if ($CommandDisplay -match '(?i)vs_BuildTools|VisualStudio|Microsoft\.VisualStudio') {
        $expectedSeconds = 2700  # 45 minutes is a normal Build Tools install
    } elseif ($CommandDisplay -match '(?i)winget\s+install') {
        $expectedSeconds = 900   # 15 minutes is generous for a winget install
    } elseif ($CommandDisplay -match '(?i)cargo\s+build') {
        $expectedSeconds = 1200  # 20 minutes for first full Rust build
    }
    $statusColor = if ($Status -eq "COMPLETE") { "Green" }
                   elseif ($Status -eq "FAILED") { "Red" }
                   elseif ($Elapsed.TotalSeconds -gt ($expectedSeconds * 2)) { "Red" }
                   elseif ($Elapsed.TotalSeconds -gt $expectedSeconds) { "Yellow" }
                   else { "Green" }

    foreach ($line in (Get-ProgressBannerLines -Style $BannerStyle)) {
        Write-Host (Fit-ConsoleLine $line) -ForegroundColor DarkCyan
    }
    Write-Host (Fit-ConsoleLine (Get-CenteredProgressLine -Ship $ship -Bar $bar -Percent $pct)) -ForegroundColor Cyan
    Write-Host (Fit-ConsoleLine (" .  *  PROGRESS ::  {0}  {1} {2}  ::  {3}" -f $stepDisplay, $Status, $Spinner, $stepName)) -ForegroundColor Gray
    Write-Host (Fit-ConsoleLine ("     course: {0}" -f $DevRoot)) -ForegroundColor DarkGray
    Write-Host (Fit-ConsoleLine ("     log: {0}" -f $Script:TranscriptLogPath)) -ForegroundColor DarkGray
    Write-Host ""

    Write-Host (Fit-ConsoleLine ("ACTIVE COMMAND {0}  elapsed {1}  last log write: {2}" -f $Spinner, $elapsedText, $lastLog)) -ForegroundColor $statusColor
    Write-Host (Fit-ConsoleLine ("COMMAND: {0}" -f $CommandDisplay)) -ForegroundColor White
    Write-Host (Fit-ConsoleLine ("OUTPUT LOG: {0}" -f $LogPath)) -ForegroundColor DarkGray
    $extraStatusLines = @(Get-ActivityExtraStatus -CommandDisplay $CommandDisplay -LogPath $LogPath)
    foreach ($extraStatusLine in $extraStatusLines) {
        if (-not [string]::IsNullOrWhiteSpace($extraStatusLine)) {
            Write-Host (Fit-ConsoleLine ("WATCH: {0}" -f $extraStatusLine)) -ForegroundColor DarkYellow
        }
    }
    if (-not [string]::IsNullOrWhiteSpace($ActivityNote)) {
        Write-WrappedDashboardNotice -Label "NOTE" -Text $ActivityNote -ForegroundColor Yellow
    }
    # v11: Pair the "do not close" line with a graceful-abort hint. Users who
    # actually need to bail had no clean exit before; Ctrl+C lets them stop
    # without slamming the X (which can leave child processes orphaned).
    Write-Host (Fit-ConsoleLine "Do not close this window unless you intentionally want to abort the setup.") -ForegroundColor DarkYellow
    Write-Host (Fit-ConsoleLine "To abort cleanly, press Ctrl+C. A log of progress so far will still be saved.") -ForegroundColor DarkYellow
    Write-Host ""

    Write-Host "Recent command output:" -ForegroundColor DarkCyan
    if (Test-Path -LiteralPath $LogPath) {
        try {
            $tail = @(Get-SafeTextFileTail -Path $LogPath -MaxLines 10)
            if ($tail.Count -eq 0) { Write-Host "  waiting for command output..." -ForegroundColor DarkGray }
            foreach ($line in $tail) {
                if ([string]::IsNullOrWhiteSpace($line)) { continue }
                Write-Host (Fit-ConsoleLine ("  " + $line)) -ForegroundColor DarkGray
            }
        } catch {
            Write-Host "  waiting for command output..." -ForegroundColor DarkGray
        }
    } else {
        Write-Host "  waiting for command log to be created..." -ForegroundColor DarkGray
    }
}

function Invoke-LoggedCommandJob {
    param(
        [Parameter(Mandatory=$true)][string]$Exe,
        [string[]]$Arguments = @(),
        [Parameter(Mandatory=$true)][string]$Display,
        [Parameter(Mandatory=$true)][string]$CommandLog,
        [string]$ActivityNote = "",
        [string]$WorkingDirectory = ""
    )

    if ([string]::IsNullOrWhiteSpace($ActivityNote)) { $ActivityNote = Get-DefaultActivityNote -Display $Display }
    $Script:LastCommandLogPath = $CommandLog
    $Script:LastCommandDisplay = $Display
    $Script:LastActivityNote = $ActivityNote
    $Script:ActivityExtraStatusCache = @()
    $Script:ActivityExtraStatusLastRefresh = [datetime]::MinValue

    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $workText = if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) { "" } else { "WORKDIR: $WorkingDirectory`r`n" }
    [IO.File]::WriteAllText($CommandLog, $workText + "COMMAND: $Display`r`nSTARTED: $((Get-Date).ToString('s'))`r`n`r`n", $utf8)

    $exitFile = "$CommandLog.exit"
    Remove-Item -LiteralPath $exitFile -Force -ErrorAction SilentlyContinue

    $job = Start-Job -ScriptBlock {
        param([string]$JobExe, [string[]]$JobArguments, [string]$JobLog, [string]$JobExitFile, [string]$JobWorkDir)
        $ErrorActionPreference = 'Continue'
        try {
            if (-not [string]::IsNullOrWhiteSpace($JobWorkDir)) {
                try { Set-Location -LiteralPath $JobWorkDir } catch { try { Add-Content -LiteralPath $JobLog -Value ("WARN: Set-Location failed for '" + $JobWorkDir + "': " + $_.Exception.Message) -Encoding UTF8 } catch { } }
            }
            & $JobExe @JobArguments 2>&1 | ForEach-Object {
                try { Add-Content -LiteralPath $JobLog -Value ($_.ToString()) -Encoding UTF8 } catch { }
            }
            $ec = $LASTEXITCODE
            if ($null -eq $ec) { $ec = 0 }
        } catch {
            try { Add-Content -LiteralPath $JobLog -Value ("ERROR: " + $_.Exception.Message) -Encoding UTF8 } catch { }
            $ec = 1
        }
        try { Add-Content -LiteralPath $JobLog -Value "`r`nFINISHED: $((Get-Date).ToString('s'))`r`nEXIT CODE: $ec" -Encoding UTF8 } catch { }
        try { Set-Content -LiteralPath $JobExitFile -Value ([string]$ec) -Encoding ASCII } catch { }
    } -ArgumentList $Exe, ([string[]]$Arguments), $CommandLog, $exitFile, $WorkingDirectory

    $spinnerFrames = @('|','/','-','\')
    $start = Get-Date
    $tick = 0
    # v11: Defer the first dashboard paint by 700ms. Many commands (--version
    # probes, winget --version, small npm config sets) finish in well under a
    # second; in v10 those would still trigger a full Clear-Host + redraw,
    # producing visible flicker for no information gain. Real long-running
    # commands easily clear this threshold and behave exactly as before.
    $firstPaintDelayMs = 700

    while ((Get-Job -Id $job.Id).State -eq 'Running') {
        $elapsed = (Get-Date) - $start
        if ($elapsed.TotalMilliseconds -ge $firstPaintDelayMs) {
            $spinner = $spinnerFrames[$tick % $spinnerFrames.Count]
            Write-ActiveCommandDashboard -CommandDisplay $Display -LogPath $CommandLog -ActivityNote $ActivityNote -Spinner $spinner -Elapsed $elapsed -Status "RUNNING"
            Start-Sleep -Seconds 1
            $tick++
        } else {
            Start-Sleep -Milliseconds 100
        }
    }

    Wait-Job -Job $job | Out-Null
    Receive-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue

    $exitCode = 1
    if (Test-Path -LiteralPath $exitFile) {
        try { $exitCode = [int]((Get-Content -LiteralPath $exitFile -ErrorAction Stop | Select-Object -First 1).Trim()) } catch { $exitCode = 1 }
        Remove-Item -LiteralPath $exitFile -Force -ErrorAction SilentlyContinue
    } else {
        Add-Content -LiteralPath $CommandLog -Value "`r`nERROR: The command finished but did not write an exit-code file." -Encoding UTF8
    }

    $elapsedFinal = (Get-Date) - $start
    $finalStatus = if ($exitCode -eq 0) { "COMPLETE" } else { "FAILED" }
    # v11: Only repaint the final dashboard if the command lasted long enough
    # to have shown the dashboard at all. A 200ms `--version` check should not
    # flicker the screen on the way out.
    if ($elapsedFinal.TotalMilliseconds -ge $firstPaintDelayMs) {
        Write-ActiveCommandDashboard -CommandDisplay $Display -LogPath $CommandLog -ActivityNote $ActivityNote -Spinner "*" -Elapsed $elapsedFinal -Status $finalStatus
        Start-Sleep -Milliseconds 350
    }

    return $exitCode
}


function Invoke-MonitoredProcessWait {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [string]$ActivityNote = "",
        [int[]]$SuccessExitCodes = @(0),
        # v12: Optional callback invoked every monitoring tick with the current
        # elapsed TimeSpan; its return value REPLACES the static $ActivityNote
        # on each dashboard repaint. Used by VS Build Tools to swap in
        # time-phased reassurance text as the user crosses well-known
        # "this looks frozen but isn't" thresholds.
        [scriptblock]$NoteCallback = $null,
        [string]$WorkingDirectory = ""
    )

    $display = Format-CommandDisplay -Exe $FilePath -Arguments $ArgumentList
    if ([string]::IsNullOrWhiteSpace($ActivityNote)) { $ActivityNote = Get-DefaultActivityNote -Display $display }

    if ($DryRun) {
        Write-Host "[dry-run] $display" -ForegroundColor DarkGray
        return 0
    }

    $commandLog = Get-CommandLogPath -Exe $FilePath
    $Script:LastCommandLogPath = $commandLog
    $Script:LastCommandDisplay = $display
    $Script:LastActivityNote = $ActivityNote
    $Script:ActivityExtraStatusCache = @()
    $Script:ActivityExtraStatusLastRefresh = [datetime]::MinValue

    $utf8 = New-Object System.Text.UTF8Encoding($false)
    $workText = if ([string]::IsNullOrWhiteSpace($WorkingDirectory)) { "" } else { "WORKDIR: $WorkingDirectory`r`n" }
    [IO.File]::WriteAllText($commandLog, $workText + "COMMAND: $display`r`nSTARTED: $((Get-Date).ToString('s'))`r`n`r`n", $utf8)
    Add-Content -LiteralPath $commandLog -Value "Started with Start-Process so the installer can show its own passive progress UI." -Encoding UTF8

    $process = $null
    try {
        $spArgs = @{ FilePath = $FilePath; ArgumentList = $ArgumentList; PassThru = $true }
        if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) { $spArgs.WorkingDirectory = $WorkingDirectory }
        $process = Start-Process @spArgs
    } catch {
        Add-Content -LiteralPath $commandLog -Value ("ERROR: " + $_.Exception.Message) -Encoding UTF8
        throw
    }

    $spinnerFrames = @('|','/','-','\')
    $start = Get-Date
    $tick = 0

    while ($null -ne $process -and -not $process.HasExited) {
        $elapsed = (Get-Date) - $start
        $spinner = $spinnerFrames[$tick % $spinnerFrames.Count]
        # v12: If the caller passed a NoteCallback, recompute the note every
        # tick. Wrapped in try/catch so a buggy callback can never wedge the
        # monitoring loop - we fall back to the static note in that case.
        $liveNote = $ActivityNote
        if ($null -ne $NoteCallback) {
            try {
                $cbResult = & $NoteCallback $elapsed
                if (-not [string]::IsNullOrWhiteSpace($cbResult)) { $liveNote = [string]$cbResult }
            } catch { }
        }
        Write-ActiveCommandDashboard -CommandDisplay $display -LogPath $commandLog -ActivityNote $liveNote -Spinner $spinner -Elapsed $elapsed -Status "RUNNING"
        Start-Sleep -Seconds 1
        $tick++
        try { $process.Refresh() } catch { }
    }

    $exitCode = 1
    try { $exitCode = [int]$process.ExitCode } catch { $exitCode = 1 }
    $elapsedFinal = (Get-Date) - $start
    Add-Content -LiteralPath $commandLog -Value "`r`nFINISHED: $((Get-Date).ToString('s'))`r`nEXIT CODE: $exitCode" -Encoding UTF8

    $finalStatus = if ($SuccessExitCodes -contains $exitCode) { "COMPLETE" } else { "FAILED" }
    # Use the final-phase note if a callback was supplied, otherwise the static one.
    $finalNote = $ActivityNote
    if ($null -ne $NoteCallback) {
        try {
            $cbResult = & $NoteCallback $elapsedFinal
            if (-not [string]::IsNullOrWhiteSpace($cbResult)) { $finalNote = [string]$cbResult }
        } catch { }
    }
    Write-ActiveCommandDashboard -CommandDisplay $display -LogPath $commandLog -ActivityNote $finalNote -Spinner "*" -Elapsed $elapsedFinal -Status $finalStatus
    Start-Sleep -Milliseconds 350

    return $exitCode
}

function Invoke-LoggedDownloadJob {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$OutFile
    )
    if ($Script:NoNetwork -or (Test-NonLiveInstallerMode)) { throw "Non-live harness blocked download: $Uri" }
    Assert-HarnessPathAllowed -Path $OutFile -Purpose "download output"

    $display = "Download $Uri -> $OutFile"
    $commandLog = Get-CommandLogPath -Exe "download"
    $note = "Downloading a setup file. Large archives can be quiet for a while; the spinner confirms the download job is still running."
    $Script:LastCommandLogPath = $commandLog
    $Script:LastCommandDisplay = $display
    $Script:LastActivityNote = $note
    $Script:ActivityExtraStatusCache = @()
    $Script:ActivityExtraStatusLastRefresh = [datetime]::MinValue

    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($commandLog, "COMMAND: $display`r`nSTARTED: $((Get-Date).ToString('s'))`r`n`r`n", $utf8)
    $exitFile = "$commandLog.exit"
    Remove-Item -LiteralPath $exitFile -Force -ErrorAction SilentlyContinue

    $job = Start-Job -ScriptBlock {
        param([string]$JobUri, [string]$JobOutFile, [string]$JobLog, [string]$JobExitFile)
        $ErrorActionPreference = 'Stop'
        $ProgressPreference = 'SilentlyContinue'
        try {
            Add-Content -LiteralPath $JobLog -Value ("Downloading from: " + $JobUri) -Encoding UTF8
            Add-Content -LiteralPath $JobLog -Value ("Saving to: " + $JobOutFile) -Encoding UTF8
            Invoke-WebRequest -Uri $JobUri -OutFile $JobOutFile -UseBasicParsing
            if (Test-Path -LiteralPath $JobOutFile) {
                $size = (Get-Item -LiteralPath $JobOutFile).Length
                Add-Content -LiteralPath $JobLog -Value ("Download complete. Bytes: " + $size) -Encoding UTF8
            }
            $ec = 0
        } catch {
            Add-Content -LiteralPath $JobLog -Value ("ERROR: " + $_.Exception.Message) -Encoding UTF8
            $ec = 1
        }
        Add-Content -LiteralPath $JobLog -Value "`r`nFINISHED: $((Get-Date).ToString('s'))`r`nEXIT CODE: $ec" -Encoding UTF8
        Set-Content -LiteralPath $JobExitFile -Value ([string]$ec) -Encoding ASCII
    } -ArgumentList $Uri, $OutFile, $commandLog, $exitFile

    $spinnerFrames = @('|','/','-','\')
    $start = Get-Date
    $tick = 0

    while ((Get-Job -Id $job.Id).State -eq 'Running') {
        $elapsed = (Get-Date) - $start
        $spinner = $spinnerFrames[$tick % $spinnerFrames.Count]
        Write-ActiveCommandDashboard -CommandDisplay $display -LogPath $commandLog -ActivityNote $note -Spinner $spinner -Elapsed $elapsed -Status "RUNNING"
        Start-Sleep -Seconds 1
        $tick++
    }

    Wait-Job -Job $job | Out-Null
    Receive-Job -Job $job -ErrorAction SilentlyContinue | Out-Null
    Remove-Job -Job $job -Force -ErrorAction SilentlyContinue

    $exitCode = 1
    if (Test-Path -LiteralPath $exitFile) {
        try { $exitCode = [int]((Get-Content -LiteralPath $exitFile -ErrorAction Stop | Select-Object -First 1).Trim()) } catch { $exitCode = 1 }
        Remove-Item -LiteralPath $exitFile -Force -ErrorAction SilentlyContinue
    }

    $elapsedFinal = (Get-Date) - $start
    $finalStatus = if ($exitCode -eq 0) { "COMPLETE" } else { "FAILED" }
    Write-ActiveCommandDashboard -CommandDisplay $display -LogPath $commandLog -ActivityNote $note -Spinner "*" -Elapsed $elapsedFinal -Status $finalStatus
    Start-Sleep -Milliseconds 350

    if ($exitCode -ne 0) { throw "Download failed: $Uri" }
}

function Initialize-ProgressHeader {
    if ($NoProgressHeader) { return }
    try {
        $Script:ProgressHeaderHeight = Get-ProgressHeaderLineCount
        $Script:ProgressHeaderTop = $Host.UI.RawUI.CursorPosition.Y
        for ($i = 0; $i -lt $Script:ProgressHeaderHeight; $i++) { Write-Host "" }
        $Script:ProgressHeaderEnabled = $true
        Write-SetupProgress -CompletedCount 0 -StepNumber 0 -StepName "Initializing" -Status "Ready"
    } catch {
        $Script:ProgressHeaderEnabled = $false
        Write-Warning "The sticky progress header is not supported by this host. Continuing with normal console output."
    }
}

function Write-SetupProgress {
    param(
        [int]$CompletedCount,
        [int]$StepNumber,
        [string]$StepName,
        [string]$Status = "Working"
    )

    if (-not $Script:ProgressHeaderEnabled) { return }

    $total = [Math]::Max(1, $Script:SetupSteps.Count)
    $done = [Math]::Max(0, [Math]::Min($total, $CompletedCount))
    $pct = [int][Math]::Floor(($done / [double]$total) * 100)
    $bar = Get-StarshipProgressBar -Percent $pct
    $ship = if ($pct -ge 100) { "<| DONE |>" } else { "<|===>" }
    $stepDisplay = if ($StepNumber -le 0) { "Step 0/$total" } else { "Step $StepNumber/$total" }
    $logDisplay = if ([string]::IsNullOrWhiteSpace($Script:TranscriptLogPath)) { "Log: will start after folder setup" } else { "Log: $($Script:TranscriptLogPath)" }

    $modeDisplay = if ($Script:HiddenDryRun) { "VISUAL PREVIEW" } elseif ($DryRun) { "DRY RUN" } else { "LIVE RUN" }
    $bannerLines = @(Get-ProgressBannerLines -Style $BannerStyle)
    $lineProgress = Get-CenteredProgressLine -Ship $ship -Bar $bar -Percent $pct
    $lineStatus = " .  *  PROGRESS ::  $stepDisplay  $Status  ::  $StepName"
    $lineCourse = "     course: $DevRoot"
    $lineLog = if ($Script:HiddenDryRun) {
        "     mode: $modeDisplay :: no installers, downloads, PATH changes, or repo/build actions"
    } else {
        "     $logDisplay"
    }

    $headerLines = @()
    $headerLines += $bannerLines
    $headerLines += $lineProgress
    $headerLines += $lineStatus
    $headerLines += $lineCourse
    $headerLines += $lineLog

    if ($Script:VisualPreviewMode) {
        Write-VisualPreviewDashboard -HeaderLines $headerLines -CompletedCount $CompletedCount -StepNumber $StepNumber -Status $Status
        return
    }

    if (-not $NoProgressHeader) {
        Write-LiveProgressDashboard -HeaderLines $headerLines -CompletedCount $CompletedCount -StepNumber $StepNumber -Status $Status
        return
    }

    try {
        $raw = $Host.UI.RawUI
        $oldPos = $raw.CursorPosition
        $target = $oldPos
        $target.X = 0
        # Redraw at the top of the visible window for a sticky feel, but do not go above the original header reservation.
        $target.Y = [int][Math]::Max($Script:ProgressHeaderTop, $raw.WindowPosition.Y)
        $raw.CursorPosition = $target

        for ($i = 0; $i -lt $Script:ProgressHeaderHeight; $i++) {
            $text = if ($i -lt $headerLines.Count) { $headerLines[$i] } else { "" }
            $color = if ($i -lt $bannerLines.Count) {
                "DarkCyan"
            } elseif ($i -eq $bannerLines.Count) {
                "Cyan"
            } elseif ($i -eq ($bannerLines.Count + 1)) {
                "Gray"
            } else {
                "DarkGray"
            }
            Write-Host (Fit-ConsoleLine $text) -ForegroundColor $color
        }

        $raw.CursorPosition = $oldPos
    } catch {
        $Script:ProgressHeaderEnabled = $false
    }
}

function Invoke-SetupStep {
    param(
        [Parameter(Mandatory=$true)][string]$Id,
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][scriptblock]$ScriptBlock,
        [switch]$Fatal
    )

    $stepNumber = 0
    if ($Script:SetupStepLookup.ContainsKey($Id)) { $stepNumber = [int]$Script:SetupStepLookup[$Id] }
    $completedBefore = if ($stepNumber -gt 0) { $stepNumber - 1 } else { 0 }
    $Script:CurrentStepNumber = $stepNumber
    $Script:CurrentStepName = $Name
    $Script:CurrentStepId = $Id
    $Script:CurrentCompletedBefore = $completedBefore

    $skipReason = Get-StepDependencySkipReason -Id $Id
    if (-not [string]::IsNullOrWhiteSpace($skipReason)) {
        Write-SetupProgress -CompletedCount $completedBefore -StepNumber $stepNumber -StepName $Name -Status "SKIPPED"
        Write-PhaseBanner -Name $Name -StepNumber $stepNumber -Status "SKIPPED"
        Write-Host $skipReason -ForegroundColor DarkYellow
        $Script:StepTimings.Add([pscustomobject]@{
            Id = $Id; Name = $Name; ElapsedSeconds = 0; Status = "SKIPPED"; Reason = $skipReason
        }) | Out-Null
        Add-SetupSkipRecord -Id $Id -Name $Name -Reason $skipReason
        Save-SetupState
        return
    }

    $stepStart = Get-Date
    $Script:CurrentStepStart = $stepStart
    $Script:CurrentStepResultStatus = ""
    $Script:CurrentStepResultReason = ""

    Write-SetupProgress -CompletedCount $completedBefore -StepNumber $stepNumber -StepName $Name -Status "Working"
    Write-PhaseBanner -Name $Name -StepNumber $stepNumber -Status "BEGIN"

    if ($Script:VisualPreviewMode) {
        Start-Sleep -Milliseconds 220
        $completedAfter = if ($stepNumber -gt 0) { $stepNumber } else { $completedBefore }
        Write-SetupProgress -CompletedCount $completedAfter -StepNumber $stepNumber -StepName $Name -Status "Complete"
        Start-Sleep -Milliseconds 90
        $Script:StepTimings.Add([pscustomobject]@{
            Id = $Id; Name = $Name; ElapsedSeconds = 0.22; Status = "Preview"; Reason = ""
        }) | Out-Null
        # Hidden visual preview must not write setup-state or cache markers.
        return
    }

    $failureMessageShown = $false
    try {
        & $ScriptBlock
        $elapsed = (Get-Date) - $stepStart
        $completedAfter = if ($stepNumber -gt 0) { $stepNumber } else { $completedBefore }
        $softStatus = ([string]$Script:CurrentStepResultStatus).Trim().ToUpperInvariant()
        if ($softStatus -eq "SKIPPED") {
            $reason = if ([string]::IsNullOrWhiteSpace($Script:CurrentStepResultReason)) { "Skipped." } else { $Script:CurrentStepResultReason }
            Write-SetupProgress -CompletedCount $completedAfter -StepNumber $stepNumber -StepName $Name -Status "SKIPPED"
            Write-PhaseBanner -Name $Name -StepNumber $stepNumber -Status "SKIPPED"
            $Script:StepTimings.Add([pscustomobject]@{
                Id = $Id; Name = $Name; ElapsedSeconds = [Math]::Round($elapsed.TotalSeconds, 1); Status = "SKIPPED"; Reason = $reason
            }) | Out-Null
            Add-SetupSkipRecord -Id $Id -Name $Name -Reason $reason
            Save-SetupState
            return
        }
        if ($softStatus -eq "WARN") {
            $reason = if ([string]::IsNullOrWhiteSpace($Script:CurrentStepResultReason)) { "Completed with warnings." } else { $Script:CurrentStepResultReason }
            Write-SetupProgress -CompletedCount $completedAfter -StepNumber $stepNumber -StepName $Name -Status "WARN"
            Write-PhaseBanner -Name $Name -StepNumber $stepNumber -Status "WARN"
            Write-Host ("Step completed with warning: {0}" -f $reason) -ForegroundColor Yellow
            $Script:StepTimings.Add([pscustomobject]@{
                Id = $Id; Name = $Name; ElapsedSeconds = [Math]::Round($elapsed.TotalSeconds, 1); Status = "WARN"; Reason = $reason
            }) | Out-Null
            Save-SetupState
            return
        }
        if ($softStatus -in @("FAIL", "FAILED", "FATAL")) {
            $reason = if ([string]::IsNullOrWhiteSpace($Script:CurrentStepResultReason)) { "Step reported failure." } else { $Script:CurrentStepResultReason }
            $statusText = if ($softStatus -eq "FATAL" -or $Fatal) { "FATAL" } else { "FAILED" }
            $Script:StepTimings.Add([pscustomobject]@{
                Id = $Id; Name = $Name; ElapsedSeconds = [Math]::Round($elapsed.TotalSeconds, 1); Status = $statusText; Reason = $reason
            }) | Out-Null
            Add-SetupFailureRecord -Id $Id -Name $Name -Reason $reason -LogPath $Script:LastCommandLogPath -Fatal:($statusText -eq "FATAL")
            Write-SetupProgress -CompletedCount $completedAfter -StepNumber $stepNumber -StepName $Name -Status "FAILED"
            Write-PhaseBanner -Name $Name -StepNumber $stepNumber -Status $statusText
            if ($statusText -eq "FATAL") {
                Write-Host "Fatal setup step failed; setup will stop after saving state and logs." -ForegroundColor Red
            } else {
                Write-Host "Step failed, but setup will continue where possible." -ForegroundColor Yellow
            }
            $failureMessageShown = $true
            Write-Host ("Reason: {0}" -f $reason) -ForegroundColor Red
            Save-SetupState
            if ($statusText -eq "FATAL") { throw $reason }
            return
        }
        Write-SetupProgress -CompletedCount $completedAfter -StepNumber $stepNumber -StepName $Name -Status "Complete"
        Write-PhaseBanner -Name $Name -StepNumber $stepNumber -Status "COMPLETE"
        $Script:StepTimings.Add([pscustomobject]@{
            Id = $Id; Name = $Name; ElapsedSeconds = [Math]::Round($elapsed.TotalSeconds, 1); Status = "OK"; Reason = ""
        }) | Out-Null
        Save-SetupState
        Set-StepCacheMarker -StepId $Id -ValidationKey $Name
        if ($elapsed.TotalSeconds -ge $Script:LongStepThresholdSeconds) {
            try { [System.Media.SystemSounds]::Asterisk.Play() } catch { }
        }
    } catch {
        $elapsed = (Get-Date) - $stepStart
        $reason = $_.Exception.Message
        $completedAfter = if ($stepNumber -gt 0) { $stepNumber } else { $completedBefore }
        $caughtSoftStatus = ([string]$Script:CurrentStepResultStatus).Trim().ToUpperInvariant()
        $statusText = if ($Fatal -or $caughtSoftStatus -eq "FATAL") { "FATAL" } else { "FAILED" }
        $alreadyRecorded = $false
        try {
            $latest = @($Script:StepTimings | Where-Object { [string]$_.Id -eq $Id } | Select-Object -Last 1)
            if ($latest.Count -gt 0) {
                $alreadyRecorded = (([string]$latest[0].Status -eq $statusText) -and ([string]$latest[0].Reason -eq $reason))
            }
        } catch { $alreadyRecorded = $false }
        if (-not $alreadyRecorded) {
            $Script:StepTimings.Add([pscustomobject]@{
                Id = $Id; Name = $Name; ElapsedSeconds = [Math]::Round($elapsed.TotalSeconds, 1); Status = $statusText; Reason = $reason
            }) | Out-Null
        }
        Add-SetupFailureRecord -Id $Id -Name $Name -Reason $reason -LogPath $Script:LastCommandLogPath -Fatal:($statusText -eq "FATAL")
        if ($elapsed.TotalSeconds -ge $Script:LongStepThresholdSeconds) {
            try { [System.Media.SystemSounds]::Hand.Play() } catch { }
        }
        if (-not $alreadyRecorded) {
            Write-SetupProgress -CompletedCount $completedAfter -StepNumber $stepNumber -StepName $Name -Status "FAILED"
            Write-PhaseBanner -Name $Name -StepNumber $stepNumber -Status $statusText
        }
        if (-not $failureMessageShown) {
            if ($statusText -eq "FATAL") {
                Write-Host "Fatal setup step failed; setup will stop after saving state and logs." -ForegroundColor Red
            } else {
                Write-Host "Step failed, but setup will continue where possible." -ForegroundColor Yellow
            }
            Write-Host ("Reason: {0}" -f $reason) -ForegroundColor Red
            if (-not [string]::IsNullOrWhiteSpace($Script:LastCommandLogPath)) {
                Write-Host ("Last command log: {0}" -f $Script:LastCommandLogPath) -ForegroundColor DarkYellow
            }
        }
        Save-SetupState
        Start-Sleep -Milliseconds 750
        if ($statusText -eq "FATAL") { throw }
        return
    }
}

function Show-SetupPlan {
    Write-Host ""
    Write-Host "Planned setup steps:" -ForegroundColor Cyan
    $total = [Math]::Max(1, $Script:SetupSteps.Count)
    for ($i = 0; $i -lt $Script:SetupSteps.Count; $i++) {
        $from = [int][Math]::Floor(($i / [double]$total) * 100)
        $to = [int][Math]::Floor((($i + 1) / [double]$total) * 100)
        Write-Host (("{0,2}. {1,-68} {2,3}% -> {3,3}%" -f ($i + 1), $Script:SetupSteps[$i].Name, $from, $to))
    }
    Write-Host ""
    Write-Host "Root: $DevRoot"
    Write-Host ("Script version: {0}" -f $Script:ScriptVersion)
    Write-Host ("Star Citizen tested builds: {0}" -f $Script:StarCitizenTestedBuildsDisplay)
    Write-Host "Workspace: $WorkspacePath"
    Write-Host "Banner style: author-selected ($(Resolve-ProgressBannerStyle))"
    if ($Script:HarnessMode) { Write-Host "Mode: safe non-live harness" -ForegroundColor Magenta }
    elseif ($Script:PlanOnly) { Write-Host "Mode: plan only" -ForegroundColor Magenta }
    elseif ($Script:HiddenDryRun) { Write-Host "Mode: visual preview" -ForegroundColor Magenta }
    elseif ($DryRun) { Write-Host "Mode: dry run" -ForegroundColor Yellow }
    if ($NoProgressHeader) { Write-Host "Progress header: disabled" } else { Write-Host "Progress header: enabled" }
}

function Get-SetupPlanSnapshot {
    $stepList = New-Object 'System.Collections.Generic.List[object]'
    for ($i = 0; $i -lt $Script:SetupSteps.Count; $i++) {
        [void]$stepList.Add([ordered]@{
            index = $i + 1
            id = [string]$Script:SetupSteps[$i].Id
            name = [string]$Script:SetupSteps[$i].Name
        })
    }
    return [ordered]@{
        generatedAt = (Get-Date).ToString('s')
        scriptVersion = [string]$Script:ScriptVersion
        starCitizenTestedBuilds = [string]$Script:StarCitizenTestedBuilds
        starCitizenTestedBuildsDisplay = [string]$Script:StarCitizenTestedBuildsDisplay
        harnessMode = [bool]$Script:HarnessMode
        planOnly = [bool]$Script:PlanOnly
        safety = [ordered]@{
            noExternalActions = [bool]$Script:NoExternalActions
            noNetwork = [bool]$Script:NoNetwork
            noGui = [bool]$Script:NoGui
            noUserEnvWrites = [bool]$Script:NoUserEnvWrites
            noGlobalGitConfig = [bool]$Script:NoGlobalGitConfig
        }
        paths = [ordered]@{
            originalDevRoot = [string]$Script:OriginalDevRoot
            devRoot = [string]$DevRoot
            harnessRoot = [string]$Script:HarnessRoot
            originalAgentWorkRoot = [string]$Script:OriginalAgentWorkRoot
            agentPromptsRoot = [string]$AgentPromptsRoot
            agentWorkRoot = [string]$Script:AgentWorkRoot
            agentOutputRoot = [string]$AgentOutputRoot
            agentReportsRoot = [string]$AgentReportsRoot
            starCitizenRoot = [string]$StarCitizenRoot
            scDataRoot = [string]$ScDataRoot
            scWorkRoot = [string]$ScWorkRoot
            workspacePath = [string]$WorkspacePath
            workspaceLaunchCmdPath = [string]$WorkspaceLaunchCmdPath
            guideRepoPath = [string]$GuideRepoPath
            setupStatePath = [string]$Script:SetupStatePath
        }
        steps = @($stepList.ToArray())
    }
}

function Write-SetupPlanJson {
    param([Parameter(Mandatory=$true)][string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return }
    Assert-HarnessPathAllowed -Path $Path -Purpose "plan JSON write"
    $snapshot = Get-SetupPlanSnapshot
    $json = [string]($snapshot | ConvertTo-Json -Depth 8)
    Write-InstallerFile -Path $Path -Text $json
    Write-Host "Plan JSON written: $Path" -ForegroundColor Green
}

function Confirm-SetupPlan {
    if ($AssumeYes -or $DryRun -or $ListSteps -or $Script:NoPause -or $Script:PlanOnly -or $Script:HarnessMode) { return }
    Write-Host ""
    Write-Host "Review the setup plan above. This can install tools and modify your user PATH/environment variables." -ForegroundColor Yellow
    $answer = Read-Host "Ready to launch? Type Y to launch or N to cancel"
    $choice = $answer.Trim().ToLowerInvariant()

    if ($choice -in @("y", "yes")) { return }

    throw "Setup cancelled before any installer steps were run. Re-run with -AssumeYes to skip this confirmation."
}

function Test-SetupPreflight {
    Register-SetupCancelHandler
    $Script:IsSandbox = Test-WindowsSandbox
    if ($Script:IsSandbox) {
        Write-Host "NOTE: Windows Sandbox detected." -ForegroundColor Yellow
        Write-Host "      This is a safe disposable test environment, but installs can be slower than normal hardware." -ForegroundColor Yellow
        Write-Host "      The dashboard WATCH lines will show whether real activity is happening." -ForegroundColor Yellow
    }
    Show-DevRootSpaceWarning
    if (-not [Environment]::Is64BitOperatingSystem) {
        throw "This setup expects 64-bit Windows."
    }

    if ($InstallTools -and (-not $DryRun) -and (-not $AllowNonAdmin) -and (-not (Test-IsAdmin))) {
        throw "Run PowerShell as Administrator for the installer phase, or re-run with -AllowNonAdmin if you accept possible installer failures."
    }

    $rootQualifier = Split-Path $DevRoot -Qualifier
    if ($rootQualifier -and (-not (Test-Path $rootQualifier))) {
        if ($DryRun) {
            Write-Warning "Drive/root does not exist: $rootQualifier. Dry-run mode will continue because no folders will be created."
        } else {
            throw "Drive/root does not exist: $rootQualifier. Re-run with -DevRoot C:\dev or another existing location."
        }
    }

    if ($DevRoot -match "(?i)onedrive|dropbox|google drive|icloud") {
        Write-Warning "DevRoot appears to be inside a sync folder. Large repos, build folders, and Data.p4k copies are safer in a non-synced folder such as D:\dev or E:\dev."
    }

    if ($DevRoot -match "['`"]") {
        Write-Warning "DevRoot contains quotes/apostrophes. Most paths are escaped, but build tools are more reliable with a simple path."
    }

    # v11: Disk space pre-flight. Build Tools alone burns ~10 GB on the system
    # drive; the tutorial's dev-root then needs room for clones, Node, Python venv,
    # exports, and Data.p4k staging. Better to fail in seconds than 30 minutes in.
    if ($InstallTools -and (-not $DryRun)) {
        $required = @(
            @{ Drive = (Split-Path ([Environment]::GetFolderPath('ProgramFilesX86')) -Qualifier); MinGB = 10; Reason = "Visual Studio Build Tools install" },
            @{ Drive = $rootQualifier;                                                              MinGB = 5;  Reason = "Dev root for clones, caches, and exports" }
        )
        # Deduplicate: if dev-root drive == system drive, only need the larger total
        $byDrive = @{}
        foreach ($r in $required) {
            $d = $r.Drive
            if ([string]::IsNullOrWhiteSpace($d)) { continue }
            $key = $d.TrimEnd('\').ToUpperInvariant()
            if (-not $byDrive.ContainsKey($key)) { $byDrive[$key] = @{ MinGB = 0; Reasons = New-Object 'System.Collections.Generic.List[string]' } }
            $byDrive[$key].MinGB += [int]$r.MinGB
            $byDrive[$key].Reasons.Add($r.Reason) | Out-Null
        }
        foreach ($key in $byDrive.Keys) {
            try {
                $driveLetter = $key.TrimEnd(':').TrimEnd('\').Substring(0,1)
                $drive = Get-PSDrive -Name $driveLetter -PSProvider FileSystem -ErrorAction Stop
                $freeGB = [Math]::Round($drive.Free / 1GB, 1)
                $needGB = $byDrive[$key].MinGB
                if ($freeGB -lt $needGB) {
                    $reasonsText = ($byDrive[$key].Reasons -join "; ")
                    throw ("Not enough free space on {0}\: {1} GB free, need ~{2} GB ({3}). Free up space or pick a different -DevRoot." -f $key, $freeGB, $needGB, $reasonsText)
                } else {
                    Write-Host ("Disk check OK on {0}\: {1} GB free (need ~{2} GB)" -f $key, $freeGB, $needGB) -ForegroundColor DarkGreen
                }
            } catch [System.Management.Automation.RuntimeException] {
                throw  # Re-throw our own "not enough space" error
            } catch {
                Write-Warning ("Could not check free space on {0}\: {1}" -f $key, $_.Exception.Message)
            }
        }
    }

    if ($RunAuroraExample -and [string]::IsNullOrWhiteSpace($DataP4kSource)) {
        $expectedP4k = Join-Path (Join-Path $ScP4kRoot $StarCitizenBuild) "Data.p4k"
        if (-not (Test-Path $expectedP4k)) {
            Write-Warning "-RunAuroraExample is enabled, but Data.p4k was not provided and was not found at $expectedP4k. The example will be skipped unless you add it first."
        }
    }

    if (-not [string]::IsNullOrWhiteSpace($DataP4kSource)) {
        if (-not (Test-Path -LiteralPath $DataP4kSource)) {
            if ($DryRun) {
                Write-Warning "DataP4kSource was not found, but dry-run mode will continue: $DataP4kSource"
            } else {
                throw "DataP4kSource was not found: $DataP4kSource"
            }
        }
    }
}

function Start-SetupTranscriptAndEnvironment {
    $logName = "setup-$((Get-Date).ToString('yyyyMMdd-HHmmss')).log"
    $Script:TranscriptLogPath = Join-Path $ScLogsRoot $logName
    if (-not $DryRun) {
        Start-Transcript -Path $Script:TranscriptLogPath -Append | Out-Null
        $Script:TranscriptStarted = $true
        Write-Host "Transcript log: $Script:TranscriptLogPath"
    }

    Set-UserEnv "SC_DEV_ROOT" (To-ForwardSlashPath $DevRoot)
    Set-UserEnv "SC_DATA_ROOT" (To-ForwardSlashPath $ScDataRoot)
    Set-UserEnv "SC_P4K_ROOT" (To-ForwardSlashPath $ScP4kRoot)
    Set-UserEnv "SC_EXPORT_ROOT" (To-ForwardSlashPath $ScExportRoot)
    Set-UserEnv "SC_WORK_ROOT" (To-ForwardSlashPath $ScWorkRoot)
    Set-AgentEnvironmentVariables -PersistUser:((-not $Script:NoUserEnvWrites) -and (-not (Test-NonLiveInstallerMode)))

    Write-Host "PowerShell: $($PSVersionTable.PSVersion)"
    Write-Host "Admin: $(Test-IsAdmin)"
    Write-Host "Computer: $env:COMPUTERNAME"
}

function Test-IsAdmin {
    $identity = [Security.Principal.WindowsIdentity]::GetCurrent()
    $principal = New-Object Security.Principal.WindowsPrincipal($identity)
    return $principal.IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)
}

function Ensure-Directory {
    param([Parameter(Mandatory=$true)][string]$Path)
    New-InstallerDirectory -Path $Path
}

function Normalize-PathEntry {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    return $Path.Trim().Trim('"').TrimEnd([char[]]@('\','/')).ToLowerInvariant()
}

function Set-UserEnv {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Value
    )
    Write-Host "Setting user environment variable $Name=$Value"
    if (-not $DryRun) {
        Set-InstallerUserEnvironmentVariable -Name $Name -Value $Value
        Set-Item -Path "Env:$Name" -Value $Value
    }
}

function Add-UserPath {
    param([Parameter(Mandatory=$true)][string]$Path)

    $target = Normalize-PathEntry $Path
    if ([string]::IsNullOrWhiteSpace($target)) { return }

    $userPath = [Environment]::GetEnvironmentVariable("Path", "User")
    if ($null -eq $userPath) { $userPath = "" }

    $parts = @()
    if (-not [string]::IsNullOrWhiteSpace($userPath)) {
        $parts = $userPath -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    }
    $exists = $false
    foreach ($part in $parts) {
        if ((Normalize-PathEntry $part) -eq $target) { $exists = $true; break }
    }

    if (-not $exists) {
        Write-Host "Adding to user PATH: $Path"
        if (-not $DryRun) {
            $newPath = if ([string]::IsNullOrWhiteSpace($userPath)) { $Path } else { "$userPath;$Path" }
            Set-InstallerUserEnvironmentVariable -Name "Path" -Value $newPath
        }
    } else {
        Write-Host "PATH already contains: $Path"
    }

    $currentParts = $env:Path -split ";" | Where-Object { -not [string]::IsNullOrWhiteSpace($_) }
    $currentExists = $false
    foreach ($part in $currentParts) {
        if ((Normalize-PathEntry $part) -eq $target) { $currentExists = $true; break }
    }
    if (-not $currentExists) {
        $env:Path = "$Path;$env:Path"
    }
}

function Format-CommandDisplay {
    param(
        [Parameter(Mandatory=$true)][string]$Exe,
        [string[]]$Arguments = @()
    )
    $display = $Exe
    if ($Arguments.Count -gt 0) { $display = "$Exe $($Arguments -join ' ')" }
    return $display
}

function Get-CommandLogPath {
    param([Parameter(Mandatory=$true)][string]$Exe)

    $Script:CommandLogCounter++
    $safeExe = [IO.Path]::GetFileNameWithoutExtension($Exe)
    if ([string]::IsNullOrWhiteSpace($safeExe)) { $safeExe = "command" }
    $safeExe = ($safeExe -replace '[^A-Za-z0-9_.-]', '_')
    $stamp = (Get-Date).ToString('yyyyMMdd-HHmmss')
    $name = "command-$stamp-$($Script:CommandLogCounter.ToString('000'))-$safeExe.log"

    $root = $ScLogsRoot
    if ([string]::IsNullOrWhiteSpace($root)) { $root = $env:TEMP }
    if (-not (Test-Path -LiteralPath $root)) {
        try { New-InstallerDirectory -Path $root } catch { $root = $env:TEMP }
    }
    Assert-HarnessPathAllowed -Path $root -Purpose "command log root"
    return (Join-Path $root $name)
}

function Get-SafeTextFileTail {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [int]$MaxLines = 10
    )
    if (-not (Test-Path -LiteralPath $Path)) { return @() }
    try {
        $fs = [System.IO.File]::Open($Path, [System.IO.FileMode]::Open, [System.IO.FileAccess]::Read, [System.IO.FileShare]::ReadWrite)
        try {
            $sr = New-Object System.IO.StreamReader($fs)
            try {
                $all = New-Object 'System.Collections.Generic.List[string]'
                while (-not $sr.EndOfStream) { [void]$all.Add($sr.ReadLine()) }
                $arr = @($all.ToArray())
                if ($arr.Count -le $MaxLines) { return $arr }
                return @($arr[($arr.Count - $MaxLines)..($arr.Count - 1)])
            } finally { $sr.Dispose() }
        } finally { $fs.Dispose() }
    } catch {
        return @()
    }
}

function Write-CommandTail {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [int]$MaxLines = 6
    )
    if (-not (Test-Path -LiteralPath $Path)) { return }
    try {
        $lines = @(Get-SafeTextFileTail -Path $Path -MaxLines $MaxLines)
        if ($lines.Count -gt 0) {
            Write-Host "    last command output:" -ForegroundColor DarkGray
            foreach ($line in $lines) {
                if (-not [string]::IsNullOrWhiteSpace($line)) {
                    Write-Host ("      " + $line) -ForegroundColor DarkGray
                }
            }
        }
    } catch { }
}

function Write-PhaseBanner {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [int]$StepNumber = 0,
        [string]$Status = "BEGIN"
    )

    if ($Script:VisualPreviewMode) { return }

    $total = [Math]::Max(1, $Script:SetupSteps.Count)
    $width = Get-ConsoleWidthSafe
    $ruleWidth = [Math]::Max(50, [Math]::Min(118, $width - 2))
    $rule = "=" * $ruleWidth
    $label = if ($StepNumber -gt 0) { "STEP $StepNumber/$total" } else { "SETUP" }

    Write-Host ""
    Write-Host $rule -ForegroundColor Cyan
    Write-Host ("  >>> {0} :: {1}" -f $label, $Name.ToUpperInvariant()) -ForegroundColor Yellow
    Write-Host ("      STATUS : {0}" -f $Status.ToUpperInvariant()) -ForegroundColor Cyan
    Write-Host $rule -ForegroundColor Cyan
    Write-Host ""
}

function Run-Native {
    param(
        [Parameter(Mandatory=$true)][string]$Exe,
        [string[]]$Arguments = @(),
        [switch]$IgnoreExitCode,
        [switch]$Interactive,
        [string]$ActivityNote = "",
        [string]$WorkingDirectory = ""
    )
    $display = Format-CommandDisplay -Exe $Exe -Arguments $Arguments
    if ($DryRun) { Write-Host "[dry-run] $display" -ForegroundColor DarkGray; return }
    Assert-InstallerExternalCommandAllowed -Exe $Exe -Arguments $Arguments -WorkingDirectory $WorkingDirectory

    $leaf = [IO.Path]::GetFileName($Exe)
    if ((Test-NonLiveInstallerMode) -and $leaf -match '^(?i:git(\.exe)?)$') {
        Write-Host "    harness git command: $display" -ForegroundColor DarkCyan
        if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) { Push-Location -LiteralPath $WorkingDirectory }
        try {
            $commandOutput = @(& $Exe @Arguments 2>&1)
            $exitCode = $LASTEXITCODE
            if ($null -eq $exitCode) { $exitCode = 0 }
        } finally {
            if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) { Pop-Location }
        }
        foreach ($line in @($commandOutput)) {
            if (-not [string]::IsNullOrWhiteSpace([string]$line)) { Write-Host ("      " + [string]$line) -ForegroundColor DarkGray }
        }
        if (($exitCode -ne 0) -and (-not $IgnoreExitCode)) {
            throw "Command failed with exit code ${exitCode}: $display"
        }
        return
    }

    if ($Interactive) {
        Write-Host "COMMAND:" -ForegroundColor Black -BackgroundColor DarkCyan
        Write-Host "  $display" -ForegroundColor Gray
        & $Exe @Arguments
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = 0 }
        if (($exitCode -ne 0) -and (-not $IgnoreExitCode)) {
            throw "Command failed with exit code ${exitCode}: $display"
        }
        return
    }

    $commandLog = Get-CommandLogPath -Exe $Exe
    $exitCode = Invoke-LoggedCommandJob -Exe $Exe -Arguments $Arguments -Display $display -CommandLog $commandLog -ActivityNote $ActivityNote -WorkingDirectory $WorkingDirectory

    if ($exitCode -eq 0) {
        Write-Host "    command completed successfully." -ForegroundColor Green
        Write-CommandTail -Path $commandLog -MaxLines 4
    } else {
        Write-Host "    command failed. See log: $commandLog" -ForegroundColor Red
        Write-CommandTail -Path $commandLog -MaxLines 12
    }

    if (($exitCode -ne 0) -and (-not $IgnoreExitCode)) {
        throw "Command failed with exit code ${exitCode}: $display"
    }
}

function Run-ProcessWait {
    param(
        [Parameter(Mandatory=$true)][string]$FilePath,
        [string[]]$ArgumentList = @(),
        [switch]$IgnoreExitCode,
        [string]$ActivityNote = "",
        [string]$WorkingDirectory = ""
    )
    $display = Format-CommandDisplay -Exe $FilePath -Arguments $ArgumentList
    if ($DryRun) { Write-Host "[dry-run] $display" -ForegroundColor DarkGray; return }
    Assert-InstallerExternalCommandAllowed -Exe $FilePath -Arguments $ArgumentList -WorkingDirectory $WorkingDirectory

    $commandLog = Get-CommandLogPath -Exe $FilePath
    $exitCode = Invoke-LoggedCommandJob -Exe $FilePath -Arguments $ArgumentList -Display $display -CommandLog $commandLog -ActivityNote $ActivityNote -WorkingDirectory $WorkingDirectory

    if ($exitCode -eq 0) {
        Write-Host "    process completed successfully." -ForegroundColor Green
        Write-CommandTail -Path $commandLog -MaxLines 4
    } else {
        Write-Host "    process finished with exit code $exitCode. See log: $commandLog" -ForegroundColor Yellow
        Write-CommandTail -Path $commandLog -MaxLines 12
    }

    if (($exitCode -ne 0) -and (-not $IgnoreExitCode)) {
        throw "Process failed with exit code ${exitCode}: $display"
    }
}

function Download-File {
    param(
        [Parameter(Mandatory=$true)][string]$Uri,
        [Parameter(Mandatory=$true)][string]$OutFile,
        [switch]$Force
    )
    if ((Test-Path $OutFile) -and (-not $Force)) {
        Write-Host "Already downloaded: $OutFile" -ForegroundColor DarkGray
        return
    }
    Write-Host "Downloading:" -ForegroundColor Cyan
    Write-Host "    from: $Uri" -ForegroundColor Gray
    Write-Host "      to: $OutFile" -ForegroundColor Gray
    if ($Script:NoNetwork -or (Test-NonLiveInstallerMode)) { throw "Non-live harness blocked download: $Uri" }
    if (-not $DryRun) {
        Ensure-Directory (Split-Path $OutFile -Parent)
        $oldProgress = $ProgressPreference
        try {
            $ProgressPreference = 'SilentlyContinue'
            Invoke-LoggedDownloadJob -Uri $Uri -OutFile $OutFile
            Write-Host "    download complete." -ForegroundColor Green
        } finally {
            $ProgressPreference = $oldProgress
        }
    }
}

function Require-Command {
    param([Parameter(Mandatory=$true)][string]$Name)
    $cmd = Get-Command $Name -ErrorAction SilentlyContinue
    if ($null -eq $cmd) {
        if ($DryRun) {
            Write-Host "[dry-run] Required command not found, but continuing preview: $Name" -ForegroundColor DarkGray
            return $Name
        }
        throw "Required command not found on PATH: $Name"
    }
    return $cmd.Source
}

function Test-WingetPackageInstalled {
    param([Parameter(Mandatory=$true)][string]$Id)
    if (-not (Get-Command winget -ErrorAction SilentlyContinue)) { return $false }
    if ($DryRun) { return $false }
    try {
        $output = @(& winget list --id $Id -e --source winget --accept-source-agreements 2>$null)
        $text = ($output -join "`n")
        return (($LASTEXITCODE -eq 0) -and ($text -match [regex]::Escape($Id)))
    } catch {
        return $false
    }
}

function Update-WingetPackageIfInstalled {
    param([Parameter(Mandatory=$true)][string]$Id)
    if (-not (Test-WingetPackageInstalled -Id $Id)) { return $false }
    Write-Host "WinGet package already appears to be installed: $Id" -ForegroundColor Green
    Write-Host "Checking whether WinGet has a newer version available for: $Id" -ForegroundColor DarkCyan
    Run-Native -Exe "winget" -Arguments @("upgrade", "--id", $Id, "-e", "--source", "winget", "--accept-package-agreements", "--accept-source-agreements", "--silent", "--disable-interactivity") -IgnoreExitCode -ActivityNote "WinGet is checking for, or applying, an update for $Id. If it is already current, this may finish quickly or report no available upgrade."
    return $true
}

function Test-CommandVersionAvailable {
    param(
        [Parameter(Mandatory=$true)][string]$Command,
        [string[]]$Arguments = @("--version")
    )
    $cmd = Get-Command $Command -ErrorAction SilentlyContinue
    if ($null -eq $cmd) { return $false }
    Run-Native -Exe $cmd.Source -Arguments $Arguments -IgnoreExitCode
    return $true
}

function Get-ExecutableOutputText {
    param(
        [Parameter(Mandatory=$true)][string]$Exe,
        [string[]]$Arguments = @("--version")
    )
    if (-not (Test-Path -LiteralPath $Exe) -and -not (Get-Command $Exe -ErrorAction SilentlyContinue)) { return "" }
    try {
        $output = @(& $Exe @Arguments 2>$null)
        return ($output -join "`n")
    } catch {
        return ""
    }
}

function Test-ExecutableOutputContains {
    param(
        [Parameter(Mandatory=$true)][string]$Exe,
        [Parameter(Mandatory=$true)][string]$Expected,
        [string[]]$Arguments = @("--version")
    )
    $text = Get-ExecutableOutputText -Exe $Exe -Arguments $Arguments
    if ([string]::IsNullOrWhiteSpace($text)) { return $false }
    return ($text -match [regex]::Escape($Expected))
}

function Install-WingetPackage {
    param(
        [Parameter(Mandatory=$true)][string]$Id,
        [string]$Override = "",
        [string]$Scope = ""
    )
    Require-Command "winget" | Out-Null

    if (Update-WingetPackageIfInstalled -Id $Id) {
        return
    }

    # v12: Renamed $args -> $wingetArgs. PowerShell's $args is an automatic
    # variable holding caller-passed arguments; assigning to it inside a
    # function shadows that and can break advanced binding scenarios.
    $wingetArgs = @(
        "install",
        "--id", $Id,
        "-e",
        "--source", "winget",
        "--accept-package-agreements",
        "--accept-source-agreements",
        "--silent",
        "--disable-interactivity"
    )
    if (-not [string]::IsNullOrWhiteSpace($Scope)) {
        $wingetArgs += @("--scope", $Scope)
    }
    if (-not [string]::IsNullOrWhiteSpace($Override)) {
        $wingetArgs += @("--override", $Override)
    }
    Run-Native -Exe "winget" -Arguments $wingetArgs
}


function Resolve-VSCodeCommandFromPath {
    param([string]$Path)

    if ([string]::IsNullOrWhiteSpace($Path)) { return $null }

    $clean = [Environment]::ExpandEnvironmentVariables($Path.Trim().Trim('"'))
    $candidates = @()

    $cmd = Get-Command $clean -ErrorAction SilentlyContinue
    if ($cmd) { $candidates += $cmd.Source }

    if (Test-Path -LiteralPath $clean) {
        $item = Get-Item -LiteralPath $clean -ErrorAction SilentlyContinue
        if ($null -ne $item) {
            if ($item.PSIsContainer) {
                # Accept either the VS Code root folder or its bin folder.
                $candidates += (Join-Path $item.FullName "code.cmd")
                $candidates += (Join-Path $item.FullName "bin\code.cmd")
            } else {
                # Accept a direct code.cmd path. If the user points at Code.exe, check the sibling bin folder.
                if ($item.Name -ieq "code.cmd") {
                    $candidates += $item.FullName
                } elseif ($item.Name -ieq "Code.exe") {
                    $candidates += (Join-Path (Split-Path $item.FullName -Parent) "bin\code.cmd")
                } else {
                    $candidates += $item.FullName
                }
            }
        }
    }

    foreach ($candidate in ($candidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)) {
        if (Test-Path -LiteralPath $candidate) {
            return (Resolve-Path -LiteralPath $candidate).Path
        }
    }

    return $null
}

function Test-VSCodeCommand {
    param([Parameter(Mandatory=$true)][string]$CodeCommand)

    if (-not (Test-Path -LiteralPath $CodeCommand)) {
        Write-Warning "VS Code CLI path does not exist: $CodeCommand"
        return $false
    }

    Write-Host "Validating VS Code CLI: $CodeCommand"
    if ($DryRun) {
        Write-Host "[dry-run] Would run: '$CodeCommand' --version"
        return $true
    }

    try {
        & $CodeCommand --version
        $exitCode = $LASTEXITCODE
        if ($null -eq $exitCode) { $exitCode = 0 }
        if ($exitCode -eq 0) {
            Write-Host "VS Code CLI validation succeeded."
            return $true
        }
        Write-Warning "VS Code CLI validation failed with exit code $exitCode."
        return $false
    } catch {
        Write-Warning "VS Code CLI validation failed: $($_.Exception.Message)"
        return $false
    }
}

function Find-VSCodeCommand {
    $codeCandidates = @()

    if (-not [string]::IsNullOrWhiteSpace($VSCodePath)) {
        $codeCandidates += $VSCodePath
    }

    $pathCommand = Get-Command "code.cmd" -ErrorAction SilentlyContinue
    if ($pathCommand) { $codeCandidates += $pathCommand.Source }

    $codeCandidates += @(
        (Join-Path $DevRoot "vscode\bin\code.cmd"),
        "C:\Program Files\Microsoft VS Code\bin\code.cmd",
        "C:\Program Files (x86)\Microsoft VS Code\bin\code.cmd",
        (Join-Path $env:LOCALAPPDATA "Programs\Microsoft VS Code\bin\code.cmd"),
        "C:\Microsoft VS Code\bin\code.cmd"
    )

    foreach ($candidate in ($codeCandidates | Where-Object { -not [string]::IsNullOrWhiteSpace($_) } | Select-Object -Unique)) {
        $resolved = Resolve-VSCodeCommandFromPath -Path $candidate
        if (-not [string]::IsNullOrWhiteSpace($resolved)) {
            if (Test-VSCodeCommand -CodeCommand $resolved) {
                return $resolved
            }
        }
    }

    return $null
}

function Read-VSCodeCommandUntilValid {
    if ($DryRun) {
        Write-Host "[dry-run] Would pause and prompt for a VS Code install folder or code.cmd path until validation succeeds."
        return $null
    }

    Write-Host ""
    Write-Host "VS Code setup checkpoint" -ForegroundColor Cyan
    Write-Host "Enter the folder where VS Code is installed, the VS Code bin folder, or the full path to code.cmd."
    Write-Host "Examples:"
    Write-Host "  C:\Program Files\Microsoft VS Code"
    Write-Host "  C:\Program Files\Microsoft VS Code\bin"
    Write-Host "  E:\Apps\Microsoft VS Code\bin\code.cmd"
    Write-Host "Press Enter to retry auto-detection. Type Q to cancel."

    while ($true) {
        $inputPath = Read-Host "VS Code folder or code.cmd path"

        if ([string]::IsNullOrWhiteSpace($inputPath)) {
            $autoDetected = Find-VSCodeCommand
            if (-not [string]::IsNullOrWhiteSpace($autoDetected)) {
                return $autoDetected
            }
            Write-Warning "Auto-detection did not find a valid VS Code CLI. Please enter the path manually."
            continue
        }

        if ($inputPath.Trim() -match '^(q|quit|exit)$') {
            throw "VS Code path validation was cancelled by the user."
        }

        $resolved = Resolve-VSCodeCommandFromPath -Path $inputPath
        if ([string]::IsNullOrWhiteSpace($resolved)) {
            Write-Warning "Could not find code.cmd from: $inputPath"
            Write-Host "Try the VS Code root folder, the VS Code bin folder, or the full path to code.cmd."
            continue
        }

        if (Test-VSCodeCommand -CodeCommand $resolved) {
            return $resolved
        }

        Write-Warning "That path did not validate. Please try another VS Code path."
    }
}

function Get-VSCodeCommandPath {
    param([switch]$PromptIfMissing)

    if (-not [string]::IsNullOrWhiteSpace($Script:VSCodeCommandPath)) {
        if (Test-Path -LiteralPath $Script:VSCodeCommandPath) {
            return $Script:VSCodeCommandPath
        }
    }

    $codeCmd = Find-VSCodeCommand
    if (-not [string]::IsNullOrWhiteSpace($codeCmd)) {
        $Script:VSCodeCommandPath = $codeCmd
        return $codeCmd
    }

    if ($PromptIfMissing -or $PromptForVSCodePath -or -not [string]::IsNullOrWhiteSpace($VSCodePath)) {
        $codeCmd = Read-VSCodeCommandUntilValid
        if (-not [string]::IsNullOrWhiteSpace($codeCmd)) {
            $Script:VSCodeCommandPath = $codeCmd
            return $codeCmd
        }
    }

    return $null
}

function Install-VSCodeArchiveIntoDevRoot {
    $vsCodeRoot = Join-Path $DevRoot "vscode"
    $codeCmd = Join-Path $vsCodeRoot "bin\code.cmd"

    if ((Test-Path $codeCmd) -and (Test-VSCodeCommand -CodeCommand $codeCmd)) {
        Write-Host "VS Code archive install already validates in the dev root: $codeCmd" -ForegroundColor Green
        return $codeCmd
    }

    $zip = Join-Path $InstallersRoot "vscode-win32-x64-archive-stable.zip"
    $extractRoot = Join-Path $InstallersRoot "vscode-extract"
    $url = "https://update.code.visualstudio.com/latest/win32-x64-archive/stable"
    Download-File -Uri $url -OutFile $zip

    if (-not $DryRun) {
        if (Test-Path $extractRoot) { Remove-Item $extractRoot -Recurse -Force }
        Expand-Archive -Path $zip -DestinationPath $extractRoot -Force
        $foundCode = Get-ChildItem $extractRoot -Recurse -Filter Code.exe | Select-Object -First 1
        if ($null -eq $foundCode) { throw "Could not find Code.exe after extracting VS Code archive: $zip" }
        $expandedRoot = Split-Path $foundCode.FullName -Parent
        if (Test-Path $vsCodeRoot) { Remove-Item $vsCodeRoot -Recurse -Force -ErrorAction SilentlyContinue }
        Ensure-Directory $vsCodeRoot
        Copy-Item "$expandedRoot\*" $vsCodeRoot -Recurse -Force
    }

    if (Test-Path $codeCmd) {
        if (-not (Test-VSCodeCommand -CodeCommand $codeCmd)) {
            throw "VS Code archive was extracted, but code.cmd did not validate: $codeCmd"
        }
        return $codeCmd
    }

    return $null
}

function Ensure-VSCodeAvailable {
    Write-SubStep "Installing or validating Visual Studio Code from the command line"

    $codeCmd = $null
    if (-not $PromptForVSCodePath) {
        # This honors -VSCodePath first, then PATH/default install locations, then the dev-root archive install.
        $codeCmd = Get-VSCodeCommandPath
    }

    if ([string]::IsNullOrWhiteSpace($codeCmd) -and (-not $SkipVSCodeInstall)) {
        $codeCmd = Install-VSCodeArchiveIntoDevRoot
    } elseif ($SkipVSCodeInstall) {
        Write-Host "Skipping VS Code installer because -SkipVSCodeInstall was provided."
    }

    if ([string]::IsNullOrWhiteSpace($codeCmd)) {
        $codeCmd = Read-VSCodeCommandUntilValid
    }

    if (-not [string]::IsNullOrWhiteSpace($codeCmd)) {
        $Script:VSCodeCommandPath = $codeCmd
        $codeBin = Split-Path $codeCmd -Parent
        Add-UserPath $codeBin
        Set-UserEnv "SC_VSCODE_CODE" $codeCmd
        Write-Host "Using VS Code CLI: $codeCmd"
    }

    return $codeCmd
}

function New-WorkFolders {
    Write-Step "Creating tutorial folder layout"

    $rootQualifier = Split-Path $DevRoot -Qualifier
    if ($rootQualifier -and (-not (Test-Path $rootQualifier))) {
        if ($DryRun) {
            Write-Warning "Drive/root does not exist: $rootQualifier. Dry-run mode will continue because no folders will be created."
        } else {
            throw "Drive/root does not exist: $rootQualifier. Re-run with -DevRoot C:\dev or another existing location."
        }
    }

    @(
        $DevRoot,
        $InstallersRoot,
        $GhRoot,
        $CargoHome,
        $RustupHome,
        $PythonInstallDir,
        $PipCacheDir,
        (Join-Path $PythonRoot "venvs"),
        $DotNetRoot,
        $CMakeRoot,
        $NodeRoot,
        $NpmCacheDir,
        $NpmGlobalDir,
        $ScDataRoot,
        $ScP4kRoot,
        $ScExportRoot,
        $ScWorkRoot,
        $ScLogsRoot,
        $StarCitizenRoot,
        $WorkspaceRoot
    ) | ForEach-Object { Ensure-Directory $_ }
}

function Test-InstallerNetworkAllowed {
    return (-not $Script:NoNetwork -and -not (Test-NonLiveInstallerMode))
}

function Test-LocalGitHubCli {
    param(
        [Parameter(Mandatory=$true)][string]$GhExe,
        [string]$VersionText = "",
        [int]$VersionExitCode = 0,
        [switch]$AssumeExists
    )
    $exists = [bool]$AssumeExists
    if (-not $exists) { $exists = Test-Path -LiteralPath $GhExe }
    $text = [string]$VersionText
    $exitCode = [int]$VersionExitCode
    $reason = ""

    if (-not $exists) {
        return [pscustomobject]@{ Exists=$false; Valid=$false; VersionText=""; Version=""; Reason="GitHub CLI was not found at $GhExe" }
    }
    if ([string]::IsNullOrWhiteSpace($text)) {
        if (Test-NonLiveInstallerMode) {
            return [pscustomobject]@{ Exists=$true; Valid=$false; VersionText=""; Version=""; Reason="Non-live mode did not execute gh.exe for validation." }
        }
        try {
            $output = @(& $GhExe --version 2>&1)
            $exitCode = $LASTEXITCODE
            if ($null -eq $exitCode) { $exitCode = 0 }
            $text = ($output -join "`n")
        } catch {
            $reason = $_.Exception.Message
        }
    }

    $version = ""
    if ($text -match '(?im)^gh\s+version\s+([0-9][^\s]*)') { $version = $Matches[1] }
    $valid = (($exitCode -eq 0) -and (-not [string]::IsNullOrWhiteSpace($text)) -and ($text -match '(?im)^gh\s+version\s+'))
    if (-not $valid -and [string]::IsNullOrWhiteSpace($reason)) { $reason = "gh --version did not return a valid GitHub CLI version." }
    return [pscustomobject]@{ Exists=$exists; Valid=$valid; VersionText=$text; Version=$version; Reason=$reason }
}

function Resolve-GitHubCliInstallDecision {
    param(
        [bool]$LocalExists,
        [bool]$LocalValid,
        [string]$LocalVersion = "",
        [bool]$NetworkAllowed = $false,
        [string]$Reason = ""
    )
    if ($LocalExists -and $LocalValid) {
        return [pscustomobject]@{
            Status="ValidLocal"; LocalValidated=$true; InstallNeeded=$false; NetworkLookupNeeded=$false; NetworkBlocked=$false
            Version=$LocalVersion; Reason="Existing dev-root GitHub CLI validated locally."
        }
    }
    if (-not $NetworkAllowed) {
        $why = if ([string]::IsNullOrWhiteSpace($Reason)) { "GitHub CLI install/update is needed, but network or external actions are disabled." } else { $Reason }
        return [pscustomobject]@{
            Status="NetworkBlocked"; LocalValidated=$false; InstallNeeded=$true; NetworkLookupNeeded=$false; NetworkBlocked=$true
            Version=$LocalVersion; Reason=$why
        }
    }
    $installReason = if ($LocalExists) { "Existing dev-root GitHub CLI did not validate; install/update is needed." } else { "GitHub CLI is missing from the dev root; install is needed." }
    if (-not [string]::IsNullOrWhiteSpace($Reason)) { $installReason = $Reason }
    return [pscustomobject]@{
        Status="InstallNeeded"; LocalValidated=$false; InstallNeeded=$true; NetworkLookupNeeded=$true; NetworkBlocked=$false
        Version=$LocalVersion; Reason=$installReason
    }
}

function Install-GitHubCliIntoDevRoot {
    Write-SubStep "Installing or validating GitHub CLI into $GhRoot"
    $extractRoot = Join-Path $InstallersRoot "gh-extract"
    $ghExe = Join-Path $GhRoot "bin\gh.exe"

    $localGh = Test-LocalGitHubCli -GhExe $ghExe
    $decision = Resolve-GitHubCliInstallDecision -LocalExists ([bool]$localGh.Exists) -LocalValid ([bool]$localGh.Valid) -LocalVersion ([string]$localGh.Version) -NetworkAllowed (Test-InstallerNetworkAllowed) -Reason ([string]$localGh.Reason)
    if ([bool]$decision.LocalValidated) {
        Write-Host ("GitHub CLI already validates in the dev root: {0} ({1})" -f $ghExe, [string]$decision.Version) -ForegroundColor Green
        Set-ToolState -Name "gh" -Status "ValidLocal" -Path $ghExe -Version ([string]$decision.Version) -Source "dev-root" -Reason ([string]$decision.Reason) -LocalValidated $true
        Add-UserPath (Join-Path $GhRoot "bin")
        return
    }

    Set-ToolState -Name "gh" -Status ([string]$decision.Status) -Path $ghExe -Version ([string]$decision.Version) -Source "dev-root" -Reason ([string]$decision.Reason) -InstallNeeded ([bool]$decision.InstallNeeded) -NetworkLookupNeeded ([bool]$decision.NetworkLookupNeeded) -NetworkBlocked ([bool]$decision.NetworkBlocked)

    if ($DryRun) {
        Write-Host "[dry-run] Would install/update gh.exe into $GhRoot only if local validation fails."
        return
    }
    if ([bool]$decision.NetworkBlocked) {
        $Script:CurrentStepResultStatus = "FAILED"
        $Script:CurrentStepResultReason = [string]$decision.Reason
        return
    }

    $ghRelease = Invoke-RestMethod "https://api.github.com/repos/cli/cli/releases/latest"
    $ghAsset = $ghRelease.assets | Where-Object { $_.name -like "gh_*_windows_amd64.zip" } | Select-Object -First 1
    if ($null -eq $ghAsset) { throw "Could not find a gh_*_windows_amd64.zip asset in the latest GitHub CLI release." }

    $latestTag = [string]$ghRelease.tag_name
    if (Test-Path $ghExe) {
        Write-Host "GitHub CLI exists but did not validate locally. Updating the dev-root copy to $latestTag." -ForegroundColor Yellow
    }

    $archive = Join-Path $InstallersRoot $ghAsset.name
    Download-File -Uri $ghAsset.browser_download_url -OutFile $archive

    if (Test-Path $extractRoot) { Remove-Item $extractRoot -Recurse -Force }
    Expand-Archive -Path $archive -DestinationPath $extractRoot -Force

    $foundGh = Get-ChildItem $extractRoot -Recurse -Filter gh.exe | Select-Object -First 1
    if ($null -eq $foundGh) { throw "Could not find gh.exe after extracting $archive" }

    $ghReleaseRoot = Split-Path (Split-Path $foundGh.FullName -Parent) -Parent
    if (Test-Path $GhRoot) { Remove-Item (Join-Path $GhRoot "*") -Recurse -Force -ErrorAction SilentlyContinue }
    Copy-Item "$ghReleaseRoot\*" $GhRoot -Recurse -Force

    Add-UserPath (Join-Path $GhRoot "bin")
    Run-Native -Exe (Join-Path $GhRoot "bin\gh.exe") -Arguments @("--version")
    Set-ToolState -Name "gh" -Status "Installed" -Path (Join-Path $GhRoot "bin\gh.exe") -Version $latestTag -Source "download" -Reason "Installed GitHub CLI from latest GitHub release." -LocalValidated $false -InstallNeeded $true -NetworkLookupNeeded $true
}

function Get-PythonSeriesFromVersion {
    param([string]$VersionText)
    if ([string]::IsNullOrWhiteSpace($VersionText)) { return "3.12" }
    if ($VersionText -match '^(\d+\.\d+)') { return $Matches[1] }
    return "3.12"
}

function Test-PythonSeriesInstalled {
    param(
        [Parameter(Mandatory=$true)][string]$PythonExe,
        [Parameter(Mandatory=$true)][string]$Series
    )
    if (-not (Test-Path -LiteralPath $PythonExe)) { return $false }
    $text = Get-ExecutableOutputText -Exe $PythonExe -Arguments @("--version")
    if ([string]::IsNullOrWhiteSpace($text)) { return $false }
    return ($text -match ("Python\s+" + [regex]::Escape($Series) + "\."))
}

function Test-PythonInstallerUrl {
    param([Parameter(Mandatory=$true)][string]$Url)
    if ($Script:NoNetwork -or (Test-NonLiveInstallerMode)) { return $false }
    try {
        $old = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        try {
            $response = Invoke-WebRequest -Uri $Url -Method Head -UseBasicParsing -TimeoutSec 20
            return ($response.StatusCode -ge 200 -and $response.StatusCode -lt 400)
        } finally {
            $ProgressPreference = $old
        }
    } catch {
        return $false
    }
}

function Resolve-PythonWindowsInstallerVersion {
    param(
        [Parameter(Mandatory=$true)][string]$RequestedVersion,
        [Parameter(Mandatory=$true)][string]$Series
    )

    $candidates = New-Object 'System.Collections.Generic.List[string]'
    if ($RequestedVersion -match '^\d+\.\d+\.\d+$') { [void]$candidates.Add($RequestedVersion) }

    Write-Host "Resolving newest available Windows x64 Python installer for series $Series..." -ForegroundColor DarkCyan
    if ($Script:NoNetwork -or (Test-NonLiveInstallerMode)) {
        return ($candidates | Select-Object -First 1)
    }

    try {
        $old = $ProgressPreference
        $ProgressPreference = 'SilentlyContinue'
        try {
            $windowsPage = Invoke-WebRequest -Uri "https://www.python.org/downloads/windows/" -UseBasicParsing -TimeoutSec 30
            $html = [string]$windowsPage.Content
            $pattern = '(?i)(?:https://www\.python\.org)?/ftp/python/(' + [regex]::Escape($Series) + '\.\d+)/python-\1-amd64\.exe'
            foreach ($m in [regex]::Matches($html, $pattern)) {
                $ver = $m.Groups[1].Value
                if (-not [string]::IsNullOrWhiteSpace($ver)) { [void]$candidates.Add($ver) }
            }
        } finally {
            $ProgressPreference = $old
        }
    } catch {
        Write-Warning "Could not read Python.org Windows releases page: $($_.Exception.Message)"
    }

    if ($RequestedVersion -match '^(\d+)\.(\d+)\.(\d+)$') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        $patch = [int]$Matches[3]
        for ($p = $patch; $p -ge 0; $p--) {
            [void]$candidates.Add(("{0}.{1}.{2}" -f $major, $minor, $p))
        }
    } elseif ($RequestedVersion -match '^(\d+)\.(\d+)$') {
        $major = [int]$Matches[1]
        $minor = [int]$Matches[2]
        for ($p = 40; $p -ge 0; $p--) {
            [void]$candidates.Add(("{0}.{1}.{2}" -f $major, $minor, $p))
        }
    }

    $unique = @($candidates | Where-Object { $_ -match ('^' + [regex]::Escape($Series) + '\.\d+$') } | Select-Object -Unique | Sort-Object { [version]$_ } -Descending)
    foreach ($ver in $unique) {
        $url = "https://www.python.org/ftp/python/$ver/python-$ver-amd64.exe"
        Write-Host "  checking Python $ver Windows installer..." -ForegroundColor DarkGray
        if (Test-PythonInstallerUrl -Url $url) {
            return [pscustomobject]@{ Version = $ver; Url = $url }
        }
    }

    return $null
}

function Get-PythonInstalledVersion {
    param([Parameter(Mandatory=$true)][string]$PythonExe)
    if (-not (Test-Path -LiteralPath $PythonExe)) { return $null }
    $text = Get-ExecutableOutputText -Exe $PythonExe -Arguments @("--version")
    if ($text -match 'Python\s+(\d+\.\d+\.\d+)') {
        try { return [version]$Matches[1] } catch { return $null }
    }
    return $null
}

function Test-PythonVersionMatchesRequest {
    param(
        [Parameter(Mandatory=$true)]$InstalledVersion,
        [Parameter(Mandatory=$true)][string]$RequestedVersion
    )
    $installed = $null
    try {
        if ($InstalledVersion -is [version]) { $installed = $InstalledVersion } else { $installed = [version]([string]$InstalledVersion) }
    } catch { return $false }

    $series = Get-PythonSeriesFromVersion -VersionText $RequestedVersion
    $installedSeries = ("{0}.{1}" -f $installed.Major, $installed.Minor)
    if ($installedSeries -ne $series) { return $false }
    return $true
}

function Test-LocalPythonInstall {
    param(
        [Parameter(Mandatory=$true)][string]$PythonExe,
        [Parameter(Mandatory=$true)][string]$RequestedVersion,
        [string]$VersionText = "",
        [int]$VersionExitCode = 0,
        [switch]$AssumeExists
    )
    $exists = [bool]$AssumeExists
    if (-not $exists) { $exists = Test-Path -LiteralPath $PythonExe }
    $text = [string]$VersionText
    $exitCode = [int]$VersionExitCode
    $reason = ""

    if (-not $exists) {
        return [pscustomobject]@{ Exists=$false; Valid=$false; Version=$null; VersionText=""; Reason="Python was not found at $PythonExe" }
    }
    if ([string]::IsNullOrWhiteSpace($text)) {
        if (Test-NonLiveInstallerMode) {
            return [pscustomobject]@{ Exists=$true; Valid=$false; Version=$null; VersionText=""; Reason="Non-live mode did not execute python.exe for validation." }
        }
        try {
            $output = @(& $PythonExe --version 2>&1)
            $exitCode = $LASTEXITCODE
            if ($null -eq $exitCode) { $exitCode = 0 }
            $text = ($output -join "`n")
        } catch {
            $reason = $_.Exception.Message
        }
    }

    $installedVersion = $null
    if ($text -match 'Python\s+(\d+\.\d+\.\d+)') {
        try { $installedVersion = [version]$Matches[1] } catch { $installedVersion = $null }
    }
    $valid = (($exitCode -eq 0) -and ($null -ne $installedVersion) -and (Test-PythonVersionMatchesRequest -InstalledVersion $installedVersion -RequestedVersion $RequestedVersion))
    if (-not $valid -and [string]::IsNullOrWhiteSpace($reason)) {
        $series = Get-PythonSeriesFromVersion -VersionText $RequestedVersion
        if ($null -eq $installedVersion) {
            $reason = "python --version did not return a parseable Python version."
        } else {
            $reason = "Local Python $installedVersion does not satisfy requested Python $RequestedVersion ($series series)."
        }
    }
    return [pscustomobject]@{ Exists=$exists; Valid=$valid; Version=$installedVersion; VersionText=$text; Reason=$reason }
}

function Resolve-PythonInstallDecision {
    param(
        [bool]$LocalExists,
        [bool]$LocalValid,
        $LocalVersion = $null,
        [bool]$NetworkAllowed = $false,
        [string]$Reason = ""
    )
    $versionText = if ($null -eq $LocalVersion) { "" } else { [string]$LocalVersion }
    if ($LocalExists -and $LocalValid) {
        return [pscustomobject]@{
            Status="ValidLocal"; LocalValidated=$true; InstallNeeded=$false; NetworkLookupNeeded=$false; NetworkBlocked=$false
            Version=$versionText; Reason="Existing dev-root Python validated locally."
        }
    }
    if (-not $NetworkAllowed) {
        $why = if ([string]::IsNullOrWhiteSpace($Reason)) { "Python install/update is needed, but network or external actions are disabled." } else { $Reason }
        return [pscustomobject]@{
            Status="NetworkBlocked"; LocalValidated=$false; InstallNeeded=$true; NetworkLookupNeeded=$false; NetworkBlocked=$true
            Version=$versionText; Reason=$why
        }
    }
    $installReason = if ($LocalExists) { "Existing dev-root Python did not satisfy the requested version; install/update is needed." } else { "Python is missing from the dev root; install is needed." }
    if (-not [string]::IsNullOrWhiteSpace($Reason)) { $installReason = $Reason }
    return [pscustomobject]@{
        Status="InstallNeeded"; LocalValidated=$false; InstallNeeded=$true; NetworkLookupNeeded=$true; NetworkBlocked=$false
        Version=$versionText; Reason=$installReason
    }
}

function Resolve-PythonVenvDecision {
    param(
        [bool]$VenvExists,
        [bool]$VenvPythonValid
    )
    if ($VenvExists -and $VenvPythonValid) {
        return [pscustomobject]@{ Status="Valid"; Action="None"; UsesLocalPython=$true; NetworkLookupNeeded=$false; Reason="Shared Python venv validated locally." }
    }
    if (-not $VenvExists) {
        return [pscustomobject]@{ Status="CreateLocal"; Action="Create"; UsesLocalPython=$true; NetworkLookupNeeded=$false; Reason="Shared Python venv is missing and can be created with local Python." }
    }
    return [pscustomobject]@{ Status="RepairLocal"; Action="Repair"; UsesLocalPython=$true; NetworkLookupNeeded=$false; Reason="Shared Python venv exists but did not validate and can be repaired with local Python." }
}

function Ensure-PythonSharedVenv {
    param(
        [Parameter(Mandatory=$true)][string]$PythonExe,
        [Parameter(Mandatory=$true)][string]$VenvDir,
        [Parameter(Mandatory=$true)][string]$Series
    )
    $venvPy = Join-Path $VenvDir "Scripts\python.exe"
    $venvExists = Test-Path -LiteralPath $VenvDir
    $venvPythonValid = $false
    if ($venvExists -and (Test-Path -LiteralPath $venvPy)) {
        $venvPythonValid = Test-PythonSeriesInstalled -PythonExe $venvPy -Series $Series
    }
    $decision = Resolve-PythonVenvDecision -VenvExists $venvExists -VenvPythonValid $venvPythonValid
    if ([string]$decision.Action -ne "None") {
        Write-Host ([string]$decision.Reason) -ForegroundColor DarkCyan
        Run-Native -Exe $PythonExe -Arguments @("-m", "venv", $VenvDir) -ActivityNote "Creating or repairing the shared Python virtual environment."
    } else {
        Write-Host "Python venv already validates locally: $VenvDir" -ForegroundColor Green
    }
    if (-not (Test-Path -LiteralPath $venvPy)) { throw "Python virtual environment was not found after validation/creation: $venvPy" }
    Run-Native -Exe $venvPy -Arguments @("--version") -IgnoreExitCode
    Run-Native -Exe $venvPy -Arguments @("-m", "pip", "check") -IgnoreExitCode
    return $decision
}

function Install-PythonIntoDevRoot {
    $pythonSeries = Get-PythonSeriesFromVersion -VersionText $PythonVersion
    Write-SubStep "Installing or validating Python $pythonSeries into $PythonInstallDir"
    $py = Join-Path $PythonInstallDir "python.exe"

    $localPython = Test-LocalPythonInstall -PythonExe $py -RequestedVersion $PythonVersion
    $decision = Resolve-PythonInstallDecision -LocalExists ([bool]$localPython.Exists) -LocalValid ([bool]$localPython.Valid) -LocalVersion $localPython.Version -NetworkAllowed (Test-InstallerNetworkAllowed) -Reason ([string]$localPython.Reason)

    if ([bool]$decision.LocalValidated) {
        Write-Host ("Python {0} already validates in the dev root: {1}" -f [string]$decision.Version, $py) -ForegroundColor Green
        Add-UserPath $PythonInstallDir
        Add-UserPath (Join-Path $PythonInstallDir "Scripts")
        Set-UserEnv "PIP_CACHE_DIR" $PipCacheDir
        $venvDecision = if (-not $DryRun) { Ensure-PythonSharedVenv -PythonExe $py -VenvDir $PythonVenvDir -Series $pythonSeries } else { Resolve-PythonVenvDecision -VenvExists $false -VenvPythonValid $false }
        Set-ToolState -Name "python" -Status "ValidLocal" -Path $py -Version ([string]$decision.Version) -Source "dev-root" -Reason ([string]$decision.Reason) -LocalValidated $true -VenvStatus ([string]$venvDecision.Status)
        return
    }

    Set-ToolState -Name "python" -Status ([string]$decision.Status) -Path $py -Version ([string]$decision.Version) -Source "dev-root" -Reason ([string]$decision.Reason) -InstallNeeded ([bool]$decision.InstallNeeded) -NetworkLookupNeeded ([bool]$decision.NetworkLookupNeeded) -NetworkBlocked ([bool]$decision.NetworkBlocked)
    if ([bool]$decision.NetworkBlocked) {
        $Script:CurrentStepResultStatus = "FAILED"
        $Script:CurrentStepResultReason = [string]$decision.Reason
        return
    }
    if ($DryRun) {
        Write-Host "[dry-run] Would install/update Python into $PythonInstallDir only if local validation fails."
        return
    }

    $candidate = Resolve-PythonWindowsInstallerVersion -RequestedVersion $PythonVersion -Series $pythonSeries
    if ($null -eq $candidate) {
        throw "Could not find a downloadable Windows x64 installer for Python $pythonSeries.x on Python.org."
    }

    if ($candidate.Version -ne $PythonVersion) {
        Write-Host ("Requested Python {0} has no usable Windows x64 installer. Selected newest available installer in the {1} series: Python {2}." -f $PythonVersion, $pythonSeries, $candidate.Version) -ForegroundColor Yellow
    } else {
        Write-Host "Selected Python installer version: $($candidate.Version)" -ForegroundColor Green
    }

    $installer = Join-Path $InstallersRoot "python-$($candidate.Version)-amd64.exe"
    Download-File -Uri $candidate.Url -OutFile $installer

    $installerArgs = @(
        "/quiet",
        "InstallAllUsers=0",
        "TargetDir=$PythonInstallDir",
        "Include_pip=1",
        "Include_launcher=1",
        "InstallLauncherAllUsers=0",
        "PrependPath=0",
        "Include_test=0",
        "Shortcuts=0"
    )
    Run-ProcessWait -FilePath $installer -ArgumentList $installerArgs -ActivityNote "Installing Python $($candidate.Version) into the selected dev root."

    Add-UserPath $PythonInstallDir
    Add-UserPath (Join-Path $PythonInstallDir "Scripts")
    Set-UserEnv "PIP_CACHE_DIR" $PipCacheDir

    if (-not $DryRun) {
        if (-not (Test-Path $py)) { throw "Python was not found after install: $py" }
        if (-not (Test-PythonSeriesInstalled -PythonExe $py -Series $pythonSeries)) {
            throw "Python exists but did not validate as Python $pythonSeries.x: $py"
        }
        Run-Native -Exe $py -Arguments @("--version")

        $venvDecision = Ensure-PythonSharedVenv -PythonExe $py -VenvDir $PythonVenvDir -Series $pythonSeries
        $venvPy = Join-Path $PythonVenvDir "Scripts\python.exe"
        if (Test-InstallerNetworkAllowed) {
            Run-Native -Exe $venvPy -Arguments @("-m", "pip", "install", "--upgrade", "pip", "setuptools", "wheel")
        }
        Set-ToolState -Name "python" -Status "Installed" -Path $py -Version ([string]$candidate.Version) -Source "download" -Reason "Installed Python from Python.org Windows installer." -LocalValidated $false -InstallNeeded $true -NetworkLookupNeeded $true -VenvStatus ([string]$venvDecision.Status)
    }
}

function Test-DotNetSdkChannelInstalled {
    param(
        [Parameter(Mandatory=$true)][string]$DotNetExe,
        [Parameter(Mandatory=$true)][string]$ChannelPrefix
    )
    if (-not (Test-Path -LiteralPath $DotNetExe)) { return $false }
    try {
        $sdks = @(& $DotNetExe --list-sdks 2>$null)
        if ($null -eq $sdks -or $sdks.Count -eq 0) { return $false }
        $prefixPattern = '^\s*' + [regex]::Escape($ChannelPrefix)
        foreach ($sdkLine in $sdks) {
            if ([string]$sdkLine -match $prefixPattern) { return $true }
        }
        return $false
    } catch { return $false }
}

function Install-DotNetIntoDevRoot {
    Write-SubStep "Installing or validating .NET SDK channels 8.0 and 9.0 into $DotNetRoot"
    $scriptPath = Join-Path $InstallersRoot "dotnet-install.ps1"
    $dotnet = Join-Path $DotNetRoot "dotnet.exe"
    Ensure-Directory $DotNetRoot

    # Validate before attempting any download. v21 could miss the second SDK
    # line from --list-sdks and falsely try to download dotnet-install.ps1.
    $has8Before = Test-DotNetSdkChannelInstalled -DotNetExe $dotnet -ChannelPrefix "8."
    $has9Before = Test-DotNetSdkChannelInstalled -DotNetExe $dotnet -ChannelPrefix "9."

    if ($has8Before -and $has9Before) {
        Write-Host ".NET SDK 8.x and 9.x already validate in $DotNetRoot; skipping install." -ForegroundColor Green
        Set-UserEnv "DOTNET_ROOT" $DotNetRoot
        Add-UserPath $DotNetRoot
        Run-Native -Exe $dotnet -Arguments @("--info") -IgnoreExitCode
        if (-not ((Test-DotNetSdkChannelInstalled -DotNetExe $dotnet -ChannelPrefix "8.") -and (Test-DotNetSdkChannelInstalled -DotNetExe $dotnet -ChannelPrefix "9."))) {
            throw ".NET validation failed after pre-check even though SDKs appeared present."
        }
        return
    }

    try {
        Download-File -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile $scriptPath -Force
    } catch {
        if ((Test-DotNetSdkChannelInstalled -DotNetExe $dotnet -ChannelPrefix "8.") -and (Test-DotNetSdkChannelInstalled -DotNetExe $dotnet -ChannelPrefix "9.")) {
            Write-Warning "dotnet-install.ps1 download failed, but .NET 8.x and 9.x already validate locally. Continuing."
            Set-UserEnv "DOTNET_ROOT" $DotNetRoot
            Add-UserPath $DotNetRoot
            Run-Native -Exe $dotnet -Arguments @("--info") -IgnoreExitCode
            return
        }
        throw
    }

    if (-not $has8Before) {
        Run-Native -Exe "powershell.exe" -Arguments @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $scriptPath, "-Channel", "8.0", "-InstallDir", $DotNetRoot)
    } else {
        Write-Host ".NET SDK 8.x already exists in $DotNetRoot; skipping channel install." -ForegroundColor Green
    }

    if (-not $has9Before) {
        Run-Native -Exe "powershell.exe" -Arguments @("-NoProfile", "-ExecutionPolicy", "Bypass", "-File", $scriptPath, "-Channel", "9.0", "-InstallDir", $DotNetRoot)
    } else {
        Write-Host ".NET SDK 9.x already exists in $DotNetRoot; skipping channel install." -ForegroundColor Green
    }

    Set-UserEnv "DOTNET_ROOT" $DotNetRoot
    Add-UserPath $DotNetRoot

    if (-not (Test-Path -LiteralPath $dotnet)) {
        throw ".NET install/validation failed: dotnet.exe was not found at $dotnet"
    }

    Run-Native -Exe $dotnet -Arguments @("--info") -IgnoreExitCode
    $has8After = Test-DotNetSdkChannelInstalled -DotNetExe $dotnet -ChannelPrefix "8."
    $has9After = Test-DotNetSdkChannelInstalled -DotNetExe $dotnet -ChannelPrefix "9."
    if (-not ($has8After -and $has9After)) {
        $list = ""
        try { $list = (@(& $dotnet --list-sdks 2>$null) -join "; ") } catch { $list = "<could not read SDK list>" }
        throw ".NET validation failed after install. Need SDK 8.x and 9.x in $DotNetRoot. Detected SDKs: $list"
    }
    Write-Host ".NET SDK validation complete: 8.x and 9.x are available." -ForegroundColor Green
}

function Install-CMakeIntoDevRoot {
    Write-SubStep "Installing CMake $CMakeVersion into $CMakeRoot"
    $cmakeExe = Join-Path $CMakeRoot "bin\cmake.exe"
    if (Test-Path $cmakeExe) {
        if (Test-ExecutableOutputContains -Exe $cmakeExe -Expected $CMakeVersion -Arguments @("--version")) {
            Write-Host "CMake $CMakeVersion already appears to be installed: $cmakeExe" -ForegroundColor Green
            Add-UserPath (Join-Path $CMakeRoot "bin")
            Run-Native -Exe $cmakeExe -Arguments @("--version") -IgnoreExitCode
            return
        }
        Write-Warning "CMake exists but does not appear to be the requested version $CMakeVersion. Replacing the dev-root CMake folder."
        if (-not $DryRun) { Remove-Item -LiteralPath $CMakeRoot -Recurse -Force -ErrorAction SilentlyContinue; Ensure-Directory $CMakeRoot }
    }

    $archiveName = "cmake-$CMakeVersion-windows-x86_64.zip"
    $archive = Join-Path $InstallersRoot $archiveName
    $url = "https://github.com/Kitware/CMake/releases/download/v$CMakeVersion/$archiveName"
    $extractRoot = Join-Path $InstallersRoot "cmake-extract"

    Download-File -Uri $url -OutFile $archive
    if (-not $DryRun) {
        if (Test-Path $extractRoot) { Remove-Item $extractRoot -Recurse -Force }
        Expand-Archive -Path $archive -DestinationPath $extractRoot -Force
        $expanded = Get-ChildItem $extractRoot -Directory | Select-Object -First 1
        if ($null -eq $expanded) { throw "Could not find extracted CMake root in $extractRoot" }
        Copy-Item "$($expanded.FullName)\*" $CMakeRoot -Recurse -Force
    }

    Add-UserPath (Join-Path $CMakeRoot "bin")
    if (Test-Path $cmakeExe) { Run-Native -Exe $cmakeExe -Arguments @("--version") }
}

function Show-VSBuildToolsWaitingRoom {
    # v12: A beginner-friendly explainer that fires ONCE before the VS Installer
    # GUI appears. The single biggest UX complaint from sandbox/4GB-RAM testing:
    # the Installer GUI opens and then sits at "Starting download operation 0%"
    # / "Starting install operation 0%" for 1-3 minutes before it does anything
    # visible. Without context, a beginner thinks the installer is frozen and
    # closes everything, requiring the full reinstall cycle. This page tells
    # them up front exactly what to expect, in plain language, with a short
    # countdown so they have time to read it.

    Write-Host ""
    Write-Host "===========================================================================" -ForegroundColor Yellow
    Write-Host "  HEADS UP: VISUAL STUDIO BUILD TOOLS IS THE LONGEST STEP - PLEASE READ" -ForegroundColor Yellow
    Write-Host "===========================================================================" -ForegroundColor Yellow
    Write-Host ""
    Write-Host "  What is about to happen, in order:" -ForegroundColor White
    Write-Host ""
    Write-Host "  1) A 'Visual Studio Installer' window will open in a moment." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  2) THAT WINDOW WILL SHOW 0% FOR 1 TO 3 MINUTES BEFORE IT MOVES." -ForegroundColor Cyan
    Write-Host "     This is normal Microsoft installer warm-up. It is NOT frozen." -ForegroundColor Gray
    Write-Host "     Look at the WATCH lines in THIS console window for proof of real" -ForegroundColor Gray
    Write-Host "     activity (package cache size growing, log writes within seconds)." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  3) Once downloads start, you will see 'Downloading and verifying'." -ForegroundColor Gray
    Write-Host "     Total download is roughly 1.5-2 GB. Time depends on your connection." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  4) Then 'Installing: package N of ~340'. Some packages (especially" -ForegroundColor Gray
    Write-Host "     large MSIs like Microsoft.Build.FileTracker, MSVC compilers, and" -ForegroundColor Gray
    Write-Host "     the Windows SDK) can pause GUI progress for 2-5 minutes each" -ForegroundColor Gray
    Write-Host "     during their post-install / file-scanning phase. THIS IS ALSO" -ForegroundColor Gray
    Write-Host "     NORMAL. The WATCH lines will keep confirming real disk activity." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  5) Typical total time: 30 to 45 minutes on a fast machine." -ForegroundColor Gray
    Write-Host "     On a 4 GB Windows Sandbox or with antivirus scanning, 60 to 90" -ForegroundColor Gray
    Write-Host "     minutes is also normal. The script continues automatically." -ForegroundColor Gray
    Write-Host ""
    Write-Host "  DO NOT close either window." -ForegroundColor Red
    Write-Host "  To abort cleanly press Ctrl+C in THIS console." -ForegroundColor Red
    Write-Host ""
    Write-Host "===========================================================================" -ForegroundColor Yellow

    # Short countdown so the user actually reads it. Five seconds is enough to
    # skim, short enough to not feel like a roadblock.
    for ($i = 5; $i -ge 1; $i--) {
        Write-Host ("  Starting in {0}..." -f $i) -ForegroundColor DarkYellow
        Start-Sleep -Seconds 1
    }
    Write-Host ""
}

function Get-VSBuildToolsPhasedNote {
    # v12: Time-phased NOTE text for the live dashboard during Build Tools install.
    # Static notes get stale fast on a 45-minute step. These phases match the
    # actual lifecycle a user observes, with explicit reassurance for the two
    # places people panic: the early-stall "0%" period, and the mid-install
    # "individual package stuck at 1%" period.
    param([TimeSpan]$Elapsed)

    $seconds = [int]$Elapsed.TotalSeconds

    if ($seconds -lt 180) {
        return @"
PHASE 1 of 3 - INSTALLER WAKING UP (0 to 3 minutes elapsed).
The Visual Studio Installer GUI is open and may show 0% in both progress bars.
This is normal warm-up while it verifies its own files and authenticates.
The WATCH lines above will start showing package-cache growth before the GUI moves.
Do NOT close either window. To abort cleanly press Ctrl+C.
"@.Trim()
    }
    if ($seconds -lt 1800) {
        return @"
PHASE 2 of 3 - DOWNLOAD AND INSTALL ACTIVE (3 to 30 minutes typical).
Downloads are roughly 1.5-2 GB total. Some packages (Microsoft.Build.FileTracker, MSVC compilers, Windows SDK) can pause GUI progress for 2-5 minutes each during their MSI custom-action phase. This is normal. The WATCH lines confirm real activity.
Do NOT close either window. To abort cleanly press Ctrl+C.
"@.Trim()
    }
    if ($seconds -lt 2700) {
        return @"
PHASE 3 of 3 - FINISHING (30 to 45 minutes elapsed).
Most components should be on disk. The remaining packages tend to be the slowest (Windows SDK headers, MSBuild, file trackers). The script will continue automatically the moment validation succeeds.
Do NOT close either window. To abort cleanly press Ctrl+C.
"@.Trim()
    }
    return @"
LONGER THAN TYPICAL (over 45 minutes).
This can happen on 4 GB sandbox setups, slow disks, or with antivirus scanning packages as they install. The install is still proceeding if the WATCH activity lines show writes in the last few minutes. If everything has gone idle, see the recovery guidance after the script finishes.
Do NOT close either window unless you have decided to abort. To abort cleanly press Ctrl+C.
"@.Trim()
}

function Resolve-VSBuildToolsInstallDecision {
    param(
        [bool]$AlreadyValid = $false,
        [bool]$PartialDetected = $false,
        [bool]$AssumeYesEnabled = $false,
        [bool]$NonLiveMode = $false,
        [string]$UserChoice = ""
    )

    if ($AlreadyValid) {
        return [pscustomobject]@{
            Status = "ValidAlready"; ShouldPrompt = $false; ShouldInstall = $false; Skipped = $false
            Reason = "Visual Studio Build Tools already validated."; Source = "local"
        }
    }
    if ($NonLiveMode) {
        return [pscustomobject]@{
            Status = "NonLiveSkipped"; ShouldPrompt = $false; ShouldInstall = $false; Skipped = $true
            Reason = "Build Tools install skipped in safe non-live mode."; Source = "non-live"
        }
    }
    if ($AssumeYesEnabled) {
        return [pscustomobject]@{
            Status = "Approved"; ShouldPrompt = $false; ShouldInstall = $true; Skipped = $false
            Reason = "Build Tools install approved by -AssumeYes."; Source = "assume-yes"
        }
    }

    $choice = ([string]$UserChoice).Trim()
    if ([string]::IsNullOrWhiteSpace($choice)) {
        return [pscustomobject]@{
            Status = "PromptNeeded"; ShouldPrompt = $true; ShouldInstall = $false; Skipped = $false
            Reason = "Build Tools install requires explicit user confirmation."; Source = "prompt"
        }
    }
    if ($choice -match '^[Yy]$') {
        return [pscustomobject]@{
            Status = "Approved"; ShouldPrompt = $false; ShouldInstall = $true; Skipped = $false
            Reason = "Build Tools install approved by user choice."; Source = "user-choice"
        }
    }
    if ($choice -match '^[Nn]$') {
        return [pscustomobject]@{
            Status = "UserSkipped"; ShouldPrompt = $false; ShouldInstall = $false; Skipped = $true
            Reason = "Build Tools skipped by user choice."; Source = "user-choice"
        }
    }
    return [pscustomobject]@{
        Status = "InvalidChoice"; ShouldPrompt = $true; ShouldInstall = $false; Skipped = $false
        Reason = "Type Y or N to choose Build Tools install behavior."; Source = "prompt"
    }
}

function Read-VSBuildToolsInstallDecision {
    param([bool]$PartialDetected = $false)

    Write-Host "" -ForegroundColor Yellow
    Write-Host "Visual Studio Build Tools is required to build StarBreaker from source." -ForegroundColor Yellow
    Write-Host "It can take a long time to install." -ForegroundColor Yellow
    Write-Host "Install Visual Studio Build Tools now? Y/N" -ForegroundColor Cyan
    Write-Host "Recommended: Y for a full setup. Choose N for Windows Sandbox, quick validation, or if you do not want Build Tools installed now." -ForegroundColor DarkYellow
    if ($PartialDetected) {
        Write-Host "A partial Build Tools install was detected; choosing Y will run the existing repair/add-components flow." -ForegroundColor DarkYellow
    }

    while ($true) {
        $answer = Read-Host "Build Tools install choice [Y/N]"
        $decision = Resolve-VSBuildToolsInstallDecision -AlreadyValid:$false -PartialDetected:$PartialDetected -AssumeYesEnabled:$false -NonLiveMode:$false -UserChoice $answer
        if (-not [bool]$decision.ShouldPrompt) { return $decision }
        Write-Warning $decision.Reason
    }
}


function Install-VSBuildToolsPassive {
    Write-SubStep "Installing or validating Visual Studio Build Tools with the C++ workload"

    $validation = Get-VSBuildToolsValidation
    if ($validation.Ready) {
        Write-Host "Visual Studio Build Tools detected and validated." -ForegroundColor Green
        Write-Host "  Install path : $($validation.InstallationPath)" -ForegroundColor DarkGray
        Write-Host "  Developer PS : $($validation.VsDevShell)" -ForegroundColor DarkGray
        Write-Host "  MSBuild      : $($validation.MSBuildPath)" -ForegroundColor DarkGray
        Write-Host "  cl.exe       : $($validation.ClPath)" -ForegroundColor DarkGray
        Set-ToolState -Name "vsbuildtools" -Status "ValidLocal" -Path $validation.InstallationPath -Source "local" -Reason "Visual Studio Build Tools already validated." -LocalValidated $true
        return
    }

    $decision = Resolve-VSBuildToolsInstallDecision -AlreadyValid:$false -PartialDetected:([bool]$validation.Partial) -AssumeYesEnabled:([bool]$AssumeYes) -NonLiveMode:(Test-NonLiveInstallerMode)
    if ([bool]$decision.ShouldPrompt) { $decision = Read-VSBuildToolsInstallDecision -PartialDetected:([bool]$validation.Partial) }
    if ([bool]$decision.Skipped) {
        Write-Host $decision.Reason -ForegroundColor DarkYellow
        Set-ToolState -Name "vsbuildtools" -Status "SKIPPED" -Path $validation.InstallationPath -Source ([string]$decision.Source) -Reason ([string]$decision.Reason) -InstallNeeded $true
        Set-CurrentSetupStepSkipped -Id "install-vsbuildtools" -Name "Install Visual Studio Build Tools" -Reason ([string]$decision.Reason)
        return
    }
    Set-ToolState -Name "vsbuildtools" -Status "InstallApproved" -Path $validation.InstallationPath -Source ([string]$decision.Source) -Reason ([string]$decision.Reason) -InstallNeeded $true

    if ($validation.Partial) {
        Write-Host "Partial Visual Studio Build Tools state detected." -ForegroundColor Yellow
        foreach ($issue in $validation.Issues) { Write-Host "  - $issue" -ForegroundColor DarkYellow }
        Write-Host "The installer will run in visible passive mode to add/repair the required C++ components." -ForegroundColor Yellow
    } else {
        Write-Host "Visual Studio Build Tools was not detected. Installing the required C++ components." -ForegroundColor Yellow
    }

    # v12: Show the beginner-friendly waiting-room page BEFORE we download the
    # bootstrapper, so the user reads it during a calm moment rather than while
    # the installer GUI is flashing and the dashboard is repainting. This is
    # the single change most likely to keep a beginner from panic-quitting
    # during the well-known 1-3 minute "stuck at 0%" warm-up phase.
    Show-VSBuildToolsWaitingRoom

    $bootstrapper = Join-Path $InstallersRoot "vs_BuildTools.exe"
    Download-File -Uri "https://aka.ms/vs/17/release/vs_BuildTools.exe" -OutFile $bootstrapper

    # v11: Do NOT pass --installPath. The bootstrapper already targets
    # "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools" by default,
    # and PowerShell's -ArgumentList handles quoting for paths with spaces. Pre-wrapping
    # the path in quotes manually was producing ""C:\Program Files...""-style args
    # on some hosts, which the bootstrapper silently rejects, leading to a 2+ hour
    # install that never finalized the components.
    # v12: Renamed $args -> $btInstallerArgs to stop shadowing PowerShell's
    # automatic $args variable. Same hygiene fix as Install-WingetPackage.
    $btInstallerArgs = @(
        "--passive",
        "--wait",
        "--norestart",
        "--add", "Microsoft.VisualStudio.Workload.VCTools",
        "--add", "Microsoft.VisualStudio.Component.VC.Tools.x86.x64",
        "--add", "Microsoft.VisualStudio.Component.Windows11SDK.26100"
    )
    if ($IncludeVSCMakeProjectComponent) {
        $btInstallerArgs += @("--add", "Microsoft.VisualStudio.Component.VC.CMake.Project")
    }

    # v12: The static $note is kept as a fallback (and for the dry-run path),
    # but the live dashboard now uses Get-VSBuildToolsPhasedNote via the
    # -NoteCallback parameter on Invoke-MonitoredProcessWait, so the NOTE line
    # rotates through phase-appropriate reassurance as elapsed time advances.
    $note = @"
Visual Studio Build Tools is usually the longest setup step.
A Visual Studio Installer progress window should appear in passive mode.
It may be quiet for 20-60+ minutes while Windows downloads, verifies, and installs C++ toolchain packages.
Watch the activity lines above. The script will continue automatically when validation succeeds.
Do not close this window unless you intentionally want to abort setup.
"@.Trim()

    Write-Host "Visual Studio Build Tools will open its own passive progress window." -ForegroundColor Yellow
    Write-Host "The script dashboard will keep monitoring setup logs, package cache activity, and install-root activity." -ForegroundColor Yellow

    $phasedNoteCallback = { param([TimeSpan]$Elapsed) Get-VSBuildToolsPhasedNote -Elapsed $Elapsed }
    $exitCode = Invoke-MonitoredProcessWait -FilePath $bootstrapper -ArgumentList $btInstallerArgs -ActivityNote $note -SuccessExitCodes @(0, 3010) -NoteCallback $phasedNoteCallback -WorkingDirectory $InstallersRoot

    if ($exitCode -eq 3010) {
        Write-Warning "Visual Studio Build Tools reported that a reboot is recommended. The script will validate what is available now. If validation fails, reboot and relaunch."
    } elseif ($exitCode -ne 0) {
        Write-Warning "Visual Studio Build Tools installer exited with code $exitCode. Validation will decide whether setup can continue."
    }

    # v11: After the bootstrapper exits, give helper processes (vs_installer,
    # vs_installerservice, dd_setup_*.exe) a fair chance to finish writing files.
    # The parent bootstrapper can return before children are done flushing the
    # install. Three quick re-validations with 10s sleeps in between is enough
    # in practice without dragging out the happy path (it bails as soon as
    # validation succeeds).
    $validation = Get-VSBuildToolsValidation
    if (-not $validation.Ready) {
        $maxRetries = 3
        $retryDelay = 10
        for ($i = 1; $i -le $maxRetries; $i++) {
            Write-Host ("Bootstrapper returned, re-checking Build Tools install ({0}/{1})..." -f $i, $maxRetries) -ForegroundColor DarkYellow
            Start-Sleep -Seconds $retryDelay
            $validation = Get-VSBuildToolsValidation
            if ($validation.Ready) { break }
        }
    }
    if (-not $validation.Ready) {
        Write-Warning "Visual Studio Build Tools did not validate after the installer returned."
        foreach ($issue in $validation.Issues) { Write-Warning "  $issue" }
        Write-Warning "Relaunching the setup later will re-check Build Tools first and will not reinstall if it validates."
        throw "Visual Studio Build Tools is missing required C++ build components. Reboot if requested, then relaunch this setup or run the Visual Studio Installer repair/modify flow."
    }

    Write-Host "Visual Studio Build Tools validated after install/repair." -ForegroundColor Green
    Write-Host "  Install path : $($validation.InstallationPath)" -ForegroundColor DarkGray
    Write-Host "  Developer PS : $($validation.VsDevShell)" -ForegroundColor DarkGray
    Write-Host "  MSBuild      : $($validation.MSBuildPath)" -ForegroundColor DarkGray
    Write-Host "  cl.exe       : $($validation.ClPath)" -ForegroundColor DarkGray
    Set-ToolState -Name "vsbuildtools" -Status "Installed" -Path $validation.InstallationPath -Source ([string]$decision.Source) -Reason "Visual Studio Build Tools validated after install/repair." -LocalValidated $true
}

function Install-NodeIntoDevRoot {
    Write-SubStep "Installing Node.js $NodeVersion into $NodeRoot"
    $nodeExe = Join-Path $NodeRoot "node.exe"

    if ((Test-Path $nodeExe) -and (-not (Test-ExecutableOutputContains -Exe $nodeExe -Expected ($NodeVersion.TrimStart('v')) -Arguments @("--version")))) {
        Write-Warning "Node.js exists but does not appear to be the requested version $NodeVersion. Replacing the dev-root Node folder."
        if (-not $DryRun) { Remove-Item -LiteralPath $NodeRoot -Recurse -Force -ErrorAction SilentlyContinue; Ensure-Directory $NodeRoot }
    }

    if (-not (Test-Path $nodeExe)) {
        $nodeZipName = "node-$NodeVersion-win-x64.zip"
        $nodeZip = Join-Path $InstallersRoot $nodeZipName
        $nodeUrl = "https://nodejs.org/dist/$NodeVersion/$nodeZipName"
        $extractRoot = Join-Path $InstallersRoot "node-extract"
        Download-File -Uri $nodeUrl -OutFile $nodeZip

        if (-not $DryRun) {
            if (Test-Path $extractRoot) { Remove-Item $extractRoot -Recurse -Force }
            Expand-Archive -Path $nodeZip -DestinationPath $extractRoot -Force
            $expanded = Get-ChildItem $extractRoot -Directory | Select-Object -First 1
            if ($null -eq $expanded) { throw "Could not find extracted Node.js root in $extractRoot" }
            Copy-Item "$($expanded.FullName)\*" $NodeRoot -Recurse -Force
        }
    } else {
        Write-Host "Node.js already appears to be installed: $nodeExe"
    }

    Ensure-Directory $NpmCacheDir
    Ensure-Directory $NpmGlobalDir
    Add-UserPath $NodeRoot
    Add-UserPath $NpmGlobalDir

    $npm = Join-Path $NodeRoot "npm.cmd"
    if (Test-Path $nodeExe) { Run-Native -Exe $nodeExe -Arguments @("--version") }
    if (Test-Path $npm) {
        Run-Native -Exe $npm -Arguments @("--version")
        Run-Native -Exe $npm -Arguments @("config", "set", "cache", $NpmCacheDir, "--location=user")
        Run-Native -Exe $npm -Arguments @("config", "set", "prefix", $NpmGlobalDir, "--location=user")
        Run-Native -Exe $npm -Arguments @("config", "get", "cache")
        Run-Native -Exe $npm -Arguments @("config", "get", "prefix")

        if (-not $SkipCodex) {
            $codexCmd = Join-Path $NpmGlobalDir "codex.cmd"
            $codexVersionText = if (Test-Path -LiteralPath $codexCmd) { Get-ExecutableOutputText -Exe $codexCmd -Arguments @("--version") } else { "" }
            if (-not [string]::IsNullOrWhiteSpace($codexVersionText)) {
                Write-Host "Codex CLI already validates in the npm global dir; skipping npm install." -ForegroundColor Green
                Run-Native -Exe $codexCmd -Arguments @("--version") -IgnoreExitCode
            } else {
                Run-Native -Exe $npm -Arguments @("install", "-g", "@openai/codex")
                if (Test-Path $codexCmd) { Run-Native -Exe $codexCmd -Arguments @("--version") -IgnoreExitCode }
            }
        }
    }
}

function Show-WingetRecoveryHelp {
    Write-Host "" -ForegroundColor Yellow
    Write-Host "WinGet was not found on PATH." -ForegroundColor Yellow
    Write-Host "This setup uses WinGet for Git, Visual Studio Build Tools, Rust, VS Code, and some installer checks." -ForegroundColor Yellow

    if ($env:USERNAME -ieq "WDAGUtilityAccount") {
        Write-Host "This Windows environment may not include Microsoft Store/App Installer/WinGet by default." -ForegroundColor Yellow
    }

    $appInstaller = Get-AppxPackage -Name Microsoft.DesktopAppInstaller -ErrorAction SilentlyContinue
    if ($null -eq $appInstaller) {
        Write-Host "Microsoft.DesktopAppInstaller / App Installer was not detected for this user." -ForegroundColor Yellow
    } else {
        Write-Host "App Installer package detected: $($appInstaller.Version). If winget is still missing, open a new terminal or check App execution aliases." -ForegroundColor Yellow
    }

    Write-Host "Fix options:" -ForegroundColor Yellow
    Write-Host "  1. Open Microsoft Store, search for App Installer, then install/update it."
    Write-Host "  2. Open a new PowerShell/CMD and run: winget --version"
    Write-Host "  3. For a true live installer test, use a fresh Windows VM if this environment does not provide WinGet."
    Write-Host ""
}

function Install-BaseTools {
    Write-Step "Installing base tools and runtimes"

    Invoke-SetupStep -Id "winget-check" -Name "Validate WinGet availability" -ScriptBlock {
        $wingetCmd = Get-Command winget.exe -ErrorAction SilentlyContinue
        if ($null -eq $wingetCmd) {
            Show-WingetRecoveryHelp
            throw "winget.exe was not found. Install or update Microsoft App Installer / WinGet, then re-run this script."
        }
        Write-Host "WinGet found: $($wingetCmd.Source)"
        Run-Native -Exe $wingetCmd.Source -Arguments @("--version") -IgnoreExitCode
    }

    Invoke-SetupStep -Id "install-git" -Name "Install or validate Git" -ScriptBlock {
        if (Get-Command git -ErrorAction SilentlyContinue) {
            Write-Host "Git is already available. Validating and checking for WinGet updates." -ForegroundColor Green
            Run-Native -Exe "git" -Arguments @("--version") -IgnoreExitCode
            Update-WingetPackageIfInstalled -Id "Git.Git" | Out-Null
        } else {
            Install-WingetPackage -Id "Git.Git"
        }
        Add-UserPath "C:\Program Files\Git\cmd"
        if (Get-Command git -ErrorAction SilentlyContinue) { Run-Native -Exe "git" -Arguments @("--version") -IgnoreExitCode }
    }

    Invoke-SetupStep -Id "install-gh" -Name "Install or validate GitHub CLI" -ScriptBlock {
        Install-GitHubCliIntoDevRoot
    }

    Invoke-SetupStep -Id "install-vsbuildtools" -Name "Install Visual Studio Build Tools" -ScriptBlock {
        Install-VSBuildToolsPassive
    }

    Invoke-SetupStep -Id "install-rust" -Name "Install or validate Rust" -ScriptBlock {
        Set-UserEnv "CARGO_HOME" $CargoHome
        Set-UserEnv "RUSTUP_HOME" $RustupHome
        Add-UserPath (Join-Path $CargoHome "bin")
        $rustupCmd = Get-Command rustup -ErrorAction SilentlyContinue
        $cargoCmd = Get-Command cargo -ErrorAction SilentlyContinue
        $rustcCmd = Get-Command rustc -ErrorAction SilentlyContinue
        if ($rustupCmd -and $cargoCmd -and $rustcCmd) {
            Write-Host "Rust/rustup/cargo/rustc already validate on PATH. Skipping rustup update on rerun." -ForegroundColor Green
            Run-Native -Exe "rustup" -Arguments @("--version") -IgnoreExitCode
            Run-Native -Exe "cargo" -Arguments @("--version") -IgnoreExitCode
            Run-Native -Exe "rustc" -Arguments @("--version") -IgnoreExitCode
            return
        } elseif ($rustupCmd) {
            Write-Host "rustup is available but cargo/rustc are not fully visible. Selecting stable toolchain without a network update." -ForegroundColor Yellow
            Run-Native -Exe "rustup" -Arguments @("default", "stable") -IgnoreExitCode
        } else {
            Install-WingetPackage -Id "Rustlang.Rustup"
        }
        if (Get-Command rustup -ErrorAction SilentlyContinue) {
            Run-Native -Exe "rustup" -Arguments @("default", "stable") -IgnoreExitCode
            Run-Native -Exe "rustup" -Arguments @("--version") -IgnoreExitCode
            Run-Native -Exe "cargo" -Arguments @("--version") -IgnoreExitCode
            Run-Native -Exe "rustc" -Arguments @("--version") -IgnoreExitCode
        } else {
            Write-Warning "rustup was not found on PATH after installation. Open a new terminal or re-run this script if the Rust installer just completed."
        }
    }

    Invoke-SetupStep -Id "install-python" -Name "Install Python and shared venv" -ScriptBlock {
        Install-PythonIntoDevRoot
    }

    Invoke-SetupStep -Id "install-dotnet" -Name "Install .NET SDKs" -ScriptBlock {
        Install-DotNetIntoDevRoot
    }

    Invoke-SetupStep -Id "install-cmake" -Name "Install CMake" -ScriptBlock {
        Install-CMakeIntoDevRoot
    }

    Invoke-SetupStep -Id "install-vscode" -Name "Install or validate VS Code" -ScriptBlock {
        Ensure-VSCodeAvailable | Out-Null
    }

    Invoke-SetupStep -Id "install-node-codex" -Name "Install Node.js, npm cache, and optional Codex CLI" -ScriptBlock {
        Install-NodeIntoDevRoot
    }

    Invoke-SetupStep -Id "execution-policy" -Name "Set CurrentUser PowerShell execution policy" -ScriptBlock {
        try {
            Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned -Force
        } catch {
            Write-Warning "Could not set CurrentUser execution policy automatically: $($_.Exception.Message)"
        }
    }
}


function Test-GitWorkingTreeClean {
    param([Parameter(Mandatory=$true)][string]$Path)
    if (-not (Test-Path (Join-Path $Path ".git"))) { return $false }
    try {
        $status = (& git -C $Path status --porcelain 2>$null)
        return [string]::IsNullOrWhiteSpace(($status -join ""))
    } catch { return $false }
}

function Get-RepoOriginUrl {
    param([string]$Path)
    try { return ((& git -C $Path remote get-url origin 2>$null) -join "").Trim() } catch { return "" }
}

function Get-NormalizedFullPath {
    param([string]$Path)
    if ([string]::IsNullOrWhiteSpace($Path)) { return "" }
    try { return ([IO.Path]::GetFullPath($Path)).TrimEnd([char[]]@('\','/')) } catch { return ([string]$Path).TrimEnd([char[]]@('\','/')) }
}

function Test-SamePath {
    param([string]$Left, [string]$Right)
    $a = Get-NormalizedFullPath -Path $Left
    $b = Get-NormalizedFullPath -Path $Right
    return (-not [string]::IsNullOrWhiteSpace($a) -and $a.Equals($b, [StringComparison]::OrdinalIgnoreCase))
}

function New-GitVersioningResult {
    param(
        [string]$Repo,
        [string]$Role,
        [string]$Path,
        [string]$Branch
    )
    return [ordered]@{
        Repo = $Repo
        Role = $Role
        Path = $Path
        GitExists = $false
        Branch = $Branch
        CurrentBranch = ""
        Dirty = $false
        DirtyStatus = "Unknown"
        IdentityStatus = "NotChecked"
        IdentityLocalPresent = $false
        IdentityCopiedFromGlobal = $false
        IdentityFallbackWritten = $false
        Status = "Pending"
        Reason = ""
    }
}

function Get-GitStatusLines {
    param([Parameter(Mandatory=$true)][string]$Path)
    try {
        $status = @(& git -C $Path status --porcelain 2>$null)
        if ($LASTEXITCODE -ne 0) { return @("__STATUS_FAILED__ git status exited $LASTEXITCODE") }
        return $status
    } catch { return @("__STATUS_FAILED__ $($_.Exception.Message)") }
}

function Get-GitCurrentBranchSafe {
    param([Parameter(Mandatory=$true)][string]$Path)
    try { return ((& git -C $Path branch --show-current 2>$null) -join "").Trim() } catch { return "" }
}

function Set-RepoLocalGitIdentity {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)]$Result
    )
    $localName = ""; $localEmail = ""; $globalName = ""; $globalEmail = ""
    try { $localName = ((& git -C $Path config --local --get user.name 2>$null) -join "").Trim() } catch { }
    try { $localEmail = ((& git -C $Path config --local --get user.email 2>$null) -join "").Trim() } catch { }

    if ((-not [string]::IsNullOrWhiteSpace($localName)) -and (-not [string]::IsNullOrWhiteSpace($localEmail))) {
        $Result.IdentityLocalPresent = $true
        $Result.IdentityStatus = "RepoLocalPresent"
        return
    }

    $canReadGlobal = -not $Script:NoGlobalGitConfig
    if (-not $canReadGlobal -and -not [string]::IsNullOrWhiteSpace($env:GIT_CONFIG_GLOBAL)) {
        try {
            $canReadGlobal = (Test-InstallerPathUnderRoot -Path $env:GIT_CONFIG_GLOBAL -Root $Script:HarnessRoot) -or
                (Test-InstallerPathUnderRoot -Path $env:GIT_CONFIG_GLOBAL -Root $Script:OriginalAgentWorkRoot) -or
                (Test-InstallerPathUnderRoot -Path $env:GIT_CONFIG_GLOBAL -Root $Script:AgentWorkRoot)
        } catch { $canReadGlobal = $false }
    }
    if ($canReadGlobal) {
        try { $globalName = ((& git config --global --get user.name 2>$null) -join "").Trim() } catch { }
        try { $globalEmail = ((& git config --global --get user.email 2>$null) -join "").Trim() } catch { }
    }

    $copied = $false
    $fallback = $false
    if ([string]::IsNullOrWhiteSpace($localName)) {
        if (-not [string]::IsNullOrWhiteSpace($globalName)) {
            Run-Native -Exe "git" -Arguments @("-C", $Path, "config", "--local", "user.name", $globalName) -WorkingDirectory $Path
            $copied = $true
        } else {
            Run-Native -Exe "git" -Arguments @("-C", $Path, "config", "--local", "user.name", "Local Developer") -WorkingDirectory $Path
            $fallback = $true
        }
    }
    if ([string]::IsNullOrWhiteSpace($localEmail)) {
        if (-not [string]::IsNullOrWhiteSpace($globalEmail)) {
            Run-Native -Exe "git" -Arguments @("-C", $Path, "config", "--local", "user.email", $globalEmail) -WorkingDirectory $Path
            $copied = $true
        } else {
            Run-Native -Exe "git" -Arguments @("-C", $Path, "config", "--local", "user.email", "local@example.invalid") -WorkingDirectory $Path
            $fallback = $true
        }
    }

    $Result.IdentityCopiedFromGlobal = $copied
    $Result.IdentityFallbackWritten = $fallback
    if ($fallback -and $copied) { $Result.IdentityStatus = "MixedGlobalAndFallback" }
    elseif ($fallback) { $Result.IdentityStatus = "FallbackWritten" }
    elseif ($copied) { $Result.IdentityStatus = "CopiedFromGlobal" }
    else { $Result.IdentityStatus = "RepoLocalPartial" }
}

function Get-GitignoreRulesForRepoRole {
    param([string]$Role)
    $common = @("target/","bin/","obj/","node_modules/",".venv/","venv/","__pycache__/","*.pyc",".env","*.log")
    if ($Role -eq "orchestration") {
        return @("scdata/","installers/","logs/","work/*.log","*.p4k","*.partial","setup-state.json",".setup-cache/") + $common
    }
    if ($Role -eq "guide") {
        return @("installers/","logs/","work/*.log","*.p4k","*.partial","setup-state.json",".setup-cache/") + $common
    }
    return $common
}

function Merge-GitignoreRules {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string[]]$Rules = @()
    )
    if ($Rules.Count -eq 0) { return $false }
    $gitignore = Join-Path $Path ".gitignore"
    $existing = @()
    if (Test-Path -LiteralPath $gitignore) {
        try { $existing = @(Get-Content -LiteralPath $gitignore -ErrorAction Stop) } catch { $existing = @() }
    }
    $seen = @{}
    foreach ($line in @($existing)) {
        $key = ([string]$line).Trim()
        if (-not [string]::IsNullOrWhiteSpace($key) -and -not $seen.ContainsKey($key)) { $seen[$key] = $true }
    }
    $missing = New-Object 'System.Collections.Generic.List[string]'
    foreach ($rule in @($Rules)) {
        $key = ([string]$rule).Trim()
        if ([string]::IsNullOrWhiteSpace($key)) { continue }
        if (-not $seen.ContainsKey($key)) {
            [void]$missing.Add($key)
            $seen[$key] = $true
        }
    }
    if ($missing.Count -eq 0) { return $false }
    if ($DryRun) {
        Write-Host ("[dry-run] Would append {0} .gitignore rule(s) to {1}" -f $missing.Count, $gitignore) -ForegroundColor DarkCyan
        return $false
    }
    Assert-HarnessPathAllowed -Path $gitignore -Purpose ".gitignore merge"
    if (Test-Path -LiteralPath $gitignore) {
        Add-Content -LiteralPath $gitignore -Value @($missing.ToArray()) -Encoding UTF8
    } else {
        Set-Content -LiteralPath $gitignore -Value @($missing.ToArray()) -Encoding UTF8
    }
    return $true
}

function Test-KnownStarCitizenChildRepoPath {
    param([string]$Path)
    $leaf = Split-Path (Get-NormalizedFullPath -Path $Path) -Leaf
    return ($leaf -in @("StarBreaker", "Blender-Tools", "unp4k", "Cryengine-Converter", "SCTextureConverter", "scdatatools", "qtvscodestyle", $GuideRepoName))
}

function Resolve-SafeOrchestrationRepoPath {
    $starRoot = Get-NormalizedFullPath -Path $StarCitizenRoot
    if ([string]::IsNullOrWhiteSpace($starRoot)) { return "" }
    if (Test-Path (Join-Path $starRoot ".git")) { return $starRoot }

    $starts = New-Object 'System.Collections.Generic.List[string]'
    if (-not [string]::IsNullOrWhiteSpace($Script:LauncherDir)) { [void]$starts.Add($Script:LauncherDir) }
    if (-not [string]::IsNullOrWhiteSpace($Script:LauncherPath)) {
        try { [void]$starts.Add((Split-Path $Script:LauncherPath -Parent)) } catch { }
    }
    try { [void]$starts.Add((Get-Location).Path) } catch { }

    foreach ($start in @($starts.ToArray() | Where-Object { -not [string]::IsNullOrWhiteSpace([string]$_) } | Select-Object -Unique)) {
        try {
            $dir = Get-Item -LiteralPath $start -ErrorAction SilentlyContinue
            while ($null -ne $dir) {
                $full = Get-NormalizedFullPath -Path $dir.FullName
                if ([string]::IsNullOrWhiteSpace($full) -or -not $full.StartsWith($starRoot, [StringComparison]::OrdinalIgnoreCase)) { break }
                if ((Test-Path (Join-Path $full ".git")) -and (-not (Test-SamePath -Left $full -Right $GuideRepoPath)) -and (-not (Test-KnownStarCitizenChildRepoPath -Path $full))) {
                    return $full
                }
                if (Test-SamePath -Left $full -Right $starRoot) { break }
                $parent = Split-Path $full -Parent
                if ([string]::IsNullOrWhiteSpace($parent) -or (Test-SamePath -Left $parent -Right $full)) { break }
                $dir = Get-Item -LiteralPath $parent -ErrorAction SilentlyContinue
            }
        } catch { }
    }
    return ""
}

function Test-StarCitizenRootUnsafeForAutoGitInit {
    if (Test-Path (Join-Path $StarCitizenRoot ".git")) { return $false }
    if (-not (Test-Path -LiteralPath $StarCitizenRoot)) { return $false }
    try {
        foreach ($name in @("scdata","prompts","work","output","reports","installers","logs")) {
            if (Test-Path -LiteralPath (Join-Path $StarCitizenRoot $name)) { return $true }
        }
        $childRepo = @(Get-ChildItem -LiteralPath $StarCitizenRoot -Force -Directory -ErrorAction SilentlyContinue |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName ".git") } |
            Select-Object -First 1)
        if ($childRepo.Count -gt 0) { return $true }
        $largeLocal = @(Get-ChildItem -LiteralPath $StarCitizenRoot -Force -File -ErrorAction SilentlyContinue |
            Where-Object { $_.Name -match '(?i)\.(p4k|partial)$' } |
            Select-Object -First 1)
        if ($largeLocal.Count -gt 0) { return $true }
    } catch { return $true }
    return $false
}

function Find-ExistingTutorialRepoFromLauncher {
    $candidates = New-Object 'System.Collections.Generic.List[string]'
    if (-not [string]::IsNullOrWhiteSpace($Script:LauncherDir)) { [void]$candidates.Add($Script:LauncherDir) }
    if (-not [string]::IsNullOrWhiteSpace($Script:LauncherPath)) { [void]$candidates.Add((Split-Path $Script:LauncherPath -Parent)) }
    [void]$candidates.Add($GuideRepoPath)
    $starRoot = Get-NormalizedFullPath -Path $StarCitizenRoot
    foreach ($start in @($candidates.ToArray() | Select-Object -Unique)) {
        try {
            $dir = Get-Item -LiteralPath $start -ErrorAction SilentlyContinue
            while ($null -ne $dir) {
                $full = Get-NormalizedFullPath -Path $dir.FullName
                if ([string]::IsNullOrWhiteSpace($full) -or (-not $full.StartsWith($starRoot, [StringComparison]::OrdinalIgnoreCase))) { break }
                if (Test-Path (Join-Path $full ".git")) {
                    $origin = Get-RepoOriginUrl -Path $full
                    if (($origin -match 'DirectorGunner/How-to-Guide-for-Extracting-and-Modding-Star-Citizen-Assets') -or (Test-SamePath -Left $full -Right $GuideRepoPath) -or ((Split-Path $full -Leaf) -eq $GuideRepoName)) {
                        $Script:TutorialRepoState.path = $full
                        $Script:TutorialRepoState.originatedFromLauncher = $true
                        return $full
                    }
                }
                if (Test-SamePath -Left $full -Right $starRoot) { break }
                $parent = Split-Path $full -Parent
                if ([string]::IsNullOrWhiteSpace($parent) -or (Test-SamePath -Left $parent -Right $full)) { break }
                $dir = Get-Item -LiteralPath $parent -ErrorAction SilentlyContinue
            }
        } catch { }
    }
    return ""
}

function Clone-RepositoryIfNeeded {
    param(
        [Parameter(Mandatory=$true)][string]$Name,
        [Parameter(Mandatory=$true)][string]$Url,
        [string]$Destination = ""
    )
    $path = if ([string]::IsNullOrWhiteSpace($Destination)) { Join-Path $StarCitizenRoot $Name } else { $Destination }
    $Script:RepoStates[$Name] = [ordered]@{ path=$path; url=$Url; status="Pending"; reason="" }
    if (Test-Path (Join-Path $path ".git")) {
        $Script:RepoStates[$Name].status = "OK"
        if ($UpdateExistingRepos) {
            if ($Name -eq $GuideRepoName -and $Script:TutorialRepoState.originatedFromLauncher) {
                Write-Warning "The launcher appears to live inside the tutorial repo. UpdateExistingRepos will not pull it automatically while this script is running."
                $Script:RepoStates[$Name].reason = "Skipped pull because launcher is inside this repo."
            } elseif (Test-GitWorkingTreeClean -Path $path) {
                Write-Host "Repository exists and is clean; attempting safe fast-forward update: $path"
                Run-Native -Exe "git" -Arguments @("-C", $path, "fetch", "--prune") -IgnoreExitCode -WorkingDirectory $path
                Run-Native -Exe "git" -Arguments @("-C", $path, "pull", "--ff-only") -IgnoreExitCode -WorkingDirectory $path
            } else {
                Write-Warning "Repository has local changes; not updating automatically: $path"
                $Script:RepoStates[$Name].reason = "Local changes present; not pulled."
            }
        } else {
            Write-Host "Repository already exists, not pulling or overwriting: $path"
        }
        return
    }
    if ((Test-Path $path) -and ((Get-ChildItem $path -Force | Select-Object -First 1) -ne $null)) {
        Write-Warning "Folder exists but is not a Git repository; not overwriting: $path"
        $Script:RepoStates[$Name].status = "WARN"
        $Script:RepoStates[$Name].reason = "Folder exists but is not a Git repo."
        return
    }
    if (Test-Path $path) { Remove-Item $path -Recurse -Force }
    Run-Native -Exe "git" -Arguments @("clone", $Url, $path) -WorkingDirectory $StarCitizenRoot
    $Script:RepoStates[$Name].status = "OK"
}

function Sync-Repositories {
    Write-Step "Cloning community repositories"
    Require-Command "git" | Out-Null
    Ensure-Directory $StarCitizenRoot

    $repos = @(
        @{ Name = "StarBreaker";          Url = "https://github.com/diogotr7/StarBreaker.git" },
        @{ Name = "Blender-Tools";        Url = "https://github.com/scorg-tools/Blender-Tools.git" },
        @{ Name = "unp4k";                Url = "https://github.com/dolkensp/unp4k.git" },
        @{ Name = "Cryengine-Converter";  Url = "https://github.com/markemp/Cryengine-Converter.git" },
        @{ Name = "SCTextureConverter";   Url = "https://github.com/Madfish71/SCTextureConverter.git" }
    )
    foreach ($repo in $repos) { Clone-RepositoryIfNeeded -Name $repo.Name -Url $repo.Url }

    Ensure-Directory (Join-Path $StarCitizenRoot "scdatatools")
    Ensure-Directory (Join-Path $StarCitizenRoot "qtvscodestyle")
}

function Sync-GuideRepository {
    Write-Step "Cloning DirectorGunner tutorial repository"
    Require-Command "git" | Out-Null
    Ensure-Directory $StarCitizenRoot
    $existing = Find-ExistingTutorialRepoFromLauncher
    if (-not [string]::IsNullOrWhiteSpace($existing)) {
        Write-Host "Tutorial repo detected from launcher location: $existing" -ForegroundColor Green
        $Script:TutorialRepoState.path = $existing
        Clone-RepositoryIfNeeded -Name $GuideRepoName -Url $GuideRepoUrl -Destination $existing
    } else {
        Clone-RepositoryIfNeeded -Name $GuideRepoName -Url $GuideRepoUrl -Destination $GuideRepoPath
        $Script:TutorialRepoState.path = $GuideRepoPath
    }
}

function Ensure-GitBranch {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Branch,
        [string]$RepoName = "",
        [string]$Role = "tool",
        [switch]$SwitchBranch
    )
    if ([string]::IsNullOrWhiteSpace($RepoName)) { $RepoName = Split-Path $Path -Leaf }
    $result = New-GitVersioningResult -Repo $RepoName -Role $Role -Path $Path -Branch $Branch
    try {
        if ([string]::IsNullOrWhiteSpace($Path) -or -not (Test-Path -LiteralPath $Path)) {
            $result.Status = "WARN"; $result.Reason = "Repository path is missing."
            Write-Warning "Skipping Git versioning; repository path is missing: $Path"
            return
        }
        if (-not (Test-Path (Join-Path $Path ".git"))) {
            $result.Status = "WARN"; $result.Reason = "Not a Git repo; skipped because this path is not safe to initialize automatically."
            Write-Warning "Skipping Git versioning; not a Git repo: $Path"
            return
        }
        $result.GitExists = $true
        Set-RepoLocalGitIdentity -Path $Path -Result $result
        $result.CurrentBranch = Get-GitCurrentBranchSafe -Path $Path
        $status = @(Get-GitStatusLines -Path $Path)
        if (($status -join "") -match '^__STATUS_FAILED__') { throw ($status -join "`n") }
        $result.Dirty = -not [string]::IsNullOrWhiteSpace(($status -join ""))
        $result.DirtyStatus = if ($result.Dirty) { (($status | Select-Object -First 8) -join " | ") } else { "Clean" }

        if ($SwitchBranch) {
            if ($result.CurrentBranch -eq $Branch) {
                $result.Status = "OK"
                $result.Reason = "Already on target branch."
                Write-Host "Already on $Branch in $Path" -ForegroundColor Green
            } elseif ($result.Dirty) {
                $result.Status = "WARN"
                $result.Reason = "Working tree has local changes; branch not switched."
                Write-Warning "Working tree has local changes; not switching branches automatically: $Path"
                foreach ($line in ($status | Select-Object -First 10)) { Write-Host "  $line" -ForegroundColor DarkYellow }
            } else {
                $existing = ((& git -C $Path branch --list $Branch 2>$null) -join "").Trim()
                if (-not [string]::IsNullOrWhiteSpace($existing)) {
                    Run-Native -Exe "git" -Arguments @("-C", $Path, "checkout", $Branch) -WorkingDirectory $Path
                } else {
                    Run-Native -Exe "git" -Arguments @("-C", $Path, "checkout", "-b", $Branch) -WorkingDirectory $Path
                }
                $result.CurrentBranch = Get-GitCurrentBranchSafe -Path $Path
                if ($result.CurrentBranch -eq $Branch) { $result.Status = "OK"; $result.Reason = "Target branch ready." }
                else { $result.Status = "FAILED"; $result.Reason = "Final branch did not verify as expected." }
            }
        } else {
            $result.Status = "OK"
            $result.Reason = "Branch switching was not requested."
        }

        $gitignoreChanged = Merge-GitignoreRules -Path $Path -Rules (Get-GitignoreRulesForRepoRole -Role $Role)
        if ($gitignoreChanged -and $result.Status -eq "OK") {
            $result.Status = "WARN"
            $result.Reason = (($result.Reason + " Missing .gitignore rules were merged; review the uncommitted .gitignore change.").Trim())
        }
        if ($result.IdentityFallbackWritten -and $result.Status -eq "OK") {
            $result.Status = "WARN"
            $result.Reason = (($result.Reason + " Repo-local fallback Git identity was written.").Trim())
        } elseif ($result.IdentityFallbackWritten -and -not ($result.Reason -match 'fallback Git identity')) {
            $result.Reason = (($result.Reason + " Repo-local fallback Git identity was written.").Trim())
        }
    } catch {
        $result.Status = "FAILED"; $result.Reason = $_.Exception.Message
        Write-Warning ("Branch setup failed for {0}: {1}" -f $Path, $_.Exception.Message)
    } finally {
        $Script:BranchStates.Add([pscustomobject]$result) | Out-Null
        if ($result.Repo -eq $GuideRepoName) { $Script:TutorialRepoState.branchStatus = $result.Status; $Script:TutorialRepoState.branchStatusReason = $result.Reason }
    }
}

function Initialize-PrivateRepoIfUseful {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$InitialBranch = "dev-private-review"
    )
    if (-not (Test-Path $Path)) { return $false }
    if (Test-Path (Join-Path $Path ".git")) { return $true }

    $files = Get-ChildItem $Path -Force | Where-Object { $_.Name -ne ".git" } | Select-Object -First 1
    if ($null -eq $files) { Write-Host "Private placeholder folder is empty; not initializing Git: $Path"; return $false }

    Run-Native -Exe "git" -Arguments @("init", "-b", $InitialBranch) -IgnoreExitCode -WorkingDirectory $Path
    if (-not (Test-Path (Join-Path $Path ".git"))) { Run-Native -Exe "git" -Arguments @("init") -WorkingDirectory $Path }
    Run-Native -Exe "git" -Arguments @("remote", "-v") -IgnoreExitCode -WorkingDirectory $Path
    return (Test-Path (Join-Path $Path ".git"))
}

function Create-SafeBranches {
    Write-Step "Creating safe development branches"
    Ensure-GitBranch -RepoName "StarBreaker" -Path (Join-Path $StarCitizenRoot "StarBreaker") -Branch "dev-mcp-blender-workflow" -Role "tool" -SwitchBranch:$CreateBranches
    Ensure-GitBranch -RepoName "Blender-Tools" -Path (Join-Path $StarCitizenRoot "Blender-Tools") -Branch "dev-direct-p4k-workflow" -Role "tool" -SwitchBranch:$CreateBranches
    Ensure-GitBranch -RepoName "unp4k" -Path (Join-Path $StarCitizenRoot "unp4k") -Branch "dev-direct-p4k-workflow" -Role "tool" -SwitchBranch:$CreateBranches
    Ensure-GitBranch -RepoName "Cryengine-Converter" -Path (Join-Path $StarCitizenRoot "Cryengine-Converter") -Branch "dev-sc-asset-pipeline" -Role "tool" -SwitchBranch:$CreateBranches
    Ensure-GitBranch -RepoName "SCTextureConverter" -Path (Join-Path $StarCitizenRoot "SCTextureConverter") -Branch "dev-sc-texture-pipeline" -Role "tool" -SwitchBranch:$CreateBranches
    $scdataToolsPath = Join-Path $StarCitizenRoot "scdatatools"
    $qtStylePath = Join-Path $StarCitizenRoot "qtvscodestyle"
    if (Initialize-PrivateRepoIfUseful -Path $scdataToolsPath -InitialBranch "dev-private-review") {
        Ensure-GitBranch -RepoName "scdatatools" -Path $scdataToolsPath -Branch "dev-private-review" -Role "private" -SwitchBranch:$CreateBranches
    } else {
        $Script:BranchStates.Add([pscustomobject](New-GitVersioningResult -Repo "scdatatools" -Role "private" -Path $scdataToolsPath -Branch "dev-private-review")) | Out-Null
        $Script:BranchStates[$Script:BranchStates.Count - 1].Status = "SKIPPED"
        $Script:BranchStates[$Script:BranchStates.Count - 1].Reason = "Private placeholder folder is empty or missing; no Git repo initialized."
    }
    if (Initialize-PrivateRepoIfUseful -Path $qtStylePath -InitialBranch "dev-private-review") {
        Ensure-GitBranch -RepoName "qtvscodestyle" -Path $qtStylePath -Branch "dev-private-review" -Role "private" -SwitchBranch:$CreateBranches
    } else {
        $Script:BranchStates.Add([pscustomobject](New-GitVersioningResult -Repo "qtvscodestyle" -Role "private" -Path $qtStylePath -Branch "dev-private-review")) | Out-Null
        $Script:BranchStates[$Script:BranchStates.Count - 1].Status = "SKIPPED"
        $Script:BranchStates[$Script:BranchStates.Count - 1].Reason = "Private placeholder folder is empty or missing; no Git repo initialized."
    }
    $guidePath = if (-not [string]::IsNullOrWhiteSpace($Script:TutorialRepoState.path)) { $Script:TutorialRepoState.path } else { $GuideRepoPath }
    Ensure-GitBranch -RepoName $GuideRepoName -Path $guidePath -Branch "dev-guide-improvements" -Role "guide" -SwitchBranch:$CreateBranches
    if (-not [string]::IsNullOrWhiteSpace($Script:OrchestrationRepoPath)) {
        Ensure-GitBranch -RepoName "starcitizen-orchestration" -Path $Script:OrchestrationRepoPath -Branch "dev-setup-stabilization" -Role "orchestration" -SwitchBranch:$CreateBranches
    }
}

function Initialize-GitVersioning {
    Write-Step "Initializing local Git versioning and safe development branches"
    Require-Command "git" | Out-Null
    $Script:BranchStates.Clear()

    $guidePath = if (-not [string]::IsNullOrWhiteSpace($Script:TutorialRepoState.path)) { $Script:TutorialRepoState.path } else { Find-ExistingTutorialRepoFromLauncher }
    if ([string]::IsNullOrWhiteSpace($guidePath)) { $guidePath = $GuideRepoPath }
    $Script:TutorialRepoState.path = $guidePath

    $orchestrationPath = Resolve-SafeOrchestrationRepoPath
    if (-not [string]::IsNullOrWhiteSpace($orchestrationPath) -and (-not (Test-SamePath -Left $orchestrationPath -Right $guidePath))) {
        $Script:OrchestrationRepoPath = $orchestrationPath
    } elseif (Test-StarCitizenRootUnsafeForAutoGitInit) {
        $rootResult = New-GitVersioningResult -Repo "starcitizen-orchestration" -Role "orchestration" -Path $StarCitizenRoot -Branch "dev-setup-stabilization"
        $rootResult.Status = "WARN"
        $rootResult.Reason = "Project root contains child repos or generated/local data; skipped broad Git init."
        $Script:BranchStates.Add([pscustomobject]$rootResult) | Out-Null
        Write-Warning $rootResult.Reason
    }

    Create-SafeBranches

    $failed = @($Script:BranchStates | Where-Object { ([string]$_.Status) -match '^(FAIL|FAILED|FATAL)$' })
    $warned = @($Script:BranchStates | Where-Object { ([string]$_.Status) -eq 'WARN' -or ([string]$_.Status) -eq 'SKIPPED' })
    if ($failed.Count -gt 0) {
        $Script:CurrentStepResultStatus = "FAILED"
        $Script:CurrentStepResultReason = "One or more Git versioning or branch operations failed."
    } elseif ($warned.Count -gt 0) {
        $Script:CurrentStepResultStatus = "WARN"
        $Script:CurrentStepResultReason = "One or more Git versioning or branch operations need review."
    }
}

function Get-VSBuildToolsInstallPath {
    if (Test-NonLiveInstallerMode) { return (Join-Path $DevRoot "vsbuildtools") }
    $vswhere = "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe"
    if (Test-Path -LiteralPath $vswhere) {
        try {
            $path = & $vswhere -latest -products Microsoft.VisualStudio.Product.BuildTools -requires Microsoft.VisualStudio.Workload.VCTools -property installationPath 2>$null
            if (-not [string]::IsNullOrWhiteSpace($path)) { return $path.Trim() }
        } catch { }
        try {
            $path = & $vswhere -latest -products * -requires Microsoft.VisualStudio.Workload.VCTools -property installationPath 2>$null
            if (-not [string]::IsNullOrWhiteSpace($path)) { return $path.Trim() }
        } catch { }
    }

    $default = "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools"
    if (Test-Path -LiteralPath $default) { return $default }
    return ""
}

function Get-VsDevShellPath {
    if (Test-NonLiveInstallerMode) { return (Join-Path (Join-Path $DevRoot "vsbuildtools") "Common7\Tools\Launch-VsDevShell.ps1") }
    $installationPath = Get-VSBuildToolsInstallPath
    if (-not [string]::IsNullOrWhiteSpace($installationPath)) {
        $candidate = Join-Path $installationPath "Common7\Tools\Launch-VsDevShell.ps1"
        if (Test-Path -LiteralPath $candidate) { return $candidate }
    }

    return "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools\Common7\Tools\Launch-VsDevShell.ps1"
}

function Get-VSBuildToolsValidation {
    $issues = New-Object 'System.Collections.Generic.List[string]'
    $installationPath = Get-VSBuildToolsInstallPath
    $vsDevShell = if (-not [string]::IsNullOrWhiteSpace($installationPath)) { Join-Path $installationPath "Common7\Tools\Launch-VsDevShell.ps1" } else { Get-VsDevShellPath }
    $msbuildPath = if (-not [string]::IsNullOrWhiteSpace($installationPath)) { Join-Path $installationPath "MSBuild\Current\Bin\MSBuild.exe" } else { "" }
    $clPath = ""

    if ([string]::IsNullOrWhiteSpace($installationPath)) {
        [void]$issues.Add("vswhere/default install path did not find a Build Tools instance with the C++ workload.")
    } elseif (-not (Test-Path -LiteralPath $installationPath)) {
        [void]$issues.Add("Build Tools install path does not exist: $installationPath")
    }

    if ([string]::IsNullOrWhiteSpace($vsDevShell) -or -not (Test-Path -LiteralPath $vsDevShell)) {
        [void]$issues.Add("Visual Studio Developer PowerShell launcher was not found.")
    }

    if ([string]::IsNullOrWhiteSpace($msbuildPath) -or -not (Test-Path -LiteralPath $msbuildPath)) {
        [void]$issues.Add("MSBuild.exe was not found under the Build Tools install path.")
    }

    if (-not [string]::IsNullOrWhiteSpace($installationPath)) {
        try {
            $msvcRoot = Join-Path $installationPath "VC\Tools\MSVC"
            if (Test-Path -LiteralPath $msvcRoot) {
                $cl = Get-ChildItem -LiteralPath $msvcRoot -Recurse -Filter cl.exe -ErrorAction SilentlyContinue |
                    Where-Object { $_.FullName -match '\\bin\\Hostx64\\x64\\cl\.exe$' } |
                    Sort-Object LastWriteTime -Descending |
                    Select-Object -First 1
                if ($null -ne $cl) { $clPath = $cl.FullName }
            }
        } catch { }
    }

    if ([string]::IsNullOrWhiteSpace($clPath) -or -not (Test-Path -LiteralPath $clPath)) {
        [void]$issues.Add("MSVC x64 compiler cl.exe was not found.")
    }

    $sdkRoot = "C:\Program Files (x86)\Windows Kits\10"
    if (-not (Test-Path -LiteralPath $sdkRoot)) {
        [void]$issues.Add("Windows 10/11 SDK root was not found.")
    }

    $ready = ($issues.Count -eq 0)
    $partial = (-not [string]::IsNullOrWhiteSpace($installationPath)) -or (Test-Path -LiteralPath "C:\Program Files (x86)\Microsoft Visual Studio\2022\BuildTools") -or (Test-Path -LiteralPath "C:\Program Files (x86)\Microsoft Visual Studio\Installer\vswhere.exe")

    return [pscustomobject]@{
        Ready = $ready
        Partial = [bool]$partial
        InstallationPath = $installationPath
        VsDevShell = $vsDevShell
        MSBuildPath = $msbuildPath
        ClPath = $clPath
        Issues = @($issues.ToArray())
    }
}

function Test-VSBuildToolsReady {
    return [bool](Get-VSBuildToolsValidation).Ready
}

function To-ForwardSlashPath {
    param([string]$Path)
    return ($Path -replace "\\", "/")
}

function Get-AgentEnvironmentValues {
    return [ordered]@{
        SC_STAR_CITIZEN_ROOT = (To-ForwardSlashPath $StarCitizenRoot)
        SC_PROMPTS_ROOT = (To-ForwardSlashPath $AgentPromptsRoot)
        SC_AGENT_WORK_ROOT = (To-ForwardSlashPath $AgentWorkRoot)
        SC_REPORTS_ROOT = (To-ForwardSlashPath $AgentReportsRoot)
        SC_WORKSPACE_PATH = (To-ForwardSlashPath $WorkspacePath)
        SC_GUIDE_REPO = (To-ForwardSlashPath $GuideRepoPath)
    }
}

function Set-AgentEnvironmentVariables {
    param([switch]$PersistUser)
    $values = Get-AgentEnvironmentValues
    foreach ($name in @($values.Keys)) {
        $value = [string]$values[$name]
        Set-Item -Path ("Env:" + $name) -Value $value
        if ($PersistUser -and (-not $Script:NoUserEnvWrites) -and (-not (Test-NonLiveInstallerMode))) {
            Set-UserEnv $name $value
        }
    }
}

function Ensure-AgentSupportFolders {
    @(
        $StarCitizenRoot,
        $AgentPromptsRoot,
        $AgentWorkRoot,
        $AgentOutputRoot,
        $AgentReportsRoot
    ) | ForEach-Object { Ensure-Directory $_ }
}

function Get-AgentGuidanceContent {
    param([ValidateSet("AGENTS","CLAUDE")][string]$Kind = "AGENTS")

    $title = if ($Kind -eq "CLAUDE") { "CLAUDE.md" } else { "AGENTS.md" }
    $marker = "SC-ZERO-TO-HERO-GENERATED: agent-guidance v1"
    $devRootPath = [string]$DevRoot
    $starCitizenRootPath = [string]$StarCitizenRoot
    $guideRepo = [string]$GuideRepoPath
    $workspace = [string]$WorkspacePath
    $pythonVenv = [string]$PythonVenvDir
    $promptsRoot = [string]$AgentPromptsRoot
    $agentWork = [string]$AgentWorkRoot
    $agentOutput = [string]$AgentOutputRoot
    $reportsRoot = [string]$AgentReportsRoot
    $scData = [string]$ScDataRoot
    $scWork = [string]$ScWorkRoot

    return @"
# $title

$marker

This local guidance file was generated by the Star Citizen Zero to Hero installer for the selected DevRoot.

## Resolved Local Paths

- DevRoot: $devRootPath
- StarCitizenRoot: $starCitizenRootPath
- GuideRepoPath: $guideRepo
- WorkspacePath: $workspace
- PythonVenvDir: $pythonVenv
- AgentPromptsRoot: $promptsRoot
- AgentWorkRoot: $agentWork
- AgentOutputRoot: $agentOutput
- AgentReportsRoot: $reportsRoot
- ScDataRoot: $scData
- ScWorkRoot: $scWork

## Path Rules

- Read and write only inside explicitly allowed task roots.
- Treat AgentWorkRoot as the agent work-log and validation-artifact area.
- Treat ScWorkRoot as Star Citizen data/tool working storage, not as the agent log area.
- Do not use arbitrary user profile, Windows, Program Files, AppData, Downloads, Desktop, unrelated drives, or live game-install paths unless the current prompt explicitly authorizes that exact access.
- Do not access, copy, hash, parse, export, or inspect a real Data.p4k unless the current prompt explicitly authorizes it.

## Prompt, Log, And Report Protocol

- Archive the active prompt under AgentPromptsRoot before source edits when a task requires it.
- Keep timestamped work logs under AgentWorkRoot.
- Write final reports under AgentReportsRoot.
- Log commands with working directory, command text, exit code, concise output summary, files inspected, files modified, and decision-log entries.
- Do not log hidden or private chain-of-thought; log concise rationale and observable decisions only.

## Safety Rules

- Do not install, download, clone, launch GUIs, or use network actions unless explicitly authorized.
- Do not run force Git operations, git reset, git clean, git rebase, git push, or remote mutation unless explicitly authorized.
- Do not change global Git config. Repo-local Git config is acceptable only for safe target repos when the task calls for it.
- Do not commit or push unless explicitly authorized.
- Prefer inert validation: git status, git diff, git diff --check, parser checks, HarnessMode PlanOnly, and HarnessMode SelfTest.

## Final Reports

- Include prompt path, work log path, target file, branch/status summary, guardrails honored, files changed, diff summary, validation results, skipped validation with reasons, risks, rollback notes, and the appended work log when the task requires a formal report.
"@
}

function Get-GeneratedGuidanceFallbackPath {
    param([Parameter(Mandatory=$true)][string]$Path)
    $parent = Split-Path $Path -Parent
    $name = [IO.Path]::GetFileNameWithoutExtension($Path)
    $extension = [IO.Path]::GetExtension($Path)
    return (Join-Path $parent ($name + ".generated" + $extension))
}

function Write-GeneratedGuidanceFile {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [Parameter(Mandatory=$true)][string]$Content,
        [Parameter(Mandatory=$true)][string]$Label
    )
    $marker = "SC-ZERO-TO-HERO-GENERATED: agent-guidance v1"
    $fallbackPath = Get-GeneratedGuidanceFallbackPath -Path $Path
    if ($DryRun) {
        Write-Host ("[dry-run] Would write generated {0}: {1}" -f $Label, $Path)
        return [pscustomobject]@{ Status = "Preview"; Path = $Path; FallbackPath = ""; Reason = "" }
    }

    if (-not (Test-Path -LiteralPath $Path)) {
        Write-InstallerFile -Path $Path -Text $Content
        return [pscustomobject]@{ Status = "Created"; Path = $Path; FallbackPath = ""; Reason = "" }
    }

    $existing = ""
    try { $existing = Get-Content -LiteralPath $Path -Raw -ErrorAction Stop } catch { $existing = "" }
    if ($existing -match [regex]::Escape($marker)) {
        Write-InstallerFile -Path $Path -Text $Content
        return [pscustomobject]@{ Status = "Updated"; Path = $Path; FallbackPath = ""; Reason = "" }
    }

    Write-InstallerFile -Path $fallbackPath -Text $Content
    return [pscustomobject]@{
        Status = "WARN"
        Path = $Path
        FallbackPath = $fallbackPath
        Reason = "$Label exists without the generated marker; preserved it and wrote generated fallback."
    }
}

function Write-VSCodeWorkspaceLauncher {
    $workspace = [string]$WorkspacePath
    $launcherText = @"
@echo off
setlocal
set "SC_WORKSPACE=$workspace"

set "CODE_CMD="
if defined SC_VSCODE_CODE (
    if exist "%SC_VSCODE_CODE%" set "CODE_CMD=%SC_VSCODE_CODE%"
)
if not defined CODE_CMD (
    where code.cmd >nul 2>nul
    if not errorlevel 1 set "CODE_CMD=code.cmd"
)
if not defined CODE_CMD (
    where code >nul 2>nul
    if not errorlevel 1 set "CODE_CMD=code"
)
if not defined CODE_CMD (
    echo VS Code CLI was not found.
    echo Install VS Code or set SC_VSCODE_CODE to code.cmd, then reopen:
    echo   %SC_WORKSPACE%
    exit /b 1
)

"%CODE_CMD%" "%SC_WORKSPACE%"
exit /b %ERRORLEVEL%
"@

    if ($DryRun) {
        Write-Host "[dry-run] Would write workspace launcher: $WorkspaceLaunchCmdPath"
        return "Preview"
    }
    Write-InstallerFile -Path $WorkspaceLaunchCmdPath -Text $launcherText
    return "Written"
}

function Write-AgentGuidanceFiles {
    Write-Step "Creating agent guidance and support folders"
    Ensure-AgentSupportFolders
    Set-AgentEnvironmentVariables -PersistUser:((-not $Script:NoUserEnvWrites) -and (-not (Test-NonLiveInstallerMode)))

    $agentsResult = Write-GeneratedGuidanceFile -Path $ProjectAgentsPath -Content (Get-AgentGuidanceContent -Kind "AGENTS") -Label "AGENTS.md"
    $claudeResult = Write-GeneratedGuidanceFile -Path $ProjectClaudePath -Content (Get-AgentGuidanceContent -Kind "CLAUDE") -Label "CLAUDE.md"
    $launcherStatus = Write-VSCodeWorkspaceLauncher

    $warnings = New-Object 'System.Collections.Generic.List[string]'
    foreach ($result in @($agentsResult, $claudeResult)) {
        if ([string]$result.Status -eq "WARN") { [void]$warnings.Add([string]$result.Reason) }
    }

    $Script:AgentGuidanceState = [ordered]@{
        status = if ($warnings.Count -gt 0) { "WARN" } elseif ($DryRun) { "Preview" } else { "OK" }
        reason = if ($warnings.Count -gt 0) { ($warnings.ToArray() -join " ") } else { "" }
        promptsRoot = [string]$AgentPromptsRoot
        workRoot = [string]$AgentWorkRoot
        outputRoot = [string]$AgentOutputRoot
        reportsRoot = [string]$AgentReportsRoot
        agentsPath = [string]$agentsResult.Path
        agentsStatus = [string]$agentsResult.Status
        agentsFallbackPath = [string]$agentsResult.FallbackPath
        claudePath = [string]$claudeResult.Path
        claudeStatus = [string]$claudeResult.Status
        claudeFallbackPath = [string]$claudeResult.FallbackPath
        launcherPath = [string]$WorkspaceLaunchCmdPath
        launcherStatus = [string]$launcherStatus
    }

    Write-Host ("Agent prompt archive: {0}" -f $AgentPromptsRoot) -ForegroundColor Green
    Write-Host ("Agent work logs: {0}" -f $AgentWorkRoot) -ForegroundColor Green
    Write-Host ("Output reports: {0}" -f $AgentReportsRoot) -ForegroundColor Green
    Write-Host ("Workspace launcher: {0}" -f $WorkspaceLaunchCmdPath) -ForegroundColor Green
    if ($warnings.Count -gt 0) {
        $Script:CurrentStepResultStatus = "WARN"
        $Script:CurrentStepResultReason = ($warnings.ToArray() -join " ")
    }
}

function Write-VSCodeWorkspace {
    Write-Step "Creating VS Code workspace"
    Ensure-Directory $WorkspaceRoot

    $dev = To-ForwardSlashPath $DevRoot
    $starRoot = To-ForwardSlashPath $StarCitizenRoot
    $vsDevShell = To-ForwardSlashPath (Get-VsDevShellPath)
    $pythonVenv = To-ForwardSlashPath (Join-Path $PythonVenvDir "Scripts\python.exe")

    $folders = New-Object 'System.Collections.Generic.List[object]'
    foreach ($folder in @(
        @{ name = "Star Citizen Workspace Control"; path = $starRoot },
        @{ name = "Prompt Archive"; path = (To-ForwardSlashPath $AgentPromptsRoot) },
        @{ name = "Agent Work Logs"; path = (To-ForwardSlashPath $AgentWorkRoot) },
        @{ name = "Output Reports"; path = (To-ForwardSlashPath $AgentReportsRoot) },
        @{ name = "StarBreaker"; path = "$starRoot/StarBreaker" },
        @{ name = "Blender-Tools"; path = "$starRoot/Blender-Tools" },
        @{ name = "unp4k"; path = "$starRoot/unp4k" },
        @{ name = "Cryengine-Converter"; path = "$starRoot/Cryengine-Converter" },
        @{ name = "SCTextureConverter"; path = "$starRoot/SCTextureConverter" },
        @{ name = "Zero to Hero Guide"; path = "$starRoot/How-to-Guide-for-Extracting-and-Modding-Star-Citizen-Assets" },
        @{ name = "scdatatools"; path = "$starRoot/scdatatools" },
        @{ name = "qtvscodestyle"; path = "$starRoot/qtvscodestyle" },
        @{ name = "scdata"; path = "$dev/scdata" }
    )) {
        [void]$folders.Add([ordered]@{ name = [string]$folder.name; path = [string]$folder.path })
    }

    $terminalEnv = [ordered]@{
        SC_DEV_ROOT = $dev
        SC_DATA_ROOT = "$dev/scdata"
        SC_P4K_ROOT = "$dev/scdata/p4k"
        SC_EXPORT_ROOT = "$dev/scdata/exports"
        SC_WORK_ROOT = "$dev/scdata/work"
        SC_STAR_CITIZEN_ROOT = (To-ForwardSlashPath $StarCitizenRoot)
        SC_PROMPTS_ROOT = (To-ForwardSlashPath $AgentPromptsRoot)
        SC_AGENT_WORK_ROOT = (To-ForwardSlashPath $AgentWorkRoot)
        SC_REPORTS_ROOT = (To-ForwardSlashPath $AgentReportsRoot)
        SC_WORKSPACE_PATH = (To-ForwardSlashPath $WorkspacePath)
        SC_GUIDE_REPO = (To-ForwardSlashPath $GuideRepoPath)
        SC_BUILD = $StarCitizenBuild
    }

    $confirmedP4k = ""
    try {
        if (-not [string]::IsNullOrWhiteSpace([string]$Script:P4KState.destination)) { $confirmedP4k = [string]$Script:P4KState.destination }
        elseif (-not [string]::IsNullOrWhiteSpace([string]$Script:P4KState.source) -and [string]$Script:P4KState.status -eq "UsingExisting") { $confirmedP4k = [string]$Script:P4KState.source }
    } catch { $confirmedP4k = "" }
    if (-not [string]::IsNullOrWhiteSpace($confirmedP4k)) { $terminalEnv["SC_DATA_P4K"] = (To-ForwardSlashPath $confirmedP4k) }
    if (-not [string]::IsNullOrWhiteSpace([string]$Script:BlenderState.exe)) { $terminalEnv["SC_BLENDER_EXE"] = (To-ForwardSlashPath ([string]$Script:BlenderState.exe)) }
    if (-not [string]::IsNullOrWhiteSpace([string]$Script:BlenderState.version)) { $terminalEnv["SC_BLENDER_VERSION"] = [string]$Script:BlenderState.version }

    $workspaceObject = [ordered]@{
        folders = @($folders.ToArray())
        settings = [ordered]@{
            "terminal.integrated.defaultProfile.windows" = "Developer PowerShell for VS 2022"
            "terminal.integrated.profiles.windows" = [ordered]@{
                "Developer PowerShell for VS 2022" = [ordered]@{
                    source = "PowerShell"
                    args = @("-NoExit", "-ExecutionPolicy", "Bypass", "-Command", "& '$vsDevShell' -Arch amd64")
                }
                PowerShell = [ordered]@{ source = "PowerShell" }
            }
            "terminal.integrated.env.windows" = $terminalEnv
            "python.defaultInterpreterPath" = $pythonVenv
            "files.exclude" = [ordered]@{
                "**/target" = $true
                "**/bin" = $true
                "**/obj" = $true
                "**/__pycache__" = $true
            }
        }
    }

    $workspaceJson = [string]($workspaceObject | ConvertTo-Json -Depth 12)

    if ($DryRun) {
        Write-Host "[dry-run] Would write workspace: $WorkspacePath"
    } else {
        Write-InstallerFile -Path $WorkspacePath -Text $workspaceJson
        Write-Host "Workspace written: $WorkspacePath"
    }
}

function Install-VSCodeExtensions {
    Write-Step "Installing VS Code extensions"
    $codeCmd = Get-VSCodeCommandPath -PromptIfMissing:$PromptForVSCodePath

    if ([string]::IsNullOrWhiteSpace($codeCmd)) {
        Write-Warning "VS Code CLI was not found. Skipping extension installation. Re-run with -PromptForVSCodePath or -VSCodePath after VS Code is installed."
        return
    }

    $extensions = @(
        "ms-python.python",
        "ms-python.vscode-pylance",
        "rust-lang.rust-analyzer",
        "tamasfe.even-better-toml",
        "ms-dotnettools.csdevkit",
        "GitHub.vscode-pull-request-github",
        "jacqueslucke.blender-development",
        "eamodio.gitlens",
        "yzhang.markdown-all-in-one",
        "DavidAnson.vscode-markdownlint",
        "bierner.markdown-mermaid",
        "redhat.vscode-yaml",
        "redhat.vscode-xml",
        "ms-azuretools.vscode-docker",
        "ms-vscode.powershell",
        "EditorConfig.EditorConfig",
        "streetsidesoftware.code-spell-checker",
        "openai.chatgpt"
    )
    $installedExtensions = @()
    try { $installedExtensions = @(& $codeCmd --list-extensions 2>$null) } catch { $installedExtensions = @() }
    foreach ($extension in $extensions) {
        if ($installedExtensions -contains $extension) {
            Write-Host "VS Code extension already installed: $extension" -ForegroundColor Green
            continue
        }
        Run-Native -Exe $codeCmd -Arguments @("--install-extension", $extension) -IgnoreExitCode
    }
    Run-Native -Exe $codeCmd -Arguments @("--list-extensions") -IgnoreExitCode
}


function Build-StarBreakerProject {
    Write-Step "Building StarBreaker and StarBreaker MCP"
    if ($DryRun) {
        Write-Host "[dry-run] Would build StarBreaker and StarBreaker MCP under $StarCitizenRoot"
        return
    }
    $starBreakerPath = Join-Path $StarCitizenRoot "StarBreaker"
    if (-not (Test-Path $starBreakerPath)) { throw "StarBreaker repo not found: $starBreakerPath" }

    $binaryState = Get-StarBreakerReleaseBinaryState -StarBreakerRoot $starBreakerPath
    $starbreakerExe = [string]$binaryState.StarBreakerExe
    $mcpExe = [string]$binaryState.McpExe
    if (Test-BuildToolsSkippedByUserChoice) {
        if ([bool]$binaryState.Ready) {
            $reason = "Build Tools were skipped by user choice; using existing StarBreaker release binaries."
            Write-Warning $reason
            try {
                Run-Native -Exe $starbreakerExe -Arguments @("--help")
                Run-Native -Exe $mcpExe -Arguments @("--help")
            } catch {
                $skipReason = "Build Tools were skipped by user choice and existing StarBreaker release binaries did not validate."
                Write-Warning $skipReason
                Write-Warning $_.Exception.Message
                Set-CurrentSetupStepSkipped -Id "build-starbreaker" -Name "Build StarBreaker and StarBreaker MCP" -Reason $skipReason
                return
            }
            $Script:CurrentStepResultStatus = "WARN"
            $Script:CurrentStepResultReason = $reason
            return
        }
        Set-CurrentSetupStepSkipped -Id "build-starbreaker" -Name "Build StarBreaker and StarBreaker MCP" -Reason "Build Tools were skipped by user choice and no existing StarBreaker release binaries were available to reuse."
        return
    }
    if ([bool]$binaryState.Ready) {
        Write-Host "StarBreaker release executables already exist. Validating and skipping rebuild if they respond." -ForegroundColor Green
        Run-Native -Exe $starbreakerExe -Arguments @("--help") -IgnoreExitCode
        Run-Native -Exe $mcpExe -Arguments @("--help") -IgnoreExitCode
        return
    }

    $vsDevShell = Get-VsDevShellPath
    if (-not (Test-Path $vsDevShell)) {
        throw "Visual Studio Developer Shell script not found: $vsDevShell. Verify Visual Studio Build Tools installed correctly."
    }

    $escapedVs = $vsDevShell.Replace("'", "''")
    $escapedRepo = $starBreakerPath.Replace("'", "''")
    $buildCommand = @"
`$ErrorActionPreference = 'Stop'
& '$escapedVs' -Arch amd64
Set-Location '$escapedRepo'
git branch --show-current
git status --short
cargo build --release -p starbreaker
if (`$LASTEXITCODE -ne 0) { exit `$LASTEXITCODE }
cargo build --release -p starbreaker-mcp
if (`$LASTEXITCODE -ne 0) { exit `$LASTEXITCODE }
.\target\release\starbreaker.exe --help
if (`$LASTEXITCODE -ne 0) { exit `$LASTEXITCODE }
.\target\release\starbreaker-mcp.exe --help
if (`$LASTEXITCODE -ne 0) { exit `$LASTEXITCODE }
"@
    Run-Native -Exe "powershell.exe" -Arguments @("-NoProfile", "-ExecutionPolicy", "Bypass", "-Command", $buildCommand) -WorkingDirectory $starBreakerPath
}

function Test-StarBreakerBlenderAddonDestination {
    param(
        [Parameter(Mandatory=$true)][string]$Source,
        [Parameter(Mandatory=$true)][string]$Destination
    )
    if (-not (Test-Path -LiteralPath $Destination)) { return $false }
    if (-not (Test-Path -LiteralPath $Source)) { return $false }
    try {
        $sample = Get-ChildItem -LiteralPath $Source -Recurse -File -ErrorAction SilentlyContinue | Select-Object -First 1
        if ($null -eq $sample) { return $true }
        $rel = $sample.FullName.Substring($Source.Length).TrimStart([char[]]@('\','/'))
        $dstSample = Join-Path $Destination $rel
        if (-not (Test-Path -LiteralPath $dstSample)) { return $false }
        $dstItem = Get-Item -LiteralPath $dstSample -ErrorAction Stop
        return ([int64]$dstItem.Length -eq [int64]$sample.Length)
    } catch {
        return $false
    }
}

function Resolve-StarBreakerAddonSource {
    # v25: The StarBreaker repository layout has shifted over time. The
    # tutorial documents D:\dev\starcitizen\StarBreaker\blender_addon\
    # starbreaker_addon but the addon has historically also lived under
    # app\blender_addon\ and crates\blender_addon\ depending on the commit
    # the user happens to clone. v25 searches a list of canonical and
    # historical paths in order, then falls back to a bounded recursive
    # scan if none match. A candidate is only accepted if it contains an
    # __init__.py file (real Blender addons always do).
    param([Parameter(Mandatory=$true)][string]$StarBreakerRoot)
    if ([string]::IsNullOrWhiteSpace($StarBreakerRoot) -or -not (Test-Path -LiteralPath $StarBreakerRoot)) {
        return $null
    }
    $candidates = @(
        (Join-Path $StarBreakerRoot "blender_addon\starbreaker_addon"),
        (Join-Path $StarBreakerRoot "app\blender_addon\starbreaker_addon"),
        (Join-Path $StarBreakerRoot "crates\blender_addon\starbreaker_addon"),
        (Join-Path $StarBreakerRoot "app\starbreaker_addon"),
        (Join-Path $StarBreakerRoot "starbreaker_addon")
    )
    foreach ($c in $candidates) {
        try {
            if ((Test-Path -LiteralPath $c) -and (Test-Path -LiteralPath (Join-Path $c "__init__.py"))) {
                return $c
            }
        } catch { }
    }
    # Last-resort recursive scan: find any folder named "starbreaker_addon"
    # under the repo that contains an __init__.py. Skip target/ (Rust build
    # output) and node_modules/ to keep this fast.
    try {
        $hits = @(Get-ChildItem -LiteralPath $StarBreakerRoot -Recurse -Directory `
                                -Filter "starbreaker_addon" -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -notmatch '\\target\\' -and `
                           $_.FullName -notmatch '\\node_modules\\' -and `
                           $_.FullName -notmatch '\\\.git\\' } |
            Where-Object { Test-Path -LiteralPath (Join-Path $_.FullName "__init__.py") } |
            Sort-Object { $_.FullName.Length })
        if ($hits.Count -gt 0) { return $hits[0].FullName }
    } catch { }
    return $null
}

function Install-StarBreakerBlenderAddon {
    Write-Step "Linking StarBreaker Blender add-on"
    if ($SkipBlender) {
        Add-SetupSkipRecord -Id "install-blender-addon" -Name "Link StarBreaker Blender add-on" -Reason "-SkipBlender supplied."
        $Script:CurrentStepResultStatus = "SKIPPED"
        $Script:CurrentStepResultReason = "-SkipBlender supplied."
        return
    }
    if ([string]::IsNullOrWhiteSpace($Script:BlenderState.exe) -or -not (Test-Path -LiteralPath $Script:BlenderState.exe)) {
        Add-SetupSkipRecord -Id "install-blender-addon" -Name "Link StarBreaker Blender add-on" -Reason "No validated Blender install."
        $Script:CurrentStepResultStatus = "SKIPPED"
        $Script:CurrentStepResultReason = "No validated Blender install."
        return
    }
    $running = @(Get-Process -Name blender -ErrorAction SilentlyContinue)
    while ($running.Count -gt 0) {
        Write-Warning "Blender is currently running. Close Blender before linking the add-on."
        foreach ($p in $running) { Write-Host ("  Running: {0} ({1})" -f $p.ProcessName, $p.Id) -ForegroundColor DarkYellow }
        $ans = Read-Host "Press Enter to recheck, or S to skip"
        if ($ans.Trim() -match '^[Ss]$') {
            Add-SetupSkipRecord -Id "install-blender-addon" -Name "Link StarBreaker Blender add-on" -Reason "Blender was running."
            $Script:CurrentStepResultStatus = "SKIPPED"
            $Script:CurrentStepResultReason = "Blender was running."
            return
        }
        $running = @(Get-Process -Name blender -ErrorAction SilentlyContinue)
    }
    # v25: Smart source resolution (see Resolve-StarBreakerAddonSource).
    $starBreakerRoot = Join-Path $StarCitizenRoot "StarBreaker"
    $src = Resolve-StarBreakerAddonSource -StarBreakerRoot $starBreakerRoot
    $versionFolder = if (-not [string]::IsNullOrWhiteSpace($Script:BlenderState.version)) { ($Script:BlenderState.version -replace '^(\d+\.\d+).*','$1') } else { $BlenderVersion }
    $dst = Join-Path $env:APPDATA "Blender Foundation\Blender\$versionFolder\scripts\addons\starbreaker_addon"
    if ($DryRun) {
        $srcShow = if ([string]::IsNullOrWhiteSpace($src)) { "<unresolved - would search '$starBreakerRoot'>" } else { $src }
        Write-Host "[dry-run] Would link Blender add-on: '$dst' -> '$srcShow'"
        return
    }
    if ([string]::IsNullOrWhiteSpace($src)) {
        Write-Warning "StarBreaker add-on source not found under: $starBreakerRoot"
        Write-Warning "Tried canonical 'blender_addon\starbreaker_addon', historical app\ and crates\ locations, and a recursive scan."
        Write-Warning "Tip: confirm StarBreaker cloned successfully and contains a 'starbreaker_addon' folder with __init__.py somewhere underneath."
        $Script:CurrentStepResultStatus = "FAILED"
        $Script:CurrentStepResultReason = "StarBreaker add-on source not found under: $starBreakerRoot"
        return
    }
    Write-Host "StarBreaker add-on source resolved: $src" -ForegroundColor DarkGreen
    Ensure-Directory (Split-Path $dst -Parent)
    if (Test-Path -LiteralPath $dst) {
        # v25: Stale-junction detection. If the destination is a reparse
        # point (junction or symlink) whose target is no longer reachable,
        # treat it as broken and replace it silently. This handles the case
        # where a prior run junctioned to a folder that has since moved,
        # been renamed, or been removed by an upstream layout change.
        $existingIsStale = $false
        try {
            $existingItem = Get-Item -LiteralPath $dst -Force -ErrorAction Stop
            $isReparse = ($existingItem.Attributes -band [IO.FileAttributes]::ReparsePoint) -ne 0
            if ($isReparse) {
                $initPyThroughLink = Join-Path $dst "__init__.py"
                if (-not (Test-Path -LiteralPath $initPyThroughLink)) {
                    $existingIsStale = $true
                    Write-Warning "Existing Blender add-on link at $dst points at a target that is no longer reachable. It will be repaired."
                }
            }
        } catch { }
        if ($existingIsStale) {
            try { Remove-Item -LiteralPath $dst -Recurse -Force -ErrorAction Stop } catch {
                Write-Warning "Could not remove stale link at $dst : $($_.Exception.Message)"
            }
        } elseif (Test-StarBreakerBlenderAddonDestination -Source $src -Destination $dst) {
            Write-Host "Existing StarBreaker add-on destination validates: $dst" -ForegroundColor Green
            $Script:BlenderState.addonLinked = $true
            $Script:BlenderState.addonLinkType = "existing"
            return
        } else {
            Write-Warning "An existing Blender add-on folder is present but was not validated as this StarBreaker add-on: $dst"
            $choice = ""
            if ($ReplaceBlenderAddonLink) { $choice = "R" }
            else {
                Write-Host "Choose how to handle the existing add-on folder:" -ForegroundColor Cyan
                Write-Host "  K = keep existing and skip this step"
                Write-Host "  R = replace existing"
                Write-Host "  B = backup then replace"
                Write-Host "  S = skip"
                $choice = Read-Host "Existing add-on choice [K/R/B/S, default K]"
                if ([string]::IsNullOrWhiteSpace($choice)) { $choice = "K" }
            }
            if ($choice.Trim() -match '^[KkSs]$') {
                Add-SetupSkipRecord -Id "install-blender-addon" -Name "Link StarBreaker Blender add-on" -Reason "Existing add-on folder was kept."
                $Script:CurrentStepResultStatus = "SKIPPED"
                $Script:CurrentStepResultReason = "Existing add-on folder was kept."
                return
            }
            if ($choice.Trim() -match '^[Bb]$') {
                $backupName = "starbreaker_addon.backup.{0}" -f (Get-Date).ToString('yyyyMMddHHmmss')
                Rename-Item -LiteralPath $dst -NewName $backupName -ErrorAction Stop
            } else {
                Remove-Item -LiteralPath $dst -Recurse -Force -ErrorAction Stop
            }
        }
    }
    try {
        New-Item -ItemType Junction -Path $dst -Target $src | Out-Null
        $Script:BlenderState.addonLinked = $true
        $Script:BlenderState.addonLinkType = "junction"
    } catch {
        Write-Warning "Junction failed: $($_.Exception.Message)"
        $ans = Read-Host "Copy add-on folder instead? Y/N"
        if ($ans.Trim() -match '^[Yy]') {
            Copy-Item -LiteralPath $src -Destination $dst -Recurse -Force
            $Script:BlenderState.addonLinked = $true
            $Script:BlenderState.addonLinkType = "copy"
        }
    }
    # v25: Post-link validation. Whatever method we used to populate the
    # destination, make sure __init__.py is actually reachable through it.
    # If the link or copy "worked" but the addon's entry point isn't
    # visible to Blender, the next step would silently fail with no
    # diagnostic. Fail loudly here instead.
    if ($Script:BlenderState.addonLinked) {
        $initPyAfter = Join-Path $dst "__init__.py"
        if (-not (Test-Path -LiteralPath $initPyAfter)) {
            Write-Warning "The link/copy at $dst was created but __init__.py is not visible through it."
            Write-Warning "Blender will not find this add-on. Most common cause: the link points at a folder without __init__.py (wrong source) or the filesystem does not support junctions/symlinks for this path."
            $Script:BlenderState.addonLinked = $false
            $Script:BlenderState.addonLinkType = ""
            $Script:CurrentStepResultStatus = "FAILED"
            $Script:CurrentStepResultReason = "Add-on destination created but __init__.py is not reachable through it."
            Add-SetupFailureRecord -Id "install-blender-addon" -Name "Link StarBreaker Blender add-on" -Reason $Script:CurrentStepResultReason -LogPath ""
            return
        }
        Write-Host "StarBreaker add-on linked: $dst" -ForegroundColor Green
        Write-Host "Link type: $($Script:BlenderState.addonLinkType); __init__.py reachable through link." -ForegroundColor DarkGreen
        Write-Host "Open Blender: Edit -> Preferences -> Add-ons -> search StarBreaker -> enable the add-on." -ForegroundColor Cyan
    } else {
        $Script:CurrentStepResultStatus = "SKIPPED"
        $Script:CurrentStepResultReason = "Add-on was not linked."
        Add-SetupSkipRecord -Id "install-blender-addon" -Name "Link StarBreaker Blender add-on" -Reason "Add-on was not linked."
    }
}

function Prepare-DataP4k {
    if (-not [string]::IsNullOrWhiteSpace($Script:P4KState.destination) -and (Test-Path -LiteralPath $Script:P4KState.destination)) {
        return $Script:P4KState.destination
    }
    if (-not [string]::IsNullOrWhiteSpace($DataP4kSource)) {
        Select-OrCopyDataP4k
        if (-not [string]::IsNullOrWhiteSpace($Script:P4KState.destination) -and (Test-Path -LiteralPath $Script:P4KState.destination)) { return $Script:P4KState.destination }
    }
    $buildForP4K = if (-not [string]::IsNullOrWhiteSpace($Script:P4KState.build)) { $Script:P4KState.build } else { $StarCitizenBuild }
    $targetDir = Join-Path $ScP4kRoot $buildForP4K
    $targetP4k = Join-Path $targetDir "Data.p4k"
    if (Test-Path -LiteralPath $targetP4k) {
        $Script:P4KState.destination = $targetP4k
        $Script:P4KState.build = $buildForP4K
        $Script:P4KState.status = "OK"
        Set-UserEnv "SC_BUILD" $buildForP4K
        Set-UserEnv "SC_DATA_P4K" $targetP4k
        return $targetP4k
    }
    Write-Warning "Data.p4k not found at expected path: $targetP4k"
    return $null
}


function Find-AuroraExportSceneJson {
    param([Parameter(Mandatory=$true)][string]$ExportDir)
    if (-not (Test-Path -LiteralPath $ExportDir)) { return "" }
    $preferred = Join-Path $ExportDir "Packages\RSI Aurora MR_LOD1_TEX2\scene.json"
    if (Test-Path -LiteralPath $preferred) { return $preferred }
    $candidates = @(Get-ChildItem -LiteralPath $ExportDir -Recurse -Filter scene.json -ErrorAction SilentlyContinue | Sort-Object FullName)
    foreach ($c in $candidates) {
        if ($c.FullName -match '(?i)Aurora.*MR|RSI.*Aurora') { return $c.FullName }
    }
    if ($candidates.Count -gt 0) { return $candidates[0].FullName }
    return ""
}

function Open-AuroraExportInBlender {
    param(
        [Parameter(Mandatory=$true)][string]$SceneJson,
        [Parameter(Mandatory=$true)][string]$ExportDir
    )
    if ($NoOpenBlenderAfterExport) {
        Set-CurrentSetupStepSkipped -Id "aurora-example" -Name "Optional Aurora MR export example" -Reason "Blender open skipped because NoOpenBlenderAfterExport was set."
        return
    }
    if ([string]::IsNullOrWhiteSpace($SceneJson) -or -not (Test-Path -LiteralPath $SceneJson)) {
        Write-Warning "Could not find Aurora scene.json to open in Blender. Expected under: $ExportDir"
        Set-CurrentSetupStepSkipped -Id "aurora-example" -Name "Optional Aurora MR export example" -Reason "Blender open skipped because Aurora scene.json was not found."
        return
    }
    $blenderExe = [string]$Script:BlenderState.exe
    if ([string]::IsNullOrWhiteSpace($blenderExe) -or -not (Test-Path -LiteralPath $blenderExe)) {
        Write-Host "Aurora export succeeded. Open this scene manually in Blender with the StarBreaker add-on:" -ForegroundColor Cyan
        Write-Host "  $SceneJson" -ForegroundColor Yellow
        Set-CurrentSetupStepSkipped -Id "aurora-example" -Name "Optional Aurora MR export example" -Reason "Blender open skipped because Blender executable was not selected."
        return
    }

    Ensure-Directory $ScWorkRoot
    $pyPath = Join-Path $ScWorkRoot "open_aurora_mr_in_blender.py"
    $logPath = Join-Path $ScWorkRoot "open_aurora_mr_in_blender.log"

    # v24 rewrite of the Blender import helper.
    #
    # Three v23 bugs that prevented the auto-import from ever working:
    #
    #   1. v23 hardcoded six guesses at the StarBreaker import operator name
    #      (starbreaker.import_package, import_scene.starbreaker_package, etc.).
    #      If none of those match the addon's actual bl_idname, nothing imports
    #      and Blender just opens to an empty scene. We have no way of knowing
    #      the addon's exact operator name from outside Blender, so v24
    #      discovers it at runtime: enumerate bpy.ops, find namespaces that
    #      mention StarBreaker, look at each operator's bl_rna properties for
    #      a filepath-like field, score them by name keywords, and try them
    #      in order. Whatever the addon called the operator, this will find it.
    #
    #   2. v23 embedded the scene-json path in the Python source as a raw
    #      string after a Replace('\\','/') call. That Replace is a no-op on
    #      ordinary Windows paths because '\\' in a PowerShell single-quoted
    #      string is two characters and Windows paths only have single
    #      backslashes. The Replace("'","\\'") tried to handle apostrophes
    #      but Python raw strings can't escape apostrophes either, so any
    #      path with one would syntax-error the entire helper. v24 passes
    #      the path through environment variables instead, sidestepping every
    #      Python string-escaping concern.
    #
    #   3. v23 created an instruction text block when auto-import failed,
    #      but left the user on the Layout workspace where the Text Editor
    #      isn't visible. v24 switches to the Scripting workspace so the
    #      instructions are actually seen.
    #
    # Using @'...'@ (single-quoted here-string) so PowerShell does NO
    # interpolation on the Python source. All dynamic values flow through
    # SC_AURORA_* environment variables.
    $py = @'
import bpy
import os
import sys
import time
import traceback
import importlib
from pathlib import Path

scene_json = os.environ.get('SC_AURORA_SCENE_JSON', '')
log_path = os.environ.get('SC_AURORA_HELPER_LOG', '')
addon_modname = 'starbreaker_addon'
addon_pkg = None
runtime_mod = None
package_root = None
import_succeeded = False
import_method_used = ''
progress_last = 0.0


def log(msg):
    line = '[SC-Aurora-Helper] ' + str(msg)
    print(line)
    if log_path:
        try:
            with open(log_path, 'a', encoding='utf-8') as f:
                f.write(str(msg) + '\n')
        except Exception:
            pass


def log_exc(label, exc):
    log(label + ': ' + str(exc))
    try:
        log(traceback.format_exc())
    except Exception:
        pass


log('Helper starting.')
log('scene_json=' + scene_json)
log('log_path=' + log_path)
log('Blender version=' + bpy.app.version_string)

scene_exists = bool(scene_json) and os.path.isfile(scene_json)
if not scene_exists:
    log('Scene JSON missing or not a file on disk; will still try to enable the addon and show instructions.')


# ---------------------------------------------------------------------------
# Add-on enable/import
# ---------------------------------------------------------------------------
addon_enabled = False
try:
    bpy.ops.preferences.addon_enable(module=addon_modname)
    log('Enabled addon module: ' + addon_modname)
    addon_enabled = True
except Exception as exc:
    log('Could not enable expected addon module ' + addon_modname + ': ' + str(exc))
    try:
        import addon_utils
        all_mods = [m.__name__ for m in addon_utils.modules()]
        sb_mods = [m for m in all_mods if 'starbreaker' in m.lower()]
        log('StarBreaker-like add-on modules visible to Blender: ' + (', '.join(sb_mods) if sb_mods else '<none>'))
        for m in sb_mods:
            try:
                bpy.ops.preferences.addon_enable(module=m)
                log('Enabled alternate addon module: ' + m)
                addon_modname = m
                addon_enabled = True
                break
            except Exception as e2:
                log('  failed to enable ' + m + ': ' + str(e2))
    except Exception as exc2:
        log('Could not enumerate installed addons: ' + str(exc2))

try:
    addon_pkg = importlib.import_module(addon_modname)
    log('Imported add-on package: ' + addon_pkg.__name__ + ' version=' + str(getattr(addon_pkg, 'VERSION', '<unknown>')))
except Exception as exc:
    log_exc('Could not import add-on package after enabling it', exc)
    addon_pkg = None

try:
    runtime_mod = importlib.import_module(addon_modname + '.runtime')
    log('Imported runtime module: ' + runtime_mod.__name__)
except Exception as exc:
    log_exc('Could not import StarBreaker runtime module', exc)
    runtime_mod = None


def runtime_const(name, fallback):
    try:
        if runtime_mod is not None:
            return getattr(runtime_mod, name, fallback)
    except Exception:
        pass
    return fallback

PROP_PACKAGE_ROOT = runtime_const('PROP_PACKAGE_ROOT', 'starbreaker_package_root')
PROP_SCENE_PATH = runtime_const('PROP_SCENE_PATH', 'starbreaker_scene_path')


def remove_default_scene_objects():
    removed = []
    for name in ('Cube',):
        obj = bpy.data.objects.get(name)
        if obj is not None and not obj.get(PROP_PACKAGE_ROOT) and not obj.get('starbreaker_package_root'):
            bpy.data.objects.remove(obj, do_unlink=True)
            removed.append(name)
    if removed:
        log('Removed default scene objects: ' + ', '.join(removed))


def progress_callback(fraction, description):
    global progress_last
    now = time.monotonic()
    if now - progress_last < 0.75 and fraction < 1.0:
        return
    progress_last = now
    try:
        pct = int(round(max(0.0, min(1.0, float(fraction))) * 100.0))
    except Exception:
        pct = 0
    log('Import progress: {0}% - {1}'.format(pct, description))
    try:
        bpy.context.window_manager.progress_update(pct)
    except Exception:
        pass
    try:
        bpy.ops.wm.redraw_timer(type='DRAW_WIN_SWAP', iterations=1)
    except Exception:
        pass


# ---------------------------------------------------------------------------
# Import package
# ---------------------------------------------------------------------------
if scene_exists and addon_enabled:
    try:
        remove_default_scene_objects()
    except Exception as exc:
        log_exc('remove_default_scene_objects failed', exc)

    # Preferred path: direct runtime API. It preserves StarBreaker metadata better
    # than trying to enumerate dynamic bpy.ops proxies.
    if runtime_mod is not None and hasattr(runtime_mod, 'import_package'):
        try:
            log('Calling direct API: {0}.runtime.import_package'.format(addon_modname))
            try:
                bpy.context.window_manager.progress_begin(0, 100)
            except Exception:
                pass
            package_root = runtime_mod.import_package(
                bpy.context,
                scene_json,
                prefer_cycles=True,
                palette_id=None,
                progress_callback=progress_callback,
            )
            try:
                bpy.context.window_manager.progress_end()
            except Exception:
                pass
            if package_root is not None:
                import_succeeded = True
                import_method_used = addon_modname + '.runtime.import_package'
                log('Direct API import completed. Package root=' + getattr(package_root, 'name', '<unnamed>'))
            else:
                log('Direct API returned no package root; will search the scene and/or try operator fallback.')
        except Exception as exc:
            try:
                bpy.context.window_manager.progress_end()
            except Exception:
                pass
            log_exc('Direct API import failed', exc)

    # Secondary fallback: known operator id. Do not depend on dir(bpy.ops.starbreaker),
    # because dynamic operator proxies do not reliably enumerate custom operators.
    if not import_succeeded:
        try:
            log('Trying known operator: bpy.ops.starbreaker.import_decomposed_package(filepath=scene_json)')
            result = bpy.ops.starbreaker.import_decomposed_package(filepath=scene_json)
            log('Known operator result=' + repr(result))
            if result and 'CANCELLED' not in result and 'FAILED' not in result:
                import_succeeded = True
                import_method_used = 'bpy.ops.starbreaker.import_decomposed_package'
        except Exception as exc:
            log_exc('Known operator import_decomposed_package failed', exc)


# ---------------------------------------------------------------------------
# Root discovery and visualization helpers
# ---------------------------------------------------------------------------
def is_starbreaker_root(obj):
    if obj is None:
        return False
    try:
        if bool(obj.get(PROP_PACKAGE_ROOT, False)):
            return True
    except Exception:
        pass
    try:
        if bool(obj.get('starbreaker_package_root', False)):
            return True
    except Exception:
        pass
    return False


def object_scene_path(obj):
    for key in (PROP_SCENE_PATH, 'starbreaker_scene_path', 'scene_path'):
        try:
            value = obj.get(key)
            if isinstance(value, str) and value:
                return value
        except Exception:
            pass
    return ''


def score_root_candidate(obj):
    score = 0
    name = getattr(obj, 'name', '') or ''
    lower = name.lower()
    if obj is package_root:
        score += 1000
    if is_starbreaker_root(obj):
        score += 500
    osp = object_scene_path(obj)
    if osp:
        if os.path.normcase(os.path.abspath(osp)) == os.path.normcase(os.path.abspath(scene_json)):
            score += 400
        else:
            score += 80
    if 'starbreaker' in lower:
        score += 80
    if 'aurora' in lower:
        score += 80
    if 'mr' in lower:
        score += 25
    if obj.parent is None:
        score += 20
    return score


def find_package_root_object():
    global package_root
    if package_root is not None and package_root.name in bpy.data.objects:
        return package_root
    candidates = []
    for obj in bpy.data.objects:
        sc = score_root_candidate(obj)
        if sc > 0:
            candidates.append((sc, obj.name, obj))
    candidates.sort(key=lambda x: (x[0], x[1]), reverse=True)
    if candidates:
        root = candidates[0][2]
        log('Resolved package root candidate: {0} score={1}'.format(root.name, candidates[0][0]))
        package_root = root
        return root
    log('No StarBreaker package root candidate found.')
    return None


def descendants(root):
    if root is None:
        return []
    try:
        return list(root.children_recursive)
    except Exception:
        out = []
        stack = list(getattr(root, 'children', []))
        while stack:
            item = stack.pop(0)
            out.append(item)
            stack.extend(list(getattr(item, 'children', [])))
        return out


def imported_objects(root):
    objs = []
    if root is not None:
        objs.append(root)
        objs.extend(descendants(root))
    if not objs:
        for obj in bpy.data.objects:
            nm = (obj.name or '').lower()
            if 'starbreaker' in nm or 'aurora' in nm:
                objs.append(obj)
    # Remove duplicates preserving order.
    seen = set()
    unique = []
    for obj in objs:
        if obj.name not in seen:
            seen.add(obj.name)
            unique.append(obj)
    return unique


def force_visible(objs):
    for obj in objs:
        try:
            obj.hide_set(False)
        except Exception:
            pass
        try:
            obj.hide_viewport = False
        except Exception:
            pass
        try:
            obj.hide_select = False
        except Exception:
            pass
    # Unhide collections that contain imported objects.
    for col in bpy.data.collections:
        try:
            lname = col.name.lower()
            if 'starbreaker' in lname or 'aurora' in lname:
                col.hide_viewport = False
        except Exception:
            pass


def mesh_focus_objects(root):
    objs = []
    for obj in imported_objects(root):
        if obj.type != 'MESH':
            continue
        data = getattr(obj, 'data', None)
        if data is None:
            continue
        try:
            if len(data.vertices) == 0:
                continue
        except Exception:
            pass
        objs.append(obj)
    if not objs:
        for obj in bpy.data.objects:
            if obj.type == 'MESH' and 'cube' not in obj.name.lower():
                objs.append(obj)
    return objs


def bounds_for_objects(objs):
    import mathutils
    corners = []
    for obj in objs:
        try:
            bbox = getattr(obj, 'bound_box', None)
            if not bbox:
                continue
            mw = obj.matrix_world
            for corner in bbox:
                corners.append(mw @ mathutils.Vector(corner))
        except Exception:
            pass
    if not corners:
        return None
    min_v = mathutils.Vector((min(v.x for v in corners), min(v.y for v in corners), min(v.z for v in corners)))
    max_v = mathutils.Vector((max(v.x for v in corners), max(v.y for v in corners), max(v.z for v in corners)))
    center = (min_v + max_v) * 0.5
    diagonal = (max_v - min_v).length
    if diagonal <= 1e-6:
        diagonal = 1.0
    return min_v, max_v, center, diagonal


def select_root_only(root):
    try:
        bpy.ops.object.select_all(action='DESELECT')
    except Exception:
        pass
    if root is not None:
        try:
            root.select_set(True)
            bpy.context.view_layer.objects.active = root
        except Exception:
            pass


def finalize_view(label='finalize'):
    import mathutils
    root = find_package_root_object()
    objs = imported_objects(root)
    force_visible(objs)
    meshes = mesh_focus_objects(root)
    bounds = bounds_for_objects(meshes)
    if not meshes:
        log(label + ': no mesh objects found to frame.')
    else:
        log(label + ': framing {0} mesh object(s).'.format(len(meshes)))

    # Let the add-on perform its own preferred view/animation handling first.
    if root is not None:
        try:
            ui = importlib.import_module(addon_modname + '.ui')
            if hasattr(ui, '_auto_apply_landing_gear_snap_last'):
                ui._auto_apply_landing_gear_snap_last(bpy.context, root)
                log(label + ': applied StarBreaker landing-gear snap-last helper.')
            if hasattr(ui, '_finalize_import_view'):
                ui._finalize_import_view(bpy.context, root)
                log(label + ': ran StarBreaker _finalize_import_view helper.')
        except Exception as exc:
            log_exc(label + ': StarBreaker UI helper calls failed', exc)

    # Generic fallback framing. This is intentionally independent from the add-on
    # so the user is not left in an apparently empty/botched viewport if helper
    # functions change between StarBreaker releases.
    try:
        if bounds is not None:
            _, _, center, diagonal = bounds
            view_direction = mathutils.Vector((-0.735, -0.487, -0.650)).normalized()
            rotation = view_direction.to_track_quat('-Z', 'Y')
            for area in (bpy.context.screen.areas if bpy.context.screen else []):
                if area.type != 'VIEW_3D':
                    continue
                region = next((r for r in area.regions if r.type == 'WINDOW'), None)
                if region is None:
                    continue
                space = area.spaces.active
                try:
                    space.show_region_ui = True
                except Exception:
                    pass
                try:
                    space.overlay.show_overlays = False
                except Exception:
                    pass
                try:
                    space.shading.type = 'SOLID'
                    space.shading.show_xray = False
                except Exception:
                    pass
                try:
                    space.clip_start = min(0.01, max(0.001, diagonal / 1000000.0))
                    space.clip_end = max(10000.0, diagonal * 20.0, 1000000.0)
                except Exception:
                    pass
                r3d = getattr(space, 'region_3d', None)
                if r3d is not None:
                    r3d.view_perspective = 'PERSP'
                    r3d.view_rotation = rotation
                    r3d.view_location = center
                    r3d.view_distance = max(diagonal * 1.15, 1.0)
                try:
                    with bpy.context.temp_override(area=area, region=region, space_data=space):
                        bpy.ops.object.select_all(action='DESELECT')
                        for obj in meshes:
                            obj.select_set(True)
                        if meshes:
                            bpy.context.view_layer.objects.active = meshes[0]
                            bpy.ops.view3d.view_selected(use_all_regions=False)
                except Exception as exc:
                    log(label + ': view_selected fallback failed in one viewport: ' + str(exc))
            log(label + ': generic viewport framing completed. diagonal={0:.3f}'.format(diagonal))
    except Exception as exc:
        log_exc(label + ': generic viewport framing failed', exc)

    select_root_only(root)
    return root


def switch_workspace(name):
    try:
        target_ws = None
        for ws in bpy.data.workspaces:
            if ws.name.strip().lower() == name.lower():
                target_ws = ws
                break
        if target_ws is not None and bpy.context.window is not None:
            bpy.context.window.workspace = target_ws
            log('Switched to ' + target_ws.name + ' workspace.')
            return True
    except Exception as exc:
        log('Workspace switch to ' + name + ' failed: ' + str(exc))
    return False


def create_status_text(root=None):
    try:
        existing = bpy.data.texts.get('SC Zero to Hero - Aurora Import')
        if existing is not None:
            bpy.data.texts.remove(existing)
        text = bpy.data.texts.new('SC Zero to Hero - Aurora Import')
        lines = []
        lines.append('Star Citizen Aurora MR Import Helper')
        lines.append('=' * 40)
        lines.append('')
        if import_succeeded:
            lines.append('Auto-import completed successfully.')
            lines.append('  method: ' + import_method_used)
            lines.append('  scene:  ' + scene_json)
            if root is not None:
                lines.append('  root:   ' + getattr(root, 'name', '<unnamed>'))
            lines.append('')
            lines.append('The helper selected/framed the Aurora root, opened the N-panel,')
            lines.append('disabled viewport overlays, and attempted Landing Gear Retract -> Last.')
            lines.append('')
            lines.append('If you do not see the StarBreaker animation panel:')
            lines.append('  1. Press N in the 3D Viewport.')
            lines.append('  2. Click the StarBreaker tab on the right side panel.')
            lines.append('  3. Select the package root in the Outliner.')
        else:
            if not scene_exists:
                lines.append('Auto-import did not run because scene.json was not found on disk:')
                lines.append('  ' + (scene_json or '(empty path)'))
            elif not addon_enabled:
                lines.append('The StarBreaker add-on could not be enabled automatically.')
                lines.append('Open Edit -> Preferences -> Add-ons, search StarBreaker, and enable it.')
            else:
                lines.append('Auto-import did not complete. Review the helper log for the exception.')
        lines.append('')
        lines.append('Manual import fallback:')
        lines.append('  1. Press N in the 3D Viewport to open the side panel.')
        lines.append('  2. Click the StarBreaker tab.')
        lines.append('  3. Click Import StarBreaker Package.')
        lines.append('  4. Select this file:')
        lines.append('     ' + (scene_json or '(scene.json path not provided)'))
        lines.append('')
        lines.append('Helper log: ' + (log_path or '(none)'))
        text.write('\n'.join(lines))
        log('Instruction/status text block created in Blender.')
    except Exception as exc:
        log_exc('Could not create instruction text block', exc)


def deferred_finalize(label):
    def _run():
        try:
            root = finalize_view(label)
            create_status_text(root)
            switch_workspace('Layout' if import_succeeded else 'Scripting')
        except Exception as exc:
            log_exc(label + ' deferred finalize failed', exc)
        return None
    return _run


# Immediate finish pass.
root = finalize_view('immediate') if import_succeeded else find_package_root_object()
create_status_text(root)
switch_workspace('Layout' if import_succeeded else 'Scripting')

# Schedule deferred passes after Blender's UI has fully settled. This fixes the
# common case where --python runs before viewport areas are ready to frame.
try:
    bpy.app.timers.register(deferred_finalize('deferred-0.75s'), first_interval=0.75)
    bpy.app.timers.register(deferred_finalize('deferred-2.00s'), first_interval=2.00)
    log('Scheduled deferred viewport/add-on finalization passes.')
except Exception as exc:
    log_exc('Could not schedule deferred finalize timers', exc)

log('Helper finished. import_succeeded={0} method={1}'.format(import_succeeded, import_method_used or '<none>'))
'@
    $utf8 = New-Object System.Text.UTF8Encoding($false)
    [IO.File]::WriteAllText($pyPath, $py, $utf8)
    # Truncate prior helper log so the user only sees this run's output.
    try { if (Test-Path -LiteralPath $logPath) { Remove-Item -LiteralPath $logPath -Force -ErrorAction SilentlyContinue } } catch { }

    Write-Host "Opening Blender with Aurora MR import helper..." -ForegroundColor Cyan
    Write-Host "Scene: $SceneJson" -ForegroundColor Yellow
    Write-Host "Helper log: $logPath" -ForegroundColor DarkGray
    Write-Host "If auto-import does not happen, follow the instructions in Blender's Text Editor (Scripting workspace)." -ForegroundColor DarkYellow
    try {
        # Pass the paths to the Python helper via environment variables so we
        # don't have to escape them through a PowerShell -> Python string.
        $env:SC_AURORA_SCENE_JSON = $SceneJson
        $env:SC_AURORA_HELPER_LOG = $logPath
        Start-InstallerGuiProcess -FilePath $blenderExe -ArgumentList @("--python", $pyPath)
    } catch {
        Write-Warning "Could not launch Blender automatically: $($_.Exception.Message)"
        Write-Host "Open Blender manually and import:" -ForegroundColor Cyan
        Write-Host "  $SceneJson" -ForegroundColor Yellow
    }
}

function Show-SetupOutcomeSummary {
    if ($Script:HiddenDryRun) { return }

    $failures = New-Object 'System.Collections.Generic.List[object]'
    $skips = New-Object 'System.Collections.Generic.List[object]'
    try { foreach ($f in (Get-ListSnapshot $Script:SetupFailures)) { if ($null -ne $f) { [void]$failures.Add($f) } } } catch { }
    try { foreach ($s in (Get-ListSnapshot $Script:SetupSkips)) { if ($null -ne $s) { [void]$skips.Add($s) } } } catch { }

    # Some steps mark themselves failed through StepTimings without adding a
    # failure record. Include those so the final banner never says success when
    # the dashboard shows a failed step.
    try {
        foreach ($r in (Get-ListSnapshot $Script:StepTimings)) {
            if ($null -eq $r) { continue }
            $status = [string]$r.Status
            if ($status -match '^(FAIL|FAILED|FATAL)$') {
                $id = [string]$r.Id
                $already = $false
                foreach ($f in @($failures.ToArray())) { try { if ([string]$f.Id -eq $id) { $already = $true; break } } catch { } }
                if (-not $already) {
                    [void]$failures.Add([pscustomobject]@{
                        Id = $id
                        Name = [string]$r.Name
                        Reason = [string]$r.Reason
                        LogPath = [string]$Script:LastCommandLogPath
                        Fatal = ($status -eq 'FATAL')
                        Time = (Get-Date).ToString('s')
                    })
                }
            }
        }
    } catch { }

    $failureCount = [int]$failures.Count
    $skipCount = [int]$skips.Count
    $warningCount = @($Script:StepTimings | Where-Object { [string]$_.Status -eq "WARN" }).Count

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor DarkCyan
    if ($failureCount -eq 0 -and $skipCount -eq 0 -and $warningCount -eq 0) {
        Write-Host " SETUP FINISHED SUCCESSFULLY" -ForegroundColor Green
    } elseif ($Script:FatalFailure) {
        Write-Host " SETUP STOPPED AFTER A FATAL PRE-FLIGHT FAILURE" -ForegroundColor Red
    } else {
        Write-Host (" SETUP FINISHED WITH " + $failureCount + " FAILED STEP(S), " + $warningCount + " WARNING STEP(S), AND " + $skipCount + " SKIPPED STEP(S)") -ForegroundColor Yellow
    }
    Write-Host "================================================================" -ForegroundColor DarkCyan

    if ($failureCount -gt 0) {
        Write-Host "FAILED STEPS:" -ForegroundColor Red
        foreach ($f in $failures) {
            $name = ""; $id = ""; $reason = ""; $logPath = ""
            try { $name = [string]$f.Name } catch { }
            try { $id = [string]$f.Id } catch { }
            try { $reason = [string]$f.Reason } catch { }
            try { $logPath = [string]$f.LogPath } catch { }
            Write-Host ("  - " + $name + " (" + $id + ")") -ForegroundColor Red
            if (-not [string]::IsNullOrWhiteSpace($reason)) { Write-Host ("    Reason: " + $reason) -ForegroundColor DarkYellow }
            if (-not [string]::IsNullOrWhiteSpace($logPath)) { Write-Host ("    Log: " + $logPath) -ForegroundColor DarkGray }
        }
    }

    if ($skipCount -gt 0) {
        Write-Host "SKIPPED STEPS:" -ForegroundColor Yellow
        foreach ($s in $skips) {
            $name = ""; $id = ""; $reason = ""
            try { $name = [string]$s.Name } catch { }
            try { $id = [string]$s.Id } catch { }
            try { $reason = [string]$s.Reason } catch { }
            Write-Host ("  - " + $name + " (" + $id + ")") -ForegroundColor Yellow
            if (-not [string]::IsNullOrWhiteSpace($reason)) { Write-Host ("    Reason: " + $reason) -ForegroundColor DarkYellow }
        }
    }

    if ($Script:BranchStates.Count -gt 0) {
        Write-Host "GIT VERSIONING STATUS:" -ForegroundColor Cyan
        foreach ($b in (Get-ListSnapshot $Script:BranchStates)) {
            $color = switch ([string]$b.Status) {
                "OK" { "Green" }
                "WARN" { "Yellow" }
                "SKIPPED" { "DarkYellow" }
                default { "Red" }
            }
            Write-Host ("  - {0} -> {1}: {2}" -f [string]$b.Repo, [string]$b.Branch, [string]$b.Status) -ForegroundColor $color
            if (-not [string]::IsNullOrWhiteSpace([string]$b.IdentityStatus)) { Write-Host ("    Identity: " + [string]$b.IdentityStatus) -ForegroundColor DarkCyan }
            if (-not [string]::IsNullOrWhiteSpace([string]$b.CurrentBranch)) { Write-Host ("    Current branch: " + [string]$b.CurrentBranch) -ForegroundColor DarkCyan }
            if (-not [string]::IsNullOrWhiteSpace([string]$b.Reason)) { Write-Host ("    Reason: " + [string]$b.Reason) -ForegroundColor DarkYellow }
        }
    }

    $toolStates = @(Get-ToolStatePlainList)
    if ($toolStates.Count -gt 0) {
        Write-Host "TOOL VALIDATION STATUS:" -ForegroundColor Cyan
        foreach ($tool in $toolStates) {
            $status = [string]$tool.status
            $color = switch ($status) {
                "ValidLocal" { "Green" }
                "Installed" { "Green" }
                "InstallNeeded" { "Yellow" }
                "NetworkBlocked" { "Red" }
                default { "DarkYellow" }
            }
            Write-Host ("  - {0}: {1}" -f [string]$tool.name, $status) -ForegroundColor $color
            if (-not [string]::IsNullOrWhiteSpace([string]$tool.version)) { Write-Host ("    Version: " + [string]$tool.version) -ForegroundColor DarkCyan }
            if (-not [string]::IsNullOrWhiteSpace([string]$tool.venvStatus)) { Write-Host ("    Venv: " + [string]$tool.venvStatus) -ForegroundColor DarkCyan }
            if (-not [string]::IsNullOrWhiteSpace([string]$tool.reason)) { Write-Host ("    Reason: " + [string]$tool.reason) -ForegroundColor DarkYellow }
        }
    }

    if ([string]$Script:AgentGuidanceState.status -ne "NotStarted") {
        $agentColor = switch ([string]$Script:AgentGuidanceState.status) {
            "OK" { "Green" }
            "Preview" { "DarkCyan" }
            "WARN" { "Yellow" }
            default { "DarkYellow" }
        }
        Write-Host "AGENT GUIDANCE STATUS:" -ForegroundColor Cyan
        Write-Host ("  - Guidance: {0}" -f [string]$Script:AgentGuidanceState.status) -ForegroundColor $agentColor
        Write-Host ("    AGENTS.md: {0} ({1})" -f [string]$Script:AgentGuidanceState.agentsStatus, [string]$Script:AgentGuidanceState.agentsPath) -ForegroundColor DarkCyan
        if (-not [string]::IsNullOrWhiteSpace([string]$Script:AgentGuidanceState.agentsFallbackPath)) { Write-Host ("    AGENTS fallback: " + [string]$Script:AgentGuidanceState.agentsFallbackPath) -ForegroundColor DarkYellow }
        Write-Host ("    CLAUDE.md: {0} ({1})" -f [string]$Script:AgentGuidanceState.claudeStatus, [string]$Script:AgentGuidanceState.claudePath) -ForegroundColor DarkCyan
        if (-not [string]::IsNullOrWhiteSpace([string]$Script:AgentGuidanceState.claudeFallbackPath)) { Write-Host ("    CLAUDE fallback: " + [string]$Script:AgentGuidanceState.claudeFallbackPath) -ForegroundColor DarkYellow }
        Write-Host ("    Launcher: {0} ({1})" -f [string]$Script:AgentGuidanceState.launcherStatus, [string]$Script:AgentGuidanceState.launcherPath) -ForegroundColor DarkCyan
        if (-not [string]::IsNullOrWhiteSpace([string]$Script:AgentGuidanceState.reason)) { Write-Host ("    Reason: " + [string]$Script:AgentGuidanceState.reason) -ForegroundColor DarkYellow }
    }

    if ($failureCount -gt 0 -or $skipCount -gt 0 -or $warningCount -gt 0) {
        Write-Host ""
        Write-Host "Recommended next action:" -ForegroundColor Cyan
        Write-Host "  Re-run the same launcher. Completed steps are validated and skipped or updated where practical." -ForegroundColor Cyan
        Write-Host "  To skip the installer/tool phase after fixing tools manually, run with -SkipTools." -ForegroundColor Cyan
    }

    if (-not [string]::IsNullOrWhiteSpace($Script:SetupStatePath)) { Write-Host ("Setup state: " + [string]$Script:SetupStatePath) -ForegroundColor DarkGray }
    if (-not [string]::IsNullOrWhiteSpace($Script:TranscriptLogPath)) { Write-Host ("Transcript: " + [string]$Script:TranscriptLogPath) -ForegroundColor DarkGray }
    Write-Host ""
}

function Run-FinalVerification {
    Write-Step "Final verification summary"
    $items = @(
        @{ Name="git"; Path="git"; Args=@("--version") },
        @{ Name="gh"; Path=(Join-Path $GhRoot "bin\gh.exe"); Args=@("--version") },
        @{ Name="rustup"; Path="rustup"; Args=@("--version") },
        @{ Name="cargo"; Path="cargo"; Args=@("--version") },
        @{ Name="rustc"; Path="rustc"; Args=@("--version") },
        @{ Name="python"; Path=(Join-Path $PythonInstallDir "python.exe"); Args=@("--version") },
        @{ Name="dotnet"; Path=(Join-Path $DotNetRoot "dotnet.exe"); Args=@("--info") },
        @{ Name="cmake"; Path=(Join-Path $CMakeRoot "bin\cmake.exe"); Args=@("--version") },
        @{ Name="vscode"; Path=(Get-VSCodeCommandPath); Args=@("--version") },
        @{ Name="node"; Path=(Join-Path $NodeRoot "node.exe"); Args=@("--version") },
        @{ Name="npm"; Path=(Join-Path $NodeRoot "npm.cmd"); Args=@("--version") },
        @{ Name="codex"; Path=(Join-Path $NpmGlobalDir "codex.cmd"); Args=@("--version") }
    )

    foreach ($item in $items) {
        $path = $item.Path
        if ([string]::IsNullOrWhiteSpace($path)) {
            Write-Warning "$($item.Name) not found."
        } elseif (($path -notmatch "[\\/]") -or (Test-Path $path)) {
            Run-Native -Exe $path -Arguments $item.Args -IgnoreExitCode
        } else {
            Write-Warning "$($item.Name) not found at expected path: $path"
        }
    }

    if (Test-Path $WorkspacePath) { Write-Host ("Script version: {0}  |  Star Citizen tested builds: {1}" -f $Script:ScriptVersion, $Script:StarCitizenTestedBuildsDisplay)
        Write-Host "Workspace: $WorkspacePath" }
    if (Test-Path $WorkspaceLaunchCmdPath) { Write-Host "Workspace launcher: $WorkspaceLaunchCmdPath" }
    $sbExe = Join-Path $StarCitizenRoot "StarBreaker\target\release\starbreaker.exe"
    if (Test-Path $sbExe) { Write-Host "StarBreaker executable: $sbExe" }
}

function Get-ResumeHintForStep {
    # v11: Map a failed step ID to a concrete re-run command line so the user
    # doesn't have to read the source to figure out how to resume. The launcher
    # is idempotent for any step whose Install-/Validate-/Get- function already
    # short-circuits on "already installed" — so re-running with the same flags
    # is the most reliable resume path. The hints below tailor that advice to
    # the specific failure point (e.g. on Build Tools, suggest reboot + full
    # re-run; on clone-repos, suggest -SkipTools to avoid the long install
    # phase entirely on re-run).
    param([string]$StepId)

    $generic = @(
        "  Most steps are idempotent: just re-run the same launcher; completed work won't redo.",
        "  To skip the slow install phase next time: append  -SkipTools",
        "  To run just one phase, use one of:  -CloneRepos / -CreateWorkspace / -CreateBranches / -BuildStarBreaker / -InstallBlenderAddon / -RunAuroraExample"
    )

    switch -Regex ($StepId) {
        '^preflight-folders$' {
            return @(
                "  Pre-flight failed BEFORE anything was installed. Likely causes:",
                "    - Drive does not exist (try a different -DevRoot)",
                "    - Insufficient disk space (free space or pick another drive)",
                "    - Not running as Administrator (right-click -> Run as Administrator)",
                "  No retry hint needed once the cause is fixed; just re-run the launcher."
            )
        }
        '^winget-check$' {
            return @(
                "  WinGet was not found. Try:",
                "    1. Open Microsoft Store -> search 'App Installer' -> Install/Update",
                "    2. Reboot, then double-click the launcher again",
                "    3. The launcher includes a WinGet bootstrap path; re-running may trigger it"
            )
        }
        '^install-vsbuildtools$' {
            return @(
                "  Visual Studio Build Tools is the most fragile step. Try:",
                "    1. Reboot Windows (the bootstrapper may have requested it silently)",
                "    2. Open 'Visual Studio Installer' from Start -> use Modify on Build Tools 2022",
                "       and ensure 'C++ build tools' workload + 'Windows 11 SDK' are checked",
                "    3. Then re-run this launcher; it will revalidate and skip if Build Tools is ready",
                "    4. If repeated installer hangs occur, run installer manually then relaunch with -SkipTools"
            )
        }
        '^install-(git|gh|rust|python|dotnet|cmake|vscode|node-codex|blender-addon)$' {
            return @(
                "  Single-tool install failed. Try:",
                "    1. Re-run the launcher; the validate-before-install logic will skip what's already there",
                "    2. If a specific WinGet package is failing, run:  winget install <Id> --accept-package-agreements --accept-source-agreements",
                "    3. To resume the rest of setup without redoing the install phase, re-run with -SkipTools"
            )
        }
        '^clone-repos$' {
            return @(
                "  Repository clone failed. Try:",
                "    1. Check your network and GitHub access ('gh auth status' if you have GitHub CLI)",
                "    2. Re-run; existing clones are detected and only the missing ones are fetched",
                "    3. To skip cloning on next run: omit -CloneRepos"
            )
        }
        '^setup-git-versioning$' {
            return @(
                "  Git versioning needs review. Try:",
                "    1. Check the Git versioning status section above",
                "    2. Commit, stash, or intentionally leave local changes before branch switching",
                "    3. Re-run with -CreateBranches when the target repo working trees are clean"
            )
        }
        '^(write-workspace|vscode-extensions)$' {
            return @(
                "  Workspace / extensions failed. Try:",
                "    1. Re-run with -PromptForVSCodePath if VS Code CLI detection was the issue",
                "    2. Open the workspace manually:  $WorkspacePath"
            )
        }
        '^build-starbreaker$' {
            return @(
                "  StarBreaker build failed. Try:",
                "    1. Confirm Build Tools cl.exe is on the Developer PowerShell path",
                "    2. Re-run just the build phase:  -SkipTools -BuildStarBreaker",
                "    3. Inspect the cargo log linked above for the first 'error:' line"
            )
        }
        '^aurora-example$' {
            return @(
                "  Aurora example failed. Try:",
                "    1. Confirm Data.p4k is present at the path expected (or pass -DataP4kSource)",
                "    2. Re-run just the example:  -SkipTools -RunAuroraExample"
            )
        }
        default {
            # No specific hint; fall through to the generic list.
        }
    }

    return $generic
}

function Show-StepTimingSummary {
    # v11: Print a clean per-step elapsed-time table at the very end of the run.
    # Two reasons this earns its place:
    #  1. It tells DirectorGunner (and his viewers) what the real-world timing
    #     budget is on a given machine. That's tutorial gold.
    #  2. On failure, it shows the user how far they got and where time went,
    #     so they can decide whether to resume from a specific phase.
    if ($null -eq $Script:StepTimings -or $Script:StepTimings.Count -eq 0) { return }

    $totalSeconds = 0.0
    foreach ($r in $Script:StepTimings) { $totalSeconds += [double]$r.ElapsedSeconds }

    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Cyan
    Write-Host " Step timing summary" -ForegroundColor Cyan
    Write-Host "================================================================" -ForegroundColor Cyan

    foreach ($r in $Script:StepTimings) {
        $secs = [double]$r.ElapsedSeconds
        $timeText = if ($secs -lt 60) {
            ("{0,5:N1}s" -f $secs)
        } elseif ($secs -lt 3600) {
            ("{0,2}m {1,2}s" -f [int]([Math]::Floor($secs/60)), [int]($secs % 60))
        } else {
            ("{0}h {1,2}m {2,2}s" -f [int]([Math]::Floor($secs/3600)), [int]((($secs % 3600)/60)), [int]($secs % 60))
        }
        $color = switch ($r.Status) {
            "OK"      { "Green" }
            "Preview" { "DarkGray" }
            "WARN"    { "Yellow" }
            "FAILED"  { "Red" }
            "FATAL"   { "Red" }
            "SKIPPED" { "DarkYellow" }
            default   { "Gray" }
        }
        $tag = switch ($r.Status) {
            "OK"      { "[ OK ]" }
            "Preview" { "[ pv ]" }
            "WARN"    { "[WARN]" }
            "FAILED"  { "[FAIL]" }
            "FATAL"   { "[XX ]" }
            "SKIPPED" { "[SKIP]" }
            default   { "[ -- ]" }
        }
        Write-Host (" {0}  {1,9}   {2}" -f $tag, $timeText, $r.Name) -ForegroundColor $color
    }

    Write-Host "----------------------------------------------------------------" -ForegroundColor DarkCyan
    $totalText = if ($totalSeconds -lt 60) {
        ("{0,5:N1}s" -f $totalSeconds)
    } elseif ($totalSeconds -lt 3600) {
        ("{0,2}m {1,2}s" -f [int]([Math]::Floor($totalSeconds/60)), [int]($totalSeconds % 60))
    } else {
        ("{0}h {1,2}m {2,2}s" -f [int]([Math]::Floor($totalSeconds/3600)), [int]((($totalSeconds % 3600)/60)), [int]($totalSeconds % 60))
    }
    Write-Host (" Total elapsed across all steps: {0}" -f $totalText) -ForegroundColor Cyan
    Write-Host ""
}


function Invoke-SelfTest {
    Write-Host ("Running script version {0} safe non-live harness self-tests. Star Citizen tested builds: {1}" -f $Script:ScriptVersion, $Script:StarCitizenTestedBuildsDisplay) -ForegroundColor Cyan
    $errors = New-Object 'System.Collections.Generic.List[string]'

    function Add-SelfTestError([string]$Message) {
        if (-not [string]::IsNullOrWhiteSpace($Message)) { [void]$errors.Add($Message) }
    }
    function Assert-SelfTest([bool]$Condition, [string]$Message) {
        if (-not $Condition) { Add-SelfTestError $Message }
    }
    function Get-LocalGitConfigValue([string]$RepoPath, [string]$Name) {
        try { return ((& git -C $RepoPath config --local --get $Name 2>$null) -join "").Trim() } catch { return "" }
    }
    function New-HarnessGitRepo([string]$Name) {
        $repo = Join-Path (Join-Path $Script:HarnessRoot "git-tests") $Name
        Ensure-Directory $repo
        Run-Native -Exe "git" -Arguments @("-C", $repo, "init", "-b", "main") -WorkingDirectory $repo
        return $repo
    }
    function Get-SelfTestTimingCount([string]$Id, [string]$Status = "") {
        $matches = @($Script:StepTimings | Where-Object {
            ([string]$_.Id -eq $Id) -and ([string]::IsNullOrWhiteSpace($Status) -or [string]$_.Status -eq $Status)
        })
        return [int]$matches.Count
    }
    function Get-SelfTestSkipCount([string]$Id, [string]$Reason) {
        $matches = @($Script:SetupSkips | Where-Object { ([string]$_.Id -eq $Id) -and ([string]$_.Reason -eq $Reason) })
        return [int]$matches.Count
    }
    function Get-SelfTestFailureCount([string]$Id, [string]$Reason, [bool]$Fatal) {
        $matches = @($Script:SetupFailures | Where-Object { ([string]$_.Id -eq $Id) -and ([string]$_.Reason -eq $Reason) -and ([bool]$_.Fatal -eq $Fatal) })
        return [int]$matches.Count
    }

    try {
        $oldSteps = $Script:SetupSteps
        $oldLookup = $Script:SetupStepLookup
        $oldTimings = $Script:StepTimings
        $oldSkips = $Script:SetupSkips
        $oldFailures = $Script:SetupFailures
        $oldFatal = $Script:FatalFailure
        $oldSetupStatePath = $Script:SetupStatePath
        $oldCurrentStepId = $Script:CurrentStepId
        $oldCurrentStepName = $Script:CurrentStepName
        $oldCurrentStepNumber = $Script:CurrentStepNumber
        $oldCurrentCompletedBefore = $Script:CurrentCompletedBefore

        $Script:StepTimings = New-Object 'System.Collections.Generic.List[object]'
        $Script:SetupSkips = New-Object 'System.Collections.Generic.List[object]'
        $Script:SetupFailures = New-Object 'System.Collections.Generic.List[object]'
        $Script:FatalFailure = $false
        $Script:SetupStatePath = Join-Path $Script:HarnessRoot "status-tests\setup-state.json"
        $Script:SetupSteps = @(
            (New-SetupStepObject -Id "step-ok" -Name "Synthetic OK step"),
            (New-SetupStepObject -Id "step-soft-skip" -Name "Synthetic soft skip step"),
            (New-SetupStepObject -Id "setup-git-versioning" -Name "Synthetic dependency source"),
            (New-SetupStepObject -Id "locate-blender" -Name "Synthetic dependent step"),
            (New-SetupStepObject -Id "step-soft-failed" -Name "Synthetic soft failed step"),
            (New-SetupStepObject -Id "step-soft-fatal" -Name "Synthetic soft fatal step"),
            (New-SetupStepObject -Id "step-thrown-failed" -Name "Synthetic thrown failed step"),
            (New-SetupStepObject -Id "step-thrown-fatal" -Name "Synthetic thrown fatal step")
        )
        $Script:SetupStepLookup = @{}
        for ($i = 0; $i -lt $Script:SetupSteps.Count; $i++) { $Script:SetupStepLookup[$Script:SetupSteps[$i].Id] = ($i + 1) }

        Invoke-SetupStep -Id "step-ok" -Name "Synthetic OK step" -ScriptBlock { }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-ok" -Status "OK") -eq 1) "OK step was not recorded as OK exactly once."
        Assert-SelfTest (Test-Path -LiteralPath $Script:SetupStatePath) "Setup-state was not saved after OK step."

        Invoke-SetupStep -Id "step-soft-skip" -Name "Synthetic soft skip step" -ScriptBlock {
            Add-SetupSkipRecord -Id "step-soft-skip" -Name "Synthetic soft skip step" -Reason "soft skip reason"
            $Script:CurrentStepResultStatus = "SKIPPED"
            $Script:CurrentStepResultReason = "soft skip reason"
        }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-soft-skip" -Status "SKIPPED") -eq 1) "Soft SKIPPED was not recorded as SKIPPED exactly once."
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-soft-skip" -Status "OK") -eq 0) "Soft SKIPPED was incorrectly recorded as OK."
        Assert-SelfTest ((Get-SelfTestSkipCount -Id "step-soft-skip" -Reason "soft skip reason") -eq 1) "Soft SKIPPED did not produce exactly one skip record."
        Assert-SelfTest (Test-SetupStepFailedOrSkipped -Id "step-soft-skip") "Soft SKIPPED did not block dependencies."

        Invoke-SetupStep -Id "setup-git-versioning" -Name "Synthetic warning source" -ScriptBlock {
            $Script:CurrentStepResultStatus = "WARN"
            $Script:CurrentStepResultReason = "warning reason"
        }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "setup-git-versioning" -Status "WARN") -eq 1) "WARN was not recorded exactly once."
        Assert-SelfTest (-not (Test-SetupStepFailedOrSkipped -Id "setup-git-versioning")) "WARN incorrectly blocked dependencies."
        Assert-SelfTest ([string]::IsNullOrWhiteSpace((Get-StepDependencySkipReason -Id "locate-blender"))) "WARN dependency source produced a skip reason."
        Invoke-SetupStep -Id "locate-blender" -Name "Synthetic dependent after warning" -ScriptBlock { }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "locate-blender" -Status "OK") -eq 1) "Dependent step did not run after WARN source."

        Invoke-SetupStep -Id "step-soft-failed" -Name "Synthetic soft failed step" -ScriptBlock {
            Add-SetupFailureRecord -Id "step-soft-failed" -Name "Synthetic soft failed step" -Reason "soft fail reason"
            $Script:CurrentStepResultStatus = "FAILED"
            $Script:CurrentStepResultReason = "soft fail reason"
        }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-soft-failed" -Status "FAILED") -eq 1) "Soft FAILED was not recorded as FAILED exactly once."
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-soft-failed" -Status "OK") -eq 0) "Soft FAILED was incorrectly recorded as OK."
        Assert-SelfTest ((Get-SelfTestFailureCount -Id "step-soft-failed" -Reason "soft fail reason" -Fatal $false) -eq 1) "Soft FAILED did not produce exactly one nonfatal failure record."
        Assert-SelfTest (Test-SetupStepFailedOrSkipped -Id "step-soft-failed") "Soft FAILED did not block dependencies."

        Invoke-SetupStep -Id "setup-git-versioning" -Name "Synthetic failed dependency source" -ScriptBlock {
            $Script:CurrentStepResultStatus = "FAIL"
            $Script:CurrentStepResultReason = "dependency fail reason"
        }
        Assert-SelfTest (Test-SetupStepFailedOrSkipped -Id "setup-git-versioning") "FAILED dependency source did not block dependencies."
        Assert-SelfTest (-not [string]::IsNullOrWhiteSpace((Get-StepDependencySkipReason -Id "locate-blender"))) "FAILED dependency source did not produce a skip reason."
        Invoke-SetupStep -Id "locate-blender" -Name "Synthetic dependent after failure" -ScriptBlock { throw "dependent should have been skipped" }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "locate-blender" -Status "SKIPPED") -eq 1) "Dependent step was not skipped after FAILED dependency."

        $softFatalThrew = $false
        try {
            Invoke-SetupStep -Id "step-soft-fatal" -Name "Synthetic soft fatal step" -ScriptBlock {
                Add-SetupFailureRecord -Id "step-soft-fatal" -Name "Synthetic soft fatal step" -Reason "soft fatal reason" -Fatal
                $Script:CurrentStepResultStatus = "FATAL"
                $Script:CurrentStepResultReason = "soft fatal reason"
            }
        } catch { $softFatalThrew = $true }
        Assert-SelfTest $softFatalThrew "Soft FATAL did not throw/stop."
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-soft-fatal" -Status "FATAL") -eq 1) "Soft FATAL was not recorded as FATAL exactly once."
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-soft-fatal" -Status "OK") -eq 0) "Soft FATAL was incorrectly recorded as OK."
        Assert-SelfTest ((Get-SelfTestFailureCount -Id "step-soft-fatal" -Reason "soft fatal reason" -Fatal $true) -eq 1) "Soft FATAL did not produce exactly one fatal failure record."

        Invoke-SetupStep -Id "step-thrown-failed" -Name "Synthetic thrown failed step" -ScriptBlock { throw "thrown fail reason" }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-thrown-failed" -Status "FAILED") -eq 1) "Thrown nonfatal exception was not recorded as FAILED."
        Assert-SelfTest ((Get-SelfTestFailureCount -Id "step-thrown-failed" -Reason "thrown fail reason" -Fatal $false) -eq 1) "Thrown nonfatal exception did not produce exactly one failure record."

        $thrownFatalThrew = $false
        try {
            Invoke-SetupStep -Id "step-thrown-fatal" -Name "Synthetic thrown fatal step" -Fatal -ScriptBlock { throw "thrown fatal reason" }
        } catch { $thrownFatalThrew = $true }
        Assert-SelfTest $thrownFatalThrew "Thrown fatal exception did not throw/stop."
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-thrown-fatal" -Status "FATAL") -eq 1) "Thrown fatal exception was not recorded as FATAL."
        Assert-SelfTest ((Get-SelfTestFailureCount -Id "step-thrown-fatal" -Reason "thrown fatal reason" -Fatal $true) -eq 1) "Thrown fatal exception did not produce exactly one fatal failure record."

        $Script:StepTimings.Add([pscustomobject]@{ Id = "manual-fail-status"; Name = "Manual FAIL status"; ElapsedSeconds = 0; Status = "FAIL"; Reason = "manual fail" }) | Out-Null
        Assert-SelfTest (Test-SetupStepFailedOrSkipped -Id "manual-fail-status") "FAIL status did not block dependencies."

        $state = Get-Content -LiteralPath $Script:SetupStatePath -Raw | ConvertFrom-Json
        $stateStatuses = @($state.stepTimings | ForEach-Object { [string]$_.status })
        foreach ($expectedStatus in @("OK", "SKIPPED", "WARN", "FAILED", "FATAL")) {
            Assert-SelfTest ($stateStatuses -contains $expectedStatus) "Setup-state did not include expected status $expectedStatus."
        }
    } catch { Add-SelfTestError "Setup step status wrapper self-test failed: $($_.Exception.Message)" }
    finally {
        $Script:SetupSteps = $oldSteps
        $Script:SetupStepLookup = $oldLookup
        $Script:StepTimings = $oldTimings
        $Script:SetupSkips = $oldSkips
        $Script:SetupFailures = $oldFailures
        $Script:FatalFailure = $oldFatal
        $Script:SetupStatePath = $oldSetupStatePath
        $Script:CurrentStepId = $oldCurrentStepId
        $Script:CurrentStepName = $oldCurrentStepName
        $Script:CurrentStepNumber = $oldCurrentStepNumber
        $Script:CurrentCompletedBefore = $oldCurrentCompletedBefore
        $Script:CurrentStepResultStatus = ""
        $Script:CurrentStepResultReason = ""
    }

    try {
        $oldSteps = $Script:SetupSteps
        $oldLookup = $Script:SetupStepLookup
        $oldTimings = $Script:StepTimings
        $oldSkips = $Script:SetupSkips
        $oldFailures = $Script:SetupFailures
        $oldFatal = $Script:FatalFailure
        $oldSetupStatePath = $Script:SetupStatePath
        $oldCurrentStepId = $Script:CurrentStepId
        $oldCurrentStepName = $Script:CurrentStepName
        $oldCurrentStepNumber = $Script:CurrentStepNumber
        $oldCurrentCompletedBefore = $Script:CurrentCompletedBefore
        $oldBlenderState = $Script:BlenderState
        $oldP4KState = $Script:P4KState

        $Script:StepTimings = New-Object 'System.Collections.Generic.List[object]'
        $Script:SetupSkips = New-Object 'System.Collections.Generic.List[object]'
        $Script:SetupFailures = New-Object 'System.Collections.Generic.List[object]'
        $Script:FatalFailure = $false
        $Script:SetupStatePath = Join-Path $Script:HarnessRoot "skip-state-tests\setup-state.json"
        $Script:BlenderState = [ordered]@{ status = ""; exe = ""; version = ""; installRoot = ""; userConfigRoot = ""; addonLinked = $false; addonLinkType = "" }
        $Script:P4KState = [ordered]@{ status = ""; build = ""; source = ""; destination = ""; partialDestination = ""; sizeBytes = 0; spaceWarning = $false; readOnly = $false; skippedReason = ""; channel = ""; starCitizenExe = ""; productVersion = ""; fileVersion = "" }
        $Script:SetupSteps = @(
            (New-SetupStepObject -Id "setup-git-versioning" -Name "Synthetic dependency source"),
            (New-SetupStepObject -Id "locate-blender" -Name "Locate or install Blender"),
            (New-SetupStepObject -Id "step-addon-missing-source" -Name "Synthetic missing Blender add-on source"),
            (New-SetupStepObject -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k"),
            (New-SetupStepObject -Id "verify-sc-build" -Name "Verify Star Citizen build environment"),
            (New-SetupStepObject -Id "step-p4k-process-running" -Name "Synthetic process-running Data.p4k skip"),
            (New-SetupStepObject -Id "step-p4k-existing-retained" -Name "Synthetic retained Data.p4k destination skip"),
            (New-SetupStepObject -Id "step-aurora-missing-p4k" -Name "Synthetic Aurora missing Data.p4k skip"),
            (New-SetupStepObject -Id "step-no-open-blender" -Name "Synthetic NoOpenBlenderAfterExport skip"),
            (New-SetupStepObject -Id "step-duplicate-skip" -Name "Synthetic duplicate skip")
        )
        $Script:SetupStepLookup = @{}
        for ($i = 0; $i -lt $Script:SetupSteps.Count; $i++) { $Script:SetupStepLookup[$Script:SetupSteps[$i].Id] = ($i + 1) }

        Invoke-SetupStep -Id "setup-git-versioning" -Name "Synthetic dependency source" -ScriptBlock { }

        Invoke-SetupStep -Id "locate-blender" -Name "Locate or install Blender" -ScriptBlock {
            $Script:BlenderState.status = "SKIPPED"
            Set-CurrentSetupStepSkipped -Id "locate-blender" -Name "Locate or install Blender" -Reason "User skipped Blender setup."
        }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "locate-blender" -Status "SKIPPED") -eq 1) "Blender skip was not recorded as SKIPPED."
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "locate-blender" -Status "OK") -eq 0) "Blender skip was incorrectly recorded as OK."
        Assert-SelfTest ((Get-SelfTestSkipCount -Id "locate-blender" -Reason "User skipped Blender setup.") -eq 1) "Blender skip did not produce exactly one skip record."

        Invoke-SetupStep -Id "step-addon-missing-source" -Name "Synthetic missing Blender add-on source" -ScriptBlock {
            $Script:CurrentStepResultStatus = "FAILED"
            $Script:CurrentStepResultReason = "StarBreaker Blender add-on source was not found."
        }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-addon-missing-source" -Status "FAILED") -eq 1) "Missing Blender add-on source was not recorded as FAILED."
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-addon-missing-source" -Status "OK") -eq 0) "Missing Blender add-on source was incorrectly recorded as OK."

        Invoke-SetupStep -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -ScriptBlock {
            $Script:P4KState.status = "SKIPPED"
            $Script:P4KState.skippedReason = "User skipped Data.p4k setup."
            Set-CurrentSetupStepSkipped -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -Reason $Script:P4KState.skippedReason
        }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "select-data-p4k" -Status "SKIPPED") -eq 1) "Data.p4k user skip was not recorded as SKIPPED."
        Assert-SelfTest ((Get-SelfTestSkipCount -Id "select-data-p4k" -Reason "User skipped Data.p4k setup.") -eq 1) "Data.p4k user skip did not produce exactly one skip record."

        Invoke-SetupStep -Id "verify-sc-build" -Name "Verify Star Citizen build environment" -ScriptBlock { throw "dependency skip should prevent this block" }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "verify-sc-build" -Status "SKIPPED") -eq 1) "Dependency skip after Data.p4k user skip was not recorded as SKIPPED."

        Invoke-SetupStep -Id "step-p4k-process-running" -Name "Synthetic process-running Data.p4k skip" -ScriptBlock {
            Set-CurrentSetupStepSkipped -Id "step-p4k-process-running" -Name "Synthetic process-running Data.p4k skip" -Reason "Star Citizen or RSI Launcher process was running, so Data.p4k copy was skipped."
        }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-p4k-process-running" -Status "SKIPPED") -eq 1) "Process-running Data.p4k copy block was not recorded as SKIPPED."

        Invoke-SetupStep -Id "step-p4k-existing-retained" -Name "Synthetic retained Data.p4k destination skip" -ScriptBlock {
            Set-CurrentSetupStepSkipped -Id "step-p4k-existing-retained" -Name "Synthetic retained Data.p4k destination skip" -Reason "Data.p4k copy was skipped because an existing destination was retained."
        }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-p4k-existing-retained" -Status "SKIPPED") -eq 1) "Existing Data.p4k destination retained skip was not recorded as SKIPPED."

        Invoke-SetupStep -Id "step-aurora-missing-p4k" -Name "Synthetic Aurora missing Data.p4k skip" -ScriptBlock {
            Set-CurrentSetupStepSkipped -Id "step-aurora-missing-p4k" -Name "Synthetic Aurora missing Data.p4k skip" -Reason "Aurora example skipped because Data.p4k is not configured."
        }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-aurora-missing-p4k" -Status "SKIPPED") -eq 1) "Aurora missing Data.p4k skip was not recorded as SKIPPED."

        Invoke-SetupStep -Id "step-no-open-blender" -Name "Synthetic NoOpenBlenderAfterExport skip" -ScriptBlock {
            Set-CurrentSetupStepSkipped -Id "step-no-open-blender" -Name "Synthetic NoOpenBlenderAfterExport skip" -Reason "Blender open skipped because NoOpenBlenderAfterExport was set."
        }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "step-no-open-blender" -Status "SKIPPED") -eq 1) "NoOpenBlenderAfterExport skip was not recorded as SKIPPED."

        Invoke-SetupStep -Id "step-duplicate-skip" -Name "Synthetic duplicate skip" -ScriptBlock {
            Add-SetupSkipRecord -Id "step-duplicate-skip" -Name "Synthetic duplicate skip" -Reason "duplicate skip reason"
            Set-CurrentSetupStepSkipped -Id "step-duplicate-skip" -Name "Synthetic duplicate skip" -Reason "duplicate skip reason"
        }
        Assert-SelfTest ((Get-SelfTestSkipCount -Id "step-duplicate-skip" -Reason "duplicate skip reason") -eq 1) "Duplicate skip records were not avoided."

        $state = Get-Content -LiteralPath $Script:SetupStatePath -Raw | ConvertFrom-Json
        $stateReasons = @($state.skippedSteps | ForEach-Object { [string]$_.reason })
        foreach ($expectedReason in @(
            "User skipped Blender setup.",
            "User skipped Data.p4k setup.",
            "Star Citizen or RSI Launcher process was running, so Data.p4k copy was skipped.",
            "Aurora example skipped because Data.p4k is not configured.",
            "Blender open skipped because NoOpenBlenderAfterExport was set."
        )) {
            Assert-SelfTest ($stateReasons -contains $expectedReason) "Setup-state missing skip reason: $expectedReason"
        }
    } catch { Add-SelfTestError "User skip-state normalization self-test failed: $($_.Exception.Message)" }
    finally {
        $Script:SetupSteps = $oldSteps
        $Script:SetupStepLookup = $oldLookup
        $Script:StepTimings = $oldTimings
        $Script:SetupSkips = $oldSkips
        $Script:SetupFailures = $oldFailures
        $Script:FatalFailure = $oldFatal
        $Script:SetupStatePath = $oldSetupStatePath
        $Script:CurrentStepId = $oldCurrentStepId
        $Script:CurrentStepName = $oldCurrentStepName
        $Script:CurrentStepNumber = $oldCurrentStepNumber
        $Script:CurrentCompletedBefore = $oldCurrentCompletedBefore
        $Script:BlenderState = $oldBlenderState
        $Script:P4KState = $oldP4KState
        $Script:CurrentStepResultStatus = ""
        $Script:CurrentStepResultReason = ""
    }

    try {
        $validDecision = Resolve-VSBuildToolsInstallDecision -AlreadyValid $true
        Assert-SelfTest ([string]$validDecision.Status -eq "ValidAlready") "Valid Build Tools did not resolve as ValidAlready."
        Assert-SelfTest (-not [bool]$validDecision.ShouldPrompt -and -not [bool]$validDecision.ShouldInstall) "Valid Build Tools unexpectedly prompted or installed."

        $assumeYesDecision = Resolve-VSBuildToolsInstallDecision -AssumeYesEnabled $true
        Assert-SelfTest ([string]$assumeYesDecision.Status -eq "Approved" -and [bool]$assumeYesDecision.ShouldInstall) "AssumeYes Build Tools decision did not approve install."

        $userNoDecision = Resolve-VSBuildToolsInstallDecision -UserChoice "N"
        Assert-SelfTest ([string]$userNoDecision.Status -eq "UserSkipped" -and [bool]$userNoDecision.Skipped) "User N Build Tools decision did not skip."
        Assert-SelfTest ([string]$userNoDecision.Reason -eq "Build Tools skipped by user choice.") "User N Build Tools decision reason was not explicit."

        $nonLiveDecision = Resolve-VSBuildToolsInstallDecision -NonLiveMode $true -AssumeYesEnabled $true
        Assert-SelfTest ([string]$nonLiveDecision.Status -eq "NonLiveSkipped" -and -not [bool]$nonLiveDecision.ShouldInstall) "Non-live Build Tools decision did not block install."

        $promptDecision = Resolve-VSBuildToolsInstallDecision
        Assert-SelfTest ([string]$promptDecision.Status -eq "PromptNeeded" -and [bool]$promptDecision.ShouldPrompt) "Build Tools missing decision did not require an explicit prompt."
    } catch { Add-SelfTestError "Build Tools decision helper self-test failed: $($_.Exception.Message)" }

    try {
        $oldSteps = $Script:SetupSteps
        $oldLookup = $Script:SetupStepLookup
        $oldTimings = $Script:StepTimings
        $oldSkips = $Script:SetupSkips
        $oldFailures = $Script:SetupFailures
        $oldToolStates = $Script:ToolStates
        $oldFatal = $Script:FatalFailure
        $oldSetupStatePath = $Script:SetupStatePath
        $oldCurrentStepId = $Script:CurrentStepId
        $oldCurrentStepName = $Script:CurrentStepName
        $oldCurrentStepNumber = $Script:CurrentStepNumber
        $oldCurrentCompletedBefore = $Script:CurrentCompletedBefore
        $oldStarCitizenRoot = $StarCitizenRoot

        $Script:StepTimings = New-Object 'System.Collections.Generic.List[object]'
        $Script:SetupSkips = New-Object 'System.Collections.Generic.List[object]'
        $Script:SetupFailures = New-Object 'System.Collections.Generic.List[object]'
        $Script:ToolStates = @{}
        $Script:FatalFailure = $false
        $Script:SetupStatePath = Join-Path $Script:HarnessRoot "build-tools-choice-tests\setup-state.json"
        $Script:SetupSteps = @(
            (New-SetupStepObject -Id "install-vsbuildtools" -Name "Install Visual Studio Build Tools"),
            (New-SetupStepObject -Id "install-rust" -Name "Synthetic Rust step"),
            (New-SetupStepObject -Id "clone-repos" -Name "Synthetic repo step"),
            (New-SetupStepObject -Id "setup-git-versioning" -Name "Synthetic Git versioning step"),
            (New-SetupStepObject -Id "build-starbreaker" -Name "Build StarBreaker and StarBreaker MCP")
        )
        $Script:SetupStepLookup = @{}
        for ($i = 0; $i -lt $Script:SetupSteps.Count; $i++) { $Script:SetupStepLookup[$Script:SetupSteps[$i].Id] = ($i + 1) }

        $fakeRootNoBinaries = Join-Path $Script:HarnessRoot "build-tools-choice-tests\devroot-no-binaries\starcitizen"
        Set-Variable -Name StarCitizenRoot -Scope Script -Value $fakeRootNoBinaries
        Invoke-SetupStep -Id "install-vsbuildtools" -Name "Install Visual Studio Build Tools" -ScriptBlock {
            Set-ToolState -Name "vsbuildtools" -Status "SKIPPED" -Source "user-choice" -Reason "Build Tools skipped by user choice." -InstallNeeded $true
            Set-CurrentSetupStepSkipped -Id "install-vsbuildtools" -Name "Install Visual Studio Build Tools" -Reason "Build Tools skipped by user choice."
        }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "install-vsbuildtools" -Status "SKIPPED") -eq 1) "Build Tools user skip was not recorded as SKIPPED."
        Assert-SelfTest ((Get-SelfTestSkipCount -Id "install-vsbuildtools" -Reason "Build Tools skipped by user choice.") -eq 1) "Build Tools user skip did not produce exactly one skip record."
        Assert-SelfTest (Test-BuildToolsSkippedByUserChoice) "Build Tools skipped-by-user state was not detectable."

        Invoke-SetupStep -Id "build-starbreaker" -Name "Build StarBreaker and StarBreaker MCP" -ScriptBlock { throw "build should have been skipped without binaries" }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "build-starbreaker" -Status "SKIPPED") -eq 1) "StarBreaker build did not skip after Build Tools user skip without binaries."
        $buildSkipReason = Get-SetupSkipReason -Id "build-starbreaker"
        Assert-SelfTest ($buildSkipReason -match "Build Tools were skipped by user choice") "StarBreaker build skip reason did not explain Build Tools user skip."

        $Script:StepTimings = New-Object 'System.Collections.Generic.List[object]'
        $Script:SetupSkips = New-Object 'System.Collections.Generic.List[object]'
        $Script:SetupFailures = New-Object 'System.Collections.Generic.List[object]'
        $Script:ToolStates = @{}
        $fakeRootWithBinaries = Join-Path $Script:HarnessRoot "build-tools-choice-tests\devroot-with-binaries\starcitizen"
        Set-Variable -Name StarCitizenRoot -Scope Script -Value $fakeRootWithBinaries
        $fakeReleaseDir = Join-Path $fakeRootWithBinaries "StarBreaker\target\release"
        Write-InstallerFile -Path (Join-Path $fakeReleaseDir "starbreaker.exe") -Text "harness fake starbreaker"
        Write-InstallerFile -Path (Join-Path $fakeReleaseDir "starbreaker-mcp.exe") -Text "harness fake starbreaker mcp"

        Invoke-SetupStep -Id "install-vsbuildtools" -Name "Install Visual Studio Build Tools" -ScriptBlock {
            Set-ToolState -Name "vsbuildtools" -Status "SKIPPED" -Source "user-choice" -Reason "Build Tools skipped by user choice." -InstallNeeded $true
            Set-CurrentSetupStepSkipped -Id "install-vsbuildtools" -Name "Install Visual Studio Build Tools" -Reason "Build Tools skipped by user choice."
        }
        Invoke-SetupStep -Id "build-starbreaker" -Name "Build StarBreaker and StarBreaker MCP" -ScriptBlock {
            $Script:CurrentStepResultStatus = "WARN"
            $Script:CurrentStepResultReason = "Build Tools were skipped by user choice; using existing StarBreaker release binaries."
        }
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "build-starbreaker" -Status "WARN") -eq 1) "StarBreaker build did not proceed to reuse existing binaries after Build Tools user skip."
        Assert-SelfTest ((Get-SelfTestTimingCount -Id "build-starbreaker" -Status "SKIPPED") -eq 0) "StarBreaker build was skipped even though reusable binaries existed."

        $state = Get-Content -LiteralPath $Script:SetupStatePath -Raw | ConvertFrom-Json
        Assert-SelfTest (@($state.tools | Where-Object { [string]$_.name -eq "vsbuildtools" -and [string]$_.status -eq "SKIPPED" -and [string]$_.reason -eq "Build Tools skipped by user choice." }).Count -eq 1) "Setup-state did not record Build Tools skipped by user choice."
    } catch { Add-SelfTestError "Build Tools user-choice self-test failed: $($_.Exception.Message)" }
    finally {
        try { Set-Variable -Name StarCitizenRoot -Scope Script -Value $oldStarCitizenRoot } catch { }
        $Script:SetupSteps = $oldSteps
        $Script:SetupStepLookup = $oldLookup
        $Script:StepTimings = $oldTimings
        $Script:SetupSkips = $oldSkips
        $Script:SetupFailures = $oldFailures
        $Script:ToolStates = $oldToolStates
        $Script:FatalFailure = $oldFatal
        $Script:SetupStatePath = $oldSetupStatePath
        $Script:CurrentStepId = $oldCurrentStepId
        $Script:CurrentStepName = $oldCurrentStepName
        $Script:CurrentStepNumber = $oldCurrentStepNumber
        $Script:CurrentCompletedBefore = $oldCurrentCompletedBefore
        $Script:CurrentStepResultStatus = ""
        $Script:CurrentStepResultReason = ""
    }

    try {
        $Script:ToolStates = @{}
        $fakeGh = Join-Path $Script:HarnessRoot "offline-tools\gh\bin\gh.exe"
        $validGh = Test-LocalGitHubCli -GhExe $fakeGh -AssumeExists -VersionText "gh version 2.75.0 (harness)" -VersionExitCode 0
        $validGhDecision = Resolve-GitHubCliInstallDecision -LocalExists ([bool]$validGh.Exists) -LocalValid ([bool]$validGh.Valid) -LocalVersion ([string]$validGh.Version) -NetworkAllowed $false -Reason ([string]$validGh.Reason)
        Assert-SelfTest ([string]$validGhDecision.Status -eq "ValidLocal") "Valid local gh did not resolve as ValidLocal."
        Assert-SelfTest (-not [bool]$validGhDecision.NetworkLookupNeeded) "Valid local gh still required a network lookup."
        Set-ToolState -Name "gh" -Status ([string]$validGhDecision.Status) -Path $fakeGh -Version ([string]$validGhDecision.Version) -Source "harness" -Reason ([string]$validGhDecision.Reason) -LocalValidated ([bool]$validGhDecision.LocalValidated)

        $missingGhDecision = Resolve-GitHubCliInstallDecision -LocalExists $false -LocalValid $false -NetworkAllowed $true
        Assert-SelfTest ([string]$missingGhDecision.Status -eq "InstallNeeded") "Missing gh did not resolve as InstallNeeded when network is allowed."
        Assert-SelfTest ([bool]$missingGhDecision.NetworkLookupNeeded) "Missing gh did not request a network lookup when install/update is needed."

        $blockedGhDecision = Resolve-GitHubCliInstallDecision -LocalExists $false -LocalValid $false -NetworkAllowed $false
        Assert-SelfTest ([string]$blockedGhDecision.Status -eq "NetworkBlocked") "Missing gh with NoNetwork did not resolve as NetworkBlocked."
        Assert-SelfTest (-not [bool]$blockedGhDecision.NetworkLookupNeeded) "NoNetwork gh decision still requested a network lookup."
        Assert-SelfTest ([bool]$blockedGhDecision.NetworkBlocked) "NoNetwork gh decision did not record networkBlocked."

        Assert-SelfTest (Test-PythonVersionMatchesRequest -InstalledVersion ([version]"3.12.13") -RequestedVersion "3.12.13") "Exact Python version did not match itself."
        Assert-SelfTest (Test-PythonVersionMatchesRequest -InstalledVersion ([version]"3.12.14") -RequestedVersion "3.12.13") "Newer same-series Python did not satisfy exact request series."
        Assert-SelfTest (Test-PythonVersionMatchesRequest -InstalledVersion ([version]"3.12.12") -RequestedVersion "3.12.13") "Older same-series Python did not satisfy exact request series."
        Assert-SelfTest (Test-PythonVersionMatchesRequest -InstalledVersion ([version]"3.12.1") -RequestedVersion "3.12") "Same-series Python did not satisfy series request."
        Assert-SelfTest (-not (Test-PythonVersionMatchesRequest -InstalledVersion ([version]"3.11.9") -RequestedVersion "3.12")) "Wrong-series Python satisfied series request."

        $fakePython = Join-Path $Script:HarnessRoot "offline-tools\python\Python312\python.exe"
        $validPython = Test-LocalPythonInstall -PythonExe $fakePython -RequestedVersion "3.12" -AssumeExists -VersionText "Python 3.12.13" -VersionExitCode 0
        $validPythonDecision = Resolve-PythonInstallDecision -LocalExists ([bool]$validPython.Exists) -LocalValid ([bool]$validPython.Valid) -LocalVersion $validPython.Version -NetworkAllowed $false -Reason ([string]$validPython.Reason)
        Assert-SelfTest ([string]$validPythonDecision.Status -eq "ValidLocal") "Valid local Python did not resolve as ValidLocal."
        Assert-SelfTest (-not [bool]$validPythonDecision.NetworkLookupNeeded) "Valid local Python still required a Python.org lookup."

        $wrongPython = Test-LocalPythonInstall -PythonExe $fakePython -RequestedVersion "3.12" -AssumeExists -VersionText "Python 3.11.9" -VersionExitCode 0
        $wrongPythonDecision = Resolve-PythonInstallDecision -LocalExists ([bool]$wrongPython.Exists) -LocalValid ([bool]$wrongPython.Valid) -LocalVersion $wrongPython.Version -NetworkAllowed $true -Reason ([string]$wrongPython.Reason)
        Assert-SelfTest ([string]$wrongPythonDecision.Status -eq "InstallNeeded") "Wrong-series Python did not resolve as InstallNeeded when network is allowed."
        Assert-SelfTest ([bool]$wrongPythonDecision.NetworkLookupNeeded) "Wrong-series Python did not request Python.org lookup when install/update is needed."

        $blockedPythonDecision = Resolve-PythonInstallDecision -LocalExists ([bool]$wrongPython.Exists) -LocalValid ([bool]$wrongPython.Valid) -LocalVersion $wrongPython.Version -NetworkAllowed $false -Reason ([string]$wrongPython.Reason)
        Assert-SelfTest ([string]$blockedPythonDecision.Status -eq "NetworkBlocked") "Wrong/missing Python with NoNetwork did not resolve as NetworkBlocked."
        Assert-SelfTest (-not [bool]$blockedPythonDecision.NetworkLookupNeeded) "NoNetwork Python decision still requested Python.org lookup."

        $validVenv = Resolve-PythonVenvDecision -VenvExists $true -VenvPythonValid $true
        $createVenv = Resolve-PythonVenvDecision -VenvExists $false -VenvPythonValid $false
        $repairVenv = Resolve-PythonVenvDecision -VenvExists $true -VenvPythonValid $false
        Assert-SelfTest ([string]$validVenv.Status -eq "Valid" -and [bool]$validVenv.UsesLocalPython -and -not [bool]$validVenv.NetworkLookupNeeded) "Valid venv decision did not stay local/offline."
        Assert-SelfTest ([string]$createVenv.Status -eq "CreateLocal" -and [bool]$createVenv.UsesLocalPython -and -not [bool]$createVenv.NetworkLookupNeeded) "Missing venv decision did not use local Python only."
        Assert-SelfTest ([string]$repairVenv.Status -eq "RepairLocal" -and [bool]$repairVenv.UsesLocalPython -and -not [bool]$repairVenv.NetworkLookupNeeded) "Repair venv decision did not use local Python only."

        Set-ToolState -Name "python" -Status ([string]$validPythonDecision.Status) -Path $fakePython -Version ([string]$validPythonDecision.Version) -Source "harness" -Reason ([string]$validPythonDecision.Reason) -LocalValidated ([bool]$validPythonDecision.LocalValidated) -VenvStatus ([string]$validVenv.Status)
        $plainTools = @(Get-ToolStatePlainList)
        Assert-SelfTest (@($plainTools | Where-Object { [string]$_.name -eq "gh" -and [string]$_.status -eq "ValidLocal" }).Count -eq 1) "ToolStates did not include valid local gh."
        Assert-SelfTest (@($plainTools | Where-Object { [string]$_.name -eq "python" -and [string]$_.status -eq "ValidLocal" -and [string]$_.venvStatus -eq "Valid" }).Count -eq 1) "ToolStates did not include valid local Python and venv status."
    } catch { Add-SelfTestError "Offline-friendly tool decision self-test failed: $($_.Exception.Message)" }

    try {
        $check = [pscustomobject]@{ SourceSize=[int64]150GB; Buffer=[int64][Math]::Max([double]10GB, [double]150GB*0.05) }
        if ($check.Buffer -lt [int64]10GB) { [void]$errors.Add("P4K buffer math failed.") }
    } catch { [void]$errors.Add("P4K math failed: $($_.Exception.Message)") }

    try {
        Ensure-Directory $Script:HarnessRoot
        Assert-SelfTest (Test-InstallerPathUnderRoot -Path $DevRoot -Root $Script:HarnessRoot) "Harness DevRoot is not under HarnessRoot."
        $blocked = $false
        try { Assert-HarnessPathAllowed -Path (Join-Path $Script:OriginalDevRoot "harness-escape-check.txt") -Purpose "escape self-test" } catch { $blocked = $true }
        Assert-SelfTest $blocked "Harness path escape check did not block a write outside the allowed test roots."
    } catch { Add-SelfTestError "Harness path safety self-test failed: $($_.Exception.Message)" }

    try {
        Initialize-SetupPlan
        $ids = @($Script:SetupSteps | ForEach-Object { [string]$_.Id })
        $agentIndex = [Array]::IndexOf($ids, "write-agent-guidance")
        $gitIndex = [Array]::IndexOf($ids, "setup-git-versioning")
        Assert-SelfTest ($agentIndex -ge 0) "write-agent-guidance was missing from the setup plan."
        Assert-SelfTest ($gitIndex -ge 0) "setup-git-versioning was missing from the setup plan."
        if ($gitIndex -ge 0) { Assert-SelfTest ($agentIndex -ge 0 -and $agentIndex -lt $gitIndex) "write-agent-guidance did not appear before setup-git-versioning." }
        foreach ($later in @("write-workspace","vscode-extensions","build-starbreaker","locate-blender","install-blender-addon","select-data-p4k","verify-sc-build","p4k-explore","aurora-example")) {
            $idx = [Array]::IndexOf($ids, $later)
            if ($idx -ge 0) { Assert-SelfTest ($agentIndex -ge 0 -and $agentIndex -lt $idx) "write-agent-guidance did not appear before $later." }
            if ($idx -ge 0) { Assert-SelfTest ($gitIndex -ge 0 -and $gitIndex -lt $idx) "setup-git-versioning did not appear before $later." }
        }
    } catch { Add-SelfTestError "Setup plan ordering self-test failed: $($_.Exception.Message)" }

    try {
        $cases = @(
            "C:\Program Files\Roberts Space Industries\StarCitizen\LIVE\Data.p4k",
            "D:\StarCitizen\LIVE\Data.p4k",
            "D:\RSI\StarCitizen\LIVE\Data.p4k",
            "E:\Games\Roberts Space Industries\StarCitizen\PTU\Data.p4k"
        )
        foreach ($case in $cases) { Assert-SelfTest (Test-IsInstalledDataP4kCandidate -Path $case) "Installed Data.p4k string did not classify as installed source: $case" }
        Assert-SelfTest (-not (Test-IsInstalledDataP4kCandidate -Path "D:\dev\starcitizen\work\Data.p4k")) "Loose Data.p4k string incorrectly classified as installed source."
    } catch { Add-SelfTestError "Data.p4k string classification self-test failed: $($_.Exception.Message)" }

    $oldGlobal = $env:GIT_CONFIG_GLOBAL
    $oldNoSystem = $env:GIT_CONFIG_NOSYSTEM
    $oldHome = $env:HOME
    $oldXdgConfig = $env:XDG_CONFIG_HOME
    try {
        $git = Get-Command git -ErrorAction SilentlyContinue
        if ($null -eq $git) { throw "git was not found; cannot validate Git helper behavior." }
        $gitHome = Join-Path $Script:HarnessRoot "git-home"
        $gitConfigHome = Join-Path $Script:HarnessRoot "git-xdg"
        Ensure-Directory $gitHome
        Ensure-Directory $gitConfigHome
        $globalConfig = Join-Path $Script:HarnessRoot "git-tests\empty-global.gitconfig"
        Write-InstallerFile -Path $globalConfig -Text "# harness global Git config placeholder`r`n"
        $env:GIT_CONFIG_GLOBAL = $globalConfig
        $env:GIT_CONFIG_NOSYSTEM = "1"
        $env:HOME = $gitHome
        $env:XDG_CONFIG_HOME = $gitConfigHome
        $globalBefore = [IO.File]::ReadAllText($globalConfig)

        $localRepo = New-HarnessGitRepo "identity-present"
        Run-Native -Exe "git" -Arguments @("-C", $localRepo, "config", "--local", "user.name", "Existing User") -WorkingDirectory $localRepo
        Run-Native -Exe "git" -Arguments @("-C", $localRepo, "config", "--local", "user.email", "existing@example.invalid") -WorkingDirectory $localRepo
        $localResult = New-GitVersioningResult -Repo "identity-present" -Role "harness" -Path $localRepo -Branch "dev-test"
        Set-RepoLocalGitIdentity -Path $localRepo -Result $localResult
        Assert-SelfTest ((Get-LocalGitConfigValue $localRepo "user.name") -eq "Existing User") "Repo-local user.name was not preserved."
        Assert-SelfTest ((Get-LocalGitConfigValue $localRepo "user.email") -eq "existing@example.invalid") "Repo-local user.email was not preserved."
        Assert-SelfTest ([bool]$localResult.IdentityLocalPresent) "Repo-local identity was not reported as already present."

        $fallbackRepo = New-HarnessGitRepo "identity-fallback"
        $fallbackResult = New-GitVersioningResult -Repo "identity-fallback" -Role "harness" -Path $fallbackRepo -Branch "dev-test"
        Set-RepoLocalGitIdentity -Path $fallbackRepo -Result $fallbackResult
        Assert-SelfTest ((Get-LocalGitConfigValue $fallbackRepo "user.name") -eq "Local Developer") "Fallback user.name was not written correctly."
        Assert-SelfTest ((Get-LocalGitConfigValue $fallbackRepo "user.email") -eq "local@example.invalid") "Fallback user.email was not written correctly."
        Assert-SelfTest ([bool]$fallbackResult.IdentityFallbackWritten) "Fallback identity was not reported as written."
        $globalAfter = [IO.File]::ReadAllText($globalConfig)
        Assert-SelfTest ($globalBefore -eq $globalAfter) "Harness Git helper modified the configured global Git config file."

        $dirtyRepo = New-HarnessGitRepo "dirty-branch"
        Write-InstallerFile -Path (Join-Path $dirtyRepo "dirty.txt") -Text "dirty"
        $beforeBranch = Get-GitCurrentBranchSafe -Path $dirtyRepo
        Ensure-GitBranch -RepoName "dirty-branch" -Path $dirtyRepo -Branch "dev-target" -Role "harness" -SwitchBranch
        $dirtyState = $Script:BranchStates[$Script:BranchStates.Count - 1]
        Assert-SelfTest ([string]$dirtyState.Status -eq "WARN") "Dirty repo did not produce WARN."
        Assert-SelfTest ((Get-GitCurrentBranchSafe -Path $dirtyRepo) -eq $beforeBranch) "Dirty repo branch was switched."

        Ensure-GitBranch -RepoName "missing-repo" -Path (Join-Path $Script:HarnessRoot "git-tests\missing") -Branch "dev-target" -Role "harness" -SwitchBranch
        $missingState = $Script:BranchStates[$Script:BranchStates.Count - 1]
        Assert-SelfTest ([string]$missingState.Status -ne "OK") "Missing repo was reported as OK."

        foreach ($repo in @($localRepo, $fallbackRepo, $dirtyRepo)) {
            $countText = ((& git -C $repo rev-list --count --all 2>$null) -join "").Trim()
            if ([string]::IsNullOrWhiteSpace($countText)) { $countText = "0" }
            Assert-SelfTest ([int]$countText -eq 0) "Harness Git repo has commits unexpectedly: $repo"
        }
    } catch { Add-SelfTestError "Git helper harness self-test failed: $($_.Exception.Message)" }
    finally {
        $env:GIT_CONFIG_GLOBAL = $oldGlobal
        $env:GIT_CONFIG_NOSYSTEM = $oldNoSystem
        $env:HOME = $oldHome
        $env:XDG_CONFIG_HOME = $oldXdgConfig
    }

    try {
        $choices = @(Get-BlenderInstallChoices -Version "5.1")
        if ($choices.Count -lt 2) { [void]$errors.Add("Blender install path builder failed.") }
        foreach ($choice in $choices) { Assert-SelfTest (Test-InstallerPathUnderRoot -Path ([string]$choice.Path) -Root $Script:HarnessRoot) "Blender harness choice escaped HarnessRoot: $($choice.Path)" }
    } catch { [void]$errors.Add("Blender path selftest failed: $($_.Exception.Message)") }

    try {
        Write-AgentGuidanceFiles
        $marker = "SC-ZERO-TO-HERO-GENERATED: agent-guidance v1"
        Assert-SelfTest (Test-Path -LiteralPath $ProjectAgentsPath) "Harness AGENTS.md was not written."
        Assert-SelfTest (Test-Path -LiteralPath $ProjectClaudePath) "Harness CLAUDE.md was not written."
        Assert-SelfTest (Test-Path -LiteralPath $WorkspaceLaunchCmdPath) "Harness workspace launcher was not written."
        foreach ($requiredDir in @($AgentPromptsRoot, $AgentWorkRoot, $AgentOutputRoot, $AgentReportsRoot)) {
            Assert-SelfTest (Test-InstallerPathUnderRoot -Path $requiredDir -Root $Script:HarnessRoot) "Agent support directory escaped HarnessRoot: $requiredDir"
            Assert-SelfTest (Test-Path -LiteralPath $requiredDir) "Agent support directory was not created: $requiredDir"
        }
        $agentsText = Get-Content -LiteralPath $ProjectAgentsPath -Raw
        $claudeText = Get-Content -LiteralPath $ProjectClaudePath -Raw
        $launcherText = Get-Content -LiteralPath $WorkspaceLaunchCmdPath -Raw
        Assert-SelfTest ($agentsText.Contains($marker)) "Harness AGENTS.md missing generated marker."
        Assert-SelfTest ($claudeText.Contains($marker)) "Harness CLAUDE.md missing generated marker."
        Assert-SelfTest ($launcherText.Contains($WorkspacePath)) "Workspace launcher does not point at the harness workspace path."
        $realScWork = Join-Path (Join-Path $Script:OriginalDevRoot "scdata") "work"
        foreach ($text in @($agentsText, $claudeText, $launcherText)) {
            Assert-SelfTest (-not $text.Contains($realScWork)) "Generated harness file referenced the real ScWorkRoot."
            Assert-SelfTest (-not $text.Contains((To-ForwardSlashPath $realScWork))) "Generated harness file referenced the real ScWorkRoot with forward slashes."
        }

        $blockedDir = Join-Path $Script:HarnessRoot "agent-guidance-overwrite-test"
        Ensure-Directory $blockedDir
        $blockedAgents = Join-Path $blockedDir "AGENTS.md"
        Write-InstallerFile -Path $blockedAgents -Text "Human-authored guidance`r`n"
        $blockedResult = Write-GeneratedGuidanceFile -Path $blockedAgents -Content (Get-AgentGuidanceContent -Kind "AGENTS") -Label "AGENTS.md"
        Assert-SelfTest ([string]$blockedResult.Status -eq "WARN") "Unmarked AGENTS.md did not produce WARN fallback behavior."
        Assert-SelfTest ((Get-Content -LiteralPath $blockedAgents -Raw) -eq "Human-authored guidance`r`n") "Unmarked AGENTS.md was overwritten."
        Assert-SelfTest (Test-Path -LiteralPath ([string]$blockedResult.FallbackPath)) "Generated AGENTS fallback was not written."
    } catch { Add-SelfTestError "Agent guidance harness self-test failed: $($_.Exception.Message)" }

    try {
        Write-VSCodeWorkspace
        Assert-SelfTest (Test-Path -LiteralPath $WorkspacePath) "Harness workspace file was not written."
        $workspaceText = Get-Content -LiteralPath $WorkspacePath -Raw
        $workspace = $workspaceText | ConvertFrom-Json
        $expectedHarnessRoot = To-ForwardSlashPath $Script:HarnessRoot
        $folderNames = @($workspace.folders | ForEach-Object { [string]$_.name })
        foreach ($expectedName in @("Star Citizen Workspace Control","Prompt Archive","Agent Work Logs","Output Reports","StarBreaker","Blender-Tools","unp4k","Cryengine-Converter","SCTextureConverter","Zero to Hero Guide","scdatatools","qtvscodestyle","scdata")) {
            Assert-SelfTest ($folderNames -contains $expectedName) "Workspace missing folder: $expectedName"
        }
        foreach ($folder in @($workspace.folders)) {
            $path = [string]$folder.path
            Assert-SelfTest ($path.StartsWith($expectedHarnessRoot, [StringComparison]::OrdinalIgnoreCase)) "Workspace folder escaped harness root: $path"
        }
        $envBlock = $workspace.settings.'terminal.integrated.env.windows'
        $envNames = @($envBlock.PSObject.Properties.Name)
        foreach ($expectedEnv in @("SC_STAR_CITIZEN_ROOT","SC_PROMPTS_ROOT","SC_AGENT_WORK_ROOT","SC_REPORTS_ROOT","SC_WORKSPACE_PATH","SC_GUIDE_REPO")) {
            Assert-SelfTest ($envNames -contains $expectedEnv) "Workspace terminal env missing $expectedEnv."
            $envValue = ""
            try { $envValue = [string]$envBlock.PSObject.Properties[$expectedEnv].Value } catch { $envValue = "" }
            Assert-SelfTest ($envValue.StartsWith($expectedHarnessRoot, [StringComparison]::OrdinalIgnoreCase)) "Workspace env $expectedEnv did not use harness root."
        }
        Assert-SelfTest (-not ($envNames -contains "SC_BLENDER_EXE")) "Workspace wrote blank SC_BLENDER_EXE."
        Assert-SelfTest (-not ($envNames -contains "SC_BLENDER_VERSION")) "Workspace wrote blank SC_BLENDER_VERSION."
        Assert-SelfTest (-not ($envNames -contains "SC_DATA_P4K")) "Workspace wrote unconfirmed SC_DATA_P4K."
        Assert-SelfTest (-not $workspaceText.Contains((To-ForwardSlashPath (Join-Path (Join-Path $Script:OriginalDevRoot "scdata") "work")))) "Workspace referenced the real ScWorkRoot."
    } catch { Add-SelfTestError "Workspace generation self-test failed: $($_.Exception.Message)" }

    try {
        Save-SetupState
        Assert-SelfTest (Test-Path -LiteralPath $Script:SetupStatePath) "Harness setup-state file was not written."
        Assert-SelfTest (Test-InstallerPathUnderRoot -Path $Script:SetupStatePath -Root $Script:HarnessRoot) "Harness setup-state path escaped HarnessRoot."
    } catch { Add-SelfTestError "Setup-state harness self-test failed: $($_.Exception.Message)" }

    try { [void]((@([ordered]@{version=$Script:ScriptVersion; scriptVersion=$Script:ScriptVersion; starCitizenTestedBuilds=$Script:StarCitizenTestedBuilds; devRoot=$DevRoot} | ConvertTo-Json -Depth 4) -join [Environment]::NewLine)) } catch { [void]$errors.Add("setup-state serialization selftest threw: $($_.Exception.Message)") }
    if ($errors.Count -gt 0) {
        Write-Host "Self-test found issues:" -ForegroundColor Red
        foreach ($e in $errors) { Write-Host "  - $e" -ForegroundColor Red }
        exit 1
    }
    Write-Host "Safe non-live harness self-test passed." -ForegroundColor Green
    Write-Host "Harness root: $Script:HarnessRoot" -ForegroundColor DarkCyan
    exit 0
}



# v23 override: make Aurora MR export/import path use direct native process capture instead of a nested
# PowerShell pipeline. The v22 helper could finish with exit code 0 while the export log only contained
# "Trying Aurora MR export target..." and no command/exit details. This version logs every StarBreaker
# command, captures stdout/stderr safely, tries multiple candidate entity targets, verifies scene.json,
# then opens Blender with the existing best-effort import helper.
function Add-WorkLogLineV23 {
    param(
        [Parameter(Mandatory=$true)][string]$Path,
        [string]$Message = ""
    )
    try {
        $parent = Split-Path $Path -Parent
        if (-not [string]::IsNullOrWhiteSpace($parent)) { Ensure-Directory $parent }
        Add-Content -LiteralPath $Path -Value $Message -Encoding UTF8
    } catch {
        Write-Warning "Could not write work log '$Path': $($_.Exception.Message)"
    }
}

function ConvertTo-StarBreakerCommandLine {
    # v26: Convert a string[] argument list into a single Win32-compatible
    # command-line tail with correct quoting per CommandLineToArgvW rules.
    # Used by Invoke-StarBreakerLoggedV23 below when invoking starbreaker.exe
    # through Start-Process -ArgumentList, which in Windows PowerShell 5.1
    # does not auto-quote arguments containing spaces.
    param([string[]]$Arguments)
    if ($null -eq $Arguments -or $Arguments.Count -eq 0) { return "" }
    $parts = New-Object 'System.Collections.Generic.List[string]'
    foreach ($a in $Arguments) {
        $s = [string]$a
        if ([string]::IsNullOrEmpty($s)) {
            [void]$parts.Add('""')
        } elseif ($s -match '[\s"]') {
            $escaped = $s -replace '"','\"'
            [void]$parts.Add('"' + $escaped + '"')
        } else {
            [void]$parts.Add($s)
        }
    }
    return ($parts -join ' ')
}

function Invoke-StarBreakerLoggedV23 {
    param(
        [Parameter(Mandatory=$true)][string]$Exe,
        [Parameter(Mandatory=$true)][string[]]$Arguments,
        [Parameter(Mandatory=$true)][string]$LogPath,
        [switch]$Append,
        [string]$WorkingDirectory = "",
        [string]$ActivityNote = ""
    )
    if (-not $Append -and (Test-Path -LiteralPath $LogPath)) {
        Remove-Item -LiteralPath $LogPath -Force -ErrorAction SilentlyContinue
    }

    $display = $Exe
    if ($Arguments.Count -gt 0) { $display = "$Exe $($Arguments -join ' ')" }
    Add-WorkLogLineV23 -Path $LogPath -Message ("COMMAND: " + $display)
    if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory)) { Add-WorkLogLineV23 -Path $LogPath -Message ("WORKDIR: " + $WorkingDirectory) }
    Add-WorkLogLineV23 -Path $LogPath -Message ("STARTED: " + (Get-Date).ToString('s'))
    Add-WorkLogLineV23 -Path $LogPath -Message ""

    $stdout = Join-Path $ScLogsRoot ("starbreaker-stdout-" + [guid]::NewGuid().ToString('N') + ".tmp")
    $stderr = Join-Path $ScLogsRoot ("starbreaker-stderr-" + [guid]::NewGuid().ToString('N') + ".tmp")
    $exitCode = 9999

    # v26 ROOT-CAUSE FIX FOR AURORA EXPORT FAILURES:
    #
    # v23/v24/v25 used "& $Exe @Arguments > $stdout 2> $stderr" and claimed
    # in a comment that this redirected stderr "to a file so StarBreaker
    # warnings do not become PowerShell errors." That comment was incorrect.
    # In Windows PowerShell 5.1, the "2>" operator routes native-command
    # stderr through the PowerShell error pipeline FIRST (where
    # $ErrorActionPreference applies), then writes the resulting error
    # records to the redirection target file.
    #
    # With $ErrorActionPreference='Stop' active in the parent scope (which
    # this script sets globally), the very first stderr line StarBreaker
    # emits during the entity-export subcommand triggers a TerminatingError.
    # StarBreaker writes informational WARN lines continuously during a
    # real export ("mesh not found", "Found N candidates, using shortest
    # match", etc.) so the child gets killed within seconds, no scene.json
    # is produced, and the Aurora step fails. The v25 setup log showed
    # this happening for all four candidate targets.
    #
    # Start-Process -RedirectStandardError performs the redirection at the
    # Win32 process-creation level via CreateProcess handle inheritance.
    # PowerShell never receives the stderr byte stream at all, so
    # $ErrorActionPreference cannot fire on its contents. Combined with a
    # local override to 'Continue', this is bulletproof.
    $savedEAP = $ErrorActionPreference
    $ErrorActionPreference = 'Continue'
    try {
        $argLine = ConvertTo-StarBreakerCommandLine -Arguments $Arguments
        $startArgs = @{
            FilePath = $Exe
            RedirectStandardOutput = $stdout
            RedirectStandardError = $stderr
            NoNewWindow = $true
            PassThru = $true
            Wait = $true
        }
        if (-not [string]::IsNullOrWhiteSpace($argLine)) {
            # PowerShell 5.1 quirk: -ArgumentList accepts either a string or
            # string[]. Passing a single pre-quoted string preserves our
            # exact Win32-correct quoting. Passing an array would re-join
            # with spaces and drop quoting around spaces in path arguments.
            $startArgs.ArgumentList = $argLine
        }
        if (-not [string]::IsNullOrWhiteSpace($WorkingDirectory) -and (Test-Path -LiteralPath $WorkingDirectory)) {
            $startArgs.WorkingDirectory = $WorkingDirectory
        }
        if ($startArgs.ContainsKey('Wait')) { [void]$startArgs.Remove('Wait') }
        $proc = Start-Process @startArgs
        $spinnerFrames = @('|','/','-','\')
        $startTime = Get-Date
        $tick = 0
        if ([string]::IsNullOrWhiteSpace($ActivityNote)) {
            $ActivityNote = "StarBreaker is processing Data.p4k/output in the background. The elapsed timer, output log, and recent output confirm activity."
        }
        $Script:LastCommandLogPath = $LogPath
        $Script:LastCommandDisplay = $display
        $Script:LastActivityNote = $ActivityNote
        while ($null -ne $proc -and -not $proc.HasExited) {
            try {
                if (Test-Path -LiteralPath $stdout) {
                    $newStd = @(Get-Content -LiteralPath $stdout -ErrorAction SilentlyContinue)
                    if ($newStd.Count -gt 0) {
                        # Mirror the raw stdout into the work log while the command is still running.
                        # Rewriting only the whole stream each tick would be expensive, so append only lines we have not copied yet.
                        if ($null -eq $Script:StarBreakerStdoutMirrorCounts) { $Script:StarBreakerStdoutMirrorCounts = @{} }
                        $key = [string]$stdout
                        $already = if ($Script:StarBreakerStdoutMirrorCounts.ContainsKey($key)) { [int]$Script:StarBreakerStdoutMirrorCounts[$key] } else { 0 }
                        if ($newStd.Count -gt $already) {
                            $newStd[$already..($newStd.Count-1)] | Add-Content -LiteralPath $LogPath -Encoding UTF8
                            $Script:StarBreakerStdoutMirrorCounts[$key] = $newStd.Count
                        }
                    }
                }
            } catch { }
            $elapsed = (Get-Date) - $startTime
            $spinner = $spinnerFrames[$tick % $spinnerFrames.Count]
            Write-ActiveCommandDashboard -CommandDisplay $display -LogPath $LogPath -ActivityNote $ActivityNote -Spinner $spinner -Elapsed $elapsed -Status "RUNNING"
            Start-Sleep -Seconds 1
            $tick++
            try { $proc.Refresh() } catch { }
        }
        if ($null -ne $proc) { $exitCode = [int]$proc.ExitCode }

        if (Test-Path -LiteralPath $stdout) {
            # Ensure any stdout not mirrored during the loop is appended.
            try {
                $allStd = @(Get-Content -LiteralPath $stdout -ErrorAction SilentlyContinue)
                $key = [string]$stdout
                $already = 0
                if ($null -ne $Script:StarBreakerStdoutMirrorCounts -and $Script:StarBreakerStdoutMirrorCounts.ContainsKey($key)) { $already = [int]$Script:StarBreakerStdoutMirrorCounts[$key] }
                if ($allStd.Count -gt $already) { $allStd[$already..($allStd.Count-1)] | Add-Content -LiteralPath $LogPath -Encoding UTF8 }
            } catch { }
        }
        if (Test-Path -LiteralPath $stderr) {
            $errLines = @(Get-Content -LiteralPath $stderr -ErrorAction SilentlyContinue)
            if ($errLines.Count -gt 0) {
                Add-WorkLogLineV23 -Path $LogPath -Message ""
                Add-WorkLogLineV23 -Path $LogPath -Message "STDERR / WARNINGS:"
                foreach ($line in $errLines) { Add-WorkLogLineV23 -Path $LogPath -Message $line }
            }
        }
        Add-WorkLogLineV23 -Path $LogPath -Message ""
        Add-WorkLogLineV23 -Path $LogPath -Message ("FINISHED: " + (Get-Date).ToString('s'))
        Add-WorkLogLineV23 -Path $LogPath -Message ("EXIT CODE: " + [string]$exitCode)
        $elapsedFinal = (Get-Date) - $startTime
        $finalStatus = if ($exitCode -eq 0) { "COMPLETE" } else { "FAILED" }
        Write-ActiveCommandDashboard -CommandDisplay $display -LogPath $LogPath -ActivityNote $ActivityNote -Spinner "*" -Elapsed $elapsedFinal -Status $finalStatus
        Start-Sleep -Milliseconds 350
        return [int]$exitCode
    } catch {
        Add-WorkLogLineV23 -Path $LogPath -Message ("ERROR: " + $_.Exception.Message)
        return 9999
    } finally {
        $ErrorActionPreference = $savedEAP
        Remove-Item -LiteralPath $stdout,$stderr -Force -ErrorAction SilentlyContinue
    }
}

function Get-AuroraExportTargetsV23 {
    param([Parameter(Mandatory=$true)][string]$LoadoutLog)
    $records = New-Object 'System.Collections.Generic.List[object]'
    if (Test-Path -LiteralPath $LoadoutLog) {
        foreach ($line in Get-Content -LiteralPath $LoadoutLog -ErrorAction SilentlyContinue) {
            if ($line -notmatch '^\s*EntityClassDefinition\.([A-Za-z0-9_]+).*?geom=(.*)$') { continue }
            $name = [string]$matches[1]
            $geom = [string]$matches[2]
            if ($name -notmatch '^RSI_Aurora_MR') { continue }
            $score = 0
            if ($name -match '^RSI_Aurora_MR($|_PU)') { $score += 100 }
            if ($name -match 'PU_AI_CIV') { $score += 35 }
            if ($name -match 'PU_AI_CRIM') { $score += 25 }
            if ($geom -match '(?i)Spaceships[\\/]Ships[\\/]RSI[\\/]Aurora[\\/]Exterior[\\/]RSI_Aurora\.cga') { $score += 100 }
            if ($name -match '(?i)_shop|INTK_|HTNK_|QTNK_|ARMR_|Thruster|Controller|vehicle_display|SCItem|DockingTube|Screen|SeatAccess|Seat_Pilot|Dashboard|Cargo|Door') { $score -= 250 }
            if ([string]::IsNullOrWhiteSpace($geom) -or $geom -eq '-') { $score -= 80 }
            [void]$records.Add([pscustomobject]@{ Name=$name; Geom=$geom; Score=$score })
        }
    }

    $ordered = New-Object 'System.Collections.Generic.List[string]'
    foreach ($r in ($records | Sort-Object Score -Descending)) {
        if ($r.Score -gt 0 -and -not $ordered.Contains([string]$r.Name)) { [void]$ordered.Add([string]$r.Name) }
    }
    foreach ($fallback in @('RSI_Aurora_MR_PU_AI_CIV','RSI_Aurora_MR_PU_AI_CRIM','RSI_Aurora_MR_PU','RSI_Aurora_MR')) {
        if (-not $ordered.Contains($fallback)) { [void]$ordered.Add($fallback) }
    }
    return @($ordered.ToArray())
}

function Run-AuroraExportExample {
    Write-Step "Running Aurora MR P4K exploration/export example"
    if (-not $RunAuroraExample) {
        if ($Script:VisualPreviewMode) {
            Write-Host "VISUAL PREVIEW MODE ACTIVE - would ask whether to run the Aurora MR export example." -ForegroundColor Magenta
            return
        }
        Write-Host "Optional Aurora MR export example" -ForegroundColor Cyan
        Write-Host "This follows the tutorial's final Aurora path search, loadout, decomposed export, file-tree capture, and Blender handoff." -ForegroundColor Yellow
        Write-Host "Export folder:" -ForegroundColor Yellow
        Write-Host "  $ScExportRoot\aurora_mr_decomposed" -ForegroundColor DarkYellow
        $ans = Read-Host "Run Aurora MR export example now? Y/N (default N)"
        if ($ans.Trim() -notmatch '^[Yy]$') {
            $reason = "User skipped optional Aurora MR export example."
            $Script:CurrentStepResultStatus = "SKIPPED"
            $Script:CurrentStepResultReason = $reason
            Add-SetupSkipRecord -Id "aurora-example" -Name "Optional Aurora MR export example" -Reason $reason
            return
        }
    }
    if ($DryRun) {
        Write-Host "[dry-run] Would run Aurora MR P4K list/loadout/export commands and then open Blender."
        return
    }

    $starBreakerPath = Join-Path $StarCitizenRoot "StarBreaker"
    $starBreakerExe = Join-Path $starBreakerPath "target\release\starbreaker.exe"
    if (-not (Test-Path -LiteralPath $starBreakerExe)) {
        $reason = "starbreaker.exe not found. Build StarBreaker first: $starBreakerExe"
        Write-Warning $reason
        Add-SetupSkipRecord -Id "aurora-example" -Name "Optional Aurora MR export example" -Reason $reason
        $Script:CurrentStepResultStatus = "SKIPPED"
        $Script:CurrentStepResultReason = $reason
        return
    }

    $dataP4k = Prepare-DataP4k
    if ($null -eq $dataP4k -or -not (Test-Path -LiteralPath $dataP4k)) {
        $reason = "Skipping Aurora example because no confirmed Data.p4k is available."
        Write-Warning $reason
        Add-SetupSkipRecord -Id "aurora-example" -Name "Optional Aurora MR export example" -Reason $reason
        $Script:CurrentStepResultStatus = "SKIPPED"
        $Script:CurrentStepResultReason = $reason
        return
    }

    $build = if (-not [string]::IsNullOrWhiteSpace($Script:P4KState.build)) { $Script:P4KState.build } else { $StarCitizenBuild }
    if ([string]::IsNullOrWhiteSpace($build) -or $build -match '(?i)unknown') {
        $reason = "Skipping Aurora example because the Star Citizen build label is missing or unknown."
        Write-Warning $reason
        Add-SetupSkipRecord -Id "aurora-example" -Name "Optional Aurora MR export example" -Reason $reason
        $Script:CurrentStepResultStatus = "SKIPPED"
        $Script:CurrentStepResultReason = $reason
        return
    }

    $env:SC_BUILD = $build
    $env:SC_DATA_P4K = $dataP4k
    $env:SC_P4K_ROOT = $ScP4kRoot
    $env:SC_EXPORT_ROOT = $ScExportRoot
    $env:SC_WORK_ROOT = $ScWorkRoot

    Ensure-Directory $ScWorkRoot
    Ensure-Directory $ScExportRoot
    $rsiRawLog = Join-Path $ScWorkRoot "rsi_ship_paths_raw_$build.txt"
    $auroraPathsLog = Join-Path $ScWorkRoot "aurora_rsi_ship_paths_$build.txt"
    $loadoutGenericLog = Join-Path $ScWorkRoot "loadout_RSI_Aurora_$build.txt"
    $loadoutMrLog = Join-Path $ScWorkRoot "loadout_RSI_Aurora_MR_$build.txt"
    $exportLog = Join-Path $ScWorkRoot "export_RSI_Aurora_MR_decomposed_$build.txt"
    $treeLog = Join-Path $ScWorkRoot "export_RSI_Aurora_MR_decomposed_filetree_$build.txt"
    $targetLog = Join-Path $ScWorkRoot "export_RSI_Aurora_MR_target_$build.txt"
    $exportDir = Join-Path $ScExportRoot "aurora_mr_decomposed"
    Ensure-Directory $exportDir

    # v25: Idempotency check. If a previous run for this build already
    # produced a valid scene.json under $exportDir, offer to reuse it. The
    # full Aurora MR re-export can take many minutes, so being able to
    # skip straight to "open Blender" on subsequent runs is a major
    # quality-of-life improvement for testing the last three tutorial
    # steps in isolation.
    $existingSceneJson = Find-AuroraExportSceneJson -ExportDir $exportDir
    if (-not [string]::IsNullOrWhiteSpace($existingSceneJson) -and (Test-Path -LiteralPath $existingSceneJson)) {
        Write-Host "Found existing Aurora MR export from a previous run:" -ForegroundColor Yellow
        Write-Host "  $existingSceneJson" -ForegroundColor DarkYellow
        $reuse = Read-Host "Reuse the existing export and skip re-export? Y/N (default Y)"
        if ($reuse.Trim() -notmatch '^[Nn]$') {
            Write-Host "Reusing existing Aurora MR export." -ForegroundColor Green
            Open-AuroraExportInBlender -SceneJson $existingSceneJson -ExportDir $exportDir
            return
        }
        Write-Host "Re-exporting Aurora MR (existing export will be replaced)." -ForegroundColor Cyan
    }

    Write-Host "Writing Aurora work logs under: $ScWorkRoot" -ForegroundColor Cyan

    $ec = Invoke-StarBreakerLoggedV23 -Exe $starBreakerExe -Arguments @('p4k','list','--filter','Data/Objects/Spaceships/Ships/RSI/**','--p4k',$dataP4k) -LogPath $rsiRawLog -WorkingDirectory $starBreakerPath
    if ($ec -ne 0) { throw "StarBreaker RSI path listing failed with exit code $ec. See $rsiRawLog" }
    try {
        Get-Content -LiteralPath $rsiRawLog -ErrorAction SilentlyContinue |
            Select-String -Pattern 'Aurora' -CaseSensitive:$false |
            ForEach-Object { $_.Line } |
            Set-Content -LiteralPath $auroraPathsLog -Encoding UTF8
    } catch {
        Write-Warning "Could not create Aurora-only path log: $($_.Exception.Message)"
    }

    $ec = Invoke-StarBreakerLoggedV23 -Exe $starBreakerExe -Arguments @('entity','loadout','RSI_Aurora','--p4k',$dataP4k) -LogPath $loadoutGenericLog -WorkingDirectory $starBreakerPath
    if ($ec -ne 0) { throw "StarBreaker generic Aurora loadout failed with exit code $ec. See $loadoutGenericLog" }

    $ec = Invoke-StarBreakerLoggedV23 -Exe $starBreakerExe -Arguments @('entity','loadout','RSI_Aurora_MR','--p4k',$dataP4k) -LogPath $loadoutMrLog -WorkingDirectory $starBreakerPath
    if ($ec -ne 0) { throw "StarBreaker Aurora MR loadout failed with exit code $ec. See $loadoutMrLog" }

    if (Test-Path -LiteralPath $exportLog) { Remove-Item -LiteralPath $exportLog -Force -ErrorAction SilentlyContinue }
    $targets = @(Get-AuroraExportTargetsV23 -LoadoutLog $loadoutMrLog)
    Add-WorkLogLineV23 -Path $targetLog -Message "Aurora MR export candidate order:"
    foreach ($t in $targets) { Add-WorkLogLineV23 -Path $targetLog -Message "  $t" }

    $success = $false
    $sceneJson = ""
    $selectedTarget = ""
    foreach ($target in $targets) {
        Add-WorkLogLineV23 -Path $exportLog -Message ("Trying Aurora MR export target: " + $target)
        Write-Host ("Trying Aurora MR export target: {0}" -f $target) -ForegroundColor Cyan
        if (Test-Path -LiteralPath $exportDir) {
            try { Remove-Item -LiteralPath $exportDir -Recurse -Force -ErrorAction SilentlyContinue } catch { }
        }
        Ensure-Directory $exportDir
        $ec = Invoke-StarBreakerLoggedV23 -Exe $starBreakerExe -Arguments @('entity','export',$target,$exportDir,'--p4k',$dataP4k,'--kind','decomposed','--materials','textures','--lod','1','--mip','2') -LogPath $exportLog -Append -WorkingDirectory $starBreakerPath
        $sceneJson = Find-AuroraExportSceneJson -ExportDir $exportDir
        if ($ec -eq 0 -and -not [string]::IsNullOrWhiteSpace($sceneJson) -and (Test-Path -LiteralPath $sceneJson)) {
            Add-WorkLogLineV23 -Path $exportLog -Message ("Aurora MR export succeeded with target: " + $target)
            $selectedTarget = $target
            $success = $true
            break
        }
        Add-WorkLogLineV23 -Path $exportLog -Message ("Target failed or produced no scene.json: " + $target + " exit=" + [string]$ec)
    }

    if (-not $success) {
        # v25: Richer diagnostic when every export target fails. The one-line
        # "did not produce scene.json after trying N target(s)" message in
        # v24 left the user with no actionable information. v25 enumerates
        # which targets were tried, what landed (if anything) in the export
        # directory, points at the relevant logs, and lists the most common
        # root causes so the user can self-diagnose without combing logs.
        $diagLines = New-Object 'System.Collections.Generic.List[string]'
        $diagLines.Add("Aurora MR export did not produce scene.json after trying $($targets.Count) target(s).")
        $diagLines.Add("")
        $diagLines.Add("Attempted targets, in scoring order:")
        if ($targets.Count -eq 0) {
            $diagLines.Add("  <none - target selection produced an empty list>")
        } else {
            foreach ($t in $targets) { $diagLines.Add("  - $t") }
        }
        $diagLines.Add("")
        $diagLines.Add("Export directory contents after the final attempt ($exportDir):")
        try {
            $allFiles = @(Get-ChildItem -LiteralPath $exportDir -Recurse -File -ErrorAction SilentlyContinue)
            if ($allFiles.Count -eq 0) {
                $diagLines.Add("  <empty - StarBreaker exited before writing any files>")
            } else {
                $shown = $allFiles | Select-Object -First 20
                foreach ($f in $shown) { $diagLines.Add("  - $($f.FullName) ($($f.Length) bytes)") }
                if ($allFiles.Count -gt 20) { $diagLines.Add("  ... and $($allFiles.Count - 20) more file(s)") }
            }
        } catch {
            $diagLines.Add("  <could not enumerate export dir: $($_.Exception.Message)>")
        }
        $diagLines.Add("")
        $diagLines.Add("Logs to consult, most useful first:")
        $diagLines.Add("  Export command output: $exportLog")
        $diagLines.Add("  Aurora MR loadout:     $loadoutMrLog")
        $diagLines.Add("  Generic Aurora loadout: $loadoutGenericLog")
        $diagLines.Add("  Target selection trace: $targetLog")
        $diagLines.Add("")
        $diagLines.Add("Most common root causes:")
        $diagLines.Add("  - Data.p4k is from a different Star Citizen build than what StarBreaker expects;")
        $diagLines.Add("    pull a fresh StarBreaker build that matches your game install.")
        $diagLines.Add("  - The Aurora MR entity has been renamed in the live build; inspect the loadout log")
        $diagLines.Add("    for the actual entity name and pass it via -P4KBuildLabel/script flow.")
        $diagLines.Add("  - StarBreaker built but the entity-export subcommand silently failed; check")
        $diagLines.Add("    the export command output for stderr noise that wasn't an exit-code failure.")
        $diagMessage = ($diagLines -join "`r`n")
        Write-Host "" -ForegroundColor Red
        Write-Host $diagMessage -ForegroundColor Red
        throw $diagMessage
    }

    try {
        Get-ChildItem -LiteralPath $exportDir -Recurse -ErrorAction SilentlyContinue |
            Select-Object FullName, Length |
            Out-File -LiteralPath $treeLog -Encoding utf8
    } catch {
        Write-Warning "Could not write export file-tree log: $($_.Exception.Message)"
    }

    Write-Host "Aurora path log: $auroraPathsLog" -ForegroundColor Green
    Write-Host "Loadout logs: $loadoutGenericLog ; $loadoutMrLog" -ForegroundColor Green
    Write-Host "Export log: $exportLog" -ForegroundColor Green
    Write-Host "Selected export target: $selectedTarget" -ForegroundColor Green
    Write-Host "Export folder: $exportDir" -ForegroundColor Green
    Write-Host "Scene JSON: $sceneJson" -ForegroundColor Green
    Write-Host "File tree log: $treeLog" -ForegroundColor Green

    Open-AuroraExportInBlender -SceneJson $sceneJson -ExportDir $exportDir
}

# Main
if ($SelfTest) { Invoke-SelfTest }
Initialize-SetupPlan
if ($ListSteps) {
    Show-SetupPlan
    if (-not [string]::IsNullOrWhiteSpace($EmitPlanJson)) { Write-SetupPlanJson -Path $EmitPlanJson }
    return
}
if ($Script:PlanOnly) {
    Show-SetupPlan
    if (-not [string]::IsNullOrWhiteSpace($EmitPlanJson)) { Write-SetupPlanJson -Path $EmitPlanJson }
    Write-Host "PlanOnly completed. No setup actions were executed." -ForegroundColor Green
    return
}
if (-not $Script:VisualPreviewMode) {
    Show-SetupPlan
}

$mainFailed = $false
try {
    Confirm-SetupPlan
    try { Clear-Host } catch { }
    Initialize-ProgressHeader

    Invoke-SetupStep -Id "preflight-folders" -Name "Preflight checks and tutorial folder layout" -Fatal -ScriptBlock {
        Test-SetupPreflight
        New-WorkFolders
    }

    Invoke-SetupStep -Id "logging-env" -Name "Transcript log and environment variables" -ScriptBlock {
        Start-SetupTranscriptAndEnvironment
    }

    if ($InstallTools) { Install-BaseTools }
    if ($CloneRepos) {
        Invoke-SetupStep -Id "clone-repos" -Name "Clone or validate community repositories" -ScriptBlock { Sync-Repositories }
        Invoke-SetupStep -Id "clone-guide-repo" -Name "Clone or validate DirectorGunner tutorial repository" -ScriptBlock { Sync-GuideRepository }
    }
    if (Test-ShouldWriteAgentGuidance) {
        Invoke-SetupStep -Id "write-agent-guidance" -Name "Create agent guidance, prompt archive, work log, and report folders" -ScriptBlock { Write-AgentGuidanceFiles }
    }
    if (Test-ShouldRunGitVersioning) {
        Invoke-SetupStep -Id "setup-git-versioning" -Name "Initialize local Git versioning and safe development branches" -ScriptBlock { Initialize-GitVersioning }
    }
    if ($CreateWorkspace) {
        Invoke-SetupStep -Id "write-workspace" -Name "Create VS Code multi-root workspace" -ScriptBlock { Write-VSCodeWorkspace }
        Invoke-SetupStep -Id "vscode-extensions" -Name "Install recommended VS Code extensions" -ScriptBlock { Install-VSCodeExtensions }
    }
    if ($BuildStarBreaker) { Invoke-SetupStep -Id "build-starbreaker" -Name "Build StarBreaker and StarBreaker MCP" -ScriptBlock { Build-StarBreakerProject } }
    if (-not $SkipBlender -and ($PromptForBlender -or $InstallBlenderAddon -or -not [string]::IsNullOrWhiteSpace($BlenderPath))) {
        Invoke-SetupStep -Id "locate-blender" -Name "Locate or install Blender" -ScriptBlock { Select-OrInstallBlender }
    }
    if (-not $SkipBlender -and $InstallBlenderAddon) { Invoke-SetupStep -Id "install-blender-addon" -Name "Link StarBreaker Blender add-on" -ScriptBlock { Install-StarBreakerBlenderAddon } }
    if (-not $SkipP4K -and ($SetupP4K -or $PromptForP4K -or $RunAuroraExample -or -not [string]::IsNullOrWhiteSpace($DataP4kSource))) {
        Invoke-SetupStep -Id "select-data-p4k" -Name "Select or copy Star Citizen Data.p4k" -ScriptBlock { Select-OrCopyDataP4k }
        Invoke-SetupStep -Id "verify-sc-build" -Name "Verify Star Citizen build environment" -ScriptBlock { Verify-StarCitizenBuildEnvironment }
        Invoke-SetupStep -Id "p4k-explore" -Name "Explore P4K paths" -ScriptBlock { Explore-P4KPaths }
    }
    if (-not $SkipP4K -and ($SetupP4K -or $PromptForP4K -or $RunAuroraExample -or -not [string]::IsNullOrWhiteSpace($DataP4kSource))) {
        Invoke-SetupStep -Id "aurora-example" -Name "Optional Aurora MR export example" -ScriptBlock { Run-AuroraExportExample }
    }

    if ($RunInteractiveAuth) {
        Invoke-SetupStep -Id "interactive-auth" -Name "Start interactive authentication helpers" -ScriptBlock {
            Write-Step "Starting interactive authentication steps"
            $ghExe = Join-Path $GhRoot "bin\gh.exe"
            if (Test-Path $ghExe) {
                Run-Native -Exe $ghExe -Arguments @("auth", "login", "--hostname", "github.com", "--git-protocol", "https", "--web") -IgnoreExitCode -Interactive
            }
            $codexCmd = Join-Path $NpmGlobalDir "codex.cmd"
            if (Test-Path $codexCmd) {
                Write-Host "Run 'codex' in a normal terminal when ready to sign in."
            }
        }
    }

    Invoke-SetupStep -Id "final-verification" -Name "Final verification summary" -ScriptBlock { Run-FinalVerification }

    if ($OpenWorkspace) {
        Invoke-SetupStep -Id "open-workspace" -Name "Open generated VS Code workspace" -ScriptBlock {
            $codeCmd = Get-VSCodeCommandPath -PromptIfMissing:$PromptForVSCodePath
            if (-not [string]::IsNullOrWhiteSpace($codeCmd)) {
                Run-Native -Exe $codeCmd -Arguments @($WorkspacePath) -IgnoreExitCode
            } else {
                Write-Warning "code.cmd not found; open VS Code manually and select the workspace: $WorkspacePath"
            }
        }
    }

    Invoke-SetupStep -Id "complete" -Name "Completion notes" -ScriptBlock {
        if ($Script:HiddenDryRun) {
            Write-Host "`nVisual preview completed. No install actions were executed." -ForegroundColor Green
        } else {
            if ($Script:SetupFailures.Count -gt 0 -or $Script:SetupSkips.Count -gt 0) {
                Write-Host "`nSetup reached the end with recoverable issues." -ForegroundColor Yellow
            } else {
                Write-Host "`nSetup script completed." -ForegroundColor Green
            }
            Write-Host "Open a new Developer PowerShell or VS Code terminal so all PATH and environment variable changes are visible."
        }
        Write-Host ("Script version: {0}" -f $Script:ScriptVersion)
        Write-Host ("Star Citizen tested builds: {0}" -f $Script:StarCitizenTestedBuildsDisplay)
        Write-Host "Workspace: $WorkspacePath"
        Write-Host "Workspace launcher: $WorkspaceLaunchCmdPath"
        Write-Host "Guide / updates: $($Script:GuideUrl)"
        if (-not [string]::IsNullOrWhiteSpace($Script:TutorialRepoState.path)) { Write-Host "Local guide repo: $($Script:TutorialRepoState.path)" }
        if (-not [string]::IsNullOrWhiteSpace($Script:SetupStatePath)) { Write-Host "Setup state: $($Script:SetupStatePath)" }
        Write-Host "Tip: keep this launcher next to your tutorial repo notes so future setup steps can be added cleanly."
        if (-not [string]::IsNullOrWhiteSpace($Script:TranscriptLogPath)) { Write-Host "Transcript log: $Script:TranscriptLogPath" }
    }

    if ($Script:HiddenDryRun) {
        Write-Host "`nVisual preview completed. No install actions were executed." -ForegroundColor Green
    }
} catch {
    $mainFailed = $true
    # v11: Show the SPECIFIC step that failed, not just the exception text.
    # On a 90-minute install, "Setup failed: ..." in isolation isn't actionable;
    # users need the step name and a re-run hint they can act on.
    $failedStepName = if ([string]::IsNullOrWhiteSpace($Script:CurrentStepName)) { "Unknown" } else { $Script:CurrentStepName }
    $failedStepId = if ([string]::IsNullOrWhiteSpace($Script:CurrentStepId)) { "" } else { $Script:CurrentStepId }
    Write-Host ""
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host (" Setup FAILED at step: {0}" -f $failedStepName) -ForegroundColor Red
    if (-not [string]::IsNullOrWhiteSpace($failedStepId)) {
        Write-Host (" Step ID: {0}" -f $failedStepId) -ForegroundColor DarkRed
    }
    Write-Host "================================================================" -ForegroundColor Red
    Write-Host (" Reason: {0}" -f $_.Exception.Message) -ForegroundColor Red
    if (-not [string]::IsNullOrWhiteSpace($Script:LastCommandLogPath) -and (Test-Path -LiteralPath $Script:LastCommandLogPath)) {
        Write-Host (" Last command log: {0}" -f $Script:LastCommandLogPath) -ForegroundColor Yellow
    }
    if (-not [string]::IsNullOrWhiteSpace($Script:TranscriptLogPath)) {
        Write-Host (" Full transcript: {0}" -f $Script:TranscriptLogPath) -ForegroundColor Yellow
    } else {
        Write-Host (" Logs folder: {0}" -f $ScLogsRoot) -ForegroundColor Yellow
    }
    Write-Host ""
    # v11: Tailored resume hint based on which step failed.
    Write-Host "Recovery tips for this specific failure:" -ForegroundColor Yellow
    foreach ($line in (Get-ResumeHintForStep -StepId $failedStepId)) {
        Write-Host $line -ForegroundColor Yellow
    }
    Write-Host ""
    Write-Host (("Living guide: {0}" -f $Script:GuideUrl)) -ForegroundColor DarkYellow
} finally {
    try { Show-SetupOutcomeSummary } catch { try { Write-Warning "Setup outcome summary failed to render: $($_.Exception.Message)" } catch { } }
    try { Show-StepTimingSummary } catch { try { Write-Warning "Step timing summary failed to render: $($_.Exception.Message)" } catch { } }
    try { Save-SetupState } catch { try { Write-Warning "Final setup-state save failed: $($_.Exception.Message)" } catch { } }
    if ($Script:TranscriptStarted) { try { Stop-Transcript | Out-Null } catch { } }
    if ($mainFailed -and $Script:ProgressHeaderEnabled) {
        try {
            $failStepNumber = if ($Script:CurrentStepNumber -gt 0) { $Script:CurrentStepNumber } else { 0 }
            $failStepName = if ([string]::IsNullOrWhiteSpace($Script:CurrentStepName)) { "Setup failed - see log" } else { $Script:CurrentStepName }
            $failCompleted = [Math]::Max(0, $Script:CurrentCompletedBefore)
            Write-SetupProgress -CompletedCount $failCompleted -StepNumber $failStepNumber -StepName $failStepName -Status "FAILED"
        } catch { }
    }
}

$hasTimedFailure = $false
try {
    foreach ($r in (Get-ListSnapshot $Script:StepTimings)) {
        if ($null -eq $r) { continue }
        if ([string]$r.Status -match '^(FAIL|FAILED|FATAL)$') { $hasTimedFailure = $true; break }
    }
} catch { $hasTimedFailure = $false }
if ($mainFailed -or $Script:FatalFailure) { exit 1 }
if (($Script:SetupFailures.Count -gt 0) -or ($Script:SetupSkips.Count -gt 0) -or $hasTimedFailure) { exit 2 }
exit 0
