# Zero to Hero: Star Citizen Asset Extraction and Modding Workflow

A modern Windows power-user workflow for StarBreaker, Blender, `Data.p4k` exploration, and AI-assisted community tool development.

> Community tutorial by [DirectorGunner](https://robertsspaceindustries.com/en/citizens/DirectorGunner).

## Overview

Times have changed. Welcome to a new era of Star Citizen asset exploration, where modern community tools and AI-assisted workflows can massively reduce the barrier to entry.

This guide is aimed at power users, modders, artists, and technically curious backers who are comfortable following command-line instructions. That said, if you use an AI assistant carefully and ask it to explain each step, you can work through this setup even with little to no prior command-line experience.

The goal of this repo is to maintain an all-in-one workflow that brings together community projects like StarBreaker, Blender, CryEngine conversion tools, texture tools, `Data.p4k` organization, VS Code, and AI-assisted development into one practical pipeline that anyone with patience can use.

> [!NOTE]
> This guide was refreshed on 05/09/2026. Star Citizen is an active alpha, and community tools may break or change as CIG updates the game data format. Treat this guide as a living document.

> [!IMPORTANT]
> This guide is intended for personal learning, fan art, research, and community tooling. Treat your local `Data.p4k` files as read-only, do not redistribute extracted game assets, and respect CIG’s terms and community rules.

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
- Importing that package into Blender with the StarBreaker add-on
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
19. [Import the decomposed package into Blender](#19-import-the-decomposed-package-into-blender)
41. [A little bit of history behind this tutorial](#41-a-little-bit-of-history-behind-this-tutorial)
42. [New to Star Citizen?](#42-new-to-star-citizen)

## Folder layout used in this guide

```text
D:\dev
├─ cmake
├─ dotnet
├─ installers
├─ node
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
│  │  └─ 4.4.1-LIVE-9457020\Data.p4k
│  └─ work
└─ starcitizen
   ├─ StarBreaker
   ├─ Blender-Tools
   ├─ unp4k
   ├─ Cryengine-Converter
   ├─ SCTextureConverter
   └─ _workspace
```

Replace paths as needed if you use a different drive or folder layout.

## 1. Install base tools

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
Environment Variables → System variables → Path → Edit
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

Add GitHub CLI to User path by open **Edit the system environment variables** from the Start menu, then go to:

```text
Environment Variables → System variables → Path → Edit
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

If no issues, authenticate and check

```powershell
gh auth login --hostname github.com --git-protocol https --web
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
Settings → Apps → Advanced app settings → App execution aliases
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

Developer PowerShell may place Visual Studio’s bundled CMake first. If you need the `D:\dev` CMake for a session, run:

```powershell
$env:Path = "D:\dev\cmake\bin;$env:Path"
where.exe cmake
```

## 7. Clone repositories

Regular PowerShell is fine for this step.

```powershell
mkdir D:\dev\starcitizen
cd D:\dev\starcitizen

git clone https://github.com/diogotr7/StarBreaker.git
git clone https://github.com/scorg-tools/Blender-Tools.git
git clone https://github.com/dolkensp/unp4k.git
git clone https://github.com/markemp/Cryengine-Converter.git
git clone https://github.com/Madfish71/SCTextureConverter
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
    { "name": "StarBreaker", "path": "D:/dev/starcitizen/StarBreaker" },
    { "name": "Blender-Tools", "path": "D:/dev/starcitizen/Blender-Tools" },
    { "name": "unp4k", "path": "D:/dev/starcitizen/unp4k" },
    { "name": "Cryengine-Converter", "path": "D:/dev/starcitizen/Cryengine-Converter" },
    { "name": "SCTextureConverter", "path": "D:/dev/starcitizen/SCTextureConverter" },
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
      "SC_DATA_ROOT": "D:/dev/scdata",
      "SC_P4K_ROOT": "D:/dev/scdata/p4k",
      "SC_EXPORT_ROOT": "D:/dev/scdata/exports",
      "SC_WORK_ROOT": "D:/dev/scdata/work"
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
"__pycache__/", "*.pyc", "*.pyo", "*.pyd", ".venv/", "venv/", ".env", "*.log", ".DS_Store", "Thumbs.db", ".vscode/", ".idea/" | Set-Content -Encoding utf8 .gitignore
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
"__pycache__/", "*.pyc", "*.pyo", "*.pyd", ".venv/", "venv/", ".env", "*.log", ".DS_Store", "Thumbs.db", ".vscode/", ".idea/" | Set-Content -Encoding utf8 .gitignore
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
echo $env:SC_P4K_ROOT
echo $env:SC_EXPORT_ROOT
echo $env:SC_WORK_ROOT
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
D:\dev\scdata\p4k\4.4.1-LIVE-9457020\Data.p4k
```

Set it for the current terminal session:

```powershell
$env:SC_BUILD = "4.4.1-LIVE-9457020"
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
.\target\release\starbreaker.exe p4k list --filter 'Data/Objects/Spaceships/Ships/RSI/**' | Select-String -Pattern 'Aurora' -CaseSensitive:$false | Out-File -Encoding utf8 "D:\dev\scdata\work\aurora_rsi_ship_paths_4.4.1-LIVE-9457020.txt"
notepad "D:\dev\scdata\work\aurora_rsi_ship_paths_4.4.1-LIVE-9457020.txt"
```

## 17. Resolve and export an Aurora MR example

Resolve the generic Aurora entity:

```powershell
.\target\release\starbreaker.exe entity loadout RSI_Aurora --p4k "$env:SC_DATA_P4K" *> "D:\dev\scdata\work\loadout_RSI_Aurora_4.4.1-LIVE-9457020.txt"
```

Resolve the MR variant:

```powershell
.\target\release\starbreaker.exe entity loadout RSI_Aurora_MR --p4k "$env:SC_DATA_P4K" *> "D:\dev\scdata\work\loadout_RSI_Aurora_MR_4.4.1-LIVE-9457020.txt"
```

Export the Aurora MR as a decomposed package:

```powershell
.\target\release\starbreaker.exe entity export RSI_Aurora_MR D:\dev\scdata\exports\aurora_mr_decomposed --p4k "$env:SC_DATA_P4K" --kind decomposed --materials textures --lod 1 --mip 2 *> "D:\dev\scdata\work\export_RSI_Aurora_MR_decomposed_4.4.1-LIVE-9457020.txt"
```

Create a file-tree log:

```powershell
Get-ChildItem "D:\dev\scdata\exports\aurora_mr_decomposed" -Recurse | Select-Object FullName, Length | Out-File -Encoding utf8 "D:\dev\scdata\work\export_RSI_Aurora_MR_decomposed_filetree_4.4.1-LIVE-9457020.txt"
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
Edit → Preferences → Add-ons
```

Search for **StarBreaker** and enable it.

## 19. Import the decomposed package into Blender

In Blender:

```text
3D Viewport → press N → StarBreaker tab → Import StarBreaker Package
```

Select:

```text
D:\dev\scdata\exports\aurora_mr_decomposed\Packages\RSI Aurora MR_LOD1_TEX2\scene.json
```

After import:

1. Disable viewport overlays to reduce black helper-line clutter.
2. In the Outliner, select the Aurora package root.
3. In the StarBreaker sidebar animation menu, find **Landing Gear Retract**.
4. Click **Last**.

The landing gear should retract if the matching animation data was exported and applied successfully.

## 20. More to be added at a later date

## AI-assisted setup

A script could eventually automate much of this setup. You can use a current LLM to help generate one from this guide, but review every command before running it. AI assistants make mistakes, and setup scripts can change your system quickly.

For best results, ask your AI assistant to explain each command, check paths before running anything, and avoid destructive commands unless you fully understand what they do.

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
