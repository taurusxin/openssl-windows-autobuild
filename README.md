# openssl-windows-autobuild

[![Build OpenSSL for Windows](https://img.shields.io/github/actions/workflow/status/taurusxin/openssl-windows-autobuild/build-openssl-windows.yml?branch=main&style=flat-square&label=build)](https://github.com/taurusxin/openssl-windows-autobuild/actions/workflows/build-openssl-windows.yml)
[![GitHub release](https://img.shields.io/github/v/release/taurusxin/openssl-windows-autobuild?include_prereleases&sort=semver&style=flat-square)](https://github.com/taurusxin/openssl-windows-autobuild/releases)
[![Last commit](https://img.shields.io/github/last-commit/taurusxin/openssl-windows-autobuild?style=flat-square)](https://github.com/taurusxin/openssl-windows-autobuild/commits/main)
[![Platform](https://img.shields.io/badge/platform-Windows-0078D4?style=flat-square)](https://github.com/taurusxin/openssl-windows-autobuild)
[![Upstream OpenSSL](https://img.shields.io/github/v/release/openssl/openssl?include_prereleases&sort=semver&style=flat-square&label=upstream&color=721412)](https://github.com/openssl/openssl/releases)

English | [中文](README.zh-CN.md)

Automated Windows builds for OpenSSL using local PowerShell scripts and GitHub Actions.

1. Build OpenSSL locally with a single command.
2. Check the latest upstream OpenSSL release every week with GitHub Actions.
3. Build only when a matching release or tag does not already exist.
4. Publish x64/x86 shared and static ZIP packages to GitHub Releases.

## Local Requirements

Local builds require Windows, a Visual Studio C++ toolchain, Strawberry Perl, and NASM.

### 1. Install Visual Studio C++ Build Tools

Install Visual Studio 2026 or Build Tools for Visual Studio 2026, then enable:

- `Desktop development with C++`
- MSVC C++ build tools
- Windows 10/11 SDK

The scripts use `vswhere.exe` to locate the latest Visual Studio C++ toolchain and then call `vcvarsall.bat`, so you do not need to manually open a Developer Command Prompt.

If Visual Studio 2022 is still installed, the scripts can continue to work with it. When Visual Studio 2026 is available, it is preferred automatically.

### 2. Install Strawberry Perl and NASM

Download and install Strawberry Perl:

```text
https://strawberryperl.com/
```

Or install it with Chocolatey:

```powershell
choco install strawberryperl -y
```

Install NASM with Chocolatey:

```powershell
choco install nasm -y
```

After installation, reopen PowerShell and verify Perl and NASM:

```powershell
perl -v
nasm -v
```

### 3. Build OpenSSL

Build the latest OpenSSL release for x64 shared libraries:

```powershell
.\scripts\Invoke-OpenSslBuild.ps1
```

Build a specific version:

```powershell
.\scripts\Invoke-OpenSslBuild.ps1 -Version 4.0.1
```

Build both x64 and x86:

```powershell
.\scripts\Invoke-OpenSslBuild.ps1 -Version 4.0.1 -Targets "x64,x86"
```

Build static libraries only:

```powershell
.\scripts\Invoke-OpenSslBuild.ps1 -Version 4.0.1 -Targets x64 -Linkage static
```

Build both shared and static libraries:

```powershell
.\scripts\Invoke-OpenSslBuild.ps1 -Version 4.0.1 -Targets "x64,x86" -Linkage both
```

Install to `dist` without creating ZIP packages:

```powershell
.\scripts\Invoke-OpenSslBuild.ps1 -Version 4.0.1 -Targets x64 -Linkage shared -NoPackage
```

Default output directories:

- Source archives and extracted source: `build`
- Installed OpenSSL files: `dist`
- ZIP packages: `packages`

Generated package names look like this:

```text
openssl-4.0.1-windows-x64-shared.zip
openssl-4.0.1-windows-x64-static.zip
openssl-4.0.1-windows-x86-shared.zip
openssl-4.0.1-windows-x86-static.zip
```

## Scripts

- `scripts/Get-LatestOpenSslVersion.ps1`: resolves the latest stable OpenSSL release from GitHub Releases.
- `scripts/Test-OpenSslReleaseExists.ps1`: checks whether this repository already has a matching `openssl-x.y.z` release or tag.
- `scripts/New-OpenSslBuildMatrix.ps1`: creates the GitHub Actions build matrix.
- `scripts/Build-OpenSslWindows.ps1`: builds one architecture and one linkage type.
- `scripts/Invoke-OpenSslBuild.ps1`: local entry point for building multiple architectures and linkage types.

## GitHub Actions

The workflow is located at:

```text
.github/workflows/build-openssl-windows.yml
```

The scheduled workflow runs once per week. It checks the latest stable OpenSSL release from upstream first. If this repository already has a matching `openssl-x.y.z` release or tag, the build is skipped.

Cloud builds use the GitHub-hosted `windows-2025-vs2026` runner, which provides Windows Server 2025 with the Visual Studio 2026 image.

You can also run the workflow manually from the GitHub **Actions** page. Available inputs:

- `openssl_version`: OpenSSL version to build. Leave empty to build the latest stable release.
- `targets`: `x64`, `x86`, or multiple values separated by commas, such as `x64,x86`.
- `linkage`: `shared`, `static`, or `both`.
- `upload_release`: whether to upload packages to a GitHub Release.

Pushing an `openssl-*` tag also triggers a build:

```powershell
git tag openssl-4.0.1
git push origin openssl-4.0.1
```

Tag-triggered builds automatically upload ZIP packages to the matching GitHub Release.
