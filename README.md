# Zero to Hero: Star Citizen Asset Extraction and Modding Workflow

A modern Windows power-user workflow for StarBreaker, Blender, `Data.p4k` exploration, and AI-assisted community tool development.

> Community tutorial by [DirectorGunner](https://robertsspaceindustries.com/en/citizens/DirectorGunner).

## Overview

Times have changed. Welcome to a new era of Star Citizen asset exploration, where modern community tools and AI-assisted workflows can massively reduce the barrier to entry.

This guide is aimed at power users, modders, artists, and technically curious backers who are comfortable following command-line instructions. That said, if you use an AI assistant carefully and ask it to explain each step, you can work through this setup even with little to no prior command-line experience.

The goal of this repo is to maintain an all-in-one workflow that brings together community projects like StarBreaker, Blender, CryEngine conversion tools, texture tools, `Data.p4k` organization, VS Code, and AI-assisted development into one practical pipeline that anyone with patience can use.

> [!NOTE]
> This guide is maintained as a living document. Star Citizen is an active alpha, and community tools may break or change as CIG updates the game data format.

> [!IMPORTANT]
> This guide is intended for personal learning, fan art, research, and community tooling. Treat your local `Data.p4k` files as read-only, do not redistribute extracted game assets, and respect CIG's terms and community rules.

> [!WARNING]
>
> ## Windows 11 Smart App Control must be Off before installing developer tools
>
> This workflow installs and runs developer tools such as **Git for Windows**, **Rust**, **Visual Studio Build Tools**, **Python**, **Node.js**, **CMake**, and related command-line components.
>
> On some Windows 11 systems, **Smart App Control** may block these tools or their DLL files before they can run. If Smart App Control is On or in Evaluation mode, setup may fail with messages like:
>
> * "Smart App Control blocked an app that may be unsafe"
> * "Part of this app has been blocked"
> * `msys-2.0.dll`
> * `libintl-8.dll`
> * `libpcre2-8-0.dll`
> * `libiconv-2.dll`
> * `libwinpthread-1.dll`
> * `rustup-init.exe`
> * `Bad Image`
> * `0xc0e90002`
>
> Before running the installer or following the manual tool-install steps:
>
> 1. Open **Windows Security**.
> 2. Go to **App & browser control**.
> 3. Open **Smart App Control settings**.
> 4. Set **Smart App Control** to **Off**.
> 5. Run the installer again.
>
> The installer does **not** disable Smart App Control for you. Running as Administrator does not bypass Smart App Control. This is a Windows security setting that must be changed by the user.
>
> If you keep Smart App Control On or in Evaluation mode, Windows may block Git, Rust, or other developer tools and the setup cannot reliably continue.

> [!IMPORTANT]
>
> ## Before launching the installer: Unblock it and run as Administrator
>
> Windows may mark downloaded `.cmd` files as coming from another computer. If the installer is blocked this way, Windows may prevent parts of the setup from running correctly.
>
> Before running the installer:
>
> 1. Right-click `Launch-SC-Zero-to-Hero-Setup.cmd`.
>
> 2. Choose **Properties**.
>
> 3. On the **General** tab, look near the bottom for:
>
>    `Security: This file came from another computer and might be blocked to help protect this computer.`
>
> 4. Check **Unblock**.
>
> 5. Click **Apply**, then **OK**.
>
> 6. Right-click the installer again and choose **Run as administrator**.
>
> If you do not see an **Unblock** checkbox, Windows has not marked the file that way and you can continue.
>
> This is separate from **Smart App Control**. You should still make sure **Smart App Control is Off** before installing developer tools.

## Recommended one-click installer

The recommended path is to run the guided installer:

```text
Launch-SC-Zero-to-Hero-Setup.cmd
```

Before running it:

- Set **Windows Security > App & browser control > Smart App Control settings** to **Off**.
- Right-click the `.cmd`, open **Properties**, and check **Unblock** if Windows shows it.
- Right-click the `.cmd` again and choose **Run as administrator**.

The launcher plays a scene-release-style music track by default on the first prompt. Press **M** at that first prompt to mute or unmute. Music stops before setup begins and does not play during tool installation. Set `SC_ZERO_TO_HERO_MUSIC=0` before launching if you want music disabled from the start.

The installer asks where to create the dev environment. Common choices are:

- `D:\dev`
- `C:\dev`
- a custom path you choose

It creates the folder layout, validates or installs tools, clones the community repos, creates the VS Code workspace, sets up safe Git branches, generates support files, links or validates the StarBreaker Blender add-on, handles `Data.p4k` selection, and can generate/open the Aurora Blender scene.

The installer is designed to be rerunnable. If it stops, crashes, repairs WinGet/App Installer, asks you to relaunch, or you skip a step, run the same CMD again. Completed steps are revalidated and skipped or reused where practical.

For Visual Studio Build Tools, the installer validates first. If Build Tools are already installed and valid, it skips that step. If they are missing or invalid, it asks Y/N:

- **Y** is recommended for a full setup.
- **N** is useful for Windows Sandbox, quick validation, or a machine where you do not want Build Tools installed now.
- If you choose **N**, StarBreaker build steps may skip unless existing binaries validate.

Windows Sandbox is useful for checking the launch flow, Smart App Control standby behavior, root selection, tool install flow, Build Tools skip/full-install behavior, logs, and Blender UI smoke tests. It is not proof that the full toolchain behaves exactly like a normal desktop. Sandbox can have input lag or scrolling issues in Blender, Visual Studio Build Tools can take too long or fail there, and some Sandbox images may not have the Smart App Control settings UI or protocol handler available.

If you test Git repos in Sandbox, do **not** map the entire DevRoot as `C:\dev`. Mapping all of `C:\dev` from the host can make Git report dubious ownership because the repos are owned by a different Windows SID. For large P4K capacity, map only storage such as `C:\Sandbox\scdata` on the host to `C:\dev\scdata` in Sandbox, and keep `C:\dev\starcitizen` internal to the Sandbox.

## What this guide covers

- Setting up a clean Windows 11 power-user development environment
- Keeping tools, caches, exports, and work files organized under `D:\dev`, or a location of your choosing
- Installing Git, Visual Studio Build Tools, Rust, Python, .NET, CMake, Node.js, and VS Code
- Creating an AI-assisted multi-repo VS Code workspace
- Building StarBreaker and StarBreaker MCP locally
- Organizing versioned `Data.p4k` builds
- Exploring `Data.p4k` directly
- Resolving ship entities and loadouts
- Exporting a decomposed StarBreaker package
- Opening that package in Blender with the StarBreaker add-on
- Using the Aurora MR as a practical end-to-end example

## Community tools used

This workflow builds on work from several community projects:

- [StarBreaker](https://github.com/diogotr7/StarBreaker)
- [Blender-Tools](https://github.com/scorg-tools/Blender-Tools)
- [unp4k](https://github.com/dolkensp/unp4k)
- [Cryengine-Converter](https://github.com/markemp/Cryengine-Converter)
- [SCTextureConverter](https://github.com/Madfish71/SCTextureConverter)

Please support and credit the original tool authors.

## Table of contents

- [Recommended one-click installer](#recommended-one-click-installer)
- [Folder layout used in this guide](#folder-layout-used-in-this-guide)
- [Installer logs, setup-state, and reruns](#installer-logs-setup-state-and-reruns)
- [Troubleshooting quick fixes](#troubleshooting-quick-fixes)

1. [Install base tools](#1-install-base-tools)
2. [Install Rust](#2-install-rust)
3. [Install Python](#3-install-python)
4. [Create work folders](#4-create-work-folders)
5. [Install .NET SDKs](#5-install-net-sdks)
6. [Install CMake](#6-install-cmake)
7. [Clone repositories](#7-clone-repositories)
8. [Install VS Code and extensions](#8-install-visual-studio-code-and-extensions)
9. [Install Node.js](#9-install-nodejs)
10. [Install Codex CLI and VS Code AI tools](#10-install-codex-cli-and-vs-code-ai-tools)
11. [Create the VS Code workspace](#11-create-the-vs-code-workspace)
12. [Create safe development branches](#12-create-safe-development-branches)
13. [Verify the workspace terminal](#13-verify-the-workspace-terminal)
14. [Build StarBreaker and MCP](#14-build-starbreaker-and-mcp)
15. [Select a Star Citizen build](#15-select-a-star-citizen-build)
16. [Explore P4K paths](#16-explore-p4k-paths)
17. [Resolve and export an Aurora MR example](#17-resolve-and-export-an-aurora-mr-example)
18. [Install the StarBreaker Blender add-on](#18-install-the-starbreaker-blender-add-on)
19. [Open the decomposed package in Blender](#19-open-the-decomposed-package-in-blender)
20. [AI-assisted setup and future MCP support](#20-ai-assisted-setup-and-future-mcp-support)
41. [A little bit of history behind this tutorial](#41-a-little-bit-of-history-behind-this-tutorial)
42. [New to Star Citizen?](#42-new-to-star-citizen)

## Folder layout used in this guide

```text
D:\dev
├─ cmake
├─ dotnet
├─ gh
├─ installers
├─ node
│  ├─ npm-cache
│  └─ npm-global
├─ python
│  ├─ Python312
│  ├─ pip-cache
│  └─ venvs\scdev
├─ rust
│  ├─ .cargo
│  └─ .rustup
├─ scdata
│  ├─ exports
│  ├─ logs
│  ├─ p4k
│  │  └─ <SC_BUILD>\Data.p4k
│  └─ work
└─ starcitizen
   ├─ AGENTS.md
   ├─ CLAUDE.md
   ├─ Open-StarCitizen-Workspace.cmd
   ├─ prompts
   ├─ work
   ├─ output
   │  └─ reports
   ├─ _workspace
   │  └─ starcitizen-tools.code-workspace
   ├─ How-to-Guide-for-Extracting-and-Modding-Star-Citizen-Assets
   ├─ StarBreaker
   ├─ Blender-Tools
   ├─ unp4k
   ├─ Cryengine-Converter
   ├─ SCTextureConverter
   ├─ scdatatools
   └─ qtvscodestyle
```

Replace paths as needed if you use a different drive or folder layout.

`D:\dev\starcitizen\work` is for Codex/Claude/agent work logs, validation scratch, prompt/report support, and harness artifacts.

`D:\dev\scdata\work` is for Star Citizen data/export/P4K/Blender workflow artifacts.

## Installer logs, setup-state, and reruns

The installer is designed to be rerunnable. Completed steps are revalidated and skipped or reused where practical.

If setup crashes, is blocked by Windows Security, needs a relaunch, repairs WinGet/App Installer, or you intentionally skip a step, rerun the same installer CMD.

Useful support files:

- `<DevRoot>\scdata\logs\setup-*.log`
- `<DevRoot>\scdata\logs\command-*.log`
- `<DevRoot>\scdata\setup-state.json`
- `<DevRoot>\scdata\work\open_aurora_mr*.log`, if generated
- `<DevRoot>\scdata\work\*scene_blend*audit*.log`, if generated
- any Blender/Aurora audit logs generated under `<DevRoot>\scdata\work`
- `<DevRoot>\scdata\work\Open-Aurora-MR-in-Blender.cmd`, if generated by the installer
- `<DevRoot>\starcitizen\output\reports`
- `<DevRoot>\starcitizen\work`

When asking for help, include the latest setup log, any relevant command log, `setup-state.json`, Blender/Aurora helper logs when available, screenshots of Blender or Windows Security prompts, and the install root you selected.

## 1. Install base tools

> [!IMPORTANT]
> Before installing Git, Rust, Build Tools, Python, Node.js, or CMake, make sure **Windows Security > App & browser control > Smart App Control settings** is set to **Off**. If Smart App Control is On or in Evaluation mode, Windows may block developer tools or DLL files and setup may fail.

Open **PowerShell as Administrator**.

### Install Git

```powershell
winget install --id Git.Git -e --source winget
```

After install, confirm Git is on `PATH`:

```powershell
git --version
```

If `git` is not found, open **Edit the system environment variables** from the Start menu, then go to:

```text
Environment Variables -> System variables -> Path -> Edit
```

Add this entry if missing:

```text
C:\Program Files\Git\cmd
```

Close and reopen PowerShell.

### Install GitHub CLI to D:\dev\gh

Create dev and dev\gh folders
```powershell
mkdir D:\dev\ -Force
mkdir D:\dev\gh -Force
mkdir D:\dev\installers -Force
```

Download the latest GitHub CLI Windows amd64 ZIP
```powershell
$ghRelease = Invoke-RestMethod "https://api.github.com/repos/cli/cli/releases/latest"
$ghAsset = $ghRelease.assets | Where-Object { $_.name -like "gh_*_windows_amd64.zip" } | Select-Object -First 1
Invoke-WebRequest -Uri $ghAsset.browser_download_url -OutFile "D:\dev\installers\$($ghAsset.name)"
```

Extract it
```powershell
Expand-Archive -Path "D:\dev\installers\$($ghAsset.name)" -DestinationPath "D:\dev\installers\gh-extract" -Force
```

Copy it
```powershell
$ghExe = Get-ChildItem D:\dev\installers\gh-extract -Recurse -Filter gh.exe | Select-Object -First 1
$ghRoot = Split-Path (Split-Path $ghExe.FullName -Parent) -Parent
Remove-Item D:\dev\gh\* -Recurse -Force -ErrorAction SilentlyContinue
Copy-Item "$ghRoot\*" D:\dev\gh -Recurse -Force
```

Add GitHub CLI to your user Path by opening **Edit the system environment variables** from the Start menu, then go to:

```text
Environment Variables -> User variables -> Path -> Edit
```
Add this entry if missing:

```text
D:\dev\gh\bin
```

Restart PowerShell and verify

```powershell
where.exe gh
gh --version
```

GitHub CLI authentication is optional for normal read-only public repo cloning. It is useful if you want to push changes, work with private repos, or use GitHub-authenticated workflows.

If you want those authenticated workflows, run:

```powershell
gh auth login --hostname github.com --git-protocol https --web
```

For normal public network connectivity, you can simply check:

```powershell
Test-NetConnection github.com -Port 443
```

### Install Visual Studio Build Tools

```powershell
winget install --id Microsoft.VisualStudio.2022.BuildTools -e --source winget --override "--wait --passive --add Microsoft.VisualStudio.Workload.VCTools --includeRecommended"
```

Make sure the following components are installed:

- Desktop development with C++
- MSVC v143 VS 2022 C++ x64/x86 build tools
- Windows 11 SDK
- C++ CMake tools for Windows

If those were not installed, run the Visual Studio installer manually:

```powershell
& "C:\Program Files (x86)\Microsoft Visual Studio\Installer\setup.exe"
```

Choose **Modify** for Build Tools and add the missing components.

## 2. Install Rust

Use **Developer PowerShell for VS 2022** for Rust verification and builds.

Create Rust folders:

```powershell
mkdir D:\dev\rust -Force
mkdir D:\dev\rust\.cargo -Force
mkdir D:\dev\rust\.rustup -Force
```

Set Rust environment variables:

```powershell
setx CARGO_HOME "D:\dev\rust\.cargo"
setx RUSTUP_HOME "D:\dev\rust\.rustup"
```

Add Cargo to your user `Path` manually using Windows Environment Variables:

```text
D:\dev\rust\.cargo\bin
```

Restart **Developer PowerShell for VS 2022** and verify:

```powershell
echo $env:CARGO_HOME
echo $env:RUSTUP_HOME
```

Install Rust:

```powershell
winget install --id Rustlang.Rustup -e --source winget
```

Verify:

```powershell
where.exe rustup
where.exe cargo
where.exe rustc
rustup --version
cargo --version
rustc --version
```

### If Rust install fails

If the installer fails because of firewall, antivirus, or a blocked installer, remove partial installs:

```powershell
winget uninstall --id Rustlang.Rustup -e
winget list Rust
winget list Rustlang.Rustup
Remove-Item "$env:USERPROFILE\.cargo" -Recurse -Force -ErrorAction SilentlyContinue
Remove-Item "$env:USERPROFILE\.rustup" -Recurse -Force -ErrorAction SilentlyContinue
```

Fix the blocker, then retry the Rust install.

## 3. Install Python

Run:

```powershell
winget install --id Python.Python.3.12 -e --source winget --interactive
```

In the installer, choose **Customize installation** and enable:

- pip
- py launcher
- Add Python to environment variables

Use this install path:

```text
D:\dev\python\Python312
```

Create pip cache and venv folders:

```powershell
mkdir D:\dev\python\pip-cache -Force
mkdir D:\dev\python\venvs -Force
setx PIP_CACHE_DIR "D:\dev\python\pip-cache"
```

Restart Developer PowerShell and verify:

```powershell
where.exe python
where.exe py
where.exe pip
python --version
py --version
pip --version
```

If Windows aliases intercept Python, disable them here:

```text
Settings -> Apps -> Advanced app settings -> App execution aliases
```

Turn off:

```text
App Installer - python.exe
App Installer - python3.exe
```

Create a shared development virtual environment:

```powershell
D:\dev\python\Python312\python.exe -m venv D:\dev\python\venvs\scdev
```

Allow local activation scripts for your Windows user:

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Activate the venv:

```powershell
D:\dev\python\venvs\scdev\Scripts\Activate.ps1
```

Verify the prompt shows `(scdev)` and run:

```powershell
python --version
pip --version
where.exe python
where.exe pip
```

Upgrade pip tooling:

```powershell
python -m pip install --upgrade pip setuptools wheel
```

Check the environment:

```powershell
pip --version
python -m pip check
python -c "import sys; print(sys.executable)"
```

Deactivate when done:

```powershell
deactivate
```

## 4. Create work folders

```powershell
mkdir D:\dev\dotnet -Force
mkdir D:\dev\cmake -Force
mkdir D:\dev\starcitizen -Force
mkdir D:\dev\starcitizen\prompts -Force
mkdir D:\dev\starcitizen\work -Force
mkdir D:\dev\starcitizen\output -Force
mkdir D:\dev\starcitizen\output\reports -Force
mkdir D:\dev\starcitizen\_workspace -Force
mkdir D:\dev\scdata -Force
mkdir D:\dev\scdata\p4k -Force
mkdir D:\dev\scdata\exports -Force
mkdir D:\dev\scdata\work -Force
mkdir D:\dev\scdata\logs -Force
```

## 5. Install .NET SDKs

Download the installer script:

```powershell
Invoke-WebRequest -Uri "https://dot.net/v1/dotnet-install.ps1" -OutFile "D:\dev\installers\dotnet-install.ps1"
```

Install .NET 8:

```powershell
powershell -ExecutionPolicy Bypass -File D:\dev\installers\dotnet-install.ps1 -Channel 8.0 -InstallDir D:\dev\dotnet
```

Install .NET 9:

```powershell
powershell -ExecutionPolicy Bypass -File D:\dev\installers\dotnet-install.ps1 -Channel 9.0 -InstallDir D:\dev\dotnet
```

Set `DOTNET_ROOT`:

```powershell
setx DOTNET_ROOT "D:\dev\dotnet"
```

Add this path manually in Windows Environment Variables:

```text
D:\dev\dotnet
```

Restart Developer PowerShell and check:

```powershell
where.exe dotnet
dotnet --info
Test-Path D:\dev\dotnet\dotnet.exe
Get-ChildItem D:\dev\dotnet
D:\dev\dotnet\dotnet.exe --info
```

If `C:\Program Files\dotnet\dotnet.exe` is taking priority, move `D:\dev\dotnet` above `C:\Program Files\dotnet` in the system `Path`.

## 6. Install CMake

```powershell
Invoke-WebRequest -Uri "https://github.com/Kitware/CMake/releases/download/v4.3.1/cmake-4.3.1-windows-x86_64.zip" -OutFile "D:\dev\installers\cmake-4.3.1-windows-x86_64.zip"
Expand-Archive -Path "D:\dev\installers\cmake-4.3.1-windows-x86_64.zip" -DestinationPath "D:\dev\installers\cmake-extract" -Force
Copy-Item "D:\dev\installers\cmake-extract\cmake-4.3.1-windows-x86_64\*" "D:\dev\cmake" -Recurse -Force
```

Verify:

```powershell
Test-Path D:\dev\cmake\bin\cmake.exe
```

Add this to system `Path`:

```text
D:\dev\cmake\bin
```

Check:

```powershell
where.exe cmake
cmake --version
```

Developer PowerShell may place Visual Studio's bundled CMake first. If you need the `D:\dev` CMake for a session, run:

```powershell
$env:Path = "D:\dev\cmake\bin;$env:Path"
where.exe cmake
```

## 7. Clone repositories

Regular PowerShell is fine for this step.

```powershell
mkdir D:\dev\starcitizen
cd D:\dev\starcitizen

git clone https://github.com/DirectorGunner/How-to-Guide-for-Extracting-and-Modding-Star-Citizen-Assets.git
git clone https://github.com/diogotr7/StarBreaker.git
git clone https://github.com/scorg-tools/Blender-Tools.git
git clone https://github.com/dolkensp/unp4k.git
git clone https://github.com/markemp/Cryengine-Converter.git
git clone https://github.com/Madfish71/SCTextureConverter.git
```

## 8. Install Visual Studio Code and extensions

Install VS Code normally. Then add its `bin` folder to `Path`. Example:

```text
C:\Microsoft VS Code\bin
```

Restart Developer PowerShell and verify:

```powershell
where.exe code
code --version
code --list-extensions
```

Install recommended extensions:

```powershell
code --install-extension ms-python.python --force
code --install-extension ms-python.vscode-pylance --force
code --install-extension rust-lang.rust-analyzer --force
code --install-extension tamasfe.even-better-toml --force
code --install-extension ms-dotnettools.csdevkit --force
code --install-extension GitHub.vscode-pull-request-github --force
code --install-extension jacqueslucke.blender-development --force
```

Optional helpful extensions:

```powershell
code --install-extension eamodio.gitlens --force
code --install-extension yzhang.markdown-all-in-one --force
code --install-extension DavidAnson.vscode-markdownlint --force
code --install-extension bierner.markdown-mermaid --force
code --install-extension redhat.vscode-yaml --force
code --install-extension redhat.vscode-xml --force
code --install-extension ms-azuretools.vscode-docker --force
code --install-extension ms-vscode.powershell --force
code --install-extension EditorConfig.EditorConfig --force
code --install-extension streetsidesoftware.code-spell-checker --force
code --install-extension openai.chatgpt --force
```

Verify:

```powershell
code --list-extensions
```

## 9. Install Node.js

```powershell
mkdir D:\dev\node -Force
mkdir D:\dev\node\npm-cache -Force
mkdir D:\dev\node\npm-global -Force
```

Download and extract Node.js:

```powershell
Invoke-WebRequest -Uri "https://nodejs.org/dist/v22.21.1/node-v22.21.1-win-x64.zip" -OutFile "D:\dev\installers\node-v22.21.1-win-x64.zip"
Expand-Archive -Path "D:\dev\installers\node-v22.21.1-win-x64.zip" -DestinationPath "D:\dev\installers\node-extract" -Force
Copy-Item "D:\dev\installers\node-extract\node-v22.21.1-win-x64\*" "D:\dev\node" -Recurse -Force
```

Verify:

```powershell
D:\dev\node\node.exe --version
D:\dev\node\npm.cmd --version
```

Add these to your user `Path`:

```text
D:\dev\node
D:\dev\node\npm-global
```

Restart PowerShell and verify:

```powershell
where.exe node
where.exe npm
where.exe npx
node --version
npm --version
npx --version
```

Configure npm:

```powershell
npm config set cache "D:\dev\node\npm-cache" --location=user
npm config set prefix "D:\dev\node\npm-global" --location=user
```

Verify:

```powershell
npm config get cache
npm config get prefix
npm --version
npm config list
```

## 10. Install Codex CLI and VS Code AI tools

Install Codex CLI globally:

```powershell
npm install -g @openai/codex
```

Verify:

```powershell
where.exe codex
codex --version
```

Open VS Code, sign in to GitHub, then install and sign into your preferred AI tools, such as Codex or Claude Code.

## 11. Create the VS Code workspace

```powershell
mkdir D:\dev\starcitizen\_workspace -Force
notepad D:\dev\starcitizen\_workspace\starcitizen-tools.code-workspace
```

Paste this workspace JSON, adjusting paths if needed:

```json
{
  "folders": [
    { "name": "Star Citizen Workspace Control", "path": "D:/dev/starcitizen" },
    { "name": "Prompt Archive", "path": "D:/dev/starcitizen/prompts" },
    { "name": "Agent Work Logs", "path": "D:/dev/starcitizen/work" },
    { "name": "Output Reports", "path": "D:/dev/starcitizen/output/reports" },
    { "name": "StarBreaker", "path": "D:/dev/starcitizen/StarBreaker" },
    { "name": "Blender-Tools", "path": "D:/dev/starcitizen/Blender-Tools" },
    { "name": "unp4k", "path": "D:/dev/starcitizen/unp4k" },
    { "name": "Cryengine-Converter", "path": "D:/dev/starcitizen/Cryengine-Converter" },
    { "name": "SCTextureConverter", "path": "D:/dev/starcitizen/SCTextureConverter" },
    { "name": "Zero to Hero Guide", "path": "D:/dev/starcitizen/How-to-Guide-for-Extracting-and-Modding-Star-Citizen-Assets" },
    { "name": "scdatatools", "path": "D:/dev/starcitizen/scdatatools" },
    { "name": "qtvscodestyle", "path": "D:/dev/starcitizen/qtvscodestyle" },
    { "name": "scdata", "path": "D:/dev/scdata" }
  ],
  "settings": {
    "terminal.integrated.defaultProfile.windows": "Developer PowerShell for VS 2022",
    "terminal.integrated.profiles.windows": {
      "Developer PowerShell for VS 2022": {
        "source": "PowerShell",
        "args": [
          "-NoExit",
          "-ExecutionPolicy",
          "Bypass",
          "-Command",
          "& 'C:/Program Files (x86)/Microsoft Visual Studio/2022/BuildTools/Common7/Tools/Launch-VsDevShell.ps1' -Arch amd64"
        ]
      },
      "PowerShell": {
        "source": "PowerShell"
      }
    },
    "terminal.integrated.env.windows": {
      "SC_DEV_ROOT": "D:/dev",
      "SC_STAR_CITIZEN_ROOT": "D:/dev/starcitizen",
      "SC_DATA_ROOT": "D:/dev/scdata",
      "SC_P4K_ROOT": "D:/dev/scdata/p4k",
      "SC_EXPORT_ROOT": "D:/dev/scdata/exports",
      "SC_WORK_ROOT": "D:/dev/scdata/work",
      "SC_PROMPTS_ROOT": "D:/dev/starcitizen/prompts",
      "SC_AGENT_WORK_ROOT": "D:/dev/starcitizen/work",
      "SC_REPORTS_ROOT": "D:/dev/starcitizen/output/reports",
      "SC_WORKSPACE_PATH": "D:/dev/starcitizen/_workspace/starcitizen-tools.code-workspace",
      "SC_GUIDE_REPO": "D:/dev/starcitizen/How-to-Guide-for-Extracting-and-Modding-Star-Citizen-Assets"
    },
    "python.defaultInterpreterPath": "D:/dev/python/venvs/scdev/Scripts/python.exe",
    "files.exclude": {
      "**/target": true,
      "**/bin": true,
      "**/obj": true,
      "**/__pycache__": true
    }
  }
}
```

Open the workspace:

```powershell
code D:\dev\starcitizen\_workspace\starcitizen-tools.code-workspace
```

The installer also creates:

```text
D:\dev\starcitizen\Open-StarCitizen-Workspace.cmd
```

You can run that launcher to open the generated VS Code workspace.

## 12. Create safe development branches

Create development branches for the cloned GitHub repositories:

```powershell
cd D:\dev\starcitizen\StarBreaker
git status
git checkout -b dev-mcp-blender-workflow

cd D:\dev\starcitizen\Blender-Tools
git status
git checkout -b dev-direct-p4k-workflow

cd D:\dev\starcitizen\unp4k
git status
git checkout -b dev-direct-p4k-workflow

cd D:\dev\starcitizen\Cryengine-Converter
git status
git checkout -b dev-sc-asset-pipeline

cd D:\dev\starcitizen\SCTextureConverter
git status
git checkout -b dev-sc-texture-pipeline

cd D:\dev\starcitizen\How-to-Guide-for-Extracting-and-Modding-Star-Citizen-Assets
git status
git checkout -b dev-guide-improvements
```

If you have private/offline StarFab-related source folders, copy them to:

```text
D:\dev\starcitizen\scdatatools
D:\dev\starcitizen\qtvscodestyle
```

Initialize them as local-only Git repos with no remote.

For `scdatatools`:

```powershell
cd D:\dev\starcitizen\scdatatools
git init
git config user.name "Local Developer"
git config user.email "local@example.invalid"
git checkout -b local-private-baseline
notepad .gitignore
```

Paste this into `.gitignore` before `git add .`:

```gitignore
__pycache__/
*.pyc
*.pyo
*.pyd
.venv/
venv/
.env
*.log
.DS_Store
Thumbs.db
.vscode/
.idea/
```

Then continue:

```powershell
git add .
git commit -m "Local private baseline import"
git checkout -b dev-private-review
git remote -v
```

For `qtvscodestyle`:

```powershell
cd D:\dev\starcitizen\qtvscodestyle
git init
git config user.name "Local Developer"
git config user.email "local@example.invalid"
git checkout -b local-private-baseline
notepad .gitignore
```

Paste this into `.gitignore` before `git add .`:

```gitignore
__pycache__/
*.pyc
*.pyo
*.pyd
.venv/
venv/
.env
*.log
.DS_Store
Thumbs.db
.vscode/
.idea/
```

Then continue:

```powershell
git add .
git commit -m "Local private baseline import"
git checkout -b dev-private-review
git remote -v
```

`git remote -v` should print nothing for these private/local-only folders.

Verify branches:

```powershell
cd D:\dev\starcitizen\StarBreaker; git status; git branch --show-current
cd D:\dev\starcitizen\Blender-Tools; git status; git branch --show-current
cd D:\dev\starcitizen\unp4k; git status; git branch --show-current
cd D:\dev\starcitizen\Cryengine-Converter; git status; git branch --show-current
cd D:\dev\starcitizen\SCTextureConverter; git status; git branch --show-current
cd D:\dev\starcitizen\How-to-Guide-for-Extracting-and-Modding-Star-Citizen-Assets; git status; git branch --show-current
cd D:\dev\starcitizen\scdatatools; git status; git branch --show-current
cd D:\dev\starcitizen\qtvscodestyle; git status; git branch --show-current
```

Expected working branches:

```text
StarBreaker            dev-mcp-blender-workflow
Blender-Tools          dev-direct-p4k-workflow
unp4k                  dev-direct-p4k-workflow
Cryengine-Converter    dev-sc-asset-pipeline
SCTextureConverter     dev-sc-texture-pipeline
How-to-Guide-for-Extracting-and-Modding-Star-Citizen-Assets
                       dev-guide-improvements
scdatatools            dev-private-review
qtvscodestyle          dev-private-review
```

## 13. Verify the workspace terminal

Reopen the workspace:

```powershell
code D:\dev\starcitizen\_workspace\starcitizen-tools.code-workspace
```

In the VS Code terminal, verify:

```powershell
echo $env:SC_DEV_ROOT
echo $env:SC_STAR_CITIZEN_ROOT
echo $env:SC_DATA_ROOT
echo $env:SC_P4K_ROOT
echo $env:SC_EXPORT_ROOT
echo $env:SC_WORK_ROOT
echo $env:SC_PROMPTS_ROOT
echo $env:SC_AGENT_WORK_ROOT
echo $env:SC_REPORTS_ROOT
echo $env:SC_WORKSPACE_PATH
echo $env:SC_GUIDE_REPO
cl
where.exe cl
where.exe link
rustc --version
cargo --version
```

## 14. Build StarBreaker and MCP

In the VS Code terminal:

```powershell
cd D:\dev\starcitizen\StarBreaker
git branch --show-current
git status --short
cargo build --release -p starbreaker
```

Test:

```powershell
.\target\release\starbreaker.exe --help
```

Build the MCP binary:

```powershell
cargo build --release -p starbreaker-mcp
```

List outputs:

```powershell
Get-ChildItem .\target\release -Filter "*.exe" | Select-Object Name, FullName
```

Test MCP:

```powershell
.\target\release\starbreaker-mcp.exe --help
```

## 15. Select a Star Citizen build

Copy your `Data.p4k` into a versioned folder, for example:

```text
D:\dev\scdata\p4k\<SC_BUILD>\Data.p4k
```

Example build label:

```text
4.8-LIVE-xxxxxxx
```

Set it for the current terminal session:

```powershell
$env:SC_BUILD = "<SC_BUILD>"
# Example only:
# $env:SC_BUILD = "4.8-LIVE-xxxxxxx"
$env:SC_DATA_P4K = Join-Path $env:SC_P4K_ROOT "$env:SC_BUILD\Data.p4k"
echo $env:SC_DATA_P4K
Test-Path $env:SC_DATA_P4K
```

`Test-Path` should return `True`.

## 16. Explore P4K paths

From `D:\dev\starcitizen\StarBreaker`, list top-level Spaceships folders:

```powershell
.\target\release\starbreaker.exe p4k list --filter 'Data/Objects/Spaceships/**' | ForEach-Object { ($_ -split '\s+')[0] } | ForEach-Object { if ($_ -match '^Data[\\/]+Objects[\\/]+Spaceships[\\/]+([^\\/]+)') { $matches[1] } } | Sort-Object -Unique
```

List manufacturer folders under `Ships`:

```powershell
.\target\release\starbreaker.exe p4k list --filter 'Data/Objects/Spaceships/Ships/**' | ForEach-Object { ($_ -split '\s+')[0] } | ForEach-Object { if ($_ -match '^Data[\\/]+Objects[\\/]+Spaceships[\\/]+Ships[\\/]+([^\\/]+)') { $matches[1] } } | Sort-Object -Unique
```

List RSI ship folders:

```powershell
.\target\release\starbreaker.exe p4k list --filter 'Data/Objects/Spaceships/Ships/RSI/**' | ForEach-Object { ($_ -split '\s+')[0] } | ForEach-Object { if ($_ -match '^Data[\\/]+Objects[\\/]+Spaceships[\\/]+Ships[\\/]+RSI[\\/]+([^\\/]+)') { $matches[1] } } | Sort-Object -Unique
```

Search for Aurora paths:

```powershell
.\target\release\starbreaker.exe p4k list --filter 'Data/Objects/Spaceships/Ships/RSI/**' | Select-String -Pattern 'Aurora' -CaseSensitive:$false
```

Because the list may be long, save it:

```powershell
.\target\release\starbreaker.exe p4k list --filter 'Data/Objects/Spaceships/Ships/RSI/**' | Select-String -Pattern 'Aurora' -CaseSensitive:$false | Out-File -Encoding utf8 "D:\dev\scdata\work\aurora_rsi_ship_paths_$env:SC_BUILD.txt"
notepad "D:\dev\scdata\work\aurora_rsi_ship_paths_$env:SC_BUILD.txt"
```

## 17. Resolve and export an Aurora MR example

Resolve the generic Aurora entity:

```powershell
.\target\release\starbreaker.exe entity loadout RSI_Aurora --p4k "$env:SC_DATA_P4K" *> "D:\dev\scdata\work\loadout_RSI_Aurora_$env:SC_BUILD.txt"
```

Resolve the MR variant:

```powershell
.\target\release\starbreaker.exe entity loadout RSI_Aurora_MR --p4k "$env:SC_DATA_P4K" *> "D:\dev\scdata\work\loadout_RSI_Aurora_MR_$env:SC_BUILD.txt"
```

Export the Aurora MR as a decomposed package:

```powershell
.\target\release\starbreaker.exe entity export RSI_Aurora_MR_PU_AI_CIV D:\dev\scdata\exports\aurora_mr_decomposed --p4k "$env:SC_DATA_P4K" --kind decomposed --materials textures --lod 1 --mip 2 *> "D:\dev\scdata\work\export_RSI_Aurora_MR_decomposed_$env:SC_BUILD.txt"
```

The installer may resolve or export the full `RSI_Aurora_MR_PU_AI_CIV` target, and generated package names may look like `RSI Aurora MR PU AI CIV_LOD1_TEX2`. If you use `RSI_Aurora_MR` as shorthand, confirm the loadout/export logs so you know which entity was actually exported.

Create a file-tree log:

```powershell
Get-ChildItem "D:\dev\scdata\exports\aurora_mr_decomposed" -Recurse | Select-Object FullName, Length | Out-File -Encoding utf8 "D:\dev\scdata\work\export_RSI_Aurora_MR_decomposed_filetree_$env:SC_BUILD.txt"
```

Logs are saved in:

```text
D:\dev\scdata\work
```

The decomposed package is saved in:

```text
D:\dev\scdata\exports\aurora_mr_decomposed
```

## 18. Install the StarBreaker Blender add-on

Close Blender before running this command.

```powershell
$src='D:\dev\starcitizen\StarBreaker\blender_addon\starbreaker_addon'; $dst="$env:APPDATA\Blender Foundation\Blender\5.1\scripts\addons\starbreaker_addon"; New-Item -ItemType Directory -Force -Path (Split-Path $dst) | Out-Null; if (Test-Path $dst) { Write-Host "Destination already exists: $dst"; Write-Host "Do not overwrite yet. Check what is there first." } else { New-Item -ItemType Junction -Path $dst -Target $src }
```

Open Blender, then go to:

```text
Edit -> Preferences -> Add-ons
```

Search for **StarBreaker** and enable it.

## 19. Open the decomposed package in Blender

For the normal visual Blender workflow:

1. Export the Aurora MR decomposed package.
2. Open the generated `scene.blend` directly.

Path pattern:

```text
<DevRoot>\scdata\exports\aurora_mr_decomposed\Packages\<package name>\scene.blend
```

Example:

```text
D:\dev\scdata\exports\aurora_mr_decomposed\Packages\RSI Aurora MR PU AI CIV_LOD1_TEX2\scene.blend
```

`scene.blend` is the StarBreaker Blender scene file. It links the exported mesh `.blend` libraries and is the correct file to open for visual review. `scene.json` remains important metadata used by StarBreaker and the add-on for package structure, animation entries, and sidecar files, but it is not the normal visual-open target.

If the installer generated this launcher, you can use it instead of browsing to the file manually:

```text
D:\dev\scdata\work\Open-Aurora-MR-in-Blender.cmd
```

In Blender:

1. Click inside the 3D Viewport.
2. Press **N** to open the right-side sidebar.
3. Choose the **StarBreaker** tab.
4. If the StarBreaker controls are missing, select the top StarBreaker package root object in the Outliner.
5. Scroll inside the StarBreaker tab to find **Animations**.

Windows Sandbox can have input delay or scrolling issues, so Blender UI behavior there may feel laggy even when the add-on is working.

### Seeing textures and materials in Blender

Solid viewport mode can make the model look gray or white. Use **Material Preview** or **Rendered** mode to see textures/materials where exported and supported.

The installer attempts to set **Rendered** view and **POM Detail** to **High** where possible. The StarBreaker panel also has **POM Detail** and **Refresh Materials** controls.

If textures look missing:

1. Select the package root in the Outliner.
2. Press **N** in the 3D Viewport.
3. Open the **StarBreaker** tab.
4. Set **POM Detail** to **High**.
5. Click **Refresh Materials**.
6. Switch the viewport to **Rendered** or **Material Preview**.

### Finding StarBreaker animation controls

StarBreaker animation controls are in the **StarBreaker** sidebar tab, not necessarily Blender's generic Animation workspace/tab.

1. Select the StarBreaker package root or entity root.
2. Press **N** in the 3D Viewport.
3. Open the **StarBreaker** tab.
4. Scroll to the **Animations** section.

The controls may appear as rows of buttons for animation states. If controls disappear, reselect the package root. Not every ship or game build exposes every animation control.

In Windows Sandbox, scrolling or input delay can make the panel harder to use.

Advanced legacy diagnostic path only: if a developer specifically asks you to test the `scene.json` importer, use the StarBreaker package import control. This may not match the normal direct `scene.blend` workflow. For normal visual review, open `scene.blend`; `scene.json` is metadata, animation, and package data.

```text
3D Viewport -> press N -> StarBreaker tab -> Import StarBreaker Package
```

Select the metadata file only for that diagnostic import:

```text
<DevRoot>\scdata\exports\aurora_mr_decomposed\Packages\<package name>\scene.json
```

Example:

```text
D:\dev\scdata\exports\aurora_mr_decomposed\Packages\RSI Aurora MR PU AI CIV_LOD1_TEX2\scene.json
```

After a legacy diagnostic import, select the Aurora package root in the Outliner and use the StarBreaker sidebar only as a developer diagnostic. Animation controls and results can differ from the direct `scene.blend` workflow.

## Troubleshooting quick fixes

- **Smart App Control blocks Git, Rust, or DLLs**: set Smart App Control to **Off** in Windows Security, then rerun the installer. Common clues include `msys-2.0.dll`, `libintl-8.dll`, `libpcre2-8-0.dll`, `rustup-init.exe`, `Bad Image`, or `0xc0e90002`.
- **Installer closes after WinGet/App Installer repair**: reopen the same `Launch-SC-Zero-to-Hero-Setup.cmd`. The repaired App Installer/WinGet state is rechecked on the next run.
- **Build Tools were skipped**: this is not fatal. Existing StarBreaker binaries can still be reused if they validate; otherwise build-dependent steps will skip until Build Tools are installed.
- **Git is installed but clone/versioning fails**: reopen the terminal, check `git --version`, and review whether Windows Security blocked Git for Windows components.
- **Python opens Microsoft Store**: disable the `python.exe` and `python3.exe` App Installer aliases under **Settings > Apps > Advanced app settings > App execution aliases**.
- **VS Code `code` command not found**: add the VS Code `bin` folder to `Path`, reopen PowerShell, then run `where.exe code`.
- **Blender opens but I do not see the StarBreaker panel**: enable the add-on in **Edit > Preferences > Add-ons**, search for **StarBreaker**, click inside the 3D Viewport, press **N**, then choose the **StarBreaker** tab.
- **Blender opens but I do not see animation buttons**: select the package root in the Outliner, open the **StarBreaker** tab, and scroll down to **Animations**. Sandbox scrolling or input delay may make this harder.
- **Blender model looks gray or white**: switch to **Material Preview** or **Rendered**, set **POM Detail** to **High**, and click **Refresh Materials**.
- **Blender opens `scene.json` or import fails**: for the normal visual workflow, open `scene.blend`, not `scene.json`. `scene.json` is metadata/animation/package data.
- **Installer reports Aurora/Blender WARN or FAILED**: attach setup logs, `setup-state.json`, `<DevRoot>\scdata\work\open_aurora_mr*.log` if generated, `<DevRoot>\scdata\work\*scene_blend*audit*.log` if generated, any Blender/Aurora audit logs from `scdata\work`, and the generated `Open-Aurora-MR-in-Blender.cmd` if present. Confirm `scene.blend` exists under the Aurora package folder.
- **Windows Sandbox Git dubious ownership**: do not map the whole DevRoot into Sandbox. Map only `scdata` for P4K capacity; mapping all of `C:\dev` can make Git think repos are owned by another SID.
- **Rerun after crash or partial setup**: run the same installer again. It revalidates completed steps and keeps useful details in `setup-state.json` and logs.

## 20. AI-assisted setup and future MCP support

The one-click installer now automates much of this setup. AI assistants can still help with review, troubleshooting, repo work, and future workflow development, but review every command before running it. AI assistants make mistakes, and setup scripts can change your system quickly.

For best results, ask your AI assistant to explain each command, check paths before running anything, and avoid destructive commands unless you fully understand what they do.

StarBreaker already has an MCP component for game-data/query workflows. Blender Lab also has an official Blender MCP Server direction here:

https://www.blender.org/lab/mcp-server/

Future versions of this project may add optional AI Blender control using MCP. The current one-click installer does **not** install Blender MCP by default, and AI control of Blender should be opt-in because it can let an AI modify the open Blender scene.

## 41. A little bit of history behind this tutorial

I have been helping Star Citizen backers understand asset extraction, modding workflows, cosplay references, and community tools since around 2015.

This guide is an evolution of [years of trial, error, broken tools, rebuilt workflows, community discoveries, and countless questions from backers](https://robertsspaceindustries.com/spectrum/community/SC/forum/50172/thread/how-to-start-modding-existing-star-citizen-assets/28079) who wanted to do something creative with Star Citizen assets but did not know where to begin.

Older workflows often required a lot of scattered knowledge: finding the right extractor, dealing with hit-or-miss CryEngine (now Star Engine) asset conversions, fixing textures, importing into Blender, understanding what broke after a patch, and figuring out which community tool still worked. For many people, that was enough friction to stop them before they ever got to the fun part.

The goal of this updated guide is to lower that wall.

This new workflow is built around a simple idea: put the related community repos, tools, exports, logs, and working folders into one organized Windows development environment so both humans and AI assistants can reason about the whole pipeline. Instead of treating every tool as a disconnected mystery box, the workspace becomes something you can inspect, build, troubleshoot, and improve.

I am proud of the work the community has done over the years, and I hope this guide helps the next wave of creative backers not only extract and render assets, but also contribute fixes, documentation, and improvements back to the tools we all rely on.

## 42. New to Star Citizen?

If you are not familiar with Star Citizen and want to try it, I maintain a beginner-friendly enlistment site here:

[EnlistCitizen.com](https://enlistcitizen.com/)

You can also use my Star Citizen referral code link when creating a new RSI account:

[Enlist with referral code STAR-GN2F-6JLW](https://robertsspaceindustries.com/enlist?referral=STAR-GN2F-6JLW)

Using a Star Citizen referral code is optional, but new accounts currently receive a referral UEC bonus when signing up with one. As of the latest community referral program information, that bonus is **50,000 UEC**.

If you are looking for people to play Star Citizen with, I am also a moderator in TEST Squadron, and I absolutely recommend it as the best player organization for group play. For new and returning players, having an active group makes a huge difference, and TEST is one of the best places to find backers online at any time for every kind of gameplay loop.

You can join the TEST Squadron Discord here:

[Discord.gg/TEST](https://discord.gg/TEST)
